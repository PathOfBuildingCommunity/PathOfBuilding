-- Path of Building headless bridge
--
-- Runs Path of Building without a window and exposes its build/calculation engine
-- over a tiny JSON-lines RPC protocol, for use by the MCP server in ../server.py.
--
-- Must be started with the PoB `src` directory as the working directory, e.g.
--     cd src && luajit /path/to/bridge.lua
-- with LUA_PATH including ./?.lua and ../runtime/lua/?.lua.
--
-- Protocol
--   stdin : one JSON object per line: {"id": <any>, "cmd": "<name>", "args": {...}}
--   stdout: one JSON object per line, prefixed with ASCII RS (0x1E):
--           {"id": <same>, "ok": true, "result": ...} or {"id": <same>, "ok": false, "error": "..."}
--   Everything PoB itself prints is redirected to stderr.

---@diagnostic disable: lowercase-global

local RS = "\30"
local stdout = io.stdout
stdout:setvbuf("line")

-- PoB uses print()/ConPrintf() liberally; keep stdout clean for the protocol.
local stderr = io.stderr
print = function(...)
	local parts = { }
	for i = 1, select("#", ...) do
		parts[i] = tostring((select(i, ...)))
	end
	stderr:write(table.concat(parts, "\t"), "\n")
end

-- Some LuaJIT builds no longer skip a leading "#..." line (several PoB entry
-- files start with "#@"). Load files through a shim that strips it while
-- preserving line numbers.
function loadfile(path)
	local file, err = io.open(path, "rb")
	if not file then
		return nil, err
	end
	local src = file:read("*a")
	file:close()
	if src:sub(1, 1) == "#" then
		src = src:gsub("^[^\n]*", "", 1)
	end
	return loadstring(src, "@" .. path)
end
function dofile(path)
	local fn, err = loadfile(path)
	if not fn then
		error(err, 2)
	end
	return fn()
end

------------------------------------------------------------------------------
-- Headless bootstrap (mirrors HeadlessWrapper.lua, minus the blocking prompt)
------------------------------------------------------------------------------

dofile("_SimpleGraphic.def.lua")

function GetVirtualScreenSize()
	return 1920, 1080
end

__callbackTable__ = { }
function runCallback(name, ...)
	if __callbackTable__[name] then
		return __callbackTable__[name](...)
	elseif __mainObject__ and __mainObject__[name] then
		return __mainObject__[name](__mainObject__, ...)
	end
end

local l_require = require
function require(name)
	if name == "lcurl.safe" then
		-- Network access is not needed (and not available) headless
		return
	end
	return l_require(name)
end

local json = require("dkjson")

local function fatal(msg)
	stderr:write("FATAL: ", tostring(msg), "\n")
	stdout:write(RS, json.encode({ ok = false, fatal = true, error = tostring(msg) }), "\n")
	stdout:flush()
	os.exit(1)
end

dofile("Launch.lua")

runCallback("OnInit")
runCallback("OnFrame")

if __mainObject__.promptMsg then
	fatal("Path of Building failed to start: " .. tostring(__mainObject__.promptMsg))
end

launch = __mainObject__
main = launch.main
-- Never let dev-mode autosave write ~~temp~~.xml into the repository
main.disableDevAutoSave = true

local function build()
	local b = main.modes["BUILD"]
	if main.mode ~= "BUILD" or not b or not b.spec then
		error("No build is loaded")
	end
	return b
end

------------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------------

local function stripColors(s)
	if type(s) ~= "string" then
		return s
	end
	return (s:gsub("%^x%x%x%x%x%x%x", ""):gsub("%^%d", ""))
end

local objectMeta = { __jsontype = "object" }
local arrayMeta = { __jsontype = "array" }

local function object(t)
	return setmetatable(t or { }, objectMeta)
end
local function array(t)
	return setmetatable(t or { }, arrayMeta)
end

