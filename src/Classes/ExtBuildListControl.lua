-- Path of Building
--
-- Class: ExtBuildListControl
-- List control class for external build providers.
--
local ipairs = ipairs
local s_format = string.format
local t_insert = table.insert
local m_max = math.max
local m_min = math.min
local dkjson = require "dkjson"

local ExtBuildListControlClass = newClass("ExtBuildListControl", "ControlHost", "Control",
	function(self, anchor, rect, providers)
		self.Control(anchor, rect)
		self.ControlHost()
		self:SelectControl()

		self.rowHeight = 200
		self.scroll = "VERTICAL"
		self.forceTooltip = false
		self.font = "VAR"
		self.importButtons = {}
		self.previewButtons = {}
		self.inTransition = false
		self.contentHeight = 0
		self.tabs = {}
		self.activeListProvider = nil
		self.buildProviders = providers
		self.buildProvidersList = {}
		self.providerMaxLength = 150
		for _, provider in ipairs(self.buildProviders) do
			self.providerMaxLength = m_max(self.providerMaxLength, DrawStringWidth(16, self.font, provider.name) + 30)
			t_insert(self.buildProvidersList, provider.name)
		end
	end)

function ExtBuildListControlClass:Init(providerName)
	wipeTable(self.controls)
	wipeTable(self.tabs)

	self.controls.sort = new("DropDownControl", { "TOP", self, "TOP" }, { 0, -20, self.providerMaxLength, 20 },
		self.buildProvidersList, function(index, value)
			self:Init(value)
		end)

	self.controls.sort:SelByValue(providerName)

	self.activeListProvider = nil

	local tabWidth = 0

	for _, provider in ipairs(self.buildProviders) do
		if provider.name == providerName then
			self.activeListProvider = provider.impl
		end
	end

	if self.activeListProvider == nil then
		print("Build provider not found: %s", providerName)
		return
	end

	self.activeListProvider:SetImportCode(self.importCode)
	self.activeListProvider:Activate()
	self.activeListProvider.buildListTitles = self.activeListProvider:GetListTitles()

	local lastControl = nil
	for index, title in ipairs(self.activeListProvider:GetListTitles()) do
		local stringWidth = DrawStringWidth(16, self.font, title)
		local anchor = { "TOP", self, "TOP" }
		if lastControl then
			anchor = { "LEFT", lastControl, "RIGHT" }
		end
		local button = new("ButtonControl", anchor, { 0, lastControl and 0 or -20, stringWidth + 10, 20 }, title, function()
			if self.activeListProvider:GetActiveList() == title then
				return
			end
			self.activeListProvider:SetActiveList(title)
			for _, _button in ipairs(self.tabs) do
				_button.locked = (_button.label == title)
			end
		end)

		button.locked = index == 1

		tabWidth = tabWidth + stringWidth + 10

		-- button.enabled = self.mode ~= "latest"
		if not lastControl then
			button.x = function()
				return (stringWidth + 10 - self.width()) / 2
			end
		end
		t_insert(self.controls, button)
		t_insert(self.tabs, button)
		lastControl = button
	end

	-- responsiveness
	self.controls.sort.width = function ()
		return m_min(150, self.width() - tabWidth)
	end
	self.controls.sort.x = function()
		return (self.width() - self.controls.sort.width()) / 2
	end

	self.controls.scrollBarV = new("ScrollBarControl", { "RIGHT", self, "RIGHT" }, { -1, 0, self.scroll and 16 or 0, 0 },
		80, "VERTICAL") {
		-- y = function()
		-- 	return (self.scrollH and -8 or 0)
		-- end,
		height = function()
			local _, height = self:GetSize()
			return height - 2 - (self.scrollH and 16 or 0)
		end
	}
	if not self.scroll then
		self.controls.scrollBarV.shown = false
	end

	if self.activeListProvider:GetPageUrl() then
		self.controls.all = new("ButtonControl", { "BOTTOM", self, "BOTTOM" }, { 0, 1, self.width, 20 }, "See All",
			function()
				local url = self.activeListProvider:GetPageUrl()
				if url then
					OpenURL(url)
				end
			end)
		self.controls.all.width = function()
			return self.width()
		end
	end
