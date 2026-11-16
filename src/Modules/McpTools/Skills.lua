-- Path of Building
--
-- Module: MCP Tools - Skills
-- The Skills tab: socket groups and their gems, the main skill, the spectre
-- library, skill sets, and support gems ranked by the gem selector's DPS sort.
--
local T = ...

local t_insert = table.insert
local t_concat = table.concat

-- The name dialogs of the set lists (SkillSetListControl/ConfigSetListControl:RenameSet) take at most 100 characters.
local SET_TITLE_MAX = 100

-- A gem line of SkillsTab:PasteSocketGroup ("Fireball 20/0  1", "Added Fire Damage 20/20 DISABLED 1").
local PASTE_GEM_PATTERN = "([ %a']+) (%d+)/(%d+) ?(%a*) (%d+)"

-- GemSelectControl:OnKeyDown: the gem type buttons set sortGemsBy to these tags.
local GEM_TYPE_TAGS = { support = "support", active = "grants_active_skill" }

local function grantedEffectOf(gem)
	return gem.grantedEffect or (gem.gemData and gem.gemData.grantedEffect)
end

-- The name the Skills tab shows for a gem (SkillsTab:AddSocketGroupTooltip).
local function gemName(gem)
	return T.Clean((gem.grantedEffect and gem.grantedEffect.name) or (gem.gemData and gem.gemData.name) or gem.nameSpec or "?")
end

-- The name the Skills tab shows for a socket group (CalcSetup sets displayLabel).
local function groupName(group)
	if group.displayLabel then
		return T.Clean(group.displayLabel)
	end
	return group.label and group.label:match("%S") and T.Clean(group.label) or "<No active skills>"
end

-- A dropdown entry's text.
local function dropLabel(entry)
	if type(entry) == "table" then
		return T.Clean(entry.label or tostring(entry.val))
	end
	return T.Clean(tostring(entry))
end

