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

local buySimilar = require("Classes.CompareBuySimilar")
local addImplicit = require("Modules.AddImplicitPopup")
local gemTooltip = require("Classes.GemTooltip")
local MercenaryTools = require("Modules.MercenaryTools")

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

local baseSlots = { "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2", "Ring 3", "Belt", "Graft 1", "Graft 2", "Flask 1", "Flask 2", "Flask 3", "Flask 4", "Flask 5" }

local forbiddenJewelCounterpart = {
	["Forbidden Flame"] = "Forbidden Flesh",
	["Forbidden Flesh"] = "Forbidden Flame",
}

local influenceInfo = itemLib.influenceInfo.all

local catalystQualityFormat = {
	"^x7F7F7FQuality (Attack Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Speed Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Suffix Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Life and Mana Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Caster Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Attribute Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Physical and Chaos Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Resistance Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Prefix Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Defence Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Elemental Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
	"^x7F7F7FQuality (Critical Modifiers): "..colorCodes.MAGIC.."+%d%% (augmented)",
}

local flavourLookup = {}

for _, entry in pairs(data.flavourText) do
	if entry.name and entry.id and entry.text then
		flavourLookup[entry.name] = flavourLookup[entry.name] or {}
		flavourLookup[entry.name][entry.id] = entry.text
	end
end

local function isAnointable(item)
	return item and item.base and not item.base.cannotBeAnointed
	    and item.base.subType ~= "Talisman"
		and (item.canBeAnointed or item.base.type == "Amulet")
end

local function buildModSortList()
	local sortList = { { label = "Default", stat = nil } }
	local sortStats = { }
	for _, entry in ipairs(data.powerStatList) do
		if entry.stat and not entry.ignoreForNodes then
			t_insert(sortList, { label = entry.label, stat = entry.stat })
			sortStats[entry.stat] = entry
		end
	end
	return sortList, sortStats
end

---@class ItemsTab: UndoHandler, ControlHost, Control
---@field displayItem Item?
local ItemsTabClass = newClass("ItemsTab", "UndoHandler", "ControlHost", "Control")

