-- Path of Building
--
-- Module: Items Tab
-- Items tab for the current build.
--
local pairs = pairs
local ipairs = ipairs
local next = next
local t_insert = table.insert
local t_remove = table.remove
local s_format = string.format
local m_max = math.max
local m_min = math.min
local m_ceil = math.ceil
local m_floor = math.floor
local m_modf = math.modf
local get_time = os.time

local dkjson = require "dkjson"

local rarityDropList = { 
	{ label = colorCodes.NORMAL.."Normal", rarity = "NORMAL" },
	{ label = colorCodes.MAGIC.."Magic", rarity = "MAGIC" },
	{ label = colorCodes.RARE.."Rare", rarity = "RARE" },
	{ label = colorCodes.UNIQUE.."Unique", rarity = "UNIQUE" },
	{ label = colorCodes.RELIC.."Relic", rarity = "RELIC" }
}

local socketDropList = {
	{ label = colorCodes.STRENGTH.."R", color = "R" },
	{ label = colorCodes.DEXTERITY.."G", color = "G" },
	{ label = colorCodes.INTELLIGENCE.."B", color = "B" },
	{ label = colorCodes.SCION.."W", color = "W" }
}

local baseSlots = { "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2", "Belt", "Flask 1", "Flask 2", "Flask 3", "Flask 4", "Flask 5" }

local leagueDropList = {
	{ label = "League SC", name = "tmpstandard" },
	{ label = "League HC", name = "tmphardcore" },
	{ label = "Standard", name = "Standard" },
	{ label = "Hardcore", name = "Hardcore" },
	{ label = "Event SC", name = "eventstandard" },
	{ label = "Event HC", name = "eventhardcore" }
}

local currencyConversionTradeMap = { }
currencyConversionTradeMap["Orb of Alteration"] = "alt"
currencyConversionTradeMap["Orb of Fusing"] = "fusing"
currencyConversionTradeMap["Orb of Alchemy"] = "alch"
currencyConversionTradeMap["Chaos Orb"] = "chaos"
currencyConversionTradeMap["Gemcutter's Prism"] = "gcp"
currencyConversionTradeMap["Exalted Orb"] = "exalted"
currencyConversionTradeMap["Chromatic Orb"] = "chrome"
currencyConversionTradeMap["Jeweller's Orb"] = "jewellers"
currencyConversionTradeMap["Engineer's Orb"] = "engineers"
currencyConversionTradeMap["Infused Engineer's Orb"] = "infused-engineers-orb"
currencyConversionTradeMap["Orb of Chance"] = "chance"
currencyConversionTradeMap["Cartographer's Chisel"] = "chisel"
currencyConversionTradeMap["Orb of Scouring"] = "scour"
currencyConversionTradeMap["Blessed Orb"] = "blessed"
currencyConversionTradeMap["Orb of Regret"] = "regret"
currencyConversionTradeMap["Regal Orb"] = "regal"
currencyConversionTradeMap["Divine Orb"] = "divine"
currencyConversionTradeMap["Vaal Orb"] = "vaal"
currencyConversionTradeMap["Orb of Annulment"] = "annul"
currencyConversionTradeMap["Orb of Binding"] = "orb-of-binding"
currencyConversionTradeMap["Ancient Orb"] = "ancient-orb"
currencyConversionTradeMap["Orb of Horizons"] = "orb-of-horizons"
currencyConversionTradeMap["Harbinger's Orb"] = "harbingers-orb"
currencyConversionTradeMap["Scroll of Wisdom"] = "wisdom"
currencyConversionTradeMap["Portal Scroll"] = "portal"
currencyConversionTradeMap["Armourer's Scrap"] = "scrap"
currencyConversionTradeMap["Blacksmith's Whetstone"] = "whetstone"
currencyConversionTradeMap["Glassblower's Bauble"] = "bauble"
currencyConversionTradeMap["Orb of Transmutation"] = "transmute"
currencyConversionTradeMap["Orb of Augmentation"] = "aug"
currencyConversionTradeMap["Mirror of Kalandra"] = "mirror"
currencyConversionTradeMap["Eternal Orb"] = "eternal"
currencyConversionTradeMap["Rogue's Marker"] = "rogues-marker"
currencyConversionTradeMap["Silver Coin"] = "silver"
currencyConversionTradeMap["Crusader's Exalted Orb"] = "crusaders-exalted-orb"
currencyConversionTradeMap["Redeemer's Exalted Orb"] = "redeemers-exalted-orb"
currencyConversionTradeMap["Hunter's Exalted Orb"] = "hunters-exalted-orb"
currencyConversionTradeMap["Warlord's Exalted Orb"] = "warlords-exalted-orb"
currencyConversionTradeMap["Awakener's Orb"] = "awakeners-orb"
currencyConversionTradeMap["Maven's Orb"] = "mavens-orb"
currencyConversionTradeMap["Facetor's Lens"] = "facetors"
currencyConversionTradeMap["Prime Regrading Lens"] = "prime-regrading-lens"
currencyConversionTradeMap["Secondary Regrading Lens"] = "secondary-regrading-lens"
currencyConversionTradeMap["Tempering Orb"] = "tempering-orb"
currencyConversionTradeMap["Tailoring Orb"] = "tailoring-orb"
currencyConversionTradeMap["Stacked Deck"] = "stacked-deck"
currencyConversionTradeMap["Simple Sextant"] = "simple-sextant"
currencyConversionTradeMap["Prime Sextant"] = "prime-sextant"
currencyConversionTradeMap["Awakened Sextant"] = "awakened-sextant"
currencyConversionTradeMap["Elevated Sextant"] = "elevated-sextant"
currencyConversionTradeMap["Orb of Unmaking"] = "orb-of-unmaking"
currencyConversionTradeMap["Blessing of Xoph"] = "blessing-xoph"
currencyConversionTradeMap["Blessing of Tul"] = "blessing-tul"
currencyConversionTradeMap["Blessing of Esh"] = "blessing-esh"
currencyConversionTradeMap["Blessing of Uul-Netol"] = "blessing-uul-netol"
currencyConversionTradeMap["Blessing of Chayula"] = "blessing-chayula"
currencyConversionTradeMap["Veiled Chaos Orb"] = "veiled-chaos-orb"
currencyConversionTradeMap["Enkindling Orb"] = "enkindling-orb"
currencyConversionTradeMap["Instilling Orb"] = "instilling-orb"
currencyConversionTradeMap["Sacred Orb"] = "sacred-orb"

local influenceInfo = itemLib.influenceInfo

local catalystQualityFormat = {
	"^x7F7F7FQuality (Attack Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Speed Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Life and Mana Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Caster Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Attribute Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Physical and Chaos Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Resistance Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Defense Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Elemental Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Critical Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
}

