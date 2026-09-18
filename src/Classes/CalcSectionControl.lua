-- Path of Building
--
-- Class: Calc Section Control
-- Section control used in the Calcs tab
--
local t_insert = table.insert
local m_max = math.max
local m_min = math.min

---@class CalcSectionControl: Control, ControlHost
local CalcSectionClass = newClass("CalcSectionControl", "Control", "ControlHost")

---@param calcsTab CalcsTab
---@param width any
---@param id any
---@param group any
---@param colour any
---@param subSection any
---@param updateFunc any
function CalcSectionClass:CalcSectionControl(calcsTab, width, id, group, colour, subSection, updateFunc)
	self:Control(calcsTab, {0, 0, width, 0})
	self:ControlHost()
	self.calcsTab = calcsTab
	self.id = id
	self.group = group
	self.colour = colour
	self.width = width
	self.subSection = subSection
	self.flag = subSection[1].data.flag
	self.notFlag = subSection[1].data.notFlag
	self.updateFunc = updateFunc

	for i, subSec in ipairs(self.subSection) do
		subSec.id = subSec.label:gsub("%W", "")

		for _, data in ipairs(subSec.data) do
			for _, colData in ipairs(data) do
				colData.calcSection = self
				if colData.control then
					self.hasControls = true
					-- Add control to the section's control list and set show/hide function
					self.controls[colData.controlName] = colData.control
					colData.control.shown = function()
						return self.enabled and not self.subSection[1].collapsed and not subSec.collapsed and data.enabled
					end
				end
			end
		end
		subSec.collapsed = subSec.defaultCollapsed
		self.controls["toggle"..i] = new("ButtonControl"):ButtonControl({"TOPRIGHT",self,"TOPRIGHT"}, {-3, -13 + (16 * i), 16, 16}, function()
			return subSec.collapsed and "+" or "-"
		end, function()
			subSec.collapsed = not subSec.collapsed
			self.calcsTab.modFlag = true
		end)
		if i == 1 then
			self.controls["toggle"..i].shown = function()
				return self.enabled
			end
		else
			self.controls["toggle"..i].shown = function()
				return self.enabled and not self.subSection[1].collapsed
			end
		end
	end
	self.controls.popOut = new("ButtonControl"):ButtonControl({"TOPRIGHT",self,"TOPRIGHT"}, {-22, 3, 16, 16}, "^", function()
		self:ToggleOverlay()
	end)
	self.controls.popOut.shown = function()
		return self.enabled and not self.isOverlay and not self.hasControls
	end
	self.isOverlay = false
	self.overlayX = 320
	self.overlayY = 50
	self.dragging = false
	self.dragOffX = 0
	self.dragOffY = 0
	self.shown = function()
		return self.enabled and not self.isOverlay
	end
	return self
end

function CalcSectionClass:IsMouseOver()
	if not self:IsShown() then
		return
	end
	if self:GetMouseOverControl() then
		return true
	end
	local mOver = self:IsMouseInBounds()
	for _, subSec in ipairs(self.subSection) do
		if mOver and not subSec.collapsed and self.enabled then
			-- Check if mouse is over one of the cells
			local cursorX, cursorY = GetCursorPos()
			for _, data in ipairs(subSec.data) do
				if data.enabled then
					for _, colData in ipairs(data) do
						if colData.control then
						if colData.control:IsMouseOver() then
							return mOver, colData
						end
					elseif cursorX >= colData.x and cursorY >= colData.y and cursorX < colData.x + colData.width and cursorY < colData.y + colData.height then
						return mOver, colData
					end
				end
				end
			end
		end
	end
	return mOver
end

function CalcSectionClass:UpdateSize()
	self.enabled = self.calcsTab:CheckFlag(self)
	if not self.enabled then
		self.height = 22
		return
	end
	local x, y = self:GetPos()
	local width = self:GetSize()
	self.height = 2
	self.enabled = false
	local yOffset = 0
	for i, subSec in ipairs(self.subSection) do
		self.controls["toggle"..i].y = yOffset + 3
		local tempHeight = 0
		yOffset = yOffset + 22
		for _, rowData in ipairs(subSec.data) do
			rowData.enabled = self.calcsTab:CheckFlag(rowData)
			if rowData.enabled then
				self.enabled = true
				local xOffset = 134
				for colour, colData in ipairs(rowData) do
					colData.xOffset = xOffset
					colData.yOffset = yOffset
					colData.width = subSec.data.colWidth or width - 136
					colData.height = 18
					xOffset = xOffset + colData.width
				end
				yOffset = yOffset + 18
				self.height = self.height + 18
				tempHeight = tempHeight + 18
			end
			if subSec.collapsed then
				rowData.enabled = false
			end
		end
		if self.enabled and not subSec.collapsed then
			self.height = self.height + 22
		else
			self.height = self.height - tempHeight + 20
			yOffset = yOffset - tempHeight - 2
		end
	end
	if self.enabled and not self.subSection[1].collapsed then
		if self.updateFunc then
			self:updateFunc()
		end
	else
		self.height = 22
	end
