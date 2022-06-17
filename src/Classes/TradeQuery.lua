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

local baseSlots = { "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2", "Belt", "Flask 1", "Flask 2", "Flask 3", "Flask 4", "Flask 5" }


local TradeQueryClass = newClass("TradeQuery", function(self, itemsTab)
	self.itemsTab = itemsTab
	self.itemsTab.leagueDropList = { }
	self.totalPrice = { }
	-- table of price results index by slot and number of fetched results
	self.resultTbl = { }
	self.sortedResultTbl = { }

	-- default set of trade item sort selection
	self.pbSortSelectionIndex = 1
	self.pbCurrencyConversion = { }
	self.currencyConversionTradeMap = { }
	self.lastCurrencyConversionRequest = 0
	self.lastCurrencyFileTime = { }
	self.pbFileTimestampDiff = { }

	pcall(require, 'DebugConfig')
	self.tradeQueryRequests = new("TradeQueryRequests")
	table.insert(main.onFrameFuncs, function()
		self.tradeQueryRequests:ProcessQueue()
	end)

    -- set 
    self.storedGlobalCacheDPSView = GlobalCache.useFullDPS
	GlobalCache.useFullDPS = GlobalCache.numActiveSkillInFullDPS > 0
end)

---Fetch currency shortnames from Poe API (used for PoeNinja price pairing)
---@param callback fun()
function TradeQueryClass:FetchCurrencyConversionTable(callback)
	self.tradeQueryRequests:DownloadPage(
		"https://www.pathofexile.com/api/trade/data/static",
		function(response)
			local obj = dkjson.decode(response)
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
function TradeQueryClass:PullLeagueList(controls)
	self.tradeQueryRequests:DownloadPage(
		"https://api.pathofexile.com/leagues?type=main&compact=1",
		function(response, errMsg)
			if errMsg then
				self:SetNotice(controls.pbNotice, "ERROR: " .. tostring(errMsg))
				return "POE ERROR", "Error: "..errMsg
			else
				local json_data = dkjson.decode(response)
				if not json_data then
					self:SetNotice(controls.pbNotice, "Failed to Get PoE League List response")
					return
				end
				self.itemsTab.leagueDropList = {
					{ label = "Standard", name = "Standard", realname = "Standard" },
					{ label = "Hardcore", name = "Hardcore", realname = "Hardcore" },
				}
				for _, league_data in pairs(json_data) do
					local league_name = league_data.id
					if league_name ~= "Standard" and league_name ~= "Hardcore" and not league_name:find("SSF") then
						if league_name:find("Hardcore") then
							t_insert(self.itemsTab.leagueDropList, 2, { label = "HC League" , name = "tmphardcore", realname = league_name})
						else
							t_insert(self.itemsTab.leagueDropList, 1, { label = "SC League" , name = "tmpstandard", realname = league_name})
						end
					end
				end
				controls.league:SetList(self.itemsTab.leagueDropList)
				controls.league.selIndex = 1
				self.pbLeague = self.itemsTab.leagueDropList[controls.league.selIndex].name
				self.pbLeagueRealName = self.itemsTab.leagueDropList[controls.league.selIndex].realname
				self:SetCurrencyConversionButton(controls)
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
		ConPrintf("Unhandled Currency Converstion: '" .. currency:lower() .. "'")
		return m_ceil(amount)
	end
end

-- Method to pull down and interpret the PoE.Ninja JSON endpoint data
function TradeQueryClass:PullPoENinjaCurrencyConversion(league, controls)
	local now = os.time()
	-- Limit PoE Ninja Currency Conversion request to 1 per hour
	if (now - self.lastCurrencyConversionRequest) < 3600 then
		self:SetNotice(controls.pbNotice, "PoE Ninja Rate Limit Exceeded: " .. tostring(3600 - (now - self.lastCurrencyConversionRequest)))
		return
	end
	-- We are getting currency shortnames from Poe API before getting PoeNinja rates
	-- Potentially, currency shortnames could be cached but this request runs 
	-- once per hour at most and the Poe API response is already Cloudflare cached
	self:FetchCurrencyConversionTable(function()
		self.pbCurrencyConversion[league] = { }
		self.lastCurrencyConversionRequest = now
		self.tradeQueryRequests:DownloadPage(
			"https://poe.ninja/api/data/CurrencyRates?league=" .. league,	
			function(response, errMsg)
				if errMsg then
					self:SetNotice(controls.pbNotice, "ERROR: " .. tostring(errMsg))
					return
				end
				local json_data = dkjson.decode(response)
				if not json_data then
					self:SetNotice(controls.pbNotice, "Failed to Get PoE Ninja response")
					return
				end
				self:PriceBuilderProcessPoENinjaResponse(json_data, controls)
				local print_str = ""
				for key, value in pairs(self.pbCurrencyConversion[self.pbLeague]) do
					print_str = print_str .. '"'..key..'": '..tostring(value)..','
				end
				local foo = io.open("../"..self.pbLeague.."_currency_values.json", "w")
				foo:write("{" .. print_str .. '"updateTime": ' .. tostring(get_time()) .. "}")
				foo:close()
				self:SetCurrencyConversionButton(controls)
			end)
	end)
end

-- Method to process the PoE.Ninja response
function TradeQueryClass:PriceBuilderProcessPoENinjaResponse(resp, controls)
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
		self:SetNotice(controls.pbNotice, "PoE Ninja JSON Processing Error")
	end
end

-- Opens the item pricing popup
function TradeQueryClass:PriceItem()
	self.tradeQueryGenerator = new("TradeQueryGenerator", self)

	-- Count number of rows to render
	local row_count = 3 + #baseSlots
	-- Count sockets
	for _, slot in pairs(self.itemsTab.sockets) do
		if not slot.inactive then
			row_count = row_count + 1
		end
	end

	-- Set main Price Builder pane height and width
	local row_height = 20
	local top_pane_alignment_ref = nil
	local top_pane_alignment_width = 0
	local top_pane_alignment_height = row_height + 8
	local pane_height = (top_pane_alignment_height) * row_count + 15
	local pane_width = 1264
	local controls = { }
	local cnt = 1
	controls.itemSetLabel = new("LabelControl",  {"TOPLEFT",nil,"TOPLEFT"}, 16, 15, 60, 18, colorCodes.CUSTOM .. "ItemSet: " .. (self.itemsTab.activeItemSet.title or "Default"))
	controls.pbNotice = new("EditControl",  {"TOP",nil,"TOP"}, 0, 15, 300, 16, "", nil, nil)
	controls.pbNotice.textCol = colorCodes.CUSTOM
	local sortSelectionList = {
		"Default",
		"Cheapest",
		"Highest DPS",
		"DPS / Price",
	}
	controls.itemSortSelection = new("DropDownControl", {"TOPRIGHT",nil,"TOPRIGHT"}, -12, 15, 100, 20, sortSelectionList, function(index, value)
		self.pbSortSelectionIndex = index
	end)
	controls.itemSortSelection.tooltipFunc = function(tooltip)
		tooltip:Clear()
		tooltip:AddLine(16, "Weighted Sum searches ('?' button) will always sort")
		tooltip:AddLine(16, "using descending weighted sum.")
	end
	controls.itemSortSelectionLabel = new("LabelControl",  {"TOPRIGHT",controls.itemSortSelection,"TOPRIGHT"}, -106, 0, 60, 18,  "^8Item Sort Selection:")
	controls.fullPrice = new("EditControl", nil, -3, pane_height - 58, pane_width - 256, row_height, "", "Total Cost", "%Z")
	top_pane_alignment_ref = {"TOPLEFT",controls.itemSetLabel,"TOPLEFT"}
	for _, slotName in ipairs(baseSlots) do
		local str_cnt = tostring(cnt)
		self:PriceItemRowDisplay(controls, str_cnt, {name = slotName}, top_pane_alignment_ref, top_pane_alignment_width, top_pane_alignment_height, row_height)
		top_pane_alignment_ref = {"TOPLEFT",controls['name'..str_cnt],"TOPLEFT"}
		top_pane_alignment_width = 0
		top_pane_alignment_height = 28
		cnt = cnt + 1
	end
	local activeSocketList = { }
	for nodeId, slot in pairs(self.itemsTab.sockets) do
		if not slot.inactive then
			t_insert(activeSocketList, nodeId)
		end
	end
	table.sort(activeSocketList)
	for _, nodeId in pairs(activeSocketList) do
		local str_cnt = tostring(cnt)
		self:PriceItemRowDisplay(controls, str_cnt, {name = self.itemsTab.sockets[nodeId].label, ref = nodeId}, top_pane_alignment_ref, top_pane_alignment_width, top_pane_alignment_height, row_height)
		top_pane_alignment_ref = {"TOPLEFT",controls['name'..str_cnt],"TOPLEFT"}
		top_pane_alignment_width = 0
		top_pane_alignment_height = 28
		cnt = cnt + 1
	end
	controls.close = new("ButtonControl", nil, 0, pane_height - 30, 90, row_height, "Done", function()
		GlobalCache.useFullDPS = self.storedGlobalCacheDPSView
		main:ClosePopup()
	end)
	controls.league = new("DropDownControl", {"TOPRIGHT",nil,"TOPRIGHT"}, -12, pane_height - 30, 100, 18, self.itemsTab.leagueDropList, function(index, value)
		self.pbLeague = value.name
		self.pbLeagueRealName = value.realname or value.name
		self:SetCurrencyConversionButton(controls)
	end)
	controls.league.enabled = function()
		return #self.itemsTab.leagueDropList > 1
	end
	controls.leagueLabel = new("LabelControl", {"TOPRIGHT",controls.league,"TOPLEFT"}, -4, 0, 20, 16, "League:")
	controls.poesessidButton = new("ButtonControl", {"TOPLEFT",controls.leagueLabel,"TOPLEFT"}, -256, 0, 240, row_height, POESESSID ~= "" and "HAVE POESESSID" or colorCodes.WARNING.."NEED POESESSID", function()
		local poesessid_controls = {}
		poesessid_controls.sessionInput = new("EditControl", nil, 0, 18, 350, 18, #POESESSID == 32 and POESESSID or "<PASTE POESESSID FROM BROWSER>", "POESESSID", "%X", 32, function(buf)
			if #poesessid_controls.sessionInput.buf == 32 then
				POESESSID = poesessid_controls.sessionInput.buf
				controls.poesessidButton.label = "HAVE POESESSID"
			end
		end)
		poesessid_controls.sessionInput.tooltipFunc = function(tooltip)
			tooltip:Clear()
			tooltip:AddLine(16, "^7To find your POESESSID value (a 32-bit hexadecimal string) do the following in Google Chrome:")
			tooltip:AddLine(16, "^7  1) Make sure you are logged into your PoE acccount on any valid and official PoE website.")
			tooltip:AddLine(16, "^7  2) Use the shortcut: CTRL+SHIFT+I to bring up 'Developer Tools'")
			tooltip:AddLine(16, "^7  3) Select 'Application' Pane on top and 'Cookies' on the left hand menu sidebar.")
			tooltip:AddLine(16, "^7  4) Under 'Cookies' click on 'https://www.pathofexile.com' which will populate the right hand side.")
			tooltip:AddLine(16, "^7  5) Find the entry named 'POESESSID' and copy the Value into this text box.")
		end
		poesessid_controls.close = new("ButtonControl", {"TOP",poesessid_controls.sessionInput,"TOP"}, 0, 24, 90, row_height, "Done", function()
			main:ClosePopup()
		end)
		main:OpenPopup(364, 72, "POESESSID", poesessid_controls)
	end)
	controls.poesessidButton.tooltipFunc = function(tooltip)
		tooltip:Clear()
		tooltip:AddLine(16, colorCodes.WARNING .. "Your POESESSID is needed for certain more complex queries and all weighted sum queries.")
		tooltip:AddLine(16, colorCodes.WARNING .. "If all the URLs for items are simple queries you don't need to provide this information.")
	end

	controls.updateCurrencyConversion = new("ButtonControl", {"TOPLEFT",nil,"TOPLEFT"}, 16, pane_height - 30, 240, row_height, "", function()
		self:PullPoENinjaCurrencyConversion(self.pbLeague, controls)
	end)
	main:OpenPopup(pane_width, pane_height, "Build Pricer", controls)

	if #self.itemsTab.leagueDropList == 0 then
		self:PullLeagueList(controls)
	else
		controls.league.selIndex = 1
		self.pbLeague = self.itemsTab.leagueDropList[controls.league.selIndex].name
		self.pbLeagueRealName = self.itemsTab.leagueDropList[controls.league.selIndex].realname
		self:SetCurrencyConversionButton(controls)
	end
end

-- Method to update the Currency Conversion button label
function TradeQueryClass:SetCurrencyConversionButton(controls)
	local currencyLabel = colorCodes.WARNING .. "Update Currency Conversion Rates"
	self.pbFileTimestampDiff[controls.league.selIndex] = nil
	local foo = io.open("../"..self.pbLeague.."_currency_values.json", "r")
	if foo then
		local lines = foo:read "*a"
		foo:close()
		self.pbCurrencyConversion[self.pbLeague] = dkjson.decode(lines)
		self.lastCurrencyFileTime[controls.league.selIndex]  = self.pbCurrencyConversion[self.pbLeague]["updateTime"]
		self.pbFileTimestampDiff[controls.league.selIndex] = get_time() - self.lastCurrencyFileTime[controls.league.selIndex] 
		if self.pbFileTimestampDiff[controls.league.selIndex] < 3600 then
			-- Less than 1 hour (60 * 60 = 3600)
			currencyLabel = "^8Currency Rates are Very Recent"
		elseif self.pbFileTimestampDiff[controls.league.selIndex] < (24 * 3600) then
			-- Less than 1 day
			currencyLabel = "^7Currency Rates are Recent"
		end
	else
		currencyLabel = colorCodes.NEGATIVE .. "Get Currency Conversion Rates"
	end
	controls.updateCurrencyConversion.label = currencyLabel
	controls.updateCurrencyConversion.enabled = function()
		return self.pbFileTimestampDiff[controls.league.selIndex] == nil or self.pbFileTimestampDiff[controls.league.selIndex] >= 3600
	end
	controls.updateCurrencyConversion.tooltipFunc = function(tooltip)
		tooltip:Clear()
		if self.lastCurrencyFileTime[controls.league.selIndex] ~= nil then
			self.pbFileTimestampDiff[controls.league.selIndex] = get_time() - self.lastCurrencyFileTime[controls.league.selIndex] 
		end
		if self.pbFileTimestampDiff[controls.league.selIndex] == nil or self.pbFileTimestampDiff[controls.league.selIndex] >= 3600 then
			tooltip:AddLine(16, colorCodes.WARNING .. "Currency Conversion rates are pulled from PoE Ninja leveraging their API.")
			tooltip:AddLine(16, colorCodes.WARNING .. "Updates are limited to once per hour and not necessary more than once per day.")
			tooltip:AddLine(16, "")
			tooltip:AddLine(16, colorCodes.NEGATIVE .. "NOTE: This will expose your IP address to poe.ninja.")
			tooltip:AddLine(16, colorCodes.NEGATIVE .. "If you are concerned about this please do not click this button.")
		elseif self.pbFileTimestampDiff[controls.league.selIndex] ~= nil and self.pbFileTimestampDiff[controls.league.selIndex] < 3600 then
			tooltip:AddLine(16, "Conversion Rates are less than an hour old (" .. tostring(self.pbFileTimestampDiff[controls.league.selIndex]) .. " seconds old)")
			tooltip:AddLine(16, "Button is DISABLED")
		end
	end
end

-- Method to set the notice message in upper right of PoB Trader pane
function TradeQueryClass:SetNotice(notice_control, msg)
	if msg:find("Complex Query") then
		msg =  colorCodes.RELIC .. msg
	elseif msg:find("No Matching Results") then
		msg = colorCodes.WARNING .. msg
	elseif msg:find("Error:") then
		msg = colorCodes.NEGATIVE .. msg
	end
	notice_control:SetText(msg)
end

-- Method to update controls after a search is completed
function TradeQueryClass:UpdateControlsWithItems(slotTbl, controls, index)
	self.sortedResultTbl[index] = self:SortFetchResults(slotTbl, index)
	local str_quantity_found = tostring(#self.sortedResultTbl[index])
	controls['resultCount'..index]:SetText("out of " .. str_quantity_found)
	controls['resultIndex'..index]:SetText("1")
	controls['priceButton'..index].label = "Price Item"
	local pb_index = self.sortedResultTbl[index][1].index
	controls['importButtonText'..index]:SetText(self.resultTbl[index][pb_index].item_string)
	self.totalPrice[index] = {
		currency = self.resultTbl[index][pb_index].currency,
		amount = self.resultTbl[index][pb_index].amount,
	}
	controls['priceAmount'..index]:SetText(self.totalPrice[index].amount .. " " .. self.totalPrice[index].currency)
	controls['whisperButtonText'..index]:SetText(self.resultTbl[index][pb_index].whisper)
	self:GenerateTotalPriceString(controls.fullPrice)
end

-- Method to set the current result return in the pane based of an index
function TradeQueryClass:SetFetchResultReturn(controls, slotIndex, pb_index)
	if self.resultTbl[slotIndex] and self.resultTbl[slotIndex][pb_index] then
		local pb_index = self.sortedResultTbl[slotIndex][pb_index].index
		controls['importButtonText'..slotIndex]:SetText(self.resultTbl[slotIndex][pb_index].item_string)
		self.totalPrice[slotIndex] = {
			currency = self.resultTbl[slotIndex][pb_index].currency,
			amount = self.resultTbl[slotIndex][pb_index].amount,
		}
		controls['priceAmount'..slotIndex]:SetText(self.totalPrice[slotIndex].amount .. " " .. self.totalPrice[slotIndex].currency)
		controls['whisperButtonText'..slotIndex]:SetText(self.resultTbl[slotIndex][pb_index].whisper)
		self:GenerateTotalPriceString(controls.fullPrice)
	end
end

-- Method to sort the fetched resutls
function TradeQueryClass:SortFetchResults(slotTbl, trade_index)
	local newTbl = {}
	if self.pbSortSelectionIndex == 1 then
		for index, tbl in pairs(self.resultTbl[trade_index]) do
			t_insert(newTbl, { outputAttr = index, index = index })
		end
		return newTbl
	end
	if self.pbSortSelectionIndex > 2 then
		local slot = slotTbl.ref and self.itemsTab.sockets[slotTbl.ref] or self.itemsTab.slots[slotTbl.name]
		local slotName = slotTbl.ref and "Jewel " .. tostring(slotTbl.ref) or slotTbl.name
		local calcFunc, calcBase = self.itemsTab.build.calcsTab:GetMiscCalculator()
		for index, tbl in pairs(self.resultTbl[trade_index]) do
			local item = new("Item", tbl.item_string)
			local output = calcFunc({ repSlotName = slotName, repItem = item }, {})
			local newDPS = GlobalCache.useFullDPS and output.FullDPS or output.TotalDPS
			if self.pbSortSelectionIndex == 4 then
				local chaosAmount = self:ConvertCurrencyToChaos(tbl.currency, tbl.amount)
				if chaosAmount > 0 then
					t_insert(newTbl, { outputAttr = newDPS / chaosAmount, index = index })
				end
			else
				if tbl.amount > 0 then
					t_insert(newTbl, { outputAttr = newDPS, index = index })
				end
			end
		end
		table.sort(newTbl, function(a,b) return a.outputAttr > b.outputAttr end)
	else
		for index, tbl in pairs(self.resultTbl[trade_index]) do
			local chaosAmount = self:ConvertCurrencyToChaos(tbl.currency, tbl.amount)
			if chaosAmount > 0 then
				t_insert(newTbl, { outputAttr = chaosAmount, index = index })
			end
		end
		table.sort(newTbl, function(a,b) return a.outputAttr < b.outputAttr end)
	end
	return newTbl
end


-- Method to generate pane elements for each item slot
function TradeQueryClass:PriceItemRowDisplay(controls, str_cnt, slotTbl, top_pane_alignment_ref, top_pane_alignment_width, top_pane_alignment_height, row_height)
	local activeSlotRef = slotTbl.ref and self.itemsTab.activeItemSet[slotTbl.ref] or self.itemsTab.activeItemSet[slotTbl.name]
	controls['name'..str_cnt] = new("LabelControl", top_pane_alignment_ref, top_pane_alignment_width, top_pane_alignment_height, 100, row_height-4, "^8"..slotTbl.name)
	controls['bestButton'..str_cnt] = new("ButtonControl", {"TOPLEFT",controls['name'..str_cnt],"TOPLEFT"}, 100 + 8, 0, 10, row_height, "?", function()
		self.tradeQueryGenerator:RequestQuery(slotTbl.ref and self.itemsTab.sockets[slotTbl.ref] or self.itemsTab.slots[slotTbl.name], { slotTbl = slotTbl, controls = controls, str_cnt = str_cnt }, function(context, query)
			self.pbSortSelectionIndex = 1
			context.controls['priceButton'..context.str_cnt].label = "Searching..."
			self.tradeQueryRequests:SearchWithQuery(self.pbLeagueRealName, query, 
				function(items, errMsg)
					if errMsg then
						self:SetNotice(context.controls.pbNotice, "Error: " .. errMsg)
						return
					else
						self:SetNotice(context.controls.pbNotice, "")
					end
					self.resultTbl[context.str_cnt] = items
					self:UpdateControlsWithItems(context.slotTbl, context.controls, context.str_cnt)
					context.controls['priceButton'..context.str_cnt].label =  "Price Item"
				end,
				{
					callbackQueryId = function(queryId)
						controls['uri'..context.str_cnt]:SetText("https://www.pathofexile.com/trade/search/".. self.pbLeagueRealName .."/".. queryId)	
					end
				}
			)
		end)
	end)
	controls['uri'..str_cnt] = new("EditControl", {"TOPLEFT",controls['bestButton'..str_cnt],"TOPLEFT"}, 10 + 8, 0, 500, row_height, "Trade Site URL", nil, "^%C\t\n", nil, nil, nil)
	if activeSlotRef and activeSlotRef.pbURL ~= "" and activeSlotRef.pbURL ~= nil then
		controls['uri'..str_cnt]:SetText(activeSlotRef.pbURL)
	else
		controls['uri'..str_cnt]:SetText("<PASTE TRADE URL FOR>: " .. slotTbl.name)
	end
	controls['uri'..str_cnt].tooltipFunc = function(tooltip)
		tooltip:Clear()
		if controls['uri'..str_cnt].buf:find('^https://www.pathofexile.com/trade/search/') ~= nil then
			tooltip:AddLine(16, "CTRL click to open in web-browser or click 'Price Item' to do it in PoB")
			tooltip:AddLine(16, "")
			tooltip:AddLine(14, colorCodes.NEGATIVE .. "NOTE: you will need to re-sort until GGG fixes")
		end
	end
	controls['priceButton'..str_cnt] = new("ButtonControl", {"TOPLEFT",controls['uri'..str_cnt],"TOPLEFT"}, 500 + 8, 0, 100, row_height, "Price Item", 
		function()
		controls['priceButton'..str_cnt].label = "Searching..."
		self.tradeQueryRequests:SearchWithURL(controls['uri'..str_cnt].buf, function(items, errMsg)
			if errMsg then
				self:SetNotice(controls.pbNotice, "Error: " .. errMsg)
			else
				self.resultTbl[str_cnt] = items
				self:UpdateControlsWithItems(slotTbl, controls, str_cnt)
			end
			controls['priceButton'..str_cnt].label = "Price Item"
		end)
		end)
	controls['priceButton'..str_cnt].enabled = function()
		local validURL = controls['uri'..str_cnt].buf:find('^https://www.pathofexile.com/trade/search/') ~= nil
		if not activeSlotRef and slotTbl.ref then
			self.itemsTab.activeItemSet[slotTbl.ref] = { pbURL = "" }
			activeSlotRef = self.itemsTab.activeItemSet[slotTbl.ref]
		end
		if validURL then
			activeSlotRef.pbURL = controls['uri'..str_cnt].buf
		elseif controls['uri'..str_cnt].buf == "" then
			activeSlotRef.pbURL = ""
		end
		local isSearching = controls['priceButton'..str_cnt].label == "Searching..."
		return validURL and not isSearching
	end
	controls['resultIndex'..str_cnt] = new("EditControl", {"TOPLEFT",controls['priceButton'..str_cnt],"TOPLEFT"}, 100 + 8, 0, 60, row_height, "#", nil, "%D", 3, function(buf)
		controls['resultIndex'..str_cnt].buf = tostring(m_min(m_max(tonumber(buf) or 1, 1), self.sortedResultTbl[str_cnt] and #self.sortedResultTbl[str_cnt] or 1))
	end)
	controls['resultIndex'..str_cnt].tooltipFunc = function(tooltip)
		if tooltip:CheckForUpdate(controls['resultIndex'..str_cnt].buf) then
			self:SetFetchResultReturn(controls, str_cnt, tonumber(controls['resultIndex'..str_cnt].buf))
		end
	end
	controls['resultCount'..str_cnt] = new("EditControl", {"TOPLEFT",controls['resultIndex'..str_cnt],"TOPLEFT"}, 60 + 8, 0, 82, row_height, "^8No Results", nil, nil)
	controls['priceAmount'..str_cnt] = new("EditControl", {"TOPLEFT",controls['resultCount'..str_cnt],"TOPLEFT"}, 82 + 8, 0, 120, row_height, "Price", nil, nil)
	controls['priceAmount'..str_cnt].enabled = function()
		local boolean = #controls['priceAmount'..str_cnt].buf > 0
		return boolean
	end
	controls['importButton'..str_cnt] = new("ButtonControl", {"TOPLEFT",controls['priceAmount'..str_cnt],"TOPLEFT"}, 120 + 8, 0, 100, row_height, "Import Item", function()
		self.itemsTab:CreateDisplayItemFromRaw(controls['importButtonText'..str_cnt].buf)
		local item = self.itemsTab.displayItem
		-- pass "true" to not auto equip it as we will have our own logic
		self.itemsTab:AddDisplayItem(true)
		-- Autoequip it
		local slot = slotTbl.ref and self.itemsTab.sockets[slotTbl.ref] or self.itemsTab.slots[slotTbl.name]
		if slot and slotTbl.name == slot.label and slot:IsShown() and self.itemsTab:IsItemValidForSlot(item, slot.slotName) then
			slot:SetSelItemId(item.id)
			self.itemsTab:PopulateSlots()
			self.itemsTab:AddUndoState()
			self.itemsTab.build.buildFlag = true
		end
	end)
	controls['importButton'..str_cnt].tooltipFunc = function(tooltip)
		tooltip:Clear()
		if #controls['importButtonText'..str_cnt].buf > 0 then
			-- Fix: item parsing bug caught here.
			-- item.baseName is nil and throws error in the following AddItemTooltip func
			-- if the item is unidentified
			local item = new("Item", controls['importButtonText'..str_cnt].buf)
			self.itemsTab:AddItemTooltip(tooltip, item, nil, true)
		end
	end
	controls['importButton'..str_cnt].enabled = function()
		return #controls['importButtonText'..str_cnt].buf > 0
	end
	-- for storing the base64 item description
	controls['importButtonText'..str_cnt] = new("EditControl", nil, 0, 0, 0, 0, "", nil, "", nil, nil, 16)
	controls['importButtonText'..str_cnt].shown = false
	-- for storing the whisper to purchase item from seller
	controls['whisperButtonText'..str_cnt] = new("EditControl", nil, 0, 0, 0, 0, "", nil, "", nil, nil, 16)
	controls['whisperButtonText'..str_cnt].shown = false
	-- Whisper so we can copy to clipboard
	controls['whisperButton'..str_cnt] = new("ButtonControl", {"TOPLEFT",controls['importButton'..str_cnt],"TOPLEFT"}, 100 + 8, 0, 100, row_height, "Whisper", function()
		Copy(controls['whisperButtonText'..str_cnt].buf)
	end)
	controls['whisperButton'..str_cnt].enabled = function()
		return #controls['whisperButtonText'..str_cnt].buf > 0
	end
	controls['whisperButton'..str_cnt].tooltipFunc = function(tooltip)
		tooltip:Clear()
		if #controls['importButtonText'..str_cnt].buf > 0 then
			tooltip.center = true
			tooltip:AddLine(16, "Copies the item purchase whisper to the clipboard")
		end
	end
end

-- Method to update the Total Price string sum of all items
function TradeQueryClass:GenerateTotalPriceString(editPane)
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
	editPane:SetText(text)
end
