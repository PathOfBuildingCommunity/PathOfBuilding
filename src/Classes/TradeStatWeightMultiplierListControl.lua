-- Path of Building
--
-- Class: Trade Stat Weight Multiplier List Control
-- Specialized UI element for listing and modifying Trade Stat Weight Multipliers.
--

local TradeStatWeightMultiplierListControlClass = newClass("TradeStatWeightMultiplierListControl", "ListControl", function(self, anchor, x, y, width, height, list, indexController)
	self.list = list
	self.indexController = indexController
	self.ListControl(anchor, x, y, width, height, 16, true, false, self.list)
	self.selIndex = nil
end)

function TradeStatWeightMultiplierListControlClass:Draw(viewPort, noTooltip)
	self.noTooltip = noTooltip
	self.ListControl.Draw(self, viewPort)
end

function TradeStatWeightMultiplierListControlClass:GetRowValue(column, index, data)
	if column == 1 then
		return data.label
	end
end

function TradeStatWeightMultiplierListControlClass:AddValueTooltip(tooltip, index, data)
	tooltip:Clear()
	if not self.noTooltip then
		tooltip:AddLine(16, "^7Double click to modify this stats weight multiplier.")
	end
end

function TradeStatWeightMultiplierListControlClass:OnSelClick(index, data, doubleClick)
	if self.indexController.index ~= index then
		self.indexController.index = index
		self.indexController.SliderLabel.label = self.list[index].stat.label
		self.indexController.Slider:SetVal(self.list[index].stat.weightMult == 1 and 1 or self.list[index].stat.weightMult - 0.01)
	end
end
