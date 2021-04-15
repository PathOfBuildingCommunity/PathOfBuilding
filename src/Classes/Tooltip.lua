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

-- Constants

local BORDER_WIDTH = 3
local H_PAD	= 12
local V_PAD = 10

-- All possible values for notable recipes (oils)
local recipeNames = {
	"AmberOil",
	"AzureOil",
	"BlackOil",
	"ClearOil",
	"CrimsonOil",
	"GoldenOil",
	"IndigoOil",
	"OpalescentOil",
	"SepiaOil",
	"SilverOil",
	"TealOil",
	"VerdantOil",
	"VioletOil",
}

-- Preload all recipe images
local recipeImages = { }
for _, recipeName in pairs(recipeNames) do
	recipeImages[recipeName] = NewImageHandle()
	recipeImages[recipeName]:Load("TreeData/" .. recipeName .. ".png", "CLAMP")
end

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
	self.recipe = nil
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
				for _, line in ipairs(main:WrapString(line, size, self.maxWidth - H_PAD)) do
					t_insert(self.lines, { size = size, text = line, block = #self.blocks })
				end
			else
				t_insert(self.lines, { size = size, text = line, block = #self.blocks })
			end
		end
	end
end

function TooltipClass:SetRecipe(recipe)
	self.recipe = recipe
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

	-- Account for recipe display
	if self.recipe and self.lines[1] then
		local title = self.lines[1]
		local imageX = DrawStringWidth(title.size, "VAR", title.text) + title.size
		local recipeTextSize = (title.size * 3) / 4
		for _, recipeName in ipairs(self.recipe) do
			-- Trim "Oil" from the recipe name, which normally looks like "GoldenOil"
			local recipeNameShort = recipeName
			if #recipeNameShort > 3 and recipeNameShort:sub(-3) == "Oil" then
				recipeNameShort = recipeNameShort:sub(1, #recipeNameShort - 3)
			end
			imageX = imageX + DrawStringWidth(recipeTextSize, "VAR", recipeNameShort) + title.size * 1.25
		end
		ttW = m_max(ttW, imageX)
	end

	return ttW + H_PAD, ttH + V_PAD
end

function TooltipClass:GetDynamicSize(viewPort)
	local staticttW, staticttH = self:GetSize()
	local columns, ttH = self:CalculateColumns(0, 0, staticttH, staticttW, viewPort)
	local ttW = columns * staticttW

	return ttW + H_PAD, ttH + V_PAD
end

function TooltipClass:CalculateColumns(ttY, ttX, ttH, ttW, viewPort)
	local y = ttY + 2 * BORDER_WIDTH
	local x = ttX
	local columns = 1 -- reset to count columns by block heights
	local currentBlock = 1
	local maxColumnHeight = 0
	local drawStack = {}

	for i, data in ipairs(self.lines) do
		if self.recipe and i == 1 then
			local title = self.lines[1]
			local imageX = DrawStringWidth(title.size, "VAR", title.text) + title.size
			local recipeTextSize = (title.size * 3) / 4
			for _, recipeName in ipairs(self.recipe) do
				-- Trim "Oil" from the recipe name, which normally looks like "GoldenOil"
				local recipeNameShort = recipeName
				if #recipeNameShort > 3 and recipeNameShort:sub(-3) == "Oil" then
					recipeNameShort = recipeNameShort:sub(1, #recipeNameShort - 3)
				end
				-- Draw the name of the recipe component (oil)
				t_insert(drawStack, {ttX + imageX, y + (title.size - recipeTextSize)/2, "LEFT", recipeTextSize, "VAR", recipeNameShort})
				imageX = imageX + DrawStringWidth(recipeTextSize, "VAR", recipeNameShort)
				-- Draw the image of the recipe component (oil)
				t_insert(drawStack, {recipeImages[recipeName], ttX + imageX, y, title.size, title.size})
				imageX = imageX + title.size * 1.25
			end
		end
		if data.text then
			-- if data + borders is going to go outside of the viewPort
			if currentBlock ~= data.block and self.blocks[data.block].height + y > ttY + math.min(ttH, viewPort.height) then
				y = ttY + 2 * BORDER_WIDTH
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
			t_insert(drawStack, {nil, x, y - 1 + data.size / 2, ttW - BORDER_WIDTH, 2})
			y = y + data.size + 2
		end
		maxColumnHeight = m_max(y - ttY + 2 * BORDER_WIDTH, maxColumnHeight)
	end

	return columns, maxColumnHeight, drawStack
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

	local columns, maxColumnHeight, drawStack = self:CalculateColumns(ttY, ttX, ttH, ttW, viewPort)

	-- background shading currently must be drawn before text lines.  API change will allow something like the commented lines below
	SetDrawColor(0, 0, 0, .85)
	--SetDrawLayer(nil, GetDrawLayer() - 5)
	DrawImage(nil, ttX, ttY + BORDER_WIDTH, ttW * columns - BORDER_WIDTH, maxColumnHeight - 2 * BORDER_WIDTH)
	--SetDrawLayer(nil, GetDrawLayer())
	SetDrawColor(1, 1, 1)
	for i, lines in ipairs(drawStack) do 
		if #lines < 6 then
			if(type(self.color) == "string") then
				SetDrawColor(self.color)
			elseif lines[1] then -- Don't color images
				SetDrawColor(1,1,1)
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
		DrawImage(nil, ttX + ttW * i - BORDER_WIDTH * math.ceil(i^2 / (i^2 + 1)), ttY, BORDER_WIDTH, maxColumnHeight) -- borders
	end
	DrawImage(nil, ttX, ttY, ttW * columns, BORDER_WIDTH) -- top border
	DrawImage(nil, ttX, ttY + maxColumnHeight - BORDER_WIDTH, ttW * columns, BORDER_WIDTH) -- bottom border

	return ttW, ttH
end