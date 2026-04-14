-- Path of Building
--
-- Module: Compare Buy Similar
-- Buy Similar popup UI and trade search URL builder for the Compare tab.
--
local t_insert = table.insert
local m_floor = math.floor
local dkjson = require "dkjson"
local tradeHelpers = LoadModule("Classes/CompareTradeHelpers")

local M = {}

-- Realm display name to API id mapping
local REALM_API_IDS = {
	["PC"]   = "pc",
	["PS4"]  = "sony",
	["Xbox"] = "xbox",
}

-- Listed status display names and their API option values
local LISTED_STATUS_OPTIONS = {
	{ label = "Instant Buyout & In Person", apiValue = "available" },
	{ label = "Instant Buyout", apiValue = "securable" },
	{ label = "In Person (Online)", apiValue = "online" },
	{ label = "Any", apiValue = "any" },
}
local LISTED_STATUS_LABELS = { }
for i, entry in ipairs(LISTED_STATUS_OPTIONS) do
	LISTED_STATUS_LABELS[i] = entry.label
end

-- Helper: create a numeric EditControl without +/- spinner buttons
local function newPlainNumericEdit(anchor, rect, init, prompt, limit)
	local ctrl = new("EditControl", anchor, rect, init, prompt, "%D", limit)
	-- Remove the +/- spinner buttons that "%D" filter triggers
	ctrl.isNumeric = false
	if ctrl.controls then
		if ctrl.controls.buttonDown then ctrl.controls.buttonDown.shown = false end
		if ctrl.controls.buttonUp then ctrl.controls.buttonUp.shown = false end
	end
	return ctrl
end

-- Build the trade search URL based on popup selections
local function buildURL(item, slotName, controls, modEntries, defenceEntries, isUnique)
	-- Determine realm and league from the popup's dropdowns
	local realmDisplayValue = controls.realmDrop and controls.realmDrop:GetSelValue() or "PC"
	local realm = REALM_API_IDS[realmDisplayValue] or "pc"
	local league = controls.leagueDrop and controls.leagueDrop:GetSelValue()
	if not league or league == "" or league == "Loading..." then
		league = "Standard"
	end
	local hostName = "https://www.pathofexile.com/"

	-- Determine listed status from dropdown
	local listedIndex = controls.listedDrop and controls.listedDrop.selIndex or 1
	local listedApiValue = LISTED_STATUS_OPTIONS[listedIndex] and LISTED_STATUS_OPTIONS[listedIndex].apiValue or "available"

	-- Build query
	local queryTable = {
		query = {
			status = { option = listedApiValue },
			stats = {
				{
					type = "and",
					filters = {}
				}
			},
		},
		sort = { price = "asc" }
	}
	local queryFilters = {}

	if isUnique then
		-- Search by unique name
		-- Strip "Foulborn" prefix from unique name for trade search
		local tradeName = (item.title or item.name):gsub("^Foulborn%s+", "")
		queryTable.query.name = tradeName
		queryTable.query.type = item.baseName
		-- If item is Foulborn, add the foulborn_item filter
		if item.foulborn then
			queryFilters.misc_filters = queryFilters.misc_filters or { filters = {} }
			queryFilters.misc_filters.filters.foulborn_item = { option = "true" }
		end
	else
		-- Category filter
		local categoryStr = tradeHelpers.getTradeCategory(slotName, item)
		if categoryStr then
			queryFilters.type_filters = {
				filters = {
					category = { option = categoryStr }
				}
			}
		end

		-- Base type filter
		if controls.baseTypeCheck and controls.baseTypeCheck.state then
			queryTable.query.type = item.baseName
		end

		-- Item level filter
		local ilvlMin = controls.ilvlMin and tonumber(controls.ilvlMin.buf)
		local ilvlMax = controls.ilvlMax and tonumber(controls.ilvlMax.buf)
		if ilvlMin or ilvlMax then
			local ilvlFilter = {}
			if ilvlMin then ilvlFilter.min = ilvlMin end
			if ilvlMax then ilvlFilter.max = ilvlMax end
			queryFilters.misc_filters = {
				filters = {
					ilvl = ilvlFilter
				}
			}
		end

		-- Defence stat filters
		local armourFilters = {}
		for i, def in ipairs(defenceEntries) do
			local prefix = "def" .. i
			if controls[prefix .. "Check"] and controls[prefix .. "Check"].state then
				local minVal = tonumber(controls[prefix .. "Min"].buf)
				local maxVal = tonumber(controls[prefix .. "Max"].buf)
				local filter = {}
				if minVal then filter.min = minVal end
				if maxVal then filter.max = maxVal end
				if minVal or maxVal then
					armourFilters[def.tradeKey] = filter
				end
			end
		end
		if next(armourFilters) then
			queryFilters.armour_filters = {
				filters = armourFilters
			}
		end
	end

	-- Mod filters
	for i, entry in ipairs(modEntries) do
		local prefix = "mod" .. i
		if entry.tradeId and controls[prefix .. "Check"] and controls[prefix .. "Check"].state then
			local minVal = tonumber(controls[prefix .. "Min"].buf)
			local maxVal = tonumber(controls[prefix .. "Max"].buf)
			local filter = { id = entry.tradeId }
			local value = {}
			if minVal then value.min = minVal end
			if maxVal then value.max = maxVal end
			if next(value) then
				filter.value = value
			end
			t_insert(queryTable.query.stats[1].filters, filter)
		end
	end

	-- Only include filters if we have any
	if next(queryFilters) then
		queryTable.query.filters = queryFilters
	end

	-- Build URL
	local queryJson = dkjson.encode(queryTable)
	local url = hostName .. "trade/search"
	if realm and realm ~= "" and realm ~= "pc" then
		url = url .. "/" .. realm
	end
	local encodedLeague = league:gsub("[^%w%-%.%_%~]", function(c)
		return string.format("%%%02X", string.byte(c))
	end):gsub(" ", "+")
	url = url .. "/" .. encodedLeague
	url = url .. "?q=" .. urlEncode(queryJson)

	return url