-- Convert an arbitrary Lua value into something dkjson can encode.
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
			-- Already shaped by object()/array(); keep that shape (matters for empty tables)
			isArray = mt.__jsontype == "array"
		end
		local out
		if isArray then
			out = array()
			for i = 1, n do
				out[i] = sanitize(value[i], depth + 1, seen)
				if out[i] == nil then
					out[i] = json.null
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
	-- functions, userdata, threads
	return nil
end

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

-- Close any popups PoB opened (confirmations, errors) and report them.
local function drainPopups()
	local msgs = array()
	local guard = 0
	while main.popups[1] and guard < 20 do
		local popup = main.popups[1]
		local text = { }
		if popup.title then
			table.insert(text, stripColors(tostring(popup.title)))
		end
		if popup.controls then
			for _, control in pairs(popup.controls) do
				if type(control) == "table" and type(control.label) == "string" then
					table.insert(text, stripColors(control.label))
				end
			end
		end
		table.insert(msgs, table.concat(text, " | "))
		main:ClosePopup()
		guard = guard + 1
	end
	return msgs
end

local function frame()
	runCallback("OnFrame")
	if launch.promptMsg then
		local msg = stripColors(tostring(launch.promptMsg))
		launch.promptMsg = nil
		error("Path of Building reported an error: " .. msg)
	end
end

local function recalc()
	local b = build()
	b.buildFlag = true
	frame()
	return drainPopups()
end

-- Snapshot of every stat that PoB would show in its sidebar, keyed by stat name
local function statLabels()
	local labels = { }
	for _, statData in ipairs(build().displayStats) do
		if statData.stat and not labels[statData.stat] then
			labels[statData.stat] = stripColors(statData.label)
		end
	end
	return labels
end

local function snapshot()
	local b = build()
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

local function diff(before, after)
	local labels = statLabels()
	local changes = array()
	local keys = { }
	for k in pairs(before) do keys[k] = true end
	for k in pairs(after) do keys[k] = true end
	local sorted = { }
	for k in pairs(keys) do table.insert(sorted, k) end
	table.sort(sorted)
	for _, k in ipairs(sorted) do
		local a, b = before[k], after[k]
		if (a or b) and a ~= b and (a == nil or b == nil or math.abs(a - b) > 0.001) then
			table.insert(changes, object({
				stat = k,
				label = labels[k] or k,
				before = a == nil and json.null or sanitize(a),
				after = b == nil and json.null or sanitize(b),
				delta = (a and b) and sanitize(b - a) or nil,
			}))
		end
	end
	return changes
end

-- Run a mutation and report how the sidebar stats changed because of it.
local function mutate(fn)
	local before = snapshot()
	local result = fn() or object()
	local popups = recalc()
	result.changes = diff(before, snapshot())
	if #popups > 0 then
		result.popups = popups
	end
	return result
end

