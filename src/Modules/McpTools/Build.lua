-- Path of Building
--
-- Module: MCP Tools - Build
-- Status, the builds folder, opening and saving builds, the side bar stats,
-- and what-if calculations.
--
local T = ...

local t_insert = table.insert
local t_concat = table.concat
local s_format = string.format

local buildListHelpers = require("Modules.BuildListHelpers")

-- Attributes PoB checks requirements against (CalcPerform, "Req"..attr).
local REQUIREMENT_ATTRIBUTES = { "Str", "Dex", "Int", "Omni" }

-- Output fields build_stats and simulate report when no list is given.
local DEFAULT_FIELDS = {
	"CombinedDPS", "TotalDPS", "FullDPS", "TotalDot", "AverageHit", "Speed", "CritChance", "CritMultiplier", "HitChance",
	"Life", "LifeUnreserved", "EnergyShield", "Mana", "ManaUnreserved", "Ward", "Armour", "Evasion",
	"FireResist", "ColdResist", "LightningResist", "ChaosResist", "EffectiveSpellSuppressionChance", "EffectiveBlockChance",
	"EffectiveSpellBlockChance", "TotalEHP", "PhysicalMaximumHitTaken", "FireMaximumHitTaken", "ColdMaximumHitTaken",
	"LightningMaximumHitTaken", "ChaosMaximumHitTaken", "LifeRegenRecovery", "EffectiveMovementSpeedMod",
	"Str", "Dex", "Int",
}

local function classInfo(spec)
	local info = {
		class = spec.curClassName,
		ascendancy = spec.curAscendClassId ~= 0 and spec.curAscendClassName or nil,
	}
	if spec.curSecondaryAscendClassId and spec.curSecondaryAscendClassId ~= 0 then
		info.secondaryAscendancy = spec.curSecondaryAscendClassName
	end
	return info
end

-- The skill the side bar is calculated for.
local function mainSkillName(build)
	local env = build.calcsTab.mainEnv
	local skill = env and env.player and env.player.mainSkill
	if not skill or not skill.activeEffect then
		return nil
	end
	local name = skill.activeEffect.grantedEffect.name
	if skill.skillPartName then
		name = name .. " (" .. skill.skillPartName .. ")"
	end
	return name
end

-- A short description of the open build.
function T.BuildSummary(build)
	local used, ascUsed = build.spec:CountAllocNodes()
	local summary = {
		name = build.buildName,
		file = build.dbFileName and (build.dbFileSubPath or "") .. build.buildName .. ".xml" or nil,
		level = build.characterLevel,
		mainSkill = mainSkillName(build),
		tab = build.viewMode,
		passivePointsUsed = used,
		ascendancyPointsUsed = ascUsed,
		unsaved = build:HasUnsavedChanges() and true or false,
	}
	for k, v in pairs(classInfo(build.spec)) do
		summary[k] = v
	end
	if summary.unsaved then
		summary.unsavedParts = T.UnsavedParts(build)
	end
	return summary
end

-- Decode a build share code (url-safe base64 of the deflated XML), or pass XML through.
function T.DecodeBuildCode(code)
	code = code:gsub("^%s+", ""):gsub("%s+$", "")
	if code:sub(1, 1) == "<" then
		return code
	end
	local xml = Inflate(common.base64.decode((code:gsub("-", "+"):gsub("_", "/"))))
	if not xml or not xml:match("<PathOfBuilding") then
		T.Fail("That is not a Path of Building build code (or the code is incomplete).")
	end
	return xml
end

function T.EncodeBuildCode(xml)
	return (common.base64.encode(Deflate(xml)):gsub("+", "-"):gsub("/", "_"))
end

-- The build-site entry (Modules/BuildSiteTools) a link belongs to.
function T.FindBuildSite(link)
	for _, site in ipairs(buildSites.websiteList) do
		if link:match(site.matchURL) then
			return site
		end
	end
end

-- A path below the builds folder, refusing anything that could leave it.
local function buildFolderPath(relative, what)
	relative = (relative or ""):gsub("\\", "/"):gsub("^/+", "")
	if relative:match("%.%.") or relative:match(":") then
		T.Fail("%s must be a path inside the builds folder, without '..' or a drive", what)
	end
	return relative
end

------------------------------------------------------------------------------

