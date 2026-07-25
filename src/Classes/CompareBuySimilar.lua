-- Path of Building
--
-- Module: Compare Buy Similar
-- Buy Similar popup UI and trade search URL builder for the Compare tab.
--
local t_insert = table.insert
local m_floor = math.floor
local dkjson = require "dkjson"
local tradeHelpers = LoadModule("Classes/TradeHelpers")
local tradeStats = tradeHelpers.getTradeStats()

-- used to check what stats actually exist on the trade site.
local existingStats = {}
for _, cat in ipairs(tradeStats or {}) do
	for _, entry in ipairs(cat.entries) do
		existingStats[entry.id] = true
	end
end

local M = {}

-- Realm display name to API id mapping
local REALM_API_IDS = {
	["PC"]   = "pc",
	["PS4"]  = "sony",
	["Xbox"] = "xbox",
}

-- Listed status display names and their API option values
local LISTED_STATUS_OPTIONS = {
	{ label = "Instant Buyout", apiValue = "securable" },
	{ label = "Instant Buyout & In Person", apiValue = "available" },
	{ label = "In Person (Online)", apiValue = "online" },
	{ label = "Any", apiValue = "any" },
}
local LISTED_STATUS_LABELS = { }
for i, entry in ipairs(LISTED_STATUS_OPTIONS) do
	LISTED_STATUS_LABELS[i] = entry.label
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
		local categoryStr, _ = tradeHelpers.getTradeCategory(slotName, item)
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
		local function getFilter(tradeId)
			local filter = { id = tradeId }
			if entry.isOption then
				-- timeless jewels use a min max range despite matching as an option
				filter.value = tradeId:match("timeless") and { min = entry.value, max = entry.value } or
					{ option = entry.value }
			elseif entry.value then
				local minVal = tonumber(controls[prefix .. "Min"].buf)
				local maxVal = tonumber(controls[prefix .. "Max"].buf)
				local value = {}
				if minVal then
					value.min = minVal
				end
				if maxVal then
					value.max = maxVal
				end
				if entry.invert then
					value.min, value.max = value.max, value.min
					value.min = value.min and -value.min
					value.max = value.max and -value.max
				end
				if next(value) then
					filter.value = value
				end
			end
			return filter
		end
		if controls[prefix .. "Check"] and controls[prefix .. "Check"].state then
			if #entry.tradeIds == 1 then
				-- 1 id entries are added to the stat filters section
				t_insert(queryTable.query.stats[1].filters, getFilter(entry.tradeIds[1]))
			elseif #entry.tradeIds > 1 then
				-- ambiguous entries are added as a separate count filter
				local countFilter = { type = "count", value = { min = 1 }, filters = {} }
				for _, tradeId in ipairs(entry.tradeIds) do
					t_insert(countFilter.filters, getFilter(tradeId))
				end
				t_insert(queryTable.query.stats, countFilter)
			end
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

