-- Path of Building
--
-- Module: Trade Query
-- Provides PoB Trader pane for interacting with PoE Trade
--


local dkjson = require "dkjson"

local get_time = os.time
local t_insert = table.insert
local t_remove = table.remove
local m_max = math.max
local m_min = math.min
local m_ceil = math.ceil
local s_format = string.format

local baseSlots = { "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2", "Belt", "Flask 1", "Flask 2", "Flask 3", "Flask 4", "Flask 5" }


local TradeQueryClass = newClass("TradeQuery", function(self, itemsTab)
	self.itemsTab = itemsTab
	self.itemsTab.leagueDropList = { }
	self.totalPrice = { }
	self.controls = { }
	-- table of price results index by slot and number of fetched results
	self.resultTbl = { }
	self.sortedResultTbl = { }
	self.itemIndexTbl = { }
	-- tooltip acceleration tables
	self.onlyWeightedBaseOutput = { }
	self.lastComparedWeightList = { }

	-- default set of trade item sort selection
	self.slotTables = { }
	self.pbItemSortSelectionIndex = 1
	self.pbCurrencyConversion = { }
	self.currencyConversionTradeMap = { }
	self.lastCurrencyConversionRequest = 0
	self.lastCurrencyFileTime = { }
	self.pbFileTimestampDiff = { }
	self.pbRealm = ""
	self.pbRealmIndex = 1
	self.pbLeagueIndex = 1
	-- table holding all realm/league pairs. (allLeagues[realm] = [league.id,...])
	self.allLeagues = {}
	-- realm id-text table to pair realm name with API parameter
	self.realmIds = {}

	self.tradeQueryRequests = new("TradeQueryRequests")
	main.onFrameFuncs["TradeQueryRequests"] = function()
		self.tradeQueryRequests:ProcessQueue()
	end

	-- set 
	self.storedGlobalCacheDPSView = GlobalCache.useFullDPS
	GlobalCache.useFullDPS = GlobalCache.numActiveSkillInFullDPS > 0
	self.hostName = "https://www.pathofexile.com/"
end)

---Fetch currency short-names from Poe API (used for PoeNinja price pairing)
---@param callback fun()
function TradeQueryClass:FetchCurrencyConversionTable(callback)
	launch:DownloadPage(
		"https://www.pathofexile.com/api/trade/data/static",
		function(response, errMsg)
			if errMsg then
				callback(response, errMsg)
				return
			end
			local obj = dkjson.decode(response.body)
			local currencyConversionTradeMap = {}
			local currencyTable
			for _, value in pairs(obj.result) do
				if value.id and value.id == "Currency" then
					currencyTable = value.entries
					break
				end
			end
			for _, value in pairs(currencyTable) do
				currencyConversionTradeMap[value.text] = value.id
			end
			self.currencyConversionTradeMap = currencyConversionTradeMap
			if callback then
				callback()
			end
		end)
end


-- Method to pull down and interpret available leagues from PoE
function TradeQueryClass:PullLeagueList()
	launch:DownloadPage(
		self.hostName .. "api/leagues?type=main&compact=1",
		function(response, errMsg)
			if errMsg then
				self:SetNotice(self.controls.pbNotice, "Error: " .. tostring(errMsg))
				return "POE ERROR", "Error: "..errMsg
			else
				local json_data = dkjson.decode(response.body)
				if not json_data then
					self:SetNotice(self.controls.pbNotice, "Failed to Get PoE League List response")
					return
				end
				table.sort(json_data, function(a, b)
					if a.endAt == nil then return false end
					if b.endAt == nil then return true end
					return #a.id < #b.id
				end)
				self.itemsTab.leagueDropList = {}
				for _, league_data in pairs(json_data) do
					if not league_data.id:find("SSF") then
						t_insert(self.itemsTab.leagueDropList,league_data.id)
					end
				end
				self.controls.league:SetList(self.itemsTab.leagueDropList)
				self.controls.league.selIndex = 1
				self.pbLeague = self.itemsTab.leagueDropList[self.controls.league.selIndex]
				self:SetCurrencyConversionButton()
			end
		end)
end

-- Method to convert currency to chaos equivalent
function TradeQueryClass:ConvertCurrencyToChaos(currency, amount)
	local conversionTable = self.pbCurrencyConversion[self.pbLeague]

	-- we take the ceiling of all prices to integer chaos
	-- to prevent dealing with shenanigans of people asking 4.9 chaos
	if conversionTable and conversionTable[currency:lower()] then
		--ConPrintf("Converted '"..currency.."' at " ..tostring(conversionTable[currency:lower()]))
		return m_ceil(amount * conversionTable[currency:lower()])
	elseif currency:lower() == "chaos" then
		return m_ceil(amount)
	else
		ConPrintf("Unhandled Currency Conversion: '" .. currency:lower() .. "'")
		return nil
	end
end

-- Method to pull down and interpret the PoE.Ninja JSON endpoint data
function TradeQueryClass:PullPoENinjaCurrencyConversion(league)
	local now = get_time()
	-- Limit PoE Ninja Currency Conversion request to 1 per hour
	if (now - self.lastCurrencyConversionRequest) < 3600 then
		self:SetNotice(self.controls.pbNotice, "PoE Ninja Rate Limit Exceeded: " .. tostring(3600 - (now - self.lastCurrencyConversionRequest)))
		return
	end
	-- We are getting currency short-names from Poe API before getting PoeNinja rates
	-- Potentially, currency short-names could be cached but this request runs 
	-- once per hour at most and the Poe API response is already Cloudflare cached
	self:FetchCurrencyConversionTable(function(data, errMsg)
		if errMsg then
			self:SetNotice(self.controls.pbNotice, "Error: " .. tostring(errMsg))
			return
		end
		self.pbCurrencyConversion[league] = { }
		self.lastCurrencyConversionRequest = now
		launch:DownloadPage(
			"https://poe.ninja/api/data/CurrencyRates?league=" .. urlEncode(league),	
			function(response, errMsg)
				if errMsg then
					self:SetNotice(self.controls.pbNotice, "Error: " .. tostring(errMsg))
					return
				end
				local json_data = dkjson.decode(response.body)
				if not json_data then
					self:SetNotice(self.controls.pbNotice, "Failed to Get PoE Ninja response")
					return
				end
				self:PriceBuilderProcessPoENinjaResponse(json_data, self.controls)
				local print_str = ""
				for key, value in pairs(self.pbCurrencyConversion[self.pbLeague]) do
					print_str = print_str .. '"'..key..'": '..tostring(value)..','
				end
				local foo = io.open("../"..self.pbLeague.."_currency_values.json", "w")
				foo:write("{" .. print_str .. '"updateTime": ' .. tostring(get_time()) .. "}")
				foo:close()
				self:SetCurrencyConversionButton()
			end)
	end)
end