--- The socket group a client means: its index in the active skill set, or its label.
local function findGroup(skillsTab, ref)
	local list = skillsTab.socketGroupList
	if ref == nil then
		T.Fail("Give the socket group (its index or label, as skills_get lists them).")
	end
	if type(ref) == "number" then
		if not list[ref] then
			T.Fail("There is no socket group %d; the active skill set has %d socket group%s (see skills_get).", ref, #list, #list == 1 and "" or "s")
		end
		return list[ref], ref
	end
	local group = T.Find(list, ref, groupName, "socket group")
	return group, isValueInArray(list, group)
end

--- A gem of a socket group: its position in the group, or its name.
local function findGem(group, ref)
	if ref == nil then
		T.Fail("Give the gem (its position in the group or its name).")
	end
	if type(ref) == "number" then
		if not group.gemList[ref] then
			T.Fail("Socket group '%s' has no gem %d; it has %d gem%s.", groupName(group), ref, #group.gemList, #group.gemList == 1 and "" or "s")
		end
		return group.gemList[ref], ref
	end
	local gem = T.Find(group.gemList, ref, gemName, "gem in '" .. groupName(group) .. "'")
	return gem, isValueInArray(group.gemList, gem)
end

local function gemSummary(gem, index)
	local effect = grantedEffectOf(gem)
	local entry = {
		index = index,
		name = gemName(gem),
		level = gem.level,
		quality = gem.quality,
		enabled = gem.enabled ~= false,
		count = gem.count or 1,
		type = not effect and "unknown" or effect.support and "support" or "active",
		error = gem.errMsg and T.Clean(gem.errMsg) or nil,
	}
	-- The level and quality the calculation used, when items or supports raise them.
	local display = gem.displayEffect
	if display and display.level and display.level ~= gem.level then
		entry.effectiveLevel = display.level
	end
	if display and display.quality and display.quality ~= gem.quality then
		entry.effectiveQuality = display.quality
	end
	return entry
end

-- Where a group PoB adds by itself comes from (SkillsTab's sourceNote).
local function groupSource(group)
	if not group.source then
		return nil
	end
	if group.explodeSources then
		local names = { }
		for _, source in ipairs(group.explodeSources) do
			t_insert(names, T.Clean(source.name or source.dn or "?"))
		end
		return "enemy explosion from " .. t_concat(names, ", ")
	end
	if group.sourceItem then
		return T.Clean(group.sourceItem.name)
	elseif group.sourceNode then
		return T.Clean(group.sourceNode.name or group.sourceNode.dn)
	elseif group.source == "Config" then
		return "Custom Modifiers"
	end
	return T.Clean(tostring(group.source))
end

local function groupSummary(build, group, index, details)
	local gems = { }
	for gemIndex, gem in ipairs(group.gemList) do
		t_insert(gems, gemSummary(gem, gemIndex))
	end
	local activeSkills = { }
	for _, activeSkill in ipairs(group.displaySkillList or { }) do
		local effect = activeSkill.activeEffect
		if effect and effect.grantedEffect then
			t_insert(activeSkills, T.Clean(effect.grantedEffect.name))
		end
	end
	local summary = {
		index = index,
		label = groupName(group),
		slot = group.slot,
		enabled = group.enabled and true or false,
		includeInFullDPS = group.includeInFullDPS and true or false,
		main = build.mainSocketGroup == index,
		activeSkills = T.Array(activeSkills),
		gems = T.Array(gems),
		grantedBy = groupSource(group),
	}
	if group.enabled and group.slotEnabled == false then
		summary.inactiveWeaponSet = true
	end
	if details and group.displaySkillList then
		-- PoB's own description of the group: active skills, and why other gems are inactive.
		local collector = T.LineCollector()
		build.skillsTab:AddSocketGroupTooltip(collector, group)
		summary.details = T.Array(collector.lines)
	end
	return summary
end

local function skillSetList(skillsTab)
	local sets = { }
	for _, id in ipairs(skillsTab.skillSetOrderList) do
		local set = skillsTab.skillSets[id]
		t_insert(sets, { id = id, title = T.Clean(set.title or "Default"), active = id == skillsTab.activeSkillSetId, socketGroups = #set.socketGroupList })
	end
	return sets
end

local function spectreList(build)
	local list = { }
	for _, id in ipairs(build.spectreList) do
		local minion = build.data.minions[id]
		t_insert(list, { id = id, name = minion and minion.name or id })
	end
	return T.Array(list)
end

-- The sidebar's main skill controls, as PoB fills them every frame.
local function refreshMainSkillControls(build)
	build:ProcessBuildFlag()
	if build.skillsTab.socketGroupList[build.mainSocketGroup] then
		build:RefreshSkillSelectControls(build.controls, build.mainSocketGroup, "")
	end
end

local function mainSkillSummary(build)
	refreshMainSkillControls(build)
	local controls = build.controls
	local group = build.skillsTab.socketGroupList[build.mainSocketGroup]
	if not group then
		return { note = "There are no socket groups in the active skill set." }
	end
	local result = { group = build.mainSocketGroup, groupLabel = groupName(group) }
	local function options(control)
		local list = { }
		for _, entry in ipairs(control.list) do
			t_insert(list, dropLabel(entry))
		end
		return T.Array(list)
	end
	if controls.mainSkill.shown and controls.mainSkill.list[1] then
		result.activeSkill = dropLabel(controls.mainSkill.list[controls.mainSkill.selIndex] or controls.mainSkill.list[1])
		result.activeSkills = options(controls.mainSkill)
	else
		result.note = "The main socket group has no active skill."
	end
	if controls.mainSkillPart.shown then
		result.skillPart = dropLabel(controls.mainSkillPart.list[controls.mainSkillPart.selIndex] or "")
		result.skillParts = options(controls.mainSkillPart)
	end
	if controls.mainSkillStageCount.shown then
		result.stageCount = tonumber(controls.mainSkillStageCount.buf)
	end
	if controls.mainSkillMineCount.shown then
		result.activeMines = tonumber(controls.mainSkillMineCount.buf)
	end
	if controls.mainSkillMinion.shown then
		local selected = controls.mainSkillMinion.list[controls.mainSkillMinion.selIndex]
		result.minion = selected and dropLabel(selected) or nil
		result.minions = options(controls.mainSkillMinion)
		if type(selected) == "table" and selected.itemSetId then
			result.minionChosenBy = "item set"
		end
		if controls.mainSkillMinionLibrary.shown then
			result.usesSpectreLibrary = true
		end
	end
	if controls.mainSkillMinionSkill.shown then
		result.minionSkill = dropLabel(controls.mainSkillMinionSkill.list[controls.mainSkillMinionSkill.selIndex] or "")
		result.minionSkills = options(controls.mainSkillMinionSkill)
	end
	return result
end

--- Pick an entry of one of PoB's dropdowns by position or text, as clicking it does.
local function selectDropDown(control, ref, what, idKey)
	local index
	if type(ref) == "number" then
		index = ref
		if not control.list[index] then
			T.Fail("There is no %s %d; there are %d.", what, ref, #control.list)
		end
	else
		for i, entry in ipairs(control.list) do
			if idKey and type(entry) == "table" and entry[idKey] == ref then
				index = i
			end
		end
		if not index then
			local entries = { }
			for i, entry in ipairs(control.list) do
				t_insert(entries, { index = i, label = dropLabel(entry) })
			end
			index = T.Find(entries, ref, function(entry) return entry.label end, what).index
		end
	end
	if type(control.list[index]) ~= "table" and idKey then
		T.Fail("'%s' is not a %s that can be chosen.", dropLabel(control.list[index]), what)
	end
	if index ~= control.selIndex then
		control.selIndex = index
		control.selFunc(index, control.list[index])
		return true
	end
	return false
end

--- Manage a list of sets (skill sets, config sets) through PoB's own set list
--- control and its dialogs, exactly as the "Manage..." dialog does.
--- opts: control (a SkillSetListControl or ConfigSetListControl), sets (id -> set),
---   order (list of ids), activeId (function), what ("skill set"), action, ref, title
function T.ManageSetList(opts)
	local control, sets, order, what = opts.control, opts.sets, opts.order, opts.what
	local function setTitle(id)
		return sets[id] and (sets[id].title or "Default") or nil
	end
	local function find()
		if opts.ref == nil then
			T.Fail("Give the %s to %s: its id or title.", what, opts.action)
		end
		local id = opts.ref
		if type(id) == "number" then
			if not isValueInArray(order, id) then
				T.Fail("There is no %s with id %d.", what, id)
			end
		else
			id = T.Find(order, opts.ref, setTitle, what)
		end
		local index = isValueInArray(order, id)
		control.selIndex = index
		control.selValue = id
		return index, id
	end
	local function newTitle()
		if type(opts.title) ~= "string" or not opts.title:match("%S") then
			T.Fail("Give a title for the %s.", what)
		end
		local title = T.Sanitise((opts.title:gsub("[%c]", " ")))
		if #title > SET_TITLE_MAX then
			T.Fail("The title is too long (at most %d characters).", SET_TITLE_MAX)
		end
		return title
	end
	-- Fill PoB's name dialog (RenameSet) and press Save.
	local function enterName(title)
		local popup = main.popups[1]
		if not popup or not popup.controls.edit or not popup.controls.save then
			T.Fail("Path of Building did not open the name dialog for the %s.", what)
		end
		popup.controls.edit:SetText(title, true)
		popup.controls.save.onClick()
	end
	local action = opts.action
	if action == "select" then
		local index, id = find()
		if id == opts.activeId() then
			return { id = id, title = T.Clean(setTitle(id)), unchanged = true }
		end
		control:OnSelClick(index, id, true)
		return { id = id, title = T.Clean(setTitle(id)) }
	elseif action == "new" then
		local title = newTitle()
		control.controls.new.onClick()
		enterName(title)
		local id = order[#order]
		return { id = id, title = T.Clean(setTitle(id)) }
	elseif action == "copy" then
		local title = newTitle()
		local _, source = find()
		control.controls.copy.onClick()
		enterName(title)
		local id = order[#order]
		return { id = id, title = T.Clean(setTitle(id)), copiedFrom = source }
	elseif action == "rename" then
		local title = newTitle()
		local _, id = find()
		control.controls.rename.onClick()
		enterName(title)
		return { id = id, title = T.Clean(setTitle(id)) }
	elseif action == "delete" then
		local _, id = find()
		if #order <= 1 then
			T.Fail("The only %s cannot be deleted.", what)
		end
		local title = setTitle(id)
		control.controls.delete.onClick()
		local popup = main.popups[1]
		if not popup or not popup.controls.confirm then
			T.Fail("Path of Building did not ask to confirm deleting the %s.", what)
		end
		popup.controls.confirm.onClick()
		return { id = id, title = T.Clean(title), deleted = true }
	end
	T.Fail("Unknown %s action '%s'.", what, tostring(action))
end

-- The spectres a reference can mean: an id, or a name (unique, or exact).
local function findSpectre(build, candidates, ref)
	for _, id in ipairs(candidates) do
		if id == ref then
			return id
		end
	end
	local exact = { }
	for _, id in ipairs(candidates) do
		if build.data.minions[id].name:lower() == ref:lower() then
			t_insert(exact, id)
		end
	end
	if #exact > 1 then
		T.Fail("Several spectres are named '%s'; give the id instead: %s", ref, t_concat(exact, ", "))
	end
	return exact[1] or T.Find(candidates, ref, function(id) return build.data.minions[id].name end, "spectre")
end

------------------------------------------------------------------------------

T.Tool {
	name = "skills_get",
	title = "Skills tab",
	description = "Returns the Skills tab of the open build: every socket group of the active skill set (index, label, item slot, "
		.. "enabled, included in Full DPS, whether it is the main group, the active skills PoB found in it, where PoB-added groups come "
		.. "from) with its gems (name, level, quality, enabled, count, support or active, the level/quality the calculation actually used "
		.. "when items raise them, and PoB's error for unrecognised or unsupported gems); the main skill selection of the side bar (group, "
		.. "active skill, skill part, stages, mines, minion and minion skill, with the choices each offers); the skill sets; and the "
		.. "spectres in the build. Pass 'group' (index or label) to get only that group with PoB's own explanation of why gems are "
		.. "inactive (for example a support that cannot apply). Use the indexes and names it returns with skills_edit.",
	readOnly = true,
	idempotent = true,
	input = {
		group = { type = { "integer", "string" }, description = "Only this socket group (index or label), with PoB's details of active and inactive gems." },
		details = { type = "boolean", description = "Include PoB's details (active skills, inactive gems and why) for every group." },
		spectre_search = { type = "string", maxLength = 100, description = "Also search the spectre library (all spectres PoB knows) by name, as its search box does; returns up to 50." },
	},
	run = function(args)
		local build = T.Build()
		build:ProcessBuildFlag()
		local skillsTab = build.skillsTab
		local result = {
			skillSet = T.Clean(skillsTab.skillSets[skillsTab.activeSkillSetId].title or "Default"),
			skillSets = skillSetList(skillsTab),
			mainSkill = mainSkillSummary(build),
			spectres = spectreList(build),
			gemDefaults = { level = skillsTab.defaultGemLevel, quality = skillsTab.defaultGemQuality or 0 },
		}
		if args.group ~= nil then
			local group, index = findGroup(skillsTab, args.group)
			result.groups = T.Array({ groupSummary(build, group, index, true) })
		else
			local groups = { }
			for index, group in ipairs(skillsTab.socketGroupList) do
				t_insert(groups, groupSummary(build, group, index, args.details))
			end
			result.groups = T.Array(groups)
		end
		if args.spectre_search then
			local sourceList = { }
			for id in pairs(build.data.spectres) do
				t_insert(sourceList, id)
			end
			-- Ordered as buildMode:OpenSpectreLibrary orders the library.
			local minions = build.data.minions
			table.sort(sourceList, function(a, b)
				if minions[a].name == minions[b].name then
					return a < b
				end
				return minions[a].name < minions[b].name
			end)
			-- The spectre library's own search list filters the names.
			local dest = new("MinionListControl"):MinionListControl(nil, { 0, 0, 265, 250 }, build.data, copyTable(build.spectreList))
			local search = new("MinionSearchListControl"):MinionSearchListControl(nil, { 0, 0, 265, 230 }, build.data, sourceList, dest)
			search:ListFilterChanged(args.spectre_search, 1)
			local found = { }
			for _, id in ipairs(search.list) do
				if #found < 50 then
					t_insert(found, { id = id, name = build.data.minions[id].name, inBuild = isValueInArray(build.spectreList, id) and true or false })
				end
			end
			result.spectreLibrary = { total = #search.list, results = T.Array(found) }
		end
		return result
	end,
}

------------------------------------------------------------------------------

local EDIT_ACTIONS = {
	"add_group", "edit_group", "remove_group", "add_gem", "edit_gem", "remove_gem", "set_main", "set_spectres",
	"select_set", "new_set", "copy_set", "rename_set", "delete_set",
}

-- Paste a socket group in PoB's copy/paste format with SkillsTab:PasteSocketGroup,
-- which uses the given text instead of the clipboard.
local function pasteSocketGroup(skillsTab, text)
	skillsTab:PasteSocketGroup(text)
end

-- The gem a name means, as SkillsTab:FindSkillGem matches pasted names. Support gems are
-- named without the word "Support" there, so a name ending in it is tried without it too.
local function findGemData(skillsTab, name)
	local errMsg, gemData = skillsTab:FindSkillGem(name)
	if not gemData and name:lower():match("%ssupport$") then
		local _, withoutSuffix = skillsTab:FindSkillGem((name:gsub("%s+[Ss]upport$", "")))
		gemData = withoutSuffix
	end
	return gemData, errMsg and T.Clean(errMsg)
end

local function checkPasteText(skillsTab, text)
	text = T.Sanitise((text:gsub("\r\n", "\n")))
	if not text:match("\n$") then
		text = text .. "\n"
	end
	local unread, unknown, lines = { }, { }, { }
	local gems = 0
	for line in text:gmatch("([^\n]*)\n") do
		if line:match("%S") and not line:match("^Label: ") and not line:match("^Slot: ") then
			local name = line:match("^%s*(.-)%s+%d+/%d+")
			if line:match(PASTE_GEM_PATTERN) and name then
				gems = gems + 1
				local gemData, errMsg = findGemData(skillsTab, name)
				if gemData then
					line = line:gsub("^%s*(.-)(%s+%d+/%d+)", function(_, rest) return gemData.name .. rest end)
				else
					t_insert(unknown, errMsg)
				end
			else
				t_insert(unread, line)
			end
		end
		t_insert(lines, line)
	end
	text = t_concat(lines, "\n") .. "\n"
	if unknown[1] and not unread[1] then
		T.Fail("%s. Use gem names as Path of Building shows them.", t_concat(unknown, "; "))
	end
	if unread[1] or gems == 0 then
		T.Fail("Path of Building cannot read %s. Use its copy/paste format: optional 'Label: <label>' and 'Slot: <slot>' lines, then "
			.. "one line per gem: '<gem name> <level>/<quality> <count>', with DISABLED before the count for a disabled gem, for example "
			.. "'Slot: Body Armour\\nFireball 20/0 1\\nSpell Echo Support 20/0 1'.", unread[1] and ("'" .. unread[1] .. "'") or "any gem in that text")
	end
	local slot = text:match("Slot: (%C+)")
	if slot then
		local valid, names = false, { }
		for _, entry in ipairs(skillsTab.controls.groupSlot.list) do
			if entry.slotName then
				t_insert(names, entry.slotName)
				valid = valid or entry.slotName == slot
			end
		end
		if not valid then
			T.Fail("'%s' is not a slot a socket group can be in. Slots: %s", slot, t_concat(names, ", "))
		end
	end
	return text
end

-- Edits made through the Skills tab's group controls need the group on display.
local function showGroup(skillsTab, group)
	if group.source then
		T.Fail("Socket group '%s' is added by %s; Path of Building does not let you edit its gems.", groupName(group), groupSource(group))
	end
	if skillsTab.displayGroup ~= group then
		skillsTab:SetDisplayGroup(group)
	end
end

local function setGemFields(skillsTab, group, index, args)
	local gem = group.gemList[index]
	local slot = skillsTab.gemSlots[index]
	if args.level then
		slot.level:SetText(tostring(args.level), true)
	end
	if args.quality then
		slot.quality:SetText(tostring(args.quality), true)
	end
	if args.count then
		slot.count:SetText(tostring(args.count), true)
	end
	if args.enabled ~= nil and args.enabled ~= gem.enabled then
		if gem.gemData then
			slot.enabled.state = args.enabled
			slot.enabled.changeFunc(args.enabled)
		else
			-- The checkbox's callback needs gem data, which an unrecognised gem lacks; do the rest of what it does.
			gem.enabled = args.enabled
			skillsTab:ProcessSocketGroup(group)
			skillsTab:AddUndoState()
			skillsTab.build.buildFlag = true
		end
	end
end

local function editSpectres(build, args)
	if not (args.spectres or args.add_spectres or args.remove_spectres) then
		T.Fail("Give spectres (the whole list), add_spectres or remove_spectres.")
	end
	build:OpenSpectreLibrary()
	local popup = main.popups[1]
	local dest, source = popup.controls.list, popup.controls.source
	local removals = args.remove_spectres or { }
	if args.spectres then
		removals = copyTable(dest.list)
	end
	local added, removed = { }, { }
	for _, ref in ipairs(removals) do
		local id = findSpectre(build, dest.list, ref)
		dest.selIndex = isValueInArray(dest.list, id)
		dest.selValue = id
		dest:OnSelDelete(dest.selIndex, id)
		t_insert(removed, id)
	end
	for _, ref in ipairs(args.spectres or args.add_spectres or { }) do
		local id = findSpectre(build, source.unfilteredList, ref)
		if not isValueInArray(dest.list, id) then
			source.selValue = id
			source:AddSel()
			t_insert(added, id)
		end
	end
	popup.controls.save.onClick()
	return added, removed
end

local function editMainSkill(build, args)
	local skillsTab = build.skillsTab
	local controls = build.controls
	if args.group ~= nil then
		local _, index = findGroup(skillsTab, args.group)
		refreshMainSkillControls(build)
		selectDropDown(controls.mainSocketGroup, index, "socket group")
	end
	refreshMainSkillControls(build)
	if not skillsTab.socketGroupList[build.mainSocketGroup] then
		T.Fail("There are no socket groups to choose a main skill from.")
	end
	local function need(control, what)
		if not control.shown then
			T.Fail("The main skill has no %s to choose.", what)
		end
	end
	if args.active_skill ~= nil then
		need(controls.mainSkill, "active skill")
		selectDropDown(controls.mainSkill, args.active_skill, "active skill")
		refreshMainSkillControls(build)
	end
	if args.skill_part ~= nil then
		need(controls.mainSkillPart, "skill part")
		selectDropDown(controls.mainSkillPart, args.skill_part, "skill part")
		refreshMainSkillControls(build)
	end
	if args.stage_count ~= nil then
		need(controls.mainSkillStageCount, "stage count")
		controls.mainSkillStageCount:SetText(tostring(args.stage_count), true)
		refreshMainSkillControls(build)
	end
	if args.mine_count ~= nil then
		need(controls.mainSkillMineCount, "active mine count")
		controls.mainSkillMineCount:SetText(tostring(args.mine_count), true)
		refreshMainSkillControls(build)
	end
	if args.minion ~= nil then
		need(controls.mainSkillMinion, "minion")
		selectDropDown(controls.mainSkillMinion, args.minion, "minion", "minionId")
		refreshMainSkillControls(build)
	end
	if args.minion_skill ~= nil then
		need(controls.mainSkillMinionSkill, "minion skill")
		selectDropDown(controls.mainSkillMinionSkill, args.minion_skill, "minion skill")
		refreshMainSkillControls(build)
	end
end

T.Tool {
	name = "skills_edit",
	title = "Edit skills",
	description = "Changes the Skills tab of the open build through the same controls the user would use, one action per call. "
		.. "add_group: paste a socket group in PoB's copy/paste format ('text'). edit_group: label, slot, enabled, include_in_full_dps. "
		.. "remove_group. add_gem: 'gem' is the gem name (PoB matches it as it does pasted gems), optionally with level, quality, enabled, "
		.. "count. edit_gem: level, quality, enabled, count of 'gem' (name or position). remove_gem. set_main: the side bar's main skill "
		.. "(group, active_skill, skill_part, stage_count, mine_count, minion, minion_skill), as picking them in its dropdowns. "
		.. "set_spectres: replace (spectres) or change (add_spectres, remove_spectres) the spectres in the build, as the spectre library does. "
		.. "select_set/new_set/copy_set/rename_set/delete_set: skill sets ('set' is an id or title, 'title' the new name). Groups are "
		.. "identified by index or label and gems by name or position, as skills_get returns them; groups PoB adds from items or passives "
		.. "cannot have their gems edited. Returns the changed group or selection and the side-bar stat changes.",
	destructive = true,
	modifies = true,
	usesDialog = true,
	input = {
		action = { type = "string", enum = EDIT_ACTIONS, description = "What to change (see the description)." },
		group = { type = { "integer", "string" }, description = "Socket group: its index or label (skills_get)." },
		gem = { type = { "integer", "string" }, description = "Gem: its name, or its position in the group (edit_gem, remove_gem)." },
		text = { type = "string", maxLength = 5000, description = "add_group: the group in PoB's copy/paste format, for example "
			.. "'Label: Main\\nSlot: Body Armour\\nFireball 20/0 1\\nSpell Echo Support 20/20 1' (gem lines are '<name> <level>/<quality> <count>', "
			.. "with DISABLED before the count for a disabled gem)." },
		level = { type = "integer", minimum = 1, maximum = 99, description = "Gem level (PoB limits it to the levels the gem has)." },
		quality = { type = "integer", minimum = 0, maximum = 99, description = "Gem quality." },
		enabled = { type = "boolean", description = "Enable or disable the gem (add_gem, edit_gem) or the group (edit_group)." },
		count = { type = "integer", minimum = 1, maximum = 99, description = "Gem count: scales the skill's DPS (several totems, minions, projectiles hitting...)." },
		label = { type = "string", maxLength = 50, description = "edit_group: the group's label (empty to let PoB name it after its skills)." },
		slot = { type = "string", description = "edit_group: the item slot the group is socketed in ('None', 'Body Armour', 'Weapon 1', 'Weapon 1 (Swap)', 'Ring 1', ...)." },
		include_in_full_dps = { type = "boolean", description = "edit_group: include the group in Full DPS." },
		active_skill = { type = { "integer", "string" }, description = "set_main: the active skill of the group (name or position)." },
		skill_part = { type = { "integer", "string" }, description = "set_main: the skill part (name or position), for skills with several." },
		stage_count = { type = "integer", minimum = 0, maximum = 9999, description = "set_main: stages, for skills with stages." },
		mine_count = { type = "integer", minimum = 0, maximum = 9999, description = "set_main: active mines, for mine skills." },
		minion = { type = { "integer", "string" }, description = "set_main: the minion (name, id or position; an item set for skills whose minion uses one)." },
		minion_skill = { type = { "integer", "string" }, description = "set_main: the minion's skill (name or position)." },
		spectres = { type = "array", items = { type = "string" }, maxItems = 50, description = "set_spectres: the complete list of spectres (names or ids)." },
		add_spectres = { type = "array", items = { type = "string" }, maxItems = 50, description = "set_spectres: spectres to add (names or ids from the library)." },
		remove_spectres = { type = "array", items = { type = "string" }, maxItems = 50, description = "set_spectres: spectres to remove (names or ids)." },
		set = { type = { "integer", "string" }, description = "Skill set actions: the skill set (id or title)." },
		title = { type = "string", maxLength = SET_TITLE_MAX, description = "new_set, copy_set, rename_set: the set's name." },
	},
	required = { "action" },
	run = function(args, ctx)
		local build = T.Build()
		build:ProcessBuildFlag()
		local skillsTab = build.skillsTab
		local action = args.action
		local result = { action = action }

		if action:match("_set$") then
			local control = new("SkillSetListControl"):SkillSetListControl(nil, { 0, 0, 350, 200 }, skillsTab)
			local done = T.ManageSetList({
				control = control, sets = skillsTab.skillSets, order = skillsTab.skillSetOrderList, what = "skill set",
				activeId = function() return skillsTab.activeSkillSetId end,
				action = action:match("^(%a+)_set$"), ref = args.set, title = args.title,
			})
			if not done.unchanged then
				ctx:Changed()
			end
			build:ProcessBuildFlag()
			result.skillSet = done
			result.skillSets = skillSetList(skillsTab)
			return result
		end

		if action == "set_spectres" then
			local added, removed = editSpectres(build, args)
			ctx:Changed()
			build:ProcessBuildFlag()
			result.added = T.Array(added)
			result.removed = T.Array(removed)
			result.spectres = spectreList(build)
			return result
		end

		if action == "set_main" then
			editMainSkill(build, args)
			ctx:Changed()
			result.mainSkill = mainSkillSummary(build)
			return result
		end

		-- Group and gem edits go through the Skills tab's own controls; put its selection back afterwards.
		local shownGroup = skillsTab.displayGroup
		local listSel = skillsTab.controls.groupList.selValue
		local function restoreSelection()
			if shownGroup and isValueInArray(skillsTab.socketGroupList, shownGroup) then
				if skillsTab.displayGroup ~= shownGroup then
					skillsTab:SetDisplayGroup(shownGroup)
				end
				local groupList = skillsTab.controls.groupList
				groupList.selValue = listSel and isValueInArray(skillsTab.socketGroupList, listSel) and listSel or nil
				groupList.selIndex = groupList.selValue and isValueInArray(skillsTab.socketGroupList, groupList.selValue) or nil
			end
		end
		local ok, err = pcall(function()
			if action == "add_group" then
				if not args.text then
					T.Fail("Give the group as 'text' in PoB's copy/paste format.")
				end
				local text = checkPasteText(skillsTab, args.text)
				local before = #skillsTab.socketGroupList
				pasteSocketGroup(skillsTab, text)
				if #skillsTab.socketGroupList == before then
					T.Fail("Path of Building did not add a group from that text.")
				end
				ctx:Changed()
				result.index = #skillsTab.socketGroupList
			elseif action == "remove_group" then
				local group, index = findGroup(skillsTab, args.group)
				if group.source then
					T.Fail("Socket group '%s' is added by %s and cannot be deleted; it goes away with its source.", groupName(group), groupSource(group))
				end
				local groupList = skillsTab.controls.groupList
				groupList.selIndex = index
				groupList.selValue = group
				result.removed = groupName(group)
				groupList:OnSelDelete(index, group)
				local popup = main.popups[1]
				if popup and popup.controls.confirm then
					popup.controls.confirm.onClick()
				end
				if isValueInArray(skillsTab.socketGroupList, group) then
					T.Fail("Path of Building did not delete the group.")
				end
				ctx:Changed()
			elseif action == "edit_group" then
				local group, index = findGroup(skillsTab, args.group)
				if args.label == nil and args.slot == nil and args.enabled == nil and args.include_in_full_dps == nil then
					T.Fail("Give what to change: label, slot, enabled or include_in_full_dps.")
				end
				skillsTab:SetDisplayGroup(group)
				local controls = skillsTab.controls
				if args.label ~= nil then
					controls.groupLabel:SetText((T.Sanitise((args.label:gsub("%c", " ")))), true)
				end
				if args.slot ~= nil then
					if group.source then
						T.Fail("Socket group '%s' is added by %s; its slot cannot be changed.", groupName(group), groupSource(group))
					end
					local wanted
					for i, entry in ipairs(controls.groupSlot.list) do
						if entry.label:lower() == args.slot:lower() or (entry.slotName and entry.slotName:lower() == args.slot:lower()) then
							wanted = i
						end
					end
					if not wanted then
						local names = { }
						for _, entry in ipairs(controls.groupSlot.list) do
							t_insert(names, entry.label)
						end
						T.Fail("'%s' is not a socket group slot. Slots: %s", args.slot, t_concat(names, ", "))
					end
					if wanted ~= controls.groupSlot.selIndex then
						controls.groupSlot.selIndex = wanted
						controls.groupSlot.selFunc(wanted, controls.groupSlot.list[wanted])
					end
				end
				if args.enabled ~= nil and args.enabled ~= (group.enabled and true or false) then
					controls.groupEnabled.state = args.enabled
					controls.groupEnabled.changeFunc(args.enabled)
				end
				if args.include_in_full_dps ~= nil and args.include_in_full_dps ~= (group.includeInFullDPS and true or false) then
					controls.includeInFullDPS.state = args.include_in_full_dps
					controls.includeInFullDPS.changeFunc(args.include_in_full_dps)
				end
				ctx:Changed()
				result.index = index
			elseif action == "add_gem" then
				local group, index = findGroup(skillsTab, args.group)
				if type(args.gem) ~= "string" then
					T.Fail("Give the name of the gem to add as 'gem'.")
				end
				local gemData, errMsg = findGemData(skillsTab, (T.Sanitise(args.gem)))
				if not gemData then
					T.Fail("%s. Use the gem's name as Path of Building shows it, for example 'Spell Echo'.", errMsg)
				end
				if gemData.grantedEffect.unsupported then
					T.Fail("Path of Building does not support %s yet.", gemData.name)
				end
				showGroup(skillsTab, group)
				local gemIndex = #group.gemList + 1
				skillsTab:UpdateGemSlots()
				local slot = skillsTab.gemSlots[gemIndex]
				-- As choosing the gem in the gem slot's dropdown.
				slot.nameSpec:SetText(gemData.name)
				slot.nameSpec.gemChangeFunc(gemData.id, true, false, true)
				if not group.gemList[gemIndex] then
					T.Fail("Path of Building did not add %s.", gemData.name)
				end
				setGemFields(skillsTab, group, gemIndex, args)
				ctx:Changed()
				result.index = index
				result.gem = gemIndex
			elseif action == "edit_gem" then
				local group, index = findGroup(skillsTab, args.group)
				local _, gemIndex = findGem(group, args.gem)
				if args.level == nil and args.quality == nil and args.enabled == nil and args.count == nil then
					T.Fail("Give what to change: level, quality, enabled or count.")
				end
				showGroup(skillsTab, group)
				setGemFields(skillsTab, group, gemIndex, args)
				ctx:Changed()
				result.index = index
				result.gem = gemIndex
			elseif action == "remove_gem" then
				local group, index = findGroup(skillsTab, args.group)
				local gem, gemIndex = findGem(group, args.gem)
				showGroup(skillsTab, group)
				result.removed = gemName(gem)
				skillsTab.gemSlots[gemIndex].delete.onClick()
				ctx:Changed()
				result.index = index
			end
		end)
		restoreSelection()
		if not ok then
			error(err, 0)
		end
		build:ProcessBuildFlag()
		if result.index and skillsTab.socketGroupList[result.index] then
			result.group = groupSummary(build, skillsTab.socketGroupList[result.index], result.index, true)
		end
		result.index = nil
		return result
	end,
}

------------------------------------------------------------------------------

T.Tool {
	name = "skills_rank_supports",
	title = "Rank support gems",
	description = "Ranks the gems Path of Building's gem selector offers for a socket group by the damage each would give, exactly as "
		.. "the selector's 'Sort gems by DPS' does: for every gem that can support the group's skills (or, for active gems, has a "
		.. "global effect) PoB calculates the build with that gem added to the group (or replacing the gem at 'gem' position), and "
		.. "sorts them. 'stat' is the value it sorts by (default: the Skills tab's 'Sort gems by DPS' choice); for all but Full DPS this "
		.. "is the main skill's value, so supports in a group that is not the main skill only matter if they reach it. Gems are added at "
		.. "the level the Skills tab's default gem level gives and its default quality. The build is not changed. Calculating every "
		.. "candidate can take some seconds; 'search' narrows the list as the selector's search box does (for example 'fire' or ':spell').",
	readOnly = true,
	idempotent = true,
	input = {
		group = { type = { "integer", "string" }, description = "Socket group (index or label). Default: the main socket group." },
		gem = { type = "integer", minimum = 1, description = "Gem position to replace instead of adding a new gem." },
		stat = { type = "string", enum = { "FullDPS", "CombinedDPS", "TotalDPS", "AverageDamage", "TotalDot", "BleedDPS", "IgniteDPS", "TotalPoisonDPS", "TotalEHP" },
			description = "What to sort by (the Skills tab's 'Sort gems by DPS' choices)." },
		type = { type = "string", enum = { "support", "active", "all" }, description = "Which gems to rank (default support)." },
		search = { type = "string", maxLength = 100, description = "Filter as the gem selector's search box (names, ':tag' filters)." },
		limit = T.PageArgs(25).limit,
		offset = T.PageArgs(25).offset,
	},
	run = function(args)
		local build = T.Build()
		build:ProcessBuildFlag()
		local skillsTab = build.skillsTab
		local group, groupIndex
		if args.group ~= nil then
			group, groupIndex = findGroup(skillsTab, args.group)
		else
			groupIndex = build.mainSocketGroup
			group = skillsTab.socketGroupList[groupIndex]
			if not group then
				T.Fail("There are no socket groups; add one with skills_edit first.")
			end
		end
		if group.source then
			T.Fail("Socket group '%s' is added by %s; its gems cannot be changed.", groupName(group), groupSource(group))
		end
		local slotIndex = args.gem or (#group.gemList + 1)
		if slotIndex > #group.gemList + 1 then
			T.Fail("Socket group '%s' has %d gems; 'gem' must be 1-%d.", groupName(group), #group.gemList, #group.gemList)
		end
		local statField = args.stat or skillsTab.sortGemsByDPSField
		local statLabel = statField
		for _, entry in ipairs(skillsTab.controls.sortGemsByDPSFieldControl.list) do
			if entry.type == statField then
				statLabel = entry.label
			end
		end
		local gemType = args.type or "support"

		-- The gem selector calculates by putting each candidate into the group's gem list and
		-- putting back only some fields; the calculation also writes choices onto the gems
		-- it runs. Keep the group and every gem as they are, and restore them afterwards.
		local saved = { }
		for _, key in ipairs({ "displayGroup", "sortGemsByDPS", "sortGemsByDPSField" }) do
			saved[key] = skillsTab[key]
		end
		local groupFields = copyTable(group, true)
		local gemTables, gemFields = { }, { }
		for i, gem in ipairs(group.gemList) do
			gemTables[i], gemFields[i] = gem, copyTable(gem, true)
		end
		local function restoreFields(t, copy)
			for k in pairs(t) do
				if copy[k] == nil then
					t[k] = nil
				end
			end
			for k, v in pairs(copy) do
				t[k] = v
			end
		end
		local ok, result = pcall(function()
			skillsTab.displayGroup = group
			skillsTab.sortGemsByDPS = true
			skillsTab.sortGemsByDPSField = statField
			local control = new("GemSelectControl"):GemSelectControl(nil, { 0, 0, 300, 20 }, skillsTab, slotIndex, function() end)
			control.sortGemsBy = GEM_TYPE_TAGS[gemType]
			control:UpdateSortCache()
			local search = args.search or ""
			control:BuildList(search)
			local sortCache = control.sortCache
			local listed = { }
			for _, gemId in ipairs(control.list) do
				listed[gemId] = true
			end
			local pending, evaluated = { }, { }
			for _, gemId in ipairs(sortCache.pendingGems or { }) do
				if listed[gemId] then
					t_insert(pending, gemId)
					evaluated[gemId] = true
				end
			end
			sortCache.pendingGems = pending
			-- The open dropdown runs this coroutine over several frames; run it to the end.
			local builder = coroutine.create(control.DPSBuilder)
			repeat
				local resumed, builderErr = coroutine.resume(builder, control)
				if not resumed then
					error(builderErr, 0)
				end
			until coroutine.status(builder) == "dead"
			control:BuildList(search)
			local baseValue = sortCache.baseDPS or 0
			local ranked = { }
			for _, gemId in ipairs(control.list) do
				local gemData = control.gems[gemId]
				if gemData and evaluated[gemId] then
					local value = sortCache.dps[gemId] or baseValue
					t_insert(ranked, {
						name = gemData.name,
						value = T.Round(value, 2),
						change = T.Round(value - baseValue, 2),
						percent = baseValue ~= 0 and T.Round((value - baseValue) / baseValue * 100, 2) or nil,
						canSupport = sortCache.canSupport[gemId] == true,
						level = skillsTab:ProcessGemLevel(gemData),
					})
				end
			end
			return { baseValue = baseValue, ranked = ranked }
		end)
		for key, value in pairs(saved) do
			skillsTab[key] = value
		end
		restoreFields(group, groupFields)
		for i = #group.gemList, 1, -1 do
			group.gemList[i] = nil
		end
		for i, gem in ipairs(gemTables) do
			restoreFields(gem, gemFields[i])
			group.gemList[i] = gem
		end
		if not ok then
			error(result, 0)
		end
		local page, paging = T.Page(result.ranked, args, 25)
		local replaced = group.gemList[slotIndex]
		return {
			group = groupIndex,
			groupLabel = groupName(group),
			replaces = replaced and gemName(replaced) or nil,
			stat = { field = statField, label = statLabel, current = T.Round(result.baseValue, 2) },
			type = gemType,
			defaultGemLevel = skillsTab.defaultGemLevel,
			defaultGemQuality = skillsTab.defaultGemQuality or 0,
			gems = page,
			page = paging,
		}
	end,
}