---@param item any
---@param modTypeSources ModTypeSources
---@return table[] entries mod entries used in buy similar popup
function M.addModEntries(item, modTypeSources)
	local modEntries = {}
	-- this adds a single aggregated entry for matching stats (e.g. transformed flat dmg mods) which
	-- avoids issues with confusing results. mods with different types are not summed as e.g.
	-- implicit and explicit mods are separate in the search. options are also avoided as they don't
	-- represent values that can be added combined
	local function insertOrAddToExisting(entry)
		for _, existingFilter in ipairs(modEntries) do
			-- check if all result trade ids are equal
			local sameHashes = #entry.tradeIds > 0 and tableDeepEquals(entry.tradeIds, existingFilter.tradeIds)
			if sameHashes and existingFilter.type == entry.type then
				if entry.value then
					local value = (entry.invert ~= existingFilter.invert) and -entry.value or entry.value or 0
					existingFilter.value = (existingFilter.value or 0) + value
				end
				t_insert(existingFilter.formattedLines, entry.formattedLines[1])
				return
			end
			::continue::
		end
		t_insert(modEntries, entry)
	end
	for _, source in ipairs(modTypeSources) do
		if source.list then
			for _, modLine in ipairs(source.list) do
				if item:CheckModLineVariant(modLine) then
					local modLine = copyTable(modLine)
					-- remove unsupported data. the formatting of unsupported
					-- mods is confusing here
					modLine.extra = nil
					local formatted = itemLib.formatModLine(modLine)
					if formatted then
						-- Use range-resolved text for matching
						local resolvedLine = (modLine.range and itemLib.applyRange(modLine.line, modLine.range, modLine.valueScalar)) or
							modLine.line
						-- check option first, because even if we match a line via the descriptors, the values for option-based stats are different
						local tradeId, value = tradeHelpers.findTradeIdOption(resolvedLine, source.type)

						local entry = {
							-- this array will always start with one line, but if multiple mods are
							-- aggregated together it will contain the original mod lines for each
							formattedLines = { formatted },
							type = source.type,
							isOption = not not tradeId,
							invert = false,
							tradeIds = { tradeId },
							value = value,
						}
						if not tradeId then
							local resultHashes, value, invert = tradeHelpers.findTradeHash(resolvedLine)
							-- convert hashes to string ids
							local resultIds = {}
							if resultHashes then
								for idx = 1, #resultHashes do
									local id = string.format("%s.stat_%s", source.type, resultHashes[idx])
									if existingStats[id] then
										t_insert(resultIds, id)
									end
								end
							end
							entry.tradeIds = resultIds
							entry.value = value
							entry.invert = invert
						end
						insertOrAddToExisting(entry)
					end
				end
			end
		end
	end
	return modEntries
