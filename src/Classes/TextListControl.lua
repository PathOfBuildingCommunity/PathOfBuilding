-- Path of Building
--
-- Class: Text List
-- Simple list control for displaying a block of text
--
-- A line's height doubles as its font size, so grouped lists pad every row to buy the text some
-- breathing room without inflating it
local rowPad = 6

---@class TextListControl: Control, ControlHost
local TextListClass = newClass("TextListControl", "Control", "ControlHost")

function TextListClass:TextListControl(anchor, rect, columns, list, sectionHeights)
	self:Control(anchor, rect)
	self:ControlHost()
	self.controls.scrollBar = new("ScrollBarControl"):ScrollBarControl({"RIGHT",self,"RIGHT"}, {-1, 0, 18, 0}, 40)
	self.controls.scrollBar.height = function()
		local width, height = self:GetSize()
		return height - 2
	end
	self.columns = columns or { { x = 0, align = "LEFT" } }
	self.list = list or { }
	self.sectionHeights = sectionHeights
	return self
end

---Height a line occupies, which is its font size plus the padding grouped lists add. Headers take
---double, to hold the rule under them clear of the card that follows.
function TextListClass:GetLineHeight(lineInfo)
	if not self.grouped then
		return lineInfo.height
	end
	return lineInfo.height + (lineInfo.header and rowPad * 2 or rowPad)
end

-- Banding for lists that arrive as one long run of lines broken up by blank spacers, which is
-- hard to read at the length the side bar stat list reaches. Each run of lines between spacers
-- becomes a card, its rows divided by hairlines, and any line flagged as a header gets a rule
-- under it. Opt in with control.grouped, since the changelog and help lists want the plain
-- treatment.
function TextListClass:DrawGroups(contentWidth, offset)
	local colors = ui.colors
	-- Cards first, so the dividers land on top of them
	local lineY = -offset
	local groupStart = nil
	local function endGroup(endY)
		if groupStart and endY > groupStart then
			ui.SetColor(colors.surface)
			ui.DrawRect(0, groupStart - 2, contentWidth, endY - groupStart + 4, ui.radiusLarge)
		end
		groupStart = nil
	end
	for _, lineInfo in ipairs(self.list) do
		if lineInfo.header or not lineInfo[1] then
			endGroup(lineY)
		else
			groupStart = groupStart or lineY
		end
		lineY = lineY + self:GetLineHeight(lineInfo)
	end
	endGroup(lineY)
	-- Rule under each header, hairline between the rows sharing a card
	lineY = -offset
	for index, lineInfo in ipairs(self.list) do
		local lineHeight = self:GetLineHeight(lineInfo)
		if lineInfo.header then
			ui.SetColor(colors.border)
			DrawImage(nil, 0, lineY + lineInfo.height + rowPad, contentWidth, 1)
		elseif lineInfo[1] then
			local nextLine = self.list[index + 1]
			if nextLine and nextLine[1] and not nextLine.header then
				ui.SetColor(colors.border, 0.45)
				DrawImage(nil, 8, lineY + lineHeight - 1, contentWidth - 16, 1)
			end
		end
		lineY = lineY + lineHeight
	end
end

function TextListClass:IsMouseOver()
	if not self:IsShown() then
		return
	end
	return self:IsMouseInBounds() or self:GetMouseOverControl()
end

function TextListClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local scrollBar = self.controls.scrollBar
	local contentHeight = 0
	for _, lineInfo in pairs(self.list) do
		contentHeight = contentHeight + self:GetLineHeight(lineInfo)
	end
	scrollBar:SetContentDimension(contentHeight, height - 4)
	ui.DrawBox(x, y, width, height, ui.radius, ui.colors.border, ui.colors.input)
	self:DrawControls(viewPort)
	SetViewport(x + 2, y + 2, width - 20, height - 4)
	if self.grouped then
		self:DrawGroups(width - 26, scrollBar.offset)
	end
	local textPad = self.grouped and rowPad / 2 or 0
	local valueCol = self.columns[2]
	for colIndex, colInfo in pairs(self.columns) do
		local lineY = -scrollBar.offset
		for _, lineInfo in ipairs(self.list) do
			local text = lineInfo[colIndex]
			if text then
				local font = lineInfo.font or "VAR"
				local drawX = lineInfo.x or colInfo.x
				local align = lineInfo.align or colInfo.align
				-- Clip a label that would otherwise run underneath its own value
				if self.grouped and colIndex == 1 and valueCol and lineInfo[2] and not lineInfo.x then
					local space = valueCol.x - drawX - DrawStringWidth(lineInfo.height, font, lineInfo[2]) - 8
					if DrawStringWidth(lineInfo.height, font, text) > space then
						local clipWidth = DrawStringWidth(lineInfo.height, font, "..")
						local clipIndex = DrawStringCursorIndex(lineInfo.height, font, text, space - clipWidth, 0)
						text = text:sub(1, clipIndex - 1) .. ".."
					end
				end
				DrawString(drawX, lineY + textPad, align, lineInfo.height, font, text)
				if lineInfo.underline and lineInfo.underline[colIndex] then
					-- measured off the text as drawn, so a clipped label keeps its rule the same length
					local textWidth = DrawStringWidth(lineInfo.height, font, StripEscapes(text))
					-- note: not fully handled. this is currently only used for
					-- the side bar stats
					local underlineX = align == "RIGHT_X" and drawX - textWidth or drawX
					ui.SetColor(ui.colors.textMuted)
					DrawImage(nil, underlineX, lineY + textPad + lineInfo.height, textWidth, 1)
				end
			end
			lineY = lineY + self:GetLineHeight(lineInfo)
		end
	end
	-- determine which line the user is hovering over
	self.hoveredLine = nil
	local cursorX, cursorY = GetCursorPos()
	if cursorX >= x + 2 and cursorX < x + width - 18 and cursorY >= y + 2 and cursorY < y + height - 2 then
		local rowY = y - scrollBar.offset + 2
		-- suboptimal. should do binary search if this causes performance problems
		for _, lineInfo in ipairs(self.list) do
			local lineHeight = self:GetLineHeight(lineInfo)
			if cursorY >= rowY and cursorY < rowY + lineHeight then
				self.hoveredLine = { line = lineInfo, x = x, y = rowY, width = width, height = lineHeight }
				break
			end
			rowY = rowY + lineHeight
		end
	end
	SetViewport()
end

function TextListClass:OnKeyDown(key, doubleClick)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "LEFTBUTTON" and self.onClick then
		self.onClick(self.hoveredLine)
	end
	local mOverControl = self:GetMouseOverControl()
	if mOverControl and mOverControl.OnKeyDown then
		return mOverControl:OnKeyDown(key)
	end
end

function TextListClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local scrollBar = self.controls.scrollBar
	if IsKeyDown("SHIFT") and self.sectionHeights then
		for i, height in ipairs(self.sectionHeights) do
			if height >= scrollBar.offset then
				if key == "WHEELDOWN" then
					scrollBar:SetOffset((i==#self.sectionHeights and self.sectionHeights[i] or self.sectionHeights[i + 1]))
					return self
				elseif key == "WHEELUP" then
					scrollBar:SetOffset(i==1 and self.sectionHeights[i] or self.sectionHeights[i - 1])
					return self
				end
			end
		end
		scrollBar.offset = scrollBar.offsetMax
		return self
	end
	if key == "WHEELDOWN" then
		scrollBar:Scroll(1)
		return self
	elseif key == "WHEELUP" then
		scrollBar:Scroll(-1)
		return self
	end
end