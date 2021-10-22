-- Path of Building
--
-- Class: Minion List
-- Minion list control.
--
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local s_format = string.format

local MinionListClass = newClass("MinionListControl", "ListControl", function(self, anchor, x, y, width, height, data, list, dest)
	self.ListControl(anchor, x, y, width, height, 16, "VERTICAL", not dest, list)
	self.data = data
	self.dest = dest
	if dest then
		self.dragTargetList = { dest }
		self.label = "^7Available Spectres:"
		self.controls.add = new("ButtonControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, 0, -2, 60, 18, "Add", function()
			self:AddSel()
		end)
		self.controls.add.enabled = function()
			return self.selValue ~= nil and not isValueInArray(dest.list, self.selValue)
		end
	else
		self.label = "^7Spectres in Build:"
		self.controls.delete = new("ButtonControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, 0, -2, 60, 18, "Remove", function()
			self:OnSelDelete(self.selIndex, self.selValue)
		end)
		self.controls.delete.enabled = function()
			return self.selValue ~= nil
		end
	end		
end)

function MinionListClass:AddSel()
	if self.dest and not isValueInArray(self.dest.list, self.selValue) then
		t_insert(self.dest.list, self.selValue)
	end
end

function MinionListClass:GetRowValue(column, index, minionId)
	local minion = self.data.minions[minionId]
	if column == 1 then
		return minion.name
	end
end

function MinionListClass:AddValueTooltip(tooltip, index, minionId)
	if tooltip:CheckForUpdate(minionId) then
		local minion = self.data.minions[minionId]
		tooltip:AddLine(18, "^7"..minion.name)
		tooltip:AddLine(14, s_format("^7Life multiplier: x%.2f", minion.life))
		if minion.energyShield then
			tooltip:AddLine(14, s_format("^7Energy Shield: %d%% of base Life", minion.energyShield * 100))
		end
		if minion.armour then
			tooltip:AddLine(14, s_format("^7Armour multiplier: x%.2f", minion.armour))
		end
		tooltip:AddLine(14, s_format("^7Resistances: %s%d^7/%s%d^7/%s%d^7/%s%d", 
			colorCodes.FIRE, minion.fireResist, 
			colorCodes.COLD, minion.coldResist, 
			colorCodes.LIGHTNING, minion.lightningResist, 
			colorCodes.CHAOS, minion.chaosResist
		))
		tooltip:AddLine(14, s_format("^7Base damage: x%.2f", minion.damage))
		tooltip:AddLine(14, s_format("^7Base attack speed: %.2f", 1 / minion.attackTime))
		for _, skillId in ipairs(minion.skillList) do
			if self.data.skills[skillId] then
				tooltip:AddLine(14, "^7Skill: "..self.data.skills[skillId].name)
			end
		end
	end
end

function MinionListClass:GetDragValue(index, value)
	return "MinionId", value
end

function MinionListClass:CanReceiveDrag(type, value)
	return type == "MinionId" and not isValueInArray(self.list, value)
end

function MinionListClass:ReceiveDrag(type, value, source)
	t_insert(self.list, self.selDragIndex or #self.list + 1, value)
end

function MinionListClass:OnSelClick(index, minionId, doubleClick)
	if doubleClick and self.dest then
		self:AddSel()
	end
end

function MinionListClass:OnSelDelete(index, minionId)
	if not self.dest then
		t_remove(self.list, index)
		self.selIndex = nil
		self.selValue = nil
	end
end