end
-- Open the Buy Similar popup for a compared item
function M.openPopup(item, slotName, primaryBuild)
	if not item then return end

	local isUnique = item.rarity == "UNIQUE" or item.rarity == "RELIC"
	local controls = {}
	local uri = ""
	local rowHeight = 24
	local popupWidth = 700
	local leftMargin = 20
	local minFieldX = popupWidth - 130
	local maxFieldX = popupWidth - 50
	local fieldW = 74
	local fieldH = 20
	local checkboxSize = 20

	---@class ModTypeSources
	local modTypeSources = {
		{ list = item.enchantModLines,  type = "enchant" },
		{ list = item.implicitModLines, type = "implicit" },
		{ list = item.explicitModLines, type = "explicit" },
		{ list = item.scourgeModLines,  type = "scourge" }
		-- disabled due to matching difficulty. the trade site searches for
		-- crucible mods, while for other things, it matches by stats
		-- { list =item.crucibleModLines, type = "crucible" },
	}

	-- Collect mod entries with trade IDs
	local modEntries = M.addModEntries(item, modTypeSources)

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

	local function rebuildUrl()
		local result = buildURL(item, slotName, controls, modEntries, defenceEntries, isUnique)
		uri = result
	end
	-- Helper to fetch and populate leagues for a given realm API id
	local function fetchLeaguesForRealm(realmApiId)
		local lastLeague = M.lastLeagueByRealm and M.lastLeagueByRealm[realmApiId]
		controls.leagueDrop:SetList({"Loading..."})
		controls.leagueDrop.selIndex = 1
		tradeQueryRequests:FetchLeagues(realmApiId, function(leagues, errMsg)
			if errMsg then
				controls.leagueDrop:SetList({"Standard"})
				rebuildUrl()
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
			controls.leagueDrop:SetSel(isValueInArray(leagueList, lastLeague) or 1, true)
			rebuildUrl()
		end)
	end

	-- Realm dropdown
	controls.realmLabel = new("LabelControl", {"TOPLEFT", nil, "TOPLEFT"}, {leftMargin, ctrlY, 0, 16}, "^7Realm:")
	controls.realmDrop = new("DropDownControl", {"LEFT", controls.realmLabel, "RIGHT"}, {4, 0, 80, 20}, {"PC", "PS4", "Xbox"}, function(index, value)
		local realmApiId = REALM_API_IDS[value] or "pc"
		fetchLeaguesForRealm(realmApiId)
		rebuildUrl()
		M.lastRealmIdx = index
	end)
	if M.lastRealmIdx then
		controls.realmDrop:SetSel(M.lastRealmIdx, true)
	end

	-- League dropdown
	controls.leagueLabel = new("LabelControl", {"LEFT", controls.realmDrop, "RIGHT"}, {12, 0, 0, 16}, "^7League:")
	controls.leagueDrop = new("DropDownControl", { "LEFT", controls.leagueLabel, "RIGHT" }, { 4, 0, 160, 20 },
		{ "Loading..." }, function(index, value)
			local realmApiId = REALM_API_IDS[controls.realmDrop:GetSelValue()] or "pc"
			M.lastLeagueByRealm = M.lastLeagueByRealm or {}
			M.lastLeagueByRealm[realmApiId] = value
			rebuildUrl()
	end)
	controls.leagueDrop.enabled = function() return #controls.leagueDrop.list > 0 and controls.leagueDrop.list[1] ~= "Loading..." end

	-- Listed status dropdown
	controls.listedDrop = new("DropDownControl", { "TOPRIGHT", nil, "TOPRIGHT" }, { -leftMargin, ctrlY, 242, 20 }, LISTED_STATUS_LABELS, function(index, value)
		M.lastListedIndex = index
		rebuildUrl()
	end)
	if M.lastListedIndex then
		controls.listedDrop:SetSel(M.lastListedIndex, true)
	end
	controls.listedLabel = new("LabelControl", {"RIGHT", controls.listedDrop, "LEFT"}, {-4, 0, 0, 16}, "^7Listed:")

	-- Fetch initial leagues for the selected realm
	fetchLeaguesForRealm(REALM_API_IDS[controls.realmDrop:GetSelValue()] or "pc")
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
		controls.baseTypeCheck = new("CheckBoxControl", nil, {-popupWidth/2 + leftMargin + checkboxSize/2, ctrlY, checkboxSize}, "", rebuildUrl)
		controls.baseTypeLabel = new("LabelControl", {"LEFT", controls.baseTypeCheck, "RIGHT"}, {4, 0, 0, 16}, "^7Use specific base: " .. (item.baseName or "Unknown"))
		ctrlY = ctrlY + rowHeight

		-- Item level
		ctrlY = ctrlY + 4
		controls.ilvlLabel = new("LabelControl", {"TOPLEFT", nil, "TOPLEFT"}, {leftMargin, ctrlY, 0, 16}, "^7Item Level:")
		controls.ilvlMin = tradeHelpers.newPlainNumericEdit(nil, { minFieldX - popupWidth / 2, ctrlY, fieldW, fieldH }, "", "Min", 4, true, rebuildUrl)
		controls.ilvlMax = tradeHelpers.newPlainNumericEdit(nil, { maxFieldX - popupWidth / 2, ctrlY, fieldW, fieldH }, "", "Max", 4, true, rebuildUrl)
		ctrlY = ctrlY + rowHeight

		-- Defence stat rows
		for i, def in ipairs(defenceEntries) do
			local prefix = "def" .. i
			controls[prefix .. "Check"] = new("CheckBoxControl", nil, {-popupWidth/2 + leftMargin + checkboxSize/2, ctrlY, checkboxSize}, "", rebuildUrl)
			controls[prefix .. "Label"] = new("LabelControl", {"LEFT", controls[prefix .. "Check"], "RIGHT"}, {4, 0, 0, 16}, "^7" .. def.label)
			controls[prefix .. "Min"] = tradeHelpers.newPlainNumericEdit(nil, { minFieldX - popupWidth / 2, ctrlY, fieldW, fieldH }, tostring(m_floor(def.value)), "Min", 6, true, rebuildUrl)
			controls[prefix .. "Max"] = tradeHelpers.newPlainNumericEdit(nil, { maxFieldX - popupWidth / 2, ctrlY, fieldW, fieldH }, "", "Max", 6, true, rebuildUrl)
			ctrlY = ctrlY + rowHeight
		end

		-- Separator between defence stats and mods
		if #defenceEntries > 0 then
			ctrlY = ctrlY + 8
		end
	end

	-- Mod rows
	local prevType
	for i, entry in ipairs(modEntries) do
		-- add extra row to separate e.g. implicits
		if prevType and prevType ~= entry.type then
			ctrlY = ctrlY + rowHeight
		end
		prevType = entry.type
		local prefix = "mod" .. i
		local canSearch = #entry.tradeIds > 0

		local rows = #entry.formattedLines

		local fontSize = 16
		-- adjust down by half a text row for each row over 1
		local controlYPos = ctrlY + (rows - 1) * 8
		local checkBoxXPos = -popupWidth/2 + leftMargin + checkboxSize/2
		controls[prefix .. "Check"] = new("CheckBoxControl", nil, {checkBoxXPos, controlYPos, checkboxSize}, "", rebuildUrl)
		controls[prefix .. "Check"].enabled = function() return canSearch end


		-- Truncate long mod text to fit
		--- @type string[]
		local displayTexts = entry.formattedLines
		for index, displayText in ipairs(displayTexts) do
			-- shorten time-lost jewel affix labels to fit better
			displayText = displayText:gsub(" Passive Skills in Radius also grant", ":")
			local colorCodeLength = displayText:match("(%^x%x%x%x%x%x%x)") or displayText:gsub("(%^%x)", "") or ""

			if not canSearch then
				-- strip color codes and replace with gray
				displayText = "^8" .. displayText:gsub("%^x%x%x%x%x%x%x", ""):gsub("%^%x", "")
			end
			if #displayText > (#colorCodeLength + 62) then
				displayText = displayText:sub(1, #colorCodeLength + 54) .. "..."
			end
			displayTexts[index] = displayText
		end


		local displayText = table.concat(displayTexts, "\n")
		-- labels anchor based on the first row instead of the middle row, so adjust upwards
		local labelXOffset = (rows - 1) * -8

		controls[prefix .. "Label"] = new("LabelControl", {"LEFT", controls[prefix .. "Check"], "RIGHT"},{ 4, labelXOffset, 0, fontSize },
			displayText)
		-- when the trade site has a dropdown for the value, we opt to disable
		-- the inputs as they are numeric
		if not (entry.isOption or entry.needsExactValue) and entry.value then
			controls[prefix .. "Min"] = tradeHelpers.newPlainNumericEdit(nil, { minFieldX - popupWidth / 2, controlYPos, fieldW, fieldH }, entry.value ~= 0 and tostring(entry.value) or "", "Min", 8, nil, rebuildUrl)
			controls[prefix .. "Max"] = tradeHelpers.newPlainNumericEdit(nil, { maxFieldX - popupWidth / 2, controlYPos, fieldW, fieldH }, "", "Max", 8, nil, rebuildUrl)
			if not canSearch then
				controls[prefix .. "Min"].enabled = function() return false end
				controls[prefix .. "Max"].enabled = function() return false end
			end
		end
		ctrlY = ctrlY + math.max(rowHeight, fontSize*rows + 8)
	end

	-- Search button
	ctrlY = ctrlY + 8
	controls.search = new("ButtonControl", nil, {0, ctrlY, 110, 20}, "Open URL", function()
		Copy(uri)
		OpenURL(uri)
	end, nil)
	controls.search.tooltipText = "The URL is also copied to the clipboard."
	controls.search.enabled = function()
		return uri and uri ~= ""
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