end

function CalcSectionClass:UpdatePos()
	if not self.enabled then
		return
	end
	local x, y = self:GetPos()
	for _, subSec in ipairs(self.subSection) do
		for _, rowData in ipairs(subSec.data) do
			if rowData.enabled then
				for colour, colData in ipairs(rowData) do
					-- Update the real coordinates of this cell
					colData.x = x + colData.xOffset
					colData.y = y + colData.yOffset
				if colData.control then
					colData.control.x = colData.x + 4
					colData.control.y = colData.y + 9 - colData.control.height/2
				end
			end
			end
		end
	end
end

local function sectionFormatActor(calcsTab)
	local actor = calcsTab:GetDisplayActor(calcsTab.calcsEnv)
	if actor then
		return actor
	end
	-- Actor Status formats calcsOutput directly. Do not invent mainSkill/skillFlags.
	return { output = calcsTab.calcsOutput or { } }
end

function CalcSectionClass:Draw(viewPort, noTooltip)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local actor = sectionFormatActor(self.calcsTab)
	-- Draw border and background
	SetDrawLayer(nil, -10)
	SetDrawColor(self.colour)
	DrawImage(nil, x, y, width, height)
	SetDrawColor(0.10, 0.10, 0.10)
	DrawImage(nil, x + 2, y + 2, width - 4, height - 4)

	self:DrawContent(x, y, width, actor, viewPort, false, noTooltip)
end

function CalcSectionClass:OnKeyDown(key, doubleClick)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local mOverControl = self:GetMouseOverControl()
	if mOverControl and mOverControl.OnKeyDown then
		return mOverControl:OnKeyDown(key)
	end
	local mOver, mOverComp = self:IsMouseOver()
	if key:match("BUTTON") then
		if not mOver then
			return
		end
		if mOverComp then
			-- Pin the stat breakdown
			self.calcsTab:SetDisplayStat(mOverComp, true)
			return self.calcsTab.controls.breakdown
		end
	end
	return
end

function CalcSectionClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local mOverControl = self:GetMouseOverControl()
	if mOverControl and mOverControl.OnKeyUp then
		return mOverControl:OnKeyUp(key)
	end
	return
end

function CalcSectionClass:ToggleOverlay()
	self.isOverlay = not self.isOverlay
	if self.isOverlay then
		local x, y = self:GetPos()
		self.overlayX = x
		self.overlayY = y
		t_insert(self.calcsTab.build.overlayPanes, self)
	else
		local panes = self.calcsTab.build.overlayPanes
		for i, pane in ipairs(panes) do
			if pane == self then
				table.remove(panes, i)
				break
			end
		end
		self.dragging = false
	end
end

function CalcSectionClass:RaiseOverlay()
	local panes = self.calcsTab.build.overlayPanes
	for i, pane in ipairs(panes) do
		if pane == self then
			table.remove(panes, i)
			t_insert(panes, self)
			break
		end
	end
end

function CalcSectionClass:IsMouseInOverlay(cursorX, cursorY)
	if not self.isOverlay or not self.calcsTab.calcsEnv then return false end
	local x = self.overlayX
	local y = self.overlayY
	if cursorX < x or cursorX > x + self.width or cursorY < y then return false end
	return cursorY < y + self:GetOverlayHeight()
end

function CalcSectionClass:GetOverlayHeight()
	local height = 28
	local enabled = self.calcsTab.calcsEnv and self.calcsTab:CheckFlag(self)
	for i, subSec in ipairs(self.subSection) do
		height = height + 22
		if not subSec.collapsed and enabled then
			for _, rowData in ipairs(subSec.data) do
				if self.calcsTab:CheckFlag(rowData) then
					height = height + 18
				end
			end
			height = height + 2
		elseif i == 1 then
			break
		end
	end
	return height
end

