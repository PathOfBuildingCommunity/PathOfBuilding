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

-- All possible values for notable recipes (oils)
local recipeNames = {
	"AmberOil",
	"AzureOil",
	"BlackOil",
	"ClearOil",
	"CrimsonOil",
	"GoldenOil",
	"OpalescentOil",
	"SepiaOil",
	"SilverOil",
	"TealOil",
	"VerdantOil",
	"VioletOil",
}

local TooltipClass = newClass("Tooltip", function(self)
	-- Preload all recipe images
	self.recipeImages = { }
	for _, recipeName in pairs(recipeNames) do
		self.recipeImages[recipeName] = NewImageHandle()
		self.recipeImages[recipeName]:Load("TreeData/" .. recipeName .. ".png", "CLAMP")
	end

	self.lines = { }
	self:Clear()
end)

function TooltipClass:Clear()
	wipeTable(self.lines)
	if self.updateParams then
		wipeTable(self.updateParams)
	end
	self.recipe = nil
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
	if type(self.color) == "string" then
		SetDrawColor(self.color) 
	else
		SetDrawColor(unpack(self.color))
	end
	DrawImage(nil, ttX, ttY, ttW, 3)
	DrawImage(nil, ttX, ttY, 3, ttH)
	DrawImage(nil, ttX, ttY + ttH - 3, ttW, 3)
	DrawImage(nil, ttX + ttW - 3, ttY, 3, ttH)
	SetDrawColor(0, 0, 0, 0.75)
	DrawImage(nil, ttX + 3, ttY + 3, ttW - 6, ttH - 6)
	SetDrawColor(1, 1, 1)

	local y = ttY + 6
	-- Draw the oil recipe for notables
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
			-- Draw the name of the recipe component (oil)
			DrawString(ttX + imageX, y + (title.size - recipeTextSize)/2, "LEFT", recipeTextSize, "VAR", recipeNameShort)
			imageX = imageX + DrawStringWidth(recipeTextSize, "VAR", recipeNameShort)
			-- Draw the image of the recipe component (oil)
			DrawImage(self.recipeImages[recipeName], ttX + imageX, y, title.size, title.size)
			imageX = imageX + title.size * 1.25
		end
	end

	for i, data in ipairs(self.lines) do
		if data.text then
			if self.center then
				DrawString(ttX + ttW/2, y, "CENTER_X", data.size, "VAR", data.text)
			else
				DrawString(ttX + 6, y, "LEFT", data.size, "VAR", data.text)
			end
			y = y + data.size + 2
		elseif self.lines[i + 1] and self.lines[i - 1] and self.lines[i + 1].text then
			if type(self.color) == "string" then
				SetDrawColor(self.color) 
			else
				SetDrawColor(unpack(self.color))
			end
			DrawImage(nil, ttX + 3, y - 1 + data.size / 2, ttW - 6, 2)
			y = y + data.size + 2
		end
	end
	return ttW, ttH
end