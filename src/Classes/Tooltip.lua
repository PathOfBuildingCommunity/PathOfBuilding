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
	"PrismaticOil",
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

function TooltipClass:Clear(clearUpdateParams)
	wipeTable(self.lines)
	wipeTable(self.blocks)
	if self.updateParams and clearUpdateParams then
		wipeTable(self.updateParams)
	end
	self.tooltipHeader = false
	self.titleYOffset = 0
	self.recipe = nil
	self.center = false
	self.maxWidth = nil
	self.color = { 0.5, 0.3, 0 }
	t_insert(self.blocks, { height = 0 })
end

function TooltipClass:CheckForUpdate(...)
	local doUpdate = false
	if not self.updateParams then
		self.updateParams = { }
	end

	for i = 1, select('#', ...) do
		local temp = select(i, ...)
		if self.updateParams[i] ~= temp then
			self.updateParams[i] = temp
			doUpdate = true
		end
	end
	if doUpdate or self.updateParams.notSupportedModTooltips ~= main.notSupportedModTooltips then
		self.updateParams.notSupportedModTooltips = main.notSupportedModTooltips
		self:Clear()
		return true
	end
end

function TooltipClass:AddLine(size, text, font)
	if text then
		local fontToUse
		if main.showFlavourText then
			fontToUse = font or "VAR"
		else
			fontToUse = "VAR"
		end
		for line in s_gmatch(text .. "\n", "([^\n]*)\n") do 
			if line:match("^.*(Equipping)") == "Equipping" or line:match("^.*(Removing)") == "Removing" then
				t_insert(self.blocks, { height = size + 2})
			else
				self.blocks[#self.blocks].height = self.blocks[#self.blocks].height + size + 2
			end
			if self.maxWidth then
				for _, wrappedLine in ipairs(main:WrapString(line, size, self.maxWidth - H_PAD)) do
					t_insert(self.lines, { size = size, text = wrappedLine, block = #self.blocks, font = fontToUse, center = self.center })
				end
			else
				t_insert(self.lines, { size = size, text = line, block = #self.blocks, font = fontToUse, center = self.center })
			end
		end
	end
end

function TooltipClass:SetRecipe(recipe)
	self.recipe = recipe
end

function TooltipClass:AddSeparator(size)
	size = size or 10

	local lastLine = self.lines[#self.lines]
	if lastLine and lastLine.separatorImage then
		-- Prevent back-to-back separator lines
		return
	end

	local separatorImage = nil

	if self.tooltipHeader then
		local rarity = tostring(self.tooltipHeader):upper()
		-- spell-checker: disable
		local separatorConfigs = {
			RELIC = "Assets/itemsseparatorfoil.png",
			UNIQUE = "Assets/itemsseparatorunique.png",
			RARE = "Assets/itemsseparatorrare.png",
			MAGIC = "Assets/itemsseparatormagic.png",
			NORMAL = "Assets/itemsseparatorwhite.png",
			GEM = "Assets/itemsseparatorgem.png",
		}
		-- spell-checker: enable
		local separatorPath = separatorConfigs[rarity] or separatorConfigs.NORMAL

		if not self.separatorImage or self.separatorImagePath ~= separatorPath then
			self.separatorImage = NewImageHandle()
			self.separatorImage:Load(separatorPath)
			self.separatorImagePath = separatorPath
		end

		separatorImage = self.separatorImage
	end

	local lastBlock = lastLine and lastLine.block or 1
	t_insert(self.lines, {
		separatorImage = separatorImage,
		size = size,
		block = lastBlock,
	})
end


function TooltipClass:GetSize()
	local ttW, ttH = 0, 0
	for i, data in ipairs(self.lines) do
		if data.text or (self.lines[i - 1] and self.lines[i + 1] and self.lines[i + 1].text) then
			ttH = ttH + data.size + 2
		end
		if data.text then
			ttW = m_max(ttW, DrawStringWidth(data.size, data.font, data.text))
		end
	end

	-- Account for recipe display
	if self.recipe and self.lines[1] then
		local title = self.lines[1]
		local font = main.showFlavourText and "FONTIN SC" or "VAR"
		local imageX = DrawStringWidth(title.size, font, title.text) + title.size
		local recipeTextSize = (title.size * 3) / 4
		for _, recipeName in ipairs(self.recipe) do
			-- Trim "Oil" from the recipe name, which normally looks like "GoldenOil"
			local recipeNameShort = recipeName
			if #recipeNameShort > 3 and recipeNameShort:sub(-3) == "Oil" then
				recipeNameShort = recipeNameShort:sub(1, #recipeNameShort - 3)
			end
			imageX = imageX + DrawStringWidth(recipeTextSize, font, recipeNameShort) + title.size * 1.25
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
	if self.titleYOffset then
		y = y + self.titleYOffset
	end
	local x = ttX
	local columns = 1 -- reset to count columns by block heights
	local currentBlock = 1
	local maxColumnHeight = 0
	local drawStack = {}
	local font

	for i, data in ipairs(self.lines) do
		-- Handle first line with recipe/oils
		if main.showFlavourText then
			font = data.font or "VAR"
		else
			font = "VAR"
		end
		if self.recipe and i == 1 and data.text then
			local title = data
			local titleSize = title.size
			local recipeTextSize = math.floor(titleSize * 3 / 4)
			local padding = 4

			-- Measure total width for centering
			local totalWidth = DrawStringWidth(titleSize, font, title.text)
			local oilWidths = {}
			for _, r in ipairs(self.recipe) do
				local rn = r
				if #rn > 3 and rn:sub(-3) == "Oil" then
					rn = rn:sub(1, #rn - 3)
				end
				local textW = DrawStringWidth(recipeTextSize, font, rn)
				local iconW = titleSize
				table.insert(oilWidths, {rn, r, textW, iconW})
				totalWidth = totalWidth + textW + iconW + padding
			end

			-- Center title + oils
			local curX = ttX + ttW / 2 - totalWidth / 2
			-- Draw title
			t_insert(drawStack, {curX, y + (titleSize - titleSize)/2, "LEFT", titleSize, font, title.text})
			curX = curX + DrawStringWidth(titleSize, font, title.text) + 6

			-- Draw oils
			local maxOilHeight = 0
			for _, part in ipairs(oilWidths) do
				local rn, recipeName, textW, iconW = part[1], part[2], part[3], part[4]
				if main.showFlavourText then
					rn = "^xF8E6CA" .. rn
				end
				t_insert(drawStack, {curX, y + (titleSize - recipeTextSize)/2, "LEFT", recipeTextSize, font, rn})
				curX = curX + textW

				local handle = recipeImages[recipeName]
				t_insert(drawStack, {{handle = handle}, curX, y, iconW, iconW})

				curX = curX + iconW + padding
			end
			-- Advance y by max height
			y = y + m_max(titleSize, maxOilHeight) + 2

			-- Mark line handled so it won’t print again
			data._handled = true
		end

		-- Normal text handling (skip if first line handled)
		if data.text and not data._handled then
			-- Column break logic
			if currentBlock ~= data.block and self.blocks[data.block].height + y > ttY + math.min(ttH, viewPort.height) then
				y = ttY + 2 * BORDER_WIDTH
				x = ttX + ttW * columns
				columns = columns + 1
			end
			currentBlock = data.block

			local lineCentered = data.center
			if lineCentered == nil then
				lineCentered = self.center
			end
			local lineX = lineCentered and (x + ttW / 2) or (x + 6)
			local lineAlign = lineCentered and "CENTER_X" or "LEFT"

			t_insert(drawStack, {lineX, y, lineAlign, data.size, font, data.text})
			y = y + data.size + 2

		elseif data.separatorImage and main.showFlavourText then
			local sepSize = data.size or 10
			if currentBlock ~= data.block and y + sepSize > ttY + math.min(ttH, viewPort.height) then
				y = ttY + 2 * BORDER_WIDTH
				x = ttX + ttW * columns
				columns = columns + 1
			end
			currentBlock = data.block
			t_insert(drawStack, {{ handle = data.separatorImage, isSeparator = true }, x + 6, y, ttW - 12, sepSize})
			y = y + sepSize + 2

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

	-- ensure ttW is at least title width + 50 pixels, this fixes the header image for Magic items and some Tree passives.
	if self.tooltipHeader and self.lines[1] and self.lines[1].text then
		local font = main.showFlavourText and "FONTIN SC" or "VAR"
		local titleW = DrawStringWidth(self.lines[1].size, font, self.lines[1].text)
		if titleW + 50 > ttW then
			ttW = titleW + 50
		end
	end
	-- spell-checker: disable
	local headerInfluence = {
		Fractured = "Assets/fracturedicon.png",
		Veiled = "Assets/veiledicon.png",
		Shaper = "Assets/shapericon.png",
		Elder = "Assets/eldericon.png",
		Redeemer = "Assets/redeemericon.png",
		Hunter = "Assets/huntericon.png",
		Crusader = "Assets/crusadericon.png",
		Warlord = "Assets/warlordicon.png",
		Eater = "Assets/eatericon.png",
		Exarch = "Assets/exarchicon.png",
		Synthesis = "Assets/synthesisicon.png",
		Experimented = "Assets/experimentedicon.png",
		Foulborn = "Assets/breachicon.png",
	}
	local headerConfigs = {
		RELIC = {left="Assets/itemsheaderfoilleft.png",middle="Assets/itemsheaderfoilmiddle.png",right="Assets/itemsheaderfoilright.png",height=54,sideWidth=47,middleWidth=52,textYOffset=1,allowInfluenceIcon=true},
		UNIQUE = {left="Assets/itemsheaderuniqueleft.png",middle="Assets/itemsheaderuniquemiddle.png",right="Assets/itemsheaderuniqueright.png",height=54,sideWidth=47,middleWidth=52,textYOffset=1,allowInfluenceIcon=true},
		RARE = {left="Assets/itemsheaderrareleft.png",middle="Assets/itemsheaderraremiddle.png",right="Assets/itemsheaderrareright.png",height=54,sideWidth=47,middleWidth=52,textYOffset=1,allowInfluenceIcon=true},
		MAGIC = {left="Assets/itemsheadermagicleft.png",middle="Assets/itemsheadermagicmiddle.png",right="Assets/itemsheadermagicright.png",height=38,sideWidth=32,middleWidth=32,textYOffset=4,allowInfluenceIcon=true},
		NORMAL = {left="Assets/itemsheaderwhiteleft.png",middle="Assets/itemsheaderwhitemiddle.png",right="Assets/itemsheaderwhiteright.png",height=38,sideWidth=32,middleWidth=32,textYOffset=4,allowInfluenceIcon=true},
		GEM = {left="Assets/itemsheadergemleft.png",middle="Assets/itemsheadergemmiddle.png",right="Assets/itemsheadergemright.png",height=38,sideWidth=33,middleWidth=38,textYOffset=3},
		JEWEL = {left="Assets/jewelpassiveheaderleft.png",middle="Assets/jewelpassiveheadermiddle.png",right="Assets/jewelpassiveheaderright.png",height=38,sideWidth=33,middleWidth=38,textYOffset=3},
		NOTABLE = {left="Assets/notablepassiveheaderleft.png",middle="Assets/notablepassiveheadermiddle.png",right="Assets/notablepassiveheaderright.png",height=38,sideWidth=38,middleWidth=38,textYOffset=3},
		PASSIVE = {left="Assets/normalpassiveheaderleft.png",middle="Assets/normalpassiveheadermiddle.png",right="Assets/normalpassiveheaderright.png",height=38,sideWidth=33,middleWidth=38,textYOffset=3},
		KEYSTONE = {left="Assets/keystonepassiveheaderleft.png",middle="Assets/keystonepassiveheadermiddle.png",right="Assets/keystonepassiveheaderright.png",height=38,sideWidth=33,middleWidth=38,textYOffset=3},
		ASCENDANCY = {left="Assets/ascendancypassiveheaderleft.png",middle="Assets/ascendancypassiveheadermiddle.png",right="Assets/ascendancypassiveheaderright.png",height=38,sideWidth=33,middleWidth=38,textYOffset=3},
		MASTERY = {left="Assets/masteryheaderunallocatedleft.png",middle="Assets/masteryheaderunallocatedmiddle.png",right="Assets/masteryheaderunallocatedright.png",height=38,sideWidth=33,middleWidth=38,textYOffset=3},
		MASTERYALLOC = {left="Assets/masteryheaderallocatedleft.png",middle="Assets/masteryheaderallocatedmiddle.png",right="Assets/masteryheaderallocatedright.png",height=38,sideWidth=33,middleWidth=38,textYOffset=3},
	}
	-- spell-checker: enable
	local config
	if self.tooltipHeader and main.showFlavourText and self.lines[1] and self.lines[1].text then
		local rarity = tostring(self.tooltipHeader):upper()
		config = headerConfigs[rarity] or headerConfigs.NORMAL
		self.titleYOffset = config.textYOffset or 0
	end
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
	end

	local columns, maxColumnHeight, drawStack = self:CalculateColumns(ttY, ttX, ttH, ttW, viewPort)

	-- background shading currently must be drawn before text lines.  API change will allow something like the commented lines below
	SetDrawColor(0, 0, 0, .85)
	--SetDrawLayer(nil, GetDrawLayer() - 5)
	DrawImage(nil, ttX, ttY + BORDER_WIDTH, ttW * columns - BORDER_WIDTH, maxColumnHeight - 2 * BORDER_WIDTH)
	--SetDrawLayer(nil, GetDrawLayer())
	SetDrawColor(1, 1, 1)

	-- Item header (drawn within borders)
	if self.tooltipHeader and main.showFlavourText and self.lines[1] and self.lines[1].text then
		local rarity = tostring(self.tooltipHeader):upper()
		local config = headerConfigs[rarity] or headerConfigs.NORMAL

		self.titleYOffset = config.textYOffset or 0

		if not self.headerLeft or self.headerLeftPath ~= config.left then
			self.headerLeft = NewImageHandle()
			self.headerLeft:Load(config.left)
			self.headerLeftPath = config.left
			self.headerMiddle = NewImageHandle()
			self.headerMiddle:Load(config.middle)
			self.headerMiddlePath = config.middle
			self.headerRight = NewImageHandle()
			self.headerRight:Load(config.right)
			self.headerRightPath = config.right
		end

		local headerHeight = config.height
		local headerSideWidth = config.sideWidth
		local headerMiddleWidth = config.middleWidth

		local headerX = ttX + BORDER_WIDTH
		local headerY = ttY + BORDER_WIDTH
		local headerTotalWidth = ttW - 2 * BORDER_WIDTH
		local headerMiddleAreaWidth = m_max(0, headerTotalWidth - 2 * headerSideWidth)

		if self.influenceHeader1 then
			self.influenceIcon1 = NewImageHandle()
			self.influenceIcon1:Load(headerInfluence[self.influenceHeader1])
			self.influenceIcon2 = NewImageHandle()
			self.influenceIcon2:Load(headerInfluence[self.influenceHeader2])
		end

		local foilTypes = {
			["Rainbow"] = {0.6, 1, 0.5},
			["Amethyst"] = {0.9, 0.6, 1},
			["Verdant"] = {0.5, 1, 0.5},
			["Ruby"] = {1, 0.5, 0.6},
			["Cobalt"] = {0.6, 0.7, 1},
			["Sunset"] = {1, 1, 0.6},
			["Aureate"] = {1, 0.85, 0.2},
			["Celestial Quartz"] = {1, 0.7, 0.85},
			["Celestial Ruby"] = {0.8, 0.3, 0.2},
			["Celestial Emerald"] = {0.2, 0.6, 0.3},
			["Celestial Aureate"] = {0.8, 0.7, 0.2},
			["Celestial Pearl"] = {1, 0.85, 0.9},
			["Celestial Amethyst"] = {0.5, 0.6, 1},
		}
		if self.tooltipHeader == "RELIC" then
			--ConPrintf(self.foilType)
			local color = foilTypes[self.foilType] or foilTypes["Rainbow"]
			if color then
				SetDrawColor(color[1], color[2], color[3])
			else
				SetDrawColor(0.6, 1, 0.5) -- fallback to green
			end
		end
		-- Draw left cap first, then influence icon on top
		DrawImage(self.headerLeft, headerX, headerY, headerSideWidth, headerHeight)
		if self.influenceHeader1 and config.allowInfluenceIcon then
			SetDrawColor(1, 1, 1)
			DrawImage(self.influenceIcon1, headerX + 2, headerY + (headerHeight - (headerHeight/2))/2, headerHeight/2, headerHeight/2)
		end

		if self.tooltipHeader == "RELIC" then
			--ConPrintf(self.foilType)
			local color = foilTypes[self.foilType] or foilTypes["Rainbow"]
			if color then
				SetDrawColor(color[1], color[2], color[3])
			else
				SetDrawColor(0.6, 1, 0.5) -- fallback to green
			end
		end
		-- Draw middle fill
		if headerMiddleAreaWidth > 0 then
			local drawX = headerX + headerSideWidth
			local endX = headerX + headerTotalWidth - headerSideWidth
			while drawX + headerMiddleWidth <= endX do
				DrawImage(self.headerMiddle, drawX, headerY, headerMiddleWidth, headerHeight)
				drawX = drawX + headerMiddleWidth
			end
			local remainingWidth = endX - drawX
			if remainingWidth > 0 then
				DrawImage(self.headerMiddle, drawX, headerY, remainingWidth, headerHeight)
			end
		end

		-- Draw right cap
		DrawImage(self.headerRight, headerX + headerTotalWidth - headerSideWidth, headerY, headerSideWidth, headerHeight)
		if self.influenceHeader2 and config.allowInfluenceIcon then
			SetDrawColor(1, 1, 1)
			DrawImage(self.influenceIcon2, headerX + headerTotalWidth - (headerHeight/2) - 2, headerY + (headerHeight - (headerHeight/2))/2, headerHeight/2, headerHeight/2)
		end
	end

	-- Draw lines and images
	local firstSeparatorSkipped = false
	for _, line in ipairs(drawStack) do 
		if #line < 6 then
			local skip = false
			if line[1] and type(line[1]) == "table" and line[1].isSeparator then
				-- Only skip first separator for items and skill gems
				local tooltipType = self.tooltipHeader and tostring(self.tooltipHeader):upper() or ""
				if main.showFlavourText and not firstSeparatorSkipped and 
				(tooltipType == "RELIC" or tooltipType == "UNIQUE" or tooltipType == "RARE" or tooltipType == "MAGIC" or tooltipType == "GEM") then
					firstSeparatorSkipped = true
					skip = true
				else
					SetDrawColor(1, 1, 1)
				end
			elseif type(self.color) == "string" then
				SetDrawColor(self.color)
			else
				SetDrawColor(unpack(self.color))
			end
			if not skip then
				if line[1] and line[1].handle then
					local args = { line[1].handle, line[2], line[3], line[4], line[5] }
					for _, v in ipairs(line[1]) do
						t_insert(args, v)
					end
					SetDrawColor(1,1,1)
					DrawImage(unpack(args))
				else
					DrawImage(unpack(line))
				end
			end
		else
			DrawString(unpack(line))
		end
	end

	-- Draw borders
	if type(self.color) == "string" then
		SetDrawColor(self.color) 
	else
		SetDrawColor(unpack(self.color))
	end
	for i = 0, columns do
		DrawImage(nil, ttX + ttW * i - BORDER_WIDTH * math.ceil(i^2 / (i^2 + 1)), ttY, BORDER_WIDTH, maxColumnHeight)
	end
	DrawImage(nil, ttX, ttY, ttW * columns, BORDER_WIDTH) -- top border
	DrawImage(nil, ttX, ttY + maxColumnHeight - BORDER_WIDTH, ttW * columns, BORDER_WIDTH) -- bottom border

	return ttW, ttH
end
