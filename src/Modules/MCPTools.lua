-- Path of Building
--
-- Module: MCP Tools
-- The tools the in-app MCP server (see Modules/MCPStatus.lua and MCPServer.lua) offers to AI
-- assistants. They run on the main thread and act on the build that is open in this window,
-- exactly as if the user had made the change: the tree, items, skills and config tabs update,
-- the build is marked unsaved, and every mutating tool reports which sidebar stats moved.
--
local dkjson = require("dkjson")
local ipairs = ipairs
local pairs = pairs
local t_insert = table.insert
local t_remove = table.remove
local t_sort = table.sort
local t_concat = table.concat
local m_min = math.min
local m_max = math.max
local m_abs = math.abs
local s_format = string.format

local mcpTools = { }

------------------------------------------------------------------------------
-- JSON helpers
------------------------------------------------------------------------------

local objectMeta = { __jsontype = "object" }
local arrayMeta = { __jsontype = "array" }

local function object(t)
	return setmetatable(t or { }, objectMeta)
end
local function array(t)
	return setmetatable(t or { }, arrayMeta)
end
mcpTools.object = object
mcpTools.array = array

local function stripColors(s)
	if type(s) ~= "string" then
		return s
	end
	return (s:gsub("%^x%x%x%x%x%x%x", ""):gsub("%^%d", ""))
end

--- Converts an arbitrary Lua value into something dkjson can encode (no functions, cycles, NaN).
local function sanitize(value, depth, seen)
	depth = depth or 0
	local t = type(value)
	if t == "number" then
		if value ~= value then
			return nil
		elseif value == math.huge then
			return "inf"
		elseif value == -math.huge then
			return "-inf"
		end
		return value
	elseif t == "string" or t == "boolean" or t == "nil" then
		return value
	elseif t == "table" then
		if depth > 6 then
			return "<table>"
		end
		seen = seen or { }
		if seen[value] then
			return "<cycle>"
		end
		seen[value] = true
		local n = 0
		local isArray = true
		for k in pairs(value) do
			n = n + 1
			if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then
				isArray = false
			end
		end
		isArray = isArray and n == #value
		local mt = getmetatable(value)
		if mt and mt.__jsontype then
			isArray = mt.__jsontype == "array"
		end
		local out
		if isArray then
			out = array()
			for i = 1, n do
				out[i] = sanitize(value[i], depth + 1, seen)
				if out[i] == nil then
					out[i] = dkjson.null
				end
			end
		else
			out = object()
			for k, v in pairs(value) do
				local sv = sanitize(v, depth + 1, seen)
				if sv ~= nil then
					out[tostring(k)] = sv
				end
			end
		end
		seen[value] = nil
		return out
	end
	return nil
end
mcpTools.sanitize = sanitize

local function scalarsOnly(tbl)
	local out = object()
	for k, v in pairs(tbl) do
		local t = type(v)
		if t == "number" or t == "string" or t == "boolean" then
			out[tostring(k)] = sanitize(v)
		end
	end
	return out
end

local function pick(tbl, keys)
	local out = object()
	for _, k in ipairs(keys) do
		if tbl[k] ~= nil then
			out[k] = sanitize(tbl[k])
		end
	end
	return out
end

------------------------------------------------------------------------------
-- Talking to the open build
------------------------------------------------------------------------------

local function currentBuild()
	local b = main.modes["BUILD"]
	if main.mode == "BUILD" and b and b.spec then
		return b
	end
	return nil
end

local function build()
	local b = currentBuild()
	if not b then
		error("No build is open in Path of Building. Use open_build, load_build or new_build first.")
	end
	return b
end

--- Whether the build has unsaved changes. Build:OnFrame caches this in b.unsaved once per frame;
--- tools run between frames, so evaluate it fresh (same expression as Build:OnFrame).
local function isUnsaved(b)
	local unsaved = b.modFlag or b.notesTab.modFlag or b.partyTab.modFlag or b.configTab.modFlag or b.treeTab.modFlag or b.treeTab.searchFlag or b.spec.modFlag or b.skillsTab.modFlag or b.itemsTab.modFlag or b.calcsTab.modFlag
	b.unsaved = unsaved
	return unsaved and true or false
end

--- Performs any pending mode switch (main:SetMode only schedules one) right now.
local function applyModeChange()
	main:ProcessModeChange()
	if launch.promptMsg then
		error("Path of Building reported an error: " .. stripColors(tostring(launch.promptMsg)))
	end
end

--- Closes popups that a tool caused PoB to open (confirmations, errors) and returns their text.
--- Popups the user had open before the tool ran are left alone.
local function drainNewPopups(popupsBefore)
	local msgs = array()
	local guard = 0
	while #main.popups > popupsBefore and guard < 20 do
		local popup = main.popups[1]
		local text = { }
		if popup.title then
			t_insert(text, stripColors(tostring(popup.title)))
		end
		if popup.controls then
			for _, control in pairs(popup.controls) do
				if type(control) == "table" and type(control.label) == "string" then
					t_insert(text, stripColors(control.label))
				end
			end
		end
		t_insert(msgs, t_concat(text, " | "))
		main:ClosePopup()
		guard = guard + 1
	end
	return msgs
end

--- Recomputes the build now (what Build:OnFrame does when buildFlag is set) so results are current.
local function recalc(b)
	wipeGlobalCache()
	b.outputRevision = (b.outputRevision or 0) + 1
	b.buildFlag = false
	b.skillsTab:UpdateSocketGroups()
	b.calcsTab:BuildOutput()
	b:RefreshStatList()
	b.configTab.calcFunc, b.configTab.calcBase = b.calcsTab:GetMiscCalculator()
	if launch.promptMsg then
		error("Path of Building reported an error: " .. stripColors(tostring(launch.promptMsg)))
	end
end

local function statLabels(b)
	local labels = { }
	for _, statData in ipairs(b.displayStats) do
		if statData.stat and not labels[statData.stat] then
			labels[statData.stat] = stripColors(statData.label)
		end
	end
	return labels
end

local function snapshot(b)
	local snap = { }
	local output = b.calcsTab.mainOutput
	for _, statData in ipairs(b.displayStats) do
		if statData.stat and not statData.childStat then
			local v = output[statData.stat]
			if type(v) == "number" then
				snap[statData.stat] = v
			end
		end
	end
	return snap
end

local function diff(b, before, after)
	local labels = statLabels(b)
	local changes = array()
	local keys = { }
	for k in pairs(before) do keys[k] = true end
	for k in pairs(after) do keys[k] = true end
	local sorted = { }
	for k in pairs(keys) do t_insert(sorted, k) end
	t_sort(sorted)
	for _, k in ipairs(sorted) do
		local a, c = before[k], after[k]
		if (a or c) and a ~= c and (a == nil or c == nil or m_abs(a - c) > 0.001) then
			t_insert(changes, object({
				stat = k,
				label = labels[k] or k,
				before = a == nil and dkjson.null or sanitize(a),
				after = c == nil and dkjson.null or sanitize(c),
				delta = (a and c) and sanitize(c - a) or nil,
			}))
		end
	end
	return changes
end