T.Tool {
	name = "app_status",
	title = "Path of Building status",
	description = "Shows what Path of Building has open: its version, whether a build is open (name, file, class, ascendancy, level, "
		.. "main skill, current tab, passive points used), whether it has unsaved changes and in which parts, whether a dialog is open, "
		.. "and whether Path of Building is logged in to a Path of Exile account (needed by import_character). "
		.. "Call it first, and again whenever you are unsure what the window shows.",
	readOnly = true,
	idempotent = true,
	needsBuild = false,
	run = function(args)
		local status = {
			version = launch.versionNumber,
			devMode = launch.devMode and true or false,
			screen = main.mode == "BUILD" and "build" or "build list",
			dialogOpen = main.popups[1] ~= nil,
			itemDatabaseReady = main.uniqueDB.loading == nil and main.rareDB.loading == nil,
			pathOfExileLogin = main.api and main.api.authToken ~= nil or false,
			buildFolder = main.buildPath,
		}
		local build = main.modes["BUILD"]
		if main.mode == "BUILD" and build.targetVersion and build.spec then
			status.build = T.BuildSummary(build)
		end
		return status
	end,
}

T.Tool {
	name = "builds_list",
	title = "List saved builds",
	description = "Lists the builds saved in Path of Building's builds folder, with their class, ascendancy and level, "
		.. "the same list the build screen shows (sort 'edited' puts the most recently saved first). Without search it lists one folder (the top folder unless 'folder' is given); with "
		.. "search it looks through every folder, using PoB's own filter (words match the name, folder or class; 'class:Witch' matches "
		.. "the class or ascendancy only). Pass a build's 'path' to build_open to open it.",
	readOnly = true,
	idempotent = true,
	needsBuild = false,
	input = {
		folder = { type = "string", description = "Folder inside the builds folder, for example 'Leveling/'. Default: the top folder." },
		search = { type = "string", description = "Filter text, as in PoB's build list search box." },
		sort = { type = "string", enum = { "name", "class", "edited", "level" }, description = "Sort order (default name; edited = most recent first)." },
		limit = T.PageArgs(50).limit,
		offset = T.PageArgs(50).offset,
	},
	run = function(args)
		local folder = buildFolderPath(args.folder, "folder")
		if folder ~= "" and not folder:match("/$") then
			folder = folder .. "/"
		end
		local index = buildListHelpers.ScanFolder("")
		local list = buildListHelpers.FilterList(index, folder, args.search)
		buildListHelpers.SortList(list, (args.sort or "name"):upper())
		local entries = { }
		for _, entry in ipairs(list) do
			if entry.folderName then
				t_insert(entries, { type = "folder", name = entry.folderName, folder = entry.subPath, path = entry.subPath .. entry.folderName .. "/" })
			else
				t_insert(entries, {
					type = "build",
					name = entry.buildName,
					folder = entry.subPath,
					path = entry.subPath .. entry.fileName,
					class = entry.className,
					ascendancy = entry.ascendClassName ~= "None" and entry.ascendClassName or nil,
					level = entry.level,
				})
			end
		end
		local page, paging = T.Page(entries, args, 50)
		return { buildFolder = main.buildPath, folder = folder, entries = page, page = paging }
	end,
}

