-- Path of Building
--
-- Class: PassiveMasteryControl
-- Specialized UI element for selecting passive masteries
--

local ipairs = ipairs
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

---@class PassiveMasteryControl: ListControl<MasterListElem>
---@field list MasterListElem[]
---@field treeTab TreeTab
---@field treeView PassiveTreeView
---@field node Node
---@field saveButton ButtonControl
---@field selIndex? integer
---@field selValue? MasterListElem
local PassiveMasteryControlClass = newClass("PassiveMasteryControl", "ListControl")

---@class MasterListElem
---@field label string
---@field id number

---@param anchor Anchor?
---@param rect Rect
---@param list MasterListElem[]
---@param treeTab TreeTab
---@param node Node
---@param saveButton ButtonControl
---@return PassiveMasteryControl
function PassiveMasteryControlClass:PassiveMasteryControl(anchor, rect, list, treeTab, node, saveButton)
	self.list = list or { }
	-- automagical width
	for j=1,#list do
		rect[3] = m_max(rect[3], DrawStringWidth(16, "VAR", list[j].label) + 5)
	end
	self:ListControl(anchor, rect, 16, nil, false, self.list)
	self.treeTab = treeTab
	self.treeView = treeTab.viewer
	self.node = node
	self.selIndex = nil
	self.saveButton = saveButton
	return self
end

---@param viewPort Viewport
function PassiveMasteryControlClass:Draw(viewPort)
	self.ListControl.Draw(self, viewPort)
end

---@param column integer
---@param index integer
---@param effect MasterListElem
---@return string?
function PassiveMasteryControlClass:GetRowValue(column, index, effect)
	if column == 1 then
		return effect.label
	end
end

---@param tooltip Tooltip
---@param index integer
---@param effect MasterListElem
function PassiveMasteryControlClass:AddValueTooltip(tooltip, index, effect)
	tooltip:Clear()
	self.node.sd = self.treeTab.build.spec.tree.masteryEffects[effect.id].sd
	self.node.allMasteryOptions = false
	self.treeTab.build.spec.tree:ProcessStats(self.node)
	self.treeView:AddNodeTooltip(tooltip, self.node, self.treeTab.build)
end

---@param index integer
---@param mastery MasterListElem
---@param doubleClick? boolean
function PassiveMasteryControlClass:OnSelClick(index, mastery, doubleClick)
	self.treeTab:SaveMasteryPopup(self.node, self)
end