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
	self:Clear()
end)

function TooltipClass:Clear()
	wipeTable(self.lines)
	if self.updateParams then
		wipeTable(self.updateParams)
	end
	self.center = false
	self.color = { 0.5, 0.3, 0 }
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
			if self.maxWidth then
				for _, line in ipairs(main:WrapString(line, size, self.maxWidth - 12)) do
					t_insert(self.lines, { size = size, text = line })
				end
			else
				t_insert(self.lines, { size = size, text = line })
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
	local tiles = 1
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
			tiles = tiles + 1
			balancedHeight = ttH / tiles + tiles * 10
		end
		ttH = balancedHeight
		if ttY + ttH > viewPort.y + viewPort.height then
			ttY = m_max(viewPort.y, y + h - ttH)
		end
	elseif self.center then
		ttX = m_floor(x - ttW/2)
	end

	SetDrawColor(0, 0, 0, 0.75)
	DrawImage(nil, ttX + 3, ttY + 3, ttW * tiles - 6, ttH - 6) -- background shading
	if type(self.color) == "string" then
		SetDrawColor(self.color) 
	else
		SetDrawColor(unpack(self.color))
	end
	for i=0,tiles do
		DrawImage(nil, ttX + ttW * i - 3 * math.ceil(i^2 / (i^2 + 1)), ttY, 3, ttH) -- borders
	end
	DrawImage(nil, ttX, ttY, ttW * tiles, 3) -- top border
	DrawImage(nil, ttX, ttY + ttH - 3, ttW * tiles, 3) -- bottom border
	
	SetDrawColor(1, 1, 1)
	local y = ttY + 6
	local x = ttX
	local currentTile = 1
	for i, data in ipairs(self.lines) do
		if data.text then
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
		if y + data.size + 2 > ttY + ttH then
			y = ttY + 6
			x = ttX + ttW * currentTile
			currentTile = currentTile + 1
		end
	end
	return ttW, ttH
end