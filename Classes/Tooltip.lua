-- Path of Building
--
-- Class: Tooltip
-- Tooltip
--
local ipairs = ipairs
local t_insert = table.insert
local m_max = math.max
local m_floor = math.floor
local s_gmatch = string.gmatch

local TooltipClass = newClass("Tooltip", function(self)
	self.lines = { }
	self.blocks = { }
	self:Clear()
end)

function TooltipClass:Clear()
	wipeTable(self.lines)
	wipeTable(self.blocks)
	if self.updateParams then
		wipeTable(self.updateParams)
	end
	self.center = false
	self.color = { 0.5, 0.3, 0 }
	t_insert(self.blocks, { height = 0 })
end

function TooltipClass:CheckForUpdate(...)
	local doUpdate = false
	if not self.updateParams then
		self.updateParams = { }
	end
	for i = 1, select('#', ...) do
		if self.updateParams[i] ~= select(i, ...) then
			doUpdate = true
			break
		end
	end
	if doUpdate then
		self:Clear()
		for i = 1, select('#', ...) do
			self.updateParams[i] = select(i, ...)
		end
		return true
	end
end

function TooltipClass:AddLine(size, text)
	if text then
		for line in s_gmatch(text .. "\n", "([^\n]*)\n") do	
			if line:match("^.*(Equipping)") == "Equipping" or line:match("^.*(Removing)") == "Removing" then
				t_insert(self.blocks, { height = size + 2})
			else
				self.blocks[#self.blocks].height = self.blocks[#self.blocks].height + size + 2
			end
			if self.maxWidth then
				for _, line in ipairs(main:WrapString(line, size, self.maxWidth - 12)) do
					t_insert(self.lines, { size = size, text = line, block = #self.blocks })
				end
			else
				t_insert(self.lines, { size = size, text = line, block = #self.blocks })
			end
		end
	end
end

function TooltipClass:AddSeparator(size)
	t_insert(self.lines, { size = size })
end

function TooltipClass:GetSize()
	local ttW, ttH = 0, 0
	for i, data in ipairs(self.lines) do
		if data.text or (self.lines[i - 1] and self.lines[i + 1] and self.lines[i + 1].text) then
			ttH = ttH + data.size + 2
		end
		if data.text then
			ttW = m_max(ttW, DrawStringWidth(data.size, "VAR", data.text))
		end
	end
	return ttW + 12, ttH + 10
end

function TooltipClass:Draw(x, y, w, h, viewPort)
	if #self.lines == 0 then
		return
	end
	local ttW, ttH = self:GetSize()
	local ttX = x
	local ttY = y
	if w and h then
		ttX = ttX + w + 5
		if ttX + ttW > viewPort.x + viewPort.width then
			ttX = m_max(viewPort.x, x - 5 - ttW)
			if ttX + ttW > x then
				ttY = ttY + h
			end
		end
		if ttY + ttH > viewPort.y + viewPort.height then
			ttY = m_max(viewPort.y, y + h - ttH)
		end
	elseif self.center then
		ttX = m_floor(x - ttW/2)
	end
	
	SetDrawColor(1, 1, 1)
	local y = ttY + 6
	local x = ttX
	local columns = 1 -- reset to count columns by block heights
	local currentBlock = 1
	local maxColumnHeight = 0
	local drawStack = {}
	for i, data in ipairs(self.lines) do
		if data.text then
			if currentBlock ~= data.block and self.blocks[data.block].height + y > ttY + math.min(ttH, viewPort.height) then
				y = ttY + 6
				x = ttX + ttW * columns
				columns = columns + 1
			end
			currentBlock = data.block
			if self.center then
				t_insert(drawStack, {x + ttW/2, y, "CENTER_X", data.size, "VAR", data.text})
			else
				t_insert(drawStack, {x + 6, y, "LEFT", data.size, "VAR", data.text})
			end
			y = y + data.size + 2
		elseif self.lines[i + 1] and self.lines[i - 1] and self.lines[i + 1].text then
			t_insert(drawStack, {nil, x, y - 1 + data.size / 2, ttW - 3, 2})
			y = y + data.size + 2
		end
		maxColumnHeight = m_max(y - ttY + 6, maxColumnHeight)
	end

	-- background shading currently must be drawn before text lines.  API change will allow something like the commented lines below
	SetDrawColor(0, 0, 0, .85)
	--SetDrawLayer(nil, GetDrawLayer() - 5)
	DrawImage(nil, ttX, ttY + 3, ttW * columns - 3, maxColumnHeight - 6)
	--SetDrawLayer(nil, GetDrawLayer())
	SetDrawColor(1, 1, 1)
	for i, lines in ipairs(drawStack) do 
		if #lines < 6 then
			if(type(self.color) == "string") then
				SetDrawColor(self.color) 
			else
				SetDrawColor(unpack(self.color))
			end
			DrawImage(unpack(lines))
		else
			DrawString(unpack(lines))
		end
	end
	if type(self.color) == "string" then
		SetDrawColor(self.color) 
	else
		SetDrawColor(unpack(self.color))
	end
	for i=0,columns do
		DrawImage(nil, ttX + ttW * i - 3 * math.ceil(i^2 / (i^2 + 1)), ttY, 3, maxColumnHeight) -- borders
	end
	DrawImage(nil, ttX, ttY, ttW * columns, 3) -- top border
	DrawImage(nil, ttX, ttY + maxColumnHeight - 3, ttW * columns, 3) -- bottom border

	return ttW, ttH
end