end

function ExtBuildListControlClass:SetImportCode(importCode)
	self.importCode = importCode
end

function ExtBuildListControlClass:IsMouseOver()
	if not self:IsShown() then
		return
	end
	return self:IsMouseInBounds() or self:GetMouseOverControl()
end

function ExtBuildListControlClass:OnKeyDown(key, doubleClick)
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

function ExtBuildListControlClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end

	if self.controls.scrollBarV:IsScrollDownKey(key) then
		self.controls.scrollBarV:Scroll(1)
	elseif self.controls.scrollBarV:IsScrollUpKey(key) then
		self.controls.scrollBarV:Scroll(-1)
	end
end

function ExtBuildListControlClass:importBuild(build)
	if not (build.buildLink) then
		print("Build link is not provided.")
		return
	end
	ImportBuild(build.buildLink, function(xmlText, urlText)
		if xmlText then
			main:SetMode("BUILD", false,
				build.buildName .. (build.authorName and (" - " .. self.build.authorName) or ""),
				xmlText, false, urlText)
		end
	end)
end

function ExtBuildListControlClass:GetAscendancyImageHandle(ascendancy)
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

-- splits strings by word and maxWidth
function ExtBuildListControlClass:splitStringByWidth(str, maxWidth, font)
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
function ExtBuildListControlClass:DrawImage(imgHandle, left, top, width, height)
	local _, y = self:GetPos()
	if top - self.controls.scrollBarV.offset >= y and top + height - self.controls.scrollBarV.offset < self.height() + y then
		DrawImage(imgHandle, left, top - self.controls.scrollBarV.offset, width, height)
	end
end

function ExtBuildListControlClass:DrawString(left, top, align, height, font, text)
	local _, y = self:GetPos()
	if top - self.controls.scrollBarV.offset >= y and top + height - self.controls.scrollBarV.offset < self.height() + y then
		DrawString(left, top - self.controls.scrollBarV.offset, align, height, font, text)
	end
end