-- Method to process the PoE.Ninja response
function TradeQueryClass:PriceBuilderProcessPoENinjaResponse(resp)
	if resp then
		-- Populate the chaos-converted values for each tradeId
		for currencyName, chaosEquivalent in pairs(resp) do
			if self.currencyConversionTradeMap[currencyName] then
				self.pbCurrencyConversion[self.pbLeague][self.currencyConversionTradeMap[currencyName]] = chaosEquivalent
			else
				ConPrintf("Unhandled Currency Name: '"..currencyName.."'")
			end
		end
	else
		self:SetNotice(self.controls.pbNotice, "PoE Ninja JSON Processing Error")
	end
end

local function initStatSortSelectionList(list)
	t_insert(list,  {
		label = "Full DPS",
		stat = "FullDPS",
		weightMult = 1.0,
	})
	t_insert(list,  {
		label = "Effective Hit Pool",
		stat = "TotalEHP",
		weightMult = 0.5,
	})
end

-- we do not want to overwrite previous list if the new list is the default, e.g. hitting reset multiple times in a row
local function isSameAsDefaultList(list)
	return list and #list == 2
		and list[1].stat == "FullDPS" and list[1].weightMult == 1.0
		and list[2].stat == "TotalEHP" and list[2].weightMult == 0.5
end

-- Opens the item pricing popup
function TradeQueryClass:PriceItem()
	self.tradeQueryGenerator = new("TradeQueryGenerator", self)
	main.onFrameFuncs["TradeQueryGenerator"] = function()
		self.tradeQueryGenerator:OnFrame()
	end

	-- Set main Price Builder pane height and width
	local row_height = 20
	local row_vertical_padding = 4
	local top_pane_alignment_ref = nil
	local pane_margins_horizontal = 16
	local pane_margins_vertical = 16

	local newItemList = { }
	for index, itemSetId in ipairs(self.itemsTab.itemSetOrderList) do
		local itemSet = self.itemsTab.itemSets[itemSetId]
		t_insert(newItemList, itemSet.title or "Default")
	end
	self.controls.setSelect = new("DropDownControl", {"TOPLEFT", nil, "TOPLEFT"}, pane_margins_horizontal, pane_margins_vertical, 188, row_height, newItemList, function(index, value)
		self.itemsTab:SetActiveItemSet(self.itemsTab.itemSetOrderList[index])
		self.itemsTab:AddUndoState()
	end)
	self.controls.setSelect.enableDroppedWidth = true
	self.controls.setSelect.enabled = function()
		return #self.itemsTab.itemSetOrderList > 1
	end

	self.controls.poesessidButton = new("ButtonControl", {"TOPLEFT", self.controls.setSelect, "TOPLEFT"}, 0, row_height + row_vertical_padding, 188, row_height, function() return main.POESESSID ~= "" and "^2Session Mode" or colorCodes.WARNING.."No Session Mode" end, function()
		local poesessid_controls = {}
		poesessid_controls.sessionInput = new("EditControl", nil, 0, 18, 350, 18, main.POESESSID, nil, "%X", 32)
		poesessid_controls.sessionInput:SetProtected(true)
		poesessid_controls.sessionInput.placeholder = "Enter your session ID here"
		poesessid_controls.sessionInput.tooltipText = "You can get this from your web browser's cookies while logged into the Path of Exile website."
		poesessid_controls.save = new("ButtonControl", {"TOPRIGHT", poesessid_controls.sessionInput, "TOP"}, -8, 24, 90, row_height, "Save", function()
			main.POESESSID = poesessid_controls.sessionInput.buf
			main:ClosePopup()
			main:SaveSettings()
			self:UpdateRealms()
		end)
		poesessid_controls.save.enabled = function() return #poesessid_controls.sessionInput.buf == 32 or poesessid_controls.sessionInput.buf == "" end
		poesessid_controls.cancel = new("ButtonControl", {"TOPLEFT", poesessid_controls.sessionInput, "TOP"}, 8, 24, 90, row_height, "Cancel", function()
			main:ClosePopup()
		end)
		main:OpenPopup(364, 72, "Change session ID", poesessid_controls)
	end)
	self.controls.poesessidButton.tooltipText = [[
The Trader feature supports two modes of operation depending on the POESESSID availability.
You can click this button to enter your POESESSID.

^2Session Mode^7
- Requires POESESSID.
- You can search, compare, and quickly import items without leaving Path of Building.
- You can generate and perform searches for the private leagues you are participating.

^xFF9922No Session Mode^7
- Doesn't require POESESSID.
- You cannot search and compare items in Path of Building.
- You can generate weighted search URLs but have to visit the trade site and manually import items.
- You can only generate weighted searches for public leagues. (Generated searches can be modified
on trade site to work on other leagues and realms)]]
	
