-- Path of Building
--
-- Class: Radius Jewel Detail List Control
-- Displays result details with passive-node and item previews.
--

local ipairs = ipairs

local placeTooltip = LoadModule("Classes/RadiusJewelTooltipPlacement").placeTooltip

---@class RadiusJewelDetailListControl: TextListControl
local RadiusJewelDetailListClass = newClass("RadiusJewelDetailListControl", "TextListControl")

function RadiusJewelDetailListClass:RadiusJewelDetailListControl(anchor, rect, columns, list, build, socketViewer)
	self:TextListControl(anchor, rect, columns, list)
	self.build = build
	self.socketViewer = socketViewer
	self.nodeTooltip = new("Tooltip"):Tooltip()
	self.itemTooltip = new("Tooltip"):Tooltip()
	return self
end

function RadiusJewelDetailListClass:GetHoverLine()
	if not self:IsShown() or not self:IsMouseInBounds() then
		return nil
	end
	local cursorX, cursorY = GetCursorPos()
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	if cursorX < x + 2 or cursorX > x + width - 20 or cursorY < y + 2 or cursorY > y + height - 2 then
		return nil
	end
	local lineY = y + 2 - self.controls.scrollBar.offset
	for _, lineInfo in ipairs(self.list or { }) do
		if cursorY >= lineY and cursorY < lineY + lineInfo.height then
			return lineInfo
		end
		lineY = lineY + lineInfo.height
	end
	return nil
end

function RadiusJewelDetailListClass:Draw(viewPort)
	self.TextListControl.Draw(self, viewPort)
	local hoverLine = self:GetHoverLine()
	if not hoverLine or main.popups[2] then
		return
	end

	local cursorX, cursorY = GetCursorPos()
	if hoverLine.item then
		SetDrawLayer(nil, 100)
		if self.itemTooltip:CheckForUpdate(hoverLine.item, IsKeyDown("SHIFT"), launch.devModeAlt, self.build.outputRevision) then
			self.build.itemsTab:AddItemTooltip(self.itemTooltip, hoverLine.item)
		end
		local ttW, ttH = self.itemTooltip:GetSize()
		local ttX, ttY = placeTooltip(viewPort, ttW, ttH, cursorX, cursorY)
		self.itemTooltip:Draw(ttX, ttY, nil, nil, viewPort)
		SetDrawLayer(nil, 0)
		return
	end
	if not hoverLine.nodeId then
		return
	end
	local node = self.build.spec.nodes[hoverLine.nodeId] or self.build.spec.tree.nodes[hoverLine.nodeId]
	if not node then
		return
	end
	local viewerRect
	SetDrawLayer(nil, 15)
	local viewerX = cursorX + 20
	local viewerY = cursorY - 150
	if viewerX + 304 > viewPort.x + viewPort.width then viewerX = cursorX - 324 end
	if viewerY < viewPort.y then viewerY = viewPort.y elseif viewerY + 304 > viewPort.y + viewPort.height then viewerY = viewPort.y + viewPort.height - 304 end
	viewerRect = { x = viewerX, y = viewerY, width = 304, height = 304 }

	SetDrawColor(1, 1, 1)
	DrawImage(nil, viewerX, viewerY, 304, 304)
	self.socketViewer.zoom = 5
	local scale = self.build.spec.tree.size / 1500
	self.socketViewer.zoomX = -node.x / scale
	self.socketViewer.zoomY = -node.y / scale
	self.socketViewer.searchStrResults[hoverLine.nodeId] = true
	SetViewport(viewerX + 2, viewerY + 2, 300, 300)
	self.socketViewer:Draw(self.build, { x = 0, y = 0, width = 300, height = 300 }, { })
	self.socketViewer.searchStrResults[hoverLine.nodeId] = nil
	SetDrawLayer(nil, 30)
	SetDrawColor(1, 1, 1, 0.2)
	DrawImage(nil, 149, 0, 2, 300)
	DrawImage(nil, 0, 149, 300, 2)
	SetViewport()

	SetDrawLayer(nil, 100)
	if self.nodeTooltip:CheckForUpdate(node, true, self.socketViewer.tracePath, launch.devModeAlt,
		self.build.outputRevision, self.build.spec.allocMode) then
		local prevShowStatDifferences = self.socketViewer.showStatDifferences
		self.socketViewer.showStatDifferences = true
		self.socketViewer:AddNodeTooltip(self.nodeTooltip, node, self.build)
		self.socketViewer.showStatDifferences = prevShowStatDifferences
	end
	local ttW, ttH = self.nodeTooltip:GetSize()
	local ttX, ttY = placeTooltip(viewPort, ttW, ttH, cursorX, cursorY, { viewerRect })
	self.nodeTooltip:Draw(ttX, ttY, nil, nil, viewPort)
	SetDrawLayer(nil, 0)
end
