-- Path of Building
--
-- Module: Compare Calcs Helpers
-- Stateless calcs tooltip helper functions for the Compare Tab.
-- Handles modifier formatting, source resolution, tabulation, and tooltip rendering.
--
local t_insert = table.insert
local s_format = string.format

local M = {}

-- Format a modifier value with its type for display
function M.FormatCalcModValue(value, modType)
	if modType == "BASE" then
		return s_format("%+g base", value)
	elseif modType == "INC" then
		if value >= 0 then
			return value .. "% increased"
		else
			return (-value) .. "% reduced"
		end
	elseif modType == "MORE" then
		if value >= 0 then
			return value .. "% more"
		else
			return (-value) .. "% less"
		end
	elseif modType == "OVERRIDE" then
		return "Override: " .. tostring(value)
	elseif modType == "FLAG" then
		return value and "True" or "False"
	else
		return tostring(value)
	end
end

-- Format CamelCase mod name to spaced words
function M.FormatCalcModName(modName)
	return modName:gsub("([%l%d]:?)(%u)", "%1 %2"):gsub("(%l)(%d)", "%1 %2")
end

-- Resolve a modifier's source to a human-readable name
function M.ResolveSourceName(mod, build)
	if not mod.source then return "" end
	local sourceType = mod.source:match("[^:]+") or ""
	if sourceType == "Item" then
		local itemId = mod.source:match("Item:(%d+):.+")
		local item = build.itemsTab and build.itemsTab.items[tonumber(itemId)]
		if item then
			return colorCodes[item.rarity] .. item.name
		end
	elseif sourceType == "Tree" then
		local nodeId = mod.source:match("Tree:(%d+)")
		if nodeId then
			local nodeIdNum = tonumber(nodeId)
			local node = (build.spec and build.spec.nodes[nodeIdNum])
				or (build.spec and build.spec.tree and build.spec.tree.nodes[nodeIdNum])
				or (build.latestTree and build.latestTree.nodes[nodeIdNum])
			if node then
				return node.dn or node.name or ""
			end
		end
	elseif sourceType == "Skill" then
		local skillId = mod.source:match("Skill:(.+)")
		if skillId and build.data and build.data.skills[skillId] then
			return build.data.skills[skillId].name
		end
	elseif sourceType == "Pantheon" then
		return mod.source:match("Pantheon:(.+)") or ""
	elseif sourceType == "Spectre" then
		return mod.source:match("Spectre:(.+)") or ""
	end
	return ""
end

-- Get the modDB and config for a sectionData entry and actor
function M.GetModStoreAndCfg(sectionData, actor)
	local cfg = {}
	if sectionData.cfg and actor.mainSkill and actor.mainSkill[sectionData.cfg .. "Cfg"] then
		cfg = copyTable(actor.mainSkill[sectionData.cfg .. "Cfg"], true)
	end
	cfg.source = sectionData.modSource
	cfg.actor = sectionData.actor

	local modStore
	if sectionData.enemy and actor.enemy then
		modStore = actor.enemy.modDB
	elseif sectionData.cfg and actor.mainSkill then
		modStore = actor.mainSkill.skillModList
	else
		modStore = actor.modDB
	end
	return modStore, cfg
end

-- Tabulate modifiers for a sectionData entry and actor
function M.TabulateMods(sectionData, actor)
	local modStore, cfg = M.GetModStoreAndCfg(sectionData, actor)
	if not modStore then return {} end

	local rowList
	if type(sectionData.modName) == "table" then
		rowList = modStore:Tabulate(sectionData.modType, cfg, unpack(sectionData.modName))
	else
		rowList = modStore:Tabulate(sectionData.modType, cfg, sectionData.modName)
	end
	return rowList or {}
end

-- Build a unique key for a modifier row to match between builds
function M.ModRowKey(row)
	local src = row.mod.source or ""
	local name = row.mod.name or ""
	local mtype = row.mod.type or ""
	-- Normalize Item sources by stripping the build-specific numeric ID
	-- "Item:5:Body Armour" -> "Item:Body Armour" so same items match across builds
	local normalizedSrc = src:gsub("^(Item):%d+:", "%1:")
	return normalizedSrc .. "|" .. name .. "|" .. mtype
end