function CalcSectionClass:HandleOverlayClick(key, cursorX, cursorY)
	if key ~= "LEFTBUTTON" then return end

	self:RaiseOverlay()

	local x = self.overlayX
	local y = self.overlayY
	local overlayWidth = self.width

	-- Check close button
	local closeX = x + overlayWidth - 18
	local closeY = y + 2
	if cursorX >= closeX and cursorX <= closeX + 14 and cursorY >= closeY and cursorY <= closeY + 16 then
		self:ToggleOverlay()
		return
	end

	local lineY = y + 26
	local primary = true
	for i, subSec in ipairs(self.subSection) do
		local secEnabled = self.calcsTab:CheckFlag(self)

		-- Check subsection toggle
		if secEnabled then
			local toggleX = x + overlayWidth - 18
			local toggleY = lineY + 3
			if cursorX >= toggleX and cursorX <= toggleX + 14 and cursorY >= toggleY and cursorY <= toggleY + 16 then
				subSec.collapsed = not subSec.collapsed
				self.overlayRevision = nil
				self.calcsTab.modFlag = true
				return
			end
		end

		if subSec.collapsed or not secEnabled then
			if primary then
				break
			else
				lineY = lineY + 20
				primary = false
			end
		else
			lineY = lineY + 20
			primary = false
			for _, rowData in ipairs(subSec.data) do
				if self.calcsTab:CheckFlag(rowData) then
					for _, colData in ipairs(rowData) do
						local cellX = x + (colData.xOffset or 134)
						local cellW = colData.width or (overlayWidth - 136)
						if cursorX >= cellX and cursorX <= cellX + cellW and cursorY >= lineY + 2 and cursorY <= lineY + 19 then
							if colData.format and self.calcsTab:CheckFlag(colData) then
								self.calcsTab:SetDisplayStat(colData, true)
							end
							return
						end
					end
					lineY = lineY + 18
				end
			end
			lineY = lineY + 2
		end
	end

	-- Start dragging
	if cursorY >= y and cursorY <= y + 24 then
		self.dragging = true
		self.dragOffX = cursorX - self.overlayX
		self.dragOffY = cursorY - self.overlayY
	end
end

function CalcSectionClass:HandleOverlayRelease(key)
	if key == "LEFTBUTTON" then
		self.dragging = false
	end
end

function CalcSectionClass:DrawOverlay(viewPort, inputEvents)
	local cursorX, cursorY = GetCursorPos()
	self.overlayBreakdownCell = nil

	if self.overlayRevision ~= self.calcsTab.build.outputRevision then
		self:UpdateSize()
		self.overlayRevision = self.calcsTab.build.outputRevision
	end

	if self.dragging then
		self.overlayX = cursorX - self.dragOffX
		self.overlayY = cursorY - self.dragOffY
	end

	self.overlayX = m_max(viewPort.x, m_min(self.overlayX, viewPort.x + viewPort.width - self.width))
	self.overlayY = m_max(viewPort.y, m_min(self.overlayY, viewPort.y + viewPort.height - 24))

	local x = self.overlayX
	local y = self.overlayY
	local overlayWidth = self.width
	local actor = sectionFormatActor(self.calcsTab)

	-- Calculate content height
	local totalHeight = self:GetOverlayHeight()

	-- Ensure it's above most other controls
	SetDrawLayer(10)

	-- Draw background
	SetDrawColor(0.08, 0.08, 0.08, 0.95)
	DrawImage(nil, x, y, overlayWidth, totalHeight)

	-- Draw border
	SetDrawColor(self.colour)
	DrawImage(nil, x, y, overlayWidth, 1)
	DrawImage(nil, x, y + totalHeight - 1, overlayWidth, 1)
	DrawImage(nil, x, y, 1, totalHeight)
	DrawImage(nil, x + overlayWidth - 1, y, 1, totalHeight)

	-- Draw header
	SetDrawColor(0.18, 0.18, 0.18)
	DrawImage(nil, x + 1, y + 1, overlayWidth - 2, 22)
	SetDrawColor(1, 1, 1)
	local cbx = x + overlayWidth - 16
	local cby = y + 3
	DrawImageQuad(nil, cbx + 3, cby + 5, cbx + 5, cby + 3, cbx + 13, cby + 11, cbx + 11, cby + 13)
	DrawImageQuad(nil, cbx + 11, cby + 3, cbx + 13, cby + 5, cbx + 5, cby + 13, cbx + 3, cby + 11)

	-- Separator
	SetDrawColor(self.colour)
	DrawImage(nil, x + 2, y + 24, overlayWidth - 4, 1)

	-- Draw content
	self:DrawContent(x, y + 26, overlayWidth, actor, viewPort, true)

	-- Draw stat breakdown
	if self.calcsTab.displayData and (self.overlayBreakdownCell or (self.calcsTab.displayPinned and self.calcsTab.displayData.calcSection == self)) then
		local cd = self.calcsTab.displayData
		local origX, origY = cd.x, cd.y
		cd.x = x + (cd.xOffset or 134)
		cd.y = y + 26 + (cd.yOffset or 0)
		self.calcsTab.controls.breakdown:Draw(viewPort)
		cd.x, cd.y = origX, origY
	end
	self.overlayBreakdownCell = nil

	SetDrawLayer(0)
end

