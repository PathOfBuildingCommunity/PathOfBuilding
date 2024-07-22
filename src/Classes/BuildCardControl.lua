-- Path of Building
--
-- Class: Build Card Control
-- Build card control for external build lists.
--

local ipairs = ipairs
local s_format = string.format
local t_insert = table.insert
local m_max = math.max
local m_min = math.min
local dkjson = require "dkjson"

local BuildCardClass = newClass("BuildCardControl", "ControlHost", "Control",
	function(self, anchor, x, y, width, height, build, maxY)
		self.ControlHost()
		self.Control(anchor, x, y, width, height)
		self:SelectControl()
		self.build = build
		self.font = "VAR"
		self.currentHeight = y
		self.maxY = maxY

	end)

-- splits strings by word and maxWidth
function BuildCardClass:IsMouseOver()
	if not self:IsShown() then
		return
	end
	return self:IsMouseInBounds() or self:GetMouseOverControl()
end

function BuildCardClass:OnKeyDown(key, doubleClick)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local mOverControl = self:GetMouseOverControl()
	if mOverControl and mOverControl.OnKeyDown then
		return mOverControl:OnKeyDown(key)
	end
	if not self:IsMouseOver() and key:match("BUTTON") then
		return
	end
end

function BuildCardClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
end

function BuildCardClass:GetAscendancyImageHandle(ascendancy)
	if ascendancy then
		local fileName = s_format('Assets/ascendants/%s.jpeg', (ascendancy:gsub("^%l", string.lower)))
		local file = io.open(fileName, "r")
		if file then
			file:close()
			local image = NewImageHandle()
			image:Load(fileName)
			return image
		end
	end

	return nil
end

function BuildCardClass:importBuild()
	if not (self.build.buildLink) then
		print("Build link is not provided.")
		return
	end
	ImportBuild(self.build.buildLink, function(xmlText, urlText)
		if xmlText then
			main:SetMode("BUILD", false,
				self.build.buildName .. (self.build.authorName and (" - " .. self.build.authorName) or ""),
				xmlText, false, urlText)
		end
	end)
end

-- splits strings by word and maxWidth
function BuildCardClass:splitStringByWidth(str, maxWidth, font)
	local words = {}
	for word in str:gmatch("%S+") do
		t_insert(words, word)
	end

	local lines = {}
	local currentLine = ""
	for _, word in ipairs(words) do
		local wordWidth = DrawStringWidth(16, font, currentLine .. " " .. word)
		if wordWidth <= maxWidth then
			currentLine = currentLine .. (currentLine == "" and "" or " ") .. word
		else
			t_insert(lines, currentLine)
			currentLine = word
		end
	end
	t_insert(lines, currentLine)

	return lines
end

-- wrappers for Drawing tools to apply scrolling
function BuildCardClass:DrawImage(imgHandle, left, top, width, height)
	if top + height <= self.maxY() and self.shown then
		DrawImage(imgHandle, left, top, width, height)
	end
end

function BuildCardClass:DrawString(left, top, align, height, font, text)
	if top + height <= self.maxY() and self.shown then
		DrawString(left, top, align, height, font, text)
	end
end