-- Fetches Box
	self.maxFetchPerSearchDefault = 2
	self.controls.fetchCountEdit = new("EditControl", {"TOPRIGHT", nil, "TOPRIGHT"}, -12, 19, 154, row_height, "", "Fetch Pages", "%D", 3, function(buf)
		self.maxFetchPages = m_min(m_max(tonumber(buf) or self.maxFetchPerSearchDefault, 1), 10)
		self.tradeQueryRequests.maxFetchPerSearch = 10 * self.maxFetchPages
		self.controls.fetchCountEdit.focusValue = self.maxFetchPages
	end)
	self.controls.fetchCountEdit.focusValue = self.maxFetchPerSearchDefault
	self.tradeQueryRequests.maxFetchPerSearch = 10 * self.maxFetchPerSearchDefault
	self.controls.fetchCountEdit:SetText(tostring(self.maxFetchPages or self.maxFetchPerSearchDefault))
	function self.controls.fetchCountEdit:OnFocusLost()
		self:SetText(tostring(self.focusValue))
	end
	self.controls.fetchCountEdit.tooltipFunc = function(tooltip)
		tooltip:Clear()
		tooltip:AddLine(16, "Specify maximum number of item pages to retrieve per search from PoE Trade.")
		tooltip:AddLine(16, "Each page fetches up to 10 items.")
		tooltip:AddLine(16, "Acceptable Range is: 1 to 10")
	end

	-- Stat sort popup button
	-- if the list is nil or empty, set default sorting, otherwise keep whatever was loaded from xml
	if not self.statSortSelectionList or (#self.statSortSelectionList) == 0 then
		self.statSortSelectionList = { }
		initStatSortSelectionList(self.statSortSelectionList)
	end
	self.controls.StatWeightMultipliersButton = new("ButtonControl", {"TOPRIGHT", self.controls.fetchCountEdit, "BOTTOMRIGHT"}, 0, row_vertical_padding, 150, row_height, "^7Adjust search weights", function()
		self.itemsTab.modFlag = true
		self:SetStatWeights()
	end)
	self.controls.StatWeightMultipliersButton.tooltipFunc = function(tooltip)
		tooltip:Clear()
		tooltip:AddLine(16, "Sorts the weights by the stats selected multiplied by a value")
		tooltip:AddLine(16, "Currently sorting by:")
		for _, stat in ipairs(self.statSortSelectionList) do
			tooltip:AddLine(16, s_format("%s: %.2f", stat.label, stat.weightMult))
		end
	end
	self.sortModes = {
		StatValue = "(Highest) Stat Value",
		StatValuePrice = "Stat Value / Price",
		Price = "(Lowest) Price",
		Weight = "(Highest) Weighted Sum",
	}
	-- Item sort dropdown
	self.itemSortSelectionList = {
		self.sortModes.StatValue,
		self.sortModes.StatValuePrice,
		self.sortModes.Price,
		self.sortModes.Weight,
	}
	self.controls.itemSortSelection = new("DropDownControl", {"TOPRIGHT", self.controls.StatWeightMultipliersButton, "TOPLEFT"}, -8, 0, 170, row_height, self.itemSortSelectionList, function(index, value)
		self.pbItemSortSelectionIndex = index
		for row_idx, _ in pairs(self.resultTbl) do
			self:UpdateControlsWithItems(row_idx)
		end
	end)
	self.controls.itemSortSelection.tooltipText = 
[[Weighted Sum searches will always sort using descending weighted sum
Additional post filtering options can be done these include:
Highest Stat Value - Sort from highest to lowest Stat Value change of equipping item
Highest Stat Value / Price - Sorts from highest to lowest Stat Value per currency
Lowest Price - Sorts from lowest to highest price of retrieved items
Highest Weight - Displays the order retrieved from trade]]
	self.controls.itemSortSelection:SetSel(self.pbItemSortSelectionIndex)
	self.controls.itemSortSelectionLabel = new("LabelControl", {"TOPRIGHT", self.controls.itemSortSelection, "TOPLEFT"}, -4, 0, 60, 16	, "^7Sort By:")
	
	-- Use Enchant in DPS sorting
	self.controls.enchantInSort = new("CheckBoxControl", {"TOPRIGHT",self.controls.fetchCountEdit,"TOPLEFT"}, -8, 0, row_height, "Include Enchants:", function(state)
		self.enchantInSort = state
		for index, _ in pairs(self.resultTbl) do
			self:UpdateControlsWithItems({name = baseSlots[index]}, index)
		end
	end)
	self.controls.enchantInSort.tooltipText = "This includes enchants in sorting that occurs after trade results have been retrieved"

	-- Realm selection
	self.controls.realmLabel = new("LabelControl", {"LEFT", self.controls.setSelect, "RIGHT"}, 18, 0, 20, row_height - 4, "^7Realm:")
	self.controls.realm = new("DropDownControl", {"LEFT", self.controls.realmLabel, "RIGHT"}, 6, 0, 150, row_height, self.realmDropList, function(index, value)
		self.pbRealmIndex = index
		self.pbRealm = self.realmIds[value]
		local function setLeagueDropList()
			self.itemsTab.leagueDropList = copyTable(self.allLeagues[self.pbRealm])
			self.controls.league:SetList(self.itemsTab.leagueDropList)
			-- invalidate selIndex to trigger select function call in the SetSel
			self.controls.league.selIndex = nil
			self.controls.league:SetSel(self.pbLeagueIndex)
			self:SetCurrencyConversionButton()
		end
		if self.allLeagues[self.pbRealm] then
			setLeagueDropList()
		else
			self.tradeQueryRequests:FetchLeagues(self.pbRealm, function(leagues, errMsg)
				if errMsg then
					self:SetNotice("Error while fetching league list: "..errMsg)
					return
				end
				local sorted_leagues = { }
				for _, league in ipairs(leagues) do
					if league ~= "Standard" and  league ~= "Ruthless" and league ~= "Hardcore" and league ~= "Hardcore Ruthless" then
						t_insert(sorted_leagues, league)
					end
				end
				t_insert(sorted_leagues, "Standard")
				t_insert(sorted_leagues, "Hardcore")
				t_insert(sorted_leagues, "Ruthless")
				t_insert(sorted_leagues, "Hardcore Ruthless")
				self.allLeagues[self.pbRealm] = sorted_leagues
				setLeagueDropList()
			end)
		end
	end)
	self.controls.realm:SetSel(self.pbRealmIndex)
	self.controls.realm.enabled = function()
		return #self.controls.realm.list > 1
	end

	-- League selection
	self.controls.leagueLabel = new("LabelControl", {"TOPRIGHT", self.controls.realmLabel, "TOPRIGHT"}, 0, row_height + row_vertical_padding, 20, row_height - 4, "^7League:")
	self.controls.league = new("DropDownControl", {"LEFT", self.controls.leagueLabel, "RIGHT"}, 6, 0, 150, row_height, self.itemsTab.leagueDropList, function(index, value)
		self.pbLeagueIndex = index
		self.pbLeague = value
		self:SetCurrencyConversionButton()
	end)
	self.controls.league:SetSel(self.pbLeagueIndex)
	self.controls.league.enabled = function()
		return #self.controls.league.list > 1
	end

	if  self.pbRealm == "" then
		self:UpdateRealms()
	end
	-- Individual slot rows
	local slotTables = {}
	for _, slotName in ipairs(baseSlots) do
		t_insert(slotTables, { slotName = slotName })
	end
	local activeSocketList = { }
	for nodeId, slot in pairs(self.itemsTab.sockets) do
		if not slot.inactive then
			t_insert(activeSocketList, nodeId)
		end
	end
	table.sort(activeSocketList)
	for _, nodeId in ipairs(activeSocketList) do
		t_insert(slotTables, { slotName = self.itemsTab.sockets[nodeId].label, nodeId = nodeId })
	end

	self.controls.sectionAnchor = new("LabelControl", { "LEFT", self.controls.poesessidButton, "LEFT" }, 0, 0, 0, 0, "")
	top_pane_alignment_ref = {"TOPLEFT", self.controls.sectionAnchor, "TOPLEFT"}
	local scrollBarShown = #activeSocketList > 6 -- clipping start at Socket 7
	-- dynamically hide rows that are above or below the scrollBar
	local hideRowFunc = function(self, index)
		if scrollBarShown then
			-- 22 items fit in the scrollBar "box" so as the offset moves, we need to dynamically show what is within the boundaries
			if (index < 23 and (self.controls.scrollBar.offset < ((row_height + row_vertical_padding)*(index-1) + row_vertical_padding))) or
				(index >= 23 and (self.controls.scrollBar.offset > (row_height + row_vertical_padding)*(index-22))) then
				return true
			end
		else
			return true
		end
		return false
	end
	for index, slotTbl in pairs(slotTables) do
		self.slotTables[index] = slotTbl
		self:PriceItemRowDisplay(index, top_pane_alignment_ref, row_vertical_padding, row_height)
		self.controls["name"..index].shown = function()
			return hideRowFunc(self, index)
		end
	end

	self.controls.otherTradesLabel = new("LabelControl", top_pane_alignment_ref, 0, (#slotTables+1)*(row_height + row_vertical_padding), 100, 16, "^8Other trades:")
	self.controls.otherTradesLabel.shown = function()
		return hideRowFunc(self, #slotTables+1)
	end
	local row_count = #slotTables + 1
	self.slotTables[row_count] = { slotName = "Megalomaniac", unique = true, alreadyCorrupted = true }
	self:PriceItemRowDisplay(row_count, top_pane_alignment_ref, row_vertical_padding, row_height)
	self.controls["name"..row_count].y = self.controls["name"..row_count].y + (row_height + row_vertical_padding) -- Megalomaniac needs to drop an extra row for "Other Trades"
	self.controls["name"..row_count].shown = function()
		return hideRowFunc(self, row_count)
	end
	row_count = row_count + 1

	local effective_row_count = row_count - ((scrollBarShown and #activeSocketList >= 4) and #activeSocketList-4 or 0) + 2 + 2 -- Two top menu rows, two bottom rows, 4 sockets overlap the other controls at the bottom of the pane
	self.effective_rows_height = row_height * (effective_row_count - #activeSocketList + 3 or 0) -- scrollBar height
	self.pane_height = (row_height + row_vertical_padding) * effective_row_count + 2 * pane_margins_vertical + row_height / 2
	local pane_width = 850 + (scrollBarShown and 25 or 0)

	self.controls.scrollBar = new("ScrollBarControl", {"TOPRIGHT", self.controls["StatWeightMultipliersButton"],"TOPRIGHT"}, 0, 25, 18, 0, 50, "VERTICAL", false)
	self.controls.scrollBar.shown = function()
		return scrollBarShown
	end

	self.controls.fullPrice = new("LabelControl", {"BOTTOM", nil, "BOTTOM"}, 0, -row_height - pane_margins_vertical - row_vertical_padding, pane_width - 2 * pane_margins_horizontal, row_height, "")
	GlobalCache.useFullDPS = GlobalCache.numActiveSkillInFullDPS > 0
	self.controls.close = new("ButtonControl", {"BOTTOM", nil, "BOTTOM"}, 0, -pane_margins_vertical, 90, row_height, "Done", function()
		GlobalCache.useFullDPS = self.storedGlobalCacheDPSView
		main:ClosePopup()
		-- there's a case where if you have a socket(s) allocated, open TradeQuery, close it, dealloc, then open TradeQuery again
		-- the deallocated socket controls were still showing, so this will give us a clean slate of controls every time
		wipeTable(self.controls)
	end)

	self.controls.updateCurrencyConversion = new("ButtonControl", {"BOTTOMLEFT", nil, "BOTTOMLEFT"}, pane_margins_horizontal, -pane_margins_vertical, 240, row_height, "Get Currency Conversion Rates", function()
		self:PullPoENinjaCurrencyConversion(self.pbLeague)
	end)
	self.controls.pbNotice = new("LabelControl",  {"BOTTOMRIGHT", nil, "BOTTOMRIGHT"}, -row_height - pane_margins_vertical - row_vertical_padding, -pane_margins_vertical, 300, row_height, "")

	-- used in PopupDialog:Draw()
	local function scrollBarFunc()
		self.controls.scrollBar.height = self.pane_height-100
		self.controls.scrollBar:SetContentDimension(self.pane_height-100, self.effective_rows_height)
		self.controls.sectionAnchor.y = -self.controls.scrollBar.offset
	end
	main:OpenPopup(pane_width, self.pane_height, "Trader", self.controls, nil, nil, "close", scrollBarFunc)
end

-- Popup to set stat weight multipliers for sorting
function TradeQueryClass:SetStatWeights(previousSelectionList)
    local controls = { }
    local statList = { }
	local sliderController = { index = 1 }
    local popupHeight = 285
	
	controls.ListControl = new("TradeStatWeightMultiplierListControl", { "TOPLEFT", nil, "TOPRIGHT" }, -410, 45, 400, 200, statList, sliderController)

	for id, stat in pairs(data.powerStatList) do
		if not stat.ignoreForItems and stat.label ~= "Name" then
			t_insert(statList, {
				label = "0      :  "..stat.label,
				stat = {
					label = stat.label,
					stat = stat.stat,
					transform = stat.transform,
					weightMult = 0,
				}
			})
		end
	end
	
	controls.SliderLabel = new("LabelControl", { "TOPLEFT", nil, "TOPRIGHT" }, -410, 20, 0, 16, "^7"..statList[1].stat.label..":")
	controls.Slider = new("SliderControl", { "TOPLEFT", controls.SliderLabel, "TOPRIGHT" }, 20, 0, 150, 16, function(value)
		if value == 0 then
			controls.SliderValue.label = "^7Disabled"
			statList[sliderController.index].stat.weightMult = 0
			statList[sliderController.index].label = s_format("%d      :  ", 0)..statList[sliderController.index].stat.label
		else
			controls.SliderValue.label = s_format("^7%.2f", 0.01 + value * 0.99)
			statList[sliderController.index].stat.weightMult = 0.01 + value * 0.99
			statList[sliderController.index].label = s_format("%.2f :  ", 0.01 + value * 0.99)..statList[sliderController.index].stat.label
		end
	end)
	controls.SliderValue = new("LabelControl", { "TOPLEFT", controls.Slider, "TOPRIGHT" }, 20, 0, 0, 16, "^7Disabled")
	controls.Slider.tooltip.realDraw = controls.Slider.tooltip.Draw
	controls.Slider.tooltip.Draw = function(self, x, y, width, height, viewPort)
		local sliderOffsetX = round(184 * (1 - controls.Slider.val))
		local tooltipWidth, tooltipHeight = self:GetSize()
		if main.screenW >= 1338 - sliderOffsetX then
			return controls[stat.label.."Slider"].tooltip.realDraw(self, x - 8 - sliderOffsetX, y - 4 - tooltipHeight, width, height, viewPort)
		end
		return controls.Slider.tooltip.realDraw(self, x, y, width, height, viewPort)
	end
	sliderController.SliderLabel = controls.SliderLabel
	sliderController.Slider = controls.Slider
	sliderController.SliderValue = controls.SliderValue
	
	for _, statBase in ipairs(self.statSortSelectionList) do
		for _, stat in ipairs(statList) do
			if stat.stat.stat == statBase.stat then
				stat.stat.weightMult = statBase.weightMult
				stat.label = s_format("%.2f :  ", statBase.weightMult)..statBase.label
				if statList[sliderController.index].stat.stat == statBase.stat then
					controls.Slider:SetVal(statBase.weightMult == 1 and 1 or statBase.weightMult - 0.01)
				end
			end
		end
	end

	controls.finalise = new("ButtonControl", { "BOTTOM", nil, "BOTTOM" }, -90, -10, 80, 20, "Save", function()
		main:ClosePopup()
		
		-- used in ItemsTab to save to xml under TradeSearchWeights node
		local statSortSelectionList = {}
		for stat, statTable in pairs(statList) do
			if statTable.stat.weightMult > 0 then
				t_insert(statSortSelectionList, statTable.stat)
			end
		end
		if (#statSortSelectionList) > 0 then
			--THIS SHOULD REALLY GIVE A WARNING NOT JUST USE PREVIOUS
			self.statSortSelectionList = statSortSelectionList
		end
		for row_idx in pairs(self.resultTbl) do
			self:UpdateControlsWithItems(row_idx)
		end
    end)
	controls.cancel = new("ButtonControl", { "BOTTOM", nil, "BOTTOM" }, 0, -10, 80, 20, "Cancel", function()
		if previousSelectionList and #previousSelectionList > 0 then
			self.statSortSelectionList = copyTable(previousSelectionList, true)
		end
		main:ClosePopup()
	end)
	controls.reset = new("ButtonControl", { "BOTTOM", nil, "BOTTOM" }, 90, -10, 80, 20, "Reset", function()
		local previousSelection = { }
		if isSameAsDefaultList(self.statSortSelectionList) then
			previousSelection = copyTable(previousSelectionList, true)
		else
			previousSelection = copyTable(self.statSortSelectionList, true) -- this is so we can revert if user hits Cancel after Reset
		end
		self.statSortSelectionList = { }
		initStatSortSelectionList(self.statSortSelectionList)
		main:ClosePopup()
		self:SetStatWeights(previousSelection)
	end)
	main:OpenPopup(420, popupHeight, "Stat Weight Multipliers", controls)
end

-- Method to update the Currency Conversion button label
function TradeQueryClass:SetCurrencyConversionButton()
	local currencyLabel = "Update Currency Conversion Rates"
	self.pbFileTimestampDiff[self.controls.league.selIndex] = nil
	if self.pbLeague == nil then
		return
	end
	if self.pbRealm ~= "pc" then
		self.controls.updateCurrencyConversion.label = "Currency Rates are not available"
		self.controls.updateCurrencyConversion.enabled = false
		self.controls.updateCurrencyConversion.tooltipFunc = function(tooltip)
			tooltip:Clear()
			tooltip:AddLine(16, "Currency Conversion rates are pulled from PoE Ninja")
			tooltip:AddLine(16, "The data is only available for the PC realm.")
		end
		return
	end
	local values_file = io.open("../"..self.pbLeague.."_currency_values.json", "r")
	if values_file then
		local lines = values_file:read "*a"
		values_file:close()
		self.pbCurrencyConversion[self.pbLeague] = dkjson.decode(lines)
		self.lastCurrencyFileTime[self.controls.league.selIndex]  = self.pbCurrencyConversion[self.pbLeague]["updateTime"]
		self.pbFileTimestampDiff[self.controls.league.selIndex] = get_time() - self.lastCurrencyFileTime[self.controls.league.selIndex]
		if self.pbFileTimestampDiff[self.controls.league.selIndex] < 3600 then
			-- Less than 1 hour (60 * 60 = 3600)
			currencyLabel = "Currency Rates are very recent"
		elseif self.pbFileTimestampDiff[self.controls.league.selIndex] < (24 * 3600) then
			-- Less than 1 day
			currencyLabel = "Currency Rates are recent"
		end
	else
		currencyLabel = "Get Currency Conversion Rates"
	end
	self.controls.updateCurrencyConversion.label = currencyLabel
	self.controls.updateCurrencyConversion.enabled = function()
		return self.pbFileTimestampDiff[self.controls.league.selIndex] == nil or self.pbFileTimestampDiff[self.controls.league.selIndex] >= 3600
	end
	self.controls.updateCurrencyConversion.tooltipFunc = function(tooltip)
		tooltip:Clear()
		if self.lastCurrencyFileTime[self.controls.league.selIndex] ~= nil then
			self.pbFileTimestampDiff[self.controls.league.selIndex] = get_time() - self.lastCurrencyFileTime[self.controls.league.selIndex]
		end
		if self.pbFileTimestampDiff[self.controls.league.selIndex] == nil or self.pbFileTimestampDiff[self.controls.league.selIndex] >= 3600 then
			tooltip:AddLine(16, "Currency Conversion rates are pulled from PoE Ninja")
			tooltip:AddLine(16, "Updates are limited to once per hour and not necessary more than once per day")
		elseif self.pbFileTimestampDiff[self.controls.league.selIndex] ~= nil and self.pbFileTimestampDiff[self.controls.league.selIndex] < 3600 then
			tooltip:AddLine(16, "Conversion Rates are less than an hour old (" .. tostring(self.pbFileTimestampDiff[self.controls.league.selIndex]) .. " seconds old)")
		end
	end
end

-- Method to set the notice message in upper right of PoB Trader pane
function TradeQueryClass:SetNotice(notice_control, msg)
	if msg:find("No Matching Results") then
		msg = colorCodes.WARNING .. msg
	elseif msg:find("Error:") then
		msg = colorCodes.NEGATIVE .. msg
	end
	notice_control.label = msg
end

-- Method to reduce the full output to only the values that were 'weighted'
function TradeQueryClass:ReduceOutput(output)
	local smallOutput = {}
	for _, statTable in ipairs(self.statSortSelectionList) do
		if statTable.stat == "FullDPS" and GlobalCache.numActiveSkillInFullDPS == 0 then
			smallOutput.TotalDPS = output.TotalDPS
			smallOutput.TotalDotDPS = output.TotalDotDPS
			smallOutput.CombinedDPS = output.CombinedDPS
		else
			smallOutput[statTable.stat] = output[statTable.stat]
		end
	end
	return smallOutput
end

-- Method to evaluate a result by getting it's output and weight
function TradeQueryClass:GetResultEvaluation(row_idx, result_index, calcFunc, baseOutput)
	local result = self.resultTbl[row_idx][result_index]
	if not calcFunc then -- Always evaluate when calcFunc is given
		calcFunc, baseOutput = self.itemsTab.build.calcsTab:GetMiscCalculator()
		local onlyWeightedBaseOutput = self:ReduceOutput(baseOutput)
		if not self.onlyWeightedBaseOutput[row_idx] then
			self.onlyWeightedBaseOutput[row_idx] = { }
		end
		if not self.lastComparedWeightList[row_idx] then
			self.lastComparedWeightList[row_idx] = { }
		end
		-- If the interesting stats are the same (the build hasn't changed) and result has already been evaluated, then just return that
		if result.evaluation and tableDeepEquals(onlyWeightedBaseOutput, self.onlyWeightedBaseOutput[row_idx][result_index]) and tableDeepEquals(self.statSortSelectionList, self.lastComparedWeightList[row_idx][result_index]) then
			return result.evaluation
		end
		self.onlyWeightedBaseOutput[row_idx][result_index] = onlyWeightedBaseOutput
		self.lastComparedWeightList[row_idx][result_index] = self.statSortSelectionList
	end
	local slotName = self.slotTables[row_idx].nodeId and "Jewel " .. tostring(self.slotTables[row_idx].nodeId) or self.slotTables[row_idx].slotName
	if slotName == "Megalomaniac" then
		local addedNodes = {}
		for nodeName in (result.item_string.."\r\n"):gmatch("1 Added Passive Skill is (.-)\r?\n") do
			t_insert(addedNodes, self.itemsTab.build.spec.tree.clusterNodeMap[nodeName])
		end
		local output12  = self:ReduceOutput(calcFunc({ addNodes = { [addedNodes[1]] = true, [addedNodes[2]] = true } }, { requirementsItems = true, requirementsGems = true, skills = true }))
		local output13  = self:ReduceOutput(calcFunc({ addNodes = { [addedNodes[1]] = true, [addedNodes[3]] = true } }, { requirementsItems = true, requirementsGems = true, skills = true }))
		local output23  = self:ReduceOutput(calcFunc({ addNodes = { [addedNodes[2]] = true, [addedNodes[3]] = true } }, { requirementsItems = true, requirementsGems = true, skills = true }))
		local output123 = self:ReduceOutput(calcFunc({ addNodes = { [addedNodes[1]] = true, [addedNodes[2]] = true, [addedNodes[3]] = true } }), { requirementsItems = true, requirementsGems = true, skills = true })
		-- Sometimes the third node is as powerful as a wet noodle, so use weight per point spent, including the jewel socket
		local weight12  = self.tradeQueryGenerator.WeightedRatioOutputs(baseOutput, output12,  self.statSortSelectionList) / 4
		local weight13  = self.tradeQueryGenerator.WeightedRatioOutputs(baseOutput, output13,  self.statSortSelectionList) / 4
		local weight23  = self.tradeQueryGenerator.WeightedRatioOutputs(baseOutput, output23,  self.statSortSelectionList) / 4
		local weight123 = self.tradeQueryGenerator.WeightedRatioOutputs(baseOutput, output123, self.statSortSelectionList) / 5
		result.evaluation = {
			{ output = output12,  weight = weight12,  DNs = { addedNodes[1].dn, addedNodes[2].dn } },
			{ output = output13,  weight = weight13,  DNs = { addedNodes[1].dn, addedNodes[3].dn } },
			{ output = output23,  weight = weight23,  DNs = { addedNodes[2].dn, addedNodes[3].dn } },
			{ output = output123, weight = weight123, DNs = { addedNodes[1].dn, addedNodes[2].dn, addedNodes[3].dn } },
		}
		table.sort(result.evaluation, function(a, b) return a.weight > b.weight end)
	else
		local item = new("Item", result.item_string)
		if not self.enchantInSort then -- Calc item DPS without anoint or enchant as these can generally be added after.
			item.enchantModLines = { }
			item:BuildAndParseRaw()
		end
		local output = self:ReduceOutput(calcFunc({ repSlotName = slotName, repItem = item }))
		local weight = self.tradeQueryGenerator.WeightedRatioOutputs(baseOutput, output, self.statSortSelectionList)
		result.evaluation = {{ output = output, weight = weight }}
	end
	return result.evaluation
end

-- Method to update controls after a search is completed
function TradeQueryClass:UpdateControlsWithItems(row_idx)
	local sortMode = self.itemSortSelectionList[self.pbItemSortSelectionIndex]
	local sortedItems, errMsg = self:SortFetchResults(row_idx, sortMode)
	if errMsg == "MissingConversionRates" then
		self:SetNotice(self.controls.pbNotice, "^4Price sorting is not available, falling back to Stat Value sort.")
		sortedItems, errMsg = self:SortFetchResults(row_idx, self.sortModes.StatValue)
	end
	if errMsg then
		self:SetNotice(self.controls.pbNotice, "Error: " .. errMsg)
		return
	else
		self:SetNotice(self.controls.pbNotice, "")
	end

	self.sortedResultTbl[row_idx] = sortedItems
	local pb_index = self.sortedResultTbl[row_idx][1].index
	self.itemIndexTbl[row_idx] = pb_index
	self.controls["priceButton".. row_idx].tooltipText = "Sorted by " .. self.itemSortSelectionList[self.pbItemSortSelectionIndex]
	self.totalPrice[row_idx] = {
		currency = self.resultTbl[row_idx][pb_index].currency,
		amount = self.resultTbl[row_idx][pb_index].amount,
	}
	self.controls.fullPrice.label = "Total Price: " .. self:GetTotalPriceString()
	local dropdownLabels = {}
	for result_index = 1, #self.resultTbl[row_idx] do
		local pb_index = self.sortedResultTbl[row_idx][result_index].index
		local item = new("Item", self.resultTbl[row_idx][pb_index].item_string)
		table.insert(dropdownLabels, colorCodes[item.rarity]..item.name)
	end
	self.controls["resultDropdown".. row_idx].selIndex = 1
	self.controls["resultDropdown".. row_idx]:SetList(dropdownLabels)
end

-- Method to set the current result return in the pane based of an index
function TradeQueryClass:SetFetchResultReturn(row_idx, index)
	if self.resultTbl[row_idx] and self.resultTbl[row_idx][index] then
		self.totalPrice[row_idx] = {
			currency = self.resultTbl[row_idx][index].currency,
			amount = self.resultTbl[row_idx][index].amount,
		}
		self.controls.fullPrice.label = "Total Price: " .. self:GetTotalPriceString()
	end
end

-- Method to sort the fetched results
function TradeQueryClass:SortFetchResults(row_idx, mode)
	local calcFunc, baseOutput
	local function getResultWeight(result_index)
		if not calcFunc then
			calcFunc, baseOutput = self.itemsTab.build.calcsTab:GetMiscCalculator()
		end
		local sum = 0
		for _, eval in ipairs(self:GetResultEvaluation(row_idx, result_index)) do
			sum = sum + eval.weight
		end
		return sum
	end
	local function getPriceTable()
		local out = {}
		local pricedItems = self:addChaosEquivalentPriceToItems(self.resultTbl[row_idx])
		if pricedItems == nil then
			return nil
		end
		for index, tbl in pairs(pricedItems) do
			local chaosAmount = self:ConvertCurrencyToChaos(tbl.currency, tbl.amount)
			if chaosAmount > 0 then
				out[index] = chaosAmount
			end
		end
		return out
	end
	local newTbl = {}
	if mode == self.sortModes.Weight then
		for index, _ in pairs(self.resultTbl[row_idx]) do
			t_insert(newTbl, { outputAttr = index, index = index })
		end
		return newTbl
	elseif mode == self.sortModes.StatValue  then
		for result_index = 1, #self.resultTbl[row_idx] do
			t_insert(newTbl, { outputAttr = getResultWeight(result_index), index = result_index })
		end
		table.sort(newTbl, function(a,b) return a.outputAttr > b.outputAttr end)
	elseif mode == self.sortModes.StatValuePrice then
		local priceTable = getPriceTable()
		if priceTable == nil then
			return nil, "MissingConversionRates"
		end
		for result_index = 1, #self.resultTbl[row_idx] do
			t_insert(newTbl, { outputAttr = getResultWeight(result_index) / priceTable[result_index], index = result_index })
		end
		table.sort(newTbl, function(a,b) return a.outputAttr > b.outputAttr end)
	elseif mode == self.sortModes.Price then
		local priceTable = getPriceTable()
		if priceTable == nil then
			return nil, "MissingConversionRates"
		end
		for result_index, price in pairs(priceTable) do
			t_insert(newTbl, { outputAttr = price, index = result_index })
		end
		table.sort(newTbl, function(a,b) return a.outputAttr < b.outputAttr end)
	else
		return nil, "InvalidSort"
	end
	return newTbl
end

--- Convert item prices to chaos equivalent using poeninja data, returns nil if fails to convert any
function TradeQueryClass:addChaosEquivalentPriceToItems(items)
	local outputItems = copyTable(items)
	for _, item in ipairs(outputItems) do
		local chaosAmount = self:ConvertCurrencyToChaos(item.currency, item.amount)
		if chaosAmount == nil then
			return nil
		end
		item.chaosEquivalent = chaosAmount
	end
	return outputItems
end

-- Method to generate pane elements for each item slot
function TradeQueryClass:PriceItemRowDisplay(row_idx, top_pane_alignment_ref, row_vertical_padding, row_height)
	local controls = self.controls
	local slotTbl = self.slotTables[row_idx]
	local activeSlotRef = slotTbl.nodeId and self.itemsTab.activeItemSet[slotTbl.nodeId] or self.itemsTab.activeItemSet[slotTbl.slotName]
	local activeSlot = slotTbl.nodeId and self.itemsTab.sockets[slotTbl.nodeId] or slotTbl.slotName and self.itemsTab.slots[slotTbl.slotName]
	local nameColor = slotTbl.unique and colorCodes.UNIQUE or "^7"
	controls["name"..row_idx] = new("LabelControl", top_pane_alignment_ref, 0, row_idx*(row_height + row_vertical_padding), 100, row_height - 4, nameColor..slotTbl.slotName)
	controls["bestButton"..row_idx] = new("ButtonControl", { "LEFT", controls["name"..row_idx], "LEFT"}, 100 + 8, 0, 80, row_height, "Find best", function()
		self.tradeQueryGenerator:RequestQuery(activeSlot, { slotTbl = slotTbl, controls = controls, row_idx = row_idx }, self.statSortSelectionList, function(context, query, errMsg)
			if errMsg then
				self:SetNotice(context.controls.pbNotice, colorCodes.NEGATIVE .. errMsg)
				return
			else
				self:SetNotice(context.controls.pbNotice, "")
			end
			if main.POESESSID == nil or main.POESESSID == "" then
				local url = self.tradeQueryRequests:buildUrl(self.hostName .. "trade/search", self.pbRealm, self.pbLeague)
				url = url .. "?q=" .. urlEncode(query)
				controls["uri"..context.row_idx]:SetText(url, true)
				return
			end
			context.controls["priceButton"..context.row_idx].label = "Searching..."
			self.tradeQueryRequests:SearchWithQueryWeightAdjusted(self.pbRealm, self.pbLeague, query, 
				function(items, errMsg)
					if errMsg then
						self:SetNotice(context.controls.pbNotice, colorCodes.NEGATIVE .. errMsg)
						context.controls["priceButton"..context.row_idx].label =  "Price Item"
						return
					else
						self:SetNotice(context.controls.pbNotice, "")
					end
					self.resultTbl[context.row_idx] = items
					self:UpdateControlsWithItems(context.row_idx)
					context.controls["priceButton"..context.row_idx].label =  "Price Item"
				end,
				{
					callbackQueryId = function(queryId)
						local url = self.tradeQueryRequests:buildUrl(self.hostName .. "trade/search", self.pbRealm, self.pbLeague, queryId)
						controls["uri"..context.row_idx]:SetText(url, true)
					end
				}
			)
		end)
	end)
	controls["bestButton"..row_idx].shown = function() return not self.resultTbl[row_idx] end
	controls["bestButton"..row_idx].tooltipText = "Creates a weighted search to find the highest Stat Value items for this slot."
	local pbURL
	controls["uri"..row_idx] = new("EditControl", { "TOPLEFT", controls["bestButton"..row_idx], "TOPRIGHT"}, 8, 0, 514, row_height, nil, nil, "^%C\t\n", nil, function(buf)
		local subpath = buf:match(self.hostName .. "trade/search/(.+)$") or ""
		local paths = {}
		for path in subpath:gmatch("[^/]+") do
			table.insert(paths, path)
		end
		controls["uri"..row_idx].validURL = #paths == 2 or #paths == 3
		if controls["uri"..row_idx].validURL then
			pbURL = buf
		elseif buf == "" then
			pbURL = ""
		end
		if not activeSlotRef and slotTbl.nodeId then
			self.itemsTab.activeItemSet[slotTbl.nodeId] = { pbURL = "" }
			activeSlotRef = self.itemsTab.activeItemSet[slotTbl.nodeId]
		end
	end, nil)
	controls["uri"..row_idx]:SetPlaceholder("Paste trade URL here...")
	if pbURL and pbURL ~= "" then
		controls["uri"..row_idx]:SetText(pbURL, true)
	end
	controls["uri"..row_idx].tooltipFunc = function(tooltip)
		tooltip:Clear()
		if controls["uri"..row_idx].buf:find('^'..self.hostName..'trade/search/') ~= nil then
			tooltip:AddLine(16, "Control + click to open in web-browser")
		end
	end
	controls["priceButton"..row_idx] = new("ButtonControl", { "TOPLEFT", controls["uri"..row_idx], "TOPRIGHT"}, 8, 0, 100, row_height, "Price Item",
		function()
			controls["priceButton"..row_idx].label = "Searching..."
			self.tradeQueryRequests:SearchWithURL(controls["uri"..row_idx].buf, function(items, errMsg)
				if errMsg then
					self:SetNotice(controls.pbNotice, "Error: " .. errMsg)
				else
					self:SetNotice(controls.pbNotice, "")
					self.resultTbl[row_idx] = items
					self:UpdateControlsWithItems(row_idx)
				end
				controls["priceButton"..row_idx].label = "Price Item"
			end)
		end)
	controls["priceButton"..row_idx].enabled = function()
		local poesessidAvailable = main.POESESSID and main.POESESSID ~= ""
		local validURL = controls["uri"..row_idx].validURL
		local isSearching = controls["priceButton"..row_idx].label == "Searching..."
		return poesessidAvailable and validURL and not isSearching
	end
	controls["priceButton"..row_idx].tooltipFunc = function(tooltip)
		tooltip:Clear()
		if not main.POESESSID or main.POESESSID == "" then
			tooltip:AddLine(16, "You must set your POESESSID to use search feature")
		elseif not controls["uri"..row_idx].validURL then
			tooltip:AddLine(16, "Enter a valid trade URL")
		end
	end
	local clampItemIndex = function(index)
		return m_min(m_max(index or 1, 1), self.sortedResultTbl[row_idx] and #self.sortedResultTbl[row_idx] or 1)
	end
	controls["changeButton"..row_idx] = new("ButtonControl", { "LEFT", controls["name"..row_idx], "LEFT"}, 100 + 8, 0, 80, row_height, "<< Search", function()
		self.itemIndexTbl[row_idx] = nil
		self.sortedResultTbl[row_idx] = nil
		self.resultTbl[row_idx] = nil
		self.totalPrice[row_idx] = nil
		self.controls.fullPrice.label = "Total Price: " .. self:GetTotalPriceString()
	end)
	controls["changeButton"..row_idx].shown = function() return self.resultTbl[row_idx] end
	local dropdownLabels = {}
	for _, sortedResult in ipairs(self.sortedResultTbl[row_idx] or {}) do
		local item = new("Item", self.resultTbl[row_idx][sortedResult.index].item_string)
		table.insert(dropdownLabels, colorCodes[item.rarity]..item.name)
	end
	controls["resultDropdown"..row_idx] = new("DropDownControl", { "TOPLEFT", controls["changeButton"..row_idx], "TOPRIGHT"}, 8, 0, 325, row_height, dropdownLabels, function(index)
		self.itemIndexTbl[row_idx] = self.sortedResultTbl[row_idx][index].index
		self:SetFetchResultReturn(row_idx, self.itemIndexTbl[row_idx])
	end)
	local function addMegalomaniacCompareToTooltipIfApplicable(tooltip, result_index)
		if slotTbl.slotName ~= "Megalomaniac" then
			return
		end
		for _, evaluationEntry in ipairs(self:GetResultEvaluation(row_idx, result_index)) do
			tooltip:AddSeparator(10)
			local nodeDNs = evaluationEntry.DNs
			local nodeCombo = nodeDNs[1]
			for i = 2, #nodeDNs do
				nodeCombo = nodeCombo .. " ^8+^7 " .. nodeDNs[i]
			end
			self.itemsTab.build:AddStatComparesToTooltip(tooltip, self.onlyWeightedBaseOutput[row_idx][result_index], evaluationEntry.output, "^8Allocating ^7"..nodeCombo.."^8 will give You:", #nodeDNs + 2)
		end
	end
	controls["resultDropdown"..row_idx].tooltipFunc = function(tooltip, dropdown_mode, dropdown_index, dropdown_display_string)
		local pb_index = self.sortedResultTbl[row_idx][dropdown_index].index
		local result = self.resultTbl[row_idx][pb_index]
		local item = new("Item", result.item_string)
		tooltip:Clear()
		self.itemsTab:AddItemTooltip(tooltip, item, slotTbl)
		addMegalomaniacCompareToTooltipIfApplicable(tooltip, pb_index)
		tooltip:AddSeparator(10)
		tooltip:AddLine(16, string.format("^7Price: %s %s", result.amount, result.currency))
	end
	controls["importButton"..row_idx] = new("ButtonControl", { "TOPLEFT", controls["resultDropdown"..row_idx], "TOPRIGHT"}, 8, 0, 100, row_height, "Import Item", function()
		self.itemsTab:CreateDisplayItemFromRaw(self.resultTbl[row_idx][self.itemIndexTbl[row_idx]].item_string)
		local item = self.itemsTab.displayItem
		-- pass "true" to not auto equip it as we will have our own logic
		self.itemsTab:AddDisplayItem(true)
		-- Autoequip it
		local slot = slotTbl.nodeId and self.itemsTab.sockets[slotTbl.nodeId] or self.itemsTab.slots[slotTbl.slotName]
		if slot and slotTbl.slotName == slot.label and slot:IsShown() and self.itemsTab:IsItemValidForSlot(item, slot.slotName) then
			slot:SetSelItemId(item.id)
			self.itemsTab:PopulateSlots()
			self.itemsTab:AddUndoState()
			self.itemsTab.build.buildFlag = true
		end
	end)
	controls["importButton"..row_idx].tooltipFunc = function(tooltip)
		tooltip:Clear()
		local selected_result_index = self.itemIndexTbl[row_idx]
		local item_string = self.resultTbl[row_idx][selected_result_index].item_string
		if selected_result_index and item_string then
			-- TODO: item parsing bug caught here.
			-- item.baseName is nil and throws error in the following AddItemTooltip func
			-- if the item is unidentified
			local item = new("Item", item_string)
			self.itemsTab:AddItemTooltip(tooltip, item, slotTbl, true)
			addMegalomaniacCompareToTooltipIfApplicable(tooltip, selected_result_index)
		end
	end
	controls["importButton"..row_idx].enabled = function()
		return self.itemIndexTbl[row_idx] and self.resultTbl[row_idx][self.itemIndexTbl[row_idx]].item_string ~= nil
	end
	-- Whisper so we can copy to clipboard
	controls["whisperButton"..row_idx] = new("ButtonControl", { "TOPLEFT", controls["importButton"..row_idx], "TOPRIGHT"}, 8, 0, 185, row_height, function()
		return self.totalPrice[row_idx] and "Whisper for " .. self.totalPrice[row_idx].amount .. " " .. self.totalPrice[row_idx].currency or "Whisper"
	end, function()
		Copy(self.resultTbl[row_idx][self.itemIndexTbl[row_idx]].whisper)
	end)
	controls["whisperButton"..row_idx].enabled = function()
		return self.itemIndexTbl[row_idx] and self.resultTbl[row_idx][self.itemIndexTbl[row_idx]].whisper ~= nil
	end
	controls["whisperButton"..row_idx].tooltipFunc = function(tooltip)
		tooltip:Clear()
		if self.itemIndexTbl[row_idx] and self.resultTbl[row_idx][self.itemIndexTbl[row_idx]].item_string then
			tooltip.center = true
			tooltip:AddLine(16, "Copies the item purchase whisper to the clipboard")
		end
	end
end

-- Method to update the Total Price string sum of all items
function TradeQueryClass:GetTotalPriceString()
	local text = ""
	local sorted_price = { }
	for _, entry in pairs(self.totalPrice) do
		if sorted_price[entry.currency] then
			sorted_price[entry.currency] = sorted_price[entry.currency] + entry.amount
		else
			sorted_price[entry.currency] = entry.amount
		end
	end
	for currency, value in pairs(sorted_price) do
		text = text .. tostring(value) .. " " .. currency .. ", "
	end
	if text ~= "" then
		text = text:sub(1, -3)
	end
	return text
end

-- Method to update realms and leagues
function TradeQueryClass:UpdateRealms()
	local function setRealmDropList()
		self.realmDropList = {}
		for realm, _ in pairs(self.realmIds) do
			-- place PC as the first entry
			if realm == "PC" then
				t_insert(self.realmDropList, 1, realm)
			else
				t_insert(self.realmDropList, realm)
			end
		end
		self.controls.realm:SetList(self.realmDropList)
		-- invalidate selIndex to trigger select function call in the SetSel
		-- DropDownControl doesn't check if the inner list has changed so selecting the first item doesn't count as an update after list refresh
		self.controls.realm.selIndex = nil
		self.controls.realm:SetSel(self.pbRealmIndex)
	end

	if main.POESESSID and main.POESESSID ~= "" then
		-- Fetch from trade page using POESESSID, includes private leagues
		ConPrintf("Fetching realms and leagues using POESESSID")
		self.tradeQueryRequests:FetchRealmsAndLeaguesHTML(function(data, errMsg)
			if errMsg then
				self:SetNotice(self.controls.pbNotice, "Error while fetching league list: "..errMsg)
				return
			end
			local leagues = data.leagues
			self.allLeagues = {}
			for _, value in ipairs(leagues) do
				if not self.allLeagues[value.realm] then self.allLeagues[value.realm] = {} end
				t_insert(self.allLeagues[value.realm], value.id)
			end
			self.realmIds = {}
			for _, value in pairs(data.realms) do
				self.realmIds[value.text] = value.id
			end
			setRealmDropList()

		end)
	else
		-- Fallback to static list
		ConPrintf("Using static realms list")
		self.realmIds = {
			["PC"]   = "pc",
			["PS4"]  = "sony",
			["Xbox"] = "xbox",
		}
		setRealmDropList()
	end
end