T.Tool {
	name = "build_open",
	title = "Open a build",
	description = "Replaces the build open in Path of Building with another one, exactly like opening it from PoB's build list or "
		.. "Import/Export tab. Give exactly one source: 'path' (a saved build, as returned by builds_list), 'code' (a build share code "
		.. "or build XML), 'link' (a build link from a site PoB supports: pobb.in, pob.codes, poe.ninja, Maxroll, pastebin, rentry, "
		.. "poedb; PoB downloads it) or 'new' (an empty build). It refuses while the open build has unsaved changes unless "
		.. "discard_unsaved is true, which you may only pass when the user agreed to lose them. Builds opened from a code, link or "
		.. "'new' have no file until build_save gives them a name. To look at another build without leaving this one, use compare_builds.",
	destructive = true,
	needsBuild = false,
	replacesBuild = true,
	openWorld = true,
	input = {
		path = { type = "string", description = "A build file inside the builds folder, for example 'Leveling/My Witch.xml'." },
		code = { type = "string", description = "A build share code, or build XML." },
		link = { type = "string", description = "A build link, for example https://pobb.in/abc123." },
		new = { type = "boolean", description = "Open a new empty build." },
		class = { type = "string", description = "For a new build: the class, for example 'Witch'." },
		ascendancy = { type = "string", description = "For a new build: the ascendancy, for example 'Necromancer'." },
		name = { type = "string", description = "Name shown for a build opened from a code, link or 'new' (default 'Imported build' / 'Unnamed build')." },
		discard_unsaved = T.discardUnsavedArg,
	},
	run = function(args)
		local sources = 0
		for _, key in ipairs({ "path", "code", "link" }) do
			if args[key] ~= nil then
				sources = sources + 1
			end
		end
		if args.new then
			sources = sources + 1
		end
		if sources ~= 1 then
			T.Fail("Give exactly one of path, code, link or new.")
		end
		T.CheckCanReplaceBuild(args)
		local name = args.name and T.Sanitise(args.name) or nil
		if args.path then
			local relative = buildFolderPath(args.path, "path")
			if not relative:lower():match("%.xml$") then
				relative = relative .. ".xml"
			end
			local fullPath = main.buildPath .. relative
			local file = io.open(fullPath, "r")
			if not file then
				T.Fail("No build file '%s' in the builds folder; use builds_list to find it.", relative)
			end
			file:close()
			local build = T.SwitchToBuild(fullPath, relative:match("([^/]+)%.[xX][mM][lL]$"))
			return { opened = T.BuildSummary(build) }
		elseif args.code then
			local xml = T.DecodeBuildCode(args.code)
			local build = T.SwitchToBuild(false, name or "Imported build", xml)
			return { opened = T.BuildSummary(build) }
		elseif args.link then
			local link = args.link:gsub("^%s+", ""):gsub("%s+$", "")
			local site = T.FindBuildSite(link)
			if not site then
				local labels = { }
				for _, entry in ipairs(buildSites.websiteList) do
					t_insert(labels, entry.label)
				end
				T.Fail("Path of Building does not recognise that link. Supported sites: %s.", t_concat(labels, ", "))
			end
			return T.Defer(function(resolve)
				buildSites.DownloadBuild(link, site, function(isSuccess, data)
					if not isSuccess then
						return resolve(nil, s_format("Could not download the build from %s: %s", site.label, tostring(data)))
					end
					T.Settle(resolve, function()
						-- The user may have changed something while the download ran.
						T.CheckCanReplaceBuild(args)
						local xml = T.DecodeBuildCode(data)
						local build = T.SwitchToBuild(false, name or "Imported build", xml, false, link)
						return { opened = T.BuildSummary(build), source = site.label }
					end)
				end)
			end, 60)
		else
			local build = T.SwitchToBuild(false, name or "Unnamed build")
			if args.class or args.ascendancy then
				T.SelectClass(build, args.class, args.ascendancy, false)
				build:ProcessBuildFlag()
			end
			return { opened = T.BuildSummary(build) }
		end
	end,
}

-- Set the class and ascendancy as the top bar's dropdowns do.
-- resetTree: whether changing to an unconnected class may reset the tree.
function T.SelectClass(build, className, ascendancyName, resetTree)
	local spec = build.spec
	if className then
		local classId
		for id, class in pairs(spec.tree.classes) do
			if class.name:lower() == className:lower() then
				classId = id
			end
		end
		if not classId then
			local names = { }
			for _, class in pairs(spec.tree.classes) do
				t_insert(names, class.name)
			end
			table.sort(names)
			T.Fail("Unknown class '%s'. Classes: %s", className, t_concat(names, ", "))
		end
		if classId ~= spec.curClassId then
			if spec:CountAllocNodes() == 0 or spec:IsClassConnected(classId) then
				spec:SelectClass(classId)
			elseif resetTree then
				spec:SelectClass(classId)
			else
				T.Fail("Changing the class to %s resets the passive tree, because the tree does not reach that class's start. "
					.. "Pass reset_tree: true if the user agreed, or allocate a path to the class first.", className)
			end
			spec:AddUndoState()
			spec:SetWindowTitleWithBuildClass()
			build.buildFlag = true
		end
	end
	if ascendancyName then
		local ascendClassId
		local names = { }
		for id, ascendClass in pairs(spec.curClass.classes) do
			t_insert(names, ascendClass.name)
			if ascendClass.name:lower() == ascendancyName:lower() then
				ascendClassId = id
			end
		end
		if not ascendClassId then
			T.Fail("%s has no ascendancy '%s'. Ascendancies: %s", spec.curClassName, ascendancyName, t_concat(names, ", "))
		end
		if ascendClassId ~= spec.curAscendClassId then
			spec:SelectAscendClass(ascendClassId)
			spec:AddUndoState()
			spec:SetWindowTitleWithBuildClass()
			build.buildFlag = true
		end
	end
