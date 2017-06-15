-- Path of Building
--
-- Class: Skill List
-- Skill list control.
--
local launch, main = ...

local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove

local SkillListClass = common.NewClass("SkillList", "ListControl", function(self, anchor, x, y, width, height, skillsTab)
	self.ListControl(anchor, x, y, width, height, 16, true, skillsTab.socketGroupList)
	self.skillsTab = skillsTab
	self.label = "^7Socket Groups:"
	self.controls.delete = common.New("ButtonControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, 0, -2, 60, 18, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil and self.selValue.source == nil
	end
	self.controls.deleteAll = common.New("ButtonControl", {"RIGHT",self.controls.delete,"LEFT"}, -4, 0, 70, 18, "Delete All", function()
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
	self.controls.new = common.New("ButtonControl", {"RIGHT",self.controls.deleteAll,"LEFT"}, -4, 0, 60, 18, "New", function()
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
end)

function SkillListClass:GetRowValue(column, index, socketGroup)
	if column == 1 then
		local label = socketGroup.displayLabel or "?"
		if not socketGroup.enabled or not socketGroup.slotEnabled then
			label = "^x7F7F7F" .. label .. " (Disabled)"
		end
		return label
	end
end

function SkillListClass:AddValueTooltip(index, socketGroup)
	if not socketGroup.displaySkillList then
		return
	end
	if socketGroup.enabled and not socketGroup.slotEnabled then
		main:AddTooltipLine(16, "^7Note: this group is disabled because it is socketed in the inactive weapon set.")
	end
	if socketGroup.sourceItem then
		main:AddTooltipLine(18, "^7Source: "..colorCodes[socketGroup.sourceItem.rarity]..socketGroup.sourceItem.name)
		main:AddTooltipSeparator(10)
	end
	local gemShown = { }
	for index, activeSkill in ipairs(socketGroup.displaySkillList) do
		if index > 1 then
			main:AddTooltipSeparator(10)
		end
		main:AddTooltipLine(16, "^7Active Skill #"..index..":")
		for _, gem in ipairs(activeSkill.gemList) do
			main:AddTooltipLine(20, string.format("%s%s ^7%d%s/%d%s", 
				data.skillColorMap[gem.grantedEffect.color], 
				gem.grantedEffect.name,
				gem.level, 
				(gem.srcGem and gem.level > gem.srcGem.level) and colorCodes.MAGIC.."+"..(gem.level - gem.srcGem.level).."^7" or "",
				gem.quality,
				(gem.srcGem and gem.quality > gem.srcGem.quality) and colorCodes.MAGIC.."+"..(gem.quality - gem.srcGem.quality).."^7" or ""
			))
			if gem.srcGem then
				gemShown[gem.srcGem] = true
			end
		end
		if activeSkill.minion then
			main:AddTooltipSeparator(10)
			main:AddTooltipLine(16, "^7Active Skill #"..index.."'s Main Minion Skill:")
			local gem = activeSkill.minion.mainSkill.gemList[1]
			main:AddTooltipLine(20, string.format("%s%s ^7%d%s/%d%s", 
				data.skillColorMap[gem.grantedEffect.color], 
				gem.grantedEffect.name, 
				gem.level, 
				(gem.srcGem and gem.level > gem.srcGem.level) and colorCodes.MAGIC.."+"..(gem.level - gem.srcGem.level).."^7" or "",
				gem.quality,
				(gem.srcGem and gem.quality > gem.srcGem.quality) and colorCodes.MAGIC.."+"..(gem.quality - gem.srcGem.quality).."^7" or ""
			))
			if gem.srcGem then
				gemShown[gem.srcGem] = true
			end
		end
	end
	local showOtherHeader = true
	for _, gem in ipairs(socketGroup.gemList) do
		if not gemShown[gem] then
			if showOtherHeader then
				showOtherHeader = false
				main:AddTooltipSeparator(10)
				main:AddTooltipLine(16, "^7Inactive Gems:")
			end
			local reason = ""
			local displayGem = gem.displayGem or gem
			if not gem.grantedEffect then
				reason = "(Unsupported)"
			elseif not gem.enabled then
				reason = "(Disabled)"
			elseif not socketGroup.enabled or not socketGroup.slotEnabled then
			elseif gem.grantedEffect.support then
				if displayGem.superseded then
					reason = "(Superseded)"
				elseif (not displayGem.isSupporting or not next(displayGem.isSupporting)) and #socketGroup.displaySkillList > 0 then
					reason = "(Cannot apply to any of the active skills)"
				end
			end
			main:AddTooltipLine(20, string.format("%s%s ^7%d%s/%d%s %s", 
				gem.color, 
				gem.grantedEffect and gem.grantedEffect.name or gem.nameSpec, 
				displayGem.level, 
				displayGem.level > gem.level and colorCodes.MAGIC.."+"..(displayGem.level - gem.level).."^7" or "",
				displayGem.quality,
				displayGem.quality > gem.quality and colorCodes.MAGIC.."+"..(displayGem.quality - gem.quality).."^7" or "",
				reason
			))
		end
	end
end

function SkillListClass:OnOrderChange()
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
	if socketGroup.source then
		main:OpenMessagePopup("Delete Socket Group", "This socket group cannot be deleted as it is created by an equipped item.")
	elseif not socketGroup.gemList[1] then
		t_remove(self.list, index)
		if self.skillsTab.displayGroup == socketGroup then
			self.skillsTab.displayGroup = nil
		end
		self.skillsTab:AddUndoState()
		self.skillsTab.build.buildFlag = true
		self.selValue = nil
	else
		main:OpenConfirmPopup("Delete Socket Group", "Are you sure you want to delete '"..socketGroup.displayLabel.."'?", "Delete", function()
			t_remove(self.list, index)
			if self.skillsTab.displayGroup == socketGroup then
				self.skillsTab:SetDisplayGroup()
			end
			self.skillsTab:AddUndoState()
			self.skillsTab.build.buildFlag = true
			self.selValue = nil
		end)
	end
end
