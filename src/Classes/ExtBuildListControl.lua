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

		self.rowHeight = 268
		self.scroll = "VERTICAL"
		self.forceTooltip = false
		self.font = "VAR"
		self.inTransition = false
		self.builds = {}
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
	-- wipeTable(self.buttons)

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
		print("Build provider not found: %s", providerName)
		return
	end

	self.activeListProvider:SetImportCode(self.importCode)
	self.activeListProvider:Activate(
		function (builds)
		for i, control in pairs(self.controls) do
			if control.build then
				control = nil
			end
		end

		for _, build in pairs(builds) do
			local buildCard = new("BuildCardControl", {"BOTTOM", nil, "BOTTOM"}, x, y, self.width(), 200, build)
			buildCard.maxY = function ()
				local x, y = self:GetPos()
				return y + self.height()
			end
			buildCard.width = function()
				return self.width()
			end
			t_insert(self.controls, buildCard)
		end

	end
)
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
		self.rowHeight, "VERTICAL") {
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

	for _, build in pairs(self.builds) do
		build:OnKeyDown(key, doubleClick)
	end
end

function ExtBuildListControlClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local function scroll(offset)
		for i, buildCard in pairs(self.builds) do
			buildCard.skip = i <= offset
		end
	end

	if self.controls.scrollBarV:IsScrollDownKey(key) then
		self.controls.scrollBarV:Scroll(1)
		local offset = self.controls.scrollBarV.offset / self.rowHeight
		scroll(offset)
	elseif self.controls.scrollBarV:IsScrollUpKey(key) then
		self.controls.scrollBarV:Scroll(-1)
		local offset = self.controls.scrollBarV.offset / self.rowHeight
		scroll(offset)
	end

	for _, build in pairs(self.builds) do
		build:OnKeyUp(key)
	end
end

function ExtBuildListControlClass:SetImportCode(importCode)
	self.importCode = importCode
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
	-- x = x + 10;
	-- y = y + 10;

	local currentHeight = y

	-- write status message
	if self.activeListProvider.statusMsg then
		DrawString(x + 10, currentHeight + 10, "LEFT", 16, self.font, self.activeListProvider.statusMsg)
		-- self:DrawControls(viewPort, (noTooltip and not self.forceTooltip) and self)
		for _, control in pairs(self.controls) do
			if not control.build then
				control:Draw(viewPort, noTooltip)
			end
		end
		return
	end

	-- loop through builds
	-- for _, build in pairs(self.activeListProvider.buildList) do
	-- 	if build.buildName then
	-- 		local image = nil
	-- 		if build.ascendancy or build.class then
	-- 			image = self:GetAscendancyImageHandle(build.ascendancy or build.class)
	-- 			if image then
	-- 				SetDrawColor(0.5, 0.5, 0.5)
	-- 				self:DrawImage(nil, x + self.width() - 115, currentHeight - 1, 82, 82)
	-- 				SetDrawColor(1, 1, 1)
	-- 				self:DrawImage(image, x + self.width() - 114, currentHeight, 80, 80)
	-- 			end
	-- 		end

	-- 		local lineCount = 0
	-- 		if build.buildName then
	-- 			for _, line in pairs(self:splitStringByWidth(build.buildName, self.width() - 180, "VAR BOLD")) do
	-- 				lineCount = lineCount + 1
	-- 				self:DrawString(x, currentHeight, "LEFT", 18, "VAR BOLD", line)
	-- 				currentHeight = currentHeight + 18
	-- 			end
	-- 		end

	-- 		-- add at least 32 height to title row so that the ascendancy picture
	-- 		-- does not overlap with other lines
	-- 		if lineCount < 3 then
	-- 			currentHeight = currentHeight + (16 * (2 + (build.mainSkill and 1 or 0) - lineCount))
	-- 		end

	-- 		-- decorator line
	-- 		currentHeight = currentHeight + 4
	-- 		SetDrawColor(0.5, 0.5, 0.5)
	-- 		self:DrawImage(nil, x - 9, currentHeight, self.width() - 115, 1)
	-- 		currentHeight = currentHeight + 8

	-- 		-- main skill, ascendancy
	-- 		SetDrawColor(1, 1, 1)
	-- 		if build.mainSkill and build.mainSkill ~= "" then
	-- 			for _, line in pairs(self:splitStringByWidth(build.mainSkill, self.width() - 125, self.font)) do
	-- 				lineCount = lineCount + 1
	-- 				self:DrawString(x, currentHeight, "LEFT", 16, self.font, line)
	-- 				currentHeight = currentHeight + 20
	-- 			end
	-- 			currentHeight = currentHeight + 4
	-- 			-- decorator line
	-- 			SetDrawColor(0.5, 0.5, 0.5)
	-- 			self:DrawImage(nil, x - 9, currentHeight, self.width() - 115, 1)
	-- 			currentHeight = currentHeight + 8
	-- 			SetDrawColor(1, 1, 1)
	-- 		end

	-- 		-- author
	-- 		if build.author then
	-- 			self:DrawString(x, currentHeight, "LEFT", 14, self.font, s_format('%s', build.author))
	-- 		end

	-- 		-- version
	-- 		if build.version then
	-- 			local authorWidth = build.author and DrawStringWidth(14, self.font, s_format('%s', build.author)) or 0
	-- 			self:DrawString(x + authorWidth + 20, currentHeight, "LEFT", 14, self.font, s_format('%s', build.version))
	-- 			SetDrawColor(0.5, 0.5, 0.5)
	-- 			if authorWidth then
	-- 				self:DrawImage(nil, x + authorWidth + 10, currentHeight - 7, 1, 28)
	-- 				self:DrawImage(nil, x + authorWidth + DrawStringWidth(14, self.font, build.version) + 30, currentHeight - 7, 1, 28)
	-- 			end
	-- 		end

	-- 		currentHeight = currentHeight + 20

	-- 		-- decorator line
	-- 		SetDrawColor(0.5, 0.5, 0.5)
	-- 		self:DrawImage(nil, x - 9, currentHeight, self.width(), 1)
	-- 		currentHeight = currentHeight + 8
	-- 		SetDrawColor(1, 1, 1)

	-- 		-- stats
	-- 		local dpsText = "DPS: 0"
	-- 		local lifeText = "Life: 0"
	-- 		local ehpText = "EHP: 0"
	-- 		if build.dps then
	-- 			-- SetDrawColor(1, 0, 0)
	-- 			dpsText = formatNumSep(s_format('DPS: %0.f', build.dps))
	-- 		end
	-- 		if build.life or build.es then
	-- 			-- SetDrawColor(0, 1, 0)
	-- 			lifeText = formatNumSep(s_format('%s: %0.f', build.life > build.es and "Life" or "ES", math.max(build.life, build.es)))
	-- 		end
	-- 		if build.ehp then
	-- 			-- SetDrawColor(0, 0, 1)
	-- 			ehpText = formatNumSep(s_format('EHP: %0.f', build.ehp))
	-- 		end

	-- 		-- prevent overlapping on smaller screens.
	-- 		local dpsWidth = DrawStringWidth(14, self.font, dpsText)
	-- 		local lifeWidth = DrawStringWidth(14, self.font, lifeText)
	-- 		local ehpWidth = DrawStringWidth(14, self.font, ehpText)
	-- 		if (dpsWidth + lifeWidth + ehpWidth < self.width() - 30) then
	-- 			self:DrawString(x, currentHeight, "LEFT", 14, self.font, dpsText)
	-- 			SetDrawColor(0.5, 0.5, 0.5)
	-- 			self:DrawImage(nil, x + dpsWidth + 10, currentHeight - 7, 1, 28)
	-- 			SetDrawColor(1, 1, 1)
	-- 			self:DrawString(x + dpsWidth + 20, currentHeight, "LEFT", 14, self.font, lifeText)
	-- 			SetDrawColor(0.5, 0.5, 0.5)
	-- 			self:DrawImage(nil, x + dpsWidth + lifeWidth + 30, currentHeight - 7, 1, 28)
	-- 			self:DrawImage(nil, x + dpsWidth + lifeWidth + ehpWidth + 50, currentHeight - 7, 1, 28)
	-- 			SetDrawColor(1, 1, 1)
	-- 			self:DrawString(x + dpsWidth + lifeWidth + 40, currentHeight, "LEFT", 14, self.font, ehpText)
	-- 			currentHeight = currentHeight + 20
	-- 			-- decorator line
	-- 			SetDrawColor(0.5, 0.5, 0.5)
	-- 			self:DrawImage(nil, x - 9, currentHeight, self.width(), 1)
	-- 			currentHeight = currentHeight + 3
	-- 		end

	-- 		-- SetDrawColor(1, 1, 1)

	-- 		if build.metadata then
	-- 			currentHeight = currentHeight + 4
	-- 			for _, metadata in pairs(build.metadata) do
	-- 				SetDrawColor(1, 1, 1)
	-- 				self:DrawString(x, currentHeight, "LEFT", 14, self.font, metadata.key .. ": " .. metadata.value)
	-- 				currentHeight = currentHeight + 20
	-- 				SetDrawColor(0.5, 0.5, 0.5)
	-- 				self:DrawImage(nil, x - 9, currentHeight, self.width(), 1)
	-- 			end

	-- 		end

	-- 		-- import button
	-- 		local importButton = {
	-- 			buildLink = build.buildLink,
	-- 			buildName = build.buildName,
	-- 			authorName = build.author,
	-- 			x0 = x,
	-- 			y0 = currentHeight + 6,
	-- 			x1 = x + 47,
	-- 			y1 = currentHeight + 26
	-- 		}
	-- 		t_insert(self.importButtons, importButton)
	-- 		-- preview button
	-- 		local previewButton = {
	-- 			previewLink = build.previewLink,
	-- 			x0 = x + 50,
	-- 			y0 = currentHeight + 6,
	-- 			x1 = x + 115,
	-- 			y1 = currentHeight + 26
	-- 		}
	-- 		t_insert(self.previewButtons, previewButton)
	-- 		local hButton = self:GetHoveredButton()

	-- 		-- highlight if hovered
	-- 		if hButton and hButton.type == "import" and hButton.button.buildLink == importButton.buildLink then
	-- 			SetDrawColor(1, 1, 1)
	-- 			self:DrawImage(nil, x, currentHeight + 6, 47, 20)
	-- 			SetDrawColor(0.5, 0.5, 0.5)
	-- 		else
	-- 			self:DrawImage(nil, x, currentHeight + 6, 47, 20)
	-- 			SetDrawColor(0, 0, 0)
	-- 		end

	-- 		-- draw the import button
	-- 		self:DrawImage(nil, x + 1, currentHeight + 7, 45, 18)
	-- 		if self.inTransition then
	-- 			SetDrawColor(0.5, 0.5, 0.5)
	-- 		else
	-- 			SetDrawColor(1, 1, 1)
	-- 		end
	-- 		self:DrawString(x + 5, currentHeight + 9, "LEFT", 14, self.font, 'Import')


	-- 		-- highlight if hovered
	-- 		if hButton and hButton.type == "preview" and hButton.button.previewLink == previewButton.previewLink then
	-- 			SetDrawColor(1, 1, 1)
	-- 			self:DrawImage(nil, x + 50, currentHeight + 6, 55, 20)
	-- 			SetDrawColor(0.5, 0.5, 0.5)
	-- 		else
	-- 			SetDrawColor(0.5, 0.5, 0.5)
	-- 			self:DrawImage(nil, x + 50, currentHeight + 6, 55, 20)
	-- 			SetDrawColor(0, 0, 0)
	-- 		end

	-- 		self:DrawImage(nil, x + 51, currentHeight + 7, 53, 18)
	-- 		if self.inTransition then
	-- 			SetDrawColor(0.5, 0.5, 0.5)
	-- 		else
	-- 			SetDrawColor(1, 1, 1)
	-- 		end
	-- 		self:DrawString(x + 55, currentHeight + 9, "LEFT", 14, self.font, 'Preview')

	-- 		-- bottom border
	-- 		SetDrawColor(1, 1, 1)
	-- 		currentHeight = currentHeight + 34
	-- 		self:DrawImage(nil, x - 9, currentHeight, self.width() - 1, 3)
	-- 		currentHeight = currentHeight + 16
	-- 	end
	-- end

	-- end
	-- self:DrawControls(viewPort, (noTooltip and not self.forceTooltip) and self)
	local totalHeight = 0
	for index, control in pairs(self.controls) do
		if control.build then
			local offset = self.controls.scrollBarV.offset / self.rowHeight
			control.shown = index > offset
			control.show = true
			local widgetHeight = 0
			if index > offset then
				control.y = currentHeight
				control.x = x
				widgetHeight = control:Draw(viewPort, noTooltip)
				currentHeight = currentHeight + widgetHeight
				totalHeight = totalHeight + widgetHeight
			else
				totalHeight = totalHeight + control:Draw(viewPort, noTooltip)
			end
		else
			control:Draw(viewPort, noTooltip)
		end
	end
	-- doesnt set it correct...
	self.controls.scrollBarV:SetContentDimension(totalHeight + y, self.height())
	-- self:DrawControls(viewPort, (noTooltip and not self.forceTooltip) and self)
end
