-- Path of Building
--
-- Class: Tooltip
-- Tooltip
--
local launch, main = ...

local ipairs = ipairs
local t_insert = table.insert
local m_max = math.max
local m_floor = math.floor
local s_gmatch = string.gmatch

local TooltipClass = common.NewClass("Tooltip", function(self)
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
	local columns = 1
	if w and h then
		ttX = ttX + w + 5
		if ttX + ttW > viewPort.x + viewPort.width then
			ttX = m_max(viewPort.x, x - 5 - ttW)
			if ttX + ttW > x then
				ttY = ttY + h
			end
		end
		
		local balancedHeight = ttH
		while balancedHeight > viewPort.height do -- does it fit with the borders?
			columns = columns + 1
			balancedHeight = ttH / columns
		end
		ttH = balancedHeight
		if ttY + ttH > viewPort.y + viewPort.height then
			ttY = m_max(viewPort.y, y + h - ttH)
		end
	elseif self.center then
		ttX = m_floor(x - ttW/2)
	end
	
	SetDrawColor(1, 1, 1)
	local y = ttY + 6
	local x = ttX
	columns = 1 -- reset to count columns by block heights
	local currentBlock = 1
	for i, data in ipairs(self.lines) do
		if data.text then
			--DrawString(400, 600 + 10 * i/5, "LEFT", data.size, "VAR", "y" .. y .. "x" .. x .. "ttY" .. ttY)
			--DrawString(x + 3, y, "LEFT", data.size, "VAR", "y" .. y .. "x" .. x .. "ttY" .. ttY .. "==" .. tostring(y == ttY + 6))
			if currentBlock ~= data.block and self.blocks[data.block].height + y > ttY + ttH then
				y = ttY + 6
				x = ttX + ttW * columns
				columns = columns + 1
			end
			if y == ttY + 6 then
				SetDrawColor(0, 0, 0, 0.75)
				DrawImage(nil, x, ttY + 3, ttW - 3, ttH - 6) -- background shading
				if type(self.color) == "string" then
					SetDrawColor(self.color) 
				else
					SetDrawColor(unpack(self.color))
				end
			end
			currentBlock = data.block
			if self.center then
				DrawString(x + ttW/2, y, "CENTER_X", data.size, "VAR", data.text)
			else
				DrawString(x + 6, y, "LEFT", data.size, "VAR", data.text)
			end
			y = y + data.size + 2
		elseif self.lines[i + 1] and self.lines[i - 1] and self.lines[i + 1].text then
			if type(self.color) == "string" then
				SetDrawColor(self.color) 
			else
				SetDrawColor(unpack(self.color))
			end
			DrawImage(nil, x + 3, y - 1 + data.size / 2, ttW - 6, 2)
			y = y + data.size + 2
		end
	end

	if type(self.color) == "string" then
		SetDrawColor(self.color) 
	else
		SetDrawColor(unpack(self.color))
	end
	for i=0,columns do
		DrawImage(nil, ttX + ttW * i - 3 * math.ceil(i^2 / (i^2 + 1)), ttY, 3, ttH) -- borders
	end
	DrawImage(nil, ttX, ttY, ttW * columns, 3) -- top border
	DrawImage(nil, ttX, ttY + ttH - 3, ttW * columns, 3) -- bottom border

	return ttW, ttH
end