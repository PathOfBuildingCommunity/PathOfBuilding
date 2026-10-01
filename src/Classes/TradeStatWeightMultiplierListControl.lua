-- Path of Building
--
-- Class: Trade Stat Weight Multiplier List Control
-- Specialized UI element for listing and modifying Trade Stat Weight Multipliers.
--

---@class TradeStatWeightMultiplier
---@field label string
---@field stat { label: string, weightMult: number }

---@class TradeStatWeightMultiplierIndexController
---@field index? integer
---@field SliderLabel LabelControl
---@field Slider SliderControl
---@field SliderValue LabelControl

---@class TradeStatWeightMultiplierListControl: ListControl<TradeStatWeightMultiplier>
---@field list TradeStatWeightMultiplier[]
---@field indexController TradeStatWeightMultiplierIndexController
---@field selIndex? integer
---@field noTooltip? boolean
local TradeStatWeightMultiplierListControlClass = newClass("TradeStatWeightMultiplierListControl", "ListControl")

---@param anchor? Anchor
---@param rect? Rect
---@param list TradeStatWeightMultiplier[]
---@param indexController TradeStatWeightMultiplierIndexController
---@return TradeStatWeightMultiplierListControl
function TradeStatWeightMultiplierListControlClass:TradeStatWeightMultiplierListControl(anchor, rect, list, indexController)
	self.list = list
	self.indexController = indexController
	self:ListControl(anchor, rect, 16, true, false, self.list)
	self.selIndex = nil
	return self
end

---@param viewPort Viewport
---@param noTooltip? boolean
function TradeStatWeightMultiplierListControlClass:Draw(viewPort, noTooltip)
	self.noTooltip = noTooltip
	self.ListControl.Draw(self, viewPort)
end

---@param column integer
---@param index integer
---@param data TradeStatWeightMultiplier
---@return string?
function TradeStatWeightMultiplierListControlClass:GetRowValue(column, index, data)
	if column == 1 then
		return data.label
	end
end

---@param tooltip Tooltip
---@param index integer
---@param data TradeStatWeightMultiplier
function TradeStatWeightMultiplierListControlClass:AddValueTooltip(tooltip, index, data)
	tooltip:Clear()
	if not self.noTooltip then
		tooltip:AddLine(16, "^7Click to modify this stats weight multiplier.")
	end
end

---@param index integer
---@param data TradeStatWeightMultiplier
---@param doubleClick? boolean
function TradeStatWeightMultiplierListControlClass:OnSelClick(index, data, doubleClick)
	if self.indexController.index ~= index then
		self.indexController.index = index
		self.indexController.SliderLabel.label = self.list[index].stat.label
		self.indexController.Slider:SetVal(self.list[index].stat.weightMult == 1 and 1 or self.list[index].stat.weightMult - 0.01)
	end
end
