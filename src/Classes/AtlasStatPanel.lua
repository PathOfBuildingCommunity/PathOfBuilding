local ipairs = ipairs
local t_insert = table.insert
local m_max = math.max
local m_min = math.min

local headerHeight = 20
local lineHeight = 16
local lineGap = 4

local AtlasStatPanelClass = newClass("AtlasStatPanel")

local function wrapText(text, height, width)
	local lines = { }
	local current
	for word in text:gmatch("%S+") do
		local candidate = current and (current .. " " .. word) or word
		if current and DrawStringWidth(height, "VAR", candidate) > width then
			t_insert(lines, current)
			current = word
		else
			current = candidate
		end
	end
	if current then
		t_insert(lines, current)
	end
	return lines
end

function AtlasStatPanelClass:AtlasStatPanel(tab)
	self.tab = tab
	self.collapsed = { }
	self.scroll = 0
	return self
end

function AtlasStatPanelClass:SetAllCollapsed(collapsed)
	for _, category in ipairs(self.tab.spec:GetStatSummary()) do
		self.collapsed[category.category] = collapsed
	end
	self.defaultCollapsed = collapsed
end

function AtlasStatPanelClass:IsCollapsed(name)
	if self.collapsed[name] == nil then
		return self.defaultCollapsed or false
	end
	return self.collapsed[name]
end

function AtlasStatPanelClass:BuildRows(width)
	local spec = self.tab.spec
	if self.cachedRevision == spec.revision and self.cachedSpec == spec and self.cachedWidth == width and not self.layoutDirty then
		return self.rows, self.contentHeight
	end
	local rows = { }
	local y = 0
	for _, category in ipairs(spec:GetStatSummary()) do
		t_insert(rows, { kind = "header", name = category.category, y = y, height = headerHeight, count = #category.lines })
		y = y + headerHeight + 2
		if not self:IsCollapsed(category.category) then
			for _, line in ipairs(category.lines) do
				local wrapped = wrapText(line.text, lineHeight, width - 12)
				local height = #wrapped * lineHeight
				t_insert(rows, { kind = "line", lines = wrapped, nodes = line.nodes, y = y, height = height })
				y = y + height + lineGap
			end
		end
		y = y + 4
	end
	self.rows = rows
	self.contentHeight = y
	self.cachedRevision = spec.revision
	self.cachedSpec = spec
	self.cachedWidth = width
	self.layoutDirty = false
	return rows, y
end

function AtlasStatPanelClass:Draw(rect, inputEvents)
	local spec = self.tab.spec
	local x, y, width, height = rect.x, rect.y, rect.width, rect.height
	local cursorX, cursorY = GetCursorPos()
	local mOver = cursorX >= x and cursorX < x + width and cursorY >= y and cursorY < y + height and not main.popups[1]

	SetDrawLayer(1, 0)
	SetDrawColor(0.08, 0.08, 0.08)
	DrawImage(nil, x, y, width, height)
	SetDrawColor(0.85, 0.85, 0.85)
	DrawImage(nil, x, y, 2, height)

	local used = spec:CountAllocNodes()
	local total = spec.tree.totalPoints
	SetDrawColor(1, 1, 1)
	DrawString(x + width / 2, y + 8, "CENTER_X", 24, "VAR", (used > total and colorCodes.NEGATIVE or "^7") .. used .. " / " .. total)
	DrawString(x + width / 2, y + 34, "CENTER_X", 14, "VAR", "^8Allocated Nodes")

	local listTop = y + 84
	local listHeight = height - 88
	local listX = x + 10
	local listWidth = width - 20
	local rows, contentHeight = self:BuildRows(listWidth)
	local maxScroll = m_max(0, contentHeight - listHeight)

	local clicked
	for id, event in ipairs(inputEvents) do
		if mOver and event.type == "KeyUp" then
			if event.key == "WHEELUP" then
				self.scroll = self.scroll - 40
				inputEvents[id] = nil
			elseif event.key == "WHEELDOWN" then
				self.scroll = self.scroll + 40
				inputEvents[id] = nil
			elseif event.key == "LEFTBUTTON" then
				clicked = true
			end
		end
	end
	self.scroll = m_max(0, m_min(maxScroll, self.scroll))

	self.tab.highlightNodes = nil
	if #rows == 0 then
		DrawString(x + width / 2, listTop + 10, "CENTER_X", 14, "VAR", "^8Allocate nodes to see their stats here.")
		return
	end

	SetViewport(listX, listTop, listWidth, listHeight)
	for _, row in ipairs(rows) do
		local rowY = row.y - self.scroll
		if rowY + row.height >= 0 and rowY <= listHeight then
			local hovered = mOver and cursorY >= listTop + rowY and cursorY < listTop + rowY + row.height and cursorY >= listTop and cursorY < listTop + listHeight
			if row.kind == "header" then
				SetDrawColor(hovered and 0.22 or 0.16, hovered and 0.22 or 0.16, hovered and 0.22 or 0.16)
				DrawImage(nil, 0, rowY, listWidth, row.height)
				SetDrawColor(1, 1, 1)
				DrawString(6, rowY + 2, "LEFT", 16, "VAR BOLD", "^7" .. row.name:upper() .. " ^8(" .. row.count .. ")")
				SetDrawColor(0.8, 0.8, 0.8)
				main:DrawArrow(listWidth - 12, rowY + row.height / 2, 8, 8, self:IsCollapsed(row.name) and "DOWN" or "UP")
				if hovered and clicked then
					self.collapsed[row.name] = not self:IsCollapsed(row.name)
					self.layoutDirty = true
				end
			else
				if hovered then
					SetDrawColor(0.15, 0.15, 0.2)
					DrawImage(nil, 0, rowY - 1, listWidth, row.height + 2)
					local highlight = { }
					for _, node in ipairs(row.nodes) do
						highlight[node] = true
					end
					self.tab.highlightNodes = highlight
				end
				SetDrawColor(1, 1, 1)
				for i, text in ipairs(row.lines) do
					DrawString(6, rowY + (i - 1) * lineHeight, "LEFT", lineHeight, "VAR", colorCodes.MAGIC .. text)
				end
			end
		end
	end
	SetViewport()

	if maxScroll > 0 then
		local barHeight = m_max(20, listHeight * listHeight / contentHeight)
		local barY = listTop + (listHeight - barHeight) * self.scroll / maxScroll
		SetDrawColor(0.4, 0.4, 0.4)
		DrawImage(nil, x + width - 6, barY, 4, barHeight)
	end
	SetDrawColor(1, 1, 1)
end