--- Runs a mutation on the open build, recomputes, marks the build unsaved and reports stat changes.
local function mutate(fn)
	local b = build()
	local popupsBefore = #main.popups
	local before = snapshot(b)
	local result = fn(b) or object()
	b.modFlag = true
	recalc(b)
	local popups = drainNewPopups(popupsBefore)
	result.changes = diff(b, before, snapshot(b))
	if #popups > 0 then
		result.popups = popups
	end
	return result
end

local function requireNoUnsavedChanges(args)
	local b = currentBuild()
	if b and isUnsaved(b) and not args.force then
		error(s_format("The open build '%s' has unsaved changes. Save it in Path of Building first, or pass force=true to discard them.", b.buildName or "Unnamed build"))
	end
	if b then
		-- Don't let dev-mode autosave write a ~~temp~~ file for a build the caller chose to discard
		b.abortSave = true
	end
end

------------------------------------------------------------------------------
-- Info builders
------------------------------------------------------------------------------

local function keyStats(b)
	return pick(b.calcsTab.mainOutput, {
		"TotalDPS", "CombinedDPS", "FullDPS", "TotalDotDPS", "WithPoisonDPS", "WithIgniteDPS", "WithBleedDPS",
		"AverageHit", "AverageDamage", "Speed", "HitChance", "CritChance", "CritMultiplier", "ManaCost", "LifeCost",
		"Life", "LifeUnreserved", "LifeRegenRecovery", "EnergyShield", "EnergyShieldRegenRecovery", "Mana", "ManaUnreserved", "ManaRegenRecovery",
		"Armour", "Evasion", "Spirit", "Ward", "TotalEHP", "PhysicalMaximumHitTaken", "FireMaximumHitTaken", "ColdMaximumHitTaken", "LightningMaximumHitTaken", "ChaosMaximumHitTaken",
		"FireResist", "ColdResist", "LightningResist", "ChaosResist", "FireResistOverCap", "ColdResistOverCap", "LightningResistOverCap", "ChaosResistOverCap",
		"BlockChance", "SpellBlockChance", "AttackDodgeChance", "SpellDodgeChance", "SpellSuppressionChance", "EffectiveMovementSpeedMod",
		"Str", "Dex", "Int", "ReqStr", "ReqDex", "ReqInt",
	})
end

local function summary()
	local b = build()
	local spec = b.spec
	local env = b.calcsTab.mainEnv
	local used, ascUsed = spec:CountAllocNodes()
	local mainSkill = env and env.player and env.player.mainSkill
	local mainSkillName
	if mainSkill and mainSkill.activeEffect and mainSkill.activeEffect.grantedEffect then
		mainSkillName = mainSkill.activeEffect.grantedEffect.name
	end
	local warnings = array()
	for _, line in ipairs(b.controls.warnings and b.controls.warnings.lines or { }) do
		t_insert(warnings, stripColors(line))
	end
	return object({
		name = b.buildName,
		file = b.dbFileName or nil,
		unsaved = isUnsaved(b),
		class = spec.curClassName,
		ascendancy = spec.curAscendClassName,
		secondaryAscendancy = spec.curSecondaryAscendClassName,
		level = b.characterLevel,
		levelAutoMode = b.characterLevelAutoMode,
		bandit = b.bandit,
		pantheonMajorGod = b.pantheonMajorGod,
		pantheonMinorGod = b.pantheonMinorGod,
		treeVersion = spec.treeVersion,
		passivePointsUsed = used,
		ascendancyPointsUsed = ascUsed,
		pointsDisplay = b.controls.pointDisplay and stripColors(b.controls.pointDisplay.str) or nil,
		mainSocketGroup = b.mainSocketGroup,
		mainSkill = mainSkillName,
		mainSkillInfo = mainSkill and stripColors(mainSkill.infoMessage) or nil,
		keyStats = keyStats(b),
		warnings = warnings,
	})
end