-- Format a single modifier row as a tooltip line
function M.FormatModRow(row, sectionData, build)
	local displayValue
	if not sectionData.modType then
		displayValue = M.FormatCalcModValue(row.value, row.mod.type)
	else
		displayValue = formatRound(row.value, 2)
	end

	local sourceType = row.mod.source and row.mod.source:match("[^:]+") or "?"
	local sourceName = M.ResolveSourceName(row.mod, build)
	local modName = ""
	if type(sectionData.modName) == "table" then
		modName = "  " .. M.FormatCalcModName(row.mod.name)
	end

	return displayValue, sourceType, sourceName, modName
end

-- Get breakdown text lines for a build's actor
function M.GetBreakdownLines(sectionData, build)
	if not sectionData.breakdown then return nil end
	local calcsActor = build.calcsTab and build.calcsTab.calcsEnv and build.calcsTab.calcsEnv.player
	if not calcsActor or not calcsActor.breakdown then return nil end

	local breakdown
	local ns, name = sectionData.breakdown:match("^(%a+)%.(%a+)$")
	if ns then
		breakdown = calcsActor.breakdown[ns] and calcsActor.breakdown[ns][name]
	else
		breakdown = calcsActor.breakdown[sectionData.breakdown]
	end

	if not breakdown or #breakdown == 0 then return nil end

	local lines = {}
	for _, line in ipairs(breakdown) do
		if type(line) == "string" then
			t_insert(lines, line)
		end
	end
	return #lines > 0 and lines or nil
end