function ExtBuildListControlClass:Draw(viewPort, noTooltip)
	if self.activeListProvider == nil then
		return
	end

	--if not main.showPublicBuilds then
	if true then
		return
	end

	-- clear button states
	wipeTable(self.previewButtons)
	wipeTable(self.importButtons)

	-- get variables
	local x, y = self:GetPos()
	local width, height = self:GetSize()

	-- drawing area
	-- SetDrawColor(0.5, 0.5, 0.5)
	SetDrawColor(1, 1, 1)
	DrawImage(nil, x, y, width, height)
	-- borders
	SetDrawColor(0, 0, 0)
	DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
	SetDrawColor(1, 1, 1)

	-- apply padding
	x = x + 10;
	y = y + 10;

	local currentHeight = y

	-- write status message
	if self.activeListProvider.statusMsg then
		self:DrawString(x, currentHeight, "LEFT", 16, self.font, self.activeListProvider.statusMsg)
	end

	local scrollBarV = self.controls.scrollBarV
	self.scrollOffsetV = scrollBarV.offset

	-- remove import/export buttons.
	for i, control in ipairs(self.controls) do
		if control.label == "Import" or control.label == "Preview" then
			self.controls[i] = nil
		end
	end

	local function addSeparator(y, fillH)
		y = y + 4
		SetDrawColor(0.5, 0.5, 0.5)
		self:DrawImage(nil, x - 9, y, self.width() - (y > fillH and 2 or 115), 1)
		y = y + 8
		SetDrawColor(1, 1, 1)
		return y
	end

	-- loop through builds
	for _, build in pairs(self.activeListProvider.buildList) do
		if build.buildName then
			local portraitHeight = currentHeight + 82
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

			-- local lineCount = 0
			if build.buildName then
				for _, line in pairs(self:splitStringByWidth(build.buildName, self.width() - 180, "VAR BOLD")) do
					-- lineCount = lineCount + 1
					self:DrawString(x, currentHeight, "LEFT", 18, "VAR BOLD", line)
					currentHeight = currentHeight + 18
				end
			end

			-- decorator line
			currentHeight = addSeparator(currentHeight, portraitHeight)

			-- main skill
			SetDrawColor(1, 1, 1)
			if build.mainSkill and build.mainSkill ~= "" then
				for _, line in pairs(self:splitStringByWidth(build.mainSkill, self.width() - 125, self.font)) do
					self:DrawString(x, currentHeight, "LEFT", 16, self.font, line)
					currentHeight = currentHeight + 20
				end
				-- decorator line
				currentHeight = addSeparator(currentHeight, portraitHeight)
			end

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
					self:DrawImage(nil, x + authorWidth + DrawStringWidth(14, self.font, build.version) + 30, currentHeight - 7, 1, 28)
				end
			end

			currentHeight = currentHeight + 16

			-- decorator line
			currentHeight = addSeparator(currentHeight, portraitHeight)

			-- stats
			local dpsText = "DPS: 0"
			local lifeText = "Life: 0"
			local ehpText = "EHP: 0"
			if build.dps then
				-- SetDrawColor(1, 0, 0)
				dpsText = formatNumSep(s_format('^x%sDPS^7: %0.f', 'FFC470', build.dps))
			end
			if build.life or build.es then
				-- SetDrawColor(0, 1, 0)
				lifeText = formatNumSep(s_format('%s^7: %0.f', (build.life or 0) > (build.es or 0) and "^xFFAAAALife" or "^x667BC6ES", math.max(build.life or 0, build.es or 0)))
			end
			if build.ehp then
				-- SetDrawColor(0, 0, 1)
				ehpText = formatNumSep(s_format('^x%sEHP^7: %0.f', '3AA6B9',  build.ehp))
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
				currentHeight = currentHeight + 16
				-- decorator line
				currentHeight = addSeparator(currentHeight, portraitHeight)
				currentHeight = currentHeight - 5
			end

			if build.metadata then
				currentHeight = currentHeight + 4
				for _, metadata in pairs(build.metadata) do
					SetDrawColor(1, 1, 1)
					self:DrawString(x, currentHeight, "LEFT", 14, self.font, metadata.key .. ": " .. metadata.value)
					currentHeight = currentHeight + 16
					currentHeight = addSeparator(currentHeight, portraitHeight)
				end
				currentHeight = currentHeight - 4
			end

			-- draw buttons
			currentHeight = currentHeight + 4
			local relativeHeight = currentHeight + 10 - self.controls.scrollBarV.offset
			if relativeHeight > y and relativeHeight < self.height() + y - 10 then
				if build.buildLink then
					local importButton = new("ButtonControl", nil, { x, currentHeight - self.controls.scrollBarV.offset, 45, 20 }, "Import", function()
						self:importBuild(build)
					end)
					t_insert(self.controls, importButton)
				end

				if build.previewLink then
					local previewButton = new("ButtonControl", nil, { x + 50, currentHeight - self.controls.scrollBarV.offset, 60, 20 }, "Preview", function()
							OpenURL(build.previewLink)
					end)
					t_insert(self.controls, previewButton)
				end
				currentHeight = currentHeight + 4
			end

			-- bottom border
			SetDrawColor(1, 1, 1)
			currentHeight = currentHeight + 24
			self:DrawImage(nil, x - 9, currentHeight, self.width() - 1, 3)
			currentHeight = currentHeight + 16
		end
	end

	self.controls.scrollBarV:SetContentDimension(currentHeight - y + 17, self.height())
	self.contentHeight = currentHeight
	-- end
	self:DrawControls(viewPort, (noTooltip and not self.forceTooltip) and self)
end