local ItemsTabClass = newClass("ItemsTab", "UndoHandler", "ControlHost", "Control", function(self, build)
	self.UndoHandler()
	self.ControlHost()
	self.Control()

	self.build = build
	
	self.socketViewer = new("PassiveTreeView")

	self.items = { }
	self.itemOrderList = { }

	-- Store POESESSID (when provided)
	self.poe_sessid = ""

	-- Set selector
	self.controls.setSelect = new("DropDownControl", {"TOPLEFT",self,"TOPLEFT"}, 96, 8, 200, 20, nil, function(index, value)
		self:SetActiveItemSet(self.itemSetOrderList[index])
		self:AddUndoState()
	end)
	self.controls.setSelect.enableDroppedWidth = true
	self.controls.setSelect.enabled = function()
		return #self.itemSetOrderList > 1
	end
	self.controls.setSelect.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if mode == "HOVER" then
			self:AddItemSetTooltip(tooltip, self.itemSets[self.itemSetOrderList[index]])
		end
	end
	self.controls.setLabel = new("LabelControl", {"RIGHT",self.controls.setSelect,"LEFT"}, -2, 0, 0, 16, "^7Item set:")
	self.controls.setManage = new("ButtonControl", {"LEFT",self.controls.setSelect,"RIGHT"}, 4, 0, 90, 20, "Manage...", function()
		self:OpenItemSetManagePopup()
	end)

	-- Item slots
	self.slots = { }
	self.orderedSlots = { }
	self.slotOrder = { }
	self.slotAnchor = new("Control", {"TOPLEFT",self,"TOPLEFT"}, 96, 54, 310, 0)
	local prevSlot = self.slotAnchor
	local function addSlot(slot)
		prevSlot = slot
		self.slots[slot.slotName] = slot
		t_insert(self.orderedSlots, slot)
		self.slotOrder[slot.slotName] = #self.orderedSlots
		t_insert(self.controls, slot)
	end
	for index, slotName in ipairs(baseSlots) do
		local slot = new("ItemSlotControl", {"TOPLEFT",prevSlot,"BOTTOMLEFT"}, 0, 0, self, slotName)
		addSlot(slot)
		if slotName:match("Weapon") then
			-- Add alternate weapon slot
			slot.weaponSet = 1
			slot.shown = function()
				return not self.activeItemSet.useSecondWeaponSet
			end
			local swapSlot = new("ItemSlotControl", {"TOPLEFT",prevSlot,"BOTTOMLEFT"}, 0, 0, self, slotName.." Swap", slotName)
			addSlot(swapSlot)
			swapSlot.weaponSet = 2
			swapSlot.shown = function()
				return self.activeItemSet.useSecondWeaponSet
			end
			for i = 1, 6 do
				local abyssal = new("ItemSlotControl", {"TOPLEFT",prevSlot,"BOTTOMLEFT"}, 0, 0, self, slotName.."Swap Abyssal Socket "..i, "Abyssal #"..i)			
				addSlot(abyssal)
				abyssal.parentSlot = swapSlot
				abyssal.weaponSet = 2
				abyssal.shown = function()
					return not abyssal.inactive and self.activeItemSet.useSecondWeaponSet
				end
				swapSlot.abyssalSocketList[i] = abyssal
			end
		end
		if slotName == "Weapon 1" or slotName == "Weapon 2" or slotName == "Helmet" or slotName == "Gloves" or slotName == "Body Armour" or slotName == "Boots" or slotName == "Belt" then
			-- Add Abyssal Socket slots
			for i = 1, 6 do
				local abyssal = new("ItemSlotControl", {"TOPLEFT",prevSlot,"BOTTOMLEFT"}, 0, 0, self, slotName.." Abyssal Socket "..i, "Abyssal #"..i)			
				addSlot(abyssal)
				abyssal.parentSlot = slot
				if slotName:match("Weapon") then
					abyssal.weaponSet = 1
					abyssal.shown = function()
						return not abyssal.inactive and not self.activeItemSet.useSecondWeaponSet
					end
				end
				slot.abyssalSocketList[i] = abyssal
			end
		end
	end
	self.sockets = { }
	local socketOrder = { }
	for _, node in pairs(build.latestTree.nodes) do
		if node.type == "Socket" then
			t_insert(socketOrder, node)
		end
	end
	table.sort(socketOrder, function(a, b)
		return a.id < b.id
	end)
	for _, node in ipairs(socketOrder) do
		local socketControl = new("ItemSlotControl", {"TOPLEFT",prevSlot,"BOTTOMLEFT"}, 0, 0, self, "Jewel "..node.id, "Socket", node.id)
		self.sockets[node.id] = socketControl
		addSlot(socketControl)
	end
	self.controls.slotHeader = new("LabelControl", {"BOTTOMLEFT",self.slotAnchor,"TOPLEFT"}, 0, -4, 0, 16, "^7Equipped items:")
	self.controls.weaponSwap1 = new("ButtonControl", {"BOTTOMRIGHT",self.slotAnchor,"TOPRIGHT"}, -20, -2, 18, 18, "I", function()
		if self.activeItemSet.useSecondWeaponSet then
			self.activeItemSet.useSecondWeaponSet = false
			self:AddUndoState()
			self.build.buildFlag = true
			local mainSocketGroup = self.build.skillsTab.socketGroupList[self.build.mainSocketGroup]
			if mainSocketGroup and mainSocketGroup.slot and self.slots[mainSocketGroup.slot].weaponSet == 2 then
				for index, socketGroup in ipairs(self.build.skillsTab.socketGroupList) do
					if socketGroup.slot and self.slots[socketGroup.slot].weaponSet == 1 then
						self.build.mainSocketGroup = index
						break
					end
				end
			end
		end
	end)
	self.controls.weaponSwap1.overSizeText = 3
	self.controls.weaponSwap1.locked = function()
		return not self.activeItemSet.useSecondWeaponSet
	end
	self.controls.weaponSwap2 = new("ButtonControl", {"BOTTOMRIGHT",self.slotAnchor,"TOPRIGHT"}, 0, -2, 18, 18, "II", function()
		if not self.activeItemSet.useSecondWeaponSet then
			self.activeItemSet.useSecondWeaponSet = true
			self:AddUndoState()
			self.build.buildFlag = true
			local mainSocketGroup = self.build.skillsTab.socketGroupList[self.build.mainSocketGroup]
			if mainSocketGroup and mainSocketGroup.slot and self.slots[mainSocketGroup.slot].weaponSet == 1 then
				for index, socketGroup in ipairs(self.build.skillsTab.socketGroupList) do
					if socketGroup.slot and self.slots[socketGroup.slot].weaponSet == 2 then
						self.build.mainSocketGroup = index
						break
					end
				end
			end
		end
	end)
	self.controls.weaponSwap2.overSizeText = 3
	self.controls.weaponSwap2.locked = function()
		return self.activeItemSet.useSecondWeaponSet
	end
	self.controls.weaponSwapLabel = new("LabelControl", {"RIGHT",self.controls.weaponSwap1,"LEFT"}, -4, 0, 0, 14, "^7Weapon Set:")

	-- All items list
	if main.portraitMode then
		self.controls.itemList = new("ItemListControl", {"TOPRIGHT",self.lastSlot,"BOTTOMRIGHT"}, 0, 0, 360, 308, self)
	else
		self.controls.itemList = new("ItemListControl", {"TOPLEFT",self.slotAnchor,"TOPRIGHT"}, 20, -20, 360, 308, self)
	end

	-- Database selector
	self.controls.selectDBLabel = new("LabelControl", {"TOPLEFT",self.controls.itemList,"BOTTOMLEFT"}, 0, 14, 0, 16, "^7Import from:")
	self.controls.selectDBLabel.shown = function()
		return self.height < 980
	end
	self.controls.selectDB = new("DropDownControl", {"LEFT",self.controls.selectDBLabel,"RIGHT"}, 4, 0, 150, 18, { "Uniques", "Rare Templates" })

	-- Unique database
	self.controls.uniqueDB = new("ItemDBControl", {"TOPLEFT",self.controls.itemList,"BOTTOMLEFT"}, 0, 76, 360, function(c) return m_min(244, self.maxY - select(2, c:GetPos())) end, self, main.uniqueDB, "UNIQUE")
	self.controls.uniqueDB.y = function()
		return self.controls.selectDBLabel:IsShown() and 118 or 96
	end
	self.controls.uniqueDB.shown = function()
		return not self.controls.selectDBLabel:IsShown() or self.controls.selectDB.selIndex == 1
	end

	-- Rare template database
	self.controls.rareDB = new("ItemDBControl", {"TOPLEFT",self.controls.itemList,"BOTTOMLEFT"}, 0, 76, 360, function(c) return m_min(260, self.maxY - select(2, c:GetPos())) end, self, main.rareDB, "RARE")
	self.controls.rareDB.y = function()
		return self.controls.selectDBLabel:IsShown() and 78 or 396
	end
	self.controls.rareDB.shown = function()
		return not self.controls.selectDBLabel:IsShown() or self.controls.selectDB.selIndex == 2
	end

	-- Price Items
	self.controls.priceDisplayItem = new("ButtonControl", {"TOPLEFT",main.portraitMode and self.slotAnchor or self.controls.itemList,"TOPRIGHT"}, 20, -20, 248, 20, colorCodes.CUSTOM .. "PoB Trader", function()
		self:PriceItem()
	end)
	self.controls.priceDisplayItem.tooltipFunc = function(tooltip)
		tooltip:Clear()
		tooltip:AddLine(18, colorCodes.NEGATIVE .. "NEW FEATURE: ")
		tooltip:AddLine(16, "^7PoB Trader help search and compare items from the official PoE Trade website.")
		tooltip:AddLine(16, "^7It allows you to retrieve up to 100 items for a given slot based on filters you")
		tooltip:AddLine(16, "^7pre-set on the official PoE trade site and copy/paste within it.")
		tooltip:AddLine(16, "")
		tooltip:AddLine(16, colorCodes.WARNING .. "NOTE: PoB Trader is respectful of GGG's Search and Fetch Rate Limits;")
		tooltip:AddLine(16, colorCodes.WARNING .. "   however, if you use 3rd-party trade apps or interact with PoE's trade site")
		tooltip:AddLine(16, colorCodes.WARNING .. "   outside of PoB at the same time you can still get rate-limited as those are")
		tooltip:AddLine(16, colorCodes.WARNING .. "   enforced at an Internet IP address level and not application level.")
	end

	-- Create/import item
	self.controls.craftDisplayItem = new("ButtonControl", {"TOPLEFT",main.portraitMode and self.slotAnchor or self.controls.itemList,"TOPRIGHT"}, 20, main.portraitMode and -20 or 0, 120, 20, "Craft item...", function()
		self:CraftItem()
	end)
	self.controls.craftDisplayItem.shown = function()
		return self.displayItem == nil 
	end
	self.controls.newDisplayItem = new("ButtonControl", {"TOPLEFT",self.controls.craftDisplayItem,"TOPRIGHT"}, 8, 0, 120, 20, "Create custom...", function()
		self:EditDisplayItemText()
	end)
	self.controls.displayItemTip = new("LabelControl", {"TOPLEFT",self.controls.craftDisplayItem,"BOTTOMLEFT"}, 0, 8, 100, 16, 
[[^7Double-click an item from one of the lists,
or copy and paste an item from in game
(hover over the item and Ctrl+C) to view or edit
the item and add it to your build. You can 
also clone an item within Path of Building by 
copying and pasting it with Ctrl+C and Ctrl+V.

You can Control + Click an item to equip it, or 
drag it onto the slot.  This will also add it to 
your build if it's from the unique/template list.
If there's 2 slots an item can go in, 
holding Shift will put it in the second.]])
	self.controls.sharedItemList = new("SharedItemListControl", {"TOPLEFT",self.controls.craftDisplayItem, "BOTTOMLEFT"}, 0, 232, 340, 308, self)

	-- Display item
	self.displayItemTooltip = new("Tooltip")
	self.displayItemTooltip.maxWidth = 458
	self.anchorDisplayItem = new("Control", {"TOPLEFT",main.portraitMode and self.slotAnchor or self.controls.itemList,"TOPRIGHT"}, 20, main.portraitMode and -20 or 0, 0, 0)
	self.anchorDisplayItem.shown = function()
		return self.displayItem ~= nil
	end
	self.controls.addDisplayItem = new("ButtonControl", {"TOPLEFT",self.anchorDisplayItem,"TOPLEFT"}, 0, 0, 100, 20, "", function()
		self:AddDisplayItem()
	end)
	self.controls.addDisplayItem.label = function()
		return self.items[self.displayItem.id] and "Save" or "Add to build"
	end
	self.controls.editDisplayItem = new("ButtonControl", {"LEFT",self.controls.addDisplayItem,"RIGHT"}, 8, 0, 60, 20, "Edit...", function()
		self:EditDisplayItemText()
	end)
	self.controls.removeDisplayItem = new("ButtonControl", {"LEFT",self.controls.editDisplayItem,"RIGHT"}, 8, 0, 60, 20, "Cancel", function()
		self:SetDisplayItem()
	end)

	-- Section: Variant(s)

	self.controls.displayItemSectionVariant = new("Control", {"TOPLEFT",self.controls.addDisplayItem,"BOTTOMLEFT"}, 0, 8, 0, function()
		if not self.controls.displayItemVariant:IsShown() then
			return 0
		end
		return 28 + (self.displayItem.hasAltVariant and 24 or 0) + (self.displayItem.hasAltVariant2 and 24 or 0) + (self.displayItem.hasAltVariant3 and 24 or 0)
	end)
	self.controls.displayItemVariant = new("DropDownControl", {"TOPLEFT", self.controls.displayItemSectionVariant,"TOPLEFT"}, 0, 0, 300, 20, nil, function(index, value)
		self.displayItem.variant = index
		self.displayItem:BuildAndParseRaw()
		self:UpdateDisplayItemTooltip()
		self:UpdateDisplayItemRangeLines()
	end)
	self.controls.displayItemVariant.shown = function()
		return self.displayItem.variantList and #self.displayItem.variantList > 1
	end
	self.controls.displayItemAltVariant = new("DropDownControl", {"TOPLEFT",self.controls.displayItemVariant,"BOTTOMLEFT"}, 0, 4, 300, 20, nil, function(index, value)
		self.displayItem.variantAlt = index
		self.displayItem:BuildAndParseRaw()
		self:UpdateDisplayItemTooltip()
		self:UpdateDisplayItemRangeLines()
	end)
	self.controls.displayItemAltVariant.shown = function()
		return self.displayItem.hasAltVariant
	end
	self.controls.displayItemAltVariant2 = new("DropDownControl", {"TOPLEFT",self.controls.displayItemAltVariant,"BOTTOMLEFT"}, 0, 4, 300, 20, nil, function(index, value)
		self.displayItem.variantAlt2 = index
		self.displayItem:BuildAndParseRaw()
		self:UpdateDisplayItemTooltip()
		self:UpdateDisplayItemRangeLines()
	end)
	self.controls.displayItemAltVariant2.shown = function()
		return self.displayItem.hasAltVariant2
	end
	self.controls.displayItemAltVariant3 = new("DropDownControl", {"TOPLEFT",self.controls.displayItemAltVariant2,"BOTTOMLEFT"}, 0, 4, 300, 20, nil, function(index, value)
		self.displayItem.variantAlt3 = index
		self.displayItem:BuildAndParseRaw()
		self:UpdateDisplayItemTooltip()
		self:UpdateDisplayItemRangeLines()
	end)
	self.controls.displayItemAltVariant3.shown = function()
		return self.displayItem.hasAltVariant3
	end

	-- Section: Sockets and Links
	self.controls.displayItemSectionSockets = new("Control", {"TOPLEFT",self.controls.displayItemSectionVariant,"BOTTOMLEFT"}, 0, 0, 0, function()
		return self.displayItem and self.displayItem.selectableSocketCount > 0 and 28 or 0
	end)
	for i = 1, 6 do
		local drop = new("DropDownControl", {"TOPLEFT",self.controls.displayItemSectionSockets,"TOPLEFT"}, (i-1) * 64, 0, 36, 20, socketDropList, function(index, value)
			self.displayItem.sockets[i].color = value.color
			self.displayItem:BuildAndParseRaw()
			self:UpdateDisplayItemTooltip()
		end)
		drop.shown = function()
			return self.displayItem.selectableSocketCount >= i and self.displayItem.sockets[i] and self.displayItem.sockets[i].color ~= "A"
		end
		self.controls["displayItemSocket"..i] = drop
		if i < 6 then
			local link = new("CheckBoxControl", {"LEFT",drop,"RIGHT"}, 4, 0, 20, nil, function(state)
				if state and self.displayItem.sockets[i].group ~= self.displayItem.sockets[i+1].group then
					for s = i + 1, #self.displayItem.sockets do
						self.displayItem.sockets[s].group = self.displayItem.sockets[s].group - 1
					end
				elseif not state and self.displayItem.sockets[i].group == self.displayItem.sockets[i+1].group then
					for s = i + 1, #self.displayItem.sockets do
						self.displayItem.sockets[s].group = self.displayItem.sockets[s].group + 1
					end
				end
				self.displayItem:BuildAndParseRaw()
				self:UpdateDisplayItemTooltip()
			end)
			link.shown = function()
				return self.displayItem.selectableSocketCount > i and self.displayItem.sockets[i+1] and self.displayItem.sockets[i+1].color ~= "A"
			end
			self.controls["displayItemLink"..i] = link
		end
	end
	self.controls.displayItemAddSocket = new("ButtonControl", {"TOPLEFT",self.controls.displayItemSectionSockets,"TOPLEFT"}, function() return (#self.displayItem.sockets - self.displayItem.abyssalSocketCount) * 64 - 12 end, 0, 20, 20, "+", function()
		local insertIndex = #self.displayItem.sockets - self.displayItem.abyssalSocketCount + 1
		t_insert(self.displayItem.sockets, insertIndex, {
			color = self.displayItem.defaultSocketColor,
			group = self.displayItem.sockets[insertIndex - 1].group + 1
		})
		for s = insertIndex + 1, #self.displayItem.sockets do
			self.displayItem.sockets[s].group = self.displayItem.sockets[s].group + 1
		end
		self.displayItem:BuildAndParseRaw()
		self:UpdateSocketControls()
		self:UpdateDisplayItemTooltip()
	end)
	self.controls.displayItemAddSocket.shown = function()
		return #self.displayItem.sockets < self.displayItem.selectableSocketCount + self.displayItem.abyssalSocketCount
	end
	
	-- Section: Enchant / Anoint / Corrupt
	self.controls.displayItemSectionEnchant = new("Control", {"TOPLEFT",self.controls.displayItemSectionSockets,"BOTTOMLEFT"}, 0, 0, 0, function()
		return (self.controls.displayItemEnchant:IsShown() or self.controls.displayItemEnchant2:IsShown() or self.controls.displayItemAnoint:IsShown() or self.controls.displayItemAnoint2:IsShown() or self.controls.displayItemCorrupt:IsShown() ) and 28 or 0
	end)
	self.controls.displayItemEnchant = new("ButtonControl", {"TOPLEFT",self.controls.displayItemSectionEnchant,"TOPLEFT"}, 0, 0, 160, 20, "Apply Enchantment...", function()
		self:EnchantDisplayItem(1)
	end)
	self.controls.displayItemEnchant.shown = function()
		return self.displayItem and self.displayItem.enchantments
	end
	self.controls.displayItemEnchant2 = new("ButtonControl", {"TOPLEFT",self.controls.displayItemEnchant,"TOPRIGHT",true}, 8, 0, 160, 20, "Apply Enchantment 2...", function()
		self:EnchantDisplayItem(2)
	end)
	self.controls.displayItemEnchant2.shown = function()
		return self.displayItem and self.displayItem.enchantments and self.displayItem.canHaveTwoEnchants and #self.displayItem.enchantModLines > 0
	end
	self.controls.displayItemAnoint = new("ButtonControl", {"TOPLEFT",self.controls.displayItemEnchant2,"TOPRIGHT",true}, 8, 0, 100, 20, "Anoint...", function()
		self:AnointDisplayItem(1)
	end)
	self.controls.displayItemAnoint.shown = function()
		return self.displayItem and (self.displayItem.base.type == "Amulet" or self.displayItem.canBeAnointed)
	end
	self.controls.displayItemAnoint2 = new("ButtonControl", {"TOPLEFT",self.controls.displayItemAnoint,"TOPRIGHT",true}, 8, 0, 100, 20, "Anoint 2...", function()
		self:AnointDisplayItem(2)
	end)
	self.controls.displayItemAnoint2.shown = function()
		return self.displayItem and
			(self.displayItem.base.type == "Amulet" or self.displayItem.canBeAnointed) and
			self.displayItem.canHaveTwoEnchants and
			#self.displayItem.enchantModLines > 0
	end
	self.controls.displayItemAnoint3 = new("ButtonControl", {"TOPLEFT",self.controls.displayItemAnoint2,"TOPRIGHT",true}, 8, 0, 100, 20, "Anoint 3...", function()
		self:AnointDisplayItem(3)
	end)
	self.controls.displayItemAnoint3.shown = function()
		return self.displayItem and
			(self.displayItem.base.type == "Amulet" or self.displayItem.canBeAnointed) and
			self.displayItem.canHaveThreeEnchants and
			#self.displayItem.enchantModLines > 1
	end
	self.controls.displayItemAnoint4 = new("ButtonControl", {"TOPLEFT",self.controls.displayItemAnoint3,"TOPRIGHT",true}, 8, 0, 100, 20, "Anoint 4...", function()
		self:AnointDisplayItem(4)
	end)
	self.controls.displayItemAnoint4.shown = function()
		return self.displayItem and
			(self.displayItem.base.type == "Amulet" or self.displayItem.canBeAnointed) and
			self.displayItem.canHaveFourEnchants and
			#self.displayItem.enchantModLines > 2
	end
	self.controls.displayItemCorrupt = new("ButtonControl", {"TOPLEFT",self.controls.displayItemAnoint4,"TOPRIGHT",true}, 8, 10, 100, 20, "Corrupt...", function()
		self:CorruptDisplayItem("Corrupted")
	end)
	self.controls.displayItemCorrupt.shown = function()
		return self.displayItem and self.displayItem.corruptable
	end
	self.controls.displayItemScourge = new("ButtonControl", {"TOPLEFT",self.controls.displayItemCorrupt,"TOPRIGHT",true}, 8, 0, 100, 20, "Scourge...", function()
		self:CorruptDisplayItem("Scourge")
	end)
	self.controls.displayItemScourge.shown = function()
		return self.displayItem and self.displayItem.corruptable
	end

	-- Section: Influcence dropdowns
	local influenceDisplayList = { "Influence" }
	for i, curInfluenceInfo in ipairs(influenceInfo) do
		influenceDisplayList[i + 1] = curInfluenceInfo.display
	end
	local function setDisplayItemInfluence(influenceIndexList)
		self.displayItem:ResetInfluence()
		for _, index in ipairs(influenceIndexList) do
			if index > 0 then
				self.displayItem[influenceInfo[index].key] = true;
			end
		end

		if self.displayItem.crafted then
			for i = 1, self.displayItem.affixLimit do
				-- Force affix selectors to update
				local drop = self.controls["displayItemAffix"..i]
				drop.selFunc(drop.selIndex, drop.list[drop.selIndex])
			end
		end
		self.displayItem:BuildAndParseRaw()
		self:UpdateDisplayItemTooltip()
	end
	self.controls.displayItemSectionInfluence = new("Control", {"TOPLEFT",self.controls.displayItemSectionEnchant,"BOTTOMLEFT"}, 0, 0, 0, function()
		return self.displayItem and self.displayItem.canBeInfluenced and 28 or 0
	end)
	self.controls.displayItemInfluence = new("DropDownControl", {"TOPLEFT",self.controls.displayItemSectionInfluence,"TOPRIGHT"}, 0, 0, 100, 20, influenceDisplayList, function(index, value)
		local otherIndex = self.controls.displayItemInfluence2.selIndex
		setDisplayItemInfluence({ index - 1, otherIndex - 1 })
	end)
	self.controls.displayItemInfluence.shown = function()
		return self.displayItem and self.displayItem.canBeInfluenced
	end
	self.controls.displayItemInfluence2 = new("DropDownControl", {"TOPLEFT",self.controls.displayItemInfluence,"TOPRIGHT",true}, 8, 0, 100, 20, influenceDisplayList, function(index, value)
		local otherIndex = self.controls.displayItemInfluence.selIndex
		setDisplayItemInfluence({ index - 1, otherIndex - 1 })
	end)
	self.controls.displayItemInfluence2.shown = function()
		return self.displayItem and self.displayItem.canBeInfluenced
	end

	-- Section: Catalysts
	self.controls.displayItemSectionCatalyst = new("Control", {"TOPLEFT",self.controls.displayItemSectionInfluence,"BOTTOMLEFT"}, 0, 0, 0, function()
		return (self.controls.displayItemCatalyst:IsShown() or self.controls.displayItemCatalystQualitySlider:IsShown()) and 28 or 0
	end)
	self.controls.displayItemCatalyst = new("DropDownControl", {"TOPLEFT",self.controls.displayItemSectionCatalyst,"TOPRIGHT"}, 0, 0, 180, 20,
		{"Catalyst","Abrasive (Attack)","Accelerating (Speed)","Fertile (Life & Mana)","Imbued (Caster)","Intrinsic (Attribute)","Noxious (Physical & Chaos)",
		 "Prismatic (Resistance)","Tempering (Defense)","Turbulent (Elemental)","Unstable (Critical)"},
		function(index, value)
			self.displayItem.catalyst = index - 1
			if not self.displayItem.catalystQuality then
				self.displayItem.catalystQuality = 20
			end
			if self.displayItem.crafted then
				for i = 1, self.displayItem.affixLimit do
					-- Force affix selectors to update
					local drop = self.controls["displayItemAffix"..i]
					drop.selFunc(drop.selIndex, drop.list[drop.selIndex])
				end
			end
			self.displayItem:BuildAndParseRaw()
			self:UpdateDisplayItemTooltip()
		end)
	self.controls.displayItemCatalyst.shown = function()
		return self.displayItem and (self.displayItem.crafted or self.displayItem.hasModTags) and (self.displayItem.base.type == "Amulet" or self.displayItem.base.type == "Ring" or self.displayItem.base.type == "Belt")
	end
	self.controls.displayItemCatalystQualitySlider = new("SliderControl", {"LEFT",self.controls.displayItemCatalyst,"RIGHT",true}, 8, 0, 200, 20, function(val)
		self.displayItem.catalystQuality = round(val * 20)
		if self.displayItem.crafted then
			for i = 1, self.displayItem.affixLimit do
				-- Force affix selectors to update
				local drop = self.controls["displayItemAffix"..i]
				drop.selFunc(drop.selIndex, drop.list[drop.selIndex])
			end
		end
		self.displayItem:BuildAndParseRaw()
		self:UpdateDisplayItemTooltip()
	end)
	self.controls.displayItemCatalystQualitySlider.shown = function()
		return self.displayItem and (self.displayItem.crafted or self.displayItem.hasModTags) and self.displayItem.catalyst and self.displayItem.catalyst > 0
	end
	self.controls.displayItemCatalystQualitySlider.tooltipFunc = function(tooltip, val)
		local quality = round(val * 20)
		tooltip:Clear()
		tooltip:AddLine(16, "^7Quality: "..quality.."%")
	end

	-- Section: Cluster Jewel
	self.controls.displayItemSectionClusterJewel = new("Control", {"TOPLEFT",self.controls.displayItemSectionCatalyst,"BOTTOMLEFT"}, 0, 0, 0, function()
		return self.controls.displayItemClusterJewelSkill:IsShown() and 52 or 0
	end)
	self.controls.displayItemClusterJewelSkill = new("DropDownControl", {"TOPLEFT",self.controls.displayItemSectionClusterJewel,"TOPLEFT"}, 0, 0, 300, 20, { }, function(index, value)
		self.displayItem.clusterJewelSkill = value.skillId
		self:CraftClusterJewel()
	end) {
		shown = function()
			return self.displayItem and self.displayItem.crafted and self.displayItem.clusterJewel
		end
	}
	self.controls.displayItemClusterJewelNodeCountLabel = new("LabelControl", {"TOPLEFT",self.controls.displayItemClusterJewelSkill,"BOTTOMLEFT"}, 0, 7, 0, 14, "^7Added Passives:")
	self.controls.displayItemClusterJewelNodeCount = new("SliderControl", {"LEFT",self.controls.displayItemClusterJewelNodeCountLabel,"RIGHT"}, 2, 0, 150, 20, function(val)
		local divVal = self.controls.displayItemClusterJewelNodeCount:GetDivVal()
		local clusterJewel = self.displayItem.clusterJewel
		self.displayItem.clusterJewelNodeCount = round(val * (clusterJewel.maxNodes - clusterJewel.minNodes) + clusterJewel.minNodes)
		self:CraftClusterJewel()
	end)

	-- Section: Affix Selection
	self.controls.displayItemSectionAffix = new("Control", {"TOPLEFT",self.controls.displayItemSectionClusterJewel,"BOTTOMLEFT"}, 0, 0, 0, function()
		if not self.displayItem or not self.displayItem.crafted then
			return 0
		end
		local h = 6
		for i = 1, 6 do
			if self.controls["displayItemAffix"..i]:IsShown() then
				h = h + 24
				if self.controls["displayItemAffixRange"..i]:IsShown() then
					h = h + 18
				end
			end
		end
		return h
	end)
	for i = 1, 6 do
		local prev = self.controls["displayItemAffix"..(i-1)] or self.controls.displayItemSectionAffix
		local drop, slider
		drop = new("DropDownControl", {"TOPLEFT",prev,"TOPLEFT"}, i==1 and 40 or 0, 0, 418, 20, nil, function(index, value)
			local affix = { modId = "None" }
			if value.modId then
				affix.modId = value.modId
				affix.range = slider.val
			elseif value.modList then
				slider.divCount = #value.modList
				local index, range = slider:GetDivVal()
				affix.modId = value.modList[index]
				affix.range = range
			end
			self.displayItem[drop.outputTable][drop.outputIndex] = affix
			self.displayItem:Craft()
			self:UpdateDisplayItemTooltip()
			self:UpdateAffixControls()
		end)
		drop.y = function()
			return i == 1 and 0 or 24 + (prev.slider:IsShown() and 18 or 0)
		end
		drop.tooltipFunc = function(tooltip, mode, index, value)
			local modList = value.modList
			if not modList or main.popups[1] or mode == "OUT" or (self.selControl and self.selControl ~= drop) then
				tooltip:Clear()
			elseif tooltip:CheckForUpdate(modList) then
				if value.modId or #modList == 1 then
					local mod = self.displayItem.affixes[value.modId or modList[1]]
					tooltip:AddLine(16, "^7Affix: "..mod.affix)
					for _, line in ipairs(mod) do
						tooltip:AddLine(14, "^7"..line)
					end
					if mod.level > 1 then
						tooltip:AddLine(16, "Level: "..mod.level)
					end
					if mod.modTags and #mod.modTags > 0 then
						tooltip:AddLine(16, "Tags: "..table.concat(mod.modTags, ', '))
					end

					local notableName = mod[1] and mod[1]:match("1 Added Passive Skill is (.*)")
					local node = notableName and self.build.spec.tree.clusterNodeMap[notableName]
					if node then
						tooltip:AddSeparator(14)

						-- Node name
						self.socketViewer:AddNodeName(tooltip, node, self.build)

						-- Node description
						if node.sd[1] then
							tooltip:AddLine(16, "")
							for i, line in ipairs(node.sd) do
								tooltip:AddLine(16, ((node.mods[i].extra or not node.mods[i].list) and colorCodes.UNSUPPORTED or colorCodes.MAGIC)..line)
							end
						end

						-- Reminder text
						if node.reminderText then
							tooltip:AddSeparator(14)
							for _, line in ipairs(node.reminderText) do
								tooltip:AddLine(14, "^xA0A080"..line)
							end
						end

						-- Comparison
						tooltip:AddSeparator(14)
						self:AppendAnointTooltip(tooltip, node, "Allocating")

						-- Information of for this notable appears
						local clusterInfo = self.build.data.clusterJewelInfoForNotable[notableName]
						if clusterInfo then
							tooltip:AddSeparator(14)
							tooltip:AddLine(20, "^7"..notableName.." can appear on:")
							local isFirstSize = true
							for size, v in pairs(clusterInfo.size) do
								tooltip:AddLine(18, colorCodes.MAGIC..size..":")
								local sizeSkills = self.build.data.clusterJewels.jewels[size].skills
								for i, type in ipairs(clusterInfo.jewelTypes) do
									if sizeSkills[type] then
										tooltip:AddLine(14, "^7    "..sizeSkills[type].name)
									end
								end
								if not isFirstSize then
									tooltip:AddLine(10, "")
								end
								isFirstSize = false
							end
						end
					end
				else
					tooltip:AddLine(16, "^7"..#modList.." Tiers")
					local minMod = self.displayItem.affixes[modList[1]]
					local maxMod = self.displayItem.affixes[modList[#modList]]
					for l, line in ipairs(minMod) do
						local minLine = line:gsub("%((%d[%d%.]*)%-(%d[%d%.]*)%)", "%1")
						local maxLine = maxMod[l]:gsub("%((%d[%d%.]*)%-(%d[%d%.]*)%)", "%2")
						if maxLine == maxMod[l] then
							tooltip:AddLine(14, maxLine)
						else
							local start = 1
							tooltip:AddLine(14, minLine:gsub("%d[%d%.]*", function(min)
								local s, e, max = maxLine:find("(%d[%d%.]*)", start)
								start = e + 1
								if min == max then
									return min
								else
									return "("..min.."-"..max..")"
								end
							end))
						end
					end
					tooltip:AddLine(16, "Level: "..minMod.level.." to "..maxMod.level)
					-- Assuming that all mods have the same tags
					if maxMod.modTags and #maxMod.modTags > 0 then
						tooltip:AddLine(16, "Tags: "..table.concat(maxMod.modTags, ', '))
					end
				end
			end
		end
		drop.shown = function()
			return self.displayItem and self.displayItem.crafted and i <= self.displayItem.affixLimit
		end
		slider = new("SliderControl", {"TOPLEFT",drop,"BOTTOMLEFT"}, 0, 2, 300, 16, function(val)
			local affix = self.displayItem[drop.outputTable][drop.outputIndex]
			local index, range = slider:GetDivVal()
			affix.modId = drop.list[drop.selIndex].modList[index]
			affix.range = range
			self.displayItem:Craft()
			self:UpdateDisplayItemTooltip()
		end)
		slider.width = function()
			return slider.divCount and 300 or 100
		end
		slider.tooltipFunc = function(tooltip, val)
			local modList = drop.list[drop.selIndex].modList
			if not modList or main.popups[1] or (self.selControl and self.selControl ~= slider) then
				tooltip:Clear()
			elseif tooltip:CheckForUpdate(val, modList) then
				local index, range = slider:GetDivVal(val)
				local modId = modList[index]
				local mod = self.displayItem.affixes[modId]
				for _, line in ipairs(mod) do
					tooltip:AddLine(16, itemLib.applyRange(line, range))
				end
				tooltip:AddSeparator(10)
				if #modList > 1 then
					tooltip:AddLine(16, "^7Affix: Tier "..(#modList - isValueInArray(modList, modId) + 1).." ("..mod.affix..")")
				else
					tooltip:AddLine(16, "^7Affix: "..mod.affix)
				end
				for _, line in ipairs(mod) do
					tooltip:AddLine(14, line)
				end
				if mod.level > 1 then
					tooltip:AddLine(16, "Level: "..mod.level)
				end
			end
		end
		drop.slider = slider
		self.controls["displayItemAffix"..i] = drop
		self.controls["displayItemAffixLabel"..i] = new("LabelControl", {"RIGHT",drop,"LEFT"}, -4, 0, 0, 14, function()
			return drop.outputTable == "prefixes" and "^7Prefix:" or "^7Suffix:"
		end)
		self.controls["displayItemAffixRange"..i] = slider
		self.controls["displayItemAffixRangeLabel"..i] = new("LabelControl", {"RIGHT",slider,"LEFT"}, -4, 0, 0, 14, function()
			return drop.selIndex > 1 and "^7Roll:" or "^x7F7F7FRoll:"
		end)
	end

	-- Section: Custom modifiers
	self.controls.displayItemSectionCustom = new("Control", {"TOPLEFT",self.controls.displayItemSectionAffix,"BOTTOMLEFT"}, 0, 0, 0, function()
		return self.controls.displayItemAddCustom:IsShown() and 28 + self.displayItem.customCount * 22 or 0
	end)
	self.controls.displayItemAddCustom = new("ButtonControl", {"TOPLEFT",self.controls.displayItemSectionCustom,"TOPLEFT"}, 0, 0, 120, 20, "Add modifier...", function()
		self:AddCustomModifierToDisplayItem()
	end)
	self.controls.displayItemAddCustom.shown = function()
		return self.displayItem and (self.displayItem.rarity == "MAGIC" or self.displayItem.rarity == "RARE")
	end

	-- Section: Modifier Range
	self.controls.displayItemSectionRange = new("Control", {"TOPLEFT",self.controls.displayItemSectionCustom,"BOTTOMLEFT"}, 0, 0, 0, function()
		return self.displayItem.rangeLineList[1] and 28 or 0
	end)
	self.controls.displayItemRangeLine = new("DropDownControl", {"TOPLEFT",self.controls.displayItemSectionRange,"TOPLEFT"}, 0, 0, 350, 18, nil, function(index, value)
		self.controls.displayItemRangeSlider.val = self.displayItem.rangeLineList[index].range
	end)
	self.controls.displayItemRangeLine.shown = function()
		return self.displayItem and self.displayItem.rangeLineList[1] ~= nil
	end
	self.controls.displayItemRangeSlider = new("SliderControl", {"LEFT",self.controls.displayItemRangeLine,"RIGHT"}, 8, 0, 100, 18, function(val)
		self.displayItem.rangeLineList[self.controls.displayItemRangeLine.selIndex].range = val
		self.displayItem:BuildAndParseRaw()
		self:UpdateDisplayItemTooltip()
		self:UpdateCustomControls()
	end)

	-- Tooltip anchor
	self.controls.displayItemTooltipAnchor = new("Control", {"TOPLEFT",self.controls.displayItemSectionRange,"BOTTOMLEFT"})

	-- Scroll bars
	self.controls.scrollBarH = new("ScrollBarControl", nil, 0, 0, 0, 18, 100, "HORIZONTAL", true)
	self.controls.scrollBarV = new("ScrollBarControl", nil, 0, 0, 18, 0, 100, "VERTICAL", true)

	-- Initialise drag target lists
	t_insert(self.controls.itemList.dragTargetList, self.controls.sharedItemList)
	t_insert(self.controls.itemList.dragTargetList, build.controls.mainSkillMinion)
	t_insert(self.controls.uniqueDB.dragTargetList, self.controls.itemList)
	t_insert(self.controls.uniqueDB.dragTargetList, self.controls.sharedItemList)
	t_insert(self.controls.uniqueDB.dragTargetList, build.controls.mainSkillMinion)
	t_insert(self.controls.rareDB.dragTargetList, self.controls.itemList)
	t_insert(self.controls.rareDB.dragTargetList, self.controls.sharedItemList)
	t_insert(self.controls.rareDB.dragTargetList, build.controls.mainSkillMinion)
	t_insert(self.controls.sharedItemList.dragTargetList, self.controls.itemList)
	t_insert(self.controls.sharedItemList.dragTargetList, build.controls.mainSkillMinion)
	for _, slot in pairs(self.slots) do
		t_insert(self.controls.itemList.dragTargetList, slot)
		t_insert(self.controls.uniqueDB.dragTargetList, slot)
		t_insert(self.controls.rareDB.dragTargetList, slot)
		t_insert(self.controls.sharedItemList.dragTargetList, slot)
	end

	-- Initialise item sets
	self.itemSets = { }
	self.itemSetOrderList = { 1 }
	self:NewItemSet(1)
	self:SetActiveItemSet(1)

	self:PopulateSlots()
	self.lastSlot = self.slots[baseSlots[#baseSlots]]
end)

function ItemsTabClass:Load(xml, dbFileName)
	self.activeItemSetId = 0
	self.itemSets = { }
	self.itemSetOrderList = { }
	for _, node in ipairs(xml) do
		if node.elem == "Item" then
			local item = new("Item", "")
			item.id = tonumber(node.attrib.id)
			item.variant = tonumber(node.attrib.variant)
			if node.attrib.variantAlt then
				item.hasAltVariant = true
				item.variantAlt = tonumber(node.attrib.variantAlt)
			end
			if node.attrib.variantAlt2 then
				item.hasAltVariant2 = true
				item.variantAlt2 = tonumber(node.attrib.variantAlt2)
			end
			if node.attrib.variantAlt3 then
				item.hasAltVariant3 = true
				item.variantAlt3 = tonumber(node.attrib.variantAlt3)
			end
			for _, child in ipairs(node) do
				if type(child) == "string" then
					item:ParseRaw(child)
				elseif child.elem == "ModRange" then
					local id = tonumber(child.attrib.id) or 0
					local range = tonumber(child.attrib.range) or 1
					-- This is garbage, but needed due to change to separate mod line lists
					-- 'ModRange' elements are legacy though, so is this actually needed? :<
					-- Maybe it is? Maybe it isn't? Maybe up is down? Maybe good is bad? AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
					-- Sorry, cluster jewels are making me crazy(-ier)
					for _, list in ipairs{item.buffModLines, item.enchantModLines, item.scourgeModLines, item.implicitModLines, item.explicitModLines} do
						if id <= #list then
							list[id].range = range
							break
						end
						id = id - #list
					end
				end
			end
			if item.base then
				item:BuildModList()
				self.items[item.id] = item
				t_insert(self.itemOrderList, item.id)
			end
		-- Below is OBE and left for legacy compatibility (all Slots are part of ItemSets now)
		elseif node.elem == "Slot" then
			local slot = self.slots[node.attrib.name or ""]
			if slot then
				slot.selItemId = tonumber(node.attrib.itemId)
				if slot.controls.activate then
					slot.active = node.attrib.active == "true"
					slot.controls.activate.state = slot.active
				end
			end
		elseif node.elem == "ItemSet" then
			local itemSet = self:NewItemSet(tonumber(node.attrib.id))
			itemSet.title = node.attrib.title
			itemSet.useSecondWeaponSet = node.attrib.useSecondWeaponSet == "true"
			for _, child in ipairs(node) do
				if child.elem == "Slot" then
					local slotName = child.attrib.name or ""
					if itemSet[slotName] then
						itemSet[slotName].selItemId = tonumber(child.attrib.itemId)
						itemSet[slotName].active = child.attrib.active == "true"
						itemSet[slotName].pbURL = child.attrib.itemPbURL or ""
					end
				elseif child.elem == "Socket" then
					itemSet["socketNodes"][tonumber(child.attrib.nodeId)] = {
						selItemId = tonumber(child.attrib.itemId),
						pbURL = child.attrib.itemPbURL or ""
					}
				end
			end
			t_insert(self.itemSetOrderList, itemSet.id)
		end
	end
	if not self.itemSetOrderList[1] then
		self.activeItemSet = self:NewItemSet(1)
		self.activeItemSet.useSecondWeaponSet = xml.attrib.useSecondWeaponSet == "true"
		self.itemSetOrderList[1] = 1
	end
	self:SetActiveItemSet(tonumber(xml.attrib.activeItemSet) or 1)
	self:ResetUndo()
end

function ItemsTabClass:Save(xml)
	xml.attrib = {
		activeItemSet = tostring(self.activeItemSetId),
		useSecondWeaponSet = tostring(self.activeItemSet.useSecondWeaponSet),
	}
	for _, id in ipairs(self.itemOrderList) do
		local item = self.items[id]
		local child = { 
			elem = "Item", 
			attrib = { 
				id = tostring(id), 
				variant = item.variant and tostring(item.variant), 
				variantAlt = item.variantAlt and tostring(item.variantAlt), 
				variantAlt2 = item.variantAlt2 and tostring(item.variantAlt2) 
			} 
		}
		item:BuildAndParseRaw()
		t_insert(child, item.raw)
		local id = #item.buffModLines + 1
		for _, modLine in ipairs(item.enchantModLines) do
			if modLine.range then
				t_insert(child, { elem = "ModRange", attrib = { id = tostring(id), range = tostring(modLine.range) } })
			end
			id = id + 1
		end
		for _, modLine in ipairs(item.scourgeModLines) do
			if modLine.range then
				t_insert(child, { elem = "ModRange", attrib = { id = tostring(id), range = tostring(modLine.range) } })
			end
			id = id + 1
		end
		for _, modLine in ipairs(item.implicitModLines) do
			if modLine.range then
				t_insert(child, { elem = "ModRange", attrib = { id = tostring(id), range = tostring(modLine.range) } })
			end
			id = id + 1
		end
		for _, modLine in ipairs(item.explicitModLines) do
			if modLine.range then
				t_insert(child, { elem = "ModRange", attrib = { id = tostring(id), range = tostring(modLine.range) } })
			end
			id = id + 1
		end
		t_insert(xml, child)
	end
	for _, itemSetId in ipairs(self.itemSetOrderList) do
		local itemSet = self.itemSets[itemSetId]
		local child = { elem = "ItemSet", attrib = { id = tostring(itemSetId), title = itemSet.title, useSecondWeaponSet = tostring(itemSet.useSecondWeaponSet) } }
		for slotName, slot in pairs(self.slots) do
			if not slot.nodeId then
				t_insert(child, { elem = "Slot", attrib = { name = slotName, itemId = tostring(itemSet[slotName].selItemId), itemPbURL = itemSet[slotName].pbURL or "", active = itemSet[slotName].active and "true" }})
			end
		end
		if itemSet["socketNodes"] then
			for nodeId, tbl in pairs(itemSet["socketNodes"]) do
				if self.sockets[nodeId] then
					t_insert(child, { elem = "Socket", attrib = { nodeId = tostring(nodeId), itemId = tostring(tbl.selItemId), itemPbURL = itemSet["socketNodes"][nodeId].pbURL or "" }})
				else
					t_insert(child, { elem = "Socket", attrib = { nodeId = tostring(nodeId), itemId = tostring(0), itemPbURL = itemSet["socketNodes"][nodeId].pbURL or "" }})
				end
			end
		end
		t_insert(xml, child)
	end
	self.modFlag = false
end

function ItemsTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height
	self.controls.scrollBarH.width = viewPort.width
	self.controls.scrollBarH.x = viewPort.x
	self.controls.scrollBarH.y = viewPort.y + viewPort.height - 18
	self.controls.scrollBarV.height = viewPort.height - 18
	self.controls.scrollBarV.x = viewPort.x + viewPort.width - 18
	self.controls.scrollBarV.y = viewPort.y
	do
		local maxY = select(2, self.lastSlot:GetPos()) + 24
		local maxX = self.anchorDisplayItem:GetPos() + 462
		if self.displayItem then
			local x, y = self.controls.displayItemTooltipAnchor:GetPos()
			local ttW, ttH = self.displayItemTooltip:GetDynamicSize(viewPort)
			maxY = m_max(maxY, y + ttH + 4)
			maxX = m_max(maxX, x + ttW + 80)
		end
		local contentHeight = maxY - self.y
		local contentWidth = maxX - self.x
		local v = contentHeight > viewPort.height
		local h = contentWidth > viewPort.width - (v and 20 or 0)
		if h then
			v = contentHeight > viewPort.height - 20
		end
		self.controls.scrollBarV:SetContentDimension(contentHeight, viewPort.height - (h and 20 or 0))
		self.controls.scrollBarH:SetContentDimension(contentWidth, viewPort.width - (v and 20 or 0))
		if self.snapHScroll == "RIGHT" then
			self.controls.scrollBarH:SetOffset(self.controls.scrollBarH.offsetMax)
		elseif self.snapHScroll == "LEFT" then
			self.controls.scrollBarH:SetOffset(0)
		end
		self.snapHScroll = nil
		self.maxY = h and self.controls.scrollBarH.y or viewPort.y + viewPort.height
	end
	self.x = self.x - self.controls.scrollBarH.offset
	self.y = self.y - self.controls.scrollBarV.offset
	
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then	
			if event.key == "v" and IsKeyDown("CTRL") then
				local newItem = Paste()
				if newItem then
					self:CreateDisplayItemFromRaw(newItem, true)
				end
			elseif event.key == "e" then
				local mOverControl = self:GetMouseOverControl()
				if mOverControl and mOverControl._className == "ItemSlotControl" and mOverControl.selItemId ~= 0 then
					-- Trigger itemList's double click procedure
					self.controls.itemList:OnSelClick(0, mOverControl.selItemId, true)
				end
			elseif event.key == "z" and IsKeyDown("CTRL") then
				self:Undo()
				self.build.buildFlag = true
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self:Redo()
				self.build.buildFlag = true
			elseif event.key == "f" and IsKeyDown("CTRL") then
				local selUnique = self.selControl == self.controls.uniqueDB.controls.search
				local selRare = self.selControl == self.controls.rareDB.controls.search
				if selUnique or (self.controls.selectDB:IsShown() and not selRare and self.controls.selectDB.selIndex == 2) then
					self:SelectControl(self.controls.rareDB.controls.search)
					self.controls.selectDB.selIndex = 2
				else
					self:SelectControl(self.controls.uniqueDB.controls.search)
					self.controls.selectDB.selIndex = 1
				end
			end
		end
	end
	self:ProcessControlsInput(inputEvents, viewPort)
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyUp" then
			if event.key == "WHEELDOWN" or event.key == "PAGEDOWN" then
				if self.controls.scrollBarV:IsMouseOver() or not self.controls.scrollBarH:IsShown() then
					self.controls.scrollBarV:Scroll(1)
				else
					self.controls.scrollBarH:Scroll(1)
				end
			elseif event.key == "WHEELUP" or event.key == "PAGEUP" then
				if self.controls.scrollBarV:IsMouseOver() or not self.controls.scrollBarH:IsShown() then
					self.controls.scrollBarV:Scroll(-1)
				else
					self.controls.scrollBarH:Scroll(-1)
				end
			end
		end
	end

	main:DrawBackground(viewPort)

	local newItemList = { }
	for index, itemSetId in ipairs(self.itemSetOrderList) do
		local itemSet = self.itemSets[itemSetId]
		t_insert(newItemList, itemSet.title or "Default")
		if itemSetId == self.activeItemSetId then
			self.controls.setSelect.selIndex = index
		end
	end
	self.controls.setSelect:SetList(newItemList)

	if self.displayItem then
		local x, y = self.controls.displayItemTooltipAnchor:GetPos()
		self.displayItemTooltip:Draw(x, y, nil, nil, viewPort)
	end

	self:UpdateSockets()

	self:DrawControls(viewPort)
	if self.controls.scrollBarH:IsShown() then
		self.controls.scrollBarH:Draw(viewPort)
	end
	if self.controls.scrollBarV:IsShown() then
		self.controls.scrollBarV:Draw(viewPort)
	end
end

-- Creates a new item set
function ItemsTabClass:NewItemSet(itemSetId)
	local itemSet = { id = itemSetId }
	if not itemSetId then
		itemSet.id = 1
		while self.itemSets[itemSet.id] do
			itemSet.id = itemSet.id + 1
		end
	end
	for slotName, slot in pairs(self.slots) do
		if not slot.nodeId then
			itemSet[slotName] = { selItemId = 0 }
		end
	end
	itemSet["socketNodes"] = { }
	if self.activeItemSet and self.activeItemSet["socketNodes"] then
		for nodeId, _ in pairs(self.activeItemSet["socketNodes"]) do
			itemSet["socketNodes"][nodeId] = { selItemId = 0 }
		end
	end
	self.itemSets[itemSet.id] = itemSet
	return itemSet
end

-- Changes the active item set
function ItemsTabClass:SetActiveItemSet(itemSetId)
	local prevSet = self.activeItemSet
	if not self.itemSets[itemSetId] then
		itemSetId = self.itemSetOrderList[1]
	end
	self.activeItemSetId = itemSetId
	self.activeItemSet = self.itemSets[itemSetId]
	local curSet = self.activeItemSet
	for slotName, slot in pairs(self.slots) do
		if not slot.nodeId then
			if prevSet then
				-- Update the previous set
				prevSet[slotName].selItemId = slot.selItemId
				prevSet[slotName].active = slot.active
			end
			-- Equip the incoming set's item
			slot.selItemId = curSet[slotName].selItemId
			slot.active = curSet[slotName].active
			if slot.controls.activate then
				slot.controls.activate.state = slot.active
			end
		end
	end

	-- Copy over Jewel Sockets
	if prevSet then
		if curSet["socketNodes"] then
			prevSet["socketNodes"] = { }
			for nodeId, _ in pairs(curSet["socketNodes"]) do
				if self.sockets[nodeId] then
					prevSet["socketNodes"][nodeId] = {
						selItemId = self.sockets[nodeId].selItemId
					}
					local item = self.items[self.sockets[nodeId].selItemId]
					if item and item.clusterJewel then
						self.build.spec.jewels[nodeId] = nil
					end
				else
					prevSet["socketNodes"][nodeId].selItemId = 0
				end
			end
		end
	end
	if curSet["socketNodes"] then
		for nodeId, tbl in pairs(curSet["socketNodes"]) do
			self.sockets[nodeId].selItemId = tbl.selItemId
			local item = self.items[tbl.selItemId]
			if self.build.spec and item and item.clusterJewel then
				self.build.spec.jewels[nodeId] = tbl.selItemId
			end
		end
	end
	if self.build.spec then
		self.build.spec:BuildClusterJewelGraphs()
	end
	self.build.buildFlag = true
	self:PopulateSlots()
end

-- Equips the given item in the given item set
function ItemsTabClass:EquipItemInSet(item, itemSetId)
	local itemSet = self.itemSets[itemSetId]
	local slotName = item:GetPrimarySlot()
	if self.slots[slotName].weaponSet == 1 and itemSet.useSecondWeaponSet then
		-- Redirect to second weapon set
		slotName = slotName .. " Swap"
	end
	if not item.id or not self.items[item.id] then
		item = new("Item", item.raw)
		self:AddItem(item, true)
	end
	local altSlot = slotName:gsub("1","2")
	if IsKeyDown("SHIFT") then
		-- Redirect to second slot if possible
		if self:IsItemValidForSlot(item, altSlot, itemSet) then
			slotName = altSlot
		end
	end
	if itemSet == self.activeItemSet then
		self.slots[slotName]:SetSelItemId(item.id)
	else
		itemSet[slotName].selItemId = item.id
		if itemSet[altSlot].selItemId ~= 0 and not self:IsItemValidForSlot(self.items[itemSet[altSlot].selItemId], altSlot, itemSet) then
			itemSet[altSlot].selItemId = 0
		end
	end
	self:PopulateSlots()
	self:AddUndoState()
	self.build.buildFlag = true
end

-- Update the item lists for all the slot controls
function ItemsTabClass:PopulateSlots()
	for _, slot in pairs(self.slots) do
		slot:Populate()
	end
	-- Populate the jewels
	for nodeId, slot in pairs(self.sockets) do
		slot:Populate()
	end
end

-- Updates the status and position of the socket controls
function ItemsTabClass:UpdateSockets()
	-- Build a list of active sockets
	local activeSocketList = { }
	for nodeId, slot in pairs(self.sockets) do
		if self.build.spec.allocNodes[nodeId] then
			t_insert(activeSocketList, nodeId)
			slot.inactive = false
		else
			slot.inactive = true
		end
	end
	table.sort(activeSocketList)

	-- Update the state of the active socket controls
	self.lastSlot = self.slots[baseSlots[#baseSlots]]
	--self.activeItemSet["socketNodes"] = { }
	for index, nodeId in ipairs(activeSocketList) do
		self.sockets[nodeId].label = "Socket #"..index
		self.lastSlot = self.sockets[nodeId]
		if self.activeItemSet["socketNodes"][nodeId] then
			self.activeItemSet["socketNodes"][nodeId].selItemId = self.sockets[nodeId].selItemId
		else
			self.activeItemSet["socketNodes"][nodeId] = {
				selItemId = self.sockets[nodeId].selItemId
			}
		end
	end

	if main.portraitMode then
		self.controls.itemList:SetAnchor("TOPRIGHT",self.lastSlot,"BOTTOMRIGHT", 0, 40)
	end
end

-- Returns the slot control and equipped jewel for the given node ID
function ItemsTabClass:GetSocketAndJewelForNodeID(nodeId)
	return self.sockets[nodeId], self.items[self.sockets[nodeId].selItemId]
end

-- Adds the given item to the build's item list
function ItemsTabClass:AddItem(item, noAutoEquip, index)
	if not item.id then
		-- Find an unused item ID
		item.id = 1
		while self.items[item.id] do
			item.id = item.id + 1
		end

		if index then
			t_insert(self.itemOrderList, index, item.id)
		else
			-- Add it to the end of the display order list
			t_insert(self.itemOrderList, item.id)
		end

		if not noAutoEquip then
			-- Autoequip it
			for _, slot in ipairs(self.orderedSlots) do
				if not slot.nodeId and slot.selItemId == 0 and slot:IsShown() and self:IsItemValidForSlot(item, slot.slotName) then
					slot:SetSelItemId(item.id)
					break
				end
			end
		end
	end
	
	-- Add it to the list
	local replacing = self.items[item.id]
	self.items[item.id] = item
	item:BuildModList()
	
	if replacing and (replacing.clusterJewel or item.clusterJewel or replacing.baseName == "Timeless Jewel") then
		-- We're replacing an existing item, and either the new or old one is a cluster jewel
		if isValueInTable(self.build.spec.jewels, item.id) then
			-- Item is currently equipped, so we need to rebuild the graphs
			self.build.spec:BuildClusterJewelGraphs()
		end
	end
end

-- Adds the current display item to the build's item list
function ItemsTabClass:AddDisplayItem(noAutoEquip)
	-- Add it to the list and clear the current display item
	self:AddItem(self.displayItem, noAutoEquip)
	self:SetDisplayItem()

	self:PopulateSlots()
	self:AddUndoState()
	self.build.buildFlag = true
end

-- Sorts the build's item list
function ItemsTabClass:SortItemList()
	table.sort(self.itemOrderList, function(a, b)
		local itemA = self.items[a]
		local itemB = self.items[b]
		local primSlotA = itemA:GetPrimarySlot()
		local primSlotB = itemB:GetPrimarySlot()
		if primSlotA ~= primSlotB then
			if not self.slotOrder[primSlotA] then
				return false
			elseif not self.slotOrder[primSlotB] then
				return true
			end
			return self.slotOrder[primSlotA] < self.slotOrder[primSlotB]
		end
		local equipSlotA, equipSetA = self:GetEquippedSlotForItem(itemA)
		local equipSlotB, equipSetB = self:GetEquippedSlotForItem(itemB)
		if equipSlotA and equipSlotB then
			if equipSlotA ~= equipSlotB then
				return self.slotOrder[equipSlotA.slotName] < self.slotOrder[equipSlotB.slotName]
			elseif equipSetA and not equipSetB then
				return false
			elseif not equipSetA and equipSetB then
				return true
			elseif equipSetA and equipSetB then
				return isValueInArray(self.itemSetOrderList, equipSetA.id) < isValueInArray(self.itemSetOrderList, equipSetB.id)
			end
		elseif equipSlotA then
			return true
		elseif equipSlotB then
			return false
		end
		return itemA.name < itemB.name
	end)
	self:AddUndoState()
end

-- Deletes an item
function ItemsTabClass:DeleteItem(item)
	for slotName, slot in pairs(self.slots) do
		if slot.selItemId == item.id then
			slot:SetSelItemId(0)
			self.build.buildFlag = true
		end
		if not slot.nodeId then
			for _, itemSet in pairs(self.itemSets) do
				if itemSet[slotName].selItemId == item.id then
					itemSet[slotName].selItemId = 0
					self.build.buildFlag = true
				end
			end
		end
	end
	for index, id in pairs(self.itemOrderList) do
		if id == item.id then
			t_remove(self.itemOrderList, index)
			break
		end
	end
	for _, spec in pairs(self.build.treeTab.specList) do
		for nodeId, itemId in pairs(spec.jewels) do
			if itemId == item.id then
				spec.jewels[nodeId] = 0
			end
		end
	end
	self.items[item.id] = nil
	self:PopulateSlots()
	self:AddUndoState()
end

-- Attempt to create a new item from the given item raw text and sets it as the new display item
function ItemsTabClass:CreateDisplayItemFromRaw(itemRaw, normalise)
	local newItem = new("Item", itemRaw)
	if newItem.base then
		if normalise then
			newItem:NormaliseQuality()
			newItem:BuildModList()
		end
		self:SetDisplayItem(newItem)
	end
end

-- Sets the display item to the given item
function ItemsTabClass:SetDisplayItem(item)
	self.displayItem = item
	if item then
		-- Update the display item controls
		self:UpdateDisplayItemTooltip()
		self.snapHScroll = "RIGHT"

		self.controls.displayItemVariant.list = item.variantList
		self.controls.displayItemVariant.selIndex = item.variant
		if item.hasAltVariant then
			self.controls.displayItemAltVariant.list = item.variantList
			self.controls.displayItemAltVariant.selIndex = item.variantAlt
		end
		if item.hasAltVariant2 then
			self.controls.displayItemAltVariant2.list = item.variantList
			self.controls.displayItemAltVariant2.selIndex = item.variantAlt2
		end
		if item.hasAltVariant3 then
			self.controls.displayItemAltVariant3.list = item.variantList
			self.controls.displayItemAltVariant3.selIndex = item.variantAlt3
		end
		self:UpdateSocketControls()
		if item.crafted then
			self:UpdateAffixControls()
		end

		-- Set both influence dropdowns
		local influence1 = 1
		local influence2 = 1
		for i, curInfluenceInfo in ipairs(influenceInfo) do
			if item[curInfluenceInfo.key] then
				if influence1 == 1 then
					influence1 = i + 1
				elseif influence2 == 1 then
					influence2 = i + 1
					break
				end
			end
		end
		self.controls.displayItemInfluence:SetSel(influence1, true) -- Don't call the selection function for the first influence dropdown as the second dropdown isn't properly set yet.
		self.controls.displayItemInfluence2:SetSel(influence2) -- The selection function for the second dropdown properly handles everything for both dropdowns
		self.controls.displayItemCatalyst:SetSel((item.catalyst or 0) + 1)
		if item.catalystQuality then
			self.controls.displayItemCatalystQualitySlider.val = m_min(item.catalystQuality / 20, 1)
		else
			self.controls.displayItemCatalystQualitySlider.val = 1
		end
		self:UpdateCustomControls()
		self:UpdateDisplayItemRangeLines()
		if item.clusterJewel and item.crafted then
			self:UpdateClusterJewelControls()
		end
	else
		self.snapHScroll = "LEFT"
	end
end

function ItemsTabClass:UpdateDisplayItemTooltip()
	self.displayItemTooltip:Clear()
	self:AddItemTooltip(self.displayItemTooltip, self.displayItem)
	self.displayItemTooltip.center = false
end

function ItemsTabClass:UpdateSocketControls()
	local sockets = self.displayItem.sockets
	for i = 1, #sockets - self.displayItem.abyssalSocketCount do
		self.controls["displayItemSocket"..i]:SelByValue(sockets[i].color, "color")
		if i > 1 then
			self.controls["displayItemLink"..(i-1)].state = sockets[i].group == sockets[i-1].group
		end
	end
end

function ItemsTabClass:UpdateClusterJewelControls()
	local item = self.displayItem

	local unavailableSkills = { ["affliction_strength"] = true, ["affliction_dexterity"] = true, ["affliction_intelligence"] = true, }

	-- Update list of skills
	local skillList = wipeTable(self.controls.displayItemClusterJewelSkill.list)
	for skillId, skill in pairs(item.clusterJewel.skills) do
		if not unavailableSkills[skillId] then
			t_insert(skillList, { label = skill.name, skillId = skillId })
		end
	end
	table.sort(skillList, function(a, b) return a.label < b.label end)
	if not item.clusterJewelSkill or not item.clusterJewel.skills[item.clusterJewelSkill] then
		item.clusterJewelSkill = skillList[1].skillId
	end
	self.controls.displayItemClusterJewelSkill:SelByValue(item.clusterJewelSkill, "skillId")

	-- Update added node count slider
	local countControl = self.controls.displayItemClusterJewelNodeCount
	item.clusterJewelNodeCount = m_min(m_max(item.clusterJewelNodeCount or item.clusterJewel.maxNodes, item.clusterJewel.minNodes), item.clusterJewel.maxNodes)
	countControl.divCount = item.clusterJewel.maxNodes - item.clusterJewel.minNodes
	countControl.val = (item.clusterJewelNodeCount - item.clusterJewel.minNodes) / (item.clusterJewel.maxNodes - item.clusterJewel.minNodes)

	self:CraftClusterJewel()
end

function ItemsTabClass:CraftClusterJewel()
	local item = self.displayItem
	wipeTable(item.enchantModLines)
	t_insert(item.enchantModLines, { line = "Adds "..(item.clusterJewelNodeCount or item.clusterJewel.maxNodes).." Passive Skills", crafted = true })
	if item.clusterJewel.size == "Large" then
		t_insert(item.enchantModLines, { line = "2 Added Passive Skills are Jewel Sockets", crafted = true })
	elseif item.clusterJewel.size == "Medium" then
		t_insert(item.enchantModLines, { line = "1 Added Passive Skill is a Jewel Socket", crafted = true })
	end
	local skill = item.clusterJewel.skills[item.clusterJewelSkill]
	t_insert(item.enchantModLines, { line = table.concat(skill.enchant, "\n"), crafted = true })
	item:BuildAndParseRaw()

	-- Update affixes manually to force out affixes that may now be invalid
	self:UpdateAffixControls()
	for i = 1, item.affixLimit do
		local drop = self.controls["displayItemAffix"..i]
		drop.selFunc(drop.selIndex, drop.list[drop.selIndex])
	end
end

-- Update affix selection controls
function ItemsTabClass:UpdateAffixControls()
	local item = self.displayItem
	for i = 1, item.affixLimit/2 do
		self:UpdateAffixControl(self.controls["displayItemAffix"..i], item, "Prefix", "prefixes", i)
		self:UpdateAffixControl(self.controls["displayItemAffix"..(i+item.affixLimit/2)], item, "Suffix", "suffixes", i)
	end	
	-- The custom affixes may have had their indexes changed, so the custom control UI is also rebuilt so that it will
	-- reference the correct affix index.
	self:UpdateCustomControls()
end

function ItemsTabClass:UpdateAffixControl(control, item, type, outputTable, outputIndex)
	local extraTags = { }
	local excludeGroups = { }
	for _, table in ipairs({"prefixes","suffixes"}) do
		for index = 1, item.affixLimit/2 do
			if index ~= outputIndex or table ~= outputTable then
				local mod = item.affixes[item[table][index] and item[table][index].modId]
				if mod then
					if mod.group then
						excludeGroups[mod.group] = true
					end
					if mod.tags then
						for _, tag in ipairs(mod.tags) do
							extraTags[tag] = true
						end
					end
				end
			end
		end
	end
	if item.clusterJewel and item.clusterJewelSkill then	
		local skill = item.clusterJewel.skills[item.clusterJewelSkill]
		if skill then
			extraTags[skill.tag] = true
		end
	end
	local affixList = { }
	for modId, mod in pairs(item.affixes) do
		if mod.type == type and not excludeGroups[mod.group] and item:GetModSpawnWeight(mod, extraTags) > 0 and not item:CheckIfModIsDelve(mod) then
			t_insert(affixList, modId)
		end
	end
	table.sort(affixList, function(a, b)
		local modA = item.affixes[a]
		local modB = item.affixes[b]
		if item.type == "Flask" then
			return modA.affix < modB.affix
		end
		for i = 1, m_max(#modA, #modB) do
			if not modA[i] then
				return true
			elseif not modB[i] then
				return false
			elseif modA.statOrder[i] ~= modB.statOrder[i] then
				return modA.statOrder[i] < modB.statOrder[i]
			end
		end
		return modA.level > modB.level
	end)
	control.selIndex = 1
	control.list = { "None" }
	control.outputTable = outputTable
	control.outputIndex = outputIndex
	control.slider.shown = false
	control.slider.val = 0.5
	local selAffix = item[outputTable][outputIndex].modId
	if item.type == "Flask" or (item.type == "Jewel" and item.base.subType ~= "Abyss") then
		for i, modId in pairs(affixList) do
			local mod = item.affixes[modId]
			if selAffix == modId then
				control.selIndex = i + 1
			end
			local modString = table.concat(mod, "/")
			local label = modString
			if item.type == "Flask" then
				label = mod.affix .. "   ^8[" .. modString .. "]"
			end
			control.list[i + 1] = {
				label = label,
				modList = { modId },
				modId = modId,
				haveRange = modString:match("%(%-?[%d%.]+%-[%d%.]+%)"),
			}
		end
	else
		local lastSeries
		for _, modId in ipairs(affixList) do
			local mod = item.affixes[modId]
			if not lastSeries or lastSeries.statOrderKey ~= mod.statOrderKey then
				local modString = table.concat(mod, "/")
				lastSeries = {
					label = modString,
					modList = { },
					haveRange = modString:match("%(%-?[%d%.]+%-[%d%.]+%)"),
					statOrderKey = mod.statOrderKey,
				}
				t_insert(control.list, lastSeries)
			end
			if selAffix == modId then
				control.selIndex = #control.list
			end
			t_insert(lastSeries.modList, 1, modId)
			if #lastSeries.modList == 2 then
				lastSeries.label = lastSeries.label:gsub("%d+%.?%d*","#"):gsub("%(#%-#%)","#")
				lastSeries.haveRange = true
			end
		end
	end
	if control.list[control.selIndex].haveRange then
		control.slider.divCount = #control.list[control.selIndex].modList
		control.slider.val = (isValueInArray(control.list[control.selIndex].modList, selAffix) - 1 + (item[outputTable][outputIndex].range or 0.5)) / control.slider.divCount
		if control.slider.divCount == 1 then
			control.slider.divCount = nil
		end
		control.slider.shown = true
	end
end

-- Create/update custom modifier controls
function ItemsTabClass:UpdateCustomControls()
	local item = self.displayItem
	local i = 1
	if item.rarity == "MAGIC" or item.rarity == "RARE" then
		for index, modLine in ipairs(item.explicitModLines) do
			if modLine.custom or modLine.crafted then
				local line = itemLib.formatModLine(modLine)
				if line then
					if not self.controls["displayItemCustomModifier"..i] then
						self.controls["displayItemCustomModifier"..i] = new("LabelControl", {"TOPLEFT",self.controls.displayItemSectionCustom,"TOPLEFT"}, 55, i * 22 + 4, 0, 16)
						self.controls["displayItemCustomModifierLabel"..i] = new("LabelControl", {"RIGHT",self.controls["displayItemCustomModifier"..i],"LEFT"}, -2, 0, 0, 16)
						self.controls["displayItemCustomModifierRemove"..i] = new("ButtonControl", {"LEFT",self.controls["displayItemCustomModifier"..i],"RIGHT"}, 4, 0, 70, 20, "^7Remove")
					end
					self.controls["displayItemCustomModifier"..i].shown = true
					local label = itemLib.formatModLine(modLine)
					if DrawStringCursorIndex(16, "VAR", label, 330, 10) < #label then
						label = label:sub(1, DrawStringCursorIndex(16, "VAR", label, 310, 10)) .. "..."
					end
					self.controls["displayItemCustomModifier"..i].label = label
					self.controls["displayItemCustomModifierLabel"..i].label = modLine.crafted and "^7Crafted:" or "^7Custom:"
					self.controls["displayItemCustomModifierRemove"..i].onClick = function()
						t_remove(item.explicitModLines, index)
						item:BuildAndParseRaw()
						local id = item.id
						self:CreateDisplayItemFromRaw(item:BuildRaw())
						self.displayItem.id = id
					end				
					i = i + 1
				end
			end
		end
	end
	item.customCount = i - 1
	while self.controls["displayItemCustomModifier"..i] do
		self.controls["displayItemCustomModifier"..i].shown = false
		i = i + 1
	end
end

-- Updates the range line dropdown and range slider for the current display item
function ItemsTabClass:UpdateDisplayItemRangeLines()
	if self.displayItem and self.displayItem.rangeLineList[1] then
		wipeTable(self.controls.displayItemRangeLine.list)
		for _, modLine in ipairs(self.displayItem.rangeLineList) do
			t_insert(self.controls.displayItemRangeLine.list, modLine.line)
		end
		self.controls.displayItemRangeLine.selIndex = 1
		self.controls.displayItemRangeSlider.val = self.displayItem.rangeLineList[1].range
	end
end

-- Returns the first slot in which the given item is equipped
function ItemsTabClass:GetEquippedSlotForItem(item)
	for _, slot in ipairs(self.orderedSlots) do
		if not slot.inactive then
			if slot.selItemId == item.id then
				return slot
			end
			for _, itemSetId in ipairs(self.itemSetOrderList) do
				local itemSet = self.itemSets[itemSetId]
				if itemSetId ~= self.activeItemSetId and itemSet[slot.slotName] and itemSet[slot.slotName].selItemId == item.id then
					return slot, itemSet
				end
			end
		end
	end
end

-- Check if the given item could be equipped in the given slot, taking into account possible conflicts with currently equipped items
-- For example, a shield is not valid for Weapon 2 if Weapon 1 is a staff, and a wand is not valid for Weapon 2 if Weapon 1 is a dagger
function ItemsTabClass:IsItemValidForSlot(item, slotName, itemSet)
	itemSet = itemSet or self.activeItemSet
	local slotType, slotId = slotName:match("^([%a ]+) (%d+)$")
	if not slotType then
		slotType = slotName
	end
	if slotType == "Jewel" then
		-- Special checks for jewel sockets
		local node = self.build.spec.tree.nodes[tonumber(slotId)] or self.build.spec.nodes[tonumber(slotId)]
		if not node or item.type ~= "Jewel" then
			return false
		elseif item.clusterJewel and not node.expansionJewel then
			-- Don't allow cluster jewels in inner sockets
			return false
		elseif not node.expansionJewel or node.expansionJewel.size == 2 then
			-- Outer sockets can fit anything
			return true
		else
			-- Only allow jewels that fit in this socket
			return not item.clusterJewel or item.clusterJewel.sizeIndex <= node.expansionJewel.size
		end
	elseif item.type == slotType then
		return true
	elseif item.type == "Jewel" and item.base.subType == "Abyss" and slotName:match("Abyssal Socket") then
		return true
	elseif slotName == "Weapon 1" or slotName == "Weapon 1 Swap" or slotName == "Weapon" then
		return item.base.weapon ~= nil
	elseif slotName == "Weapon 2" or slotName == "Weapon 2 Swap" then
		local weapon1Sel = itemSet[slotName == "Weapon 2" and "Weapon 1" or "Weapon 1 Swap"].selItemId or 0
		local weapon1Type = weapon1Sel > 0 and self.items[weapon1Sel].base.type or "None"
		if weapon1Type == "None" then
			return item.type == "Shield" or (self.build.data.weaponTypeInfo[item.type] and self.build.data.weaponTypeInfo[item.type].oneHand)
		elseif weapon1Type == "Bow" then
			return item.type == "Quiver"
		elseif self.build.data.weaponTypeInfo[weapon1Type].oneHand then
			return item.type == "Shield" or (self.build.data.weaponTypeInfo[item.type] and self.build.data.weaponTypeInfo[item.type].oneHand and ((weapon1Type == "Wand" and item.type == "Wand") or (weapon1Type ~= "Wand" and item.type ~= "Wand")))
		end
	end
end

-- Opens the item set manager
function ItemsTabClass:OpenItemSetManagePopup()
	local controls = { }
	controls.setList = new("ItemSetListControl", nil, -155, 50, 300, 200, self)
	controls.sharedList = new("SharedItemSetListControl", nil, 155, 50, 300, 200, self)
	controls.setList.dragTargetList = { controls.sharedList }
	controls.sharedList.dragTargetList = { controls.setList }
	controls.close = new("ButtonControl", nil, 0, 260, 90, 20, "Done", function()
		main:ClosePopup()
	end)
	main:OpenPopup(630, 290, "Manage Item Sets", controls)
end

-- Price Builder: set the notice message in upper right of price builder pane
function ItemsTabClass:SetNotice(notice_control, msg)
	notice_control:SetText(msg)
end

-- Price Builder: add time to the 3 rate-limit windows for search tracking
function ItemsTabClass:PriceBuilderInsertSearchRequest()
	local time = get_time()
	t_insert(self.rate_short_window, 1, time)
	t_insert(self.rate_medium_window, 1, time)
	t_insert(self.rate_long_window, 1, time)
end

-- Price Builder: add time to the 2 rate-limit windows for fetch tracking
function ItemsTabClass:PriceBuilderInsertFetchRequest()
	local time = get_time()
	t_insert(self.rate_short_fetch_window, 1, time)
	t_insert(self.rate_long_fetch_window, 1, time)
end

-- Price Builder: remove search times from rate-limit windows based on age out
function ItemsTabClass:PriceBuilderAgeOutSearchRequest(tbl, agedTime)
	local pop_count = 0
	for _, v in ipairs(tbl) do
		if v <= agedTime then
			pop_count = pop_count + 1
		end
	end

	for i = 1, pop_count do
		t_remove(tbl) 
	end
end

-- Price Builder: sync search rate tables to age out appropriate times from each rate-limit table
function ItemsTabClass:PriceBuilderSyncSearchRateTables(time)
	self:PriceBuilderAgeOutSearchRequest(self.rate_short_window, time - self.rate_short_time)
	self:PriceBuilderAgeOutSearchRequest(self.rate_medium_window, time - self.rate_medium_time)
	self:PriceBuilderAgeOutSearchRequest(self.rate_long_window, time - self.rate_long_time)
end

-- Price Builder: sync fetch rate tables to age out appropriate times from each rate-limit table
function ItemsTabClass:PriceBuilderSyncFetchRateTables(time)
	self:PriceBuilderAgeOutSearchRequest(self.rate_short_fetch_window, time - self.rate_short_fetch_time)
	self:PriceBuilderAgeOutSearchRequest(self.rate_long_fetch_window, time - self.rate_long_fetch_time)
end

-- Price Builder: check if we have slots in the three search rate-limit windows to issue a search
function ItemsTabClass:PriceBuilderCanSearch(controls)
	local time = get_time()
	self:PriceBuilderSyncSearchRateTables(time)
	if #self.rate_short_window < self.rate_short_max_searches and
		#self.rate_medium_window < self.rate_medium_max_searches and
		#self.rate_long_window < self.rate_long_max_searches then
		if controls.pbNotice.buf:find("SEARCH") then
			self:SetNotice(controls.pbNotice, "")
		end
		return true
	else
		local short_time = 0
		local medium_time = 0
		local long_time = 0
		if #self.rate_short_window >= self.rate_short_max_searches then
			short_time = self.rate_short_time - (time - self.rate_short_window[#self.rate_short_window])
		end
		if #self.rate_medium_window >= self.rate_medium_max_searches then
			medium_time = self.rate_medium_time - (time - self.rate_medium_window[#self.rate_medium_window])
		end
		if #self.rate_long_window >= self.rate_long_max_searches then
			long_time = self.rate_long_time - (time - self.rate_long_window[#self.rate_long_window])
		end
		self:SetNotice(controls.pbNotice, colorCodes.WARNING .. "<SEARCH RATE LIMIT> " .. tostring(m_max(short_time, m_max(medium_time, long_time))))
		return false
	end
end

-- Price Builder: check if we have slots in the two fetch rate-limit windows to issue a search
function ItemsTabClass:PriceBuilderCanFetch(controls)
	local time = get_time()
	self:PriceBuilderSyncFetchRateTables(time)
	if #self.rate_short_fetch_window < self.rate_short_max_fetches and
		#self.rate_long_fetch_window < self.rate_long_max_fetches then
		if controls.pbNotice.buf:find("FETCH") then
			self:SetNotice(controls.pbNotice, "")
		end
		return true
	else
		local short_time = 0
		local long_time = 0
		if #self.rate_short_fetch_window >= self.rate_short_max_fetches then
			short_time = self.rate_short_fetch_time - (time - self.rate_short_fetch_window[#self.rate_short_fetch_window])
		end
		if #self.rate_long_fetch_window >= self.rate_long_max_fetches then
			long_time = self.rate_long_fetch_time - (time - self.rate_long_fetch_window[#self.rate_long_fetch_window])
		end
		self:SetNotice(controls.pbNotice, colorCodes.WARNING .. "<FETCH RATE LIMIT> " .. tostring(m_max(short_time, long_time)))
		return false
	end
end

-- Opens the item pricing popup
function ItemsTabClass:PriceItem()
	-- Note: Per each Check Price button click we do 2 search requests
	--       Search is the most rate limiting behavior we need to track
	-- SEARCH REQUEST RATE LIMIT DATA (as of Feb 2021)
	--	 Up to  5 search requests in a 12 second window
	--	 Up to 15 search requests in a 62 second window
	--	 Up to 30 search requests in a 302 second window
	self.totalPrice = { }
	self.rate_short_window = { }
	self.rate_short_time = 12
	-- we reduce from 5 to 4 since we need 2 search slots for each request
	self.rate_short_max_searches = 4
	self.rate_medium_window = { }
	self.rate_medium_time = 62
	-- we reduce from 15 to 14 since we need 2 search slots for each request
	self.rate_medium_max_searches = 14
	self.rate_long_window = { }
	self.rate_long_time = 302
	-- we reduce from 30 to 29 since we need 2 search slots for each request
	self.rate_long_max_searches = 29

	-- FETCH REQUEST RATE LIMIT DATA (as of Feb 2021)
	--	 Up to 12 fetch requests in a 6 second window
	--	 Up to 16 fetch requests in a 14 second window
	self.rate_short_fetch_window = { }
	self.rate_short_fetch_time = 6
	-- we reduce from 12 to 7 since we may want up to 5 fetch slots for each request
	self.rate_short_max_fetches = 7
	self.rate_long_fetch_window = { }
	self.rate_long_fetch_time = 14
	-- we reduce from 16 to 11 since we may want up to 5 fetch slots for each request
	self.rate_long_max_fetches = 11

	-- table of price results index by slot and number of fetched results
	self.resultTbl = { }
	self.sortedResultTbl = { }

	-- default set of trade item sort selection
	self.pbSortSelectionIndex = 1
	self.pbCurrencyConversion = { }
	self.lastCurrencyConversionRequest = 0
	self.lastCurrencyFileTime = nil

	-- Count number of rows to render
	local row_count = 3 + #baseSlots
	-- Count sockets
	for _, slot in pairs(self.sockets) do
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
	local pane_width = 1246
	local controls = { }
	local cnt = 1
	controls.itemSetLabel = new("LabelControl",  {"TOPLEFT",nil,"TOPLEFT"}, 16, 15, 60, 18, colorCodes.CUSTOM .. "ItemSet: " .. (self.activeItemSet.title or "Default"))
	controls.pbNotice = new("EditControl",  {"TOP",nil,"TOP"}, 0, 15, 300, 16, "", nil, nil)
	controls.pbNotice.textCol = colorCodes.CUSTOM
	local sortSelectionList = {
		"Cheapest",
		"Highest DPS",
		"DPS / Price",
	}
	controls.itemSortSelection = new("DropDownControl", {"TOPRIGHT",nil,"TOPRIGHT"}, -12, 15, 100, 20, sortSelectionList, function(index, value)
		self.pbSortSelectionIndex = index
	end)
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
	for nodeId, slot in pairs(self.sockets) do
		if not slot.inactive then
			t_insert(activeSocketList, nodeId)
		end
	end
	table.sort(activeSocketList)
	for _, nodeId in pairs(activeSocketList) do
		local str_cnt = tostring(cnt)
		self:PriceItemRowDisplay(controls, str_cnt, {name = self.sockets[nodeId].label, ref = nodeId}, top_pane_alignment_ref, top_pane_alignment_width, top_pane_alignment_height, row_height)
		top_pane_alignment_ref = {"TOPLEFT",controls['name'..str_cnt],"TOPLEFT"}
		top_pane_alignment_width = 0
		top_pane_alignment_height = 28
		cnt = cnt + 1
	end
	controls.close = new("ButtonControl", nil, 0, pane_height - 30, 90, row_height, "Done", function()
		main:ClosePopup()
	end)
	controls.league = new("DropDownControl", {"TOPRIGHT",nil,"TOPRIGHT"}, -12, pane_height - 30, 100, 18, leagueDropList, function(index, value)
		self.pbLeague = value.name
		self:SetCurrencyConversionButton(controls)
	end)
	controls.league.selIndex = 1
	self.pbLeague = leagueDropList[controls.league.selIndex].name
	controls.leagueLabel = new("LabelControl", {"TOPRIGHT",controls.league,"TOPLEFT"}, -4, 0, 20, 16, "League:")
	controls.poesessidButton = new("ButtonControl", {"TOPLEFT",controls.leagueLabel,"TOPLEFT"}, -256, 0, 240, row_height, self.poe_sessid ~= "" and "HAVE POESESSID" or colorCodes.WARNING.."NEED POESESSID", function()
		local poesessid_controls = {}
		poesessid_controls.sessionInput = new("EditControl", nil, 0, 18, 350, 18, #self.poe_sessid == 32 and self.poe_sessid or "<PASTE POESESSID FROM BROWSER>", "POESESSID", "%X", 32, function(buf)
			if #poesessid_controls.sessionInput.buf == 32 then
				self.poe_sessid = poesessid_controls.sessionInput.buf
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
	self:SetCurrencyConversionButton(controls)
	main:OpenPopup(pane_width, pane_height, "Build Pricer", controls)
end

function ItemsTabClass:SetCurrencyConversionButton(controls)
	local currencyLabel = colorCodes.WARNING .. "Update Currency Conversion Rates"
	self.pbFileTimestampDiff = nil
	local foo = io.open("../"..self.pbLeague.."_currency_values.json", "r")
	if foo then
		local lines = foo:read "*a"
		foo:close()
		self.pbCurrencyConversion[self.pbLeague] = self:ProcessJSON(lines)
		self.lastCurrencyFileTime = self.pbCurrencyConversion[self.pbLeague]["updateTime"]
		self.pbFileTimestampDiff = get_time() - self.lastCurrencyFileTime
		if self.pbFileTimestampDiff < 3600 then
			-- Less than 1 hour (60 * 60 = 3600)
			currencyLabel = "^8Currency Rates are Very Recent"
		elseif self.pbFileTimestampDiff < (24 * 3600) then
			-- Less than 1 day
			currencyLabel = "^7Currency Rates are Recent"
		end
	else
		currencyLabel = colorCodes.NEGATIVE .. "Get Currency Conversion Rates"
	end
	controls.updateCurrencyConversion.label = currencyLabel
	controls.updateCurrencyConversion.enabled = function()
		return self.pbFileTimestampDiff == nil or self.pbFileTimestampDiff >= 3600
	end
	controls.updateCurrencyConversion.tooltipFunc = function(tooltip)
		tooltip:Clear()
		if self.lastCurrencyFileTime ~= nil then
			self.pbFileTimestampDiff = get_time() - self.lastCurrencyFileTime
		end
		if self.pbFileTimestampDiff == nil or self.pbFileTimestampDiff >= 3600 then
			tooltip:AddLine(16, colorCodes.WARNING .. "Currency Conversion rates are pulled from PoE Ninja leveraging their API.")
			tooltip:AddLine(16, colorCodes.WARNING .. "Updates are limited to once per hour and not necessary more than once per day.")
			tooltip:AddLine(16, "")
			tooltip:AddLine(16, colorCodes.NEGATIVE .. "NOTE: This will expose your IP address to poe.ninja.")
			tooltip:AddLine(16, colorCodes.NEGATIVE .. "If you are concerned about this please do not click this button.")
		elseif self.pbFileTimestampDiff ~= nil and self.pbFileTimestampDiff < 3600 then
			tooltip:AddLine(16, "Conversion Rates are less than an hour old (" .. tostring(self.pbFileTimestampDiff) .. " seconds old)")
			tooltip:AddLine(16, "Button is DISABLED")
		end
	end
end

function ItemsTabClass:GenerateTotalPriceString(editPane)
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

function ItemsTabClass:PriceItemRowDisplay(controls, str_cnt, slotTbl, top_pane_alignment_ref, top_pane_alignment_width, top_pane_alignment_height, row_height)
	local activeItemRef = slotTbl.ref and self.activeItemSet["socketNodes"][slotTbl.ref] or self.activeItemSet[slotTbl.name]
	controls['name'..str_cnt] = new("LabelControl", top_pane_alignment_ref, top_pane_alignment_width, top_pane_alignment_height, 100, row_height-4, "^8"..slotTbl.name)
	controls['uri'..str_cnt] = new("EditControl", {"TOPLEFT",controls['name'..str_cnt],"TOPLEFT"}, 100 + 8, 0, 500, row_height, "Trade Site URL", nil, "^%C\t\n", nil, nil, 16)
	if activeItemRef and activeItemRef.pbURL ~= "" and activeItemRef.pbURL ~= nil then
		controls['uri'..str_cnt]:SetText(activeItemRef.pbURL)
	else
		controls['uri'..str_cnt]:SetText("<PASTE TRADE URL FOR>: " .. slotTbl.name)
	end
	controls['priceButton'..str_cnt] = new("ButtonControl", {"TOPLEFT",controls['uri'..str_cnt],"TOPLEFT"}, 500 + 8, 0, 100, row_height, "Price Item", function()
		self:PublicTrade(controls['uri'..str_cnt].buf, slotTbl, controls, str_cnt)
	end)
	controls['priceButton'..str_cnt].enabled = function()
		local validURL = controls['uri'..str_cnt].buf:find('^https://www.pathofexile.com/trade/search/') ~= nil
		if activeItemRef then
			if validURL then
				activeItemRef.pbURL = controls['uri'..str_cnt].buf
			elseif controls['uri'..str_cnt].buf == "" then
				activeItemRef.pbURL = ""
			end
		end
		return validURL and self:PriceBuilderCanSearch(controls) and self:PriceBuilderCanFetch(controls)
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
		self:CreateDisplayItemFromRaw(controls['importButtonText'..str_cnt].buf)
		local item = self.displayItem
		-- pass "true" to not auto equip it as we will have our own logic
		self:AddDisplayItem(true)
		-- Autoequip it
		local slot = slotTbl.ref and self.sockets[slotTbl.ref] or self.slots[slotTbl.name]
		if slot and slotTbl.name == slot.label and slot:IsShown() and self:IsItemValidForSlot(item, slot.slotName) then
			slot:SetSelItemId(item.id)
			self:PopulateSlots()
			self:AddUndoState()
			self.build.buildFlag = true
		end
	end)
	controls['importButton'..str_cnt].tooltipFunc = function(tooltip)
		tooltip:Clear()
		if #controls['importButtonText'..str_cnt].buf > 0 then
			local item = new("Item", controls['importButtonText'..str_cnt].buf)
			self:AddItemTooltip(tooltip, item, nil, true)
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
	-- Whisper store in clipboard (CTLR+C)
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

function ItemsTabClass:ProcessJSON(json)
	return dkjson.decode(json)
end

function ItemsTabClass:PriceBuilderPoENinjaCurrencyRequest()
	self.lastCurrencyConversionRequest = get_time()
end

function ItemsTabClass:PriceBuilderProcessPoENinjaResponse(resp, controls)
	if resp then
		-- Populate the chaos-converted values for each tradeId
		for currencyName, chaosEquivalent in pairs(resp) do
			if currencyConversionTradeMap[currencyName] then
				self.pbCurrencyConversion[self.pbLeague][currencyConversionTradeMap[currencyName]] = chaosEquivalent
			else
				ConPrintf("Unhandled Currency Name: '"..currencyName.."'")
			end
		end
	else
		self:SetNotice(controls.pbNotice, "PoE Ninja JSON Processing Error")
	end
end

function ItemsTabClass:PullPoENinjaCurrencyConversion(league, controls)
	-- Limit PoE Ninja Currency Conversion request to 1 per hour
	if (get_time() - self.lastCurrencyConversionRequest) > 3600 then
		self.pbCurrencyConversion[league] = { }
		local id = LaunchSubScript([[
			local curl = require("lcurl.safe")
			local page = ""
			local easy = curl.easy()
			easy:setopt{
				url = "https://poe.ninja/api/data/CurrencyRates?league=]]..league..[[",
				httpheader = {'Content-Type: application/json', 'Accept: application/json', 'User-Agent: Path of Building/]]..launch.versionNumber..[[ (contact: pob@mailbox.org)'}
			}
			easy:setopt_writefunction(function(data)
				page = page..data
				return true
			end)
			easy:perform()
			easy:close()
			return page
		]], "", "")
		if id then
			self:PriceBuilderPoENinjaCurrencyRequest()
			launch:RegisterSubScript(id, function(response, errMsg)
				if errMsg then
					self:SetNotice(controls.pbNotice, "ERROR: " .. tostring(errMsg))
					return "POE NINJA ERROR", "Error: "..errMsg
				else
					local json_data = self:ProcessJSON(response)
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
				end
			end)
		end
	else
		self:SetNotice(controls.pbNotice, "PoE Ninja Rate Limit Exceeded: " .. tostring(3600 - (get_time() - self.lastCurrencyConversionRequest)))
	end
end

function ItemsTabClass:CovertCurrencyToChaos(currency, amount)
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

function ItemsTabClass:SortFetchResults(slotTbl, trade_index)
	local newTbl = {}
	if self.pbSortSelectionIndex ~= 1 then
		local slot = slotTbl.ref and self.activeItemSet["socketNodes"][slotTbl.ref] or self.slots[slotTbl.name]
		local slotName = slotTbl.ref and "Jewel " .. tostring(slotTbl.ref) or slotTbl.name
		local storedGlobalCacheDPSView = GlobalCache.useFullDPS
		GlobalCache.useFullDPS = GlobalCache.numActiveSkillInFullDPS > 0
		local calcFunc, calcBase = self.build.calcsTab:GetMiscCalculator()
		for index, tbl in pairs(self.resultTbl[trade_index]) do
			local item = new("Item", tbl.item_string)
			local output = calcFunc({ repSlotName = slotName, repItem = item }, {})
			local newDPS = GlobalCache.useFullDPS and output.FullDPS or output.TotalDPS
			if self.pbSortSelectionIndex == 3 then
				local chaosAmount = self:CovertCurrencyToChaos(tbl.currency, tbl.amount)
				if chaosAmount > 0 then
					t_insert(newTbl, { outputAttr = newDPS / chaosAmount, index = index })
				end
			else
				if tbl.amount > 0 then
					t_insert(newTbl, { outputAttr = newDPS, index = index })
				end
			end
		end
		GlobalCache.useFullDPS = storedGlobalCacheDPSView
		table.sort(newTbl, function(a,b) return a.outputAttr > b.outputAttr end)
	else
		for index, tbl in pairs(self.resultTbl[trade_index]) do
			local chaosAmount = self:CovertCurrencyToChaos(tbl.currency, tbl.amount)
			if chaosAmount > 0 then
				t_insert(newTbl, { outputAttr = chaosAmount, index = index })
			end
		end
		table.sort(newTbl, function(a,b) return a.outputAttr < b.outputAttr end)
	end
	return newTbl
end

function ItemsTabClass:SetFetchResultReturn(controls, index, pb_index)
	if self.resultTbl[index] and self.resultTbl[index][pb_index] then
		local pb_index = self.sortedResultTbl[index][pb_index].index
		controls['importButtonText'..index]:SetText(self.resultTbl[index][pb_index].item_string)
		self.totalPrice[index] = {
			currency = self.resultTbl[index][pb_index].currency,
			amount = self.resultTbl[index][pb_index].amount,
		}
		controls['priceAmount'..index]:SetText(self.totalPrice[index].amount .. " " .. self.totalPrice[index].currency)
		controls['whisperButtonText'..index]:SetText(self.resultTbl[index][pb_index].whisper)
		self:GenerateTotalPriceString(controls.fullPrice)
	end
end

function ItemsTabClass:FetchItem(slotTbl, controls, response_1, index, quantity_found, current_fetch_block)
	local max_block_size = 10
	local res_lines = ""
	for response_index, res_line in ipairs(response_1.result) do
		if response_index > current_fetch_block and response_index <= m_min(current_fetch_block + max_block_size, quantity_found) then
			res_lines = res_lines .. res_line .. ","
		elseif response_index > m_min(current_fetch_block + max_block_size, quantity_found) then
			break
		end
	end
	res_lines = res_lines:sub(1, -2)
	local fetch_url = "https://www.pathofexile.com/api/trade/fetch/"..res_lines.."?query="..response_1.id
	local id2 = LaunchSubScript([[
		local fetch_url = ...
		local curl = require("lcurl.safe")
		local page = ""
		local easy = curl.easy()
		easy:setopt{
			url = fetch_url,
			httpheader = {'User-Agent: Path of Building/]]..launch.versionNumber..[[ (contact: pob@mailbox.org)'}
		}
		easy:setopt_writefunction(function(data)
			page = page..data
			return true
		end)
		easy:perform()
		easy:close()
		return page
	]], "", "", fetch_url)
	if id2 then
		self:PriceBuilderInsertFetchRequest()
		local ret_data = nil
		launch:RegisterSubScript(id2, function(response2, errMsg)
			if errMsg then
				self:SetNotice(controls.pbNotice, "ERROR: " .. tostring(errMsg))
			else
				local response_2, response_2_err = self:ProcessJSON(response2)
				if not response_2 or not response_2.result then
					if response_2_err then
						self:SetNotice(controls.pbNotice, "JSON Parse Error")
					else
						self:SetNotice(controls.pbNotice, "Failed to Get Trade Items")
					end
					return
				end
				for trade_indx, trade_entry in ipairs(response_2.result) do
					current_fetch_block = current_fetch_block + 1
					self.resultTbl[index][current_fetch_block] = {
						amount = trade_entry.listing.price.amount,
						currency = trade_entry.listing.price.currency,
						item_string = common.base64.decode(trade_entry.item.extended.text),
						whisper = trade_entry.listing.whisper,
					}
				end
				if current_fetch_block == quantity_found then
					self.sortedResultTbl[index] = self:SortFetchResults(slotTbl, index)
					local str_quantity_found = quantity_found == 100 and "100+" or tostring(#self.sortedResultTbl[index])
					controls['resultCount'..index]:SetText("out of " .. str_quantity_found)
					controls['resultIndex'..index]:SetText("1")
					local pb_index = self.sortedResultTbl[index][1].index
					controls['importButtonText'..index]:SetText(self.resultTbl[index][pb_index].item_string)
					self.totalPrice[index] = {
						currency = self.resultTbl[index][pb_index].currency,
						amount = self.resultTbl[index][pb_index].amount,
					}
					controls['priceAmount'..index]:SetText(self.totalPrice[index].amount .. " " .. self.totalPrice[index].currency)
					controls['whisperButtonText'..index]:SetText(self.resultTbl[index][pb_index].whisper)
					self:GenerateTotalPriceString(controls.fullPrice)
				else
					self:FetchItem(slotTbl, controls, response_1, index, quantity_found, current_fetch_block)
				end
			end
		end)
	else
		return
	end
end

function ItemsTabClass:SearchItem(league, json_data, slotTbl, controls, index)
	local id = LaunchSubScript([[
		local json_data = ...
		local curl = require("lcurl.safe")
		local page = ""
		local easy = curl.easy()
		easy:setopt{
			url = "https://www.pathofexile.com/api/trade/search/]]..league..[[",
			post = true,
			httpheader = {
				'Content-Type: application/json',
				'Accept: application/json',
				'User-Agent: Path of Building/]]..launch.versionNumber..[[ (contact: pob@mailbox.org)',
				'Cookie: POESESSID=]]..self.poe_sessid..[['
			},
			postfields = json_data
		}
		easy:setopt_writefunction(function(data)
			page = page..data
			return true
		end)
		easy:perform()
		easy:close()
		return page
	]], "", "", json_data)
	if id then
		self:PriceBuilderInsertSearchRequest()
		launch:RegisterSubScript(id, function(response, errMsg)
			if errMsg then
				self:SetNotice(controls.pbNotice, "ERROR: " .. tostring(errMsg))
				return "TRADE ERROR", "Error: "..errMsg
			else
				local response_1 = self:ProcessJSON(response)
				if not response_1 then
					self:SetNotice(controls.pbNotice, "Failed to Get Trade response")
					return
				end
				if not response_1.result or #response_1.result == 0 then
					if response_1.error then
						if response_1.error.code == 2 then
							self:SetNotice(controls.pbNotice, colorCodes.RELIC .. "Complex Query - Please provide your POESESSID")
						elseif response_1.error.message then
							self:SetNotice(controls.pbNotice, colorCodes.NEGATIVE .. response_1.error.message)
						end
					else
						self:SetNotice(controls.pbNotice, colorCodes.WARNING .. "No Matching Results Found")
					end
					return
				else
					self:SetNotice(controls.pbNotice, "")
				end
				local quantity_found = m_min(#response_1.result, 100)
				local current_fetch_block = 0
				self.resultTbl[index] = {}
				self:FetchItem(slotTbl, controls, response_1, index, quantity_found, current_fetch_block)
			end
		end)
	end
end

function ItemsTabClass:ParseURL(url)
	local league, query = url:match("https://www.pathofexile.com/trade/search/(.+)/(.+)$")
	return league, "https://www.pathofexile.com/api/trade/search/" .. query
end

function ItemsTabClass:PublicTrade(url, slotTbl, controls, index)
	local league, url = self:ParseURL(url)
	local id = LaunchSubScript([[
		local url = ...
		local curl = require("lcurl.safe")
		local page = ""
		local easy = curl.easy()
		easy:setopt{
			url = url,
			httpheader = {'User-Agent: Path of Building/]]..launch.versionNumber..[[ (contact: pob@mailbox.org)'}
		}
		easy:setopt_writefunction(function(data)
			page = page..data
			return true
		end)
		easy:perform()
		easy:close()
		return page
	]], "", "", url)
	if id then
		launch:RegisterSubScript(id, function(response, errMsg)
			if errMsg then
				self:SetNotice(controls.pbNotice, "Bad URL: " .. tostring(errMsg))
				return "TRADE ERROR", "Error: "..errMsg
			else
				self:PriceBuilderInsertSearchRequest()
				self:SearchItem(league, response, slotTbl, controls, index)
			end
		end)
	end
end

-- Opens the item crafting popup
function ItemsTabClass:CraftItem()
	local controls = { }
	local function makeItem(base)
		local item = new("Item")
		item.name = base.name
		item.base = base.base
		item.baseName = base.name
		item.buffModLines = { }
		item.enchantModLines = { }
		item.scourgeModLines = { }
		item.implicitModLines = { }
		item.explicitModLines = { }
		item.quality = 0
		local raritySel = controls.rarity.selIndex
		if base.base.flask then
			if raritySel == 3 then
				raritySel = 2
			end
		end
		if raritySel == 2 or raritySel == 3 then
			item.crafted = true
		end
		item.rarity = controls.rarity.list[raritySel].rarity
		if raritySel >= 3 then
			item.title = controls.title.buf:match("%S") and controls.title.buf or "New Item"
		end
		if base.base.implicit then
			local implicitIndex = 1
			for line in base.base.implicit:gmatch("[^\n]+") do
				local modList, extra = modLib.parseMod(line)
				t_insert(item.implicitModLines, { line = line, extra = extra, modList = modList or { }, modTags = base.base.implicitModTypes and base.base.implicitModTypes[implicitIndex] or { } })
				implicitIndex = implicitIndex + 1
			end
		end
		item:NormaliseQuality()
		item:BuildAndParseRaw()
		return item
	end
	controls.rarityLabel = new("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 50, 20, 0, 16, "Rarity:")
	controls.rarity = new("DropDownControl", nil, -80, 20, 100, 18, rarityDropList)
	controls.rarity.selIndex = self.lastCraftRaritySel or 3
	controls.title = new("EditControl", nil, 70, 20, 190, 18, "", "Name")
	controls.title.shown = function()
		return controls.rarity.selIndex >= 3
	end
	controls.typeLabel = new("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 50, 45, 0, 16, "Type:")
	controls.type = new("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 55, 45, 295, 18, self.build.data.itemBaseTypeList, function(index, value)
		controls.base.list = self.build.data.itemBaseLists[self.build.data.itemBaseTypeList[index]]
		controls.base.selIndex = 1
	end)
	controls.type.selIndex = self.lastCraftTypeSel or 1
	controls.baseLabel = new("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 50, 70, 0, 16, "Base:")
	controls.base = new("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 55, 70, 200, 18, self.build.data.itemBaseLists[self.build.data.itemBaseTypeList[controls.type.selIndex]])
	controls.base.selIndex = self.lastCraftBaseSel or 1
	controls.base.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if mode ~= "OUT" then
			self:AddItemTooltip(tooltip, makeItem(value), nil, true)
		end
	end
	controls.save = new("ButtonControl", nil, -45, 100, 80, 20, "Create", function()
		main:ClosePopup()
		local item = makeItem(controls.base.list[controls.base.selIndex])
		self:SetDisplayItem(item)
		if not item.crafted and item.rarity ~= "NORMAL" then
			self:EditDisplayItemText()
		end
		self.lastCraftRaritySel = controls.rarity.selIndex
		self.lastCraftTypeSel = controls.type.selIndex
		self.lastCraftBaseSel = controls.base.selIndex
	end)
	controls.cancel = new("ButtonControl", nil, 45, 100, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(370, 130, "Craft Item", controls)
end

-- Opens the item text editor popup
function ItemsTabClass:EditDisplayItemText(alsoAddItem)
	local controls = { }
	local function buildRaw()
		local editBuf = controls.edit.buf
		if editBuf:match("^Item Class: .*\nRarity: ") then
			return editBuf
		else
			return "Rarity: "..controls.rarity.list[controls.rarity.selIndex].rarity.."\n"..controls.edit.buf
		end
	end
	controls.rarity = new("DropDownControl", nil, -190, 10, 100, 18, rarityDropList)
	controls.edit = new("EditControl", nil, 0, 40, 480, 420, "", nil, "^%C\t\n", nil, nil, 14)
	if self.displayItem then
		controls.edit:SetText(self.displayItem:BuildRaw():gsub("Rarity: %w+\n",""))
		controls.rarity:SelByValue(self.displayItem.rarity, "rarity")
	else
		controls.rarity.selIndex = 3
	end
	controls.edit.font = "FIXED"
	controls.edit.pasteFilter = function(text)
		return text:gsub("\246","o")
	end
	controls.save = new("ButtonControl", nil, -45, 470, 80, 20, self.displayItem and "Save" or "Create", function()
		local id = self.displayItem and self.displayItem.id
		self:CreateDisplayItemFromRaw(buildRaw(), not self.displayItem)
		self.displayItem.id = id
		if alsoAddItem then
			self:AddDisplayItem()
		end
		main:ClosePopup()
	end)
	controls.save.enabled = function()
		local item = new("Item", buildRaw())
		return item.base ~= nil
	end
	controls.save.tooltipFunc = function(tooltip)
		tooltip:Clear()
		local item = new("Item", buildRaw())
		if item.base then
			self:AddItemTooltip(tooltip, item, nil, true)
		else
			tooltip:AddLine(14, "The item is invalid.")
			tooltip:AddLine(14, "Check that the item's title and base name are in the correct format.")
			tooltip:AddLine(14, "For Rare and Unique items, the first 2 lines must be the title and base name. E.g.:")
			tooltip:AddLine(14, "Abberath's Horn")
			tooltip:AddLine(14, "Goat's Horn")
			tooltip:AddLine(14, "For Normal and Magic items, the base name must be somewhere in the first line. E.g.:")
			tooltip:AddLine(14, "Scholar's Platinum Kris of Joy")
		end
	end	
	controls.cancel = new("ButtonControl", nil, 45, 470, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(500, 500, self.displayItem and "Edit Item Text" or "Create Custom Item from Text", controls, nil, "edit")
end

-- Opens the item enchanting popup
function ItemsTabClass:EnchantDisplayItem(enchantSlot)
	self.enchantSlot = enchantSlot or 1

	local controls = { } 
	local enchantments = self.displayItem.enchantments
	local haveSkills = true
	for _, source in ipairs(self.build.data.enchantmentSource) do
		if self.displayItem.enchantments[source.name] then
			haveSkills = false
			break
		end
	end
	local skillList = { }
	local skillsUsed = { }
	if haveSkills then
		for _, socketGroup in ipairs(self.build.skillsTab.socketGroupList) do
			for _, gemInstance in ipairs(socketGroup.gemList) do
				if gemInstance.gemData then 
					for _, grantedEffect in ipairs(gemInstance.gemData.grantedEffectList) do
						if not grantedEffect.support and enchantments[grantedEffect.name] then
							skillsUsed[grantedEffect.name] = true
						end
					end
				end
			end
		end
	end
	local function buildSkillList(onlyUsedSkills)
		wipeTable(skillList)
		for skillName in pairs(enchantments) do
			if not onlyUsedSkills or not next(skillsUsed) or skillsUsed[skillName] then
				t_insert(skillList, skillName)
			end
		end
		table.sort(skillList)
	end
	local enchantmentSourceList = { }
	local function buildEnchantmentSourceList()
		wipeTable(enchantmentSourceList)
		local list = haveSkills and enchantments[skillList[controls.skill and controls.skill.selIndex or 1]] or enchantments
		for _, source in ipairs(self.build.data.enchantmentSource) do
			if list[source.name] then
				t_insert(enchantmentSourceList, source)
			end
		end
	end
	local enchantmentList = { }
	local function buildEnchantmentList()
		wipeTable(enchantmentList)
		local list = haveSkills and enchantments[skillList[controls.skill and controls.skill.selIndex or 1]] or enchantments
		for _, enchantment in ipairs(list[enchantmentSourceList[controls.enchantmentSource and controls.enchantmentSource.selIndex or 1].name]) do
			t_insert(enchantmentList, enchantment)
		end
	end
	if haveSkills then
		buildSkillList(true)
	end
	buildEnchantmentSourceList()
	buildEnchantmentList()
	local function enchantItem()
		local item = new("Item", self.displayItem:BuildRaw())
		item.id = self.displayItem.id
		local list = haveSkills and enchantments[controls.skill.list[controls.skill.selIndex]] or enchantments
		local line = list[controls.enchantmentSource.list[controls.enchantmentSource.selIndex].name][controls.enchantment.selIndex]
		local first, second = line:match("([^/]+)/([^/]+)")
		if first then
			item.enchantModLines = { { crafted = true, line = first }, { crafted = true, line = second } }
		else
			if not item.canHaveTwoEnchants and #item.enchantModLines > 1 then
				item.enchantModLines = { item.enchantModLines[1] }
			end
			if #item.enchantModLines >= self.enchantSlot then
				t_remove(item.enchantModLines, self.enchantSlot)
			end
			t_insert(item.enchantModLines, self.enchantSlot, { crafted = true, line = line})
		end
		item:BuildAndParseRaw()
		return item
	end
	if haveSkills then
		controls.skillLabel = new("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 95, 20, 0, 16, "^7Skill:")
		controls.skill = new("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 100, 20, 180, 18, skillList, function(index, value)
			buildEnchantmentSourceList()
			buildEnchantmentList()
			controls.enchantment:SetSel(1)
		end)
		controls.allSkills = new("CheckBoxControl", {"TOPLEFT",nil,"TOPLEFT"}, 350, 20, 18, "All skills:", function(state)
			buildSkillList(not state)
			controls.skill:SetSel(1)
			buildEnchantmentList()
			controls.enchantment:SetSel(1)
		end)
		controls.allSkills.tooltipText = "Show all skills, not just those used by this build."
		if not next(skillsUsed) then
			controls.allSkills.state = true
			controls.allSkills.enabled = false
		end
	end
	controls.enchantmentSourceLabel = new("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 95, 45, 0, 16, "^7Source:")
	controls.enchantmentSource = new("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 100, 45, 180, 18, enchantmentSourceList, function(index, value)
		buildEnchantmentList()
		controls.enchantment:SetSel(m_min(controls.enchantment.selIndex, #enchantmentList))
	end)
	controls.enchantmentLabel = new("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 95, 70, 0, 16, "^7Enchantment:")
	controls.enchantment = new("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 100, 70, 440, 18, enchantmentList)
	controls.save = new("ButtonControl", nil, -45, 100, 80, 20, "Enchant", function()
		self:SetDisplayItem(enchantItem())
		main:ClosePopup()
	end)
	controls.save.tooltipFunc = function(tooltip)
		tooltip:Clear()
		self:AddItemTooltip(tooltip, enchantItem(), nil, true)
	end	
	controls.close = new("ButtonControl", nil, 45, 100, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(550, 130, "Enchant Item", controls)
end

---Gets the name of the anointed node on an item
---@param item table @The item to get the anoint from
---@return string @The name of the anointed node, or nil if there is no anoint
function ItemsTabClass:getAnoint(item)
	local result = { }
	if item then
		for _, modList in ipairs{item.enchantModLines, item.scourgeModLines, item.implicitModLines, item.explicitModLines} do
			for _, mod in ipairs(modList) do
				local line = mod.line
				local anoint = line:find("Allocates ([a-zA-Z ]+)")
				if anoint then
					local nodeName = line:sub(anoint + string.len("Allocates "))
					t_insert(result, nodeName)
				end
			end
		end
	end
	return result
end

---Returns a copy of the currently displayed item, but anointed with a new node.
---Removes any existing enchantments before anointing. (Anoints are considered enchantments)
---@param node table @The passive tree node to anoint, or nil to just remove existing anoints.
---@return table @The new item
function ItemsTabClass:anointItem(node)
	self.anointEnchantSlot = self.anointEnchantSlot or 1
	local item = new("Item", self.displayItem:BuildRaw())
	item.id = self.displayItem.id
	if #item.enchantModLines >= self.anointEnchantSlot then
		t_remove(item.enchantModLines, self.anointEnchantSlot)
	end
	if node then
		t_insert(item.enchantModLines, self.anointEnchantSlot, { crafted = true, line = "Allocates " .. node.dn })
	end
	item:BuildAndParseRaw()
	return item
end

---Appends tooltip information for anointing a new passive tree node onto the currently editing amulet
---@param tooltip table @The tooltip to append into
---@param node table @The passive tree node that will be anointed, or nil to remove the current anoint.
function ItemsTabClass:AppendAnointTooltip(tooltip, node, actionText)
	if not self.displayItem then
		return
	end

	if not actionText then
		actionText = "Anointing"
	end

	local header
	if node then
		if self.build.spec.allocNodes[node.id] then
			tooltip:AddLine(14, "^7"..actionText.." "..node.dn.." changes nothing because this node is already allocated on the tree.")
			return
		end

		local curAnoints = self:getAnoint(self.displayItem)
		if curAnoints and #curAnoints > 0 then
			for _, curAnoint in ipairs(curAnoints) do
				if curAnoint == node.dn then
					tooltip:AddLine(14, "^7"..actionText.." "..node.dn.." changes nothing because this node is already anointed.")
					return
				end
			end
		end

		header = "^7"..actionText.." "..node.dn.." will give you: "
	else
		header = "^7"..actionText.." nothing will give you: "
	end
	local calcFunc = self.build.calcsTab:GetMiscCalculator()
	local outputBase = calcFunc({ repSlotName = "Amulet", repItem = self.displayItem }, {})
	local outputNew = calcFunc({ repSlotName = "Amulet", repItem = self:anointItem(node) }, {})
	local numChanges = self.build:AddStatComparesToTooltip(tooltip, outputBase, outputNew, header)
	if node and numChanges == 0 then
		tooltip:AddLine(14, "^7"..actionText.." "..node.dn.." changes nothing.")
	end
end

-- Opens the item anointing popup
function ItemsTabClass:AnointDisplayItem(enchantSlot)
	self.anointEnchantSlot = enchantSlot or 1

	local controls = { } 
	controls.notableDB = new("NotableDBControl", {"TOPLEFT",nil,"TOPLEFT"}, 10, 60, 360, 360, self, self.build.spec.tree.nodes, "ANOINT")

	local function saveLabel()
		local node = controls.notableDB.selValue
		if node then
			return "Anoint " .. node.dn
		end
		local curAnoints = self:getAnoint(self.displayItem)
		if curAnoints and #curAnoints >= self.anointEnchantSlot then
			return "Remove "..curAnoints[self.anointEnchantSlot]
		end
		return "No Anoint"
	end
	local function saveLabelWidth()
		local label = saveLabel()
		return DrawStringWidth(16, "VAR", label) + 10
	end
	local function saveLabelX()
		local width = saveLabelWidth()
		return -(width + 90) / 2
	end
	controls.save = new("ButtonControl", {"BOTTOMLEFT", nil, "BOTTOM" }, saveLabelX, -4, saveLabelWidth, 20, saveLabel, function()
		self:SetDisplayItem(self:anointItem(controls.notableDB.selValue))
		main:ClosePopup()
	end)
	controls.save.tooltipFunc = function(tooltip)
		tooltip:Clear()
		self:AppendAnointTooltip(tooltip, controls.notableDB.selValue)
	end	
	controls.close = new("ButtonControl", {"TOPLEFT", controls.save, "TOPRIGHT" }, 10, 0, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(380, 448, "Anoint Item", controls)
end

-- Opens the item corrupting popup
function ItemsTabClass:CorruptDisplayItem(modType)
	local controls = { } 
	local implicitList = { }
	for modId, mod in pairs(self.displayItem.affixes) do
		if mod.type == modType and self.displayItem:GetModSpawnWeight(mod) > 0 then
			t_insert(implicitList, mod)
		end
	end
	table.sort(implicitList, function(a, b)
		local an = a[1]:lower():gsub("%(.-%)","$"):gsub("[%+%-%%]",""):gsub("%d+","$")
		local bn = b[1]:lower():gsub("%(.-%)","$"):gsub("[%+%-%%]",""):gsub("%d+","$")
		if an ~= bn then
			return an < bn
		else
			return a.level < b.level
		end
	end)
	local function buildList(control, other)
		local selfMod = control.selIndex and control.selIndex > 1 and control.list[control.selIndex].mod
		local otherMod = other.selIndex and other.selIndex > 1 and other.list[other.selIndex].mod
		wipeTable(control.list)
		t_insert(control.list, { label = "None" })
		for _, mod in ipairs(implicitList) do
			if not otherMod or mod.group ~= otherMod.group then
				t_insert(control.list, { label = table.concat(mod, "/"), mod = mod })
			end
		end
		control:SelByValue(selfMod, "mod")
	end
	local function corruptItem()
		local item = new("Item", self.displayItem:BuildRaw())
		item.id = self.displayItem.id
		item.corrupted = true
		local newImplicit = { }
		for _, control in ipairs{controls.implicit, controls.implicit2} do
			if control.selIndex > 1 then
				local mod = control.list[control.selIndex].mod
				for _, modLine in ipairs(mod) do
					modLine = (modType == "Scourge" and "{scourge}" or "") .. modLine
					if mod.modTags[1] then
						t_insert(newImplicit, { line = "{tags:" .. table.concat(mod.modTags, ",") .. "}" .. modLine })
					else
						t_insert(newImplicit, { line = modLine })
					end
				end
			end
		end
		if #newImplicit > 0 then
			wipeTable(modType == "Corrupted" and item.implicitModLines or item.scourgeModLines)
			for i, implicit in ipairs(newImplicit) do
				t_insert(modType == "Corrupted" and item.implicitModLines or item.scourgeModLines, i, implicit)
			end
		end
		item:BuildAndParseRaw()
		return item
	end
	controls.implicitLabel = new("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 75, 20, 0, 16, "^7Implicit #1:")
	controls.implicit = new("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 80, 20, 440, 18, nil, function()
		buildList(controls.implicit2, controls.implicit)
	end)
	controls.implicit2Label = new("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 75, 40, 0, 16, "^7Implicit #2:")
	controls.implicit2 = new("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 80, 40, 440, 18, nil, function()
		buildList(controls.implicit, controls.implicit2)
	end)
	buildList(controls.implicit, controls.implicit2)
	buildList(controls.implicit2, controls.implicit)
	controls.save = new("ButtonControl", nil, -45, 70, 80, 20, modType, function()
		self:SetDisplayItem(corruptItem())
		main:ClosePopup()
	end)
	controls.save.tooltipFunc = function(tooltip)
		tooltip:Clear()
		self:AddItemTooltip(tooltip, corruptItem(), nil, true)
	end	
	controls.close = new("ButtonControl", nil, 45, 70, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(540, 100, modType .. " Item", controls)
end

-- Opens the custom modifier popup
function ItemsTabClass:AddCustomModifierToDisplayItem()
	local controls = { }
	local sourceList = { }
	local modList = { }
	---Mutates modList to contain mods from the specified source
	---@param sourceId string @The crafting source id to build the list of mods for
	local function buildMods(sourceId)
		wipeTable(modList)
		if sourceId == "MASTER" then
			local excludeGroups = { }
			for _, modLine in ipairs({ self.displayItem.prefixes, self.displayItem.suffixes }) do
				for i = 1, self.displayItem.affixLimit / 2 do
					if modLine[i].modId ~= "None" then
						excludeGroups[self.displayItem.affixes[modLine[i].modId].group] = true
					end
				end
			end
			for i, craft in ipairs(self.build.data.masterMods) do
				if craft.types[self.displayItem.type] and not excludeGroups[craft.group] then
					t_insert(modList, {
						label = table.concat(craft, "/") .. " ^8(" .. craft.type .. ")",
						mod = craft,
						type = "crafted",
						affixType = craft.type,
						defaultOrder = i,
					})
				end
			end
			table.sort(modList, function(a, b)
				if a.affixType ~= b.affixType then
					return a.affixType == "Prefix" and b.affixType == "Suffix"
				else
					return a.defaultOrder < b.defaultOrder
				end
			end)
		elseif sourceId == "ESSENCE" then
			for _, essence in pairs(self.build.data.essences) do
				local modId = essence.mods[self.displayItem.type]
				local mod = self.displayItem.affixes[modId]
				t_insert(modList, {
					label = essence.name .. "   " .. "^8[" .. table.concat(mod, "/") .. "]" .. " (" .. mod.type .. ")",
					mod = mod,
					type = "custom",
					essence = essence,
				})
			end
			table.sort(modList, function(a, b)
				if a.essence.type ~= b.essence.type then
					return a.essence.type > b.essence.type 
				else
					return a.essence.tier > b.essence.tier
				end
			end)
		elseif sourceId == "PREFIX" or sourceId == "SUFFIX" then
			for _, mod in pairs(self.displayItem.affixes) do
				if sourceId:lower() == mod.type:lower() and self.displayItem:GetModSpawnWeight(mod) > 0 then
					t_insert(modList, {
						label = mod.affix .. "   ^8[" .. table.concat(mod, "/") .. "]",
						mod = mod,
						type = "custom",
					})
				end
			end
			table.sort(modList, function(a, b) 
				local modA = a.mod
				local modB = b.mod
				for i = 1, m_max(#modA, #modB) do
					if not modA[i] then
						return true
					elseif not modB[i] then
						return false
					elseif modA.statOrder[i] ~= modB.statOrder[i] then
						return modA.statOrder[i] < modB.statOrder[i]
					end
				end
				return modA.level > modB.level
			end)
		elseif sourceId == "VEILED" then
			for i, mod in pairs(self.build.data.veiledMods) do
				if self.displayItem:GetModSpawnWeight(mod) > 0 then
					t_insert(modList, {
						label =  table.concat(mod, "/") .. " (" .. mod.type .. ")",
						mod = mod,
						affixType = mod.type,
						type = "custom",
						defaultOrder = i,
					})
				end
			end
			table.sort(modList, function(a, b)
				if a.affixType ~= b.affixType then
					return a.affixType == "Prefix" and b.affixType == "Suffix"
				else
					return a.defaultOrder < b.defaultOrder
				end
			end)
		elseif sourceId == "DELVE" then
			for i, mod in pairs(self.displayItem.affixes) do
				if self.displayItem:CheckIfModIsDelve(mod) and self.displayItem:GetModSpawnWeight(mod) > 0 then
					t_insert(modList, {
						label =  table.concat(mod, "/") .. " (" .. mod.type .. ")",
						mod = mod,
						affixType = mod.type,
						type = "custom",
						defaultOrder = i,
					})
				end
			end
			table.sort(modList, function(a, b)
				if a.affixType ~= b.affixType then
					return a.affixType == "Prefix" and b.affixType == "Suffix"
				else
					return a.defaultOrder < b.defaultOrder
				end
			end)
		end
	end
	if self.displayItem.type ~= "Jewel" then
		t_insert(sourceList, { label = "Crafting Bench", sourceId = "MASTER" })
	end
	if self.displayItem.type ~= "Jewel" and self.displayItem.type ~= "Flask" then
		t_insert(sourceList, { label = "Essence", sourceId = "ESSENCE" })
	end
	if self.displayItem.type ~= "Jewel" and self.displayItem.type ~= "Flask" then
		t_insert(sourceList, { label = "Veiled", sourceId = "VEILED"})
	end
	if self.displayItem.type ~= "Flask" then
		t_insert(sourceList, { label = "Delve", sourceId = "DELVE"})
	end
	if not self.displayItem.crafted then
		t_insert(sourceList, { label = "Prefix", sourceId = "PREFIX" })
		t_insert(sourceList, { label = "Suffix", sourceId = "SUFFIX" })
	end
	t_insert(sourceList, { label = "Custom", sourceId = "CUSTOM" })
	buildMods(sourceList[1].sourceId)
	local function addModifier()
		local item = new("Item", self.displayItem:BuildRaw())
		item.id = self.displayItem.id
		local sourceId = sourceList[controls.source.selIndex].sourceId
		if sourceId == "CUSTOM" then
			if controls.custom.buf:match("%S") then
				t_insert(item.explicitModLines, { line = controls.custom.buf, custom = true })
			end
		else
			local listMod = modList[controls.modSelect.selIndex]
			for _, line in ipairs(listMod.mod) do
				t_insert(item.explicitModLines, { line = line, modTags = listMod.mod.modTags, [listMod.type] = true })
			end
		end
		item:BuildAndParseRaw()
		return item
	end
	controls.sourceLabel = new("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 95, 20, 0, 16, "^7Source:")
	controls.source = new("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 100, 20, 150, 18, sourceList, function(index, value)
		buildMods(value.sourceId)
		controls.modSelect:SetSel(1)
	end)
	controls.source.enabled = #sourceList > 1
	controls.modSelectLabel = new("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 95, 45, 0, 16, "^7Modifier:")
	controls.modSelect = new("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 100, 45, 600, 18, modList)
	controls.modSelect.shown = function()
		return sourceList[controls.source.selIndex].sourceId ~= "CUSTOM"
	end
	controls.modSelect.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if mode ~= "OUT" and value then
			for _, line in ipairs(value.mod) do
				tooltip:AddLine(16, "^7"..line)
			end
		end
	end
	controls.custom = new("EditControl", {"TOPLEFT",nil,"TOPLEFT"}, 100, 45, 440, 18)
	controls.custom.shown = function()
		return sourceList[controls.source.selIndex].sourceId == "CUSTOM"
	end
	controls.save = new("ButtonControl", nil, -45, 75, 80, 20, "Add", function()
		self:SetDisplayItem(addModifier())
		main:ClosePopup()
	end)
	controls.save.tooltipFunc = function(tooltip)
		tooltip:Clear()
		self:AddItemTooltip(tooltip, addModifier())
	end	
	controls.close = new("ButtonControl", nil, 45, 75, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(710, 105, "Add Modifier to Item", controls, "save", sourceList[controls.source.selIndex].sourceId == "CUSTOM" and "custom")	
end

function ItemsTabClass:AddItemSetTooltip(tooltip, itemSet)
	for _, slot in ipairs(self.orderedSlots) do
		if not slot.nodeId then
			local item = self.items[itemSet[slot.slotName].selItemId]
			if item then
				tooltip:AddLine(16, s_format("^7%s: %s%s", slot.label, colorCodes[item.rarity], item.name))
			end
		end
	end
end

function ItemsTabClass:FormatItemSource(text)
	return text:gsub("unique{([^}]+)}",colorCodes.UNIQUE.."%1"..colorCodes.SOURCE)
			   :gsub("normal{([^}]+)}",colorCodes.NORMAL.."%1"..colorCodes.SOURCE)
			   :gsub("currency{([^}]+)}",colorCodes.CURRENCY.."%1"..colorCodes.SOURCE)
			   :gsub("prophecy{([^}]+)}",colorCodes.PROPHECY.."%1"..colorCodes.SOURCE)
end

function ItemsTabClass:AddItemTooltip(tooltip, item, slot, dbMode)
	-- Item name
	local rarityCode = colorCodes[item.rarity]
	tooltip.center = true
	tooltip.color = rarityCode
	if item.title then
		tooltip:AddLine(20, rarityCode..item.title)
		tooltip:AddLine(20, rarityCode..item.baseName:gsub(" %(.+%)",""))
	else
		tooltip:AddLine(20, rarityCode..item.namePrefix..item.baseName:gsub(" %(.+%)","")..item.nameSuffix)
	end
	for _, curInfluenceInfo in ipairs(influenceInfo) do
		if item[curInfluenceInfo.key] then
			tooltip:AddLine(16, curInfluenceInfo.color..curInfluenceInfo.display.." Item")
		end
	end
	if item.fractured then
		tooltip:AddLine(16, colorCodes.FRACTURED.."Fractured Item")
	end
	if item.synthesised then
		tooltip:AddLine(16, colorCodes.CRAFTED.."Synthesised Item")
	end
	tooltip:AddSeparator(10)

	-- Special fields for database items
	if dbMode then
		if item.variantList then
			if #item.variantList == 1 then
				tooltip:AddLine(16, "^xFFFF30Variant: "..item.variantList[1])
			else
				tooltip:AddLine(16, "^xFFFF30Variant: "..item.variantList[item.variant].." ("..#item.variantList.." variants)")
			end
		end
		if item.league then
			tooltip:AddLine(16, "^xFF5555Exclusive to: "..item.league)
		end
		if item.unreleased then
			tooltip:AddLine(16, "^1Not yet available")
		end
		if item.source then
			tooltip:AddLine(16, colorCodes.SOURCE.."Source: "..self:FormatItemSource(item.source))
		end
		if item.upgradePaths then
			for _, path in ipairs(item.upgradePaths) do
				tooltip:AddLine(16, colorCodes.SOURCE..self:FormatItemSource(path))
			end
		end
		tooltip:AddSeparator(10)
	end

	local base = item.base
	local slotNum = slot and slot.slotNum or (IsKeyDown("SHIFT") and 2 or 1)
	local modList = item.modList or item.slotModList[slotNum]
	if base.weapon then
		-- Weapon-specific info
		local weaponData = item.weaponData[slotNum]
		tooltip:AddLine(16, s_format("^x7F7F7F%s", self.build.data.weaponTypeInfo[base.type].label or base.type))
		if item.quality > 0 then
			tooltip:AddLine(16, s_format("^x7F7F7FQuality: "..colorCodes.MAGIC.."+%d%%", item.quality))
		end
		local totalDamageTypes = 0
		if weaponData.PhysicalDPS then
			tooltip:AddLine(16, s_format("^x7F7F7FPhysical Damage: "..colorCodes.MAGIC.."%d-%d (%.1f DPS)", weaponData.PhysicalMin, weaponData.PhysicalMax, weaponData.PhysicalDPS))
			totalDamageTypes = totalDamageTypes + 1
		end
		if weaponData.ElementalDPS then
			local elemLine
			for _, var in ipairs({"Fire","Cold","Lightning"}) do
				if weaponData[var.."DPS"] then
					elemLine = elemLine and elemLine.."^x7F7F7F, " or "^x7F7F7FElemental Damage: "
					elemLine = elemLine..s_format("%s%d-%d", colorCodes[var:upper()], weaponData[var.."Min"], weaponData[var.."Max"])
				end
			end
			tooltip:AddLine(16, elemLine)
			tooltip:AddLine(16, s_format("^x7F7F7FElemental DPS: "..colorCodes.MAGIC.."%.1f", weaponData.ElementalDPS))
			totalDamageTypes = totalDamageTypes + 1	
		end
		if weaponData.ChaosDPS then
			tooltip:AddLine(16, s_format("^x7F7F7FChaos Damage: "..colorCodes.CHAOS.."%d-%d "..colorCodes.MAGIC.."(%.1f DPS)", weaponData.ChaosMin, weaponData.ChaosMax, weaponData.ChaosDPS))
			totalDamageTypes = totalDamageTypes + 1
		end
		if totalDamageTypes > 1 then
			tooltip:AddLine(16, s_format("^x7F7F7FTotal DPS: "..colorCodes.MAGIC.."%.1f", weaponData.TotalDPS))
		end
		tooltip:AddLine(16, s_format("^x7F7F7FCritical Strike Chance: %s%.2f%%", main:StatColor(weaponData.CritChance, base.weapon.CritChanceBase), weaponData.CritChance))
		tooltip:AddLine(16, s_format("^x7F7F7FAttacks per Second: %s%.2f", main:StatColor(weaponData.AttackRate, base.weapon.AttackRateBase), weaponData.AttackRate))
		if weaponData.range < 120 then
			tooltip:AddLine(16, s_format("^x7F7F7FWeapon Range: %s%d", main:StatColor(weaponData.range, base.weapon.Range), weaponData.range))
		end
	elseif base.armour then
		-- Armour-specific info
		local armourData = item.armourData
		if item.quality > 0 then
			tooltip:AddLine(16, s_format("^x7F7F7FQuality: "..colorCodes.MAGIC.."+%d%%", item.quality))
		end
		if base.armour.BlockChance and armourData.BlockChance > 0 then
			tooltip:AddLine(16, s_format("^x7F7F7FChance to Block: %s%d%%", main:StatColor(armourData.BlockChance, base.armour.BlockChance), armourData.BlockChance))
		end
		if armourData.Armour > 0 then
			tooltip:AddLine(16, s_format("^x7F7F7FArmour: %s%d", main:StatColor(armourData.Armour, base.armour.ArmourBase), armourData.Armour))
		end
		if armourData.Evasion > 0 then
			tooltip:AddLine(16, s_format("^x7F7F7FEvasion Rating: %s%d", main:StatColor(armourData.Evasion, base.armour.EvasionBase), armourData.Evasion))
		end
		if armourData.EnergyShield > 0 then
			tooltip:AddLine(16, s_format("^x7F7F7FEnergy Shield: %s%d", main:StatColor(armourData.EnergyShield, base.armour.EnergyShieldBase), armourData.EnergyShield))
		end
		if armourData.Ward > 0 then
			tooltip:AddLine(16, s_format("^x7F7F7FWard: %s%d", main:StatColor(armourData.Ward, base.armour.WardBase), armourData.Ward))
		end
	elseif base.flask then
		-- Flask-specific info
		local flaskData = item.flaskData
		if item.quality > 0 then
			tooltip:AddLine(16, s_format("^x7F7F7FQuality: "..colorCodes.MAGIC.."+%d%%", item.quality))
		end
		if flaskData.lifeTotal then
			if flaskData.lifeGradual ~= 0 then
				tooltip:AddLine(16, s_format("^x7F7F7FRecovers %s%d ^x7F7F7FLife over %s%.1f0 ^x7F7F7FSeconds",
					main:StatColor(flaskData.lifeTotal, base.flask.life), flaskData.lifeGradual,
					main:StatColor(flaskData.duration, base.flask.duration), flaskData.duration
					))
			end
			if flaskData.lifeInstant ~= 0 then
				tooltip:AddLine(16, s_format("^x7F7F7FRecovers %s%d ^x7F7F7FLife instantly", main:StatColor(flaskData.lifeTotal, base.flask.life), flaskData.lifeInstant))
			end
		end
		if flaskData.manaTotal then
			if flaskData.manaGradual then
				tooltip:AddLine(16, s_format("^x7F7F7FRecovers %s%d ^x7F7F7FMana over %s%.1f0 ^x7F7F7FSeconds",
					main:StatColor(flaskData.manaTotal, base.flask.mana), flaskData.manaGradual,
					main:StatColor(flaskData.duration, base.flask.duration), flaskData.duration
					))
			end
			if flaskData.manaInstant then
				tooltip:AddLine(16, s_format("^x7F7F7FRecovers %s%d ^x7F7F7FMana instantly", main:StatColor(flaskData.manaTotal, base.flask.mana), flaskData.manaInstant))
			end
		end
		if not flaskData.lifeTotal and not flaskData.manaTotal then
			tooltip:AddLine(16, s_format("^x7F7F7FLasts %s%.2f ^x7F7F7FSeconds", main:StatColor(flaskData.duration, base.flask.duration), flaskData.duration))
		end
		tooltip:AddLine(16, s_format("^x7F7F7FConsumes %s%d ^x7F7F7Fof %s%d ^x7F7F7FCharges on use",
			main:StatColor(flaskData.chargesUsed, base.flask.chargesUsed), flaskData.chargesUsed,
			main:StatColor(flaskData.chargesMax, base.flask.chargesMax), flaskData.chargesMax
		))
		for _, modLine in pairs(item.buffModLines) do
			tooltip:AddLine(16, (modLine.extra and colorCodes.UNSUPPORTED or colorCodes.MAGIC) .. modLine.line)
		end
	elseif item.type == "Jewel" then
		-- Jewel-specific info
		if item.limit then
			tooltip:AddLine(16, "^x7F7F7FLimited to: ^7"..item.limit)
		end
		if item.jewelRadiusLabel then
			tooltip:AddLine(16, "^x7F7F7FRadius: ^7"..item.jewelRadiusLabel)
		end
		if item.jewelRadiusData and slot and item.jewelRadiusData[slot.nodeId] then
			local radiusData = item.jewelRadiusData[slot.nodeId]
			local line
			local codes = { colorCodes.STRENGTH, colorCodes.DEXTERITY, colorCodes.INTELLIGENCE }
			for i, stat in ipairs({"Str","Dex","Int"}) do
				if radiusData[stat] and radiusData[stat] ~= 0 then
					line = (line and line .. ", " or "") .. s_format("%s%d %s^7", codes[i], radiusData[stat], stat)
				end
			end
			if line then
				tooltip:AddLine(16, "^x7F7F7FAttributes in Radius: "..line)
			end
		end
	end
	
	if item.catalyst and item.catalyst > 0 and item.catalyst <= #catalystQualityFormat and item.catalystQuality and item.catalystQuality > 0 then
		tooltip:AddLine(16, s_format(catalystQualityFormat[item.catalyst], item.catalystQuality))
		tooltip:AddSeparator(10)
	end

	if #item.sockets > 0 then
		-- Sockets/links
		local group = 0
		local line = ""
		for i, socket in ipairs(item.sockets) do
			if i > 1 then
				if socket.group == group then
					line = line .. "^7="
				else
					line = line .. "  "
				end
				group = socket.group
			end
			local code
			if socket.color == "R" then
				code = colorCodes.STRENGTH
			elseif socket.color == "G" then
				code = colorCodes.DEXTERITY
			elseif socket.color == "B" then
				code = colorCodes.INTELLIGENCE
			elseif socket.color == "W" then
				code = colorCodes.SCION
			elseif socket.color == "A" then
				code = "^xB0B0B0"
			end
			line = line .. code .. socket.color
		end
		tooltip:AddLine(16, "^x7F7F7FSockets: "..line)
	end
	tooltip:AddSeparator(10)

	if item.talismanTier then
		tooltip:AddLine(16, "^x7F7F7FTalisman Tier ^xFFFFFF"..item.talismanTier)
		tooltip:AddSeparator(10)
	end

	-- Requirements
	self.build:AddRequirementsToTooltip(tooltip, item.requirements.level, 
		item.requirements.strMod, item.requirements.dexMod, item.requirements.intMod, 
		item.requirements.str or 0, item.requirements.dex or 0, item.requirements.int or 0)

	-- Modifiers
	for _, modList in ipairs{item.enchantModLines, item.scourgeModLines, item.implicitModLines, item.explicitModLines} do
		if modList[1] then
			for _, modLine in ipairs(modList) do
				if item:CheckModLineVariant(modLine) then
					tooltip:AddLine(16, itemLib.formatModLine(modLine, dbMode))
				end
			end
			tooltip:AddSeparator(10)
		end
	end

	-- Cluster jewel notables/keystone
	if item.clusterJewel then
		tooltip:AddSeparator(10)
		if #item.jewelData.clusterJewelNotables > 0 then
			for _, name in ipairs(item.jewelData.clusterJewelNotables) do
				local node = self.build.spec.tree.clusterNodeMap[name]
				if node then
					tooltip:AddLine(16, colorCodes.MAGIC .. node.dn)
					for _, stat in ipairs(node.sd) do
						tooltip:AddLine(16, "^x7F7F7F"..stat)
					end
				end
			end
		elseif item.jewelData.clusterJewelKeystone then
			local node = self.build.spec.tree.clusterNodeMap[item.jewelData.clusterJewelKeystone]
			if node then
				tooltip:AddLine(16, colorCodes.MAGIC .. node.dn)
				for _, stat in ipairs(node.sd) do
					tooltip:AddLine(16, "^x7F7F7F"..stat)
				end
			end
		end
		tooltip:AddSeparator(10)
	end

	-- Corrupted item label
	if item.corrupted then
		if #item.explicitModLines == 0 then
			tooltip:AddSeparator(10)
		end
		tooltip:AddLine(16, "^1Corrupted")
	end
	tooltip:AddSeparator(14)

	-- Stat differences
	local calcFunc, calcBase = self.build.calcsTab:GetMiscCalculator()
	if base.flask then
		-- Special handling for flasks
		local stats = { }
		local flaskData = item.flaskData
		local modDB = self.build.calcsTab.mainEnv.modDB
		local output = self.build.calcsTab.mainOutput
		local durInc = modDB:Sum("INC", nil, "FlaskDuration")
		local effectInc = modDB:Sum("INC", nil, "FlaskEffect")
		if item.base.flask.life or item.base.flask.mana then
			local rateInc = modDB:Sum("INC", nil, "FlaskRecoveryRate")
			local instantPerc = flaskData.instantPerc
			if item.base.flask.life then
				local lifeInc = modDB:Sum("INC", nil, "FlaskLifeRecovery")
				local lifeRateInc = modDB:Sum("INC", nil, "FlaskLifeRecoveryRate")
				local inst = flaskData.lifeBase * instantPerc / 100 * (1 + lifeInc / 100) * (1 + effectInc / 100)
				local grad = flaskData.lifeBase * (1 - instantPerc / 100) * (1 + lifeInc / 100) * (1 + effectInc / 100) * (1 + durInc / 100) * output.LifeRecoveryRateMod
				local lifeDur = flaskData.duration * (1 + durInc / 100) / (1 + rateInc / 100) / (1 + lifeRateInc / 100)
				if inst > 0 and grad > 0 then
					t_insert(stats, s_format("^8Life recovered: ^7%d ^8(^7%d^8 instantly, plus ^7%d ^8over^7 %.2fs^8)", inst + grad, inst, grad, lifeDur))
				elseif inst + grad ~= flaskData.lifeTotal or (inst == 0 and lifeDur ~= flaskData.duration) then
					if inst > 0 then
						t_insert(stats, s_format("^8Life recovered: ^7%d ^8instantly", inst))
					elseif grad > 0 then
						t_insert(stats, s_format("^8Life recovered: ^7%d ^8over ^7%.2fs", grad, lifeDur))
					end
				end
				if modDB:Flag(nil, "LifeFlaskAppliesToEnergyShield") then
					if inst > 0 and grad > 0 then
						t_insert(stats, s_format("^8Energy Shield recovered: ^7%d ^8(^7%d^8 instantly, plus ^7%d ^8over^7 %.2fs^8)", inst + grad, inst, grad, lifeDur))
					elseif inst > 0 and grad == 0 then
						t_insert(stats, s_format("^8Energy Shield recovered: ^7%d ^8instantly", inst))
					elseif inst == 0 and grad > 0 then
						t_insert(stats, s_format("^8Energy Shield recovered: ^7%d ^8over ^7%.2fs", grad, lifeDur))
					end
				end
			end
			if item.base.flask.mana then
				local manaInc = modDB:Sum("INC", nil, "FlaskManaRecovery")
				local manaRateInc = modDB:Sum("INC", nil, "FlaskManaRecoveryRate")
				local inst = flaskData.manaBase * instantPerc / 100 * (1 + manaInc / 100) * (1 + effectInc / 100)
				local grad = flaskData.manaBase * (1 - instantPerc / 100) * (1 + manaInc / 100) * (1 + effectInc / 100) * (1 + durInc / 100) * output.ManaRecoveryRateMod
				local manaDur = flaskData.duration * (1 + durInc / 100) / (1 + rateInc / 100) / (1 + manaRateInc / 100)
				if inst > 0 and grad > 0 then
					t_insert(stats, s_format("^8Mana recovered: ^7%d ^8(^7%d^8 instantly, plus ^7%d ^8over^7 %.2fs^8)", inst + grad, inst, grad, manaDur))
				elseif inst + grad ~= flaskData.manaTotal or (inst == 0 and manaDur ~= flaskData.duration) then
					if inst > 0 then
						t_insert(stats, s_format("^8Mana recovered: ^7%d ^8instantly", inst))
					elseif grad > 0 then
						t_insert(stats, s_format("^8Mana recovered: ^7%d ^8over ^7%.2fs", grad, manaDur))
					end
				end
			end
		else
			if durInc ~= 0 then
				t_insert(stats, s_format("^8Flask effect duration: ^7%.1f0s", flaskData.duration * (1 + durInc / 100)))
			end
		end
		local effectMod = 1 + (flaskData.effectInc + effectInc) / 100
		if effectMod ~= 1 then
			t_insert(stats, s_format("^8Flask effect modifier: ^7%+d%%", effectMod * 100 - 100))
		end
		local usedInc = modDB:Sum("INC", nil, "FlaskChargesUsed")
		if usedInc ~= 0 then
			local used = m_floor(flaskData.chargesUsed * (1 + usedInc / 100))
			t_insert(stats, s_format("^8Charges used: ^7%d ^8of ^7%d ^8(^7%d ^8uses)", used, flaskData.chargesMax, m_floor(flaskData.chargesMax / used)))
		end
		local gainMod = flaskData.gainMod * (1 + modDB:Sum("INC", nil, "FlaskChargesGained") / 100)
		if gainMod ~= 1 then
			t_insert(stats, s_format("^8Charge gain modifier: ^7%+d%%", gainMod * 100 - 100))
		end
		if stats[1] then
			tooltip:AddLine(14, "^7Effective flask stats:")
			for _, stat in ipairs(stats) do
				tooltip:AddLine(14, stat)
			end
		end
		local storedGlobalCacheDPSView = GlobalCache.useFullDPS
		GlobalCache.useFullDPS = GlobalCache.numActiveSkillInFullDPS > 0
		local output = calcFunc({ toggleFlask = item }, {})
		GlobalCache.useFullDPS = storedGlobalCacheDPSView
		local header
		if self.build.calcsTab.mainEnv.flasks[item] then
			header = "^7Deactivating this flask will give you:"
		else
			header = "^7Activating this flask will give you:"
		end
		self.build:AddStatComparesToTooltip(tooltip, calcBase, output, header)
	else
		self:UpdateSockets()
		-- Build sorted list of slots to compare with
		local compareSlots = { }
		for slotName, slot in pairs(self.slots) do
			if self:IsItemValidForSlot(item, slotName) and not slot.inactive and (not slot.weaponSet or slot.weaponSet == (self.activeItemSet.useSecondWeaponSet and 2 or 1)) then
				t_insert(compareSlots, slot)
			end
		end
		table.sort(compareSlots, function(a, b)
			if a.selItemId ~= b.selItemId then
				if item == self.items[a.selItemId] then
					return true
				elseif item == self.items[b.selItemId] then
					return false
				end
			end
			local aNum = tonumber(a.slotName:match("%d+"))
			local bNum = tonumber(b.slotName:match("%d+"))
			if aNum and bNum then
				return aNum < bNum
			else
				return a.slotName < b.slotName
			end
		end)

		-- Add comparisons for each slot
		for _, slot in pairs(compareSlots) do
			local selItem = self.items[slot.selItemId]
			local storedGlobalCacheDPSView = GlobalCache.useFullDPS
			GlobalCache.useFullDPS = GlobalCache.numActiveSkillInFullDPS > 0
			local output = calcFunc({ repSlotName = slot.slotName, repItem = item ~= selItem and item }, {})
			GlobalCache.useFullDPS = storedGlobalCacheDPSView
			local header
			if item == selItem then
				header = "^7Removing this item from "..slot.label.." will give you:"
			else
				header = string.format("^7Equipping this item in %s will give you:%s", slot.label, selItem and "\n(replacing "..colorCodes[selItem.rarity]..selItem.name.."^7)" or "")
			end
			self.build:AddStatComparesToTooltip(tooltip, calcBase, output, header)
		end
	end

	if launch.devModeAlt then
		-- Modifier debugging info
		tooltip:AddSeparator(10)
		for _, mod in ipairs(modList) do
			tooltip:AddLine(14, "^7"..modLib.formatMod(mod))
		end
	end
end

function ItemsTabClass:CreateUndoState()
	local state = { }
	state.activeItemSetId = self.activeItemSetId
	state.items = copyTableSafe(self.items, false, true)
	state.itemOrderList = copyTable(self.itemOrderList)
	state.slotSelItemId = { }
	for slotName, slot in pairs(self.slots) do
		state.slotSelItemId[slotName] = slot.selItemId
	end
	state.itemSets = copyTableSafe(self.itemSets)
	state.itemSetOrderList = copyTable(self.itemSetOrderList)
	return state
end

function ItemsTabClass:RestoreUndoState(state)
	self.items = state.items
	wipeTable(self.itemOrderList)
	for k, v in pairs(state.itemOrderList) do
		self.itemOrderList[k] = v
	end
	for slotName, selItemId in pairs(state.slotSelItemId) do
		self.slots[slotName]:SetSelItemId(selItemId)
	end
	self.itemSets = state.itemSets
	wipeTable(self.itemSetOrderList)
	for k, v in pairs(state.itemSetOrderList) do
		self.itemSetOrderList[k] = v
	end
	self.activeItemSetId = state.activeItemSetId
	self.activeItemSet = self.itemSets[self.activeItemSetId]
	self:PopulateSlots()
end