-- Draw the calcs hover tooltip showing breakdown for both builds with common/unique grouping
-- tooltip, primaryBuild, primaryLabel passed as args instead of self
function M.DrawCalcsTooltip(tooltip, primaryBuild, primaryLabel, colData, rowLabel, rowX, rowY, rowW, rowH, vp, compareEntry)
	if tooltip:CheckForUpdate(colData, rowLabel) then
		-- Get calcsEnv actors (these have breakdown data populated)
		local primaryCalcsActor = primaryBuild.calcsTab and primaryBuild.calcsTab.calcsEnv
			and primaryBuild.calcsTab.calcsEnv.player
		local compareCalcsActor = compareEntry.calcsTab and compareEntry.calcsTab.calcsEnv
			and compareEntry.calcsTab.calcsEnv.player

		local primaryActor = primaryCalcsActor or (primaryBuild.calcsTab.mainEnv and primaryBuild.calcsTab.mainEnv.player)
		local compareActor = compareCalcsActor or (compareEntry.calcsTab.mainEnv and compareEntry.calcsTab.mainEnv.player)

		if not primaryActor and not compareActor then
			return
		end

		local compareLabel = compareEntry.label or "Compare Build"

		-- Tooltip header
		tooltip:AddLine(16, "^7" .. (rowLabel or ""))
		tooltip:AddSeparator(10)

		-- Process each sectionData entry in colData
		for _, sectionData in ipairs(colData) do
			-- Show breakdown formulas per build (these are always build-specific)
			if sectionData.breakdown then
				local primaryLines = M.GetBreakdownLines(sectionData, primaryBuild)
				local compareLines = M.GetBreakdownLines(sectionData, compareEntry)

				if primaryLines then
					tooltip:AddLine(14, colorCodes.POSITIVE .. primaryLabel .. ":")
					for _, line in ipairs(primaryLines) do
						tooltip:AddLine(14, "^7  " .. line)
					end
				end
				if compareLines then
					tooltip:AddLine(14, colorCodes.WARNING .. compareLabel .. ":")
					for _, line in ipairs(compareLines) do
						tooltip:AddLine(14, "^7  " .. line)
					end
				end
				if primaryLines or compareLines then
					tooltip:AddSeparator(10)
				end
			end

			-- Show modifier sources split into common / primary-only / compare-only
			if sectionData.modName then
				local pRows = primaryActor and M.TabulateMods(sectionData, primaryActor) or {}
				local cRows = compareActor and M.TabulateMods(sectionData, compareActor) or {}

				if #pRows > 0 or #cRows > 0 then
					-- Build lookup of compare rows by key
					local cByKey = {}
					for _, row in ipairs(cRows) do
						local key = M.ModRowKey(row)
						cByKey[key] = row
					end

					-- Classify into common, primary-only, compare-only
					local common = {}    -- { { pRow, cRow }, ... }
					local pOnly = {}
					local cMatched = {}  -- keys that were matched

					for _, pRow in ipairs(pRows) do
						local key = M.ModRowKey(pRow)
						if cByKey[key] then
							t_insert(common, { pRow, cByKey[key] })
							cMatched[key] = true
						else
							t_insert(pOnly, pRow)
						end
					end

					local cOnly = {}
					for _, cRow in ipairs(cRows) do
						local key = M.ModRowKey(cRow)
						if not cMatched[key] then
							t_insert(cOnly, cRow)
						end
					end

					-- Sub-section header (e.g., "Sources", "Increased Life Regeneration Rate")
					local sectionLabel = sectionData.label or "Player modifiers"
					tooltip:AddLine(14, "^7" .. sectionLabel .. ":")

					-- Common modifiers
					if #common > 0 then
						-- Sort by primary value descending
						table.sort(common, function(a, b)
							if type(a[1].value) == "number" and type(b[1].value) == "number" then
								return a[1].value > b[1].value
							end
							return false
						end)
						tooltip:AddLine(12, "^x808080  Common:")
						for _, pair in ipairs(common) do
							local pVal, sourceType, sourceName, modName = M.FormatModRow(pair[1], sectionData, primaryBuild)
							local cVal = M.FormatModRow(pair[2], sectionData, compareEntry)
							local valStr
							if pVal == cVal then
								valStr = s_format("^7%-10s", pVal)
							else
								valStr = colorCodes.POSITIVE .. s_format("%-5s", pVal) .. "^7/" .. colorCodes.WARNING .. s_format("%-5s", cVal)
							end
							local line = s_format("    %s ^7%-6s ^7%s%s", valStr, sourceType, sourceName, modName)
							tooltip:AddLine(12, line)
						end
					end

					-- Primary-only modifiers
					if #pOnly > 0 then
						table.sort(pOnly, function(a, b)
							if type(a.value) == "number" and type(b.value) == "number" then
								return a.value > b.value
							end
							return false
						end)
						tooltip:AddLine(12, colorCodes.POSITIVE .. "  " .. primaryLabel .. " only:")
						for _, row in ipairs(pOnly) do
							local displayValue, sourceType, sourceName, modName = M.FormatModRow(row, sectionData, primaryBuild)
							local line = s_format("    ^7%-10s ^7%-6s ^7%s%s", displayValue, sourceType, sourceName, modName)
							tooltip:AddLine(12, line)
						end
					end

					-- Compare-only modifiers
					if #cOnly > 0 then
						table.sort(cOnly, function(a, b)
							if type(a.value) == "number" and type(b.value) == "number" then
								return a.value > b.value
							end
							return false
						end)
						tooltip:AddLine(12, colorCodes.WARNING .. "  " .. compareLabel .. " only:")
						for _, row in ipairs(cOnly) do
							local displayValue, sourceType, sourceName, modName = M.FormatModRow(row, sectionData, compareEntry)
							local line = s_format("    ^7%-10s ^7%-6s ^7%s%s", displayValue, sourceType, sourceName, modName)
							tooltip:AddLine(12, line)
						end
					end

					-- Separator between sub-sections
					tooltip:AddSeparator(6)
				end
			end
		end
	end

	SetDrawLayer(nil, 100)
	tooltip:Draw(rowX, rowY, rowW, rowH, vp)
	SetDrawLayer(nil, 0)
end

-- Resolve a modifier's source name for breakdown panel display
local function resolveModSource(mod, build)
	local sourceType = mod.source and mod.source:match("[^:]+") or "?"
	local sourceName = ""
	if sourceType == "Item" then
		local itemId = mod.source:match("Item:(%d+):.+")
		local item = build.itemsTab and build.itemsTab.items[tonumber(itemId)]
		if item then
			sourceName = colorCodes[item.rarity] .. item.name
		end
	elseif sourceType == "Tree" then
		local nodeId = mod.source:match("Tree:(%d+)")
		if nodeId then
			local nodeIdNum = tonumber(nodeId)
			local node = (build.spec and build.spec.nodes[nodeIdNum])
				or (build.spec and build.spec.tree and build.spec.tree.nodes[nodeIdNum])
				or (build.latestTree and build.latestTree.nodes[nodeIdNum])
			if node then
				sourceName = node.dn or node.name or ""
			end
		end
	elseif sourceType == "Skill" then
		local skillId = mod.source:match("Skill:(.+)")
		if skillId and build.data and build.data.skills[skillId] then
			sourceName = build.data.skills[skillId].name
		end
	elseif sourceType == "Pantheon" then
		sourceName = mod.source:match("Pantheon:(.+)") or ""
	elseif sourceType == "Spectre" then
		sourceName = mod.source:match("Spectre:(.+)") or ""
	end
	return sourceType, sourceName