local function keyStats()
	local o = build().calcsTab.mainOutput
	return pick(o, {
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
		table.insert(warnings, stripColors(line))
	end
	return object({
		name = b.buildName,
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
		keyStats = keyStats(),
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
			table.insert(exact, node)
		elseif name:find(needle, 1, true) then
			table.insert(partial, node)
		end
	end
	local candidates = #exact > 0 and exact or partial
	if #candidates == 0 then
		error("No passive node matching '" .. tostring(ref) .. "'")
	end
	-- Prefer nodes that can actually be reached from the current tree, then notables/keystones
	table.sort(candidates, function(a, b)
		local ra, rb = a.path and 1 or 0, b.path and 1 or 0
		if ra ~= rb then return ra > rb end
		local wa = (a.type == "Keystone" or a.type == "Notable") and 1 or 0
		local wb = (b.type == "Keystone" or b.type == "Notable") and 1 or 0
		if wa ~= wb then return wa > wb end
		return a.id < b.id
	end)
	if #candidates > 1 and candidates[1].type ~= "Keystone" and candidates[1].type ~= "Notable" and #exact == 0 then
		local names = { }
		for i = 1, math.min(#candidates, 8) do
			table.insert(names, string.format("%s (%d)", candidates[i].dn or "?", candidates[i].id))
		end
		error("Ambiguous node '" .. tostring(ref) .. "'; candidates: " .. table.concat(names, ", ") .. ". Use the numeric id.")
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
			table.insert(stats, stripColors(line))
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
		table.insert(gems, gemInfo(gemInstance))
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
			table.insert(slots, slot.slotName)
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
-- Command handlers
------------------------------------------------------------------------------

local handlers = { }

function handlers.ping()
	local b = main.modes["BUILD"]
	return object({
		version = launch.versionNumber,
		treeVersion = b and b.spec and b.spec.treeVersion or nil,
		buildLoaded = main.mode == "BUILD" and b ~= nil and b.spec ~= nil,
	})
end

function handlers.load_xml(args)
	assert(type(args.xml) == "string" and #args.xml > 0, "xml is required")
	main:SetMode("BUILD", false, args.name or "Imported build", args.xml)
	frame()
	local popups = drainPopups()
	if main.mode ~= "BUILD" or not main.modes["BUILD"].spec then
		error("Build could not be loaded" .. (#popups > 0 and (": " .. table.concat(popups, "; ")) or ""))
	end
	local result = summary()
	if #popups > 0 then
		result.popups = popups
	end
	return result
end

function handlers.new_build(args)
	main:SetMode("BUILD", false, args.name or "New build")
	frame()
	drainPopups()
	local result = summary()
	if args.class then
		result = handlers.set_class({ class = args.class, ascendancy = args.ascendancy })
	end
	return result
end

function handlers.set_class(args)
	local b = build()
	local spec = b.spec
	return mutate(function()
		if args.class then
			local classId
			for id, class in pairs(spec.tree.classes) do
				if class.name:lower() == tostring(args.class):lower() then
					classId = id
				end
			end
			assert(classId, "Unknown class '" .. tostring(args.class) .. "'")
			if classId ~= spec.curClassId then
				if spec:CountAllocNodes() == 0 or spec:IsClassConnected(classId) then
					spec:SelectClass(classId)
				elseif spec:ConnectToClass(classId) then
					spec:SelectClass(classId)
				else
					error("Cannot change class without resetting the tree; use reset_tree first")
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
end

function handlers.summary()
	return summary()
end

function handlers.stats(args)
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
				table.insert(missing, name)
			else
				out[name] = sanitize(v)
			end
		end
		return object({ stats = out, missing = missing })
	end
	return object({ stats = scalarsOnly(output) })
end

function handlers.sidebar()
	local b = build()
	local lines = array()
	for _, line in ipairs(b.controls.statBox.list) do
		if type(line[1]) == "string" then
			table.insert(lines, object({
				label = stripColors(line[1]):gsub(":%s*$", ""),
				value = stripColors(line[2]),
			}))
		end
	end
	return object({ lines = lines })
end

function handlers.breakdown(args)
	assert(args.stat, "stat is required")
	local b = build()
	-- Breakdown tables are only generated for the "CALCS" pass, not the sidebar ("MAIN") pass
	local env = b.calcsTab.calcsEnv
	local actor = args.actor == "minion" and env.minion or env.player
	if not actor or not actor.breakdown then
		error("No breakdown data available")
	end
	local data = actor.breakdown[args.stat]
	if data == nil then
		-- PoB only builds a breakdown when something actually modifies the stat; help the caller find a key
		local needle = tostring(args.stat):lower()
		local similar = { }
		for key in pairs(actor.breakdown) do
			if type(key) == "string" and key:lower():find(needle, 1, true) then
				table.insert(similar, key)
			end
		end
		table.sort(similar)
		local hint = #similar > 0 and (" Similar breakdowns: " .. table.concat(similar, ", ", 1, math.min(#similar, 15)))
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
end

-- Skills ---------------------------------------------------------------------

function handlers.skills()
	local b = build()
	local groups = array()
	for i, group in ipairs(b.skillsTab.socketGroupList) do
		table.insert(groups, socketGroupInfo(i, group, b.mainSocketGroup))
	end
	return object({ mainSocketGroup = b.mainSocketGroup, groups = groups })
end

function handlers.set_main_skill(args)
	local b = build()
	local index = tonumber(args.index)
	assert(index and b.skillsTab.socketGroupList[index], "Invalid socket group index")
	return mutate(function()
		b.mainSocketGroup = index
		if args.active_skill then
			b.skillsTab.socketGroupList[index].mainActiveSkill = tonumber(args.active_skill)
		end
		return object({ mainSocketGroup = index, mainSkill = nil })
	end)
end

function handlers.add_skill_group(args)
	local b = build()
	assert(type(args.gems) == "string", "gems text is required")
	local lines = { }
	for line in args.gems:gmatch("[^\r\n]+") do
		line = line:match("^%s*(.-)%s*$")
		if #line > 0 then
			-- "Name 20/20" -> "Name 20/20  1" so PasteSocketGroup's pattern accepts it
			if line:match("^[ %a']+ %d+/%d+$") then
				line = line .. "  1"
			elseif line:match("^[ %a']+$") then
				line = line .. " 20/0  1"
			end
			table.insert(lines, line)
		end
	end
	if args.slot then
		table.insert(lines, 1, "Slot: " .. args.slot)
	end
	if args.label then
		table.insert(lines, 1, "Label: " .. args.label)
	end
	local text = table.concat(lines, "\n") .. "\n"
	return mutate(function()
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
		-- PoB names support gems without the "Support" suffix ("Spell Echo", not "Spell Echo Support")
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
		return object({ index = index, group = socketGroupInfo(index, b.skillsTab.socketGroupList[index], args.make_main and index or b.mainSocketGroup) })
	end)
end

function handlers.remove_skill_group(args)
	local b = build()
	local index = tonumber(args.index)
	assert(index and b.skillsTab.socketGroupList[index], "Invalid socket group index")
	return mutate(function()
		table.remove(b.skillsTab.socketGroupList, index)
		if b.mainSocketGroup > #b.skillsTab.socketGroupList then
			b.mainSocketGroup = math.max(1, #b.skillsTab.socketGroupList)
		elseif b.mainSocketGroup > index then
			b.mainSocketGroup = b.mainSocketGroup - 1
		end
		b.skillsTab:AddUndoState()
		return object({ removed = index })
	end)
end

function handlers.set_gem(args)
	local b = build()
	local group = b.skillsTab.socketGroupList[tonumber(args.group) or 0]
	assert(group, "Invalid socket group index")
	local gem = group.gemList[tonumber(args.gem) or 0]
	assert(gem, "Invalid gem index")
	return mutate(function()
		if args.level ~= nil then gem.level = tonumber(args.level) end
		if args.quality ~= nil then gem.quality = tonumber(args.quality) end
		if args.enabled ~= nil then gem.enabled = args.enabled and true or false end
		if args.count ~= nil then gem.count = tonumber(args.count) end
		if args.name ~= nil then gem.nameSpec = tostring(args.name) end
		b.skillsTab:ProcessSocketGroup(group)
		b.skillsTab:AddUndoState()
		return object({ gem = gemInfo(gem) })
	end)
end

function handlers.set_group_enabled(args)
	local b = build()
	local group = b.skillsTab.socketGroupList[tonumber(args.index) or 0]
	assert(group, "Invalid socket group index")
	return mutate(function()
		if args.enabled ~= nil then group.enabled = args.enabled and true or false end
		if args.include_in_full_dps ~= nil then group.includeInFullDPS = args.include_in_full_dps and true or false end
		return object({ group = socketGroupInfo(tonumber(args.index), group, b.mainSocketGroup) })
	end)
end

-- Items ----------------------------------------------------------------------

function handlers.items()
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
		table.insert(slots, object({
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
			table.insert(items, itemInfo(itemsTab, item))
		end
	end
	return object({ slots = slots, items = items })
end

function handlers.item_text(args)
	local b = build()
	local item = b.itemsTab.items[tonumber(args.id) or 0]
	assert(item, "No item with id " .. tostring(args.id))
	return object({ id = item.id, name = item.name, text = item:BuildRaw() })
end

function handlers.add_item(args)
	local b = build()
	local itemsTab = b.itemsTab
	assert(type(args.text) == "string" and #args.text > 0, "item text is required")
	return mutate(function()
		itemsTab:CreateDisplayItemFromRaw(args.text, args.normalise and true or false)
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
		end
		return object({ item = itemInfo(itemsTab, item) })
	end)
end

function handlers.equip_item(args)
	local b = build()
	local itemsTab = b.itemsTab
	local item = itemsTab.items[tonumber(args.id) or 0]
	assert(item, "No item with id " .. tostring(args.id))
	local slot = itemsTab.slots[args.slot or ""]
	assert(slot, "Unknown slot '" .. tostring(args.slot) .. "'")
	return mutate(function()
		if not itemsTab:IsItemValidForSlot(item, args.slot) then
			error("Item '" .. item.name .. "' cannot be equipped in slot " .. args.slot)
		end
		slot:SetSelItemId(item.id)
		itemsTab:PopulateSlots()
		itemsTab:AddUndoState()
		return object({ item = itemInfo(itemsTab, item) })
	end)
end

function handlers.unequip_slot(args)
	local b = build()
	local itemsTab = b.itemsTab
	local slot = itemsTab.slots[args.slot or ""]
	assert(slot, "Unknown slot '" .. tostring(args.slot) .. "'")
	return mutate(function()
		local previous = slot.selItemId
		slot:SetSelItemId(0)
		itemsTab:PopulateSlots()
		itemsTab:AddUndoState()
		return object({ slot = args.slot, previousItemId = previous ~= 0 and previous or nil })
	end)
end

function handlers.delete_item(args)
	local b = build()
	local itemsTab = b.itemsTab
	local item = itemsTab.items[tonumber(args.id) or 0]
	assert(item, "No item with id " .. tostring(args.id))
	return mutate(function()
		itemsTab:DeleteItem(item)
		return object({ deleted = item.id, name = item.name })
	end)
end

-- Passive tree ---------------------------------------------------------------

function handlers.tree(args)
	local b = build()
	local spec = b.spec
	local used, ascUsed, secondaryAscUsed, sockets = spec:CountAllocNodes()
	local nodes = array()
	local ids = { }
	for id, node in pairs(spec.allocNodes) do
		if node.type ~= "ClassStart" and node.type ~= "AscendClassStart" then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	local withStats = args.with_stats and true or false
	for _, id in ipairs(ids) do
		local node = spec.allocNodes[id]
		if not args.notables_only or node.type == "Notable" or node.type == "Keystone" or node.type == "Mastery" then
			table.insert(nodes, nodeInfo(node, withStats or node.type == "Keystone" or node.type == "Notable"))
		end
	end
	local masteries = array()
	for nodeId, effectId in pairs(spec.masterySelections) do
		local node = spec.nodes[nodeId]
		local effectText
		if node and node.masteryEffects then
			for _, effect in ipairs(node.masteryEffects) do
				if effect.effect == effectId then
					effectText = stripColors(table.concat(effect.sd or { }, "; "))
				end
			end
		end
		table.insert(masteries, object({ nodeId = nodeId, mastery = node and node.dn or nil, effectId = effectId, effect = effectText }))
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
end

function handlers.search_nodes(args)
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
				table.insert(matches, node)
			end
		end
	end
	table.sort(matches, function(a, b)
		local ra, rb = a.alloc and 2 or (a.path and 1 or 0), b.alloc and 2 or (b.path and 1 or 0)
		if ra ~= rb then return ra > rb end
		local pa, pb = a.path and #a.path or 1e9, b.path and #b.path or 1e9
		if pa ~= pb then return pa < pb end
		return a.id < b.id
	end)
	local nodes = array()
	for i = 1, math.min(#matches, limit) do
		table.insert(nodes, nodeInfo(matches[i], true))
	end
	return object({ total = #matches, nodes = nodes })
end

function handlers.alloc_node(args)
	local b = build()
	local spec = b.spec
	local node = findNode(spec, args.node)
	if node.alloc then
		return object({ node = nodeInfo(node, true), alreadyAllocated = true, changes = array() })
	end
	if not node.path then
		error(string.format("Node '%s' (%d) cannot be reached from the current tree", node.dn or "?", node.id))
	end
	return mutate(function()
		local pathNodes = array()
		for _, pathNode in ipairs(node.path) do
			if not pathNode.alloc then
				table.insert(pathNodes, nodeInfo(pathNode, false))
			end
		end
		spec:AllocNode(node)
		spec:AddUndoState()
		return object({ node = nodeInfo(node, true), allocatedPath = pathNodes })
	end)
end

function handlers.dealloc_node(args)
	local b = build()
	local spec = b.spec
	local node = findNode(spec, args.node)
	if not node.alloc then
		error(string.format("Node '%s' (%d) is not allocated", node.dn or "?", node.id))
	end
	return mutate(function()
		local removed = array()
		for _, depNode in ipairs(node.depends) do
			table.insert(removed, nodeInfo(depNode, false))
		end
		spec:DeallocNode(node)
		spec:AddUndoState()
		return object({ node = nodeInfo(node, true), deallocated = removed })
	end)
end

function handlers.reset_tree()
	local b = build()
	return mutate(function()
		b.spec:ResetNodes()
		b.spec:BuildAllDependsAndPaths()
		b.spec:AddUndoState()
		return object({ reset = true })
	end)
end

function handlers.import_tree_url(args)
	local b = build()
	assert(type(args.url) == "string", "url is required")
	return mutate(function()
		local err = b.spec:DecodeURL(args.url)
		if err then
			error("Could not decode tree URL: " .. tostring(err))
		end
		b.spec:AddUndoState()
		return object({ imported = true })
	end)
end

-- Configuration --------------------------------------------------------------

local varList = require("Modules.ConfigOptions")

local function configEntry(configTab, varData, section)
	local input = configTab.input
	local placeholder = configTab.placeholder
	local entry = object({
		var = varData.var,
		type = varData.type,
		label = stripColors(varData.label),
		section = section,
		value = sanitize(input[varData.var]),
		placeholder = sanitize(placeholder[varData.var]),
	})
	if varData.tooltip and type(varData.tooltip) == "string" then
		entry.tooltip = stripColors(varData.tooltip)
	end
	if varData.type == "list" and varData.list then
		local options = array()
		for _, opt in ipairs(varData.list) do
			table.insert(options, object({ value = sanitize(opt.val), label = stripColors(opt.label) }))
		end
		entry.options = options
		if varData.defaultIndex and varData.list[varData.defaultIndex] then
			entry.default = sanitize(varData.list[varData.defaultIndex].val)
		end
	end
	return entry
end

function handlers.config_list(args)
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
					table.insert(entries, configEntry(configTab, varData, section))
				end
			end
		end
	end
	return object({ total = total, options = entries })
end

function handlers.config_set(args)
	local b = build()
	local configTab = b.configTab
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
					table.insert(labels, tostring(opt.val) .. " (" .. stripColors(opt.label) .. ")")
				end
				error("Invalid value for '" .. varData.var .. "'. Options: " .. table.concat(labels, ", "))
			end
			value = matched
		else
			value = tostring(value)
		end
	else
		value = nil
	end
	return mutate(function()
		configTab.input[varData.var] = value
		-- Keep the Build-level mirrors of a few options in sync
		if varData.var == "bandit" or varData.var == "pantheonMajorGod" or varData.var == "pantheonMinorGod" then
			b[varData.var] = value or "None"
		end
		configTab:BuildModList()
		configTab:AddUndoState()
		local entry = configEntry(configTab, varData, nil)
		return object({ option = entry })
	end)
end

local CUSTOM_BLOCK_TITLE = "MCP"

function handlers.set_custom_mods(args)
	local b = build()
	local configTab = b.configTab
	local text = args.text and tostring(args.text) or ""
	return mutate(function()
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
						table.remove(set.customModsList, i)
						break
					end
				end
			end
		else
			if not block then
				block = { title = CUSTOM_BLOCK_TITLE, enabled = true }
				table.insert(set.customModsList, block)
			end
			block.text = text
			block.enabled = true
		end
		configTab:BuildModList()
		-- Report which lines PoB could not parse
		local unparsed = array()
		for line in text:gmatch("([^\n]*)\n?") do
			local stripped = line:match("^%s*(.-)%s*$")
			if #stripped > 0 then
				local mods, extra = modLib.parseMod(stripped)
				if not mods or extra then
					table.insert(unparsed, stripped)
				end
			end
		end
		return object({ text = text, unparsed = unparsed })
	end)
end

function handlers.get_custom_mods()
	local b = build()
	local set = b.configTab.configSets[b.configTab.activeConfigSetId]
	local blocks = array()
	for _, block in ipairs(set.customModsList or { }) do
		table.insert(blocks, object({ title = block.title, enabled = block.enabled ~= false, text = block.text }))
	end
	return object({ blocks = blocks, legacyCustomMods = b.configTab.input.customMods })
end

function handlers.set_character(args)
	local b = build()
	return mutate(function()
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
		for _, key in ipairs({ "bandit", "pantheonMajorGod", "pantheonMinorGod" }) do
			if args[key] ~= nil then
				b[key] = tostring(args[key])
				b.configTab.input[key] = tostring(args[key])
			end
		end
		b.configTab:BuildModList()
		return summary()
	end)
end

-- Export ---------------------------------------------------------------------

function handlers.export_xml()
	local b = build()
	local xml = b:SaveDB("export")
	if not xml then
		error("Could not serialise the build")
	end
	return object({ xml = xml })
end

------------------------------------------------------------------------------
-- Main loop
------------------------------------------------------------------------------

local function respond(resp)
	local ok, encoded = pcall(json.encode, resp)
	if not ok then
		encoded = json.encode({ id = resp.id, ok = false, error = "Could not encode response: " .. tostring(encoded) })
	end
	stdout:write(RS, encoded, "\n")
	stdout:flush()
end

while true do
	local line = io.stdin:read("*l")
	if not line then
		break
	end
	if line:match("%S") then
		local req, _, decodeErr = json.decode(line)
		if type(req) ~= "table" then
			respond({ ok = false, error = "Malformed request: " .. tostring(decodeErr) })
		else
			local handler = handlers[req.cmd]
			if not handler then
				respond({ id = req.id, ok = false, error = "Unknown command '" .. tostring(req.cmd) .. "'" })
			else
				local ok, result = xpcall(function()
					return handler(req.args or { })
				end, function(err)
					return debug.traceback(tostring(err), 2)
				end)
				if ok then
					respond({ id = req.id, ok = true, result = sanitize(result) })
				else
					-- Keep the full traceback on stderr, send the first line back
					stderr:write(result, "\n")
					local firstLine = tostring(result):match("^[^\n]*")
					-- Drop the "<path>/bridge.lua:123: " prefix Lua adds to error() messages
					firstLine = firstLine:gsub("^.-bridge%.lua:%d+: ", "")
					respond({ id = req.id, ok = false, error = stripColors(firstLine) })
				end
			end
		end
	end
end
