-- Path of Building
--
-- Module: MCP Tools - Config
-- The Config tab: its options (Modules/ConfigOptions), config sets and the
-- custom modifier groups.
--
local T = ...

local t_insert = table.insert
local t_concat = table.concat
local m_floor = math.floor

local varList = require("Modules.ConfigOptions")

local NUMBER_TYPES = { count = true, integer = true, countAllowZero = true, float = true }

-- Every option of the Config tab with the section it is in, in the tab's order.
local optionList, optionsByVar
local function options()
	if not optionList then
		optionList, optionsByVar = { }, { }
		local section
		for _, varData in ipairs(varList) do
			if varData.section then
				section = varData.section
			elseif varData.var then
				local label = varData.label and T.Clean(varData.label):gsub("%s*:%s*$", "") or varData.var
				local option = { varData = varData, var = varData.var, label = label, section = section }
				t_insert(optionList, option)
				optionsByVar[varData.var] = option
			end
		end
	end
	return optionList, optionsByVar
end

local function listLabel(varData, value)
	for _, entry in ipairs(varData.list) do
		if entry.val == value then
			return T.Clean(entry.label)
		end
	end
	return value ~= nil and tostring(value) or nil
end

local function listChoices(varData)
	local choices = { }
	for _, entry in ipairs(varData.list) do
		t_insert(choices, T.Clean(entry.label))
	end
	return choices
end

-- An option's value as the Config tab shows it, and whether it differs from
-- the default (the test ConfigTab uses to highlight changed options).
local function describeOption(configTab, option, withChoices)
	local varData = option.varData
	local configSet = configTab.configSets[configTab.activeConfigSetId]
	local current = configSet.input[varData.var]
	local default = configTab:GetDefaultState(varData.var, type(current))
	local entry = { var = option.var, label = option.label, section = option.section, type = varData.type }
	if varData.type == "check" then
		entry.value = current and true or false
		entry.default = default and true or false
	elseif varData.type == "list" then
		entry.value = listLabel(varData, current ~= nil and current or default)
		entry.default = listLabel(varData, default)
		if withChoices then
			entry.choices = listChoices(varData)
		end
	elseif NUMBER_TYPES[varData.type] then
		entry.value = T.Number(current)
		entry.default = T.Number(default)
		-- An empty number box uses its placeholder (enemy stats follow the boss choice this way).
		local placeholder = configSet.placeholder[varData.var]
		if current == nil and type(placeholder) == "number" then
			entry.usesPlaceholder = true
		end
	else
		entry.value = current
		entry.default = default
	end
	return entry, current ~= nil and current ~= default
end

local function configSetList(configTab)
	local sets = { }
	for _, id in ipairs(configTab.configSetOrderList) do
		t_insert(sets, { id = id, title = T.Clean(configTab.configSets[id].title or "Default"), active = id == configTab.activeConfigSetId })
	end
	return sets
end

-- The lines of a custom modifier group PoB does not recognise: the ones its
-- edit box shows in red, as ConfigTab:BuildModList skips them.
local function unrecognisedLines(text)
	local lines = { }
	for line in (text or ""):gmatch("([^\n]*)\n?") do
		local stripped = StripEscapes(line):match("^%s*(.-)%s*$")
		if stripped ~= "" then
			local mods, extra = modLib.parseMod(stripped)
			if not (mods and not extra) then
				t_insert(lines, stripped)
			end
		end
	end
	return lines
end

local function customModGroups(configTab)
	local groups = { }
	for index, block in ipairs(configTab.configSets[configTab.activeConfigSetId].customModsList or { }) do
		local group = { index = index, title = block.title or "Default", enabled = block.enabled ~= false, text = block.text or "" }
		local unrecognised = unrecognisedLines(block.text)
		if unrecognised[1] then
			group.unrecognised = unrecognised
		end
		t_insert(groups, group)
	end
	return groups
end

local function activeSetTitle(configTab)
	return T.Clean(configTab.configSets[configTab.activeConfigSetId].title or "Default")
end

------------------------------------------------------------------------------

