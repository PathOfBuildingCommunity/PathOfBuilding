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
	function(self, anchor, x, y, width, height, providers)
		self.Control(anchor, x, y, width, height)
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

	self.controls.sort = new("DropDownControl", { "TOP", self, "TOP" }, 0, -20, self.providerMaxLength, 20,
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
		printf("Build provider not found: %s", providerName)
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
		local button = new("ButtonControl", anchor, 0, lastControl and 0 or -20, stringWidth + 10, 20, title, function()
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

	self.controls.scrollBarV = new("ScrollBarControl", { "RIGHT", self, "RIGHT" }, -1, 0, self.scroll and 16 or 0, 0,
		40, "VERTICAL") {
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
		self.controls.all = new("ButtonControl", { "BOTTOM", self, "BOTTOM" }, 0, 1, self.width, 20, "See All",
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

	if key == "LEFTBUTTON" then
		self:CheckButtons()
	end
end

function ExtBuildListControlClass:GetHoveredButton()
	if self.inTransition then
		return
	end
	local cursorX, cursorY = GetCursorPos();
	cursorY = cursorY + self.controls.scrollBarV.offset
	for i, importButton in ipairs(self.importButtons) do
		if (cursorX > importButton.x0) and
			(cursorX < importButton.x1) and
			(cursorY > importButton.y0) and
			(cursorY < importButton.y1) then
			return {
				button = importButton,
				type = 'import'
			}
		end
	end

	for i, previewButton in ipairs(self.previewButtons) do
		if (cursorX > previewButton.x0) and
			(cursorX < previewButton.x1) and
			(cursorY > previewButton.y0) and
			(cursorY < previewButton.y1) then
			return {
				button = previewButton,
				type = 'preview'
			}
		end
	end
end

function ExtBuildListControlClass:GetAscendancyImageHandle(ascendancy)
	local image = nil
	if ascendancy then
		image = NewImageHandle()
		image:Load(s_format('Assets/ascendants/%s.jpeg', (ascendancy:gsub("^%l", string.lower))))
	end

	return image
end

function ExtBuildListControlClass:GetClassImageHandle(class)
	local image = nil
	if class then
		image = NewImageHandle()
		image:Load(s_format('Assets/ascendants/%s.jpeg', (class:gsub("^%l", string.lower))))
	end

	return image
end

function ExtBuildListControlClass:HandleButtonClick(button, buttonType)
	if button then
		self.inTransition = true
		if buttonType == "import" then
			ImportBuild(button.buildLink, function (xmlText, urlText)
				if xmlText then
					main:SetMode("BUILD", false, button.buildName, xmlText, false, urlText)
				end
			end)
		elseif buttonType == "preview" then
			OpenURL(button.previewLink)
		end
		self.inTransition = false
	end
end

function ExtBuildListControlClass:CheckButtons()
	if self.inTransition then
		return
	end
	local cursorX, cursorY = GetCursorPos();
	cursorY = cursorY + self.controls.scrollBarV.offset
	for i, importButton in ipairs(self.importButtons) do
		if (cursorX > importButton.x0) and
			(cursorX < importButton.x1) and
			(cursorY > importButton.y0) and
			(cursorY < importButton.y1) then
			self:HandleButtonClick(importButton, 'import')
			break
		end
	end

	for i, previewButton in ipairs(self.previewButtons) do
		if (cursorX > previewButton.x0) and
			(cursorX < previewButton.x1) and
			(cursorY > previewButton.y0) and
			(cursorY < previewButton.y1) then
			self:HandleButtonClick(previewButton, 'preview')
			break
		end
	end
end

-- splits strings by word and maxWidth
function ExtBuildListControlClass:splitStringByWidth(str, maxWidth)
	local words = {}
	for word in str:gmatch("%S+") do
		t_insert(words, word)
	end

	local lines = {}
	local currentLine = ""
	for _, word in ipairs(words) do
		local wordWidth = DrawStringWidth(16, self.font, currentLine .. " " .. word)
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

	currentHeight = y - self.scrollOffsetV

	-- loop through builds
	for _, build in pairs(self.activeListProvider.buildList) do
		if build.buildName then
			local image = nil
			if build.ascendancy then
				image = self:GetAscendancyImageHandle(build.ascendancy)
			else if build.class then
				image = self:GetClassImageHandle(build.class)
				end
			end

			if image then
				SetDrawColor(0.5, 0.5, 0.5)
				self:DrawImage(nil, x + self.width() - 115, currentHeight - 1, 82, 82)
				SetDrawColor(1, 1, 1)
				self:DrawImage(image, x + self.width() - 114, currentHeight, 80, 80)
			end

			local lineCount = 0
			if build.buildName then
				for _, line in pairs(self:splitStringByWidth(build.buildName, self.width() - 125)) do
					lineCount = lineCount + 1
					self:DrawString(x, currentHeight, "LEFT", 16, self.font, line)
					currentHeight = currentHeight + 16
				end
			end
			-- add at least 32 height to title row so that the ascendancy picture
			-- does not overlap with other lines
			if lineCount < 3 then
				currentHeight = currentHeight + (16 * (3 - lineCount))
			end

			-- decorator line
			currentHeight = currentHeight + 4
			SetDrawColor(0.5, 0.5, 0.5)
			self:DrawImage(nil, x - 9, currentHeight, self.width() - 115, 1)
			currentHeight = currentHeight + 4

			-- main skill, ascendancy
			SetDrawColor(1, 1, 1)
			if build.mainSkill then
				for _, line in pairs(self:splitStringByWidth(build.mainSkill, self.width() - 125)) do
					lineCount = lineCount + 1
					self:DrawString(x, currentHeight, "LEFT", 16, self.font, line)
					currentHeight = currentHeight + 16
				end
				currentHeight = currentHeight + 4
			else
				self:DrawString(x, currentHeight, "LEFT", 14, self.font, s_format('%s', '-'))
				currentHeight = currentHeight + 20
			end


			-- decorator line
			SetDrawColor(0.5, 0.5, 0.5)
			self:DrawImage(nil, x - 9, currentHeight, self.width() - 115, 1)
			currentHeight = currentHeight + 8
			SetDrawColor(1, 1, 1)

			-- author
			if build.author then
				self:DrawString(x, currentHeight, "LEFT", 14, self.font, s_format('%s', build.author))
			end


			currentHeight = currentHeight + 20

			-- decorator line
			SetDrawColor(0.5, 0.5, 0.5)
			self:DrawImage(nil, x - 9, currentHeight, self.width(), 1)
			currentHeight = currentHeight + 8
			SetDrawColor(1, 1, 1)

			-- stats
			local dpsText = "DPS:"
			local lifeText = "Life: "
			local ehpText = "EHP: "
			if build.dps then
				-- SetDrawColor(1, 0, 0)
				dpsText = s_format('DPS: %0.f', build.dps)
			end
			if build.life or build.es then
				-- SetDrawColor(0, 1, 0)
				lifeText = s_format('%s: %0.f', build.life > build.es and "Life" or "ES", math.max(build.life, build.es))
			end
			if build.ehp then
				-- SetDrawColor(0, 0, 1)
				ehpText = s_format('EHP: %0.f', build.ehp)
			end

			-- prevent overlapping on smaller screens.
			local dpsWidth = DrawStringWidth(16, self.font, dpsText)
			local lifeWidth = DrawStringWidth(16, self.font, lifeText)
			local ehpWidth = DrawStringWidth(16, self.font, ehpText)
			if (dpsWidth + lifeWidth + ehpWidth < self.width() - 30) then
				self:DrawString(x, currentHeight, "LEFT", 14, self.font, dpsText)
				self:DrawString(x + dpsWidth, currentHeight, "LEFT", 14, self.font, lifeText)
				self:DrawString(x + dpsWidth + lifeWidth, currentHeight, "LEFT", 14, self.font, ehpText)
				currentHeight = currentHeight + 20
				-- decorator line
				SetDrawColor(0.5, 0.5, 0.5)
				self:DrawImage(nil, x - 9, currentHeight, self.width(), 1)
			end

			if build.metadata then
				currentHeight = currentHeight + 4
				for _, metadata in pairs(build.metadata) do
					SetDrawColor(1, 1, 1)
					self:DrawString(x, currentHeight, "LEFT", 16, self.font, metadata.key .. ": " .. metadata.value)
					currentHeight = currentHeight + 20
					SetDrawColor(0.5, 0.5, 0.5)
					self:DrawImage(nil, x - 9, currentHeight, self.width(), 1)
					currentHeight = currentHeight + 4
				end

			end


			-- import button
			local importButton = {
				buildLink = build.buildLink,
				buildName = build.buildName,
				x0 = x,
				y0 = currentHeight + 6,
				x1 = x + 47,
				y1 = currentHeight + 26
			}
			t_insert(self.importButtons, importButton)
			-- preview button
			local previewButton = {
				previewLink = build.previewLink,
				x0 = x + 50,
				y0 = currentHeight + 6,
				x1 = x + 115,
				y1 = currentHeight + 26
			}
			t_insert(self.previewButtons, previewButton)
			local hButton = self:GetHoveredButton()

			-- highlight if hovered
			if hButton and hButton.type == "import" and hButton.button.buildLink == importButton.buildLink then
				SetDrawColor(1, 1, 1)
				self:DrawImage(nil, x, currentHeight + 6, 47, 20)
				SetDrawColor(0.5, 0.5, 0.5)
			else
				self:DrawImage(nil, x, currentHeight + 6, 47, 20)
				SetDrawColor(0, 0, 0)
			end

			-- draw the import button
			self:DrawImage(nil, x + 1, currentHeight + 7, 45, 18)
			if self.inTransition then
				SetDrawColor(0.5, 0.5, 0.5)
			else
				SetDrawColor(1, 1, 1)
			end
			self:DrawString(x + 5, currentHeight + 8, "LEFT", 14, self.font, 'Import')


			-- highlight if hovered
			if hButton and hButton.type == "preview" and hButton.button.previewLink == previewButton.previewLink then
				SetDrawColor(1, 1, 1)
				self:DrawImage(nil, x + 50, currentHeight + 6, 55, 20)
				SetDrawColor(0.5, 0.5, 0.5)
			else
				SetDrawColor(0.5, 0.5, 0.5)
				self:DrawImage(nil, x + 50, currentHeight + 6, 55, 20)
				SetDrawColor(0, 0, 0)
			end

			self:DrawImage(nil, x + 51, currentHeight + 7, 53, 18)
			if self.inTransition then
				SetDrawColor(0.5, 0.5, 0.5)
			else
				SetDrawColor(1, 1, 1)
			end
			self:DrawString(x + 55, currentHeight + 8, "LEFT", 14, self.font, 'Preview')

			-- bottom border
			SetDrawColor(1, 1, 1)
			currentHeight = currentHeight + 36
			self:DrawImage(nil, x - 9, currentHeight, self.width() - 1, 1)
			currentHeight = currentHeight + 16
		end
	end

	self.controls.scrollBarV:SetContentDimension(currentHeight - y + 30, self.height())
	self.contentHeight = currentHeight
	-- end
	self:DrawControls(viewPort, (noTooltip and not self.forceTooltip) and self)
end
