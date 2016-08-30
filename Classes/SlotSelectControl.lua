-- Path of Building
--
-- Class: Slot Select Control
-- Slot selector control, extends the basic dropdown control.
--
local launch, main = ...

local SlotSelectControlClass = common.NewClass("SlotSelectControl", "DropDownControl", function(self, anchor, x, y, width, height, build, selFunc)
	self.DropDownControl(anchor, x, y, width, height, { "None", "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2" }, selFunc)
	self.build = build
end)

function SlotSelectControlClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	self.DropDownControl:Draw(viewPort)
	if self:IsMouseOver() then
		local ttSlot
		if self.dropped then
			if self.hoverSel and self.hoverSel > 1 then
				ttSlot = self.list[self.hoverSel]
			end
		elseif self.sel > 1 then
			ttSlot = self.list[self.sel]
		end
		SetDrawLayer(nil, 100)
		if ttSlot then
			local ttItem = self.build.itemsTab.list[self.build.itemsTab.slots[ttSlot].selItemId]
			if ttItem then
				self.build.itemsTab:AddItemTooltip(ttItem, self)
				main:DrawTooltip(x, y, width, height, viewPort, data.colorCodes[ttItem.rarity], true)
			else
				main:AddTooltipLine(16, "No item is equipped in this slot.")
				main:DrawTooltip(x, y, width, height, viewPort)
			end
		else
			main:AddTooltipLine(16, "Select the item in which this skill is socketed.")
			main:AddTooltipLine(16, "This will allow the skill to benefit from modifiers on the item that affect socketed gems.")
			main:DrawTooltip(x, y, width, height, viewPort)
		end
		SetDrawLayer(nil, 0)
	end
end