function BuildCardClass:Draw(viewPort, noTooltip)
	local build = self.build
	local x, y = self:GetPos()

	x = x + 10
	y = y + 10

	local currentHeight = y

	if build.buildName then
		local image = nil
		if build.ascendancy or build.class then
			image = self:GetAscendancyImageHandle(build.ascendancy or build.class)
			if image then
				SetDrawColor(0.5, 0.5, 0.5)
				self:DrawImage(nil, x + self.width() - 115, currentHeight - 1, 82, 82)
				SetDrawColor(1, 1, 1)
				self:DrawImage(image, x + self.width() - 114, currentHeight, 80, 80)
			end
		end

		-- title
		local maxTitle = 3
		local titleLines = self:splitStringByWidth(build.buildName, self.width() - 180, "VAR BOLD")
		for var=1,maxTitle,1 do
			local title = titleLines[var]
			-- append ... to last line if there are more lines than max.
			title = title and (title .. ((#titleLines > maxTitle and maxTitle == var) and "..." or "")) or ""
			-- lineCount = lineCount + 1
			self:DrawString(x, currentHeight, "LEFT", 18, "VAR BOLD", title)
			currentHeight = currentHeight + 18
		end

		-- decorator line
		currentHeight = currentHeight + 4
		SetDrawColor(0.5, 0.5, 0.5)
		self:DrawImage(nil, x - 9, currentHeight, self.width() - 115, 1)
		SetDrawColor(1, 1, 1)
		currentHeight = currentHeight + 8

		-- main skill
		SetDrawColor(1, 1, 1)
		if build.mainSkill and build.mainSkill ~= "" then
			local skillLines = self:splitStringByWidth(build.mainSkill, self.width() - 125, self.font)
			local skill = skillLines[1] .. (#skillLines > 1 and "..." or "")
	 		self:DrawString(x, currentHeight, "LEFT", 16, self.font, skill)
		else
			self:DrawString(x, currentHeight, "LEFT", 16, self.font, '-')
		end

		-- decorator line
		currentHeight = currentHeight + 24
		SetDrawColor(0.5, 0.5, 0.5)
		self:DrawImage(nil, x - 9, currentHeight, self.width() - 2, 1)
		currentHeight = currentHeight + 8
		SetDrawColor(1, 1, 1)

		-- author
		if build.author then
			self:DrawString(x, currentHeight, "LEFT", 14, self.font, s_format('%s', build.author))
		end

		-- version
		if build.version then
			local authorWidth = build.author and DrawStringWidth(14, self.font, s_format('%s', build.author)) or 0
			self:DrawString(x + authorWidth + 20, currentHeight, "LEFT", 14, self.font, s_format('%s', build.version))
			SetDrawColor(0.5, 0.5, 0.5)
			if authorWidth then
				self:DrawImage(nil, x + authorWidth + 10, currentHeight - 7, 1, 28)
				self:DrawImage(nil, x + authorWidth + DrawStringWidth(14, self.font, build.version) + 30, currentHeight - 7, 1,
					28)
			end
		end


		-- decorator line
		currentHeight = currentHeight + 20
		SetDrawColor(0.5, 0.5, 0.5)
		self:DrawImage(nil, x - 9, currentHeight, self.width() - 2, 1)
		currentHeight = currentHeight + 8
		SetDrawColor(1, 1, 1)

		-- stats
		local dpsText = "DPS: 0"
		local lifeText = "Life: 0"
		local ehpText = "EHP: 0"
		if build.dps then
			-- SetDrawColor(1, 0, 0)
			dpsText = formatNumSep(s_format('DPS: %0.f', build.dps))
		end
		if build.life or build.es then
			-- SetDrawColor(0, 1, 0)
			lifeText = formatNumSep(s_format('%s: %0.f', build.life > build.es and "Life" or "ES",
				math.max(build.life, build.es)))
		end
		if build.ehp then
			-- SetDrawColor(0, 0, 1)
			ehpText = formatNumSep(s_format('EHP: %0.f', build.ehp))
		end

		-- prevent overlapping on smaller screens.
		local dpsWidth = DrawStringWidth(14, self.font, dpsText)
		local lifeWidth = DrawStringWidth(14, self.font, lifeText)
		local ehpWidth = DrawStringWidth(14, self.font, ehpText)
		if (dpsWidth + lifeWidth + ehpWidth < self.width() - 30) then
			self:DrawString(x, currentHeight, "LEFT", 14, self.font, dpsText)
			SetDrawColor(0.5, 0.5, 0.5)
			self:DrawImage(nil, x + dpsWidth + 10, currentHeight - 7, 1, 28)
			SetDrawColor(1, 1, 1)
			self:DrawString(x + dpsWidth + 20, currentHeight, "LEFT", 14, self.font, lifeText)
			SetDrawColor(0.5, 0.5, 0.5)
			self:DrawImage(nil, x + dpsWidth + lifeWidth + 30, currentHeight - 7, 1, 28)
			self:DrawImage(nil, x + dpsWidth + lifeWidth + ehpWidth + 50, currentHeight - 7, 1, 28)
			SetDrawColor(1, 1, 1)
			self:DrawString(x + dpsWidth + lifeWidth + 40, currentHeight, "LEFT", 14, self.font, ehpText)
			currentHeight = currentHeight + 20
			-- decorator line
			SetDrawColor(0.5, 0.5, 0.5)
			self:DrawImage(nil, x - 9, currentHeight, self.width() - 2, 1)
			currentHeight = currentHeight + 3
		end

		if build.metadata then
			currentHeight = currentHeight + 4
			for _, metadata in pairs(build.metadata) do
				SetDrawColor(1, 1, 1)
				self:DrawString(x, currentHeight, "LEFT", 14, self.font, metadata.key .. ": " .. metadata.value)
				currentHeight = currentHeight + 20
				SetDrawColor(0.5, 0.5, 0.5)
				self:DrawImage(nil, x - 9, currentHeight, self.width(), 1)
			end
		end

		-- draw buttons
		currentHeight = currentHeight + 4
		if not self.controls.importButton then
			self.controls.importButton = new("ButtonControl", nil, self.x + 10, currentHeight, 47, 20, "Import", function()
				self:importBuild()
			end)
		else
			self.controls.importButton.x = self.x + 10
			self.controls.importButton.y = currentHeight
			if currentHeight > self.maxY() then
				self.controls.importButton.shown = false and self.shown
			else
				self.controls.importButton.shown = true and self.shown
			end
		end

		if not self.controls.previewButton then
			self.controls.previewButton = new("ButtonControl", nil, self.x + 60, currentHeight, 60, 20, "Preview", function()
				if self.build.previewLink then
					OpenURL(self.build.previewLink)
				end
			end)
		else
			self.controls.previewButton.x = self.x + 60
			self.controls.previewButton.y = currentHeight
			if currentHeight > self.maxY() then
				self.controls.previewButton.shown = false and self.shown
			else
				self.controls.previewButton.shown = true and self.shown
			end
		end

		-- bottom border
		SetDrawColor(1, 1, 1)
		currentHeight = currentHeight + 26
		self:DrawImage(nil, x - 9, currentHeight, self.width() - 1, 3)
		-- currentHeight = currentHeight + 16

		self:DrawString(x, currentHeight - 10, "LEFT", 14, self.font, s_format('%s', currentHeight - y))


		self:DrawControls(viewPort, (noTooltip and not self.forceTooltip) and self)
		return currentHeight - y
	end
end