end

-- Draw a breakdown panel for a single build's SkillBuffs or SkillDebuffs,
function M.DrawSkillBreakdownPanel(build, breakdownKey, label, cellX, cellY, cellW, cellH, vp)
	local player = build.calcsTab and build.calcsTab.calcsEnv
		and build.calcsTab.calcsEnv.player
	if not player or not player.breakdown then return end

	local breakdown = player.breakdown[breakdownKey]
	if not breakdown or not breakdown.modList or #breakdown.modList == 0 then return end

	local modList = breakdown.modList

	-- Sort by mod name then value
	local rowList = {}
	for _, entry in ipairs(modList) do
		t_insert(rowList, entry)
	end
	table.sort(rowList, function(a, b)
		return a.mod.name > b.mod.name or (a.mod.name == b.mod.name
			and type(a.value) == "number" and type(b.value) == "number"
			and a.value > b.value)
	end)

	-- Process rows: compute display strings and measure column widths
	local colDefs = {
		{ label = "Value", key = "displayValue" },
		{ label = "Stat", key = "name" },
		{ label = "Source", key = "source" },
		{ label = "Source Name", key = "sourceName" },
	}

	local rows = {}
	for _, entry in ipairs(rowList) do
		local mod = entry.mod
		local row = {}
		row.displayValue = M.FormatCalcModValue(entry.value, mod.type)
		row.name = M.FormatCalcModName(mod.name or "")
		local sourceType, sourceName = resolveModSource(mod, build)
		row.source = sourceType
		row.sourceName = sourceName
		t_insert(rows, row)
	end

	-- Measure column widths
	for _, col in ipairs(colDefs) do
		col.width = DrawStringWidth(16, "VAR", col.label) + 6
		for _, row in ipairs(rows) do
			if row[col.key] then
				col.width = math.max(col.width, DrawStringWidth(12, "VAR", row[col.key]) + 6)
			end
		end
	end

	-- Calculate panel size
	local panelPadding = 4
	local headerRowH = 20
	local dataRowH = 14
	local panelW = panelPadding
	for _, col in ipairs(colDefs) do
		panelW = panelW + col.width
	end
	local panelH = headerRowH + #rows * dataRowH + 4

	-- Position panel next to the hovered cell (right side, or left if no room)
	local panelX = cellX + cellW + 5
	if panelX + panelW > vp.x + vp.width then
		panelX = math.max(vp.x, cellX - 5 - panelW)
	end
	local panelY = math.min(cellY, vp.y + vp.height - panelH)

	-- Draw background
	SetDrawLayer(nil, 10)
	SetDrawColor(0, 0, 0, 0.9)
	DrawImage(nil, panelX + 2, panelY + 2, panelW - 4, panelH - 4)

	-- Draw border
	SetDrawLayer(nil, 11)
	SetDrawColor(0.33, 0.66, 0.33)
	DrawImage(nil, panelX, panelY, panelW, 2)
	DrawImage(nil, panelX, panelY + panelH - 2, panelW, 2)
	DrawImage(nil, panelX, panelY, 2, panelH)
	DrawImage(nil, panelX + panelW - 2, panelY, 2, panelH)
	SetDrawLayer(nil, 10)

	-- Draw column headers and separators
	local colX = panelX + panelPadding
	for i, col in ipairs(colDefs) do
		col.x = colX
		if i > 1 then
			SetDrawColor(0.5, 0.5, 0.5)
			DrawImage(nil, colX - 2, panelY + 2, 1, panelH - 4)
		end
		SetDrawColor(1, 1, 1)
		DrawString(colX, panelY + 2, "LEFT", 16, "VAR", col.label)
		colX = colX + col.width
	end

	-- Draw rows
	local rowY = panelY + headerRowH
	for _, row in ipairs(rows) do
		-- Row separator
		SetDrawColor(0.5, 0.5, 0.5)
		DrawImage(nil, panelX + 2, rowY - 1, panelW - 4, 1)
		for _, col in ipairs(colDefs) do
			if row[col.key] and row[col.key] ~= "" then
				DrawString(col.x, rowY + 1, "LEFT", 12, "VAR", "^7" .. row[col.key])
			end
		end
		rowY = rowY + dataRowH
	end

	SetDrawLayer(nil, 0)
end

return M
