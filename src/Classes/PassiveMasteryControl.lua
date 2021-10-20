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
local PassiveMasteryControlClass = newClass("PassiveMasteryControl", "ListControl", function(self, anchor, x, y, width, height, list, treeTab, node, tooltipText)
	self.list = list or { }
	self.ListControl(anchor, x, y, width, height, 16, false, false, self.list)
	self.treeTab = treeTab
	self.treeView = treeTab.viewer
	self.node = node
	self.selIndex = nil
end)

--  POB passive mastery UI
    -- Hover tooltip for mastery node lists options
    -- Clicking mastery node opens a panel that shows all options
        -- Hovering an option highlights the option in beige and displays a tooltip that shows allocation effect as if it was the node on the tree
        -- Clicking an option selects it, highlights it in white, and greys out other options


        -- Hovering a greyed out option compares it to the currently selected option

			-- Compare values of all display stats between the two output tables, and add any changed stats to the tooltip
			-- Adds the provided header line before the first stat line, if any are added
			-- Returns the number of stat lines added
			-- build:AddStatComparesToTooltip(tooltip, baseOutput, compareOutput, header, nodeCount)

        -- Clicking a greyed out option selects it instead and colors options appropriately
        -- Assign button closes the panel, assigns highlighted option to mastery node, and allocates it
        -- Cancel button closes the panel without assigning a mastery option to the mastery node or allocating it

		--make sure that you can also see the stat differences of allocating without hovering over the option itself.
		--like either add a tooltip to the Assign button like the Anoint menu has, or just show it all the time when the mastery UI is up


function PassiveMasteryControlClass:Draw(viewPort)
	self.ListControl.Draw(self, viewPort)
end

function PassiveMasteryControlClass:GetRowValue(column, index, effect)
	if column == 1 then
		return StripEscapes(type(effect) == "table" and effect.label or effect)
	end
end

function PassiveMasteryControlClass:AddValueTooltip(tooltip, index, effect)
	tooltip:Clear()
	self.node.sd = self.treeTab.build.spec.tree.masteryEffects[effect.id].sd
	self.node.allMasteryOptions = false
	self.treeTab.build.spec.tree:ProcessStats(self.node)
	self.treeView:AddNodeTooltip(tooltip, self.node, self.treeTab.build)
end