T.Tool {
	name = "config_get",
	title = "Config tab",
	description = "Returns the Config tab of the open build's active config set: by default only the options that differ from "
		.. "their defaults (what PoB highlights), which together with the defaults describe every assumption the numbers rest on "
		.. "(enemy boss type and resistances, charges, buffs, conditions, bandit, pantheon...). With 'search' it lists every option whose "
		.. "label, var name or section contains the text, with the choices of list options; with 'all' it lists every option. Each "
		.. "option has its var (the name config_set takes), label, section, type (check, count, integer, countAllowZero, float, list, "
		.. "text), current value (list options by the label PoB shows) and default. Also returns the config sets, the effective enemy "
		.. "level and the custom modifier groups with the lines PoB does not recognise.",
	readOnly = true,
	idempotent = true,
	input = {
		search = { type = "string", maxLength = 100, description = "Only options whose label, var or section contains this text (any value)." },
		all = { type = "boolean", description = "List every option, not only changed ones (use limit/offset to page)." },
		limit = T.PageArgs(50).limit,
		offset = T.PageArgs(50).offset,
	},
	run = function(args)
		local build = T.Build()
		build:ProcessBuildFlag()
		local configTab = build.configTab
		local list = { }
		local search = args.search and args.search:lower():match("^%s*(.-)%s*$")
		if search == "" then
			search = nil
		end
		for _, option in ipairs((options())) do
			local matches
			if search then
				matches = option.label:lower():find(search, 1, true) or option.var:lower():find(search, 1, true)
					or (option.section or ""):lower():find(search, 1, true)
			end
			local entry, changed = describeOption(configTab, option, search ~= nil)
			if (search and matches) or (not search and (args.all or changed)) then
				t_insert(list, entry)
			end
		end
		local page, paging = T.Page(list, args, 50)
		return {
			configSet = activeSetTitle(configTab),
			configSets = configSetList(configTab),
			listed = search and "matching" or args.all and "all" or "changed from default",
			options = page,
			page = paging,
			enemyLevel = configTab.enemyLevel,
			customModifiers = T.Array(customModGroups(configTab)),
		}
	end,
}

------------------------------------------------------------------------------

-- The option a client means: its var, or its exact label.
local function findOption(key)
	local list, byVar = options()
	if byVar[key] then
		return byVar[key]
	end
	local wanted = T.Clean(tostring(key)):gsub("%s*:%s*$", ""):lower()
	local found = { }
	for _, option in ipairs(list) do
		if option.label:lower() == wanted or option.var:lower() == wanted then
			t_insert(found, option)
		end
	end
	if #found == 1 then
		return found[1]
	elseif #found > 1 then
		local vars = { }
		for _, option in ipairs(found) do
			t_insert(vars, option.var)
		end
		return nil, "several options have that label; use the var: " .. t_concat(vars, ", ")
	end
	-- Suggest options with a similar label.
	local close = { }
	for _, option in ipairs(list) do
		if #close < 8 and (option.label:lower():find(wanted, 1, true) or option.var:lower():find(wanted, 1, true)) then
			t_insert(close, option.var .. " (" .. option.label .. ")")
		end
	end
	return nil, "no such option" .. (close[1] and ("; similar: " .. t_concat(close, "; ")) or "; find it with config_get search")
end

-- Check a value against the option's type, as its control would accept it.
-- Returns the value to apply (for lists, the index of the choice) or nil and a reason.
local function checkValue(varData, value)
	local kind = varData.type
	if kind == "check" then
		if type(value) == "boolean" then
			return value
		elseif value == "true" or value == "false" then
			return value == "true"
		end
		return nil, "expects true or false"
	elseif NUMBER_TYPES[kind] then
		local number = tonumber(value)
		if not T.Number(number) then
			return nil, "expects a number"
		end
		-- The edit boxes accept digits only (count), digits and a minus sign (integer, countAllowZero), or digits and a point (float).
		if kind ~= "float" and number ~= m_floor(number) then
			return nil, "expects a whole number"
		end
		if (kind == "count" or kind == "float") and number < 0 then
			return nil, "expects a number of 0 or more"
		end
		return number
	elseif kind == "list" then
		for index, entry in ipairs(varData.list) do
			if entry.val == value then
				return index
			end
		end
		local wanted = tostring(value):lower()
		for index, entry in ipairs(varData.list) do
			if T.Clean(entry.label):lower() == wanted or tostring(entry.val):lower() == wanted then
				return index
			end
		end
		return nil, "is not one of the choices"
	elseif kind == "text" then
		if type(value) ~= "string" then
			return nil, "expects text"
		end
		return value
	end
	return nil, "cannot be set"
end

