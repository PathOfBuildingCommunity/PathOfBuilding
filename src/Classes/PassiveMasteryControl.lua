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
	if width == 0 then
		-- do not be smaller than this width
		width = 579
		for j=1,#list do
			width = m_max(width, DrawStringWidth(16, "VAR", list[j].label) + 5)
		end
	end
	self.ListControl(anchor, x, y, width, height, 16, false, false, self.list)
	self.treeTab = treeTab
	self.treeView = treeTab.viewer
	self.node = node
	self.selIndex = nil
	self.saveButton = saveButton
end)

--  POB passive mastery UI
-- TODO
        -- Hovering a greyed out option compares it to the currently selected option
			-- Compare values of all display stats between the two output tables, and add any changed stats to the tooltip

		--make sure that you can also see the stat differences of allocating without hovering over the option itself.
		--like either add a tooltip to the Assign button like the Anoint menu has, or just show it all the time when the mastery UI is up


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
	if doubleClick then
		self.saveButton:Click()
	end
end