function CalcSectionClass:DrawContent(drawX, startLineY, drawWidth, actor, viewPort, isOverlay, noTooltip)
	local cursorX, cursorY = GetCursorPos()
	local lineY = startLineY
	local primary = true
	local enabled = isOverlay and (actor and self.calcsTab:CheckFlag(self)) or self.enabled

	for _, subSec in ipairs(self.subSection) do
		-- Top border
		SetDrawColor(self.colour)
		DrawImage(nil, drawX + 2, lineY, drawWidth - 4, 2)

		-- Label
		if not enabled then
			local lx = isOverlay and drawX + 4 or drawX + 3
			DrawString(lx, lineY + 3, "LEFT", 16, "VAR BOLD", "^8"..(subSec.label or ""))
		else
			local lx = isOverlay and drawX + 4 or drawX + 3
			local textColor = "^7"
			if not isOverlay and self.calcsTab:SearchMatch(subSec.label) then
				textColor = colorCodes.HIGHLIGHT
			end
			DrawString(lx, lineY + 3, "LEFT", 16, "VAR BOLD", textColor..(subSec.label or "")..":")
			if subSec.data.extra then
				local ex = lx + DrawStringWidth(16, "VAR BOLD", subSec.label) + (isOverlay and 12 or 10)
				DrawString(ex, lineY + 3, "LEFT", 16, "VAR", "^7"..formatCalcStr(subSec.data.extra, actor))
			end
		end

		-- Bottom border
		SetDrawColor(self.colour)
		DrawImage(nil, drawX + 2, lineY + 20, drawWidth - 4, 2)

		-- Toggle
		if isOverlay then
			if enabled then
				DrawString(drawX + drawWidth - 16, lineY + 3, "LEFT", 14, "VAR", "^7"..(subSec.collapsed and "+" or "-"))
			end
		else
			SetDrawLayer(nil, 0)
			self:DrawControls(viewPort, noTooltip and self.calcsTab.selControl)
		end

		if subSec.collapsed or not enabled then
			if primary then
				return
			else
				lineY = lineY + 20
				primary = false
			end
		else
			lineY = lineY + 20
			primary = false
			local rows = 0
			for _, rowData in ipairs(subSec.data) do
				if (isOverlay and actor and self.calcsTab:CheckFlag(rowData)) or (not isOverlay and rowData.enabled) then
					rows = rows + 1
					if not isOverlay then
						local textColor = rowData.color or "^7"
						if rowData.label then
							SetDrawColor(rowData.bgCol or "^0")
							DrawImage(nil, drawX + 2, lineY + 2, 130, 18)
							if self.calcsTab:SearchMatch(rowData.label) then
								textColor = colorCodes.HIGHLIGHT
							end
							DrawString(drawX + 132, lineY + 2, "RIGHT_X", 16, "VAR", textColor..rowData.label.."^7:")
						end
					elseif rowData.label then
						DrawString(drawX + 132, lineY + 2, "RIGHT_X", 16, "VAR", "^7"..rowData.label.."^7:")
					end
					for colour, colData in ipairs(rowData) do
						local cellX = isOverlay and (drawX + (colData.xOffset or 134)) or colData.x
						local cellW = isOverlay and (colData.width or (drawWidth - 136)) or colData.width
						local cellY = isOverlay and lineY + 2 or colData.y
						local cellH = colData.height or 18

						SetDrawColor(self.colour)
						DrawImage(nil, cellX, lineY + 2, 2, cellH)

						if colData.format and (isOverlay or self.calcsTab:CheckFlag(colData)) then
							if isOverlay and actor and self.calcsTab:CheckFlag(colData) or not isOverlay then
								if isOverlay then
									if cursorY >= lineY + 2 and cursorY < lineY + 20 and cursorX >= cellX and cursorX < cellX + cellW then
										self.calcsTab:SetDisplayStat(colData)
										self.overlayBreakdownCell = true
									end
								elseif cursorY >= viewPort.y and cursorY < viewPort.y + viewPort.height and cursorX >= cellX and cursorY >= cellY and cursorX < cellX + cellW and cursorY < cellY + cellH then
									self.calcsTab:SetDisplayStat(colData)
								end

								if not isOverlay and self.calcsTab.displayData == colData then
									SetDrawColor(0.25, 1, 0.25)
									DrawImage(nil, cellX + 2, cellY, cellW - 2, cellH)
									SetDrawColor(rowData.bgCol or "^0")
									DrawImage(nil, cellX + 3, cellY + 1, cellW - 4, cellH - 2)
								else
									SetDrawColor(rowData.bgCol or "^0")
									DrawImage(nil, cellX + 2, lineY + 2, cellW - 2, 18)
								end

								local textSize = rowData.textSize or 14
								SetViewport(cellX + 3, isOverlay and lineY + 2 or cellY, cellW - 4, 18)
								DrawString(1, 9 - textSize / 2, "LEFT", textSize, "VAR", "^7"..formatCalcStr(colData.format, actor, colData))
								SetViewport()
							end
						end
					end
					lineY = lineY + 18
				end
			end
			if rows > 0 then
				lineY = lineY + 2
			end
		end
	end
end