-- Set an option through its Config tab control, so the control's own callback runs
-- (input, undo state, BuildModList, buildFlag).
local function applyOption(configTab, varData, value)
	local control = configTab.varControls[varData.var]
	local kind = varData.type
	if kind == "check" then
		control.state = value
		control.changeFunc(value)
	elseif NUMBER_TYPES[kind] then
		control:SetText(value == nil and "" or tostring(value), true)
	elseif kind == "list" then
		control.selIndex = value
		control.selFunc(value, control.list[value])
	elseif kind == "text" then
		control:SetText(T.Sanitise((value:gsub("\r\n", "\n"))), true)
	end
end

local function optionValue(configTab, option)
	return (describeOption(configTab, option)).value
end

-- Text for a custom modifier group's edit box, which keeps printable characters, tabs and new lines.
local function cleanModText(text)
	text = text:gsub("\r\n", "\n"):gsub("%c", function(c)
		return (c == "\n" or c == "\t") and c or ""
	end)
	return (T.Sanitise(text))
end

local function editCustomMods(configTab, args, result)
	if not configTab.customSection then
		T.Fail("This version of Path of Building has no custom modifiers section.")
	end
	local list = configTab.configSets[configTab.activeConfigSetId].customModsList
	local index
	if args.new_custom_mods_group then
		configTab.controls.customModsAddBlock.onClick()
		index = #configTab.configSets[configTab.activeConfigSetId].customModsList
		local title = T.Sanitise((args.new_custom_mods_group:gsub("%c", " ")))
		if title:match("%S") then
			configTab.customModsBlockControls[index].controls.titleEdit:SetText(title, true)
		end
	elseif args.custom_mods_group ~= nil then
		local ref = args.custom_mods_group
		if type(ref) == "number" then
			if not list[ref] then
				T.Fail("There is no custom modifier group %d; there are %d.", ref, #list)
			end
			index = ref
		else
			index = isValueInArray(list, T.Find(list, ref, function(block) return block.title or "Default" end, "custom modifier group"))
		end
	else
		index = 1
	end
	local blockControl = configTab.customModsBlockControls[index]
	local block = configTab.configSets[configTab.activeConfigSetId].customModsList[index]
	if args.custom_mods then
		local text = cleanModText(args.custom_mods)
		if args.custom_mods_mode == "replace" then
			blockControl.controls.textEdit:SetText(text, true)
		else
			local existing = block.text or ""
			if existing ~= "" and not existing:match("\n$") then
				existing = existing .. "\n"
			end
			blockControl.controls.textEdit:SetText(existing .. text, true)
		end
	end
	if args.custom_mods_enabled ~= nil and args.custom_mods_enabled ~= (block.enabled ~= false) then
		blockControl.controls.enableCheck.state = args.custom_mods_enabled
		blockControl.controls.enableCheck.changeFunc(args.custom_mods_enabled)
	end
	local group = customModGroups(configTab)[index]
	result.customModifiers = group
	if group.unrecognised then
		result.note = "Path of Building does not recognise the lines in customModifiers.unrecognised; they have no effect. "
			.. "Write them as item or passive modifiers are worded in the game."
	end
end

T.Tool {
	name = "config_set",
	title = "Change the Config tab",
	description = "Changes the Config tab of the open build through its own controls, so PoB applies them exactly as when the user "
		.. "clicks: 'options' sets options by var (or exact label), for example {\"enemyIsBoss\": \"Pinnacle\", \"usePowerCharges\": true, "
		.. "\"enemyFireResist\": 40, \"bandit\": \"Kill all\"}; boss types and boss skill presets ('enemyIsBoss', 'presetBossSkills') are "
		.. "list options like any other. Values are checked against the option's type (check: true/false; count/integer/float: numbers; "
		.. "list: one of its choices, by the label PoB shows or the stored value; text: text); invalid ones are listed under 'rejected' "
		.. "with the reason and the valid choices. 'reset' puts options back to their defaults. 'set_action' manages config sets "
		.. "(select, new, copy, rename, delete) and runs first, so options then apply to the selected set. 'custom_mods' replaces or "
		.. "appends text in a custom modifier group and reports lines PoB does not recognise. Use config_get to find vars and choices.",
	destructive = true,
	idempotent = true,
	modifies = true,
	usesDialog = true,
	input = {
		options = { type = "object", description = "Options to set: { var or exact label: value }." },
		reset = { type = "array", items = { type = "string" }, maxItems = 100, description = "Options (var or exact label) to put back to their default." },
		set_action = { type = "string", enum = { "select", "new", "copy", "rename", "delete" }, description = "Config set action. new/copy do not select the new set; select it in another call." },
		set = { type = { "integer", "string" }, description = "The config set for select, copy, rename or delete (id or title)." },
		title = { type = "string", maxLength = 100, description = "Name for new, copy or rename." },
		custom_mods = { type = "string", maxLength = 20000, description = "Custom modifier text, one modifier per line, worded as on items (for example '10% increased maximum Life')." },
		custom_mods_mode = { type = "string", enum = { "append", "replace" }, description = "Append to the group's text (default) or replace it." },
		custom_mods_group = { type = { "integer", "string" }, description = "Custom modifier group (index or title). Default: the first." },
		new_custom_mods_group = { type = "string", maxLength = 100, description = "Add a new custom modifier group with this title and write custom_mods there." },
		custom_mods_enabled = { type = "boolean", description = "Enable or disable the custom modifier group." },
	},
	run = function(args, ctx)
		local build = T.Build()
		build:ProcessBuildFlag()
		local configTab = build.configTab
		local result = { }
		local didSomething = false

		if args.set_action then
			local control = new("ConfigSetListControl"):ConfigSetListControl(nil, { 0, 0, 350, 200 }, configTab)
			local done = T.ManageSetList({
				control = control, sets = configTab.configSets, order = configTab.configSetOrderList, what = "config set",
				activeId = function() return configTab.activeConfigSetId end,
				action = args.set_action, ref = args.set, title = args.title,
			})
			if not done.unchanged then
				ctx:Changed()
			end
			didSomething = true
			result.configSetChange = done
		end

		local applied, rejected = { }, { }
		local function reject(key, reason, option)
			local entry = { option = tostring(key), reason = reason }
			if option and option.varData.type == "list" then
				entry.choices = listChoices(option.varData)
			end
			t_insert(rejected, entry)
		end
		local keys = { }
		for key in pairs(args.options or { }) do
			t_insert(keys, key)
		end
		table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
		for _, key in ipairs(keys) do
			local option, err = findOption(key)
			if not option then
				reject(key, err)
			else
				local value, reason = checkValue(option.varData, args.options[key])
				if value == nil then
					reject(key, option.var .. " " .. reason, option)
				else
					local previous = optionValue(configTab, option)
					applyOption(configTab, option.varData, value)
					t_insert(applied, { var = option.var, label = option.label, value = optionValue(configTab, option), previous = previous })
				end
			end
		end
		for _, key in ipairs(args.reset or { }) do
			local option, err = findOption(key)
			if not option then
				reject(key, err)
			else
				local varData = option.varData
				local previous = optionValue(configTab, option)
				if varData.type == "check" then
					applyOption(configTab, varData, varData.defaultState or false)
				elseif varData.type == "list" then
					applyOption(configTab, varData, varData.defaultIndex or 1)
				elseif NUMBER_TYPES[varData.type] then
					applyOption(configTab, varData, nil)
				elseif varData.type == "text" then
					applyOption(configTab, varData, varData.defaultState or "")
				end
				t_insert(applied, { var = option.var, label = option.label, value = optionValue(configTab, option), previous = previous, reset = true })
			end
		end
		if applied[1] then
			ctx:Changed()
			didSomething = true
		end

		if args.custom_mods or args.new_custom_mods_group or args.custom_mods_enabled ~= nil then
			editCustomMods(configTab, args, result)
			ctx:Changed()
			didSomething = true
		end

		if not didSomething then
			if rejected[1] then
				local reasons = { }
				for _, entry in ipairs(rejected) do
					t_insert(reasons, entry.option .. ": " .. entry.reason .. (entry.choices and (" (choices: " .. t_concat(entry.choices, ", ") .. ")") or ""))
				end
				T.Fail("Nothing was changed. %s", t_concat(reasons, "; "))
			end
			T.Fail("Nothing to change: give options, reset, set_action or custom_mods.")
		end
		build:ProcessBuildFlag()
		result.applied = T.Array(applied)
		result.rejected = T.Array(rejected)
		result.configSet = activeSetTitle(configTab)
		result.configSets = configSetList(configTab)
		result.enemyLevel = configTab.enemyLevel
		return result
	end,
}
