-- Path of Building
--
-- Module: MCP Tools - Calcs
-- The Calcs tab: its sections and cells (Modules/CalcSections), and the
-- breakdown PoB shows for a cell (CalcBreakdownControl).
--
local T = ...

local t_insert = table.insert
local t_concat = table.concat

local CALC_MODES = { "UNBUFFED", "BUFFED", "COMBAT", "EFFECTIVE" }
local MAX_TABLE_ROWS = 200

local function text(value)
	if value == nil then
		return nil
	end
	return (T.Clean(tostring(value)):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalise(value)
	return (tostring(value or ""):lower():gsub("[^%w]", ""))
end

-- The Calcs tab's own calculation, as CalcsTab:BuildOutput makes it, with the
-- refresh of its pinned breakdown. The side bar's calculation is not touched.
local function rebuildCalcsEnv(calcsTab)
	calcsTab.calcsEnv = calcsTab.calcs.buildOutput(calcsTab.build, "CALCS")
	calcsTab.calcsOutput = calcsTab.calcsEnv.player.output
	if calcsTab.displayData then
		calcsTab.controls.breakdown:SetBreakdownData()
		calcsTab.controls.breakdown:SetBreakdownData(calcsTab.displayData, calcsTab.displayPinned)
	end
end

-- Run fn with the Calcs tab showing the skill, mode and actor asked for, then put
-- the tab's selection back (it is saved with the build) and recalculate it.
local function withCalcsView(build, args, fn)
	local calcsTab = build.calcsTab
	local skillsTab = build.skillsTab
	local inputCopy = copyTable(calcsTab.input, true)
	local changes = { }
	local function change(t, key, value)
		t_insert(changes, { t, key, t[key] })
		t[key] = value
	end
	local recalculated = false
	local function recalculate()
		recalculated = true
		rebuildCalcsEnv(calcsTab)
	end
	local ok, result = pcall(function()
		if args.group ~= nil then
			local index = args.group
			if type(index) ~= "number" then
				index = isValueInArray(skillsTab.socketGroupList, T.Find(skillsTab.socketGroupList, args.group, function(group)
					return group.displayLabel or group.label
				end, "socket group"))
			elseif not skillsTab.socketGroupList[index] then
				T.Fail("There is no socket group %d (see skills_get).", index)
			end
			change(calcsTab.input, "skill_number", index)
			recalculate()
		end
		local group = skillsTab.socketGroupList[calcsTab.input.skill_number]
		if args.active_skill ~= nil then
			local list = group and group.displaySkillListCalcs or { }
			local index = args.active_skill
			if type(index) ~= "number" then
				local entries = { }
				for i, activeSkill in ipairs(list) do
					t_insert(entries, { index = i, name = activeSkill.activeEffect.grantedEffect.name })
				end
				index = T.Find(entries, args.active_skill, function(entry) return entry.name end, "active skill").index
			elseif not list[index] then
				T.Fail("The socket group has %d active skill%s.", #list, #list == 1 and "" or "s")
			end
			change(group, "mainActiveSkillCalcs", index)
			recalculate()
		end
		if args.skill_part ~= nil then
			local activeSkill = group and group.displaySkillListCalcs and group.displaySkillListCalcs[group.mainActiveSkillCalcs or 1]
			local parts = activeSkill and activeSkill.activeEffect.grantedEffect.parts
			if not parts or #parts < 2 then
				T.Fail("The Calcs tab's skill has no skill parts to choose.")
			end
			local index = args.skill_part
			if type(index) ~= "number" then
				local entries = { }
				for i, part in ipairs(parts) do
					t_insert(entries, { index = i, name = part.name })
				end
				index = T.Find(entries, args.skill_part, function(entry) return entry.name end, "skill part").index
			elseif not parts[index] then
				T.Fail("The skill has %d parts.", #parts)
			end
			change(activeSkill.activeEffect.srcInstance, "skillPartCalcs", index)
			recalculate()
		end
		if args.mode and args.mode ~= calcsTab.input.misc_buffMode then
			change(calcsTab.input, "misc_buffMode", args.mode)
			recalculate()
		end
		if args.minion ~= nil then
			change(calcsTab.input, "showMinion", args.minion or nil)
			if args.minion and not calcsTab.calcsEnv.minion then
				T.Fail("The Calcs tab's skill has no minion, so there are no minion stats to show.")
			end
		end
		return fn(calcsTab)
	end)
	for i = #changes, 1, -1 do
		local entry = changes[i]
		entry[1][entry[2]] = entry[3]
	end
	wipeTable(calcsTab.input)
	for key, value in pairs(inputCopy) do
		calcsTab.input[key] = value
	end
	if recalculated then
		rebuildCalcsEnv(calcsTab)
	end
	if not ok then
		error(result, 0)
	end
	return result
end

-- What the Calcs tab is showing.
local function viewInfo(build, calcsTab)
	local env = calcsTab.calcsEnv
	local skill = env.player.mainSkill
	local group = build.skillsTab.socketGroupList[calcsTab.input.skill_number]
	local info = {
		mode = calcsTab.input.misc_buffMode,
		actor = calcsTab.input.showMinion and env.minion and "minion" or "player",
		hasMinion = env.minion ~= nil,
		group = calcsTab.input.skill_number,
		groupLabel = group and text(group.displayLabel or group.label) or nil,
	}
	if skill and skill.activeEffect then
		info.skill = text(skill.activeEffect.grantedEffect.name)
		info.skillPart = skill.skillPartName and text(skill.skillPartName) or nil
	end
	return info
end

-- A subsection whose first row has no label holds column headers (Physical, Lightning, ...).
local function columnHeaders(subSec)
	local first = subSec.data[1]
	if not first or first.label then
		return nil
	end
	local headers = { }
	for i, cell in ipairs(first) do
		headers[i] = cell.format and (text(cell.format):gsub(":$", "")) or nil
	end
	return headers
end

-- Every labelled cell of the Calcs tab, in the tab's order, and whether the tab
-- shows it for this build (the CheckFlag tests CalcSectionControl:UpdateSize makes).
local function collectCells(calcsTab)
	local cells = { }
	for _, section in ipairs(calcsTab.sectionList) do
		local sectionShown = calcsTab:CheckFlag(section)
		for subIndex, subSec in ipairs(section.subSection) do
			local headers = columnHeaders(subSec)
			for rowIndex, rowData in ipairs(subSec.data) do
				if rowData.label then
					local rowShown = sectionShown and calcsTab:CheckFlag(rowData)
					for colIndex, colData in ipairs(rowData) do
						if colData.format then
							local breakdowns = { }
							for _, sectionData in ipairs(colData) do
								if sectionData.breakdown then
									t_insert(breakdowns, sectionData.breakdown)
								end
							end
							t_insert(cells, {
								id = section.id .. "/" .. subIndex .. "/" .. rowIndex .. "/" .. colIndex,
								section = section.id,
								subsection = text(subSec.label),
								row = text(rowData.label),
								column = headers and headers[colIndex] or nil,
								outputKey = colData.format:match("{%d*:?output:([%a%.]+)}"),
								breakdowns = breakdowns,
								hasBreakdown = colData[1] ~= nil,
								shown = rowShown and calcsTab:CheckFlag(colData) and true or false,
								colData = colData,
							})
						end
					end
				end
			end
		end
	end
	return cells
end

-- The names a cell answers to, strongest first: its id; the output it shows;
-- the breakdowns it shows; then its labels.
local function cellNames(cell)
	local tiers = { { cell.id }, { }, { }, { } }
	if cell.outputKey then
		t_insert(tiers[2], cell.outputKey)
		t_insert(tiers[2], (cell.outputKey:gsub("^%a+%.", "")))
	end
	for _, name in ipairs(cell.breakdowns) do
		t_insert(tiers[3], name)
		t_insert(tiers[3], (name:gsub("^%a+%.", "")))
	end
	local row, column, sub = cell.row or "", cell.column, cell.subsection or ""
	if column then
		t_insert(tiers[4], row .. " " .. column)
		t_insert(tiers[4], column .. " " .. row)
		t_insert(tiers[4], sub .. " " .. row .. " " .. column)
	else
		t_insert(tiers[4], row)
		t_insert(tiers[4], sub .. " " .. row)
		t_insert(tiers[4], cell.section .. " " .. row)
	end
	return tiers
end

-- Every word of the filter must appear in one of the cell's names.
local function cellMatches(cell, filter)
	local terms = { }
	for term in tostring(filter):gmatch("%S+") do
		if normalise(term) ~= "" then
			t_insert(terms, normalise(term))
		end
	end
	if not terms[1] then
		return true
	end
	for _, tier in ipairs(cellNames(cell)) do
		for _, name in ipairs(tier) do
			local n = normalise(name)
			local all = true
			for _, term in ipairs(terms) do
				if not n:find(term, 1, true) then
					all = false
					break
				end
			end
			if all then
				return true
			end
		end
	end
	return false
end

local function cellValue(calcsTab, cell)
	if not cell.shown then
		return nil
	end
	local actor = calcsTab.input.showMinion and calcsTab.calcsEnv.minion or calcsTab.calcsEnv.player
	local ok, value = pcall(formatCalcStr, cell.colData.format, actor, cell.colData)
	return ok and text(value) or nil
end

local function publicCell(calcsTab, cell)
	return {
		id = cell.id,
		section = cell.section,
		subsection = cell.subsection,
		row = cell.row,
		column = cell.column,
		value = cellValue(calcsTab, cell),
		output = cell.outputKey,
		hasBreakdown = cell.hasBreakdown,
		shown = cell.shown,
	}
end

-- The breakdown PoB shows for a cell: CalcBreakdownControl:SetBreakdownData run
-- on a stand-in object, so the tab's own breakdown pane is left alone.
local function breakdownOf(calcsTab, cell)
	local proxy = setmetatable({
		calcsTab = calcsTab,
		sectionList = { },
		clearDisplayFunc = function() end,
	}, common.classes.CalcBreakdownControl)
	proxy:SetBreakdownData(cell.colData, false)
	local sections = { }
	for _, section in ipairs(proxy.sectionList) do
		if section.type == "TEXT" then
			local lines = { }
			for _, line in ipairs(section.lines) do
				t_insert(lines, text(line))
			end
			t_insert(sections, { type = "lines", lines = lines })
		elseif section.type == "TABLE" then
			-- The columns PoB draws: those with a value in some row.
			local columns, keys = { }, { }
			for _, col in ipairs(section.colList) do
				for _, row in ipairs(section.rowList) do
					if row[col.key] ~= nil then
						t_insert(columns, text(col.label))
						t_insert(keys, col.key)
						break
					end
				end
			end
			local rows = { }
			for i, row in ipairs(section.rowList) do
				if i > MAX_TABLE_ROWS then
					break
				end
				local cells = { }
				for c, key in ipairs(keys) do
					cells[c] = row[key] ~= nil and text(row[key]) or ""
				end
				t_insert(rows, cells)
			end
			t_insert(sections, {
				type = "table",
				label = text(section.label),
				footer = text(section.footer),
				columns = columns,
				rows = T.Array(rows),
				truncated = #section.rowList > MAX_TABLE_ROWS and #section.rowList or nil,
			})
		elseif section.type == "RADIUS" then
			t_insert(sections, { type = "radius", radius = section.radius })
		end
	end
	return sections
end

-- The cell a stat name means; fails with the closest cells when it is not clear.
local function findCell(calcsTab, cells, stat, sectionName)
	local wanted = normalise(stat)
	local sectionWanted = sectionName and normalise(sectionName)
	local matches
	for tier = 1, 4 do
		local found = { }
		for _, cell in ipairs(cells) do
			if not sectionWanted or normalise(cell.section) == sectionWanted or normalise(cell.subsection) == sectionWanted then
				for _, name in ipairs(cellNames(cell)[tier]) do
					if normalise(name) == wanted then
						t_insert(found, cell)
						break
					end
				end
			end
		end
		if found[1] then
			matches = found
			break
		end
	end
	local function describe(list)
		local names = { }
		for _, cell in ipairs(list) do
			if #names < 15 then
				t_insert(names, cell.id .. " (" .. cell.section .. ": " .. (cell.row or "") .. (cell.column and (" " .. cell.column) or "") .. ")")
			end
		end
		return t_concat(names, "; ")
	end
	if not matches then
		local close = { }
		for _, cell in ipairs(cells) do
			if cell.shown and cellMatches(cell, stat) then
				t_insert(close, cell)
			end
		end
		T.Fail("No Calcs tab cell is called '%s'.%s", stat, close[1] and (" Similar: " .. describe(close)) or " List the cells with a filter to find it.")
	end
	-- Prefer cells the tab shows for this build; hidden ones have nothing to break down.
	local shown = { }
	for _, cell in ipairs(matches) do
		if cell.shown then
			t_insert(shown, cell)
		end
	end
	local pool = shown[1] and shown or matches
	if #pool > 1 then
		T.Fail("'%s' matches several Calcs tab cells; give one of their ids as stat, or a section: %s", stat, describe(pool))
	end
	return pool[1]
end

T.Tool {
	name = "calcs_breakdown",
	title = "Calcs tab breakdown",
	description = "Reads Path of Building's Calcs tab. Without 'stat' it lists the tab's sections and cells (section, row, column, the "
		.. "value shown, whether it has a breakdown) matching 'filter' (words matched against labels and output names, for example 'crit chance' or "
		.. "'fire resist'). With 'stat' (a cell id from the list, an output name such as 'Life' or 'AverageHit', or a label such as "
		.. "'Life Total') it returns the breakdown PoB shows when hovering that cell: the formula lines, and the tables of sources and "
		.. "modifiers (value, stat, source, source name...). The Calcs tab normally details the main skill in Effective DPS mode; "
		.. "'group', 'active_skill', 'skill_part', 'mode' and 'minion' look at another skill, calculation mode or the minion, and the "
		.. "tab's selection is put back afterwards. Nothing in the build changes.",
	readOnly = true,
	idempotent = true,
	input = {
		stat = { type = "string", maxLength = 100, description = "The cell to break down: id, output name or label." },
		section = { type = "string", maxLength = 100, description = "Only cells of this section or subsection (for example 'Life', 'Offence')." },
		filter = { type = "string", maxLength = 100, description = "Without stat: list only cells whose names contain all these words." },
		include_hidden = { type = "boolean", description = "Without stat: also list cells the tab hides for this build." },
		group = { type = { "integer", "string" }, description = "Socket group to detail (index or label). Default: the Calcs tab's current one." },
		active_skill = { type = { "integer", "string" }, description = "Active skill of that group (name or position)." },
		skill_part = { type = { "integer", "string" }, description = "Skill part (name or position), for skills with parts." },
		mode = { type = "string", enum = CALC_MODES, description = "Calculation mode: UNBUFFED, BUFFED, COMBAT or EFFECTIVE (the tab's default)." },
		minion = { type = "boolean", description = "Show the minion's stats instead of the player's." },
		limit = T.PageArgs(50).limit,
		offset = T.PageArgs(50).offset,
	},
	run = function(args)
		local build = T.Build()
		build:ProcessBuildFlag()
		return withCalcsView(build, args, function(calcsTab)
			local cells = collectCells(calcsTab)
			if args.section and not args.stat then
				local wanted = normalise(args.section)
				local inSection = { }
				for _, cell in ipairs(cells) do
					if normalise(cell.section) == wanted or normalise(cell.subsection) == wanted then
						t_insert(inSection, cell)
					end
				end
				cells = inSection
			end
			local result = { view = viewInfo(build, calcsTab) }
			if args.stat then
				local cell = findCell(calcsTab, cells, args.stat, args.section)
				result.cell = publicCell(calcsTab, cell)
				if not cell.shown then
					result.note = "The Calcs tab does not show this cell for this build, so it has no breakdown."
					result.breakdown = T.Array({ })
				else
					result.breakdown = T.Array(breakdownOf(calcsTab, cell))
				end
				return result
			end
			local list, sections, seen = { }, { }, { }
			for _, cell in ipairs(cells) do
				if (cell.shown or args.include_hidden) and cellMatches(cell, args.filter or "") then
					t_insert(list, cell)
					if not seen[cell.section] then
						seen[cell.section] = true
						t_insert(sections, cell.section)
					end
				end
			end
			-- The sections the listed cells are in, in the tab's order.
			result.sections = T.Array(sections)
			local page, paging = T.Page(list, args, 50)
			local cellsOut = { }
			for _, cell in ipairs(page) do
				t_insert(cellsOut, publicCell(calcsTab, cell))
			end
			result.cells = T.Array(cellsOut)
			result.page = paging
			return result
		end)
	end,
}
