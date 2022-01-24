-- Path of Building
--
-- Class: PassiveMasteryControl
-- Specialized UI element for selecting passive masteries
--

local ipairs = ipairs
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

--constructor
local PassiveMasteryControlClass = newClass("PassiveMasteryControl", "ListControl", function(self, anchor, x, y, width, height, list, treeTab, node, saveButton)
	self.list = list or { }
	-- automagical width
	for j=1,#list do
		width = m_max(width, DrawStringWidth(16, "VAR", list[j].label) + 5)
	end
	self.ListControl(anchor, x, y, width, height, 16, false, false, self.list)
	self.treeTab = treeTab
	self.treeView = treeTab.viewer
	self.node = node
	self.selIndex = nil
	self.saveButton = saveButton
end)

function PassiveMasteryControlClass:Draw(viewPort)
	self.ListControl.Draw(self, viewPort)
end

function PassiveMasteryControlClass:GetRowValue(column, index, effect)
	if column == 1 then
		return effect.label
	end
end

function PassiveMasteryControlClass:AddValueTooltip(tooltip, index, effect)
	tooltip:Clear()
	self.node.sd = self.treeTab.build.spec.tree.masteryEffects[effect.id].sd
	self.node.allMasteryOptions = false
	self.treeTab.build.spec.tree:ProcessStats(self.node)
	self.treeView:AddNodeTooltip(tooltip, self.node, self.treeTab.build)
end

function PassiveMasteryControlClass:OnSelClick(index, mastery, doubleClick)
	self.treeTab:SaveMasteryPopup(self.node, self)
end