end

T.Tool {
	name = "build_save",
	title = "Save the build",
	description = "Saves the open build, like PoB's Save and Save As buttons. Without 'name' it saves to the build's own file "
		.. "(a build opened from a code, link or 'new' has none: give a name). With 'name' it saves a copy under that name in the builds "
		.. "folder (optionally in 'folder') and the window then works on that file. It never replaces a different existing file unless "
		.. "overwrite is true. This is the only tool that writes build files.",
	destructive = true,
	idempotent = true,
	input = {
		name = { type = "string", description = "Save as this build name (the file name without .xml)." },
		folder = { type = "string", description = "Folder inside the builds folder for 'name' (must exist). Default: the build's current folder, or the top folder." },
		overwrite = { type = "boolean", description = "Allow replacing an existing different build file with the same name." },
	},
	run = function(args)
		local build = T.Build()
		if args.name then
			local name = T.Sanitise(args.name):gsub("[\\/:%*%?\"<>|%c]", "-")
			if not name:match("%S") then
				T.Fail("name must not be empty")
			end
			local folder = args.folder and buildFolderPath(args.folder, "folder") or (build.dbFileSubPath or "")
			if folder ~= "" and not folder:match("/$") then
				folder = folder .. "/"
			end
			if folder ~= "" and not NewFileSearch(main.buildPath .. folder:gsub("/$", ""), true) then
				T.Fail("There is no folder '%s' in the builds folder.", folder)
			end
			local fileName = main.buildPath .. folder .. name .. ".xml"
			local existing = io.open(fileName, "r")
			if existing then
				existing:close()
				if fileName ~= build.dbFileName and not args.overwrite then
					T.Fail("A build named '%s' already exists in that folder. Choose another name, or pass overwrite: true if the user wants to replace it.", name)
				end
			end
			build.dbFileName = fileName
			build.buildName = name
			build.dbFileSubPath = folder
		elseif not build.dbFileName then
			T.Fail("This build has no file yet (it was opened from a code, a link or as new). Give a name to save it.")
		end
		if build:SaveDBFile() then
			T.Fail("Path of Building could not write %s; check the folder exists and is writable.", build.dbFileName)
		end
		build.spec:SetWindowTitleWithBuildClass()
		return { saved = (build.dbFileSubPath or "") .. build.buildName .. ".xml", build = T.BuildSummary(build) }
	end,
}

T.Tool {
	name = "build_export",
	title = "Export the build",
	description = "Returns the open build as a Path of Building share code (what Import/Export's Generate button produces; other "
		.. "PoB users can import it) or as the XML PoB saves. Includes unsaved changes. Nothing is uploaded.",
	readOnly = true,
	idempotent = true,
	input = {
		format = { type = "string", enum = { "code", "xml" }, description = "code (default) or xml." },
	},
	run = function(args)
		local build = T.Build()
		local xml = build:SaveDB("code")
		if not xml then
			T.Fail("Path of Building could not compose the build.")
		end
		if args.format == "xml" then
			return { format = "xml", xml = xml }
		end
		return { format = "code", code = T.EncodeBuildCode(xml) }
	end,
}

-- Raw output values for a list of field names.
local function outputValues(output, fields)
	local values, missing = { }, { }
	for _, field in ipairs(fields) do
		local value = output[field]
		if type(value) == "number" then
			values[field] = T.Round(value)
		elseif type(value) == "boolean" or type(value) == "string" then
			values[field] = value
		else
			t_insert(missing, field)
		end
	end
	return T.Object(values), missing
end

-- The side bar as PoB shows it (Build:RefreshStatList fills controls.statBox).
local function sidebarLines(build)
	local lines = { }
	for _, row in ipairs(build.controls.statBox.list) do
		if row[1] then
			local label = T.Clean(row[1]):gsub(":$", "")
			if row[2] then
				t_insert(lines, { label = label, value = T.Clean(row[2]) })
			elseif label:match("%S") then
				t_insert(lines, { label = label })
			end
		end
	end
	return lines
end

local function warnings(build)
	local list = { }
	for _, line in ipairs(build.controls.warnings.lines or { }) do
		t_insert(list, T.Clean(line))
	end
	return list
