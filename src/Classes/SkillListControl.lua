-- Path of Building
--
-- Class: Skill List
-- Skill list control.
--
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local slot_map = {
	["Weapon 1"] 		= { icon = NewImageHandle(), path = "Assets/icon_weapon.png" },
	["Weapon 2"] 		= { icon = NewImageHandle(), path = "Assets/icon_weapon_2.png" },
	["Weapon 1 Swap"] 	= { icon = NewImageHandle(), path = "Assets/icon_weapon_swap.png" },
	["Weapon 2 Swap"] 	= { icon = NewImageHandle(), path = "Assets/icon_weapon_2_swap.png" },
	["Bow"] 			= { icon = NewImageHandle(), path = "Assets/icon_bow.png" },
	["Quiver"] 			= { icon = NewImageHandle(), path = "Assets/icon_quiver.png" },
	["Shield"] 			= { icon = NewImageHandle(), path = "Assets/icon_shield.png" },
	["Shield Swap"] 	= { icon = NewImageHandle(), path = "Assets/icon_shield_swap.png" },
	["Helmet"] 			= { icon = NewImageHandle(), path = "Assets/icon_helmet.png" },
	["Body Armour"] 	= { icon = NewImageHandle(), path = "Assets/icon_body_armour.png" },
	["Gloves"] 			= { icon = NewImageHandle(), path = "Assets/icon_gloves.png" },
	["Boots"] 			= { icon = NewImageHandle(), path = "Assets/icon_boots.png" },
	["Amulet"] 			= { icon = NewImageHandle(), path = "Assets/icon_amulet.png" },
	["Ring 1"] 			= { icon = NewImageHandle(), path = "Assets/icon_ring_left.png" },
	["Ring 2"] 			= { icon = NewImageHandle(), path = "Assets/icon_ring_right.png" },
	["Belt"] 			= { icon = NewImageHandle(), path = "Assets/icon_belt.png" },
}