end

-- Open the Buy Similar popup for a compared item
function M.openPopup(item, slotName, primaryBuild)
	if not item then return end

	local isUnique = item.rarity == "UNIQUE" or item.rarity == "RELIC"
	local controls = {}
	local rowHeight = 24
	local popupWidth = 700
	local leftMargin = 20
	local minFieldX = popupWidth - 130
	local maxFieldX = popupWidth - 50
	local fieldW = 60
	local fieldH = 20
	local checkboxSize = 20

	-- Collect mod entries with trade IDs
	local modEntries = {}
	local modTypeSources = {
		{ list = item.implicitModLines, type = "implicit" },
		{ list = item.enchantModLines, type = "enchant" },
		{ list = item.scourgeModLines, type = "explicit" },
		{ list = item.explicitModLines, type = "explicit" },
		{ list = item.crucibleModLines, type = "explicit" },
	}
	for _, source in ipairs(modTypeSources) do
		if source.list then
			for _, modLine in ipairs(source.list) do
				if item:CheckModLineVariant(modLine) then
					local formatted = itemLib.formatModLine(modLine)
					if formatted then
						-- Use range-resolved text for matching
						local resolvedLine = (modLine.range and itemLib.applyRange(modLine.line, modLine.range, modLine.valueScalar)) or modLine.line
						local tradeId = tradeHelpers.findTradeModId(resolvedLine, source.type)
						local value = tradeHelpers.modLineValue(resolvedLine)
						t_insert(modEntries, {
							line = modLine.line,
							formatted = formatted:gsub("%^x%x%x%x%x%x%x", ""):gsub("%^%x", ""), -- strip color codes
							tradeId = tradeId,
							value = value,
							modType = source.type,
						})
					end
				end
			end
		end
	end

	-- Collect defence stats for non-unique gear items
	local defenceEntries = {}
	if not isUnique and item.armourData and item.base and item.base.armour then
		local defences = {
			{ key = "Armour", label = "Armour", tradeKey = "ar" },
			{ key = "Evasion", label = "Evasion", tradeKey = "ev" },
			{ key = "EnergyShield", label = "Energy Shield", tradeKey = "es" },
			{ key = "Ward", label = "Ward", tradeKey = "ward" },
		}
		for _, def in ipairs(defences) do
			local val = item.armourData[def.key]
			if val and val > 0 then
				t_insert(defenceEntries, {
					label = def.label,
					value = val,
					tradeKey = def.tradeKey,
				})
			end
		end
	end

	-- Build controls
	local ctrlY = 25

	-- Realm and league dropdowns
	local tradeQuery = primaryBuild.itemsTab and primaryBuild.itemsTab.tradeQuery
	local tradeQueryRequests = tradeQuery and tradeQuery.tradeQueryRequests
	if not tradeQueryRequests then
		tradeQueryRequests = new("TradeQueryRequests")
	end

	-- Helper to fetch and populate leagues for a given realm API id
	local function fetchLeaguesForRealm(realmApiId)
		controls.leagueDrop:SetList({"Loading..."})
		controls.leagueDrop.selIndex = 1
		tradeQueryRequests:FetchLeagues(realmApiId, function(leagues, errMsg)
			if errMsg then
				controls.leagueDrop:SetList({"Standard"})
				return
			end
			local leagueList = {}
			for _, league in ipairs(leagues) do
				if league ~= "Standard" and league ~= "Ruthless" and league ~= "Hardcore" and league ~= "Hardcore Ruthless" then
					if not (league:find("Hardcore") or league:find("Ruthless")) then
						t_insert(leagueList, 1, league)
					else
						t_insert(leagueList, league)
					end
				end
			end
			t_insert(leagueList, "Standard")
			t_insert(leagueList, "Hardcore")
			t_insert(leagueList, "Ruthless")
			t_insert(leagueList, "Hardcore Ruthless")
			controls.leagueDrop:SetList(leagueList)
		end)
	end

	-- Realm dropdown
	controls.realmLabel = new("LabelControl", {"TOPLEFT", nil, "TOPLEFT"}, {leftMargin, ctrlY, 0, 16}, "^7Realm:")
	controls.realmDrop = new("DropDownControl", {"LEFT", controls.realmLabel, "RIGHT"}, {4, 0, 80, 20}, {"PC", "PS4", "Xbox"}, function(index, value)
		local realmApiId = REALM_API_IDS[value] or "pc"
		fetchLeaguesForRealm(realmApiId)
	end)

	-- League dropdown
	controls.leagueLabel = new("LabelControl", {"LEFT", controls.realmDrop, "RIGHT"}, {12, 0, 0, 16}, "^7League:")
	controls.leagueDrop = new("DropDownControl", {"LEFT", controls.leagueLabel, "RIGHT"}, {4, 0, 160, 20}, {"Loading..."}, function(index, value)
		-- League selection stored in the dropdown itself
	end)
	controls.leagueDrop.enabled = function() return #controls.leagueDrop.list > 0 and controls.leagueDrop.list[1] ~= "Loading..." end

	-- Listed status dropdown
	controls.listedDrop = new("DropDownControl", {"TOPRIGHT", nil, "TOPRIGHT"}, {-leftMargin, ctrlY, 242, 20}, LISTED_STATUS_LABELS, function(index, value)
		-- Listed status selection stored in the dropdown itself
	end)
	controls.listedLabel = new("LabelControl", {"RIGHT", controls.listedDrop, "LEFT"}, {-4, 0, 0, 16}, "^7Listed:")

	-- Fetch initial leagues for default realm
	fetchLeaguesForRealm("pc")
	ctrlY = ctrlY + rowHeight + 4

	if isUnique then
		-- Unique item name label
		controls.nameLabel = new("LabelControl", nil, {0, ctrlY, 0, 16}, "^x" .. (colorCodes[item.rarity] or "FFFFFF"):gsub("%^x","") .. item.name)
		ctrlY = ctrlY + rowHeight
	else
		-- Category label
		local categoryLabel = tradeHelpers.getTradeCategoryLabel(slotName, item)
		controls.categoryLabel = new("LabelControl", {"TOPLEFT", nil, "TOPLEFT"}, {leftMargin, ctrlY, 0, 16}, "^7Category: " .. categoryLabel)
		ctrlY = ctrlY + rowHeight

		-- Base type checkbox
		controls.baseTypeCheck = new("CheckBoxControl", nil, {-popupWidth/2 + leftMargin + checkboxSize/2, ctrlY, checkboxSize}, "", nil, nil)
		controls.baseTypeLabel = new("LabelControl", {"LEFT", controls.baseTypeCheck, "RIGHT"}, {4, 0, 0, 16}, "^7Use specific base: " .. (item.baseName or "Unknown"))
		ctrlY = ctrlY + rowHeight

		-- Item level
		ctrlY = ctrlY + 4
		controls.ilvlLabel = new("LabelControl", {"TOPLEFT", nil, "TOPLEFT"}, {leftMargin, ctrlY, 0, 16}, "^7Item Level:")
		controls.ilvlMin = newPlainNumericEdit(nil, {minFieldX - popupWidth/2, ctrlY, fieldW, fieldH}, "", "Min", 4)
		controls.ilvlMax = newPlainNumericEdit(nil, {maxFieldX - popupWidth/2, ctrlY, fieldW, fieldH}, "", "Max", 4)
		ctrlY = ctrlY + rowHeight

		-- Defence stat rows
		for i, def in ipairs(defenceEntries) do
			local prefix = "def" .. i
			controls[prefix .. "Check"] = new("CheckBoxControl", nil, {-popupWidth/2 + leftMargin + checkboxSize/2, ctrlY, checkboxSize}, "", nil, nil)
			controls[prefix .. "Label"] = new("LabelControl", {"LEFT", controls[prefix .. "Check"], "RIGHT"}, {4, 0, 0, 16}, "^7" .. def.label)
			controls[prefix .. "Min"] = newPlainNumericEdit(nil, {minFieldX - popupWidth/2, ctrlY, fieldW, fieldH}, tostring(m_floor(def.value)), "Min", 6)
			controls[prefix .. "Max"] = newPlainNumericEdit(nil, {maxFieldX - popupWidth/2, ctrlY, fieldW, fieldH}, "", "Max", 6)
			ctrlY = ctrlY + rowHeight
		end

		-- Separator between defence stats and mods
		if #defenceEntries > 0 then
			ctrlY = ctrlY + 8
		end
	end

	-- Mod rows
	for i, entry in ipairs(modEntries) do
		local prefix = "mod" .. i
		local canSearch = entry.tradeId ~= nil
		controls[prefix .. "Check"] = new("CheckBoxControl", nil, {-popupWidth/2 + leftMargin + checkboxSize/2, ctrlY, checkboxSize}, "", nil, nil)
		controls[prefix .. "Check"].enabled = function() return canSearch end
		-- Truncate long mod text to fit
		local displayText = entry.formatted
		if #displayText > 45 then
			displayText = displayText:sub(1, 42) .. "..."
		end
		controls[prefix .. "Label"] = new("LabelControl", {"LEFT", controls[prefix .. "Check"], "RIGHT"}, {4, 0, 0, 16}, (canSearch and "^7" or "^8") .. displayText)
		controls[prefix .. "Min"] = newPlainNumericEdit(nil, {minFieldX - popupWidth/2, ctrlY, fieldW, fieldH}, entry.value ~= 0 and tostring(m_floor(entry.value)) or "", "Min", 8)
		controls[prefix .. "Max"] = newPlainNumericEdit(nil, {maxFieldX - popupWidth/2, ctrlY, fieldW, fieldH}, "", "Max", 8)
		if not canSearch then
			controls[prefix .. "Min"].enabled = function() return false end
			controls[prefix .. "Max"].enabled = function() return false end
		end
		ctrlY = ctrlY + rowHeight
	end

	-- Search button
	ctrlY = ctrlY + 8
	controls.search = new("ButtonControl", nil, {0, ctrlY, 110, 20}, "Generate URL", function()
		local success, result = pcall(function()
			return buildURL(item, slotName, controls, modEntries, defenceEntries, isUnique)
		end)
		if success and result then
			controls.uri:SetText(result, true)
		elseif not success then
			controls.uri:SetText("Error: " .. tostring(result), true)
		else
			controls.uri:SetText("Error: could not determine league", true)
		end
	end)
	ctrlY = ctrlY + rowHeight + 4

	-- URL field
	controls.uri = new("EditControl", nil, {-30, ctrlY, popupWidth - 100, fieldH}, "", nil, "^%C\t\n")
	controls.uri:SetPlaceholder("Press 'Generate URL' then Ctrl+Click to open")
	controls.uri.tooltipFunc = function(tooltip)
		tooltip:Clear()
		if controls.uri.buf and controls.uri.buf ~= "" then
			tooltip:AddLine(16, "^7Ctrl + Click to open in web browser")
		end
	end
	controls.close = new("ButtonControl", nil, {popupWidth/2 - 50, ctrlY, 60, 20}, "Close", function()
		main:ClosePopup()
	end)

	-- Calculate popup height from final control position
	local popupHeight = ctrlY + fieldH + 16
	if popupHeight > 600 then popupHeight = 600 end

	local title = "Buy Similar"
	main:OpenPopup(popupWidth, popupHeight, title, controls, "search", nil, "close")
end

return M