end

T.Tool {
	name = "build_stats",
	title = "Build stats",
	description = "Returns the open build's stats as Path of Building calculates them: the side bar exactly as PoB shows it (labels "
		.. "and formatted values, including the minion section), PoB's warnings (unmet requirements, not enough mana, too many "
		.. "jewels, ...), the main skill, and raw numbers for a set of key output fields. Pass 'fields' to get other raw output values by "
		.. "their PoB name (for example 'BleedDPS', 'IgniteDPS', 'ManaCost', 'LifeLeechGainRate'); fields PoB did not calculate for "
		.. "this build are listed under 'missing'. The numbers depend on the Config tab (enemy, buffs, conditions): see config_get.",
	readOnly = true,
	idempotent = true,
	input = {
		fields = { type = "array", items = { type = "string" }, maxItems = 100, description = "Output field names to return raw values for (default: a set of key offence and defence fields)." },
		sidebar = { type = "boolean", description = "Include the formatted side bar (default true)." },
		minion = { type = "boolean", description = "Return the raw fields from the minion's output instead of the player's." },
	},
	run = function(args)
		local build = T.Build()
		build:ProcessBuildFlag()
		local output = build.calcsTab.mainOutput
		if args.minion then
			output = output.Minion
			if not output then
				T.Fail("The main skill has no minion.")
			end
		end
		local values, missing = outputValues(output, args.fields or DEFAULT_FIELDS)
		local result = {
			build = T.BuildSummary(build),
			values = values,
			warnings = T.Array(warnings(build)),
		}
		if args.fields and missing[1] then
			result.missing = missing
		end
		if args.sidebar ~= false then
			result.sidebar = T.Array(sidebarLines(build))
		end
		return result
	end,
}

T.Tool {
	name = "build_edit",
	title = "Edit level and notes",
	description = "Changes the character level (as the level box in the top bar does, which switches level mode to Manual) or "
		.. "the build's notes (Notes tab). The change shows in the window and marks the build unsaved. Class and ascendancy are "
		.. "changed with tree_edit; bandit and pantheon are Config options (config_set).",
	idempotent = true,
	modifies = true,
	input = {
		level = { type = "integer", minimum = 1, maximum = 100, description = "Character level." },
		auto_level = { type = "boolean", description = "true: let PoB estimate the level from passive points (Auto mode)." },
		notes = { type = "string", maxLength = 100000, description = "Replace the notes with this text. PoB colour codes (^1-^9, ^xRRGGBB) work." },
		append_notes = { type = "string", maxLength = 100000, description = "Add this text at the end of the notes." },
	},
	run = function(args, ctx)
		local build = T.Build()
		local result = { }
		if args.level then
			build.controls.characterLevel:SetText(tostring(args.level), true)
			ctx:Changed()
		end
		if args.auto_level ~= nil and args.auto_level ~= build.characterLevelAutoMode then
			build.controls.levelScalingButton.onClick()
			ctx:Changed()
		end
		if args.notes or args.append_notes then
			local edit = build.notesTab.controls.edit
			build.notesTab:SetShowColorCodes(false)
			local text = args.notes or edit.buf
			if args.append_notes then
				text = text .. (text ~= "" and "\n" or "") .. args.append_notes
			end
			local clean, changed = T.Sanitise(text)
			edit:SetText(clean)
			if changed then
				result.note = "Characters Path of Building cannot display were replaced."
			end
			ctx:Changed()
		end
		build:ProcessBuildFlag()
		result.level = build.characterLevel
		result.levelMode = build.characterLevelAutoMode and "auto" or "manual"
		if args.notes or args.append_notes then
			result.notesLength = #build.notesTab.controls.edit.buf
		end
		return result
	end,
}

------------------------------------------------------------------------------
-- What-if calculations
------------------------------------------------------------------------------