local SkillListClass = newClass("SkillListControl", "ListControl", function(self, anchor, x, y, width, height, skillsTab)
	self.ListControl(anchor, x, y, width, height, 16, "VERTICAL", true, skillsTab.socketGroupList)
	self.skillsTab = skillsTab
	self.label = "^7Socket Groups:"
	self.controls.delete = new("ButtonControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, 0, -2, 60, 18, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil and self.selValue.source == nil
	end
	self.controls.deleteAll = new("ButtonControl", {"RIGHT",self.controls.delete,"LEFT"}, -4, 0, 70, 18, "Delete All", function()
		main:OpenConfirmPopup("Delete All", "Are you sure you want to delete all socket groups in this build?", "Delete", function()
			wipeTable(self.list)
			skillsTab:SetDisplayGroup()
			skillsTab:AddUndoState()
			skillsTab.build.buildFlag = true
			self.selIndex = nil
			self.selValue = nil
		end)
	end)
	self.controls.deleteAll.enabled = function()
		return #self.list > 0 
	end
	self.controls.new = new("ButtonControl", {"RIGHT",self.controls.deleteAll,"LEFT"}, -4, 0, 60, 18, "New", function()
		local newGroup = { 
			label = "", 
			enabled = true, 
			gemList = { } 
		}
		t_insert(self.list, newGroup)
		self.selIndex = #self.list
		self.selValue = newGroup
		skillsTab:SetDisplayGroup(newGroup)
		skillsTab:AddUndoState()
		skillsTab.build.buildFlag = true
		return skillsTab.gemSlots[1].nameSpec
	end)
	for k, x in pairs(slot_map) do
		x.icon:Load(x.path)
	end
end)

function SkillListClass:GetRowValue(column, index, socketGroup)
	if column == 1 then
		local label = socketGroup.displayLabel or "?"
		local currentMainSkill = self.skillsTab.build.mainSocketGroup == index
		local disabled = not socketGroup.enabled or not socketGroup.slotEnabled
		if disabled then
			local colour = currentMainSkill and "" or "^x7F7F7F"
			label = colour .. label .. " (Disabled)"
		end
		if currentMainSkill then 
			local activeLabel = disabled and " (Forced Active)" or " (Active)"
			label = label .. colorCodes.RELIC .. activeLabel
		end
		if socketGroup.includeInFullDPS then 
			label = label .. colorCodes.CUSTOM .. " (FullDPS)"
		end
		return label
	end
end

function SkillListClass:AddValueTooltip(tooltip, index, socketGroup)
	if not socketGroup.displaySkillList then
		tooltip:Clear()
		return
	end
	if tooltip:CheckForUpdate(socketGroup, self.skillsTab.build.outputRevision) then
		self.skillsTab:AddSocketGroupTooltip(tooltip, socketGroup)
	end
end

function SkillListClass:OnOrderChange(selIndex, selDragIndex)
	local skillsTabIndex = self.skillsTab.build.mainSocketGroup
	if skillsTabIndex == selIndex then
		self.skillsTab.build.mainSocketGroup = selDragIndex
	elseif skillsTabIndex > selIndex and skillsTabIndex <= selDragIndex then
		self.skillsTab.build.mainSocketGroup = skillsTabIndex - 1
	elseif skillsTabIndex < selIndex and skillsTabIndex >= selDragIndex then
		self.skillsTab.build.mainSocketGroup = skillsTabIndex + 1
	end
	local calcsTabIndex = self.skillsTab.build.calcsTab.input.skill_number
	if calcsTabIndex == selIndex then
		self.skillsTab.build.calcsTab.input.skill_number = selDragIndex
	elseif calcsTabIndex > selIndex and calcsTabIndex <= selDragIndex then
		self.skillsTab.build.calcsTab.input.skill_number = calcsTabIndex - 1
	elseif calcsTabIndex < selIndex and calcsTabIndex >= selDragIndex then
		self.skillsTab.build.calcsTab.input.skill_number = calcsTabIndex + 1
	end
	self.skillsTab:AddUndoState()
	self.skillsTab.build.buildFlag = true
end

function SkillListClass:OnSelect(index, socketGroup)
	self.skillsTab:SetDisplayGroup(socketGroup)
end

function SkillListClass:OnSelCopy(index, socketGroup)
	if not socketGroup.source then	
		self.skillsTab:CopySocketGroup(socketGroup)
	end
end

function SkillListClass:OnSelDelete(index, socketGroup)
	local function updateActiveSocketGroupIndex()
		local skillsTabIndex = self.skillsTab.build.mainSocketGroup
		if skillsTabIndex > self.selIndex then
			self.skillsTab.build.mainSocketGroup = skillsTabIndex - 1
		end
		local calcsTabIndex = self.skillsTab.build.calcsTab.input.skill_number
		if calcsTabIndex > self.selIndex then
			self.skillsTab.build.calcsTab.input.skill_number = calcsTabIndex - 1
		end
	end
	if socketGroup.source then
		main:OpenMessagePopup("Delete Socket Group", "This socket group cannot be deleted as it is created by an equipped item.")
	elseif not socketGroup.gemList[1] then
		t_remove(self.list, index)
		if self.skillsTab.displayGroup == socketGroup then
			self.skillsTab.displayGroup = nil
		end
		updateActiveSocketGroupIndex()
		self.skillsTab:AddUndoState()
		self.skillsTab.build.buildFlag = true
		self.selValue = nil
	else
		main:OpenConfirmPopup("Delete Socket Group", "Are you sure you want to delete '"..socketGroup.displayLabel.."'?", "Delete", function()
			t_remove(self.list, index)
			if self.skillsTab.displayGroup == socketGroup then
				self.skillsTab:SetDisplayGroup()
			end
			updateActiveSocketGroupIndex()
			self.skillsTab:AddUndoState()
			self.skillsTab.build.buildFlag = true
			self.selValue = nil
		end)
	end
end

function SkillListClass:OnHoverKeyUp(key)
	local item = self.ListControl:GetHoverValue()
	if item then
		if itemLib.wiki.matchesKey(key) then
			-- Get the first gem in the group
			local gem = item.gemList[1]
			if gem then
				-- either the skill is from a gem or granted from an item/passive
				itemLib.wiki.openGem(gem.gemData or gem.grantedEffect.name)
			end
		elseif key == "RIGHTBUTTON" then
			if IsKeyDown("CTRL") then
				item.includeInFullDPS = not item.includeInFullDPS
				if item == self.skillsTab.displayGroup then
					self.skillsTab:SetDisplayGroup(item)
				end
				self.skillsTab:AddUndoState()
				self.skillsTab.build.buildFlag = true
			else
				local index = self.ListControl:GetHoverIndex()
				if index then
					self.skillsTab.build.mainSocketGroup = index
					self.skillsTab:AddUndoState()
					self.skillsTab.build.buildFlag = true
				end
			end
		elseif key == "LEFTBUTTON" and IsKeyDown("CTRL") then
			item.enabled = not item.enabled
			if item == self.skillsTab.displayGroup then
				self.skillsTab:SetDisplayGroup(item)
			end
			self.skillsTab:AddUndoState()
			self.skillsTab.build.buildFlag = true
		end
	end
end


function SkillListClass:Draw(viewPort)
	self.ListControl.Draw(self, viewPort)
end

function SkillListClass:GetRowIcon(column, index, socketGroup)
	if column == 1 then
		local slot = socketGroup.slot
		local itemsTab = self.skillsTab.build.itemsTab
		local weapon1Sel = itemsTab.activeItemSet["Weapon 1"].selItemId or 0
		local weapon1Type = itemsTab.items[weapon1Sel] and itemsTab.items[weapon1Sel].base.type or "None"
		local weapon1SwapSel = itemsTab.activeItemSet["Weapon 1 Swap"].selItemId or 0
		local weapon1SwapType = itemsTab.items[weapon1SwapSel] and itemsTab.items[weapon1SwapSel].base.type or "None"
		local weapon2Sel = itemsTab.activeItemSet["Weapon 2"].selItemId or 0
		local weapon2Type = itemsTab.items[weapon2Sel] and itemsTab.items[weapon2Sel].base.type or "None"
		local weapon2SwapSel = itemsTab.activeItemSet["Weapon 2 Swap"].selItemId or 0
		local weapon2SwapType = itemsTab.items[weapon2SwapSel] and itemsTab.items[weapon2SwapSel].base.type or "None"
		if slot == "Weapon 1" and weapon1Type == "Bow" then
			slot = weapon1Type
		end
		if slot == "Weapon 1 Swap" and weapon1SwapType == "Bow" then
			slot = weapon1SwapType.." Swap"
		end
		if slot == "Weapon 2" and (weapon2Type == "Quiver" or weapon2Type == "Shield") then
			slot = weapon2Type
		end
		if slot == "Weapon 2 Swap" and (weapon2SwapType == "Quiver" or weapon2SwapType == "Shield") then
			slot = weapon2SwapType.." Swap"
		end
		return slot_map[slot] and slot_map[slot].icon
	end
end