local function findNode(spec, ref)
	local id = tonumber(ref)
	if id then
		local node = spec.nodes[id]
		if not node then
			error("No passive node with id " .. tostring(id))
		end
		return node
	end
	local needle = tostring(ref):lower()
	local exact, partial = { }, { }
	for _, node in pairs(spec.nodes) do
		local name = (node.dn or node.name or ""):lower()
		if name == needle then
			t_insert(exact, node)
		elseif name:find(needle, 1, true) then
			t_insert(partial, node)
		end
	end
	local candidates = #exact > 0 and exact or partial
	if #candidates == 0 then
		error("No passive node matching '" .. tostring(ref) .. "'")
	end
	t_sort(candidates, function(a, c)
		local ra, rb = a.path and 1 or 0, c.path and 1 or 0
		if ra ~= rb then return ra > rb end
		local wa = (a.type == "Keystone" or a.type == "Notable") and 1 or 0
		local wb = (c.type == "Keystone" or c.type == "Notable") and 1 or 0
		if wa ~= wb then return wa > wb end
		return a.id < c.id
	end)
	if #candidates > 1 and candidates[1].type ~= "Keystone" and candidates[1].type ~= "Notable" and #exact == 0 then
		local names = { }
		for i = 1, m_min(#candidates, 8) do
			t_insert(names, s_format("%s (%d)", candidates[i].dn or "?", candidates[i].id))
		end
		error("Ambiguous node '" .. tostring(ref) .. "'; candidates: " .. t_concat(names, ", ") .. ". Use the numeric id.")
	end
	return candidates[1]
end

local function nodeInfo(node, withStats)
	local info = object({
		id = node.id,
		name = node.dn or node.name,
		type = node.type,
		allocated = node.alloc and true or false,
		ascendancy = node.ascendancyName,
		reachable = node.path ~= nil,
		pathCost = node.path and (#node.path - (node.alloc and 1 or 0)) or nil,
	})
	if withStats and node.sd then
		local stats = array()
		for _, line in ipairs(node.sd) do
			t_insert(stats, stripColors(line))
		end
		info.stats = stats
	end
	return info
end

local function gemInfo(gemInstance)
	local gemData = gemInstance.gemData
	local grantedEffect = gemData and gemData.grantedEffect
	return object({
		nameSpec = gemInstance.nameSpec,
		name = gemData and gemData.name or nil,
		level = gemInstance.level,
		quality = gemInstance.quality,
		qualityId = gemInstance.qualityId,
		enabled = gemInstance.enabled and true or false,
		count = gemInstance.count or 1,
		isSupport = grantedEffect and grantedEffect.support or false,
		recognised = gemData ~= nil,
		errMsg = gemInstance.errMsg,
	})
end

local function socketGroupInfo(index, group, mainIndex)
	local gems = array()
	for _, gemInstance in ipairs(group.gemList) do
		t_insert(gems, gemInfo(gemInstance))
	end
	return object({
		index = index,
		label = group.label ~= "" and group.label or nil,
		displayLabel = stripColors(group.displayLabel),
		slot = group.slot,
		source = group.source,
		enabled = group.enabled and true or false,
		includeInFullDPS = group.includeInFullDPS and true or false,
		isMainSkill = index == mainIndex,
		mainActiveSkill = group.mainActiveSkill,
		gems = gems,
	})
end

local function itemInfo(itemsTab, item)
	local slots = array()
	for _, slot in ipairs(itemsTab.orderedSlots) do
		if slot.selItemId == item.id then
			t_insert(slots, slot.slotName)
		end
	end
	return object({
		id = item.id,
		name = item.name,
		title = item.title,
		baseName = item.baseName,
		type = item.type,
		rarity = item.rarity,
		itemLevel = item.itemLevel,
		quality = item.quality,
		corrupted = item.corrupted and true or false,
		equippedIn = slots,
	})
end

------------------------------------------------------------------------------
-- Share codes and build files
------------------------------------------------------------------------------

local function decodeShareCode(code)
	code = code:gsub("%s", "")
	local xml = Inflate(common.base64.decode((code:gsub("-", "+"):gsub("_", "/"))))
	if not xml or not xml:match("^%s*<") then
		error("Not a valid Path of Building share code")
	end
	return xml
end

local function encodeShareCode(xml)
	return (common.base64.encode(Deflate(xml)):gsub("+", "-"):gsub("/", "_"))
end

local function readFile(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end
	local text = file:read("*a")
	file:close()
	return text
end

local function isAbsolutePath(path)
	return path:match("^[\\/]") or path:match("^%a:[\\/]") or path:match("^~")
end

local function buildFilePath(name)
	name = name:gsub("^[\\/]+", "")
	if not name:lower():match("%.xml$") then
		name = name .. ".xml"
	end
	if isAbsolutePath(name) then
		return name
	end
	return main.buildPath .. name
end

--- Turns the `source` of load_build into build XML: raw XML, a share code, a file path, or text
--- the server sub script downloaded from a build site.
local function resolveBuildXML(source)
	local text = tostring(source or ""):match("^%s*(.-)%s*$")
	assert(#text > 0, "source is empty")
	if text:match("^<") then
		return text, "xml"
	end
	if text:match("^https?://") then
		error("Could not download '" .. text .. "'. Pass the share code or the build XML instead.")
	end
	local fileText = readFile(text) or readFile(buildFilePath(text))
	if fileText then
		fileText = fileText:match("^%s*(.-)%s*$")
		if fileText:match("^<") then
			return fileText, text
		end
		return decodeShareCode(fileText), text
	end
	if text:find("[/ ]") then
		error("'" .. text .. "' is neither an existing file, a URL, nor a share code")
	end
	return decodeShareCode(text), "share code"
end

------------------------------------------------------------------------------
-- Tool definitions
------------------------------------------------------------------------------

local tools = { }
local toolsByName = { }

--- Registers a tool. `properties` is the JSON-schema property map; `handler(args)` returns a JSON-able table.
local function def(name, description, properties, required, handler)
	local schema = object({ type = "object", properties = object(properties or { }) })
	if required and #required > 0 then
		schema.required = array(required)
	end
	for _, prop in pairs(schema.properties) do
		setmetatable(prop, objectMeta)
		if prop.enum then
			setmetatable(prop.enum, arrayMeta)
		end
	end
	local tool = { name = name, description = description, inputSchema = schema, handler = handler }
	t_insert(tools, tool)
	toolsByName[name] = tool
end

local STR = function(desc) return { type = "string", description = desc } end
local INT = function(desc) return { type = "integer", description = desc } end
local NUM = function(desc) return { type = "number", description = desc } end
local BOOL = function(desc) return { type = "boolean", description = desc } end

-- Builds ---------------------------------------------------------------------

def("get_build_summary",
	"Class, ascendancy, level, main skill, passive points, warnings and the key offensive/defensive stats of the build open in Path of Building.",
	{ }, nil,
	function()
		return summary()
	end)

def("list_builds",
	"The build files in Path of Building's Builds folder (optionally a sub-folder), for open_build.",
	{ folder = STR("Sub-folder of the Builds folder to list (default: the root)") }, nil,
	function(args)
		local sub = tostring(args.folder or ""):gsub("^[\\/]+", "")
		if #sub > 0 and not sub:match("[\\/]$") then
			sub = sub .. "/"
		end
		local builds = array()
		local handle = NewFileSearch(main.buildPath .. sub .. "*.xml")
		while handle do
			local fileName = handle:GetFileName()
			t_insert(builds, object({
				name = fileName:gsub("%.xml$", ""),
				path = sub .. fileName,
				modified = handle:GetFileModifiedTime(),
			}))
			if not handle:NextFile() then
				break
			end
		end
		local folders = array()
		handle = NewFileSearch(main.buildPath .. sub .. "*", true)
		while handle do
			t_insert(folders, sub .. handle:GetFileName())
			if not handle:NextFile() then
				break
			end
		end
		t_sort(builds, function(a, c) return a.name:lower() < c.name:lower() end)
		local open = currentBuild()
		return object({
			buildsFolder = main.buildPath,
			folders = folders,
			builds = builds,
			openBuild = open and object({ name = open.buildName, file = open.dbFileName or nil, unsaved = isUnsaved(open) }) or nil,
		})
	end)

def("open_build",
	"Open a saved build from the Builds folder in the Path of Building window (name or relative path from list_builds). Refuses to replace a build with unsaved changes unless force=true.",
	{ name = STR("Build name or path relative to the Builds folder, e.g. \"My Build\" or \"Folder/My Build.xml\""), force = BOOL("Discard unsaved changes of the currently open build") }, { "name" },
	function(args)
		local fullPath = buildFilePath(tostring(args.name))
		if not readFile(fullPath) then
			error("No build file at '" .. fullPath .. "'")
		end
		requireNoUnsavedChanges(args)
		local buildName = fullPath:match("([^\\/]+)%.xml$")
		main:SetMode("BUILD", fullPath, buildName)
		local popupsBefore = #main.popups
		applyModeChange()
		local popups = drainNewPopups(popupsBefore)
		if not currentBuild() then
			error("Build could not be opened" .. (#popups > 0 and (": " .. t_concat(popups, "; ")) or ""))
		end
		local result = summary()
		if #popups > 0 then
			result.popups = popups
		end
		return result
	end)

def("load_build",
	"Load a build into the Path of Building window from a share code, raw build XML, a .xml file path, or a pobb.in / pob.codes / poe.ninja / maxroll.gg / pastebin / rentry / poedb link. "
	.. "The build opens unsaved (use save_build to keep it). Refuses to replace a build with unsaved changes unless force=true.",
	{ source = STR("Share code, build XML, file path, or build-site URL"), name = STR("Name for the new build (default: derived from the source)"), force = BOOL("Discard unsaved changes of the currently open build") }, { "source" },
	function(args)
		local xml, origin = resolveBuildXML(args.source)
		requireNoUnsavedChanges(args)
		local name = args.name
		if not name or name == "" then
			if origin ~= "xml" and origin ~= "share code" and not origin:match("^https?://") then
				name = origin:match("([^\\/]+)%.xml$") or origin:match("([^\\/]+)$")
			else
				name = "Imported build"
			end
		end
		main:SetMode("BUILD", false, name, xml)
		local popupsBefore = #main.popups
		applyModeChange()
		local popups = drainNewPopups(popupsBefore)
		if not currentBuild() then
			error("Build could not be loaded" .. (#popups > 0 and (": " .. t_concat(popups, "; ")) or ""))
		end
		local result = summary()
		result.source = args.source_url or origin
		if #popups > 0 then
			result.popups = popups
		end
		return result
	end)

def("new_build",
	"Start a new, empty build (level 1, no items, no skills) in the Path of Building window; optionally pick class and ascendancy. Refuses to replace a build with unsaved changes unless force=true.",
	{ class_name = STR("Character class, e.g. \"Witch\""), ascendancy = STR("Ascendancy class, e.g. \"Necromancer\""), name = STR("Build name"), force = BOOL("Discard unsaved changes of the currently open build") }, nil,
	function(args)
		requireNoUnsavedChanges(args)
		main:SetMode("BUILD", false, args.name or "New build")
		local popupsBefore = #main.popups
		applyModeChange()
		drainNewPopups(popupsBefore)
		local result = summary()
		if args.class_name then
			result = toolsByName.set_class.handler({ class_name = args.class_name, ascendancy = args.ascendancy })
		end
		return result
	end)

def("close_build",
	"Close the open build and return to Path of Building's build list. Refuses when there are unsaved changes unless force=true.",
	{ force = BOOL("Discard unsaved changes") }, nil,
	function(args)
		local b = build()
		requireNoUnsavedChanges(args)
		local name = b.buildName
		b:CloseBuild()
		applyModeChange()
		return object({ closed = name })
	end)

def("save_build",
	"Save the open build. Without `path` it is written to its own file (the build must have been saved before); with `path` it is written there (relative paths go into the Builds folder) and the window switches to that file.",
	{ path = STR("Target file, e.g. \"My Build\" or \"Folder/My Build.xml\"") }, nil,
	function(args)
		local b = build()
		if args.path and args.path ~= "" then
			local fullPath = buildFilePath(tostring(args.path))
			local folder = fullPath:match("^(.*)[\\/][^\\/]+$")
			if folder then
				MakeDir(folder)
			end
			b.dbFileName = fullPath
			b.buildName = fullPath:match("([^\\/]+)%.xml$")
			b.dbFileSubPath = fullPath:sub(1, #main.buildPath) == main.buildPath and (fullPath:sub(#main.buildPath + 1):match("^(.*[\\/])") or "") or b.dbFileSubPath
			b.spec:SetWindowTitleWithBuildClass()
		elseif not b.dbFileName then
			error("This build has never been saved; pass `path` to choose a file name")
		end
		local popupsBefore = #main.popups
		local failed = b:SaveDBFile()
		local popups = drainNewPopups(popupsBefore)
		if failed then
			error("Could not save the build" .. (#popups > 0 and (": " .. t_concat(popups, "; ")) or ""))
		end
		return object({ path = b.dbFileName, name = b.buildName })
	end)

def("export_build",
	"Export the open build as a share code (format=\"code\", for pobb.in or PoB's Import tab) or as XML (format=\"xml\").",
	{ format = { type = "string", enum = { "code", "xml" }, description = "\"code\" (default) or \"xml\"" } }, nil,
	function(args)
		local b = build()
		local xml = b:SaveDB("export")
		if not xml then
			error("Could not serialise the build")
		end
		if args.format == "xml" then
			return object({ xml = xml })
		end
		return object({ code = encodeShareCode(xml) })
	end)

def("decode_build_code",
	"Decode a PoB share code into its XML without loading it.",
	{ code = STR("The share code") }, { "code" },
	function(args)
		return object({ xml = decodeShareCode(tostring(args.code or "")) })
	end)

def("set_class",
	"Change the character class and/or ascendancy of the open build. The tree is kept when the new class start is connected; otherwise PoB connects it along the shortest path.",
	{ class_name = STR("Character class"), ascendancy = STR("Ascendancy class") }, nil,
	function(args)
		return mutate(function(b)
			local spec = b.spec
			if args.class_name then
				local classId
				for id, class in pairs(spec.tree.classes) do
					if class.name:lower() == tostring(args.class_name):lower() then
						classId = id
					end
				end
				assert(classId, "Unknown class '" .. tostring(args.class_name) .. "'")
				if classId ~= spec.curClassId then
					if spec:CountAllocNodes() == 0 or spec:IsClassConnected(classId) then
						spec:SelectClass(classId)
					elseif spec:ConnectToClass(classId) then
						spec:SelectClass(classId)
					else
						error("Cannot change class without resetting the tree; use reset_passive_tree first")
					end
				end
			end
			if args.ascendancy then
				local ascendId
				local class = spec.tree.classes[spec.curClassId]
				for id, ascend in pairs(class.classes) do
					if ascend.name:lower() == tostring(args.ascendancy):lower() then
						ascendId = id
					end
				end
				assert(ascendId, "Unknown ascendancy '" .. tostring(args.ascendancy) .. "' for class " .. class.name)
				spec:SelectAscendClass(ascendId)
			end
			spec:AddUndoState()
			return summary()
		end)
	end)

def("set_character",
	"Set character level (1-100, turns off auto level unless level_auto=true), bandit choice (\"None\", \"Oak\", \"Kraityn\", \"Alira\") and pantheon gods (e.g. \"TheBrineKing\", \"Lunaris\", \"Solaris\", \"Arakaali\", \"Gruthkul\", \"Yugul\", \"Abberath\", \"Tukohama\", \"Garukhan\", \"Ralakesh\", \"Ryslatha\", \"Shakari\").",
	{ level = INT("Character level 1-100"), level_auto = BOOL("Let PoB pick the level from the allocated points"), bandit = STR("Bandit choice"), pantheon_major_god = STR("Major god"), pantheon_minor_god = STR("Minor god") }, nil,
	function(args)
		return mutate(function(b)
			if args.level ~= nil then
				local level = tonumber(args.level)
				assert(level and level >= 1 and level <= 100, "level must be between 1 and 100")
				b.characterLevel = level
				b.characterLevelAutoMode = false
				if b.controls.characterLevel then
					b.controls.characterLevel:SetText(tostring(level))
				end
			end
			if args.level_auto ~= nil then
				b.characterLevelAutoMode = args.level_auto and true or false
			end
			local map = { bandit = "bandit", pantheon_major_god = "pantheonMajorGod", pantheon_minor_god = "pantheonMinorGod" }
			for argKey, key in pairs(map) do
				if args[argKey] ~= nil then
					b[key] = tostring(args[argKey])
					b.configTab.input[key] = tostring(args[argKey])
				end
			end
			b.configTab:BuildModList()
			return summary()
		end)
	end)

-- Stats ----------------------------------------------------------------------

def("get_stats",
	"Raw calculated stats from PoB's output table. Pass `names` (e.g. [\"TotalDPS\", \"Life\", \"FireResist\"]) for specific values, or omit to get every scalar stat (several hundred). `actor` may be \"player\" or \"minion\".",
	{ names = { type = "array", items = { type = "string" }, description = "Stat names to return" }, actor = { type = "string", enum = { "player", "minion" } } }, nil,
	function(args)
		local b = build()
		local env = b.calcsTab.mainEnv
		local actor = env.player
		if args.actor == "minion" then
			actor = env.minion
			if not actor then
				error("This build has no minion actor")
			end
		end
		local output = actor.output
		if args.names then
			local out = object()
			local missing = array()
			for _, name in ipairs(args.names) do
				local v = output[name]
				if v == nil then
					t_insert(missing, name)
				else
					out[name] = sanitize(v)
				end
			end
			return object({ stats = out, missing = missing })
		end
		return object({ stats = scalarsOnly(output) })
	end)

def("get_sidebar_stats",
	"The stats exactly as PoB shows them in the left-hand sidebar (formatted strings, in display order).",
	{ }, nil,
	function()
		local b = build()
		local lines = array()
		for _, line in ipairs(b.controls.statBox.list) do
			if type(line[1]) == "string" then
				t_insert(lines, object({
					label = (stripColors(line[1]):gsub(":%s*$", "")),
					value = stripColors(line[2]),
				}))
			end
		end
		return object({ lines = lines })
	end)

def("get_breakdown",
	"PoB's calculation breakdown for one stat (what the Calcs tab shows on hover), e.g. \"Life\", \"TotalDPS\", \"Speed\", \"Armour\". PoB only builds a breakdown for stats that modifiers affect; the error lists similar keys when one is missing.",
	{ stat = STR("Stat name"), actor = { type = "string", enum = { "player", "minion" } } }, { "stat" },
	function(args)
		local b = build()
		local env = b.calcsTab.calcsEnv
		local actor = args.actor == "minion" and env.minion or env.player
		if not actor or not actor.breakdown then
			error("No breakdown data available")
		end
		local data = actor.breakdown[args.stat]
		if data == nil then
			local needle = tostring(args.stat):lower()
			local similar = { }
			for key in pairs(actor.breakdown) do
				if type(key) == "string" and key:lower():find(needle, 1, true) then
					t_insert(similar, key)
				end
			end
			t_sort(similar)
			local hint = #similar > 0 and (" Similar breakdowns: " .. t_concat(similar, ", ", 1, m_min(#similar, 15)))
				or " (PoB only generates a breakdown when modifiers affect the stat.)"
			error("No breakdown for stat '" .. tostring(args.stat) .. "'." .. hint)
		end
		local function strip(v)
			if type(v) == "string" then
				return stripColors(v)
			elseif type(v) == "table" then
				local out = { }
				for k, x in pairs(v) do
					out[k] = strip(x)
				end
				return out
			end
			return v
		end
		local mainActor = args.actor == "minion" and b.calcsTab.mainEnv.minion or b.calcsTab.mainEnv.player
		return object({
			stat = args.stat,
			value = sanitize(actor.output[args.stat]),
			sidebarValue = mainActor and sanitize(mainActor.output[args.stat]) or nil,
			breakdown = sanitize(strip(data)),
		})
	end)

-- Skills ---------------------------------------------------------------------

def("list_skills",
	"All socket groups (skill setups) with their gems, levels, qualities and which one is the main skill.",
	{ }, nil,
	function()
		local b = build()
		local groups = array()
		for i, group in ipairs(b.skillsTab.socketGroupList) do
			t_insert(groups, socketGroupInfo(i, group, b.mainSocketGroup))
		end
		return object({ mainSocketGroup = b.mainSocketGroup, groups = groups })
	end)

def("set_main_skill",
	"Select which socket group (1-based index from list_skills) is the main skill used for DPS; `active_skill` picks the active gem within the group when it has several.",
	{ index = INT("Socket group index"), active_skill = INT("Active skill index within the group") }, { "index" },
	function(args)
		return mutate(function(b)
			local index = tonumber(args.index)
			assert(index and b.skillsTab.socketGroupList[index], "Invalid socket group index")
			b.mainSocketGroup = index
			if args.active_skill then
				b.skillsTab.socketGroupList[index].mainActiveSkill = tonumber(args.active_skill)
			end
			return object({ mainSocketGroup = index })
		end)
	end)

def("add_skill_group",
	"Add a socket group. `gems` is one gem per line as \"<name> <level>/<quality>\" (e.g. \"Fireball 21/20\"; the Support suffix is optional). `slot` (e.g. \"Body Armour\", \"Weapon 1\") links the group to an item slot.",
	{ gems = STR("Gem lines"), slot = STR("Item slot"), label = STR("Group label"), make_main = BOOL("Make this the main skill group") }, { "gems" },
	function(args)
		assert(type(args.gems) == "string", "gems text is required")
		local lines = { }
		for line in args.gems:gmatch("[^\r\n]+") do
			line = line:match("^%s*(.-)%s*$")
			if #line > 0 then
				if line:match("^[ %a']+ %d+/%d+$") then
					line = line .. "  1"
				elseif line:match("^[ %a']+$") then
					line = line .. " 20/0  1"
				end
				t_insert(lines, line)
			end
		end
		if args.slot then
			t_insert(lines, 1, "Slot: " .. args.slot)
		end
		if args.label then
			t_insert(lines, 1, "Label: " .. args.label)
		end
		local text = t_concat(lines, "\n") .. "\n"
		return mutate(function(b)
			local count = #b.skillsTab.socketGroupList
			b.skillsTab:PasteSocketGroup(text)
			if #b.skillsTab.socketGroupList == count then
				error("No gems were recognised in the supplied text")
			end
			local index = #b.skillsTab.socketGroupList
			if args.make_main then
				b.mainSocketGroup = index
			end
			local group = b.skillsTab.socketGroupList[index]
			b.skillsTab:ProcessSocketGroup(group)
			local retry = false
			for _, gemInstance in ipairs(group.gemList) do
				if gemInstance.errMsg and gemInstance.nameSpec:match(" [Ss]upport$") then
					gemInstance.nameSpec = gemInstance.nameSpec:gsub(" [Ss]upport$", "")
					retry = true
				end
			end
			if retry then
				b.skillsTab:ProcessSocketGroup(group)
			end
			return object({ index = index, group = socketGroupInfo(index, group, b.mainSocketGroup) })
		end)
	end)

def("remove_skill_group",
	"Remove a socket group by its 1-based index.",
	{ index = INT("Socket group index") }, { "index" },
	function(args)
		return mutate(function(b)
			local index = tonumber(args.index)
			assert(index and b.skillsTab.socketGroupList[index], "Invalid socket group index")
			t_remove(b.skillsTab.socketGroupList, index)
			if b.mainSocketGroup > #b.skillsTab.socketGroupList then
				b.mainSocketGroup = m_max(1, #b.skillsTab.socketGroupList)
			elseif b.mainSocketGroup > index then
				b.mainSocketGroup = b.mainSocketGroup - 1
			end
			b.skillsTab:AddUndoState()
			return object({ removed = index })
		end)
	end)

def("set_gem",
	"Change a gem inside a socket group (both indices 1-based, from list_skills). `name` swaps the gem for another.",
	{ group_index = INT("Socket group index"), gem_index = INT("Gem index within the group"), level = INT("Gem level"), quality = INT("Gem quality"), enabled = BOOL("Enable or disable the gem"), count = INT("Number of copies"), name = STR("Replacement gem name") }, { "group_index", "gem_index" },
	function(args)
		return mutate(function(b)
			local group = b.skillsTab.socketGroupList[tonumber(args.group_index) or 0]
			assert(group, "Invalid socket group index")
			local gem = group.gemList[tonumber(args.gem_index) or 0]
			assert(gem, "Invalid gem index")
			if args.level ~= nil then gem.level = tonumber(args.level) end
			if args.quality ~= nil then gem.quality = tonumber(args.quality) end
			if args.enabled ~= nil then gem.enabled = args.enabled and true or false end
			if args.count ~= nil then gem.count = tonumber(args.count) end
			if args.name ~= nil then gem.nameSpec = tostring(args.name) end
			b.skillsTab:ProcessSocketGroup(group)
			b.skillsTab:AddUndoState()
			return object({ gem = gemInfo(gem) })
		end)
	end)

def("set_skill_group_enabled",
	"Enable/disable a socket group, or toggle whether it counts towards Full DPS.",
	{ index = INT("Socket group index"), enabled = BOOL("Enabled"), include_in_full_dps = BOOL("Include in Full DPS") }, { "index" },
	function(args)
		return mutate(function(b)
			local group = b.skillsTab.socketGroupList[tonumber(args.index) or 0]
			assert(group, "Invalid socket group index")
			if args.enabled ~= nil then group.enabled = args.enabled and true or false end
			if args.include_in_full_dps ~= nil then group.includeInFullDPS = args.include_in_full_dps and true or false end
			return object({ group = socketGroupInfo(tonumber(args.index), group, b.mainSocketGroup) })
		end)
	end)

-- Items ----------------------------------------------------------------------

def("list_items",
	"Equipment slots with what is equipped, plus every item in the build's item list (equipped or not).",
	{ }, nil,
	function()
		local b = build()
		local itemsTab = b.itemsTab
		local slots = array()
		for _, slot in ipairs(itemsTab.orderedSlots) do
			local item = slot.selItemId ~= 0 and itemsTab.items[slot.selItemId] or nil
			local shown = true
			if slot.IsShown then
				local ok, res = pcall(slot.IsShown, slot)
				shown = (not ok) or res
			end
			t_insert(slots, object({
				slot = slot.slotName,
				isJewelSocket = slot.nodeId ~= nil,
				nodeId = slot.nodeId,
				active = shown and true or false,
				itemId = item and item.id or nil,
				itemName = item and item.name or nil,
			}))
		end
		local items = array()
		for _, id in ipairs(itemsTab.itemOrderList) do
			local item = itemsTab.items[id]
			if item then
				t_insert(items, itemInfo(itemsTab, item))
			end
		end
		return object({ slots = slots, items = items })
	end)

def("get_item_text",
	"Full item text (PoB/in-game format) for an item from list_items.",
	{ item_id = INT("Item id") }, { "item_id" },
	function(args)
		local b = build()
		local item = b.itemsTab.items[tonumber(args.item_id) or 0]
		assert(item, "No item with id " .. tostring(args.item_id))
		return object({ id = item.id, name = item.name, text = item:BuildRaw() })
	end)

def("add_item",
	"Add an item from its text (in-game Ctrl+C format or PoB item format) and, by default, equip it. Without `slot` PoB picks the first valid empty slot; with `slot` (e.g. \"Ring 2\", \"Weapon 1\", \"Body Armour\", \"Flask 3\") it replaces what is equipped there.",
	{ item_text = STR("Item text"), slot = STR("Slot to equip into"), equip = BOOL("Equip the item (default true)") }, { "item_text" },
	function(args)
		assert(type(args.item_text) == "string" and #args.item_text > 0, "item text is required")
		return mutate(function(b)
			local itemsTab = b.itemsTab
			itemsTab:CreateDisplayItemFromRaw(args.item_text, false)
			local item = itemsTab.displayItem
			if not item then
				error("Could not parse item text (unknown base type?)")
			end
			local equip = args.equip ~= false
			itemsTab:AddDisplayItem((not equip) or args.slot ~= nil)
			if equip and args.slot then
				local slot = itemsTab.slots[args.slot]
				assert(slot, "Unknown slot '" .. tostring(args.slot) .. "'")
				if not itemsTab:IsItemValidForSlot(item, args.slot) then
					error("Item '" .. item.name .. "' cannot be equipped in slot " .. args.slot)
				end
				slot:SetSelItemId(item.id)
				itemsTab:PopulateSlots()
			end
			return object({ item = itemInfo(itemsTab, item) })
		end)
	end)

def("equip_item",
	"Equip an existing item (from list_items) into a slot.",
	{ item_id = INT("Item id"), slot = STR("Slot name") }, { "item_id", "slot" },
	function(args)
		return mutate(function(b)
			local itemsTab = b.itemsTab
			local item = itemsTab.items[tonumber(args.item_id) or 0]
			assert(item, "No item with id " .. tostring(args.item_id))
			local slot = itemsTab.slots[args.slot or ""]
			assert(slot, "Unknown slot '" .. tostring(args.slot) .. "'")
			if not itemsTab:IsItemValidForSlot(item, args.slot) then
				error("Item '" .. item.name .. "' cannot be equipped in slot " .. args.slot)
			end
			slot:SetSelItemId(item.id)
			itemsTab:PopulateSlots()
			itemsTab:AddUndoState()
			return object({ item = itemInfo(itemsTab, item) })
		end)
	end)

def("unequip_slot",
	"Empty an equipment slot (the item stays in the item list).",
	{ slot = STR("Slot name") }, { "slot" },
	function(args)
		return mutate(function(b)
			local itemsTab = b.itemsTab
			local slot = itemsTab.slots[args.slot or ""]
			assert(slot, "Unknown slot '" .. tostring(args.slot) .. "'")
			local previous = slot.selItemId
			slot:SetSelItemId(0)
			itemsTab:PopulateSlots()
			itemsTab:AddUndoState()
			return object({ slot = args.slot, previousItemId = previous ~= 0 and previous or nil })
		end)
	end)

def("delete_item",
	"Delete an item from the build entirely.",
	{ item_id = INT("Item id") }, { "item_id" },
	function(args)
		return mutate(function(b)
			local itemsTab = b.itemsTab
			local item = itemsTab.items[tonumber(args.item_id) or 0]
			assert(item, "No item with id " .. tostring(args.item_id))
			itemsTab:DeleteItem(item)
			return object({ deleted = item.id, name = item.name })
		end)
	end)

-- Passive tree ---------------------------------------------------------------

def("get_passive_tree",
	"Allocated passive nodes, mastery choices, point counts and a pathofexile.com tree link. By default only notables, keystones and masteries are listed; set notables_only=false for every node.",
	{ notables_only = BOOL("Only notables, keystones and masteries (default true)"), with_stats = BOOL("Include each node's stat lines") }, nil,
	function(args)
		local b = build()
		local spec = b.spec
		local used, ascUsed, secondaryAscUsed, sockets = spec:CountAllocNodes()
		local notablesOnly = args.notables_only ~= false
		local nodes = array()
		local ids = { }
		for id, node in pairs(spec.allocNodes) do
			if node.type ~= "ClassStart" and node.type ~= "AscendClassStart" then
				t_insert(ids, id)
			end
		end
		t_sort(ids)
		local withStats = args.with_stats and true or false
		for _, id in ipairs(ids) do
			local node = spec.allocNodes[id]
			if not notablesOnly or node.type == "Notable" or node.type == "Keystone" or node.type == "Mastery" then
				t_insert(nodes, nodeInfo(node, withStats or node.type == "Keystone" or node.type == "Notable"))
			end
		end
		local masteries = array()
		for nodeId, effectId in pairs(spec.masterySelections) do
			local node = spec.nodes[nodeId]
			local effectText
			if node and node.masteryEffects then
				for _, effect in ipairs(node.masteryEffects) do
					if effect.effect == effectId then
						effectText = stripColors(t_concat(effect.sd or { }, "; "))
					end
				end
			end
			t_insert(masteries, object({ nodeId = nodeId, mastery = node and node.dn or nil, effectId = effectId, effect = effectText }))
		end
		local url
		pcall(function()
			url = spec:EncodeURL("https://www.pathofexile.com/passive-skill-tree/")
		end)
		return object({
			class = spec.curClassName,
			ascendancy = spec.curAscendClassName,
			treeVersion = spec.treeVersion,
			passivePointsUsed = used,
			ascendancyPointsUsed = ascUsed,
			secondaryAscendancyPointsUsed = secondaryAscUsed,
			jewelSocketsAllocated = sockets,
			pointsDisplay = b.controls.pointDisplay and stripColors(b.controls.pointDisplay.str) or nil,
			nodes = nodes,
			masteries = masteries,
			url = url,
		})
	end)

def("search_passive_nodes",
	"Find passive nodes whose name or stat text contains `query`; reports whether each is allocated and how many points it costs to reach.",
	{ query = STR("Text to search for"), allocated_only = BOOL("Only allocated nodes"), limit = INT("Maximum results (default 40)") }, { "query" },
	function(args)
		local b = build()
		local spec = b.spec
		local needle = tostring(args.query or ""):lower()
		assert(#needle > 0, "query is required")
		local limit = tonumber(args.limit) or 40
		local matches = { }
		for _, node in pairs(spec.nodes) do
			if node.type ~= "ClassStart" and node.type ~= "AscendClassStart" and (not args.allocated_only or node.alloc) then
				local hit = (node.dn or ""):lower():find(needle, 1, true) ~= nil
				if not hit and node.sd then
					for _, line in ipairs(node.sd) do
						if line:lower():find(needle, 1, true) then
							hit = true
							break
						end
					end
				end
				if hit then
					t_insert(matches, node)
				end
			end
		end
		t_sort(matches, function(a, c)
			local ra, rb = a.alloc and 2 or (a.path and 1 or 0), c.alloc and 2 or (c.path and 1 or 0)
			if ra ~= rb then return ra > rb end
			local pa, pb = a.path and #a.path or 1e9, c.path and #c.path or 1e9
			if pa ~= pb then return pa < pb end
			return a.id < c.id
		end)
		local nodes = array()
		for i = 1, m_min(#matches, limit) do
			t_insert(nodes, nodeInfo(matches[i], true))
		end
		return object({ total = #matches, nodes = nodes })
	end)

def("allocate_node",
	"Allocate a passive node (by numeric id or name, e.g. \"Elemental Overload\") plus the shortest path to it.",
	{ node = STR("Node id or name") }, { "node" },
	function(args)
		local b = build()
		local node = findNode(b.spec, args.node)
		if node.alloc then
			return object({ node = nodeInfo(node, true), alreadyAllocated = true, changes = array() })
		end
		if not node.path then
			error(s_format("Node '%s' (%d) cannot be reached from the current tree", node.dn or "?", node.id))
		end
		return mutate(function()
			local pathNodes = array()
			for _, pathNode in ipairs(node.path) do
				if not pathNode.alloc then
					t_insert(pathNodes, nodeInfo(pathNode, false))
				end
			end
			b.spec:AllocNode(node)
			b.spec:AddUndoState()
			return object({ node = nodeInfo(node, true), allocatedPath = pathNodes })
		end)
	end)

def("deallocate_node",
	"Deallocate a passive node (by id or name) and any nodes that were only connected through it.",
	{ node = STR("Node id or name") }, { "node" },
	function(args)
		local b = build()
		local node = findNode(b.spec, args.node)
		if not node.alloc then
			error(s_format("Node '%s' (%d) is not allocated", node.dn or "?", node.id))
		end
		return mutate(function()
			local removed = array()
			for _, depNode in ipairs(node.depends) do
				t_insert(removed, nodeInfo(depNode, false))
			end
			b.spec:DeallocNode(node)
			b.spec:AddUndoState()
			return object({ node = nodeInfo(node, true), deallocated = removed })
		end)
	end)

def("reset_passive_tree",
	"Remove every allocated passive (keeps class and ascendancy).",
	{ }, nil,
	function()
		return mutate(function(b)
			b.spec:ResetNodes()
			b.spec:BuildAllDependsAndPaths()
			b.spec:AddUndoState()
			return object({ reset = true })
		end)
	end)

def("import_passive_tree",
	"Replace the passive tree from a pathofexile.com or poeplanner passive tree URL.",
	{ url = STR("Passive tree URL") }, { "url" },
	function(args)
		assert(type(args.url) == "string", "url is required")
		return mutate(function(b)
			local err = b.spec:DecodeURL(args.url)
			if err then
				error("Could not decode tree URL: " .. tostring(err))
			end
			b.spec:AddUndoState()
			return object({ imported = true })
		end)
	end)

-- Configuration --------------------------------------------------------------

local varList = LoadModule("Modules/ConfigOptions")

local function configEntry(configTab, varData, section)
	local entry = object({
		var = varData.var,
		type = varData.type,
		label = stripColors(varData.label),
		section = section,
		value = sanitize(configTab.input[varData.var]),
		placeholder = sanitize(configTab.placeholder[varData.var]),
	})
	if type(varData.tooltip) == "string" then
		entry.tooltip = stripColors(varData.tooltip)
	end
	if varData.type == "list" and varData.list then
		local options = array()
		for _, opt in ipairs(varData.list) do
			t_insert(options, object({ value = sanitize(opt.val), label = stripColors(opt.label) }))
		end
		entry.options = options
		if varData.defaultIndex and varData.list[varData.defaultIndex] then
			entry.default = sanitize(varData.list[varData.defaultIndex].val)
		end
	end
	return entry
end

def("list_config_options",
	"Configuration tab options (buffs, charges, enemy settings, conditions...) with their current values. Filter with `query` (variable name or label, e.g. \"frenzy\", \"boss\", \"shock\") or `section` (\"General\", \"Skill Options\", \"Map Modifiers and Player Debuffs\", \"When In Combat\", \"For Effective DPS\"); only_set=true shows just the options changed from default.",
	{ query = STR("Text filter"), section = STR("Section filter"), only_set = BOOL("Only options with a value set"), limit = INT("Maximum results (default 150)") }, nil,
	function(args)
		local b = build()
		local configTab = b.configTab
		local query = args.query and tostring(args.query):lower() or nil
		local wantSection = args.section and tostring(args.section):lower() or nil
		local limit = tonumber(args.limit) or 150
		local section
		local entries = array()
		local total = 0
		for _, varData in ipairs(varList) do
			if varData.section then
				section = varData.section
			elseif varData.var then
				local ok = true
				if wantSection and not (section or ""):lower():find(wantSection, 1, true) then
					ok = false
				end
				if ok and args.only_set and configTab.input[varData.var] == nil then
					ok = false
				end
				if ok and query then
					local hay = (varData.var .. " " .. stripColors(varData.label or "")):lower()
					if not hay:find(query, 1, true) then
						ok = false
					end
				end
				if ok then
					total = total + 1
					if #entries < limit then
						t_insert(entries, configEntry(configTab, varData, section))
					end
				end
			end
		end
		return object({ total = total, options = entries })
	end)

def("set_config_option",
	"Set a Configuration tab option by variable name (from list_config_options). Checkboxes take true/false, counters take numbers, lists take an option value or label; pass null or \"\" to reset to default. Examples: (\"usePowerCharges\", true), (\"enemyIsBoss\", \"Pinnacle\"), (\"multiplierRage\", 50).",
	{ var = STR("Option variable name"), value = { description = "New value (boolean, number, string or null)" } }, { "var" },
	function(args)
		assert(args.var, "var is required")
		local varData
		for _, data in ipairs(varList) do
			if data.var == args.var then
				varData = data
				break
			end
		end
		assert(varData, "Unknown config option '" .. tostring(args.var) .. "'")
		local value = args.value
		if value == dkjson.null then
			value = nil
		end
		if value ~= nil and value ~= "" then
			if varData.type == "check" then
				if type(value) == "string" then
					value = value:lower() == "true" or value == "1" or value:lower() == "yes"
				else
					value = value and true or false
				end
				if not value then
					value = nil
				end
			elseif varData.type == "count" or varData.type == "integer" or varData.type == "countAllowZero" or varData.type == "float" then
				value = tonumber(value)
				assert(value, "Option '" .. varData.var .. "' expects a number")
			elseif varData.type == "list" then
				local matched
				for _, opt in ipairs(varData.list) do
					if opt.val == value or tostring(opt.val) == tostring(value) or (type(value) == "string" and stripColors(opt.label):lower() == value:lower()) then
						matched = opt.val
						break
					end
				end
				if matched == nil then
					local labels = { }
					for _, opt in ipairs(varData.list) do
						t_insert(labels, tostring(opt.val) .. " (" .. stripColors(opt.label) .. ")")
					end
					error("Invalid value for '" .. varData.var .. "'. Options: " .. t_concat(labels, ", "))
				end
				value = matched
			else
				value = tostring(value)
			end
		else
			value = nil
		end
		return mutate(function(b)
			local configTab = b.configTab
			configTab.input[varData.var] = value
			if varData.var == "bandit" or varData.var == "pantheonMajorGod" or varData.var == "pantheonMinorGod" then
				b[varData.var] = value or "None"
			end
			configTab:BuildModList()
			configTab:AddUndoState()
			return object({ option = configEntry(configTab, varData, nil) })
		end)
	end)

local CUSTOM_BLOCK_TITLE = "MCP"

def("set_custom_modifiers",
	"Apply free-form modifiers to the character, one per line, in item/passive wording - e.g. \"+100 to maximum Life\", \"20% increased Attack Speed\", \"Chaos Inoculation\". Useful for what-if questions. Replaces modifiers previously set by this tool (they live in a Custom Modifiers block named \"MCP\" on the Configuration tab); pass \"\" to clear. Lines PoB cannot parse are returned in `unparsed`.",
	{ text = STR("Modifier lines") }, { "text" },
	function(args)
		local text = args.text and tostring(args.text) or ""
		return mutate(function(b)
			local configTab = b.configTab
			local set = configTab.configSets[configTab.activeConfigSetId]
			set.customModsList = set.customModsList or { }
			local block
			for _, existing in ipairs(set.customModsList) do
				if existing.title == CUSTOM_BLOCK_TITLE then
					block = existing
				end
			end
			if #text:gsub("%s", "") == 0 then
				if block then
					for i, existing in ipairs(set.customModsList) do
						if existing == block then
							t_remove(set.customModsList, i)
							break
						end
					end
				end
			else
				if not block then
					block = { title = CUSTOM_BLOCK_TITLE, enabled = true }
					t_insert(set.customModsList, block)
				end
				block.text = text
				block.enabled = true
			end
			configTab:BuildModList()
			local unparsed = array()
			for line in text:gmatch("([^\n]*)\n?") do
				local stripped = line:match("^%s*(.-)%s*$")
				if #stripped > 0 then
					local mods, extra = modLib.parseMod(stripped)
					if not mods or extra then
						t_insert(unparsed, stripped)
					end
				end
			end
			return object({ text = text, unparsed = unparsed })
		end)
	end)

def("get_custom_modifiers",
	"Custom modifier blocks currently applied to the build (Configuration tab > Custom Modifiers).",
	{ }, nil,
	function()
		local b = build()
		local set = b.configTab.configSets[b.configTab.activeConfigSetId]
		local blocks = array()
		for _, block in ipairs(set.customModsList or { }) do
			t_insert(blocks, object({ title = block.title, enabled = block.enabled ~= false, text = block.text }))
		end
		return object({ blocks = blocks, legacyCustomMods = b.configTab.input.customMods })
	end)

------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------

mcpTools.INSTRUCTIONS = [[
Path of Building (Path of Exile 1 build planner). These tools act on the build that is open in the
Path of Building window; the user sees every change immediately and can undo or save it there.

Typical workflow:
1. `get_build_summary` to see what is open (or `list_builds` + `open_build`, `load_build` with a share
   code / build-site link, or `new_build`).
2. `get_sidebar_stats` / `get_stats` / `get_breakdown` to read what PoB calculates.
3. Change things - `add_item`, `set_config_option`, `allocate_node`, `set_gem`, `set_custom_modifiers`
   and friends. Every mutating tool returns `changes`: the sidebar stats that moved, with before/after values.
4. The build is marked unsaved; `save_build` writes it, `export_build` gives a share code.

Stat names (`get_stats`, `get_breakdown`) are PoB's internal output keys, e.g. TotalDPS, CombinedDPS,
FullDPS, Life, EnergyShield, Mana, Armour, Evasion, TotalEHP, FireResist, ColdResist, LightningResist,
ChaosResist, Speed, CritChance, AverageHit. `get_stats` with no names lists everything.

Item text uses the in-game copy format (Ctrl+C on an item): rarity line, name, base, then one modifier
per line. Gem lists use one gem per line as "<name> <level>/<quality>", e.g. "Fireball 21/20".
]]

--- The tool list as `tools/list` returns it.
function mcpTools.List()
	local list = array()
	for _, tool in ipairs(tools) do
		t_insert(list, object({ name = tool.name, description = tool.description, inputSchema = tool.inputSchema }))
	end
	return list
end

function mcpTools.Has(name)
	return toolsByName[name] ~= nil
end

--- Runs a tool. Returns `true, result` or `false, errorMessage`.
function mcpTools.Call(name, args)
	local tool = toolsByName[name]
	if not tool then
		return false, "Unknown tool '" .. tostring(name) .. "'"
	end
	args = type(args) == "table" and args or { }
	local ok, result = xpcall(function()
		return tool.handler(args)
	end, function(err)
		return debug.traceback(tostring(err), 2)
	end)
	if ok then
		return true, sanitize(result)
	end
	ConPrintf("MCP tool %s failed: %s", name, tostring(result))
	local firstLine = tostring(result):match("^[^\n]*")
	firstLine = firstLine:gsub("^.-%.lua:%d+: ", "")
	return false, stripColors(firstLine)
end

return mcpTools