---@param build Build
function ItemsTabClass:ItemsTab(build)
	self:UndoHandler()
	self:ControlHost()
	self:Control()

	self.build = build

	self.socketViewer = new("PassiveTreeView"):PassiveTreeView()

	self.items = { }
	self.itemOrderList = { }

	self.showStatDifferences = true

	-- PoB Trader class initialization
	self.tradeQuery = new("TradeQuery"):TradeQuery(self)

	-- Set selector
	self.controls.setSelect = new("DropDownControl"):DropDownControl({"TOPLEFT",self,"TOPLEFT"}, {96, 8, 216, 20}, nil, function(index, value)
		self:SetViewItemSet(self.itemSetOrderList[index])
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
	self.controls.setLabel = new("LabelControl"):LabelControl({"RIGHT",self.controls.setSelect,"LEFT"}, {-2, 0, 0, 16}, "^7View item set:")
	self.controls.setManage = new("ButtonControl"):ButtonControl({"LEFT",self.controls.setSelect,"RIGHT"}, {4, 0, 90, 20}, "Manage...", function()
		self:OpenItemSetManagePopup()
	end)

	-- Price Items
	self.controls.priceDisplayItem = new("ButtonControl"):ButtonControl({"TOPLEFT",self,"TOPLEFT"}, {96, 32, 310, 20}, "Trade for these items", function()
		self.tradeQuery:PriceItem()
	end)
	self.controls.priceDisplayItem.tooltipFunc = function(tooltip)
		tooltip:Clear()
		tooltip:AddLine(16, "^7Contains searches from the official trading site to help find")
		tooltip:AddLine(16, "^7similar or better items for this build")
	end

	-- Item slots
	self.slots = { }
	self.orderedSlots = { }
	self.slotOrder = { }
	self.slotAnchor = new("Control"):Control({"TOPLEFT",self,"TOPLEFT"}, {96, 76, 310, 0})
	local prevSlot = self.slotAnchor
	local function addSlot(slot)
		prevSlot = slot
		self.slots[slot.slotName] = slot
		t_insert(self.orderedSlots, slot)
		self.slotOrder[slot.slotName] = #self.orderedSlots
		t_insert(self.controls, slot)
	end
	for index, slotName in ipairs(baseSlots) do
		local slot = new("ItemSlotControl"):ItemSlotControl({"TOPLEFT",prevSlot,"BOTTOMLEFT"}, 0, 2, self, slotName)
		addSlot(slot)
		if slotName:match("Weapon") then
			-- Add alternate weapon slot
			slot.weaponSet = 1
			slot.shown = function()
				return not self:GetVisibleItemSet().useSecondWeaponSet
			end
			local swapSlot = new("ItemSlotControl"):ItemSlotControl({"TOPLEFT",prevSlot,"BOTTOMLEFT"}, 0, 2, self, slotName.." Swap", slotName)
			addSlot(swapSlot)
			swapSlot.weaponSet = 2
			swapSlot.shown = function()
				return self:GetVisibleItemSet().useSecondWeaponSet
			end
			for i = 1, 6 do
				local abyssal = new("ItemSlotControl"):ItemSlotControl({"TOPLEFT",prevSlot,"BOTTOMLEFT"}, 0, 2, self, slotName.." Swap Abyssal Socket "..i, "Abyssal #"..i)
				addSlot(abyssal)
				abyssal.parentSlot = swapSlot
				abyssal.weaponSet = 2
				abyssal.shown = function()
					return not abyssal.inactive and self:GetVisibleItemSet().useSecondWeaponSet
				end
				swapSlot.abyssalSocketList[i] = abyssal
			end
		elseif slotName == "Graft 1" or slotName == "Graft 2" then
			slot.shown = function()
				return self.build.spec.treeVersion:find("3_27")
			end
		elseif slotName == "Ring 3" then
			slot.shown = function()
				return self.build.calcsTab.mainEnv.modDB:Flag(nil, "AdditionalRingSlot")
			end
		end
		if slotName == "Weapon 1" or slotName == "Weapon 2" or slotName == "Helmet" or slotName == "Gloves" or slotName == "Body Armour" or slotName == "Boots" or slotName == "Belt" then
			-- Add Abyssal Socket slots
			for i = 1, 6 do
				local abyssal = new("ItemSlotControl"):ItemSlotControl({"TOPLEFT",prevSlot,"BOTTOMLEFT"}, 0, 2, self, slotName.." Abyssal Socket "..i, "Abyssal #"..i)
				addSlot(abyssal)
				abyssal.parentSlot = slot
				if slotName:match("Weapon") then
					abyssal.weaponSet = 1
					abyssal.shown = function()
						return not abyssal.inactive and not self:GetVisibleItemSet().useSecondWeaponSet
					end
				end
				slot.abyssalSocketList[i] = abyssal
			end
		end
	end

	-- Passive tree dropdown controls
	self.controls.specSelect = new("DropDownControl"):DropDownControl({"TOPLEFT",prevSlot,"BOTTOMLEFT"}, {0, 8, 216, 20}, nil, function(index, value)
		if self.build.treeTab.specList[index] then
			self.build.modFlag = true
			self.build.treeTab:SetActiveSpec(index)
		end
	end)
	self.controls.specSelect.enabled = function()
		return #self.controls.specSelect.list > 1
	end
	prevSlot = self.controls.specSelect
	self.controls.specButton = new("ButtonControl"):ButtonControl({"LEFT",prevSlot,"RIGHT"}, {4, 0, 90, 20}, "Manage...", function()
		self.build.treeTab:OpenSpecManagePopup()
	end)
	self.controls.specLabel = new("LabelControl"):LabelControl({"RIGHT",prevSlot,"LEFT"}, {-2, 0, 0, 16}, "^7Passive tree:")

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
		local socketControl = new("ItemSlotControl"):ItemSlotControl({"TOPLEFT",prevSlot,"BOTTOMLEFT"}, 0, 2, self, "Jewel "..node.id, "Socket", node.id)
		self.sockets[node.id] = socketControl
		addSlot(socketControl)
	end
	self.controls.slotHeader = new("LabelControl"):LabelControl({"BOTTOMLEFT",self.slotAnchor,"TOPLEFT"}, {0, -4, 0, 16}, "^7Equipped items:")
	self.controls.weaponSwap1 = new("ButtonControl"):ButtonControl({"BOTTOMRIGHT",self.slotAnchor,"TOPRIGHT"}, {-20, -2, 18, 18}, "I", function()
		self:SetVisibleWeaponSet(false)
	end)
	self.controls.weaponSwap1.overSizeText = 3
	self.controls.weaponSwap1.locked = function()
		return not self:GetVisibleItemSet().useSecondWeaponSet
	end
	self.controls.weaponSwap2 = new("ButtonControl"):ButtonControl({"BOTTOMRIGHT",self.slotAnchor,"TOPRIGHT"}, {0, -2, 18, 18}, "II", function()
		self:SetVisibleWeaponSet(true)
	end)
	self.controls.weaponSwap2.overSizeText = 3
	self.controls.weaponSwap2.locked = function()
		return self:GetVisibleItemSet().useSecondWeaponSet
	end
	self.controls.weaponSwapLabel = new("LabelControl"):LabelControl({"RIGHT",self.controls.weaponSwap1,"LEFT"}, {-4, 0, 0, 14}, "^7Weapon Set:")
	-- All items list
	if main.portraitMode then
		self.controls.itemList = new("ItemListControl"):ItemListControl({"TOPRIGHT",self.lastSlot,"BOTTOMRIGHT"}, {0, 0, 360, 308}, self, true)
	else
		self.controls.itemList = new("ItemListControl"):ItemListControl({"TOPLEFT",self.controls.setManage,"TOPRIGHT"}, {20, 20, 360, 308}, self, true)
	end

	-- Database selector
	self.controls.selectDBLabel = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.itemList,"BOTTOMLEFT"}, {0, 14, 0, 16}, "^7Import from:")
	self.controls.selectDBLabel.shown = function()
		return self.height < 980
	end
	self.controls.selectDB = new("DropDownControl"):DropDownControl({"LEFT",self.controls.selectDBLabel,"RIGHT"}, {4, 0, 150, 18}, { "Uniques", "Rare Templates" })

	-- Unique database
	self.controls.uniqueDB = new("ItemDBControl"):ItemDBControl({"TOPLEFT",self.controls.itemList,"BOTTOMLEFT"}, {0, 76, 360, function(c) return m_min(244, self.maxY - select(2, c:GetPos())) end}, self, main.uniqueDB, "UNIQUE")
	self.controls.uniqueDB.y = function()
		return self.controls.selectDBLabel:IsShown() and 118 or 96
	end
	self.controls.uniqueDB.shown = function()
		return not self.controls.selectDBLabel:IsShown() or self.controls.selectDB.selIndex == 1
	end

	-- Rare template database
	self.controls.rareDB = new("ItemDBControl"):ItemDBControl({"TOPLEFT",self.controls.itemList,"BOTTOMLEFT"}, {0, 76, 360, function(c) return m_min(260, self.maxY - select(2, c:GetPos())) end}, self, main.rareDB, "RARE")
	self.controls.rareDB.y = function()
		return self.controls.selectDBLabel:IsShown() and 78 or 396
	end
	self.controls.rareDB.shown = function()
		return not self.controls.selectDBLabel:IsShown() or self.controls.selectDB.selIndex == 2
	end
	-- Create/import item
	self.controls.craftDisplayItem = new("ButtonControl"):ButtonControl({"TOPLEFT",main.portraitMode and self.controls.setManage or self.controls.itemList,"TOPRIGHT"}, {20, main.portraitMode and 0 or -20, 120, 20}, "Craft item...", function()
		self:CraftItem()
	end)
	self.controls.craftDisplayItem.shown = function()
		return self.displayItem == nil
	end
	self.controls.newDisplayItem = new("ButtonControl"):ButtonControl({"TOPLEFT",self.controls.craftDisplayItem,"TOPRIGHT"}, {8, 0, 120, 20}, "Create custom...", function()
		self:EditDisplayItemText()
	end)
	self.controls.displayItemTip = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.craftDisplayItem,"BOTTOMLEFT"}, {0, 8, 100, 16},
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
	self.controls.sharedItemList = new("SharedItemListControl"):SharedItemListControl({"TOPLEFT",self.controls.craftDisplayItem, "BOTTOMLEFT"}, {0, 232, 340, 308}, self, true)

	-- Display item
	self.displayItemTooltip = new("Tooltip"):Tooltip()
	self.displayItemTooltip.maxWidth = 458
	self.anchorDisplayItem = new("Control"):Control({"TOPLEFT",main.portraitMode and self.controls.setManage or self.controls.itemList,"TOPRIGHT"}, {20, main.portraitMode and 0 or -20, 0, 0})
	self.anchorDisplayItem.shown = function()
		return self.displayItem ~= nil
	end
	self.controls.addDisplayItem = new("ButtonControl"):ButtonControl({"TOPLEFT",self.anchorDisplayItem,"TOPLEFT"}, {0, 0, 100, 20}, "", function()
		self:AddDisplayItem()
	end)
	self.controls.addDisplayItem.label = function()
		return self.items[self.displayItem.id] and "Save" or "Add to build"
	end
	self.controls.editDisplayItem = new("ButtonControl"):ButtonControl({"LEFT",self.controls.addDisplayItem,"RIGHT"}, {8, 0, 60, 20}, "Edit...", function()
		self:EditDisplayItemText()
	end)
	self.controls.removeDisplayItem = new("ButtonControl"):ButtonControl({"LEFT",self.controls.editDisplayItem,"RIGHT"}, {8, 0, 60, 20}, "Cancel", function()
		self:SetDisplayItem()
	end)

	self.controls.displayItemBuySimilar = new("ButtonControl"):ButtonControl({ "LEFT", self.controls.removeDisplayItem, "RIGHT", true },
		{ 8, 0, 100, 20 }, "Buy similar", function()
			local itemSlot = self:GetComparisonSlotNameForItem(self.displayItem)
			buySimilar.openPopup(self.displayItem, itemSlot, self.build)
		end)
	self.controls.displayItemBuySimilar.shown = function()
		return self.displayItem
	end
	-- Section: Variant(s)

	self.controls.displayItemSectionVariant = new("Control"):Control({"TOPLEFT",self.controls.addDisplayItem,"BOTTOMLEFT"}, {0, 8, 0, function()
		if not self.displayItem then
			return 0
		end
		if self.displayItem.usesVariantGroups then
			local rows = self.displayItem.versionList and #self.displayItem.versionList > 1 and 1 or 0
			local groups = 0
			for groupId in pairsSortByKey(self.displayItem.variantGroups) do
				if groups < 6 and #self.displayItem:GetVariantGroupOptions(groupId, false) > 0 then
					rows = rows + 1
					groups = groups + 1
				end
			end
			return rows > 0 and rows * 24 + 4 or 0
		end
		if not self.controls.displayItemVariant:IsShown() then
			return 0
		end
		return (28 +
		(self.displayItem.hasAltVariant and 24 or 0) +
		(self.displayItem.hasAltVariant2 and 24 or 0) +
		(self.displayItem.hasAltVariant3 and 24 or 0) +
		(self.displayItem.hasAltVariant4 and 24 or 0) +
		(self.displayItem.hasAltVariant5 and 24 or 0))
	end})
	self.controls.displayItemVersion = new("DropDownControl"):DropDownControl({"TOPLEFT", self.controls.displayItemSectionVariant,"TOPLEFT"}, {0, 0, 300, 20}, nil, function(index, value)
		self.displayItem.selectedVersion = index
		self.displayItem:NormaliseVariantSelections()
		self.displayItem:BuildAndParseRaw()
		self:UpdateDisplayItemVariantControls()
		self:UpdateDisplayItemTooltip()
		self:UpdateDisplayItemRangeLines()
	end)
	self.controls.displayItemVersion.maxDroppedWidth = 1000
	self.controls.displayItemVersion.shown = function()
		return self.displayItem and self.displayItem.usesVariantGroups
			and self.displayItem.versionList and #self.displayItem.versionList > 1
	end
	self.controls.displayItemVariant = new("DropDownControl"):DropDownControl({"TOPLEFT", self.controls.displayItemSectionVariant,"TOPLEFT"}, {0, 0, 300, 20}, nil, function(index, value)
		self:SelectDisplayItemVariant(index, value, "variant", self.controls.displayItemVariant)
	end)
	self.controls.displayItemVariant.y = function()
		return self.controls.displayItemVersion:IsShown() and 24 or 0
	end
	self.controls.displayItemVariant.maxDroppedWidth = 1000
	self.controls.displayItemVariant.shown = function()
		return self.displayItem.variantList and #self.displayItem.variantList > 1
	end
	self.controls.displayItemAltVariant = new("DropDownControl"):DropDownControl({"TOPLEFT",self.controls.displayItemVariant,"BOTTOMLEFT"}, {0, 4, 300, 20}, nil, function(index, value)
		self:SelectDisplayItemVariant(index, value, "variantAlt", self.controls.displayItemAltVariant)
	end)
	self.controls.displayItemAltVariant.maxDroppedWidth = 1000
	self.controls.displayItemAltVariant.shown = function()
		return self.displayItem.hasAltVariant
	end
	self.controls.displayItemAltVariant2 = new("DropDownControl"):DropDownControl({"TOPLEFT",self.controls.displayItemAltVariant,"BOTTOMLEFT"}, {0, 4, 300, 20}, nil, function(index, value)
		self:SelectDisplayItemVariant(index, value, "variantAlt2", self.controls.displayItemAltVariant2)
	end)
	self.controls.displayItemAltVariant2.maxDroppedWidth = 1000
	self.controls.displayItemAltVariant2.shown = function()
		return self.displayItem.hasAltVariant2
	end
	self.controls.displayItemAltVariant3 = new("DropDownControl"):DropDownControl({"TOPLEFT",self.controls.displayItemAltVariant2,"BOTTOMLEFT"}, {0, 4, 300, 20}, nil, function(index, value)
		self:SelectDisplayItemVariant(index, value, "variantAlt3", self.controls.displayItemAltVariant3)
	end)
	self.controls.displayItemAltVariant3.maxDroppedWidth = 1000
	self.controls.displayItemAltVariant3.shown = function()
		return self.displayItem.hasAltVariant3
	end
	self.controls.displayItemAltVariant4 = new("DropDownControl"):DropDownControl({"TOPLEFT",self.controls.displayItemAltVariant3,"BOTTOMLEFT"}, {0, 4, 300, 20}, nil, function(index, value)
		self:SelectDisplayItemVariant(index, value, "variantAlt4", self.controls.displayItemAltVariant4)
	end)
	self.controls.displayItemAltVariant4.maxDroppedWidth = 1000
	self.controls.displayItemAltVariant4.shown = function()
		return self.displayItem.hasAltVariant4
	end
	self.controls.displayItemAltVariant5 = new("DropDownControl"):DropDownControl({"TOPLEFT",self.controls.displayItemAltVariant4,"BOTTOMLEFT"}, {0, 4, 300, 20}, nil, function(index, value)
		self:SelectDisplayItemVariant(index, value, "variantAlt5", self.controls.displayItemAltVariant5)
	end)
	self.controls.displayItemAltVariant5.maxDroppedWidth = 1000
	self.controls.displayItemAltVariant5.shown = function()
		return self.displayItem.hasAltVariant5
	end
	for _, control in ipairs({
		self.controls.displayItemVariant,
		self.controls.displayItemAltVariant,
		self.controls.displayItemAltVariant2,
		self.controls.displayItemAltVariant3,
		self.controls.displayItemAltVariant4,
		self.controls.displayItemAltVariant5,
	}) do
		local legacyShown = control.shown
		control.shown = function(c)
			return self.displayItem and (self.displayItem.usesVariantGroups and c.newVariantVisible
				or not self.displayItem.usesVariantGroups and legacyShown())
		end
		control.enabled = function(c)
			return not self.displayItem or not self.displayItem.usesVariantGroups or c.newVariantEnabled
		end
	end

	-- Section: Sockets and Links
	self.controls.displayItemSectionSockets = new("Control"):Control({"TOPLEFT",self.controls.displayItemSectionVariant,"BOTTOMLEFT"}, {0, 0, 0, function()
		return self.displayItem and self.displayItem.selectableSocketCount > 0 and 28 or 0
	end})
	for i = 1, 6 do
		local drop = new("DropDownControl"):DropDownControl({"TOPLEFT",self.controls.displayItemSectionSockets,"TOPLEFT"}, {(i-1) * 64, 0, 36, 20}, socketDropList, function(index, value)
			self.displayItem.sockets[i].color = value.color
			self.displayItem:BuildAndParseRaw()
			self:UpdateDisplayItemTooltip()
		end)
		drop.shown = function()
			return self.displayItem.selectableSocketCount >= i and self.displayItem.sockets[i] and self.displayItem.sockets[i].color ~= "A"
		end
		self.controls["displayItemSocket"..i] = drop
		if i < 6 then
			local link = new("CheckBoxControl"):CheckBoxControl({"LEFT",drop,"RIGHT"}, {4, 0, 20}, nil, function(state)
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
	self.controls.displayItemAddSocket = new("ButtonControl"):ButtonControl({"TOPLEFT",self.controls.displayItemSectionSockets,"TOPLEFT"}, {function() return (#self.displayItem.sockets - self.displayItem.abyssalSocketCount) * 64 - 12 end, 0, 20, 20}, "+", function()
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
	self.controls.displayItemSectionEnchant = new("Control"):Control({"TOPLEFT",self.controls.displayItemSectionSockets,"BOTTOMLEFT"}, {0, 0, 0, function()
		return (self.controls.displayItemEnchant:IsShown() or self.controls.displayItemEnchant2:IsShown() or self.controls.displayItemAnoint:IsShown() or self.controls.displayItemAnoint2:IsShown() or self.controls.displayItemCorrupt:IsShown() ) and 28 or 0
	end})
	self.controls.displayItemEnchant = new("ButtonControl"):ButtonControl({ "TOPLEFT", self.controls.displayItemSectionEnchant, "TOPLEFT" }, { 0, 0, 160, 20 }, "Change Enchantment...", function()
		self:EnchantDisplayItem(1)
	end)
	self.controls.displayItemEnchant.shown = function()
		return self.displayItem and self.displayItem.enchantments
	end
	self.controls.displayItemEnchant2 = new("ButtonControl"):ButtonControl({ "TOPLEFT", self.controls.displayItemEnchant, "TOPRIGHT", true }, { 8, 0, 160, 20 }, "Change Enchantment 2...", function()
		self:EnchantDisplayItem(2)
	end)
	self.controls.displayItemEnchant2.shown = function()
		return self.displayItem and self.displayItem.enchantments and self.displayItem.canHaveTwoEnchants and #self.displayItem.enchantModLines > 0
	end
	self.controls.displayItemAnoint = new("ButtonControl"):ButtonControl({"TOPLEFT",self.controls.displayItemEnchant2,"TOPRIGHT",true}, {8, 0, 100, 20}, "Anoint...", function()
		self:AnointDisplayItem(1)
	end)
	self.controls.displayItemAnoint.shown = function()
		return self.displayItem and isAnointable(self.displayItem)
	end
	self.controls.displayItemAnoint2 = new("ButtonControl"):ButtonControl({"TOPLEFT",self.controls.displayItemAnoint,"TOPRIGHT",true}, {8, 0, 100, 20}, "Anoint 2...", function()
		self:AnointDisplayItem(2)
	end)
	self.controls.displayItemAnoint2.shown = function()
		return self.displayItem and
			isAnointable(self.displayItem) and
			self.displayItem.canHaveTwoEnchants and
			#self.displayItem.enchantModLines > 0
	end
	self.controls.displayItemAnoint3 = new("ButtonControl"):ButtonControl({"TOPLEFT",self.controls.displayItemAnoint2,"TOPRIGHT",true}, {8, 0, 100, 20}, "Anoint 3...", function()
		self:AnointDisplayItem(3)
	end)
	self.controls.displayItemAnoint3.shown = function()
		return self.displayItem and
			isAnointable(self.displayItem) and
			self.displayItem.canHaveThreeEnchants and
			#self.displayItem.enchantModLines > 1
	end
	self.controls.displayItemAnoint4 = new("ButtonControl"):ButtonControl({"TOPLEFT",self.controls.displayItemAnoint3,"TOPRIGHT",true}, {8, 0, 100, 20}, "Anoint 4...", function()
		self:AnointDisplayItem(4)
	end)
	self.controls.displayItemAnoint4.shown = function()
		return self.displayItem and
			isAnointable(self.displayItem) and
			self.displayItem.canHaveFourEnchants and
			#self.displayItem.enchantModLines > 2
	end
	self.controls.displayItemCorrupt = new("ButtonControl"):ButtonControl({"TOPLEFT",self.controls.displayItemAnoint4,"TOPRIGHT",true}, {8, 10, 100, 20}, "Corrupt...", function()
		self:CorruptDisplayItem()
	end)
	self.controls.displayItemCorrupt.shown = function()
		return self.displayItem and self.displayItem.corruptible
	end
	self.controls.displayItemAddImplicit = new("ButtonControl"):ButtonControl({"TOPLEFT",self.controls.displayItemCorrupt,"TOPRIGHT",true}, {8, 0, 120, 20}, "Add Implicit...", function()
		addImplicit.AddImplicitToDisplayItem(self, self.displayItem)
	end)
	self.controls.displayItemAddImplicit.shown = function()
		return self.displayItem and
			self.displayItem.type ~= "Tincture" and self.displayItem.type ~= "Graft" and (self.displayItem.corruptible or ((self.displayItem.type ~= "Flask" and self.displayItem.type ~= "Jewel") and
			(self.displayItem.rarity == "NORMAL" or self.displayItem.rarity == "MAGIC" or self.displayItem.rarity == "RARE"))) and
			not self.displayItem.implicitsCannotBeChanged
	end

	-- Section: Influence dropdowns
	local influenceDisplayList = { "Influence" }
	for i, curInfluenceInfo in ipairs(influenceInfo) do
		influenceDisplayList[i + 1] = curInfluenceInfo.display
	end
	local function setDisplayItemInfluence(influenceIndexList)
		self.displayItem:ResetInfluence()
		if self.displayItem.HasElderShaperAndAllConquerorInfluences then
			for i, curInfluenceInfo in ipairs(itemLib.influenceInfo.default) do
				self.displayItem[influenceInfo[i].key] = true
			end
		else
			for _, index in ipairs(influenceIndexList) do
				if index > 0 then
					self.displayItem[influenceInfo[index].key] = true
				end
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
	self.controls.displayItemSectionInfluence = new("Control"):Control({"TOPLEFT",self.controls.displayItemSectionEnchant,"BOTTOMLEFT"}, {0, 0, 0, function()
		return self.displayItem and self.displayItem.canBeInfluenced and 28 or 0
	end})
	local influenceTipText = table.concat(main:WrapString("Selecting an influence here will also allow the modifier dropdowns to contain influenced mods.", 16, 140), "\n")
	self.controls.displayItemInfluence = new("DropDownControl"):DropDownControl({"TOPLEFT",self.controls.displayItemSectionInfluence,"TOPRIGHT"}, {0, 0, 100, 20}, influenceDisplayList, function(index, value)
		local otherIndex = self.controls.displayItemInfluence2.selIndex
		setDisplayItemInfluence({ index - 1, otherIndex - 1 })
	end)
	self.controls.displayItemInfluence.tooltipText = influenceTipText
	self.controls.displayItemInfluence.shown = function()
		return self.displayItem and self.displayItem.canBeInfluenced
	end
	self.controls.displayItemInfluence2 = new("DropDownControl"):DropDownControl({"TOPLEFT",self.controls.displayItemInfluence,"TOPRIGHT",true}, {8, 0, 100, 20}, influenceDisplayList, function(index, value)
		local otherIndex = self.controls.displayItemInfluence.selIndex
		setDisplayItemInfluence({ index - 1, otherIndex - 1 })
	end)
	self.controls.displayItemInfluence2.shown = function()
		return self.displayItem and self.displayItem.canBeInfluenced
	end
	self.controls.displayItemInfluence2.tooltipText = influenceTipText

	-- Section: Item Quality
	self.controls.displayItemSectionQuality = new("Control"):Control({"TOPLEFT",self.controls.displayItemSectionInfluence,"BOTTOMLEFT"}, {0, 0, 0, function()
		return (self.controls.displayItemQuality:IsShown() and self.controls.displayItemQualityEdit:IsShown()) and 28 or 0
	end})
	self.controls.displayItemQuality = new("LabelControl"):LabelControl({ "TOPLEFT", self.controls.displayItemSectionQuality, "TOPRIGHT" }, { 0, 0, 0, 16 }, "^7Quality:")
	self.controls.displayItemQuality.shown = function()
		return self.displayItem and self.displayItem.quality and (self.displayItem.base.type ~= "Amulet" or self.displayItem.base.type ~= "Belt" or self.displayItem.base.type ~= "Jewel" or self.displayItem.base.type ~= "Quiver" or self.displayItem.base.type ~= "Ring" or self.displayItem.type ~= "Graft")
	end

	self.controls.displayItemQualityEdit = new("EditControl"):EditControl({"LEFT",self.controls.displayItemQuality,"RIGHT"}, {2, 0, 60, 20}, nil, nil, "%D", 2, function(buf)
		self.displayItem.quality = tonumber(buf)
		self.displayItem:BuildAndParseRaw()
		self:UpdateDisplayItemTooltip()
	end)
	self.controls.displayItemQualityEdit.shown = function()
		return self.displayItem and self.displayItem.quality and (self.displayItem.base.type ~= "Amulet" or self.displayItem.base.type ~= "Belt" or self.displayItem.base.type ~= "Jewel" or self.displayItem.base.type ~= "Quiver" or self.displayItem.base.type ~= "Ring" or self.displayItem.type ~= "Graft")
	end

	local sortingOptions = {
		{ stat = nil, label = "Default" }
	}
	for _, option in ipairs(data.powerStatList) do
		if not option.ignoreForItems and option.label ~= "Name" then
			table.insert(sortingOptions, option)
		end
	end
	-- Section: Catalysts
	self.controls.displayItemSectionCatalyst = new("Control"):Control({"TOPLEFT",self.controls.displayItemSectionQuality,"BOTTOMLEFT"}, {0, 0, 0, function()
		return (self.controls.displayItemCatalyst:IsShown() or self.controls.displayItemCatalystQualityEdit:IsShown()) and 28 or 0
	end})
	self.controls.displayItemCatalyst = new("DropDownControl"):DropDownControl({"TOPLEFT",self.controls.displayItemSectionCatalyst,"TOPRIGHT"}, {0, 0, 250, 20},
		{"Catalyst","Abrasive (Attack)","Accelerating (Speed)","Dextral (Suffix)","Fertile (Life & Mana)","Imbued (Caster)","Intrinsic (Attribute)","Noxious (Physical & Chaos Damage)",
		 "Prismatic (Resistance)","Sinistral (Prefix)","Tempering (Defense)","Turbulent (Elemental)","Unstable (Critical)"},
		function(index, value)
			self.displayItem.catalyst = index - 1
			if not self.displayItem.catalystQuality then
				self.displayItem.catalystQuality = 20
				self.controls.displayItemCatalystQualityEdit:SetText(self.displayItem.catalystQuality)
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
	self.controls.displayItemCatalystQualityEdit = new("EditControl"):EditControl({"LEFT",self.controls.displayItemCatalyst,"RIGHT"}, {2, 0, 60, 20}, nil, nil, "%D", 2, function(buf)
		self.displayItem.catalystQuality = tonumber(buf)
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
	self.controls.displayItemCatalystQualityEdit.shown = function()
		return self.displayItem and (self.displayItem.crafted or self.displayItem.hasModTags) and self.displayItem.catalyst and self.displayItem.catalyst > 0
	end

	-- Section: Cluster Jewel
	self.controls.displayItemSectionClusterJewel = new("Control"):Control({"TOPLEFT",self.controls.displayItemSectionCatalyst,"BOTTOMLEFT"}, {0, 0, 0, function()
		return self.controls.displayItemClusterJewelSkill:IsShown() and 52 or 0
	end})
	self.controls.displayItemClusterJewelSkill = new("DropDownControl"):DropDownControl({"TOPLEFT",self.controls.displayItemSectionClusterJewel,"TOPLEFT"}, {0, 0, 300, 20}, { }, function(index, value)
		self.displayItem.clusterJewelSkill = value.skillId
		self:CraftClusterJewel()
	end) {
		shown = function()
			return self.displayItem and self.displayItem.crafted and self.displayItem.clusterJewel
		end
	}

	self.controls.displayItemClusterJewelNodeCountLabel = new("LabelControl"):LabelControl({"TOPLEFT",self.controls.displayItemClusterJewelSkill,"BOTTOMLEFT"}, {0, 7, 0, 14}, "^7Added Passives:")
	self.controls.displayItemClusterJewelNodeCount = new("SliderControl"):SliderControl({"LEFT",self.controls.displayItemClusterJewelNodeCountLabel,"RIGHT"}, {2, 0, 150, 20}, function(val)
		local divVal = self.controls.displayItemClusterJewelNodeCount:GetDivVal()
		local clusterJewel = self.displayItem.clusterJewel
		self.displayItem.clusterJewelNodeCount = round(val * (clusterJewel.maxNodes - clusterJewel.minNodes) + clusterJewel.minNodes)
		self:CraftClusterJewel()
	end)

	self.controls.craftingSortingLabel = new("LabelControl"):LabelControl({ "TOPLEFT", self.controls.displayItemSectionClusterJewel, "BOTTOMLEFT" }, { 0, 0, 0, 16 }, "^7Modifier sorting:")
	self.controls.craftingSortingLabel.shown = function()
		return self.displayItem and self.displayItem.crafted and
			-- cluster jewels don't have good comparison support and sorting would be misleading
			not (self.displayItem.base.type == "Jewel" and self.displayItem.base.subType == "Cluster")
	end
	self.controls.craftingSorting = new("DropDownControl"):DropDownControl({ "LEFT", self.controls.craftingSortingLabel, "RIGHT" }, { 4, 0, 200, 20 }, sortingOptions, function()
		self:UpdateAffixControls()
	end)

	-- Section: Affix Selection
	local maxModCount = 9
	self.controls.displayItemSectionAffix = new("Control"):Control({ "TOPLEFT", self.controls.craftingSortingLabel, "BOTTOMLEFT", true }, { 0, function()
		if self.controls.craftingSortingLabel.shown() then
			return 8
		else
			return -16
		end
	end, 0, function()
		if not self.displayItem or not self.displayItem.crafted then
			return 0
		end
		local h = 6
		for i = 1, maxModCount do
			if self.controls["displayItemAffix"..i]:IsShown() then
				h = h + 24
				if self.controls["displayItemAffixRange"..i]:IsShown() then
					h = h + 18
				end
			end
		end
		return h
	end})
	self.controls.displayItemSectionAffix.shown = function()
		return self.displayItem and self.displayItem.crafted
	end
	for i = 1, maxModCount do
		local prev = self.controls["displayItemAffix"..(i-1)] or self.controls.displayItemSectionAffix
		local drop, slider
		local function verifyRange(range, index, drop) -- flips range if it will form discontinuous values
			local priorMod = index - 1 > 0 and self.displayItem.affixes[drop.list[drop.selIndex].modList[index - 1]] or nil
			local nextMod = index + 1 < #drop.list[drop.selIndex].modList and self.displayItem.affixes[drop.list[drop.selIndex].modList[index + 1]] or nil
			local function flipRange(modA, modB) -- assumes all pairs are ordered the same
				local function getMinMax(mod) -- gets first valid range from a mod
					for _, line in ipairs(mod) do
						local min, max = line:match("%((%d[%d%.]*)%-(%d[%d%.]*)%)")
						if min and max then return tonumber(min), tonumber(max)	end
					end
				end

				local minA, maxA = getMinMax(modA)
				local minB, maxB = getMinMax(modB)

				if not minA or not minB or not maxA or not maxB then
					return false
				end

				local allInts = minA == m_floor(minA) and maxA == m_floor(maxA) and minB == m_floor(minB) and maxB == m_floor(maxB) -- if the mod goes in steps that aren't 1, then the code below this doesn't work
				if (minA and minB and maxA and maxB and allInts) then
					if (minA < minB) then -- ascending
						return minA + 1 == maxB
					else -- descending
						return minA - 1 == maxB
					end
				end
				return false
			end

			if priorMod then
				if flipRange(priorMod, self.displayItem.affixes[drop.list[drop.selIndex].modList[index]]) then
					range = 1 - range
				end
			elseif nextMod then
				if flipRange(self.displayItem.affixes[drop.list[drop.selIndex].modList[index]], nextMod) then
					range = 1 - range
				end
			end
			return range
		end
		drop = new("DropDownControl"):DropDownControl({"TOPLEFT",prev,"TOPLEFT"}, {i==1 and 40 or 0, 0, 418, 20}, nil, function(index, value)
			local affix = { modId = "None", fractured = self.displayItem[drop.outputTable][drop.outputIndex].fractured }
			if value.modId then
				affix.modId = value.modId
				affix.range = slider.val
			elseif value.modList then
				slider.divCount = #value.modList
				local index, range = slider:GetDivVal()
				affix.modId = value.modList[index]
				affix.range = verifyRange(range, index, drop)
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
							tooltip:AddLine(14, (minLine:gsub("%d[%d%.]*", function(min)
								local s, e, max = maxLine:find("(%d[%d%.]*)", start)
								start = e + 1
								if min == max then
									return min
								else
									return "("..min.."-"..max..")"
								end
							end)))
						end
					end
					tooltip:AddLine(16, "Level: "..minMod.level.." to "..maxMod.level)
					-- Assuming that all mods have the same tags
					if maxMod.modTags and #maxMod.modTags > 0 then
						tooltip:AddLine(16, "Tags: "..table.concat(maxMod.modTags, ', '))
					end
				end
				local mod = self.displayItem.affixes[value.modId or modList[1]]
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
							if line ~= " " and (node.mods[i].extra or not node.mods[i].list) then
								local line = colorCodes.UNSUPPORTED .. line
								line = main.notSupportedModTooltips and (line .. main.notSupportedTooltipText) or line
								tooltip:AddLine(16, line)
							else
								tooltip:AddLine(16, colorCodes.MAGIC..line)
							end
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
					self:AppendAddedNotableTooltip(tooltip, node)

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
				else
					local mod = { }
					if value.modId or #modList == 1 then
						mod = self.displayItem.affixes[value.modId or modList[1]]
					else
						mod = self.displayItem.affixes[modList[1 + round((#modList - 1) * (main.defaultItemAffixQuality or 0.5))]]
					end

					-- Adding Mod
					self:AddModComparisonTooltip(tooltip, mod)
				end
			end
		end
		drop.shown = function()
			return self.displayItem and self.displayItem.crafted and i <= self.displayItem.affixLimit
		end
		slider = new("SliderControl"):SliderControl({"TOPLEFT",drop,"BOTTOMLEFT"}, {0, 2, 300, 16}, function(val)
			local affix = self.displayItem[drop.outputTable][drop.outputIndex]
			local index, range = slider:GetDivVal()
			affix.modId = drop.list[drop.selIndex].modList[index]

			affix.range = verifyRange(range, index, drop)
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
				range = verifyRange(range, index, drop)
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
		self.controls["displayItemAffixLabel"..i] = new("LabelControl"):LabelControl({"RIGHT",drop,"LEFT"}, {-4, 0, 0, 14}, function()
			local ignoreModType = self.displayItem.rareLikeUnique and self.displayItem.rareLikeUnique.ignoreModType
			return ignoreModType and "^7Explicit:"
				or drop.outputTable == "prefixes" and "^7Prefix:"
				or "^7Suffix:"
		end)
		self.controls["displayItemAffixRange"..i] = slider
		self.controls["displayItemAffixRangeLabel"..i] = new("LabelControl"):LabelControl({"RIGHT",slider,"LEFT"}, {-4, 0, 0, 14}, function()
			return drop.selIndex > 1 and "^7Roll:" or "^x7F7F7FRoll:"
		end)
	end

	-- Section: Custom modifiers
	-- if either Custom or Crucible mod buttons are shown, create the control for the list of mods
	self.controls.displayItemSectionCustom = new("Control"):Control({"TOPLEFT",self.controls.displayItemSectionAffix,"BOTTOMLEFT",true}, {0, 0, 0, function()
		return (self.controls.displayItemAddCustom:IsShown() or self.controls.displayItemAddCrucible:IsShown()) and 28 + self.displayItem.customCount * 22 or 0
	end})
	self.controls.displayItemSectionCustom.shown = function()
		return self.displayItem ~= nil
	end
	self.controls.displayItemAddCustom = new("ButtonControl"):ButtonControl({"TOPLEFT",self.controls.displayItemSectionCustom,"TOPLEFT"}, {0, 0, 120, 20}, "Add modifier...", function()
		self:AddCustomModifierToDisplayItem()
	end)
	self.controls.displayItemAddCustom.shown = function()
		return self.displayItem and (self.displayItem.rarity == "MAGIC" or self.displayItem.rarity == "RARE" or (self.displayItem.rareLikeUnique and self.displayItem.rareLikeUnique.supportsCustomModifiers))
	end

	-- Section: Crucible modifiers
	-- if the Add modifier button is not shown, take its place, otherwise move it to the right of it
	self.controls.displayItemAddCrucible = new("ButtonControl"):ButtonControl({"TOPLEFT",self.controls.displayItemSectionCustom,"TOPLEFT"}, {function()
		return (self.controls.displayItemAddCustom:IsShown() and 128) or 0
	end, 0, 150, 20}, "Add Crucible mod...", function()
		self:AddCrucibleModifierToDisplayItem()
	end)
	self.controls.displayItemAddCrucible.shown = function()
		return self.displayItem and (self.displayItem:GetPrimarySlot() == "Weapon 1" or self.displayItem.type == "Shield" or self.displayItem.canHaveShieldCrucibleTree)
	end

	-- Section: Modifier Range
	local labelFontSize = 14
	self.controls.displayItemSectionRange = new("Control"):Control({ "TOPLEFT", self.controls.displayItemSectionCustom, "BOTTOMLEFT" }, { 0, 0, 0, function()
		if not self.displayItem or not self.displayItem.rangeLineList[1] then
			return 0
		end
		if main.showAllItemAffixes and self.displayItem.rarity == "UNIQUE" then
			local height = 0
			for i = 1, #self.displayItem.rangeLineList do
				local label = self.controls["displayItemStackedRangeLine" .. i]
				height = height + math.max(22, (label.lineCount or 0) * labelFontSize)
			end
			return height + 4
		else
			return 28
		end
	end})
	local foulbornIcon = NewImageHandle()
	foulbornIcon:Load("Assets/breachicon.png")
	self.controls.displayItemRangeLine = new("DropDownControl"):DropDownControl({"TOPLEFT",self.controls.displayItemSectionRange,"TOPLEFT"}, {0, 0, 350, 18}, nil, function(index, value)
		self.controls.displayItemRangeSlider.val = self.displayItem.rangeLineList[index].range
	end)
	self.controls.displayItemRangeLine.shown = function()
		return self.displayItem and self.displayItem.rangeLineList[1] ~= nil and not (main.showAllItemAffixes and self.displayItem.rarity == "UNIQUE")
	end
	local function getSelectedModLine()
		return self.displayItem and self.displayItem.rangeLineList[self.controls.displayItemRangeLine.selIndex] or nil
	end
	local box = new("CheckBoxControl"):CheckBoxControl({ "LEFT", self.controls.displayItemRangeLine, "RIGHT", true }, { 0, 0, 18 }, nil)
	box.changeFunc = function(val)
		local line = getSelectedModLine()
		if line and line.modId and line.newModId then
			self.displayItem:MutateMod(line.modId, line.newModId, not line.mutated)
			self:UpdateDisplayItemTooltip()
			self:UpdateCustomControls()
			self:UpdateDisplayItemRangeLines()
		end
	end
	box.RealDraw = box.Draw
	function box:Draw(...)
		local x, y = self:GetPos()
		SetDrawColor(1, 1, 1)
		DrawImage(foulbornIcon, x - 24, y - 1, 20, 20)
		return box:RealDraw(...)
	end

	box.shown = function()
		local line = getSelectedModLine()
		-- hack: set property according to item. the state is not a prop and so can't be set as a function value
		if line and line.mutated then
			box.state = true
		else
			box.state = false
		end
		return not main.showAllItemAffixes and line and line.modId and line.newModId
	end
	-- fix spacing
	box.x = function()
		if box:IsShown() then
			return 25
		else
			return 8
		end
	end
	self.controls.displayItemMutatedCheckbox = box
	local slider = new("SliderControl"):SliderControl({ "LEFT", self.controls.displayItemMutatedCheckbox, "RIGHT", true }, { 4, 0, 100, 18 }, function(val)
		local line = getSelectedModLine()
		line.range = val
		self.displayItem:BuildAndParseRaw()
		self:UpdateDisplayItemTooltip()
		self:UpdateCustomControls()
	end)
	slider.shown = function()
		local modLine = self.displayItem and not (main.showAllItemAffixes and self.displayItem.rarity == "UNIQUE") and self.displayItem.rangeLineList[self.controls.displayItemRangeLine.selIndex]
		if modLine then
			-- it's possible for the range to change while this slider is
			-- hidden, so correct the slider to show the same value
			slider.val = modLine.range or slider.val
			return modLine.showSlider
		else
			return false
		end
	end
	self.controls.displayItemRangeSlider = slider

	for i = 1, 20 do
		local baseControl = self.controls.displayItemSectionRange

		-- layout: [box] <- [slider] <- text

		local box = new("CheckBoxControl"):CheckBoxControl({ "TOPLEFT", baseControl, "TOPLEFT", true }, { 0, 0, 18 }, nil, function(val)
			local line = self.displayItem and self.displayItem.rangeLineList[i]
			if line and line.modId and line.newModId then
				self.displayItem:MutateMod(line.modId, line.newModId, not line.mutated)
				self:UpdateDisplayItemTooltip()
				self:UpdateCustomControls()
			end
		end)
		-- fix spacing
		box.x = function()
			if box:IsShown() then
				return 24
			else
				return 0
			end
		end
		box.y = function()
			local prevBox = self.controls["displayItemStackedMutatedCheckbox" .. (i - 1)]
			local prevLabel = self.controls["displayItemStackedRangeLine" .. (i - 1)]
			return i == 1 and 2 or prevBox:GetProperty("y") + math.max(22, (prevLabel.lineCount or 0) * 14)
		end
		box.shown = function()
			local line = (self.displayItem and self.displayItem.rangeLineList[i]) or nil
			-- hack: set property according to item. the state is not a prop and so can't be set as a function value
			if line and line.mutated then
				box.state = true
			else
				box.state = false
			end
			return main.showAllItemAffixes and line and line.modId and line.newModId
		end
		box.RealDraw = box.Draw
		function box:Draw(...)
			local x, y = self:GetPos()
			SetDrawColor(1, 1, 1)
			DrawImage(foulbornIcon, x - 24, y, 20, 20)
			return box:RealDraw(...)
		end

		self.controls["displayItemStackedMutatedCheckbox" .. i] = box

		local slider = new("SliderControl"):SliderControl({ "LEFT", box, "RIGHT", true }, { 4, 0, 100, 18 }, function(val)
			if self.displayItem and self.displayItem.rangeLineList[i] then
				self.displayItem.rangeLineList[i].range = val
				self.displayItem:BuildAndParseRaw()
				self:UpdateDisplayItemTooltip()
				self:UpdateCustomControls()
			end
		end)
		slider.shown = function()
			local modLine = main.showAllItemAffixes and self.displayItem and self.displayItem.rarity == "UNIQUE" and self.displayItem.rangeLineList[i]
			if modLine then
				-- it's possible for the range to change while this slider is
				-- hidden, so correct the slider to show the same value
				slider.val = modLine.range or slider.val
				return modLine.showSlider
			else
				return false
			end
		end

		self.controls["displayItemStackedRangeSlider" .. i] = slider

		self.controls["displayItemStackedRangeLine" .. i] = new("LabelControl"):LabelControl({ "LEFT", slider, "RIGHT", true }, { 4, -2, 350, labelFontSize }, function()
			local modLine = self.displayItem.rangeLineList[i]
			if self.displayItem and modLine then
				local colour = modLine.mutated and colorCodes.MUTATED or "^7"
				local text = table.concat(main:WrapString(modLine.line, labelFontSize, 370), "\n")
				local _, lineCount = text:gsub("\n", "")
				self.controls["displayItemStackedRangeLine" .. i].lineCount = lineCount + 1
				return colour .. text
			end
			return ""
		end)
		self.controls["displayItemStackedRangeLine" .. i].shown = function()
			return slider:IsShown() or box:IsShown()
		end
	end
	-- Tooltip anchor
	self.controls.displayItemTooltipAnchor = new("Control"):Control({"TOPLEFT",self.controls.displayItemSectionRange,"BOTTOMLEFT"})

	-- Scroll bars
	self.controls.scrollBarH = new("ScrollBarControl"):ScrollBarControl(nil, {0, 0, 0, 18}, 100, "HORIZONTAL", true)
	self.controls.scrollBarV = new("ScrollBarControl"):ScrollBarControl(nil, {0, 0, 18, 0}, 100, "VERTICAL", true)

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
	return self
end

function ItemsTabClass:Load(xml, dbFileName)
	self.activeItemSetId = 0
	self.viewItemSetId = nil
	self.viewItemSet = nil
	self.viewComparisonActor = nil
	self.itemSets = { }
	self.itemSetOrderList = { }
	self.tradeQuery.statSortSelectionList = { }
	for _, node in ipairs(xml) do
		if node.elem == "Item" then
			local item = new("Item"):Item("")
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
			if node.attrib.variantAlt4 then
				item.hasAltVariant4 = true
				item.variantAlt4 = tonumber(node.attrib.variantAlt4)
			end
			if node.attrib.variantAlt5 then
				item.hasAltVariant5 = true
				item.variantAlt5 = tonumber(node.attrib.variantAlt5)
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
					for _, list in ipairs{item.buffModLines, item.enchantModLines, item.scourgeModLines, item.implicitModLines, item.explicitModLines, item.crucibleModLines} do
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
					local itemSlot = itemSet[slotName]
					if itemSlot then
						itemSlot.selItemId = tonumber(child.attrib.itemId) or 0
						itemSlot.active = child.attrib.active == "true"
						itemSlot.pbURL = child.attrib.itemPbURL or ""
					end
				elseif child.elem == "SocketIdURL" then
					local id = tonumber(child.attrib.nodeId)
					itemSet[id] = { pbURL = child.attrib.itemPbURL or "" }
				end
			end
			t_insert(self.itemSetOrderList, itemSet.id)
		elseif node.elem == "TradeSearchWeights" then
			for _, child in ipairs(node) do
				local statSort = {
					label = child.attrib.label,
					stat = child.attrib.stat,
					weightMult = tonumber(child.attrib.weightMult)
				}
				for _, statEntry in ipairs(data.powerStatList) do
					if statSort.stat == statEntry.stat then
						-- update information which can be out of data or missing in the xml
						statSort.label = statEntry.label
						statSort.transform = statEntry.transform
						t_insert(self.tradeQuery.statSortSelectionList, statSort)
						break
					end
				end
			end
		end
	end
	local savedActiveItemSetId = tonumber(xml.attrib.activeItemSet)
	if not self.itemSetOrderList[1] then
		local itemSet = self:NewItemSet(1)
		itemSet.useSecondWeaponSet = xml.attrib.useSecondWeaponSet == "true"
		t_insert(self.itemSetOrderList, itemSet.id)
	end
	local activeItemSetId = savedActiveItemSetId
	if not self.itemSets[activeItemSetId] then
		activeItemSetId = self.itemSetOrderList[1]
	end
	self.skipConfigItemSetSync = true
	self:SetActiveItemSet(activeItemSetId)
	self.skipConfigItemSetSync = false
	if xml.attrib.showStatDifferences then
		self.showStatDifferences = xml.attrib.showStatDifferences == "true"
	end
	self:ResetUndo()
end

function ItemsTabClass:Save(xml)
	xml.attrib = {
		activeItemSet = tostring(self.activeItemSetId),
		useSecondWeaponSet = tostring(self.activeItemSet.useSecondWeaponSet),
		showStatDifferences = tostring(self.showStatDifferences),
	}
	for _, id in ipairs(self.itemOrderList) do
		local item = self.items[id]
		local child = {
			elem = "Item",
			attrib = {
				id = tostring(id),
				variant = item.variant and tostring(item.variant),
				variantAlt = item.variantAlt and tostring(item.variantAlt),
				variantAlt2 = item.variantAlt2 and tostring(item.variantAlt2),
				variantAlt3 = item.variantAlt3 and tostring(item.variantAlt3),
				variantAlt4 = item.variantAlt4 and tostring(item.variantAlt4),
				variantAlt5 = item.variantAlt5 and tostring(item.variantAlt5)
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
		for _, modLine in ipairs(item.crucibleModLines) do
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
		for _, slot in ipairs(self.orderedSlots) do
			if not slot.nodeId then
				local itemSlot = itemSet[slot.slotName]
				if itemSlot then
					t_insert(child, { elem = "Slot", attrib = { name = slot.slotName, itemId = tostring(itemSlot.selItemId), itemPbURL = itemSlot.pbURL or "", active = itemSlot.active and "true" }})
				end
			end
		end
		for _, slot in ipairs(self.orderedSlots) do
			if slot.nodeId and self.build.spec.allocNodes[slot.nodeId] then
				t_insert(child, { elem = "SocketIdURL", attrib = { name = slot.slotName, nodeId = tostring(slot.nodeId), itemPbURL = itemSet[slot.nodeId] and itemSet[slot.nodeId].pbURL or ""}})
			end
		end
		t_insert(xml, child)
	end
	if self.tradeQuery.statSortSelectionList then
		local parent = {
			elem = "TradeSearchWeights"
		}
		for _, statSort in ipairs(self.tradeQuery.statSortSelectionList) do
			if statSort.weightMult and statSort.weightMult > 0 then
				local child = {
				elem = "Stat",
				attrib = {
					label = statSort.label,
					stat = statSort.stat,
					weightMult = s_format("%.2f", tostring(statSort.weightMult))
				}
			}
			t_insert(parent, child)
			end
		end
		t_insert(xml, parent)
	end
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

	for _, event in ipairs(inputEvents) do
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
			elseif event.key == "d" and IsKeyDown("CTRL") then
				self.showStatDifferences = not self.showStatDifferences
				self.build.buildFlag = true
			end
		end
	end
	self:ProcessControlsInput(inputEvents, viewPort)
	for _, event in ipairs(inputEvents) do
		if event.type == "KeyUp" then
			if self.controls.scrollBarV:IsScrollDownKey(event.key) then
				if self.controls.scrollBarV:IsMouseOver() or not self.controls.scrollBarH:IsShown() then
					self.controls.scrollBarV:Scroll(1)
				else
					self.controls.scrollBarH:Scroll(1)
				end
			elseif self.controls.scrollBarV:IsScrollUpKey(event.key) then
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
		local title = itemSet.title or "Default"
		t_insert(newItemList, title)
		if itemSetId == self.viewItemSetId then
			self.controls.setSelect.selIndex = index
		end
	end
	self.controls.setSelect:SetList(newItemList)

	if self.displayItem then
		local x, y = self.controls.displayItemTooltipAnchor:GetPos()
		self.displayItemTooltip:Draw(x, y, nil, nil, viewPort)

		-- Toggle mods
		local cursorX, cursorY = GetCursorPos()
		for _, line in ipairs(self.displayItemTooltip.lines) do
			if line.modLine and line.bounds then
				local b = line.bounds
				if cursorX >= b.x and cursorX <= b.x + b.width and cursorY >= b.y and cursorY <= b.y + b.height then
					SetDrawColor(1, 1, 1, 0.15)
					DrawImage(nil, b.x, b.y, b.width, b.height)
					SetDrawColor(1, 1, 1)

					for id, event in ipairs(inputEvents) do
						if event.type == "KeyDown" and event.key:match("BUTTON") then
							inputEvents[id] = nil
							self:ToggleDisplayItemModLine(line.modLine)
							break
						end
					end
				end
			end
		end
	end

	self:UpdateSockets()

	if main.portraitMode then
		self.controls.itemList:SetAnchor("TOPRIGHT", self.lastSlot, "BOTTOMRIGHT", 0, 40)
	else
		self.controls.itemList:SetAnchor("TOPLEFT", self.controls.setManage, "TOPRIGHT", 20, 20)
	end
	self.controls.craftDisplayItem:SetAnchor("TOPLEFT", main.portraitMode and self.controls.setManage or self.controls.itemList, "TOPRIGHT", 20, main.portraitMode and 0 or -20)
	self.anchorDisplayItem:SetAnchor("TOPLEFT", main.portraitMode and self.controls.setManage or self.controls.itemList, "TOPRIGHT", 20, main.portraitMode and 0)

	self:DrawControls(viewPort)
	if self.controls.scrollBarH:IsShown() then
		self.controls.scrollBarH:Draw(viewPort)
	end
	if self.controls.scrollBarV:IsShown() then
		self.controls.scrollBarV:Draw(viewPort)
	end

	self.controls.specSelect:SetList(self.build.treeTab:GetSpecList())
end

function ItemsTabClass:GetPlayerItemSetOrderList()
	local playerSets = { }
	for _, itemSetId in ipairs(self.itemSetOrderList) do
		-- Skip the auto-created auxiliary Mercenary equipment set, not any set
		-- the Mercenary happens to be wearing.
		if not MercenaryTools.isAuxiliaryMercenaryItemSet(itemSetId, self) then
			t_insert(playerSets, itemSetId)
		end
	end
	return playerSets
end

function ItemsTabClass:GetMinionItemSetOrderList()
	return self.itemSetOrderList
end

function ItemsTabClass:GetVisibleItemSet()
	return self.viewItemSet
end

-- Changes weapon set I/II on the currently viewed item set.
-- The player's selected main skill only follows this change when that set is actually equipped.
function ItemsTabClass:SetVisibleWeaponSet(useSecond)
	local visibleItemSet = self:GetVisibleItemSet()
	if not visibleItemSet then
		return
	end
	local wantSecond = useSecond and true or false
	if (visibleItemSet.useSecondWeaponSet and true or false) == wantSecond then
		return
	end
	visibleItemSet.useSecondWeaponSet = wantSecond
	self:AddUndoState()
	self.build.buildFlag = true
	if visibleItemSet ~= self.activeItemSet then
		return
	end
	local fromSet = useSecond and 1 or 2
	local toSet = useSecond and 2 or 1
	local mainSocketGroup = self.build.skillsTab.socketGroupList[self.build.mainSocketGroup]
	local fromSlot = mainSocketGroup and mainSocketGroup.slot and self.slots[mainSocketGroup.slot]
	if fromSlot and fromSlot.weaponSet == fromSet then
		for index, socketGroup in ipairs(self.build.skillsTab.socketGroupList) do
			local toSlot = socketGroup.slot and self.slots[socketGroup.slot]
			if toSlot and toSlot.weaponSet == toSet then
				self.build.mainSocketGroup = index
				break
			end
		end
	end
end

function ItemsTabClass:GetVisibleItemSlots()
	return self.orderedSlots
end

function ItemsTabClass:GetItemSetSlotName(slotName)
	return slotName
end

function ItemsTabClass:GetItemSetSlot(itemSet, slotName)
	return itemSet and itemSet[slotName]
end

function ItemsTabClass:GetVisibleSlotName(slotName)
	return slotName
end

function ItemsTabClass:IsItemSetReferenced(itemSetId)
	local mercenaryTab = self.build.mercenaryTab
	if mercenaryTab and mercenaryTab.itemSetId == itemSetId then
		return true
	end
	for _, socketGroup in ipairs(self.build.skillsTab and self.build.skillsTab.socketGroupList or { }) do
		for _, gem in ipairs(socketGroup.gemList or { }) do
			if gem.skillMinionItemSet == itemSetId or gem.skillMinionItemSetCalcs == itemSetId then
				return true
			end
		end
	end
	return false
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
	for _, slot in ipairs(self.orderedSlots) do
		if not slot.nodeId then
			itemSet[slot.slotName] = { selItemId = 0 }
		end
	end
	self.itemSets[itemSet.id] = itemSet
	return itemSet
end

function ItemsTabClass:ItemCalculationOverride(slotName, item)
	return MercenaryTools.itemCalculationOverride(self.viewItemSetId, slotName, item, self)
end

function ItemsTabClass:SetViewItemSet(itemSetId, comparisonActor)
	local itemSet = self.itemSets[itemSetId]
	if not itemSet then
		return false
	end
	self.viewItemSetId = itemSet.id
	self.viewItemSet = itemSet
	if comparisonActor == "MERCENARY" or comparisonActor == "PLAYER" then
		self.viewComparisonActor = comparisonActor
	else
		self.viewComparisonActor = nil
	end
	self.build.buildFlag = true
	self:PopulateSlots()
	self:UpdateSockets()
	return true
end

-- Changes the active player item set. Missing IDs are rejected.
-- Pass changeView == false to equip without switching the Items tab's viewed set.
function ItemsTabClass:SetActiveItemSet(itemSetId, changeView)
	local itemSet = self.itemSets[itemSetId]
	if not itemSet then
		return false
	end
	self.activeItemSetId = itemSetId
	self.activeItemSet = itemSet
	if changeView ~= false then
		self.viewItemSetId = itemSetId
		self.viewItemSet = itemSet
		self.viewComparisonActor = nil
	end
	if self.build.configTab and not self.skipConfigItemSetSync then
		self.build.configTab:SyncActorItemSet("player", itemSetId)
	end
	self.build.buildFlag = true
	self:PopulateSlots()
	self:UpdateSockets()
	self.build:SyncLoadouts()
	return true
end

-- Equips the given item in the given item set
function ItemsTabClass:EquipItemInSet(item, itemSetId)
	local itemSet = self.itemSets[itemSetId]
	local slotName = item:GetPrimarySlot()
	slotName = self:GetItemSetSlotName(slotName, itemSet)
	local slot = self.slots[slotName]
	if slot and slot.weaponSet == 1 and itemSet.useSecondWeaponSet then
		-- Redirect to second weapon set
		slotName = slotName .. " Swap"
	end
	if not item.id or not self.items[item.id] then
		item = new("Item"):Item(item.raw)
		self:AddItem(item, true)
	end
	local altSlot = slotName:gsub("1","2")
	if IsKeyDown("SHIFT") then
		-- Redirect to second slot if possible
		if self:IsItemValidForSlot(item, altSlot, itemSet) then
			slotName = altSlot
		end
	end
	if itemSet == self:GetVisibleItemSet() and self.slots[slotName] then
		self.slots[slotName]:SetSelItemId(item.id, itemSet)
	else
		local itemSlot = itemSet[self:GetItemSetSlotName(slotName, itemSet)]
		if itemSlot then itemSlot.selItemId = item.id end
		local altItemSlot = itemSet[self:GetItemSetSlotName(altSlot, itemSet)]
		if altItemSlot and altItemSlot.selItemId ~= 0 and not self:IsItemValidForSlot(self.items[altItemSlot.selItemId], altSlot, itemSet) then
			altItemSlot.selItemId = 0
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
end

-- Updates the status and position of the socket controls
function ItemsTabClass:UpdateSockets()
	self.lastSlot = self.slots[baseSlots[#baseSlots]]
	if not self.build.spec then return end
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
	for index, nodeId in ipairs(activeSocketList) do
		self.sockets[nodeId].label = "Socket #"..index
		self.lastSlot = self.sockets[nodeId]
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
			local visibleItemSet = self:GetVisibleItemSet()
			for _, slot in ipairs(self:GetVisibleItemSlots()) do
				if not slot.nodeId and slot.selItemId == 0 and slot:IsShown() and self:IsItemValidForSlot(item, slot.slotName, visibleItemSet) then
					slot:SetSelItemId(item.id, visibleItemSet)
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

-- Given one half of a Forbidden Flame/Flesh pair, adds the other half with the same notable
-- Both jewels are generated from the same sorted class/notable list
function ItemsTabClass:AddForbiddenJewelCounterpart(item)
	local otherTitle = item and item.title and forbiddenJewelCounterpart[item.title]
	if not otherTitle or main.uniqueDB.loading or not item.variantList or not item.variant then
		return
	end
	local variantName = item.variantList[item.variant]
	if not variantName then
		return
	end

	for _, other in pairs(self.items) do
		if other.title == otherTitle and other.variantList and other.variantList[other.variant] == variantName then
			return
		end
	end

	local dbItem
	for _, unique in pairs(main.uniqueDB.list) do
		if unique.title == otherTitle then
			dbItem = unique
			break
		end
	end
	if not dbItem then
		return
	end

	local newItem = new("Item"):Item(dbItem.raw)
	local variantIndex
	for index, name in ipairs(newItem.variantList or { }) do
		if name == variantName then
			variantIndex = index
			break
		end
	end
	if not variantIndex then
		return
	end
	newItem.variant = variantIndex
	newItem:BuildAndParseRaw()
	newItem:NormaliseQuality()
	self:AddItem(newItem, true)
	return newItem
end

-- Keeps the Forbidden jewels in sync: manually editing one jewel moves the other counterpart to the same notable
function ItemsTabClass:UpdateForbiddenJewelCounterpart(oldItem, item)
	local otherTitle = item and item.title and forbiddenJewelCounterpart[item.title]
	if not otherTitle or not oldItem or oldItem.title ~= item.title then
		return
	end
	if not (item.variantList and item.variant and oldItem.variantList and oldItem.variant) then
		return
	end
	local oldName = oldItem.variantList[oldItem.variant]
	local newName = item.variantList[item.variant]
	if not oldName or not newName or oldName == newName then
		return
	end

	for _, other in pairs(self.items) do
		if other.id ~= item.id and other.title == otherTitle and other.variantList and other.variantList[other.variant] == oldName then
			for index, name in ipairs(other.variantList) do
				if name == newName then
					other.variant = index
					other:BuildAndParseRaw()
					other:BuildModList()
					self.build.buildFlag = true
					break
				end
			end
		end
	end
end

-- Adds the current display item to the build's item list
function ItemsTabClass:AddDisplayItem(noAutoEquip)
	local item = self.displayItem
	local oldItem = item and item.id and self.items[item.id]
	-- Add it to the list and clear the current display item
	self:AddItem(item, noAutoEquip)
	self:SetDisplayItem()

	self:UpdateForbiddenJewelCounterpart(oldItem, item)
	self:AddForbiddenJewelCounterpart(item)

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
function ItemsTabClass:DeleteItem(item, deferUndoState)
	for slotName, slot in pairs(self.slots) do
		if slot.selItemId == item.id then
			slot.selItemId = 0
			self.build.buildFlag = true
		end
		if not slot.nodeId then
			for _, itemSet in pairs(self.itemSets) do
				local itemSlot = itemSet[slotName]
				if itemSlot and itemSlot.selItemId == item.id then
					itemSlot.selItemId = 0
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
		local rebuildClusterJewelGraphs = false
		for nodeId, itemId in pairs(spec.jewels) do
			if itemId == item.id then
				spec.jewels[nodeId] = 0
				rebuildClusterJewelGraphs = true
				-- Deallocate all nodes that required this jewel
				if spec.nodes[nodeId] then
					for depNodeId, depNode in ipairs(spec.nodes[nodeId].depends) do
						depNode.alloc = false
						spec.allocNodes[depNodeId] = nil
					end
					spec.nodes[nodeId].alloc = false
					spec.allocNodes[nodeId] = nil
				end
			end
		end
		if rebuildClusterJewelGraphs and not deferUndoState then
			spec:BuildClusterJewelGraphs()
		end
	end
	self.items[item.id] = nil
	if not deferUndoState then
		self:PopulateSlots()
		self:AddUndoState()
	end
end

function ItemsTabClass:CopyAnointsAndEldritchImplicits(newItem, copyEldritchImplicits, overwrite, sourceSlotName)
	local newItemType = sourceSlotName or (newItem.base.weapon and "Weapon 1" or newItem.base.type)
	local itemSet = self:GetVisibleItemSet()
	local itemSetSlotName = self:GetItemSetSlotName(newItemType, itemSet)
	local itemSetSlot = itemSet and itemSet[itemSetSlotName]
	if itemSetSlot then
		local currentItem = itemSetSlot.selItemId and self.items[itemSetSlot.selItemId]
		-- if you don't have an equipped item that matches the type of the newItem, no need to do anything
		if currentItem then
			-- if the new item is anointable and does not have an anoint and your current respective item does, apply that anoint to the new item
			if isAnointable(newItem) and (#newItem.enchantModLines == 0 or overwrite) and itemSetSlot.selItemId > 0 then
				local currentAnoint = currentItem.enchantModLines
				if currentAnoint and #currentAnoint == 1 then -- skip if amulet has more than one anoint e.g. Stranglegasp
					newItem.enchantModLines = currentAnoint
				end
			end
			-- if the new item is a non-corrupted Normal, Magic, or Rare Helmet, Body Armour, Gloves, or Boots and does not have any influence
			-- and your current respective item is Eater and/or Exarch, apply those implicits and influence to the new item
			local eldritchBaseTypes = { "Helmet", "Body Armour", "Gloves", "Boots" }
			local eldritchRarities = { "NORMAL", "MAGIC", "RARE" }
			for _, influence in ipairs(itemLib.influenceInfo.default) do
				if newItem[influence.key] then
					return
				end
			end

			local modifiableItem = not (newItem.corrupted or newItem.mirrored)
			if copyEldritchImplicits and isValueInTable(eldritchBaseTypes, newItem.base.type) and isValueInTable(eldritchRarities, newItem.rarity)
				and (#newItem.implicitModLines == 0 or overwrite) and modifiableItem and (currentItem.cleansing or currentItem.tangle) and currentItem.implicitModLines then
					newItem.implicitModLines = currentItem.implicitModLines
					newItem.tangle = currentItem.tangle
					newItem.cleansing = currentItem.cleansing
			end

			-- harvest and heist enchantments on modifiable body armour or weapons
			if (newItem.base.weapon or newItem.base.type == "Body Armour") and (#newItem.enchantModLines == 0 or overwrite)	and itemSetSlot.selItemId > 0 and modifiableItem and currentItem.enchantModLines then
				newItem.enchantModLines = currentItem.enchantModLines
			end

			newItem:BuildAndParseRaw()
		end
	end
end

-- Attempt to create a new item from the given item raw text and sets it as the new display item
function ItemsTabClass:CreateDisplayItemFromRaw(itemRaw, normalise)
	local newItem = new("Item"):Item(itemRaw)
	if newItem.base then
		if normalise then
			self:CopyAnointsAndEldritchImplicits(newItem, main.migrateEldritchImplicits, false)
			newItem:NormaliseQuality()
			newItem:BuildModList()
		end
		self:SetDisplayItem(newItem)
	end
end

function ItemsTabClass:SelectDisplayItemVariant(index, value, legacyField, control)
	if self.displayItem.usesVariantGroups then
		if not value or not value.variantId then
			return
		end
		self.displayItem.variantGroupSelections[control.variantGroupId] = value.variantId
		self.displayItem:NormaliseVariantSelections()
	else
		self.displayItem[legacyField] = index
	end
	self.displayItem:BuildAndParseRaw()
	self:UpdateDisplayItemVariantControls()
	self:UpdateDisplayItemTooltip()
	self:UpdateDisplayItemRangeLines()
end

function ItemsTabClass:UpdateDisplayItemVariantControls()
	local item = self.displayItem
	local controls = {
		self.controls.displayItemVariant,
		self.controls.displayItemAltVariant,
		self.controls.displayItemAltVariant2,
		self.controls.displayItemAltVariant3,
		self.controls.displayItemAltVariant4,
		self.controls.displayItemAltVariant5,
	}
	for _, control in ipairs(controls) do
		control.newVariantVisible = false
	end
	if not item or not item.usesVariantGroups then
		return
	end

	self.controls.displayItemVersion.list = item.versionList or { }
	self.controls.displayItemVersion.selIndex = item.selectedVersion or 1
	self.controls.displayItemVersion:CheckDroppedWidth(true)
	local controlIndex = 1
	for groupId in pairsSortByKey(item.variantGroups) do
		local eligibleOptions = item:GetVariantGroupOptions(groupId, false)
		if #eligibleOptions > 0 then
			local control = controls[controlIndex]
			if not control then
				ConPrintf("Item '%s' has more than 6 variant groups", item.name)
				break
			end
			local availableOptions = item:GetVariantGroupOptions(groupId, true)
			local list = { }
			local selectedIndex
			for _, variantId in ipairs(availableOptions) do
				t_insert(list, {
					label = item.variantList[variantId],
					variantId = variantId,
				})
				if item.variantGroupSelections[groupId] == variantId then
					selectedIndex = #list
				end
			end
			if #list == 0 then
				t_insert(list, {
					label = "No available variants",
				})
			end
			control.list = list
			control.selIndex = selectedIndex or 1
			control.variantGroupId = groupId
			control.newVariantVisible = true
			control.newVariantEnabled = #availableOptions > 1
			control:CheckDroppedWidth(true)
			controlIndex = controlIndex + 1
		end
	end
end

-- Sets the display item to the given item
function ItemsTabClass:SetDisplayItem(item)
	self.displayItem = item
	if item then
		-- Update the display item controls
		self:UpdateDisplayItemTooltip()
		self.snapHScroll = "RIGHT"

		if item.usesVariantGroups then
			self:UpdateDisplayItemVariantControls()
		else
			self.controls.displayItemVariant.list = item.variantList
			self.controls.displayItemVariant.selIndex = item.variant
			self.controls.displayItemVariant:CheckDroppedWidth(true)
		end
		if not item.usesVariantGroups and item.hasAltVariant then
			self.controls.displayItemAltVariant.list = item.variantList
			self.controls.displayItemAltVariant.selIndex = item.variantAlt
			self.controls.displayItemAltVariant:CheckDroppedWidth(true)
		end
		if not item.usesVariantGroups and item.hasAltVariant2 then
			self.controls.displayItemAltVariant2.list = item.variantList
			self.controls.displayItemAltVariant2.selIndex = item.variantAlt2
			self.controls.displayItemAltVariant2:CheckDroppedWidth(true)
		end
		if not item.usesVariantGroups and item.hasAltVariant3 then
			self.controls.displayItemAltVariant3.list = item.variantList
			self.controls.displayItemAltVariant3.selIndex = item.variantAlt3
			self.controls.displayItemAltVariant3:CheckDroppedWidth(true)
		end
		if not item.usesVariantGroups and item.hasAltVariant4 then
			self.controls.displayItemAltVariant4.list = item.variantList
			self.controls.displayItemAltVariant4.selIndex = item.variantAlt4
			self.controls.displayItemAltVariant4:CheckDroppedWidth(true)
		end
		if not item.usesVariantGroups and item.hasAltVariant5 then
			self.controls.displayItemAltVariant5.list = item.variantList
			self.controls.displayItemAltVariant5.selIndex = item.variantAlt5
			self.controls.displayItemAltVariant5:CheckDroppedWidth(true)
		end
		self:UpdateSocketControls()
		if item.crafted then
			self:UpdateAffixControls()
		end

		-- Set both influence dropdowns
		local influence1 = 1
		local influence2 = 1
		local influenceDisplayList = { "Influence" }
		for i, curInfluenceInfo in ipairs((item.canHaveEldritchInfluence or item.type == "Helmet" or item.type == "Body Armour" or item.type == "Gloves" or item.type == "Boots") and itemLib.influenceInfo.all or itemLib.influenceInfo.default) do
			influenceDisplayList[i + 1] = curInfluenceInfo.display
		end
		self.controls.displayItemInfluence.list = influenceDisplayList
		self.controls.displayItemInfluence2.list = influenceDisplayList
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
		-- Initialising these controls must not re-craft the parsed item.
		self.controls.displayItemInfluence:SetSel(influence1, true)
		self.controls.displayItemInfluence2:SetSel(influence2, true)
		self.controls.displayItemQualityEdit:SetText(item.quality)
		self.controls.displayItemCatalyst:SetSel((item.catalyst or 0) + 1, true)
		if item.catalystQuality then
			self.controls.displayItemCatalystQualityEdit:SetText(m_max(item.catalystQuality, 0))
		else
			self.controls.displayItemCatalystQualityEdit:SetText(0)
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
	self.displayItemTooltip.center = true
end

function ItemsTabClass:ToggleDisplayItemModLine(modLine)
	if not self.displayItem or not modLine then
		return
	end
	modLine.disabled = not modLine.disabled
	self.displayItem:BuildAndParseRaw()
	self:UpdateDisplayItemTooltip()
	self:UpdateDisplayItemRangeLines()
	self:UpdateCustomControls()
	if self.displayItem.crafted then
		self:UpdateAffixControls()
	end
	self.build.buildFlag = true
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
	item.clusterJewelNodeCount = m_min(m_max(item.clusterJewelNodeCount or item.clusterJewel.minNodes, item.clusterJewel.minNodes), item.clusterJewel.maxNodes)
	countControl.divCount = item.clusterJewel.maxNodes - item.clusterJewel.minNodes
	countControl.val = (item.clusterJewelNodeCount - item.clusterJewel.minNodes) / (item.clusterJewel.maxNodes - item.clusterJewel.minNodes)

	self:CraftClusterJewel()
end

function ItemsTabClass:CraftClusterJewel()
	local item = self.displayItem
	wipeTable(item.enchantModLines)
	t_insert(item.enchantModLines, { line = "Adds "..(item.clusterJewelNodeCount or item.clusterJewel.minNodes).." Passive Skills", crafted = true })
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
	local prefixLimit = item.prefixes.limit or (item.affixLimit / 2)
	local ignoreModType = item.rareLikeUnique and item.rareLikeUnique.ignoreModType
	local powerCache = {}
	for i = 1, item.affixLimit do
		if i <= prefixLimit then
			local modType = "Prefix"
			if ignoreModType then
				modType = nil
			end
			self:UpdateAffixControl(self.controls["displayItemAffix" .. i], item, modType, "prefixes", i, powerCache)
		else
			self:UpdateAffixControl(self.controls["displayItemAffix" .. i], item, "Suffix", "suffixes", i - prefixLimit, powerCache)
		end
	end
	-- The custom affixes may have had their indexes changed, so the custom control UI is also rebuilt so that it will
	-- reference the correct affix index.
	self:UpdateCustomControls()
end

function ItemsTabClass:UpdateAffixControl(control, item, affixType, outputTable, outputIndex, powerCache)
	local extraTags = { }
	local excludeGroups = { }
	local allowDuplicateGroups = item.rareLikeUnique and item.rareLikeUnique.allowDuplicateGroups
	for _, table in ipairs({"prefixes","suffixes"}) do
		for index = 1, (item[table].limit or (item.affixLimit / 2)) do
			if index ~= outputIndex or table ~= outputTable then
				local mod = item.affixes[item[table][index] and item[table][index].modId]
				if mod then
					if mod.group and not allowDuplicateGroups then
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
	local selAffix = item[outputTable][outputIndex] and item[outputTable][outputIndex].modId
	local affixList = { }
	local retainedAffixes = { }
	for modId, mod in pairs(item.affixes) do
		if (not affixType or (mod.type == affixType)) and not excludeGroups[mod.group] and not item:CheckIfModIsDelve(mod) then
			if item:CanHaveMod(mod, extraTags) then
				t_insert(affixList, modId)
			elseif modId == selAffix then
				t_insert(affixList, modId)
				retainedAffixes[modId] = true
			end
		end
	end
	table.sort(affixList, function(a, b)
		local modA = item.affixes[a]
		local modB = item.affixes[b]
		for i = 1, m_max(#modA, #modB) do
			if not modA[i] then
				return true
			elseif not modB[i] then
				return false
			elseif modA.statOrder[i] ~= modB.statOrder[i] then
				return modA.statOrder[i] < modB.statOrder[i]
			end
		end
		if modA.level ~= modB.level then
			return modA.level < modB.level
		end
		return a < b
	end)
	control.selIndex = 1
	control.list = { "None" }
	control.outputTable = outputTable
	control.outputIndex = outputIndex
	control.slider.shown = false
	control.slider.val = main.defaultItemAffixQuality or 0.5
	local selAffix = item[outputTable][outputIndex].modId
	local lastSeries
	-- combine runs of modifiers to one group, which will only take up one row
	-- in the list
	for _, modId in ipairs(affixList) do
		local mod = item.affixes[modId]
		if not lastSeries or not tableDeepEquals(lastSeries.statOrder, mod.statOrder) then
			local modString = table.concat(mod, "/")
			lastSeries = {
				label = modString,
				modList = {},
				haveRange = modString:match("%(%-?[%d%.]+%-%-?[%d%.]+%)"),
				statOrder = mod.statOrder,
			}
			t_insert(control.list, lastSeries)
		end
		-- cluster jewel mods retained after changing the cluster type
		if retainedAffixes[modId] and item.clusterJewel then
			lastSeries.label = "^8[Retained] " .. lastSeries.label
		end
		t_insert(lastSeries.modList, modId)
		if #lastSeries.modList == 2 then
			lastSeries.label = lastSeries.label:gsub("%(%-?[%d%.]+%-%-?[%d%.]+%)", "#"):gsub("%-?%d+%.?%d*", "#")
			lastSeries.haveRange = true
		end
	end

	local sortOption = self.controls.craftingSorting:GetSelValue()
	-- sort modifier groups by power
	if sortOption.stat and self.controls.craftingSortingLabel.shown() then
		local calcFunc = self.build.calcsTab:GetMiscCalculator()
		local slotName = self.displayItem:GetPrimarySlot()
		local testSubject = new("Item"):Item(self.displayItem:BuildRaw())
		local controlPowerCache = powerCache
		if selAffix and selAffix ~= "None" then
			testSubject[outputTable][outputIndex] = { modId = "None" }
			testSubject:Craft()
			controlPowerCache = { }
		end
		local function pickModifierFromList(modList)
			-- pick mid tier modifier from a group
			if #modList == 1 then
				return modList[1]
			else
				return modList[1 + round((#modList - 1) * main.defaultItemAffixQuality)]
			end
		end
		local function getPower(modId)
			if controlPowerCache[modId] then
				return controlPowerCache[modId]
			end
			local mod = testSubject.affixes[modId]

			local modCount = #mod
			-- magnitude scaling happens during item parsing, which means we
			-- can't use the faster path where items don't need to be
			-- re-parsed. note that this wouldn't be correct if we were
			-- adding a mod magnitude mod here, but currently all mod
			-- magnitude mods are custom modifiers and so this works
			local power
			if (#testSubject.modMagnitudeMods > 0) or (testSubject.catalyst and testSubject.catalyst > 0) then
				local originalItem = testSubject:BuildRaw()
				for _, subMod in ipairs(mod) do
					local modLine = { line = subMod, modTags = mod.modTags }
					if mod.type then
						modLine[mod.type] = true
					end
					t_insert(testSubject.explicitModLines, modLine)
				end
				testSubject:BuildAndParseRaw()
				power = data.powerStatList.GetFromOutput(
					calcFunc(self:ItemCalculationOverride(slotName, testSubject)),
					sortOption
				)
				testSubject = new("Item"):Item(originalItem)
			else
				for _, line in ipairs(mod) do
					local rangedLine = itemLib.applyRange(line, main.defaultItemAffixQuality or 0.5, 1, 1)
					local modList, extra = modLib.parseMod(rangedLine)
					local modLine = { line = line, modList = modList, extra = extra, modTags = mod.modTags }
					if mod.type then
						modLine[mod.type] = true
					end
					t_insert(testSubject.explicitModLines, modLine)
				end

				testSubject:BuildModList()
				power = data.powerStatList.GetFromOutput(
					calcFunc(self:ItemCalculationOverride(slotName, testSubject)),
					sortOption
				)
				for _ = 1, modCount do
					t_remove(testSubject.explicitModLines, #testSubject.explicitModLines)
				end
			end
			controlPowerCache[modId] = power
			return power
		end
		table.sort(control.list, function(a, b)
			-- keep "None" as the first option
			if not a.modList then
				return true
			elseif not b.modList then
				return false
			end

			local modIdA = pickModifierFromList(a.modList)
			local modIdB = pickModifierFromList(b.modList)

			return getPower(modIdA) > getPower(modIdB)
		end)
	end
	local function findSelectedIdx()
		for i, entry in ipairs(control.list) do
			if entry.modList then
				for _, modId in ipairs(entry.modList) do
					if selAffix == modId then
						return i
					end
				end
			else
				if selAffix == entry then
					return i
				end
			end
		end
		return 1
	end
	control.selIndex = findSelectedIdx()
	if control.list[control.selIndex].haveRange then
		control.slider.divCount = #control.list[control.selIndex].modList
		local index = isValueInArray(control.list[control.selIndex].modList, selAffix)
		-- Imported legacy rolls can sit outside the current 0-1 affix range.
		-- Keep that value on the affix, but show the nearest slider endpoint.
		local affixRange = item[outputTable][outputIndex].range
		local range = m_min(1, m_max(0, type(affixRange) == "table" and affixRange[1] or affixRange or 0.5))
		-- Avoid exact integer boundary that slider:GetDivVal's ceil would assign to the previous segment
		if range == 0 and index > 1 then
			range = 1e-4
		end
		control.slider.val = (index - 1 + range) / control.slider.divCount
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
	local modLines = copyTable(item.explicitModLines)
	if item.crucibleModLines and #item.crucibleModLines > 0 then
		for _, line in ipairs(item.crucibleModLines) do
			t_insert(modLines, line)
		end
	end
	if item.rareLikeUnique or item.rarity == "MAGIC" or item.rarity == "RARE" or (item.crucibleModLines and #item.crucibleModLines > 0) then
		for index, modLine in ipairs(modLines) do
			if modLine.custom or modLine.crafted or modLine.crucible then
				local line = itemLib.formatModLine(modLine)
				if line then
					if not self.controls["displayItemCustomModifierRemove"..i] then
						self.controls["displayItemCustomModifierRemove"..i] = new("ButtonControl"):ButtonControl({"TOPLEFT",self.controls.displayItemSectionCustom,"TOPLEFT"}, {0, i * 22 + 4, 70, 20}, "^7Remove")
						self.controls["displayItemCustomModifier"..i] = new("LabelControl"):LabelControl({"LEFT",self.controls["displayItemCustomModifierRemove"..i],"RIGHT"}, {65, 0, 0, 16})
						self.controls["displayItemCustomModifierLabel"..i] = new("LabelControl"):LabelControl({"LEFT",self.controls["displayItemCustomModifierRemove"..i],"RIGHT"}, {5, 0, 0, 16})
					end
					self.controls["displayItemCustomModifierRemove"..i].shown = true
					local label = itemLib.formatModLine(modLine)
					if DrawStringCursorIndex(16, "VAR", label, 330, 10) < #label then
						label = label:sub(1, DrawStringCursorIndex(16, "VAR", label, 310, 10)) .. "..."
					end
					self.controls["displayItemCustomModifier"..i].label = label
					self.controls["displayItemCustomModifierLabel"..i].label = modLine.crafted and " ^7Crafted:" or modLine.crucible and "^7Crucible:" or " ^7Custom:"
					self.controls["displayItemCustomModifierRemove"..i].onClick = function()
						if index > #item.explicitModLines then
							t_remove(item.crucibleModLines, index - #item.explicitModLines)
						else
							t_remove(item.explicitModLines, index)
						end
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
	while self.controls["displayItemCustomModifierRemove"..i] do
		self.controls["displayItemCustomModifierRemove"..i].shown = false
		i = i + 1
	end
end

-- Updates the range line dropdown and range slider for the current display item
function ItemsTabClass:UpdateDisplayItemRangeLines()
	if self.displayItem and self.displayItem.rangeLineList[1] then
		wipeTable(self.controls.displayItemRangeLine.list)
		for _, modLine in ipairs(self.displayItem.rangeLineList) do
			if (modLine.modId and modLine.newModId) or modLine.range then
				t_insert(self.controls.displayItemRangeLine.list, { modLine = modLine, label = modLine.line })
			end
		end
		self.controls.displayItemRangeLine.selIndex = 1
		self.controls.displayItemRangeSlider.val = self.displayItem.rangeLineList[1].range
	end
end

local function checkLineForAllocates(line, nodes)
	if nodes and string.match(line, "Allocates") then
		local nodeId = tonumber(string.match(line, "%d+"))
		if nodes[nodeId] then
			return "Allocates "..nodes[nodeId].name
		end
	end
	return line
end

function ItemsTabClass:AddModComparisonTooltip(tooltip, mod, replaceImplicits)
	local slotName = self.displayItem:GetPrimarySlot()
	local newItem = new("Item"):Item(self.displayItem:BuildRaw())
	local targetLines = replaceImplicits and newItem.implicitModLines or newItem.explicitModLines
	if replaceImplicits then
		wipeTable(targetLines)
	end

	for _, subMod in ipairs(mod) do
		local modLine = { line = checkLineForAllocates(subMod, self.build.spec.nodes), modTags = mod.modTags }
		if mod.type then
			modLine[mod.type] = true
		end
		t_insert(targetLines, modLine)
	end

	newItem:BuildAndParseRaw()

	local calcFunc = self.build.calcsTab:GetMiscCalculator()
	local outputBase = calcFunc(self:ItemCalculationOverride(slotName, self.displayItem))
	local outputNew = calcFunc(self:ItemCalculationOverride(slotName, newItem))
	self.build:AddStatComparesToTooltip(tooltip, outputBase, outputNew, "\nAdding this mod will give: ")
end

-- Returns the first slot in which the given item is equipped.
-- Actively worn equipment returns (slot) with no item set; other sets return (slot, itemSet).
function ItemsTabClass:GetEquippedSlotForItem(item)
	for _, slot in ipairs(self.orderedSlots) do
		if not slot.inactive then
			if slot.nodeId then
				if slot.selItemId == item.id then
					return slot
				end
			else
				local activeSlot = self.activeItemSet and self.activeItemSet[slot.slotName]
				if activeSlot and activeSlot.selItemId == item.id then
					return slot
				end
			end
		end
	end
	for _, slot in ipairs(self.orderedSlots) do
		if not slot.inactive and not slot.nodeId then
			for _, itemSetId in ipairs(self.itemSetOrderList) do
				if itemSetId ~= self.activeItemSetId then
					local itemSet = self.itemSets[itemSetId]
					local itemSlot = itemSet and itemSet[slot.slotName]
					if itemSlot and itemSlot.selItemId == item.id then
						return slot, itemSet
					end
				end
			end
		end
	end
end

function ItemsTabClass:GetComparisonSlotNameForItem(item)
	local equippedSlot = self:GetEquippedSlotForItem(item)
	if equippedSlot then
		return equippedSlot.slotName
	end
	if item.type == "Jewel" then
		for _, slot in ipairs(self.orderedSlots) do
			if not slot.inactive and slot.selItemId == 0 and slot:IsShown() and self:IsItemValidForSlot(item, slot.slotName) then
				return slot.slotName
			end
		end
	end
	return item:GetPrimarySlot()
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
		elseif node.charmSocket or item.base.subType == "Charm" then
			-- Charm sockets can only have charms, and charms can only be in charm sockets
			if node.charmSocket and item.base.subType == "Charm" then
				return true
			end
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
	elseif item.type == "Tincture" and slotType == "Flask" then
		return true
	elseif item.type == "Jewel" and item.base.subType == "Abyss" and slotName:match("Abyssal Socket") then
		return true
	elseif slotName == "Weapon 1" or slotName == "Weapon 1 Swap" or slotName == "Weapon" then
		return item.base.weapon ~= nil
	elseif slotName == "Weapon 2" or slotName == "Weapon 2 Swap" then
		local weapon1SlotName = slotName == "Weapon 2" and "Weapon 1" or "Weapon 1 Swap"
		local weapon1Slot = itemSet and itemSet[weapon1SlotName]
		local weapon1Sel = weapon1Slot and weapon1Slot.selItemId or 0
		local weapon1Type = self.items[weapon1Sel] and self.items[weapon1Sel].base.type or "None"
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
	controls.setList = new("ItemSetListControl"):ItemSetListControl(nil, {-155, 50, 300, 200}, self)
	controls.sharedList = new("SharedItemSetListControl"):SharedItemSetListControl(nil, {155, 50, 300, 200}, self)
	controls.setList.dragTargetList = { controls.sharedList }
	controls.sharedList.dragTargetList = { controls.setList }
	controls.close = new("ButtonControl"):ButtonControl(nil, {0, 260, 90, 20}, "Done", function()
		main:ClosePopup()
	end)
	main:OpenPopup(630, 290, "Manage Item Sets", controls)
end

-- Opens the item crafting popup
function ItemsTabClass:CraftItem()
	local controls = { }
	local function makeItem(base)
		local item = new("Item"):Item()
		item.name = base.name
		item.base = base.base
		item.baseName = base.name
		item.buffModLines = { }
		item.enchantModLines = { }
		item.classRequirementModLines = { }
		item.scourgeModLines = { }
		item.implicitModLines = { }
		item.explicitModLines = { }
		item.crucibleModLines = { }
		if base.base.type == "Amulet" or base.base.type == "Belt" or base.base.type == "Jewel" or base.base.type == "Quiver" or base.base.type == "Ring" or base.base.type == "Graft" then
			item.quality = nil
		else
			item.quality = 0
		end
		local raritySel = controls.rarity.selIndex
		if base.base.flask
				or (base.base.type == "Jewel" and base.base.subType == "Charm")
		 		or base.base.type == "Tincture"
		then
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
	controls.rarityLabel = new("LabelControl"):LabelControl({"TOPRIGHT",nil,"TOPLEFT"}, {50, 20, 0, 16}, "Rarity:")
	controls.rarity = new("DropDownControl"):DropDownControl(nil, {-80, 20, 100, 18}, rarityDropList)
	controls.rarity.selIndex = self.lastCraftRaritySel or 3
	controls.title = new("EditControl"):EditControl(nil, {70, 20, 190, 18}, "", "Name")
	controls.title.shown = function()
		return controls.rarity.selIndex >= 3
	end
	controls.typeLabel = new("LabelControl"):LabelControl({"TOPRIGHT",nil,"TOPLEFT"}, {50, 45, 0, 16}, "Type:")
	controls.type = new("DropDownControl"):DropDownControl({"TOPLEFT",nil,"TOPLEFT"}, {55, 45, 295, 18}, self.build.data.itemBaseTypeList, function(index, value)
		controls.base.list = self.build.data.itemBaseLists[self.build.data.itemBaseTypeList[index]]
		controls.base.selIndex = 1
	end)
	controls.type.selIndex = self.lastCraftTypeSel or 1
	controls.baseLabel = new("LabelControl"):LabelControl({"TOPRIGHT",nil,"TOPLEFT"}, {50, 70, 0, 16}, "Base:")
	controls.base = new("DropDownControl"):DropDownControl({"TOPLEFT",nil,"TOPLEFT"}, {55, 70, 200, 18}, self.build.data.itemBaseLists[self.build.data.itemBaseTypeList[controls.type.selIndex]])
	controls.base.selIndex = self.lastCraftBaseSel or 1
	controls.base.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if mode ~= "OUT" then
			self:AddItemTooltip(tooltip, makeItem(value), nil, true)
		end
	end
	controls.save = new("ButtonControl"):ButtonControl(nil, {-45, 100, 80, 20}, "Create", function()
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
	controls.cancel = new("ButtonControl"):ButtonControl(nil, {45, 100, 80, 20}, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(370, 130, "Craft Item", controls)
end

-- Opens the item text editor popup
function ItemsTabClass:EditDisplayItemText(alsoAddItem)
	local controls = { }
	local function buildRaw()
		local editBuf = controls.edit.buf
		if editBuf:match("^Item Class: .*\nRarity: ") or editBuf:match("^Rarity: ") then
			return editBuf
		else
			return "Rarity: "..controls.rarity.list[controls.rarity.selIndex].rarity.."\n"..controls.edit.buf
		end
	end
	controls.rarity = new("DropDownControl"):DropDownControl(nil, {-190, 10, 100, 18}, rarityDropList)
	controls.edit = new("EditControl"):EditControl(nil, {0, 40, 480, 420}, "", nil, "^%C\t\n", nil, nil, 14)
	if self.displayItem then
		controls.edit:SetText(self.displayItem:BuildRaw():gsub("Rarity: %w+\n",""))
		controls.rarity:SelByValue(self.displayItem.rarity, "rarity")
	else
		controls.rarity.selIndex = 3
	end
	controls.edit.font = "FIXED"
	controls.edit.pasteFilter = sanitiseText
	controls.save = new("ButtonControl"):ButtonControl(nil, {-45, 470, 80, 20}, self.displayItem and "Save" or "Create", function()
		local id = self.displayItem and self.displayItem.id
		self:CreateDisplayItemFromRaw(buildRaw(), not self.displayItem)
		self.displayItem.id = id
		if alsoAddItem then
			self:AddDisplayItem()
		end
		main:ClosePopup()
	end, nil, true)
	controls.save.enabled = function()
		local item = new("Item"):Item(buildRaw())
		return item.base ~= nil
	end
	controls.save.tooltipFunc = function(tooltip)
		tooltip:Clear()
		local item = new("Item"):Item(buildRaw())
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
	controls.cancel = new("ButtonControl"):ButtonControl(nil, {45, 470, 80, 20}, "Cancel", function()
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
	local sortList, sortStats = buildModSortList()
	local function setDefaultSortOrder()
		for index, entry in ipairs(enchantmentList) do
			entry.defaultSortOrder = index
			entry.sortValue = nil
			entry.sortValues = nil
		end
	end
	local function buildEnchantmentList()
		wipeTable(enchantmentList)
		local list = haveSkills and enchantments[skillList[controls.skill and controls.skill.selIndex or 1]] or enchantments
		for _, enchantment in ipairs(list[enchantmentSourceList[controls.enchantmentSource and controls.enchantmentSource.selIndex or 1].name]) do
			t_insert(enchantmentList, { label = enchantment, line = enchantment })
		end
		setDefaultSortOrder()
	end
	if haveSkills then
		buildSkillList(true)
	end
	buildEnchantmentSourceList()
	buildEnchantmentList()
	local function enchantItem(idx, remove)
		local item = new("Item"):Item(self.displayItem:BuildRaw())
		local index = idx or controls.enchantment.selIndex
		item.id = self.displayItem.id
		local entry = enchantmentList[index]
		if remove then
			t_remove(item.enchantModLines, self.enchantSlot)
		elseif entry then
			local line = entry.line
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
				t_insert(item.enchantModLines, self.enchantSlot, { crafted = true, line = line })
			end
		end
		item:BuildAndParseRaw()
		return item
	end
	local function getSortValue(entry, stat, calcFunc, slotName, useFullDPS)
		entry.sortValues = entry.sortValues or { }
		if entry.sortValues[stat] ~= nil then
			return entry.sortValues[stat]
		end
		local item = new("Item"):Item(self.displayItem:BuildRaw())
		item.id = self.displayItem.id
		local line = entry.line
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
			t_insert(item.enchantModLines, self.enchantSlot, { crafted = true, line = line })
		end
		item:BuildAndParseRaw()
		local output = calcFunc(self:ItemCalculationOverride(slotName, item), useFullDPS)
		local value = data.powerStatList.GetFromOutput(output, sortStats[stat])
		entry.sortValues[stat] = value
		return value
	end
	local function applySort(stat, selectFirst)
		if not controls.enchantment or not controls.enchantment:IsShown() then
			return
		end
		local selected = not selectFirst and enchantmentList[controls.enchantment.selIndex] or nil
		if stat then
			local slotName = self.displayItem:GetPrimarySlot()
			local calcFunc = self.build.calcsTab:GetMiscCalculator()
			local useFullDPS = stat == "FullDPS"
			for _, entry in ipairs(enchantmentList) do
				entry.sortValue = getSortValue(entry, stat, calcFunc, slotName, useFullDPS)
			end
			table.sort(enchantmentList, function(a, b)
				if a.sortValue ~= b.sortValue then
					return a.sortValue > b.sortValue
				end
				return (a.defaultSortOrder or 0) < (b.defaultSortOrder or 0)
			end)
		else
			table.sort(enchantmentList, function(a, b)
				return (a.defaultSortOrder or 0) < (b.defaultSortOrder or 0)
			end)
		end
		controls.enchantment:UpdateSearch()
		if selected then
			for index, entry in ipairs(enchantmentList) do
				if entry == selected then
					controls.enchantment.selIndex = index
					break
				end
			end
		else
			controls.enchantment:SetSel(1, true)
		end
	end
	if haveSkills then
		controls.skillLabel = new("LabelControl"):LabelControl({"TOPRIGHT",nil,"TOPLEFT"}, {95, 20, 0, 16}, "^7Skill:")
		controls.skill = new("DropDownControl"):DropDownControl({"TOPLEFT",nil,"TOPLEFT"}, {100, 20, 180, 18}, skillList, function(index, value)
			buildEnchantmentSourceList()
			buildEnchantmentList()
			controls.enchantment:SetSel(1)
			if controls.sort then
				applySort(controls.sort.list[controls.sort.selIndex].stat, true)
			end
		end)
		controls.allSkills = new("CheckBoxControl"):CheckBoxControl({"TOPLEFT",nil,"TOPLEFT"}, {350, 20, 18}, "All skills:", function(state)
			buildSkillList(not state)
			controls.skill:SetSel(1)
			buildEnchantmentList()
			controls.enchantment:SetSel(1)
			if controls.sort then
				applySort(controls.sort.list[controls.sort.selIndex].stat, true)
			end
		end)
		controls.allSkills.tooltipText = "Show all skills, not just those used by this build."
		if not next(skillsUsed) then
			controls.allSkills.state = true
			controls.allSkills.enabled = false
		end
	end
	controls.enchantmentSourceLabel = new("LabelControl"):LabelControl({"TOPRIGHT",nil,"TOPLEFT"}, {95, 45, 0, 16}, "^7Source:")
	controls.enchantmentSource = new("DropDownControl"):DropDownControl({"TOPLEFT",nil,"TOPLEFT"}, {100, 45, 180, 18}, enchantmentSourceList, function(index, value)
		buildEnchantmentList()
		controls.enchantment:SetSel(m_min(controls.enchantment.selIndex, #enchantmentList))
		if controls.sort then
			applySort(controls.sort.list[controls.sort.selIndex].stat, true)
		end
	end)
	controls.sortLabel = new("LabelControl"):LabelControl({"TOPRIGHT",nil,"TOPLEFT"}, {350, 45, 0, 16}, "^7Sort by:")
	controls.sort = new("DropDownControl"):DropDownControl({"TOPLEFT",nil,"TOPLEFT"}, {355, 45, 240, 18}, sortList, function(index, value)
		applySort(value.stat, true)
	end)
	controls.enchantmentLabel = new("LabelControl"):LabelControl({"TOPRIGHT",nil,"TOPLEFT"}, {95, 70, 0, 16}, "^7Enchantment:")
	controls.enchantment = new("DropDownControl"):DropDownControl({"TOPLEFT",nil,"TOPLEFT"}, {100, 70, 495, 18}, enchantmentList)
	controls.enchantment.tooltipFunc = function(tooltip, mode, index)
		tooltip:Clear()
		self:AddItemTooltip(tooltip, enchantItem(index), nil, true)
	end
	controls.save = new("ButtonControl"):ButtonControl(nil, {-88, 100, 80, 20}, "Enchant", function()
		self:SetDisplayItem(enchantItem())
		main:ClosePopup()
	end)
	controls.remove = new("ButtonControl"):ButtonControl(nil, {0, 100, 80, 20}, "Remove", function()
		self:SetDisplayItem(enchantItem(nil, true))
		main:ClosePopup()
	end)
	controls.close = new("ButtonControl"):ButtonControl(nil, {88, 100, 80, 20}, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(605, 130, "Enchant Item", controls)
end

---Gets the name of the anointed node on an item
---@param item table @The item to get the anoint from
---@return string @The name of the anointed node, or nil if there is no anoint
function ItemsTabClass:getAnoint(item)
	local result = { }
	if item then
		for _, modList in ipairs{item.enchantModLines, item.scourgeModLines, item.implicitModLines, item.explicitModLines, item.crucibleModLines} do
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

---Gets how many anoint slots are still missing on an item.
---@param item table @The item to inspect
---@return number @How many additional anoints can still be applied
function ItemsTabClass:getMissingAnointCount(item)
	if not isAnointable(item) then
		return 0
	end
	local maxAnoints = item.canHaveFourEnchants and 4 or item.canHaveThreeEnchants and 3 or item.canHaveTwoEnchants and 2 or 1
	local anointCount = #self:getAnoint(item)
	return m_max(0, maxAnoints - m_min(anointCount, maxAnoints))
end

---Returns a copy of the currently displayed item, but anointed with a new node.
---Removes any existing enchantments before anointing. (Anoints are considered enchantments)
---@param node table @The passive tree node to anoint, or nil to just remove existing anoints.
---@return table @The new item
function ItemsTabClass:anointItem(node)
	self.anointEnchantSlot = self.anointEnchantSlot or 1
	local item = new("Item"):Item(self.displayItem:BuildRaw())
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

---Appends tooltip information for anointing a new passive tree node onto the currently editing item
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
	local repSlotName = self.displayItem.base and self.displayItem.base.type or "Amulet"
	local outputBase = calcFunc(self:ItemCalculationOverride(repSlotName, self.displayItem))
	local outputNew = calcFunc(self:ItemCalculationOverride(repSlotName, self:anointItem(node)))
	local numChanges = self.build:AddStatComparesToTooltip(tooltip, outputBase, outputNew, header)
	if node and numChanges == 0 then
		tooltip:AddLine(14, "^7"..actionText.." "..node.dn.." changes nothing.")
	end
end

---Appends tooltip with information about added notable passive node if it would be allocated.
---@param tooltip table @The tooltip to append into
---@param node table @The passive tree node that will be added
function ItemsTabClass:AppendAddedNotableTooltip(tooltip, node)
	local calcFunc, calcBase = self.build.calcsTab:GetMiscCalculator()
	local outputNew = calcFunc({ addNodes = { [node] = true } })
	local numChanges = self.build:AddStatComparesToTooltip(tooltip, calcBase, outputNew, "^7Allocating "..node.dn.." will give you: ")
	if numChanges == 0 then
		tooltip:AddLine(14, "^7Allocating "..node.dn.." changes nothing.")
	end
end

-- Opens the item anointing popup
function ItemsTabClass:AnointDisplayItem(enchantSlot)
	self.anointEnchantSlot = enchantSlot or 1

	local controls = { }
	controls.notableDB = new("NotableDBControl"):NotableDBControl({"TOPLEFT",nil,"TOPLEFT"}, {10, 60, 360, 360}, self, self.build.spec.tree.nodes, "ANOINT")

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
	controls.save = new("ButtonControl"):ButtonControl({"BOTTOMLEFT", nil, "BOTTOM" }, {saveLabelX, -4, saveLabelWidth, 20}, saveLabel, function()
		self:SetDisplayItem(self:anointItem(controls.notableDB.selValue))
		main:ClosePopup()
	end)
	controls.save.tooltipFunc = function(tooltip)
		tooltip:Clear()
		self:AppendAnointTooltip(tooltip, controls.notableDB.selValue)
	end
	controls.close = new("ButtonControl"):ButtonControl({"TOPLEFT", controls.save, "TOPRIGHT" }, {10, 0, 80, 20}, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(380, 448, "Anoint Item", controls)
end

-- Opens the item corrupting popup
function ItemsTabClass:CorruptDisplayItem()
	local controls = { }
	local implicitList = { }
	local shownExplicits = {}
	local explicitOffset = 0
	local corruptedRanges = {}
	local sourceList = { "Corrupted", "Scourge" }
	local sortList, sortStats = buildModSortList()
	local itemMaxCorruptImplicits = self.displayItem.corruptImplicitCount or 2
	for i, modLine in ipairs(self.displayItem.implicitModLines) do
		for _, mod in ipairs(modLine.modList or {}) do
			-- the vestigial implicit modifier doesn't go away when corrupting items
			if mod.name == "CorruptImplicitCount" then
				itemMaxCorruptImplicits = itemMaxCorruptImplicits - 1
			end
		end
	end
	local isGlimpse = self.displayItem.title and self.displayItem.title:lower():find("glimpse of chaos") and self.displayItem.isUnique
	if isGlimpse then
		table.insert(sourceList, 1, "Glimpse of Chaos")
	end
	local currentModType = sourceList[1]
	-- the amount of controls created
	local maxImplicitNum = 5
	local function buildImplicitList(modType)
		if implicitList[modType] then
			return
		end
		implicitList[modType] = {}
		if modType == "Glimpse of Chaos" then
			for modId, mod in pairs(data.itemMods.ItemExclusive) do
				if modId:find("^UniqueSpecialCorruption") then
					t_insert(implicitList[modType], { mod = mod })
				end
			end
		else
			for modId, mod in pairs(self.displayItem.affixes) do
				if mod.type == modType and self.displayItem:GetModSpawnWeight(mod) > 0 then
					t_insert(implicitList[modType], { mod = mod })
				end
			end
		end
		table.sort(implicitList[modType], function(a, b)
			local an = a.mod[1]:lower():gsub("%(.-%)","$"):gsub("[%+%-%%]",""):gsub("%d+","$")
			local bn = b.mod[1]:lower():gsub("%(.-%)","$"):gsub("[%+%-%%]",""):gsub("%d+","$")
			if an ~= bn then
				return an < bn
			else
				return a.mod.level < b.mod.level
			end
		end)
		for index, entry in ipairs(implicitList[modType]) do
			entry.defaultSortOrder = index
		end
	end
	buildImplicitList(currentModType)
	local function buildScourgeList(control, other, modType)
		local selfMod = control.selIndex and control.selIndex > 1 and control.list[control.selIndex].mod
		local otherMod = other and other.selIndex and other.selIndex > 1 and other.list[other.selIndex].mod
		wipeTable(control.list)
		t_insert(control.list, { label = "None" })
		for _, entry in ipairs(implicitList[modType]) do
			local mod = entry.mod
			if not otherMod or mod.group ~= otherMod.group then
				t_insert(control.list, { label = table.concat(mod, "/"), mod = mod })
			end
		end
		control:SelByValue(selfMod, "mod")
	end
	local function buildCorruptLists(modType)
		-- avoid letting the user select the same implicit twice
		local selectedGroups = {}
		for i = 1, maxImplicitNum do
			---@type DropDownControl
			local control = controls[string.format("implicit%d", i)]
			local selected = control:GetSelValue()
			if selected and selected.mod then
				selectedGroups[selected.mod.group] = { idx = i, val = selected.mod }
			end
		end
		for i = 1, maxImplicitNum do
			---@type DropDownControl
			local control = controls[string.format("implicit%d", i)]
			wipeTable(control.list)
			t_insert(control.list, { label = "None" })
			for _, entry in ipairs(implicitList[modType]) do
				local mod = entry.mod
				if not selectedGroups[mod.group] or selectedGroups[mod.group].idx == i then
					t_insert(control.list, { label = table.concat(mod, "/"), mod = mod })
				end
			end
		end
		for _, entry in pairs(selectedGroups) do
			---@type DropDownControl
			local control = controls[string.format("implicit%d", entry.idx)]
			control:SelByValue(entry.val, "mod")
		end
	end
	local function getSortValue(entry, modType, stat, calcFunc, slotName, useFullDPS)
		entry.sortValues = entry.sortValues or { }
		if entry.sortValues[stat] ~= nil then
			return entry.sortValues[stat]
		end
		local item = new("Item"):Item(self.displayItem:BuildRaw())
		item.id = self.displayItem.id
		item.corrupted = true
		local mod = entry.mod
		local targetLines = (modType == "ScourgeUpside" or modType == "ScourgeDownside") and item.scourgeModLines or item.implicitModLines
		wipeTable(targetLines)
		for _, modLine in ipairs(mod) do
			modLine = (currentModType == "ScourgeUpside" and "{scourge}" or "") .. modLine
			if mod.modTags[1] then
				t_insert(targetLines, { line = "{tags:" .. table.concat(mod.modTags, ",") .. "}" .. modLine })
			else
				t_insert(targetLines, { line = modLine })
			end
		end
		item:BuildAndParseRaw()
		local output = calcFunc(self:ItemCalculationOverride(slotName, item), useFullDPS)
		local value = data.powerStatList.GetFromOutput(output, sortStats[stat])
		entry.sortValues[stat] = value
		return value
	end
	local function sortModType(modType, stat, calcFunc, slotName, useFullDPS)
		if not implicitList[modType] then
			return
		end
		if stat then
			for _, entry in ipairs(implicitList[modType]) do
				entry.sortValue = getSortValue(entry, modType, stat, calcFunc, slotName, useFullDPS)
			end
			table.sort(implicitList[modType], function(a, b)
				if a.sortValue ~= b.sortValue then
					return a.sortValue > b.sortValue
				end
				return (a.defaultSortOrder or 0) < (b.defaultSortOrder or 0)
			end)
		else
			table.sort(implicitList[modType], function(a, b)
				return (a.defaultSortOrder or 0) < (b.defaultSortOrder or 0)
			end)
		end
	end
	local function applySort(stat)
		if not controls.implicit1 then
			return
		end
		local slotName = self.displayItem:GetPrimarySlot()
		local calcFunc = stat and self.build.calcsTab:GetMiscCalculator() or nil
		local useFullDPS = stat == "FullDPS"
		if currentModType ~= "ScourgeUpside" then
			sortModType(currentModType, stat, calcFunc, slotName, useFullDPS)
		else
			sortModType("ScourgeUpside", stat, calcFunc, slotName, useFullDPS)
			sortModType("ScourgeDownside", stat, calcFunc, slotName, useFullDPS)
		end
		if currentModType ~= "ScourgeUpside" then
			buildCorruptLists(currentModType)
		else
			buildScourgeList(controls.implicit1, controls.implicit2, "ScourgeUpside")
			buildScourgeList(controls.implicit2, controls.implicit1, "ScourgeUpside")
			buildScourgeList(controls.implicit3, controls.implicit4, "ScourgeDownside")
			buildScourgeList(controls.implicit4, controls.implicit3, "ScourgeDownside")
		end
		for i = 1, maxImplicitNum do
			local control = controls[string.format("implicit%d", i)]
			control:UpdateSearch()
		end
	end
	local function corruptItem(addingImplicits)
		local item = new("Item"):Item(self.displayItem:BuildRaw())
		item.id = self.displayItem.id
		item.corrupted = true
		local specialCorruptLine
		if currentModType ~= "ScourgeUpside" then
			for i, modLine in ipairs(self.displayItem.implicitModLines) do
				for _, mod in ipairs(modLine.modList or {}) do
					if mod.name == "CorruptImplicitCount" then
						specialCorruptLine = modLine
					end
				end
			end
		end
		-- either add implicits or roll ranges. if in the future it is possible
		-- to double corrupt an item, this needs to be changed to not remove
		-- implicits, like in pob2
		if addingImplicits then
			local newImplicit = {}
			for i = 1, maxImplicitNum do
				local control = controls[string.format("implicit%d", i)]
				if control.selIndex > 1 then
					local mod = control.list[control.selIndex].mod
					for _, modLine in ipairs(mod) do
						modLine = (currentModType == "ScourgeUpside" and "{scourge}" or "") .. modLine
						if mod.modTags[1] then
							t_insert(newImplicit, { line = "{tags:" .. table.concat(mod.modTags, ",") .. "}" .. modLine })
						else
							t_insert(newImplicit, { line = modLine })
						end
					end
				end
			end
			if #newImplicit > 0 then
				wipeTable(currentModType ~= "ScourgeUpside" and item.implicitModLines or item.scourgeModLines)
				if specialCorruptLine then
					t_insert(item.implicitModLines, specialCorruptLine)
				end
				for _, implicit in ipairs(newImplicit) do
					t_insert(currentModType ~= "ScourgeUpside" and item.implicitModLines or item.scourgeModLines, implicit)
				end
			end
		end
		if not addingImplicits then
			for i, modLine in ipairs(item.explicitModLines) do
				local corruptedRange = corruptedRanges[i]
				if corruptedRange then
					modLine.corruptedRange = corruptedRange ~= 1 and corruptedRange or nil
				end
			end
		end
		item:BuildAndParseRaw()
		return item
	end
	if self.displayItem.rarity == "UNIQUE" or self.displayItem.rarity == "RELIC" then
		local item = new("Item"):Item(self.displayItem:BuildRaw())
		local offset = 20
		for i, mod in ipairs(item.explicitModLines) do
			local modRange = mod.range or main.defaultItemAffixQuality
			if itemLib.isModLineScalable(mod.line, modRange, mod.valueScalar) and item:CheckModLineVariant(mod) then
				local function formatLabel(corruptedRange)
					local line = itemLib.applyRange(mod.line, modRange, mod.valueScalar or 1, corruptedRange)
					local lines = main:WrapString("^7" .. line, 16, 430)
					return table.concat(lines, "\n"), #lines
				end
				controls["rollRangeValue" .. i] = new("LabelControl"):LabelControl({ "TOPLEFT", nil, "TOPLEFT" },
					{ 10, 10 + offset, 200, 16 }, "^71.00")
				controls["rollRangeSlider" .. i] = new("SliderControl"):SliderControl({ "LEFT", controls["rollRangeValue" .. i], "RIGHT" }, { 5, 0, 80, 18 }, function(val)
						corruptedRanges[i] = 0.78 + round(0.44 * val, 2) -- 0.78-1.22
						controls["rollRangeValue" .. i].label = "^7" .. string.format("%.2f", corruptedRanges[i])
						controls["rollRangeLabel" .. i].label = formatLabel(corruptedRanges[i])
					end)
				corruptedRanges[i] = mod.corruptedRange or 1
				controls["rollRangeSlider" .. i].val = ((corruptedRanges[i]) - 0.78) / 0.44
				controls["rollRangeValue" .. i].label = "^7" .. string.format("%.2f", corruptedRanges[i])
				local label, lineCount = formatLabel(corruptedRanges[i])
				offset = offset + 16 * (lineCount - 1)
				controls["rollRangeLabel" .. i] = new("LabelControl"):LabelControl({ "LEFT", controls["rollRangeSlider" .. i], "RIGHT" },
					{ 5, 0, 200, 16 }, label)
				-- hide them by default as they are a secondary window
				controls["rollRangeLabel" .. i].shown = false
				controls["rollRangeSlider" .. i].shown = false
				controls["rollRangeValue" .. i].shown = false
				offset = offset + 20
				t_insert(shownExplicits, i)
			end
		end
		explicitOffset = offset
	end
	local function setImplicitControlsShown(implicitNum, canChangeImplicits)
		for i = 1, maxImplicitNum do
			local shown = canChangeImplicits and i <= implicitNum
			controls["implicit" .. i].shown = shown
			controls["implicit" .. i .. "Label"].shown = shown
		end
		controls.implicitCannotBeChangedLabel.shown = implicitNum > 0 and not canChangeImplicits
	end
	controls.implicits = new("ButtonControl"):ButtonControl({ "TOPLEFT", nil, "TOPLEFT" }, { 5, 5, 80, 20 }, "Implicits",
		function()
			local implicitNum = currentModType ~= "ScourgeUpside" and itemMaxCorruptImplicits or 4
			local canChangeImplicits = currentModType ~= "Corrupted" or not self.displayItem.implicitsCannotBeChanged
			setImplicitControlsShown(implicitNum, canChangeImplicits)
			for _, i in ipairs(shownExplicits) do
				controls["rollRangeLabel" .. i].shown = false
				controls["rollRangeSlider" .. i].shown = false
				controls["rollRangeValue" .. i].shown = false
			end
			controls.source.shown = true
			controls.sourceLabel.shown = true
			controls.sort.shown = true
			controls.sortLabel.shown = true
			main.popups[1].height = 103 + 20 * implicitNum
		end)
	controls.implicits.shown = function()
		return self.displayItem.rarity == "UNIQUE" or self.displayItem.rarity == "RELIC"
	end
	controls.rolls = new("ButtonControl"):ButtonControl({ "LEFT", controls.implicits, "RIGHT" }, { 5, 0, 80, 20 },
		"Roll Ranges",
		function()
			setImplicitControlsShown(0, false)
			for _, i in ipairs(shownExplicits) do
				controls["rollRangeLabel" .. i].shown = true
				controls["rollRangeSlider" .. i].shown = true
				controls["rollRangeValue" .. i].shown = true
			end
			controls.source.shown = false
			controls.sourceLabel.shown = false
			controls.sort.shown = false
			controls.sortLabel.shown = false
			main.popups[1].height = 55 + explicitOffset
		end)
	controls.rolls.shown = function()
		return self.displayItem.rarity == "UNIQUE" or self.displayItem.rarity == "RELIC"
	end
	controls.sourceLabel = new("LabelControl"):LabelControl({ "TOPRIGHT", nil, "TOPLEFT" }, { 95, 30, 0, 16 },
		"^7Source:")
	controls.source = new("DropDownControl"):DropDownControl({ "TOPLEFT", nil, "TOPLEFT" }, { 100, 30, 150, 18 },
		sourceList, function(index, value)
			if value == "Scourge" then
				currentModType = "ScourgeUpside"
				buildImplicitList("ScourgeUpside")
				buildImplicitList("ScourgeDownside")
				local implicitNum = (self.displayItem.rarity == "UNIQUE" or self.displayItem.rarity == "RELIC") and 4 or 3
				setImplicitControlsShown(implicitNum, true)
				main.popups[1].height = 103 + 20 * implicitNum
				buildScourgeList(controls.implicit3, controls.implicit4, "ScourgeDownside")
				buildScourgeList(controls.implicit4, controls.implicit3, "ScourgeDownside")
			else
				buildImplicitList(value)
				currentModType = value
				setImplicitControlsShown(itemMaxCorruptImplicits, not self.displayItem.implicitsCannotBeChanged)
				main.popups[1].height = 103 + 20 * itemMaxCorruptImplicits
			end
			if controls.sort then
				applySort(controls.sort.list[controls.sort.selIndex].stat)
			else
				buildCorruptLists(currentModType)
			end
			for i = 1, maxImplicitNum do
				controls[string.format("implicit%d", i)]:SetSel(1)
			end
		end)
	controls.source.enabled = #sourceList > 1
	controls.sortLabel = new("LabelControl"):LabelControl({"TOPRIGHT",nil,"TOPLEFT"}, {350, 20, 0, 16}, "^7Sort by:")
	controls.sort = new("DropDownControl"):DropDownControl({"TOPLEFT",nil,"TOPLEFT"}, {355, 20, 240, 18}, sortList, function(index, value)
		applySort(value.stat)
	end)
	local implicitRowSize = 20
	local implicitYPos = 35
	controls.implicitCannotBeChangedLabel = new("LabelControl"):LabelControl({ "TOPLEFT", nil, "TOPLEFT" }, { 20, implicitYPos + implicitRowSize, 0, 20 }, "^7This Items Implicits Cannot Be Changed")
	controls.implicitCannotBeChangedLabel.shown = self.displayItem.implicitsCannotBeChanged
	for i = 1, maxImplicitNum do
		local controlName = "implicit" .. i
		controls[controlName .. "Label"] = new("LabelControl"):LabelControl({ "TOPRIGHT", nil, "TOPLEFT" }, { 75, implicitYPos + i * implicitRowSize, 0, 16 },
			string.format("^7Implicit #%d:", i))
		controls[controlName] = new("DropDownControl"):DropDownControl({ "TOPLEFT", nil, "TOPLEFT" }, { 80, implicitYPos + i * implicitRowSize, 440, 18 }, nil)
		controls[controlName].tooltipFunc = function(tooltip, mode, index, value)
			tooltip:Clear()
			if mode ~= "OUT" and value and value.mod then
				for _, line in ipairs(value.mod) do
					tooltip:AddLine(16, "^7" .. line)
				end
				self:AddModComparisonTooltip(tooltip, value.mod, true)
			end
		end
		local shownVal
		if i <= itemMaxCorruptImplicits then
			shownVal = not self.displayItem.implicitsCannotBeChanged
		else
			shownVal = false
		end
		controls[controlName].shown = shownVal
		controls[controlName .. "Label"].shown = shownVal
	end
	for i = 1, maxImplicitNum do
		controls["implicit" .. i].selFunc = function()
			if currentModType == "ScourgeUpside" then
				local otherIdx = (i % 2 == 0) and (i - 1) or (i + 1)
				local modType = i <= 2 and "ScourgeUpside" or "ScourgeDownside"
				-- remove selected entry from other dropdown of the same type
				buildScourgeList(controls["implicit" .. otherIdx], controls["implicit" .. i], modType)
			else
				buildCorruptLists(currentModType)
			end
		end
		if i <= itemMaxCorruptImplicits then
			controls["implicit" .. i].selFunc()
		end
	end
	controls.save = new("ButtonControl"):ButtonControl({ "BOTTOM", nil, "BOTTOM" }, { -45, -4, 80, 20 }, "Corrupt", function()
		self:SetDisplayItem(corruptItem(controls.implicit1.shown))
		main:ClosePopup()
	end)
	controls.save.tooltipFunc = function(tooltip)
		tooltip:Clear()
		self:AddItemTooltip(tooltip, corruptItem(controls.implicit1.shown), nil, false)
	end
	controls.close = new("ButtonControl"):ButtonControl({ "BOTTOM", nil, "BOTTOM" }, { 45, -4, 80, 20 }, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(605, 103 + 20 * itemMaxCorruptImplicits, "Corrupt Item", controls)
end

local delveDropOnlyCategories = require("Data.DelveDropOnly")
local incursionDropOnlyCategories = require("Data.IncursionDropOnly")
-- Opens the custom modifier popup
function ItemsTabClass:AddCustomModifierToDisplayItem()
	local controls = { }
	local sourceList = { }
	local modList = { }
	local sortList, sortStats = buildModSortList()
	local function setDefaultSortOrder()
		for index, listMod in ipairs(modList) do
			listMod.defaultSortOrder = index
			listMod.sortValue = nil
			listMod.sortValues = nil
		end
	end
	local function getSortValue(listMod, stat, calcFunc, slotName, useFullDPS)
		listMod.sortValues = listMod.sortValues or { }
		if listMod.sortValues[stat] ~= nil then
			return listMod.sortValues[stat]
		end
		local item = new("Item"):Item(self.displayItem:BuildRaw())
		item.id = self.displayItem.id
		for _, line in ipairs(listMod.mod) do
			t_insert(item.explicitModLines, { line = checkLineForAllocates(line, self.build.spec.nodes), modTags = listMod.mod.modTags, [listMod.type] = true })
		end
		item:BuildAndParseRaw()
		local output = calcFunc(self:ItemCalculationOverride(slotName, item), useFullDPS)
		local value = data.powerStatList.GetFromOutput(output, sortStats[stat])
		listMod.sortValues[stat] = value
		return value
	end
	local function applySort(stat, selectFirst)
		if not controls.modSelect or not controls.modSelect:IsShown() then
			return
		end
		local selected = not selectFirst and modList[controls.modSelect.selIndex] or nil
		if stat then
			local slotName = self.displayItem:GetPrimarySlot()
			local calcFunc = self.build.calcsTab:GetMiscCalculator()
			local useFullDPS = stat == "FullDPS"
			for _, listMod in ipairs(modList) do
				listMod.sortValue = getSortValue(listMod, stat, calcFunc, slotName, useFullDPS)
			end
			table.sort(modList, function(a, b)
				if a.sortValue ~= b.sortValue then
					return a.sortValue > b.sortValue
				end
				return (a.defaultSortOrder or 0) < (b.defaultSortOrder or 0)
			end)
		else
			table.sort(modList, function(a, b)
				return (a.defaultSortOrder or 0) < (b.defaultSortOrder or 0)
			end)
		end
		controls.modSelect:UpdateSearch()
		if selected then
			for index, listMod in ipairs(modList) do
				if listMod == selected then
					controls.modSelect.selIndex = index
					break
				end
			end
		else
			controls.modSelect:SetSel(1, true)
		end
	end
	local function buildDropRestricted(baseCategories, modDb)
		local base = self.displayItem.base
		local subTypeName = base.subType and base.type .. ": " .. base.subType
		for modId, entry in pairs(baseCategories) do
			local mod = modDb[modId]
			if not mod then
				ConPrintf("Unknown drop-restricted mod id: %s", tostring(modId))
				goto nextDrop
			end
			for _, cat in ipairs(entry.categories) do
				if base.type == cat or subTypeName == cat then
					t_insert(modList, {
						label = table.concat(mod, "/") .. " (" .. mod.type .. ")",
						mod = mod,
						affixType = mod.type,
						type = "custom",
						defaultOrder = modId,
					})
					goto nextDrop
				end
			end
			::nextDrop::
		end
	end
	local function sortByPrefixSuffix(a, b)
		if a.affixType ~= b.affixType then
			return a.affixType == "Prefix" and b.affixType == "Suffix"
		else
			return a.defaultOrder < b.defaultOrder
		end
	end
	---Mutates modList to contain mods from the specified source
	---@param sourceId string @The crafting source id to build the list of mods for
	local function buildMods(sourceId)
		wipeTable(modList)
		if sourceId == "MASTER" then
			local excludeGroups = { }
			for _, modLine in ipairs({ self.displayItem.prefixes, self.displayItem.suffixes }) do
				for i = 1, (modLine.limit or (self.displayItem.affixLimit / 2)) do
					if modLine[i] and modLine[i].modId ~= "None" then
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
				if mod then
					t_insert(modList, {
						label = essence.name .. "   " .. "^8[" .. table.concat(mod, "/") .. "]" .. " (" .. mod.type .. ")",
						mod = mod,
						type = "custom",
						essence = essence,
					})
				end
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
				if sourceId:lower() == (mod.type and mod.type:lower()) and self.displayItem:GetModSpawnWeight(mod) > 0 then
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
						label = table.concat(mod, "/") .. " (" .. mod.type .. ")",
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
		elseif sourceId == "INCURSION" then
			buildDropRestricted(incursionDropOnlyCategories, data.itemMods.Explicit)
			table.sort(modList, sortByPrefixSuffix)
		elseif sourceId == "DELVE" then
			buildDropRestricted(delveDropOnlyCategories, data.itemMods.Delve)
			table.sort(modList, sortByPrefixSuffix)
		elseif sourceId == "FOSSIL" then
			for i, mod in pairs(self.displayItem.affixes) do
				if self.displayItem:CheckIfModIsDelve(mod) and self.displayItem:GetModSpawnWeight(mod) > 0 then
					t_insert(modList, {
						label = table.concat(mod, "/") .. " (" .. mod.type .. ")",
						mod = mod,
						affixType = mod.type,
						type = "custom",
						defaultOrder = i,
					})
				end
			end
			table.sort(modList, sortByPrefixSuffix)
		elseif sourceId == "NECROPOLIS" then
			for i, mod in pairs(self.build.data.necropolisMods) do
				if self.displayItem:GetNecropolisModSpawnWeight(mod) > 0 then
					t_insert(modList, {
						label = table.concat(mod, "/") .. " (" .. mod.type .. ")",
						mod = mod,
						affixType = mod.type,
						type = "custom",
						defaultOrder = i,
					})
				end
			end
			table.sort(modList, sortByPrefixSuffix)
		elseif sourceId == "BEASTCRAFT" then
			for i, mod in pairs(self.build.data.beastCraft) do
				t_insert(modList, {
					label = table.concat(mod, "/") .. " (" .. mod.type .. ")",
					mod = mod,
					affixType = mod.type,
					type = "custom",
					defaultOrder = i,
				})
			end
			table.sort(modList, sortByPrefixSuffix)
		end
		setDefaultSortOrder()
	end
	if self.displayItem.type ~= "Tincture" and self.displayItem.type ~= "Graft" then
		if self.displayItem.type ~= "Jewel" then
			t_insert(sourceList, { label = "Crafting Bench", sourceId = "MASTER" })
		end
		if self.displayItem.type ~= "Jewel" and self.displayItem.type ~= "Flask" and self.displayItem.type ~= "Graft" then
			t_insert(sourceList, { label = "Essence", sourceId = "ESSENCE" })
			t_insert(sourceList, { label = "Veiled", sourceId = "VEILED"})
			t_insert(sourceList, { label = "Beastcraft", sourceId = "BEASTCRAFT" })
		end
		if self.displayItem.type == "Helmet" or self.displayItem.type == "Body Armour" or self.displayItem.type == "Gloves" or self.displayItem.type == "Boots" then
			t_insert(sourceList, { label = "Necropolis", sourceId = "NECROPOLIS"})
		end
		if not self.displayItem.clusterJewel and self.displayItem.type ~= "Flask" and self.displayItem.type ~= "Graft" then
			t_insert(sourceList, { label = "Fossil", sourceId = "FOSSIL" })
			t_insert(sourceList, { label = "Delve Drop-restricted", sourceId = "DELVE" })
			t_insert(sourceList, { label = "Incursion Drop-restricted", sourceId = "INCURSION" })
		end
		if not self.displayItem.crafted then
			t_insert(sourceList, { label = "Prefix", sourceId = "PREFIX" })
			t_insert(sourceList, { label = "Suffix", sourceId = "SUFFIX" })
		end
	end
	if self.displayItem.rareLikeUnique then
		local applicableSourceIds = self.displayItem.rareLikeUnique.supportsCustomModifiers
		if applicableSourceIds then
			local newSourceList = {}
			for _, list in ipairs(sourceList) do
				if applicableSourceIds[list.sourceId] then
					table.insert(newSourceList, list)
				end
			end
			sourceList = newSourceList
		end
	end
	-- test each category to see if they actually match any mods
	-- TODO: given that we need to do this, it would be better to just keep a
	-- list of matching mod ids, rather than building a list to check, and then
	-- building it again when selecting it
	local i = 1
	while sourceList[i] do
		buildMods(sourceList[i].sourceId)
		if #modList == 0 then
			table.remove(sourceList, i)
		else
			i = i + 1
		end
	end
	t_insert(sourceList, { label = "Custom", sourceId = "CUSTOM" })
	buildMods(sourceList[1].sourceId)
	local function addModifier()
		local item = new("Item"):Item(self.displayItem:BuildRaw())
		item.id = self.displayItem.id
		local sourceId = sourceList[controls.source.selIndex].sourceId
		if sourceId == "CUSTOM" then
			if controls.custom.buf:match("%S") then
				t_insert(item.explicitModLines, { line = controls.custom.buf, custom = true })
			end
		else
			local listMod = modList[controls.modSelect.selIndex]
			if listMod then
				for _, line in ipairs(listMod.mod) do
					t_insert(item.explicitModLines, { line = line, modTags = listMod.mod.modTags, [listMod.type] = true })
				end
			end
		end
		item:BuildAndParseRaw()
		return item
	end
	controls.sourceLabel = new("LabelControl"):LabelControl({"TOPRIGHT",nil,"TOPLEFT"}, {95, 20, 0, 16}, "^7Source:")
	controls.source = new("DropDownControl"):DropDownControl({"TOPLEFT",nil,"TOPLEFT"}, {100, 20, 150, 18}, sourceList, function(index, value)
		buildMods(value.sourceId)
		controls.modSelect:SetSel(1)
		if controls.sort then
			applySort(controls.sort.list[controls.sort.selIndex].stat, true)
		end
	end)
	controls.source.enabled = #sourceList > 1
	controls.sortLabel = new("LabelControl"):LabelControl({"TOPRIGHT",nil,"TOPLEFT"}, {350, 20, 0, 16}, "^7Sort by:")
	controls.sortLabel.shown = function()
		return sourceList[controls.source.selIndex].sourceId ~= "CUSTOM"
	end
	controls.sort = new("DropDownControl"):DropDownControl({"TOPLEFT",nil,"TOPLEFT"}, {355, 20, 240, 18}, sortList, function(index, value)
		applySort(value.stat, true)
	end)
	controls.sort.shown = function()
		return sourceList[controls.source.selIndex].sourceId ~= "CUSTOM"
	end
	controls.modSelectLabel = new("LabelControl"):LabelControl({"TOPRIGHT",nil,"TOPLEFT"}, {95, 45, 0, 16}, "^7Modifier:")
	controls.modSelect = new("DropDownControl"):DropDownControl({"TOPLEFT",nil,"TOPLEFT"}, {100, 45, 600, 18}, modList)
	controls.modSelect.shown = function()
		return sourceList[controls.source.selIndex].sourceId ~= "CUSTOM"
	end
	controls.modSelect.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if mode ~= "OUT" and value then
			for _, line in ipairs(value.mod) do
				tooltip:AddLine(16, "^7"..line)
			end
			self:AddModComparisonTooltip(tooltip, value.mod)
		end
	end
	controls.custom = new("EditControl"):EditControl({"TOPLEFT",nil,"TOPLEFT"}, {100, 45, 440, 18})
	controls.custom.shown = function()
		return sourceList[controls.source.selIndex].sourceId == "CUSTOM"
	end
	controls.save = new("ButtonControl"):ButtonControl(nil, {-45, 75, 80, 20}, "Add", function()
		self:SetDisplayItem(addModifier())
		main:ClosePopup()
	end)
	controls.save.tooltipFunc = function(tooltip)
		tooltip:Clear()
		self:AddItemTooltip(tooltip, addModifier())
	end
	controls.close = new("ButtonControl"):ButtonControl(nil, {45, 75, 80, 20}, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(710, 105, "Add Modifier to Item", controls, "save", sourceList[controls.source.selIndex].sourceId == "CUSTOM" and "custom")
end

-- Opens the crucible modifier popup
function ItemsTabClass:AddCrucibleModifierToDisplayItem()
	local controls = { }
	local modList = {[1] = {"None"}, [2] = {"None"}, [3] = {"None"}, [4] = {"None"}, [5] = {"None"}}
	local itemModMap, nodeSelections = { }, { }
	local function getLabelFromMod(mod)
		local label = copyTable(mod)
		for index, line in ipairs(mod) do
			label[index] = checkLineForAllocates(line, self.build.spec.nodes)
		end
		return table.concat(label, "/")
	end
	local function buildCrucibleMods()
		for i, mod in pairs(self.build.data.crucible) do
			if self.displayItem:CanHaveMod(mod) then
				-- item mod must match the whole mod, whether that's one line or two
				if itemModMap[checkLineForAllocates(mod[1], self.build.spec.nodes)] and ((mod[2] and itemModMap[checkLineForAllocates(mod[2], self.build.spec.nodes)]) or not mod[2]) then
					-- for multi nodes, if the first location is taken, use second
					-- works for multi vs single node, ambiguous for multi vs multi (3,4 vs 3,4) but both mods load
					if nodeSelections[mod.nodeLocation[1]] and mod.nodeLocation[2] then
						nodeSelections[mod.nodeLocation[2]] = i
					-- nodeSelections[nodeId] = defaultOrder, used later to match with sorted modList to get selIndex
					else
						nodeSelections[mod.nodeLocation[1]] = i
					end
				end
				for _, location in ipairs(mod.nodeLocation) do
					t_insert(modList[location], {
						label = getLabelFromMod(mod) .. " - Tier: " .. mod.tier,
						mod = mod,
						affixType = mod.type,
						type = "crucible",
						defaultOrder = i,
					})
				end
			end
		end
		for _, tierList in ipairs(modList) do
			table.sort(tierList, function(a, b)
				if b ~= "None" then
					if a.affixType ~= b.affixType then
						return a.affixType == "Spawn" and b.affixType == "MergeOnly"
					else
						return a.defaultOrder < b.defaultOrder
					end
				end
			end)
		end
	end
	local function addModifier()
		local item = new("Item"):Item(self.displayItem:BuildRaw())
		item.id = self.displayItem.id
		item.crucibleModLines = { }
		local listMod = {
			modList[1][controls.modSelectNode1.selIndex],
			modList[2][controls.modSelectNode2.selIndex],
			modList[3][controls.modSelectNode3.selIndex],
			modList[4][controls.modSelectNode4.selIndex],
			modList[5][controls.modSelectNode5.selIndex],
		}
		for _, nodeMod in ipairs(listMod) do
			if nodeMod ~= "None" then
				for index, line in ipairs(nodeMod.mod) do
					t_insert(item.crucibleModLines, { line = checkLineForAllocates(line, self.build.spec.nodes), modTags = nodeMod.mod.modTags, [nodeMod.type] = true })
				end
			end
		end
		item:BuildAndParseRaw()
		return item
	end
	-- set up name map to know what modLines the item has as we build the mods out
	for _, mod in ipairs(self.displayItem.crucibleModLines) do
		itemModMap[mod.line] = true
	end
	buildCrucibleMods()
	local y = 45
	for i = 1,5 do
		controls["modSelectNode"..i.."Label"] = new("LabelControl"):LabelControl({"TOPRIGHT",nil,"TOPLEFT"}, {95, y, 0, 16}, "^7Node "..i..":")
		controls["modSelectNode"..i] = new("DropDownControl"):DropDownControl({"TOPLEFT",nil,"TOPLEFT"}, {100, y, 555, 18}, modList[i])
		controls["modSelectNode"..i].tooltipFunc = function(tooltip, mode, index, value)
			tooltip:Clear()
			if mode ~= "OUT" and value and value ~= "None" then
				for _, line in ipairs(value.mod) do
					tooltip:AddLine(16, "^7"..checkLineForAllocates(line, self.build.spec.nodes))
				end
				self:AddModComparisonTooltip(tooltip, value.mod)
			end
		end
		y = y + 22
	end
	-- populate dropdowns with item mods
	for nodeId, defaultOrder in pairs(nodeSelections) do
		for index, mod in pairs(modList[nodeId]) do
			if defaultOrder == mod.defaultOrder then
				controls["modSelectNode"..nodeId].selIndex = index
			end
		end
	end
	controls.save = new("ButtonControl"):ButtonControl(nil, {-45, 157, 80, 20}, "Add", function()
		self:SetDisplayItem(addModifier())
		main:ClosePopup()
	end)
	controls.save.tooltipFunc = function(tooltip)
		tooltip:Clear()
		self:AddItemTooltip(tooltip, addModifier())
	end
	controls.close = new("ButtonControl"):ButtonControl(nil, {45, 157, 80, 20}, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(710, 185, "Add Crucible Modifier to Item", controls, "save")
end

function ItemsTabClass:AddItemSetTooltip(tooltip, itemSet)
	for _, slot in ipairs(self.orderedSlots) do
		if not slot.nodeId then
			local itemSlot = itemSet[slot.slotName]
			local item = itemSlot and self.items[itemSlot.selItemId]
			if item then
				tooltip:AddLine(16, s_format("^7%s: %s%s", slot.label, colorCodes[item.rarity], item.name))
			end
		end
	end
end

function ItemsTabClass:SetTooltipHeaderInfluence(tooltip, item)
	tooltip.influenceHeader1 = nil
	tooltip.influenceHeader2 = nil

	local function addInfluence(name)
		if not tooltip.influenceHeader1 then
			tooltip.influenceHeader1 = name
		elseif not tooltip.influenceHeader2 then
			tooltip.influenceHeader2 = name
		end
	end

	-- Eater and Exarch combo takes priority over fractured icon.
	if item.cleansing and item.tangle then
		addInfluence("Exarch")
		addInfluence("Eater")
	else
		-- Dual influence with fracture will show fractured icon and highest priority influence.
		if item.fractured then
			addInfluence("Fractured")
		end
		-- Replica Eternity Shroud has Experimented icon and Shaper icon on the right.
		if item.title and item.title:find("Replica") then
			addInfluence("Experimented")
		end
		if item.foulborn then
			addInfluence("Foulborn")
		end
		if item.veiled then
			addInfluence("Veiled")
		end
		if item.cleansing then
			addInfluence("Exarch")
		end
		if item.tangle then
			addInfluence("Eater")
		end
		if item.shaper then
			addInfluence("Shaper")
		end
		if item.elder then
			addInfluence("Elder")
		end
		if item.crusader then
			addInfluence("Crusader")
		end
		if item.eyrie then
			addInfluence("Redeemer")
		end
		if item.basilisk then
			addInfluence("Hunter")
		end
		if item.adjudicator then
			addInfluence("Warlord")
		end
		if item.vestigial then
			addInfluence("Vestigial")
		end
		if item.synthesised and not tooltip.influenceHeader1 then
			addInfluence("Synthesis")
		end
		if item.memoryStrands and not tooltip.influenceHeader1 then
			addInfluence("Memory")
		end
	end

	if tooltip.influenceHeader1 and not tooltip.influenceHeader2 then
		tooltip.influenceHeader2 = tooltip.influenceHeader1
	end
end

function ItemsTabClass:FormatItemSource(text)
	return text:gsub("unique{([^}]+)}",colorCodes.UNIQUE.."%1"..colorCodes.SOURCE)
			   :gsub("normal{([^}]+)}",colorCodes.NORMAL.."%1"..colorCodes.SOURCE)
			   :gsub("currency{([^}]+)}",colorCodes.CURRENCY.."%1"..colorCodes.SOURCE)
			   :gsub("prophecy{([^}]+)}",colorCodes.PROPHECY.."%1"..colorCodes.SOURCE)
end

local function itemChangesPassiveTree(item)
	return not not (item and item.type == "Jewel" and item.jewelData
		and (item.jewelData.conqueredBy or item.jewelRadiusIndex
			and (item.jewelData.intuitiveLeapLike or item.jewelData.impossibleEscapeKeystone)))
end

-- These jewels can replace passive nodes or disconnect allocated passives, so
-- rebuild the passive tree before comparing their stats.
-- Keep this list in sync with PassiveSpec's constructor, Init, and Select*
-- methods; omitted fields fail safe as nil on the comparison spec.
local sharedSpecKeysForJewelComparison = {
	build = true,
	treeVersion = true,
	tree = true,
	title = true,
	ignoreAllocatingSubgraph = true,
	clusterHashFormatVersion = true,
	curClassId = true,
	curClass = true,
	curClassName = true,
	curAscendClassId = true,
	curAscendClass = true,
	curAscendClassName = true,
	curAscendClassBaseName = true,
	curSecondaryAscendClassId = true,
	curSecondaryAscendClass = true,
	curSecondaryAscendClassName = true,
}

local function cloneSpecForJewelComparison(spec)
	local specCopy = setmetatable({ }, getmetatable(spec))
	-- Share only immutable/scalar spec state. Tables that BuildAllDependsAndPaths
	-- may mutate must be owned by the comparison spec.
	for key in pairs(sharedSpecKeysForJewelComparison) do
		specCopy[key] = spec[key]
	end

	specCopy.nodes = { }
	for id, node in pairs(spec.nodes) do
		local nodeCopy = setmetatable({ }, getmetatable(node))
		for key, value in pairs(node) do
			if key ~= "linked" and key ~= "depends" and key ~= "intuitiveLeapLikesAffecting"
			and key ~= "path" and key ~= "power" then
				nodeCopy[key] = value
			end
		end
		nodeCopy.alloc = false
		nodeCopy.linked = { }
		nodeCopy.depends = { }
		nodeCopy.intuitiveLeapLikesAffecting = { }
		nodeCopy.power = { }
		specCopy.nodes[id] = nodeCopy
	end
	for id, nodeCopy in pairs(specCopy.nodes) do
		for _, linkedNode in ipairs(spec.nodes[id].linked or { }) do
			local linkedCopy = specCopy.nodes[linkedNode.id]
			if linkedCopy then
				t_insert(nodeCopy.linked, linkedCopy)
			end
		end
	end

	specCopy.allocNodes = { }
	for id in pairs(spec.allocNodes) do
		local nodeCopy = specCopy.nodes[id]
		if nodeCopy then
			nodeCopy.alloc = true
			specCopy.allocNodes[id] = nodeCopy
		end
	end
	specCopy.jewels = copyTable(spec.jewels, true)
	specCopy.masterySelections = copyTable(spec.masterySelections, true)
	specCopy.hashOverrides = copyTable(spec.hashOverrides, true)
	specCopy.ignoredNodes = copyTable(spec.ignoredNodes, true)
	specCopy.splitPersonalityPath = { }
	specCopy.allocSubgraphNodes = { }
	specCopy.allocExtendedNodes = { }
	specCopy.subGraphs = { }

	return specCopy
end

---@param itemsTab ItemsTab
---@param compareSlot ItemSlotControl
---@param replacementItem Item
local function buildSpecForJewelComparison(itemsTab, compareSlot, replacementItem)
	local tempItemId
	local spec = cloneSpecForJewelComparison(itemsTab.build.spec)
	if replacementItem then
		if replacementItem.id and itemsTab.items[replacementItem.id] == replacementItem then
			spec.jewels[compareSlot.nodeId] = replacementItem.id
		else
			tempItemId = -1
			while itemsTab.items[tempItemId] do
				tempItemId = tempItemId - 1
			end
			itemsTab.items[tempItemId] = replacementItem
			spec.jewels[compareSlot.nodeId] = tempItemId
		end
	else
		spec.jewels[compareSlot.nodeId] = nil
	end
	local ok, err = xpcall(function()
		spec:BuildAllDependsAndPaths()
	end, debug.traceback)
	if tempItemId then
		itemsTab.items[tempItemId] = nil
	end
	if not ok then
		error(err, 0)
	end
	return spec
end

function ItemsTabClass:GetSocketDescriptionLine(item)
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
	return line
end
function ItemsTabClass:AddItemTooltip(tooltip, item, slot, dbMode, maxWidth)
	local fontSizeSmall = main.showFlavourText and 16 or 14
	local fontSizeBig = main.showFlavourText and 18 or 16
	local fontSizeTitle = main.showFlavourText and 22 or 20
	local rarityCode = colorCodes[item.rarity]
	tooltip.maxWidth = m_min(maxWidth or 600, 600) -- Cap very long lines. Can use a narrower width for small viewports
	tooltip.tooltipHeader = item.rarity
	tooltip.foilType = item.foilType
	tooltip.center = true
	tooltip.color = rarityCode
	-- Shared items can use old base names that no longer exist. Add a tooltip so they can be copied or removed without causing a crash.
	if not item.base or not item.baseName then
		tooltip:AddLine(fontSizeTitle, rarityCode..(item.title or item.name or "Unknown Item"), "FONTIN SC")
		tooltip:AddSeparator(30)
		tooltip:AddLine(fontSizeTitle, colorCodes.NEGATIVE.."Item base is not supported by the current version.", "FONTIN SC")
		return
	end
	self:SetTooltipHeaderInfluence(tooltip, item)
	-- Item name
	if item.title then
		tooltip:AddLine(fontSizeTitle, rarityCode..item.title, "FONTIN SC")
		tooltip:AddLine(fontSizeTitle, rarityCode..item.baseName:gsub(" %(.+%)",""),"FONTIN SC")
	else
		tooltip:AddLine(fontSizeTitle, rarityCode..item.namePrefix..item.baseName:gsub(" %(.+%)","")..item.nameSuffix, "FONTIN SC")
	end
	for _, curInfluenceInfo in ipairs(influenceInfo) do
		if item[curInfluenceInfo.key] and not main.showFlavourText then
			tooltip:AddLine(fontSizeBig, curInfluenceInfo.color..curInfluenceInfo.display.." Item", "FONTIN SC")
		end
	end
	if item.fractured and not main.showFlavourText then
		tooltip:AddLine(fontSizeBig, colorCodes.FRACTURED.."Fractured Item")
	end
	if item.synthesised and not main.showFlavourText then
		tooltip:AddLine(fontSizeBig, colorCodes.CRAFTED.."Synthesised Item")
	end
	tooltip:AddSeparator(10)

	-- Special fields for database items
	if dbMode then
		if item.usesVariantGroups then
			if item.versionList and item.selectedVersion then
				tooltip:AddLine(fontSizeBig, "^xFFFF30Version: " .. item.versionList[item.selectedVersion], "FONTIN SC")
			end
			local selectedVariants = { }
			for groupId in pairsSortByKey(item.variantGroups) do
				local variantId = item.variantGroupSelections[groupId]
				if variantId and item:IsVariantGroupOptionEligible(groupId, variantId) then
					t_insert(selectedVariants, item.variantList[variantId])
				end
			end
			if #selectedVariants > 0 then
				tooltip:AddLine(fontSizeBig, "^xFFFF30Variants: " .. table.concat(selectedVariants, ", "), "FONTIN SC")
			end
		elseif item.variantList then
			if #item.variantList == 1 then
				tooltip:AddLine(fontSizeBig, "^xFFFF30Variant: "..item.variantList[1], "FONTIN SC")
			else
				tooltip:AddLine(fontSizeBig, "^xFFFF30Variant: "..item.variantList[item.variant].." ("..#item.variantList.." variants)", "FONTIN SC")
			end
		end
		if item.league then
			tooltip:AddLine(fontSizeBig, "^xFF5555Exclusive to: "..item.league, "FONTIN SC")
		end
		if item.unreleased then
			tooltip:AddLine(fontSizeBig, colorCodes.NEGATIVE.."Not yet available", "FONTIN SC")
		end
		if item.source then
			tooltip:AddLine(fontSizeBig, colorCodes.SOURCE.."Source: "..self:FormatItemSource(item.source), "FONTIN SC")
		end
		if item.upgradePaths then
			for _, path in ipairs(item.upgradePaths) do
				tooltip:AddLine(fontSizeBig, colorCodes.SOURCE..self:FormatItemSource(path), "FONTIN SC")
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
		tooltip:AddLine(fontSizeBig, s_format("^x7F7F7F%s", self.build.data.weaponTypeInfo[base.type].label or base.subType or base.type), "FONTIN SC")
		if item.quality > 0 then
			tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FQuality: "..colorCodes.MAGIC.."+%d%%", item.quality), "FONTIN SC")
		end
		local totalDamageTypes = 0
		if weaponData.PhysicalDPS then
			tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FPhysical Damage: "..colorCodes.MAGIC.."%d-%d (%.1f DPS)", weaponData.PhysicalMin, weaponData.PhysicalMax, weaponData.PhysicalDPS), "FONTIN SC")
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
			tooltip:AddLine(fontSizeBig, elemLine, "FONTIN SC")
			tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FElemental DPS: "..colorCodes.MAGIC.."%.1f", weaponData.ElementalDPS), "FONTIN SC")
			totalDamageTypes = totalDamageTypes + 1
		end
		if weaponData.ChaosDPS then
			tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FChaos Damage: "..colorCodes.CHAOS.."%d-%d "..colorCodes.MAGIC.."(%.1f DPS)", weaponData.ChaosMin, weaponData.ChaosMax, weaponData.ChaosDPS), "FONTIN SC")
			totalDamageTypes = totalDamageTypes + 1
		end
		if totalDamageTypes > 1 then
			tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FTotal DPS: "..colorCodes.MAGIC.."%.1f", weaponData.TotalDPS), "FONTIN SC")
		end
		tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FCritical Strike Chance: %s%.2f%%", main:StatColor(weaponData.CritChance, base.weapon.CritChanceBase), weaponData.CritChance), "FONTIN SC")
		tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FAttacks per Second: %s%.2f", main:StatColor(weaponData.AttackRate, base.weapon.AttackRateBase), weaponData.AttackRate), "FONTIN SC")
		if weaponData.range < 120 then
			tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FWeapon Range: %s%.1f ^x7F7F7Fmetres", main:StatColor(weaponData.range, base.weapon.Range), weaponData.range / 10), "FONTIN SC")
		end
	elseif base.armour then
		-- Armour-specific info
		local armourData = item.armourData
		if item.quality > 0 then
			tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FQuality: "..colorCodes.MAGIC.."+%d%%", item.quality), "FONTIN SC")
		end
		if base.armour.BlockChance and armourData.BlockChance > 0 then
			tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FChance to Block: %s%d%%", main:StatColor(armourData.BlockChance, base.armour.BlockChance), armourData.BlockChance), "FONTIN SC")
		end
		if armourData.Armour > 0 then
			tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FArmour: %s%d", main:StatColor(armourData.Armour, armourData.ArmourBase), armourData.Armour), "FONTIN SC")
		end
		if armourData.Evasion > 0 then
			tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FEvasion Rating: %s%d", main:StatColor(armourData.Evasion, armourData.EvasionBase), armourData.Evasion), "FONTIN SC")
		end
		if armourData.EnergyShield > 0 then
			tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FEnergy Shield: %s%d", main:StatColor(armourData.EnergyShield, armourData.EnergyShieldBase), armourData.EnergyShield), "FONTIN SC")
		end
		if armourData.Ward > 0 then
			tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FWard: %s%d", main:StatColor(armourData.Ward, armourData.WardBase), armourData.Ward), "FONTIN SC")
		end
	elseif base.flask then
		-- Flask-specific info
		local flaskData = item.flaskData
		if item.quality > 0 then
			tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FQuality: "..colorCodes.MAGIC.."+%d%%", item.quality), "FONTIN SC")
		end
		if flaskData.lifeTotal then
			if flaskData.lifeGradual ~= 0 then
				tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FRecovers %s%d ^x7F7F7FLife over %s%.1f0 ^x7F7F7FSeconds",
					main:StatColor(flaskData.lifeTotal, base.flask.life), flaskData.lifeGradual,
					main:StatColor(flaskData.duration, base.flask.duration), flaskData.duration
					), "FONTIN SC")
			end
			if flaskData.lifeInstant ~= 0 then
				tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FRecovers %s%d ^x7F7F7FLife instantly", main:StatColor(flaskData.lifeTotal, base.flask.life), flaskData.lifeInstant), "FONTIN SC")
			end
		end
		if flaskData.manaTotal then
			if flaskData.manaGradual ~= 0 then
				tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FRecovers %s%d ^x7F7F7FMana over %s%.1f0 ^x7F7F7FSeconds",
					main:StatColor(flaskData.manaTotal, base.flask.mana), flaskData.manaGradual,
					main:StatColor(flaskData.duration, base.flask.duration), flaskData.duration
					), "FONTIN SC")
			end
			if flaskData.manaInstant ~= 0 then
				tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FRecovers %s%d ^x7F7F7FMana instantly", main:StatColor(flaskData.manaTotal, base.flask.mana), flaskData.manaInstant), "FONTIN SC")
			end
		end
		if not flaskData.lifeTotal and not flaskData.manaTotal then
			tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FLasts %s%.2f ^x7F7F7FSeconds", main:StatColor(flaskData.duration, base.flask.duration), flaskData.duration), "FONTIN SC")
		end
		tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FConsumes %s%d ^x7F7F7Fof %s%d ^x7F7F7FCharges on use",
			main:StatColor(flaskData.chargesUsed, base.flask.chargesUsed), flaskData.chargesUsed,
			main:StatColor(flaskData.chargesMax, base.flask.chargesMax), flaskData.chargesMax
		), "FONTIN SC")
		for _, modLine in pairs(item.buffModLines) do
			if modLine.extra then
				local line = colorCodes.UNSUPPORTED..modLine.line
				line = main.notSupportedModTooltips and (line .. main.notSupportedTooltipText) or line
				tooltip:AddLine(fontSizeBig, line, "FONTIN SC")
			else
				tooltip:AddLine(fontSizeBig, colorCodes.MAGIC..modLine.line, "FONTIN SC")
			end
		end
	elseif base.tincture then
		-- Tincture-specific info
		local tinctureData = item.tinctureData

		if item.quality and item.quality > 0 then
			tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FQuality: "..colorCodes.MAGIC.."+%d%%", item.quality), "FONTIN SC")
		end

		tooltip:AddLine(fontSizeBig, s_format("^x7F7F7FInflicts Mana Burn every %s%.2f ^x7F7F7FSeconds", main:StatColor(tinctureData.manaBurn, base.tincture.manaBurn), tinctureData.manaBurn), "FONTIN SC")
		tooltip:AddLine(fontSizeBig, s_format("^x7F7F7F%s%.2f ^x7F7F7FSecond Cooldown When Deactivated", main:StatColor(tinctureData.cooldown, base.tincture.cooldown), tinctureData.cooldown), "FONTIN SC")
		for _, modLine in pairs(item.buffModLines) do
			if modLine.extra then
				local line = colorCodes.UNSUPPORTED..modLine.line
				line = main.notSupportedModTooltips and (line .. main.notSupportedTooltipText) or line
				tooltip:AddLine(fontSizeBig, line, "FONTIN SC")
			else
				tooltip:AddLine(fontSizeBig, colorCodes.MAGIC..modLine.line, "FONTIN SC")
			end
		end
	elseif item.type == "Jewel" then
		-- Jewel-specific info
		if item.limit then
			tooltip:AddLine(fontSizeBig, "^x7F7F7FLimited to: ^7"..item.limit, "FONTIN SC")
		end
		if item.classRestriction then
			tooltip:AddLine(fontSizeBig, "^x7F7F7FRequires Class "..(self.build.spec.curClassName == item.classRestriction and colorCodes.POSITIVE or colorCodes.NEGATIVE)..item.classRestriction, "FONTIN SC")
		end
		if item.jewelRadiusLabel then
			tooltip:AddLine(fontSizeBig, "^x7F7F7FRadius: ^7"..item.jewelRadiusLabel, "FONTIN SC")
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
				tooltip:AddLine(fontSizeBig, "^x7F7F7FAttributes in Radius: "..line, "FONTIN SC")
			end
		end
	end
	if item.catalyst and item.catalyst > 0 and item.catalyst <= #catalystQualityFormat and item.catalystQuality and item.catalystQuality > 0 then
		tooltip:AddLine(fontSizeBig, s_format(catalystQualityFormat[item.catalyst], item.catalystQuality), "FONTIN SC")
		tooltip:AddSeparator(10)
	end

	if #item.sockets > 0 then
		local line = self:GetSocketDescriptionLine(item)
		tooltip:AddLine(fontSizeBig, "^x7F7F7FSockets: "..line, "FONTIN SC")
	end

	if item.talismanTier then
		tooltip:AddLine(fontSizeBig, "^x7F7F7FTalisman Tier ^xFFFFFF"..item.talismanTier, "FONTIN SC")
		tooltip:AddSeparator(10)
	end
	if item.memoryStrands then
		if main.showFlavourText then tooltip:AddLine(5, "") end
		tooltip:AddLine(fontSizeBig, colorCodes.MEMORY .. s_format("Memory Strands: ^7%d", item.memoryStrands), "FONTIN SC", nil, "Assets/memorybg.png")
		if main.showFlavourText then tooltip:AddLine(5, "") end
	end
	if item.intangibility then
		if main.showFlavourText then tooltip:AddLine(5, "") end
		tooltip:AddLine(fontSizeBig, colorCodes.INTANGIBILITY .. s_format("Intangibility: ^7%d%%", item.intangibility), "FONTIN SC", nil, "Assets/intangibilitybg.png")
		if main.showFlavourText then tooltip:AddLine(5, "") end
	end
	tooltip:AddSeparator(10)
	-- Requirements
	self.build:AddRequirementsToTooltip(tooltip, item.requirements.level,
		item.requirements.strMod, item.requirements.dexMod, item.requirements.intMod,
		item.requirements.str or 0, item.requirements.dex or 0, item.requirements.int or 0)

	-- Modifiers
	for _, modList in ipairs{item.enchantModLines, item.scourgeModLines, item.implicitModLines, item.explicitModLines, item.crucibleModLines} do
		if modList[1] then
			for _, modLine in ipairs(modList) do
				local variantCount = item:GetModLineVariantCount(modLine)
				if variantCount > 0 then
					local formattedModLine = itemLib.formatModLine(modLine, dbMode)
					if formattedModLine then
						for _ = 1, variantCount do
							tooltip:AddLine(fontSizeBig, formattedModLine, "FONTIN SC", modLine)
						end
					end
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
					tooltip:AddLine(fontSizeBig, colorCodes.MAGIC .. node.dn, "FONTIN SC")
					for _, stat in ipairs(node.sd) do
						tooltip:AddLine(fontSizeBig, "^x7F7F7F"..stat, "FONTIN SC")
					end
				end
			end
		elseif item.jewelData.clusterJewelKeystone then
			local node = self.build.spec.tree.clusterNodeMap[item.jewelData.clusterJewelKeystone]
			if node then
				tooltip:AddLine(fontSizeBig, colorCodes.MAGIC .. node.dn, "FONTIN SC")
				for _, stat in ipairs(node.sd) do
					tooltip:AddLine(fontSizeBig, "^x7F7F7F"..stat, "FONTIN SC")
				end
			end
		end
		tooltip:AddSeparator(10)
	end

	-- Corrupted item label
	if item.corrupted or item.split or item.mirrored then
		if #item.explicitModLines == 0 then
			tooltip:AddSeparator(10)
		end
		if item.split then
			tooltip:AddLine(fontSizeBig, colorCodes.NEGATIVE.."Split", "FONTIN SC")
		end
		if item.mirrored then
			tooltip:AddLine(fontSizeBig, colorCodes.NEGATIVE.."Mirrored", "FONTIN SC")
		end
		if item.corrupted then
			tooltip:AddLine(fontSizeBig, colorCodes.NEGATIVE.."Corrupted", "FONTIN SC")
		end
		tooltip:AddSeparator(14)
	end

	-- Show flavour text:
	if (item.rarity == "UNIQUE" or item.rarity == "RELIC" or item.base.flavourText) and main.showFlavourText then
		local flavour = nil
		local flavourTable = nil

		if item.base.flavourText then
			flavour = item.base.flavourText
		else
			flavourTable = flavourLookup[item.title:gsub("^Foulborn%s+", "")]
		end

		if flavourTable then
			if (item.title and item.title:match("Grand Spectrum")) then
				local selectedFlavourId = nil
				for _, lineEntry in ipairs(tooltip.lines or {}) do
					local lineText = lineEntry.text or ""
					if lineText:find("Power") then
						selectedFlavourId = "UniqueJewel170"
						break
					elseif lineText:find("Endurance") then
						selectedFlavourId = "UniqueJewel168"
						break
					elseif lineText:find("Frenzy") then
						selectedFlavourId = "UniqueJewel169"
						break
					elseif lineText:find("Elemental Damage") then
						selectedFlavourId = "UniqueJewel168"
						break
					elseif lineText:find("Elemental Ailments") then
						selectedFlavourId = "UniqueJewel166"
						break
					elseif lineText:find("Elemental Resistances") or lineText:find("Armour") then
						selectedFlavourId = "UniqueJewel76"
						break
					elseif lineText:find("Maximum Life") then
						selectedFlavourId = "UniqueJewel165"
						break
					elseif lineText:find("Critical Strike Multiplier") then
						selectedFlavourId = "UniqueJewel167"
						break
					elseif lineText:find("Critical Strike Chance") or lineText:find("Mana") then
						selectedFlavourId = "UniqueJewel75"
						break
					end
				end
				if selectedFlavourId and flavourTable[selectedFlavourId] then
					flavour = flavourTable[selectedFlavourId]
				end
			else
				for _, text in pairs(flavourTable) do
					flavour = text
					break
				end
			end
		end

		if flavour then
			for _, line in ipairs(flavour) do
				tooltip:AddLine(fontSizeBig, colorCodes.UNIQUE .. line, "FONTIN SC ITALIC")
			end
			tooltip:AddSeparator(14)
		end
	end

	-- Skill tooltip. We add child tooltips, which will be rendered to the right of the main
	-- tooltip, growing downwards
	if not tooltip.childTooltips then
		tooltip.childTooltips = {}
	end
	for _, tt in ipairs(tooltip.childTooltips) do
		tt:Clear()
	end
	local itemSkills = copyTable(item.grantedSkills or {})
	-- append "Supported by #" to active skills
	for _, mod in ipairs(modList) do
		if mod.name == "ExtraSupport" then
			t_insert(itemSkills, mod.value)
		end
	end
	if #itemSkills > 0 then
		tooltip:AddSeparator(14)
		tooltip:AddLine(14,
			colorCodes.TIP ..
			"Tip: Hold Shift to display a tooltip for the granted skill" ..
			(#itemSkills > 1 and "s" or "") .. ".")
		for i, itemSkill in ipairs(itemSkills) do
			if not tooltip.childTooltips[i] then
				tooltip.childTooltips[i] = new("Tooltip"):Tooltip()
			end
			-- find gem since the item data only contains the skill id
			local skill = data.skills[itemSkill.skillId]
			if skill and skill.id and IsKeyDown("SHIFT") then
				local gemId = data.gemForSkill[skill] or ""
				local gem = data.gems[gemId]
				-- if the skill has no matching gem, make up one. it will lack some information, but should still display somewhat correctly
				---@type GemToolTipOptions
				local options = {}
				if not gem then
					gem = { grantedEffect = skill, tags = {} }
					options.skipRequirements = true
				end
				local gemInst = {
					gemData = gem,
					level = itemSkill.level or 1,
					quality = 0,
					grantedEffect = skill
				}
				gemTooltip.AddGemTooltip(tooltip.childTooltips[i], self.build, gemInst, options)
			end
		end
	end
	-- Stat differences
	local itemTabHint = self.build.viewMode == "ITEMS" and "" or " in the Items tab"
	if not self.showStatDifferences then
		tooltip:AddSeparator(14)
		tooltip:AddLine(14, colorCodes.TIP.."Tip: Press Ctrl+D"..itemTabHint.." to enable the display of stat differences.")
		return
	elseif not (base.flask or base.tincture) then
		tooltip:AddLine(14, colorCodes.TIP .. "Tip: Press Ctrl+D" .. itemTabHint .. " to disable the display of stat differences.")
	end
	self:AddItemStatDifferences(tooltip, item, base, slot)

	if launch.devModeAlt then
		-- Modifier debugging info
		tooltip:AddSeparator(10)
		for _, mod in ipairs(modList) do
			tooltip:AddLine(14, "^7" .. modLib.formatMod(mod))
		end
	end
end

---@param tooltip Tooltip
---@param item Item
---@param base any
function ItemsTabClass:AddItemStatDifferences(tooltip, item, base, slot)
	local calcFunc, calcBase, calcBaseByActor = self.build.calcsTab:GetMiscCalculator()
	if base.flask then
		-- Special handling for flasks
		local stats = {}
		local flaskData = item.flaskData
		local modDB = self.build.calcsTab.mainEnv.modDB
		local output = self.build.calcsTab.mainOutput
		local durInc = modDB:Sum("INC", nil, "FlaskDuration")
		local effectInc = modDB:Sum("INC", { actor = "player" }, "FlaskEffect")
		local lifeDur = 0
		local manaDur = 0

		if item.rarity == "MAGIC" and not item.base.flask.life and not item.base.flask.mana then
			effectInc = effectInc + modDB:Sum("INC", { actor = "player" }, "MagicUtilityFlaskEffect")
		end

		if item.base.flask.life or item.base.flask.mana then
			local rateInc = modDB:Sum("INC", nil, "FlaskRecoveryRate")
			if item.base.flask.life then
				local lifeInc = modDB:Sum("INC", nil, "FlaskLifeRecovery")
				local lifeMore = modDB:More(nil, "FlaskLifeRecovery")
				local lifeRateInc = modDB:Sum("INC", nil, "FlaskLifeRecoveryRate")
				local instantPerc = flaskData.instantPerc + modDB:Sum("BASE", nil, "LifeFlaskInstantRecovery")

				-- More life recovery while on low life is not affected by flask effect (verified ingame).
				-- Since this will be multiplied by the flask effect value below we have to counteract this by removing the flask effect from the value beforehand.
				-- This is also the reason why this value needs a separate multiplier and cannot just be calculated into FlaskLifeRecovery.
				local lifeMoreOnLowLife = modDB:More(nil, "FlaskLifeRecoveryLowLife")
				local lowLifeMulti = (lifeMoreOnLowLife > 1 and ((lifeMoreOnLowLife - 1) / (1 + effectInc / 100)) + 1 or 1)

				local inst = flaskData.lifeBase * instantPerc / 100 * (1 + lifeInc / 100) * lifeMore * (1 + effectInc / 100) * lowLifeMulti
				local base = flaskData.lifeBase * (1 - instantPerc / 100) * (1 + lifeInc / 100) * lifeMore * (1 + effectInc / 100) * (1 + durInc / 100) * lowLifeMulti
				local grad = base * output.LifeRecoveryRateMod
				local esGrad = base * output.EnergyShieldRecoveryRateMod
				lifeDur = flaskData.duration * (1 + durInc / 100) / (1 + rateInc / 100) / (1 + lifeRateInc / 100)

				-- LocalLifeFlaskAdditionalLifeRecovery flask mods
				if flaskData.lifeAdditional > 0 and not self.build.configTab.input.conditionFullLife then
					local totalAdditionalAmount = (flaskData.lifeAdditional / 100) * flaskData.lifeTotal * output.LifeRecoveryRateMod
					local additionalGrad = (lifeDur / 10) * totalAdditionalAmount
					local leftoverDur = 10 - lifeDur
					local leftoverAmount = totalAdditionalAmount - additionalGrad

					if inst > 0 then
						if grad > 0 then
							t_insert(stats, s_format("^8Life recovered: ^7%d ^8(^7%d^8 instantly, plus ^7%d ^8over^7 %.2fs^8, and an additional ^7%d ^8over subsequent ^7%.2fs^8)",
								inst + grad + totalAdditionalAmount, inst, grad + additionalGrad, lifeDur, leftoverAmount, leftoverDur))
						else
							lifeDur = 0
							t_insert(stats, s_format("^8Life recovered: ^7%d ^8(^7%d^8 instantly, and an additional ^7%d ^8over ^7%.2fs^8)",
								inst + totalAdditionalAmount, inst, totalAdditionalAmount, 10))
						end
					else
						t_insert(stats, s_format("^8Life recovered: ^7%d ^8(^7%d ^8over ^7%.2fs^8, and an additional ^7%d ^8over subsequent ^7%.2fs^8)",
							grad + totalAdditionalAmount, grad + additionalGrad, lifeDur, leftoverAmount, leftoverDur))
					end
				else
					if inst > 0 and grad > 0 then
						t_insert(stats, s_format("^8Life recovered: ^7%d ^8(^7%d^8 instantly, plus ^7%d ^8over^7 %.2fs^8)", inst + grad, inst, grad, lifeDur))
						-- modifiers to recovery amount or duration
					elseif inst + grad ~= flaskData.lifeTotal or (inst == 0 and lifeDur ~= flaskData.duration) then
						if inst > 0 then
							lifeDur = 0
							t_insert(stats, s_format("^8Life recovered: ^7%d ^8instantly", inst))
						elseif grad > 0 then
							t_insert(stats, s_format("^8Life recovered: ^7%d ^8over ^7%.2fs", grad, lifeDur))
						end
					end
				end
				if modDB:Flag(nil, "LifeFlaskAppliesToEnergyShield") then
					if inst > 0 and esGrad > 0 then
						t_insert(stats, s_format("^8Energy Shield recovered: ^7%d ^8(^7%d^8 instantly, plus ^7%d ^8over^7 %.2fs^8)", inst + esGrad, inst, esGrad, lifeDur))
					elseif inst > 0 and esGrad == 0 then
						t_insert(stats, s_format("^8Energy Shield recovered: ^7%d ^8instantly", inst))
					elseif inst == 0 and esGrad > 0 then
						t_insert(stats, s_format("^8Energy Shield recovered: ^7%d ^8over ^7%.2fs", esGrad, lifeDur))
					end
				end
			end
			if item.base.flask.mana then
				local manaInc = modDB:Sum("INC", nil, "FlaskManaRecovery")
				local manaRateInc = modDB:Sum("INC", nil, "FlaskManaRecoveryRate")
				local instantPerc = flaskData.instantPerc + modDB:Sum("BASE", nil, "ManaFlaskInstantRecovery")
				local inst = flaskData.manaBase * instantPerc / 100 * (1 + manaInc / 100) * (1 + effectInc / 100)
				local base = flaskData.manaBase * (1 - instantPerc / 100) * (1 + manaInc / 100) * (1 + effectInc / 100) * (1 + durInc / 100)
				local grad = base * output.ManaRecoveryRateMod
				local lifeGrad = base * output.LifeRecoveryRateMod
				manaDur = flaskData.duration * (1 + durInc / 100) / (1 + rateInc / 100) / (1 + manaRateInc / 100)

				if inst > 0 and grad > 0 then
					t_insert(stats, s_format("^8Mana recovered: ^7%d ^8(^7%d^8 instantly, plus ^7%d ^8over^7 %.2fs^8)", inst + grad, inst, grad, manaDur))
				elseif inst + grad ~= flaskData.manaTotal or (inst == 0 and manaDur ~= flaskData.duration) then
					if inst > 0 then
						manaDur = 0
						t_insert(stats, s_format("^8Mana recovered: ^7%d ^8instantly", inst))
					elseif grad > 0 then
						t_insert(stats, s_format("^8Mana recovered: ^7%d ^8over ^7%.2fs", grad, manaDur))
					end
				end
				if modDB:Flag(nil, "ManaFlaskAppliesToLife") then
					if lifeGrad > 0 then
						t_insert(stats, s_format("^8Life recovered: ^7%d ^8over ^7%.2fs", lifeGrad, manaDur))
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

		-- charge generation
		local chargesGenerated = modDB:Sum("BASE", nil, "FlaskChargesGenerated")
		if item.base.flask.life then
			chargesGenerated = chargesGenerated + modDB:Sum("BASE", nil, "LifeFlaskChargesGenerated")
		end
		if item.base.flask.mana then
			chargesGenerated = chargesGenerated + modDB:Sum("BASE", nil, "ManaFlaskChargesGenerated")
		end
		if not item.base.flask.mana and not item.base.flask.life then
			chargesGenerated = chargesGenerated + modDB:Sum("BASE", nil, "UtilityFlaskChargesGenerated")
		end
		local chargesGeneratedOnWardBreak = 0
		if item.baseName == "Iron Flask" then
			chargesGeneratedOnWardBreak = chargesGeneratedOnWardBreak + modDB:Sum("BASE", nil, "IronFlaskChargesGeneratedOnWardBreak")
		end

		local chargesGeneratedPerFlask = modDB:Sum("BASE", nil, "FlaskChargesGeneratedPerEmptyFlask")
		local emptyFlaskSlots = 0
		for slotName, slot in pairs(self.slots) do
			if slotName:find("^Flask") ~= nil and slot.selItemId == 0 then
				emptyFlaskSlots = emptyFlaskSlots + 1
			end
		end
		chargesGeneratedPerFlask = chargesGeneratedPerFlask * emptyFlaskSlots
		chargesGenerated = chargesGenerated * gainMod
		chargesGeneratedOnWardBreak = chargesGeneratedOnWardBreak * gainMod
		chargesGeneratedPerFlask = chargesGeneratedPerFlask * gainMod

		local totalChargesGenerated = chargesGenerated + chargesGeneratedPerFlask
		if totalChargesGenerated > 0 then
			t_insert(stats, s_format("^8Charges generated: ^7%.2f^8 per second", totalChargesGenerated))
		end
		if chargesGeneratedOnWardBreak > 0 then
			t_insert(stats, s_format("^8Charges generated on Ward Break: ^7%.2f", chargesGeneratedOnWardBreak))
		end

		local chanceToNotConsumeCharges = m_min(modDB:Sum("BASE", nil, "FlaskChanceNotConsumeCharges"), 100)
		if chanceToNotConsumeCharges ~= 0 then
			t_insert(stats, s_format("^8Chance to not consume charges: ^7%d%%", chanceToNotConsumeCharges))
		end

		-- flask uptime
		local hasUptime = not item.base.flask.life and not item.base.flask.mana
		local flaskDuration = flaskData.duration * (1 + durInc / 100)

		if item.base.flask.life and (flaskData.lifeEffectNotRemoved or modDB:Flag(nil, "LifeFlaskEffectNotRemoved")) then
			hasUptime = true
			flaskDuration = lifeDur
		elseif item.base.flask.mana and (flaskData.manaEffectNotRemoved or modDB:Flag(nil, "ManaFlaskEffectNotRemoved")) then
			hasUptime = true
			flaskDuration = manaDur
		end

		if hasUptime then
			local flaskChargesUsed = flaskData.chargesUsed * (1 + usedInc / 100)
			if flaskChargesUsed > 0 and flaskDuration > 0 then
				local per3Duration = flaskDuration - (flaskDuration % 3)
				local per5Duration = flaskDuration - (flaskDuration % 5)
				local minimumChargesGenerated = per3Duration * chargesGenerated + per5Duration * chargesGeneratedPerFlask
				local percentageMin = m_min(minimumChargesGenerated / flaskChargesUsed * 100, 100)
				if percentageMin < 100 and chanceToNotConsumeCharges < 100 then
					local averageChargesGenerated = (chargesGenerated + chargesGeneratedPerFlask) * flaskDuration
					local averageChargesUsed = flaskChargesUsed * (100 - chanceToNotConsumeCharges) / 100
					local percentageAvg = m_min(averageChargesGenerated / averageChargesUsed * 100, 100)
					t_insert(stats, s_format("^8Flask uptime: ^7%d%%^8 average, ^7%d%%^8 minimum", percentageAvg, percentageMin))
				else
					t_insert(stats, s_format("^8Flask uptime: ^7100%%^8"))
				end
			end
		end

		if stats[1] then
			tooltip:AddLine(14, "^7Effective flask stats:")
			for _, stat in ipairs(stats) do
				tooltip:AddLine(14, stat)
			end
		end
		local output = calcFunc({ toggleFlask = item })
		local header
		if self.build.calcsTab.mainEnv.flasks[item] then
			header = "^7Deactivating this flask will give you:"
		else
			header = "^7Activating this flask will give you:"
		end
		self.build:AddStatComparesToTooltip(tooltip, calcBase, output, header)
	elseif base.tincture then
		-- Special handling for tinctures
		local stats = {}
		local tinctureData = item.tinctureData
		local modDB = self.build.calcsTab.mainEnv.modDB
		local output = self.build.calcsTab.mainOutput
		local effectInc = modDB:Sum("INC", { actor = "player" }, "TinctureEffect")

		if item.rarity == "MAGIC" then
			effectInc = effectInc + modDB:Sum("INC", { actor = "player" }, "MagicTinctureEffect")
		end
		local effectMod = (1 + (tinctureData.effectInc + effectInc) / 100) * (1 + (item.quality or 0) / 100)
		if effectMod ~= 1 then
			t_insert(stats, s_format("^8Tincture effect modifier: ^7%+d%%", effectMod * 100 - 100))
		end
		t_insert(stats, s_format("^8Mana Burn Inflicted Every Second: ^7%.2f", 1 / (tinctureData.manaBurn / (1 + modDB:Sum("INC", { actor = "player" }, "TinctureManaBurnRate") / 100) / (1 + modDB:Sum("MORE", { actor = "player" }, "TinctureManaBurnRate") / 100))))
		local TincturesNotInflictManaBurn = m_min(modDB:Sum("BASE", nil, "TincturesNotInflictManaBurn"), 100)
		if TincturesNotInflictManaBurn ~= 0 then
			t_insert(stats, s_format("^8Chance to not inflict Mana Burn: ^7%d%%", TincturesNotInflictManaBurn))
		end
		t_insert(stats, s_format("^8Tincture Cooldown when deactivated: ^7%.2f^8 seconds", base.tincture.cooldown / (1 + (modDB:Sum("INC", { actor = "player" }, "TinctureCooldownRecovery") + tinctureData.cooldownInc) / 100)))

		if stats[1] then
			tooltip:AddLine(14, "^7Effective tincture stats:")
			for _, stat in ipairs(stats) do
				tooltip:AddLine(14, stat)
			end
		end
		local output = calcFunc({ toggleTincture = item })
		local header
		if self.build.calcsTab.mainEnv.tinctures[item] then
			header = "^7Deactivating this tincture will give you:"
		else
			header = "^7Activating this tincture will give you:"
		end
		self.build:AddStatComparesToTooltip(tooltip, calcBase, output, header)
	else
		self:UpdateSockets()
		-- Build sorted list of slots to compare with
		local compareSlots = { }
		local visibleItemSet = self:GetVisibleItemSet()
		for slotName, slot in pairs(self.slots) do
			if self:IsItemValidForSlot(item, slotName, visibleItemSet) and not slot.inactive and (not slot.weaponSet or slot.weaponSet == (visibleItemSet.useSecondWeaponSet and 2 or 1)) and slot.shown() then
				t_insert(compareSlots, slot)
			end
		end

		local function getReplacedItemAndOutput(compareSlot)
			local selItem = self.items[compareSlot.selItemId]
			local override = self:ItemCalculationOverride(compareSlot.slotName, item ~= selItem and item or nil)
			if compareSlot.nodeId and (itemChangesPassiveTree(selItem) or itemChangesPassiveTree(item)) then
				override.spec = buildSpecForJewelComparison(self, compareSlot, override.repItem)
			end
			local output = calcFunc(override)
			return selItem, output
		end
		local function addCompareForSlot(compareSlot, selItem, output)
			if not selItem or not output then
				selItem, output = getReplacedItemAndOutput(compareSlot)
			end
			local header
			if item == selItem then
				header = "^7Removing this item from " .. compareSlot.label .. " will give you:"
			else
				header = string.format("^7Equipping this item in %s will give you:%s", compareSlot.label or compareSlot.slotName, selItem and "\n(replacing " .. colorCodes[selItem.rarity] .. selItem.name .. "^7)" or "")
			end
			local comparisonActor = MercenaryTools.comparisonActorForSlot(compareSlot.slotName, self.viewItemSetId, self)
			if comparisonActor == "PLAYER" then
				comparisonActor = nil
			end
			local compareBase = comparisonActor and calcBaseByActor.MERCENARY or calcBase
			if comparisonActor and not MercenaryTools.mercenaryOutputAvailable(compareBase) then
				tooltip:AddLine(16, colorCodes.WARNING.."Mercenary comparison unavailable")
				return
			end
			if not output then
				return
			end
			self.build:AddStatComparesToTooltip(tooltip, compareBase, output, header, nil, comparisonActor)
		end

		-- if we have a specific slot to compare to, and the user has "Show
		-- tooltips only for affected slots" checked, we can just compare that
		-- one slot
		if main.slotOnlyTooltips and slot then
			slot = type(slot) ~= "string" and slot or self.slots[self:GetVisibleSlotName(slot)]
			if slot then addCompareForSlot(slot) end
			return
		end


		local slots = {}
		local isUnique = item.rarity == "UNIQUE" or item.rarity == "RELIC"
		local currentSameUniqueCount = 0
		for _, compareSlot in ipairs(compareSlots) do
			local selItem, output = getReplacedItemAndOutput(compareSlot)
			local isSameUnique = isUnique and selItem and item.name == selItem.name
			if isUnique and isSameUnique and item.limit then
				currentSameUniqueCount = currentSameUniqueCount + 1
			end
			table.insert(slots,
				{ selItem = selItem, output = output, compareSlot = compareSlot, isSameUnique = isSameUnique })
		end

		-- limited uniques: only compare to slots with the same item if more don't fit
		if currentSameUniqueCount == item.limit then
			for _, slotEntry in ipairs(slots) do
				if slotEntry.isSameUnique then
					addCompareForSlot(slotEntry.compareSlot, slotEntry.selItem, slotEntry.output)
				end
			end
			return
		end


		-- either the same unique or same base type
		local function similar(compareItem, sameUnique)
			-- empty slot
			if not compareItem then return 0 end

			local sameBaseType = not isUnique
				and compareItem.rarity ~= "UNIQUE" and compareItem.rarity ~= "RELIC"
				and item.base.type == compareItem.base.type
				and item.base.subType == compareItem.base.subType
			if sameBaseType or sameUnique then
				return 1
			else
				return 0
			end
		end
		-- sort by:
		-- 1. empty sockets
		-- 2. same base group jewel or unique
		-- 3. DPS
		-- 4. EHP
		local function sortFunc(a, b)
			if a == b then return end

			local aParams = { a.compareSlot.selItemId == 0 and 1 or 0, similar(a.selItem, a.isSameUnique), a.output.FullDPS, a.output.CombinedDPS, a.output.TotalEHP, a.compareSlot.label, a.compareSlot.slotName }
			local bParams = { b.compareSlot.selItemId == 0 and 1 or 0, similar(b.selItem, b.isSameUnique), b.output.FullDPS, b
				.output.CombinedDPS, b.output.TotalEHP, b.compareSlot.label, b.compareSlot.slotName }
			for i = 1, #aParams do
				if aParams[i] == nil or bParams[i] == nil then
					-- continue
				elseif aParams[i] > bParams[i] then
					return true
				elseif aParams[i] < bParams[i] then
					return false
				end
			end
			return false
		end
		table.sort(slots, sortFunc)

		for _, slotEntry in ipairs(slots) do
			addCompareForSlot(slotEntry.compareSlot, slotEntry.selItem, slotEntry.output)
		end
	end
end

function ItemsTabClass:CreateUndoState()
	local state = { }
	state.activeItemSetId = self.activeItemSetId
	state.viewItemSetId = self.viewItemSetId
	state.viewComparisonActor = self.viewComparisonActor
	state.items = { }
	for k, v in pairs(self.items) do
		state.items[k] = copyTableSafe(self.items[k], true, true)
	end
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
	self.itemSets = state.itemSets
	wipeTable(self.itemSetOrderList)
	for k, v in pairs(state.itemSetOrderList) do
		self.itemSetOrderList[k] = v
	end
	self.activeItemSetId = state.activeItemSetId
	self.activeItemSet = self.itemSets[self.activeItemSetId]
	if self.build.configTab and not self.skipConfigItemSetSync then
		self.build.configTab:SyncActorItemSet("player", self.activeItemSetId)
	end
	local viewItemSetId = state.viewItemSetId
	if not self.itemSets[viewItemSetId] then
		viewItemSetId = self.activeItemSetId
	end
	self.viewItemSetId = viewItemSetId
	self.viewItemSet = self.itemSets[self.viewItemSetId]
	self.viewComparisonActor = state.viewComparisonActor
	for slotName, selItemId in pairs(state.slotSelItemId) do
		local slot = self.slots[slotName]
		if slot and slot.nodeId then slot:SetSelItemId(selItemId) end
	end
	self:PopulateSlots()
end