-- Look up a passive node by id or name (names must be unique on the tree).
function T.FindNode(spec, ref)
	local id = tonumber(ref)
	if id then
		local node = spec.nodes[id]
		if not node then
			T.Fail("There is no passive node with id %d on this tree.", id)
		end
		return node
	end
	local wanted = tostring(ref):lower()
	local matches = { }
	for _, node in pairs(spec.nodes) do
		if node.dn and node.dn:lower() == wanted and node.type ~= "ClassStart" and node.type ~= "AscendClassStart" then
			t_insert(matches, node)
		end
	end
	if #matches == 0 then
		T.Fail("No passive node is named '%s'; find it with tree_search.", tostring(ref))
	elseif #matches > 1 then
		-- Prefer the one this build can reach, as the tree's hover would.
		local reachable = { }
		for _, node in ipairs(matches) do
			if node.alloc or node.path then
				t_insert(reachable, node)
			end
		end
		if #reachable == 1 then
			return reachable[1]
		end
		local ids = { }
		for _, node in ipairs(matches) do
			t_insert(ids, tostring(node.id))
		end
		T.Fail("Several passive nodes are named '%s' (ids %s); pass the id instead.", tostring(ref), t_concat(ids, ", "))
	end
	return matches[1]
end

-- Requirements the calculated build does not meet (CalcPerform's Req* outputs).
function T.UnmetRequirements(output)
	local unmet = { }
	for _, attr in ipairs(REQUIREMENT_ATTRIBUTES) do
		local required = output["Req" .. attr]
		if type(required) == "number" and required > (output[attr] or 0) then
			local source = output["Req" .. attr .. "Item"]
			local from
			if type(source) == "table" then
				from = source.source == "Item" and source.sourceItem and source.sourceItem.name
					or source.source == "Gem" and source.sourceGem and source.sourceGem.nameSpec or nil
			end
			t_insert(unmet, { attribute = attr, required = required, have = output[attr] or 0, from = from })
		end
	end
	return unmet
end

-- Before/after/delta for a list of fields.
function T.CompareValues(before, after, fields)
	local values = { }
	for _, field in ipairs(fields) do
		local a, b = T.Number(before[field]), T.Number(after[field])
		if a or b then
			values[field] = { before = T.Round(a or 0), after = T.Round(b or 0), change = T.Round((b or 0) - (a or 0)) }
		end
	end
	return T.Object(values)
end

-- An item from its text, prepared as the Items tab prepares a pasted item
-- (ItemsTab:CreateDisplayItemFromRaw with normalise).
-- slotName: the slot the item is meant for, whose anoint and eldritch implicits are copied (as the Items tab does).
function T.ParseItem(build, text, slotName)
	if type(text) ~= "string" or not text:match("%S") then
		T.Fail("item text is empty")
	end
	local item = new("Item"):Item((T.Sanitise((text:gsub("\r\n", "\n")))))
	if not item.base then
		T.Fail("Path of Building could not read that item (unknown base type). Use the item text as copied from the game or from PoB.")
	end
	build.itemsTab:CopyAnointsAndEldritchImplicits(item, main.migrateEldritchImplicits, false, slotName)
	item:NormaliseQuality()
	item:BuildModList()
	return item
end

-- The item slot control for a slot name ("Helmet", "Ring 1", "Flask 2", a jewel socket label ...).
function T.FindSlot(build, slotName)
	local itemsTab = build.itemsTab
	local slot = itemsTab.slots[slotName]
	if slot then
		return slot
	end
	return T.Find(itemsTab.orderedSlots, slotName, function(candidate)
		if candidate.inactive or (candidate.shown and not candidate.shown()) then
			return nil
		end
		return candidate.label or candidate.slotName
	end, "item slot")
end

T.Tool {
	name = "simulate",
	title = "Simulate a change",
	description = "Calculates what a change would do to the open build, without changing it: equipping an item (its text, as "
		.. "copied from the game or PoB) in a slot or removing one, allocating or removing passive nodes, and switching a flask on "
		.. "or off; any of these can be combined in one call (one item per call). It uses PoB's own what-if calculator, the same "
		.. "one behind its hover tooltips: 'changes' lists the side-bar stats that change, as PoB words them in tooltips, 'values' gives "
		.. "raw before/after numbers, and 'unmetRequirements' lists attribute requirements the result would not meet. Adding a node "
		.. "also adds the path to it, as clicking it on the tree would. Use it to rank items or passives before recommending them.",
	readOnly = true,
	idempotent = true,
	input = {
		slot = { type = "string", description = "Equipment slot for 'item' or 'remove_item', for example 'Body Armour', 'Ring 2', 'Weapon 1', 'Flask 3'." },
		item = { type = "string", maxLength = 20000, description = "Item text to put in 'slot'." },
		remove_item = { type = "boolean", description = "Simulate removing the item in 'slot'." },
		add_nodes = { type = "array", items = { type = { "string", "integer" } }, maxItems = 50, description = "Passive nodes to allocate (names or ids)." },
		remove_nodes = { type = "array", items = { type = { "string", "integer" } }, maxItems = 50, description = "Allocated passive nodes to remove (with the nodes that depend on them)." },
		toggle_flask = { type = "integer", minimum = 1, maximum = 5, description = "Flask slot number to switch on or off." },
		fields = { type = "array", items = { type = "string" }, maxItems = 100, description = "Output fields to report before/after (default: key offence and defence fields)." },
	},
	run = function(args)
		local build = T.Build()
		build:ProcessBuildFlag()
		local itemsTab = build.itemsTab
		local spec = build.spec
		local calcFunc, calcBase = build.calcsTab:GetMiscCalculator()
		local override = { }
		local described = { }
		if args.item or args.remove_item then
			if not args.slot then
				T.Fail("slot is required with item or remove_item")
			end
			local slot = T.FindSlot(build, args.slot)
			local item
			if args.remove_item then
				item = itemsTab.items[slot.selItemId]
				if not item then
					T.Fail("Nothing is equipped in %s.", slot.label or slot.slotName)
				end
				t_insert(described, "remove " .. item.name .. " from " .. (slot.label or slot.slotName))
			else
				item = T.ParseItem(build, args.item, slot.slotName)
				if not itemsTab:IsItemValidForSlot(item, slot.slotName) then
					T.Fail("%s cannot be equipped in %s.", item.name, slot.label or slot.slotName)
				end
				local replaced = itemsTab.items[slot.selItemId]
				t_insert(described, "equip " .. item.name .. " in " .. (slot.label or slot.slotName) .. (replaced and (" replacing " .. replaced.name) or ""))
			end
			local slotOverride = itemsTab:GetSlotReplacementOverride(slot, item)
			for k, v in pairs(slotOverride) do
				override[k] = v
			end
		end
		if args.add_nodes and args.add_nodes[1] then
			override.addNodes = { }
			for _, ref in ipairs(args.add_nodes) do
				local node = T.FindNode(spec, ref)
				if node.alloc then
					T.Fail("%s is already allocated.", node.dn)
				end
				if not node.path then
					T.Fail("%s cannot be reached from this build's tree.", node.dn)
				end
				for _, pathNode in ipairs(node.path) do
					override.addNodes[pathNode] = true
				end
				t_insert(described, s_format("allocate %s (%d point%s)", node.dn, #node.path, #node.path == 1 and "" or "s"))
			end
		end
		if args.remove_nodes and args.remove_nodes[1] then
			override.removeNodes = { }
			for _, ref in ipairs(args.remove_nodes) do
				local node = T.FindNode(spec, ref)
				if not node.alloc then
					T.Fail("%s is not allocated.", node.dn)
				end
				for _, depNode in ipairs(node.depends) do
					override.removeNodes[depNode] = true
				end
				t_insert(described, s_format("remove %s (%d point%s)", node.dn, #node.depends, #node.depends == 1 and "" or "s"))
			end
		end
		if args.toggle_flask then
			local slot = itemsTab.slots["Flask " .. args.toggle_flask]
			local flask = slot and itemsTab.items[slot.selItemId]
			if not flask then
				T.Fail("No flask is equipped in Flask %d.", args.toggle_flask)
			end
			override.toggleFlask = flask
			t_insert(described, (build.calcsTab.mainEnv.flasks[flask] and "switch off " or "switch on ") .. flask.name)
		end
		if not described[1] then
			T.Fail("Nothing to simulate: give item/remove_item with slot, add_nodes, remove_nodes or toggle_flask.")
		end
		local output = calcFunc(override)
		local collector = T.LineCollector()
		build:AddStatComparesToTooltip(collector, calcBase, output, "Changes:")
		local changes = { }
		for _, line in ipairs(collector.lines) do
			if line ~= "Changes:" then
				t_insert(changes, line)
			end
		end
		return {
			simulated = described,
			changes = T.Array(changes),
			values = T.CompareValues(calcBase, output, args.fields or DEFAULT_FIELDS),
			unmetRequirements = T.Array(T.UnmetRequirements(output)),
			unmetRequirementsNow = T.Array(T.UnmetRequirements(calcBase)),
		}
	end,
}

T.DEFAULT_FIELDS = DEFAULT_FIELDS
