-- Path of Building
--
-- Class: ArchivesListControl
-- Archives list control.
--
local ipairs = ipairs
local s_format = string.format
local t_insert = table.insert
local dkjson = require "dkjson"

local ArchivesListClass = newClass("ArchivesListControl", "ControlHost", "Control",
	function(self, anchor, x, y, width, height, mode)
		self.Control(anchor, x, y, width, height)
		self.ControlHost()
		self:SelectControl()
		self.list = {}
		self.rowHeight = 200
		self.scroll = "VERTICAL"
		self.forceTooltip = false
		self.font = "VAR"
		self.errMsg = nil
		self.listMode = "VERTICAL"
		self.importButtons = {}
		self.previewButtons = {}
		self.mode = mode
		self.inTransition = false
		self.contentHeight = nil
		self:GetBuilds()

		self.controls.scrollBarV = new("ScrollBarControl", { "RIGHT", self, "RIGHT" }, -1, 0, self.scroll and 16 or 0, 0,
			40, "VERTICAL") {
			y = function()
				return (self.scrollH and -8 or 0)
			end,
			height = function()
				local width, height = self:GetSize()
				return height - 2 - (self.scrollH and 16 or 0)
			end
		}
		if not self.scroll then
			self.controls.scrollBarV.shown = false
		end

		if self.mode ~= "similar" then
			self.controls.latest = new("ButtonControl", { "TOP", self, "TOP" }, 0, -20, 60, 20, "Latest", function()
				if self.mode ~= "latest" then
					self.mode = "latest"
					self:GetBuilds()
					self.controls.latest.enabled = false
					self.controls.trending.enabled = true
				end
			end)
			self.controls.latest.enabled = self.mode ~= "latest"
			self.controls.latest.x = function()
				return -self.width() / 2 + 30
			end
			self.controls.trending = new("ButtonControl", { "LEFT", self.controls.latest, "RIGHT" }, 0, 0, 80, 20,
				"Trending", function()
					if not self.mode ~= "trending" then
						self.mode = "trending"
						self:GetBuilds()
						self.controls.latest.enabled = true
						self.controls.trending.enabled = false
					end
				end)
			self.controls.trending.enabled = self.mode ~= "trending"
		end
		self.controls.all = new("ButtonControl", { "BOTTOM", self, "BOTTOM" }, 0, 1, self.width, 20, "See All",
			function()
				local url = self:GetPageUrl()
				if url then
					OpenURL(url)
				end
			end)
	end)

function ArchivesListClass:IsMouseOver()
	if not self:IsShown() then
		return
	end
	return self:IsMouseInBounds() or self:GetMouseOverControl()
end

function ArchivesListClass:OnKeyDown(key, doubleClick)
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

function ArchivesListClass:OnKeyUp(key)
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

function ArchivesListClass:GetHoveredButton()
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

function ArchivesListClass:GetApiUrl()
	local archivesUrl = 'https://pobarchives.com'
	local apiPath = '/api/builds'
	return archivesUrl .. apiPath .. '?q=' .. self.mode
end

function ArchivesListClass:GetPageUrl()
	local archivesUrl = 'https://pobarchives.com'
	local buildsPath = '/builds'
	if self.mode == "latest" then
		return archivesUrl .. buildsPath .. '/yenTGNDb'
	end
	if self.mode == "trending" then
		return archivesUrl .. buildsPath .. '/7U8QXU8m?sort=popularity'
	end
	if self.mode == "similar" then
		return archivesUrl .. buildsPath .. '/?similar=' .. self.similarTo
	end

	return nil
end

function ArchivesListClass:GetAscendancyImageHandle(ascendancy)
	local image = nil
	if ascendancy then
		image = NewImageHandle()
		image:Load(s_format('Assets/ascendants/%s.jpeg', (ascendancy:gsub("^%l", string.lower))))
	end

	return image
end

function ArchivesListClass:HandleButtonClick(button, buttonType)
	if button then
		self.inTransition = true
		if buttonType == "import" then
			local urlText = button.build_link:gsub("^[%s?]+", ""):gsub("[%s?]+$", "") -- Quick Trim
			local websiteInfo = nil
			for j = 1, #buildSites.websiteList do
				if urlText:match(buildSites.websiteList[j].matchURL) then
					websiteInfo = buildSites.websiteList[j]
				end
			end

			if websiteInfo then
				buildSites.DownloadBuild(button.build_link, websiteInfo, function(isSuccess, data)
					if isSuccess then
						local xmlText = Inflate(common.base64.decode(data:gsub("-", "+"):gsub("_", "/")))
						if xmlText then
							main:SetMode("BUILD", false, button.buildName, xmlText, nil, "skdglsdg")
						end
					end
				end)
			end
		elseif buttonType == "preview" then
			OpenURL(s_format('https://pobarchives.com/build/%s', button.short_uuid))
		end
		self.inTransition = false
	end
end

function ArchivesListClass:CheckButtons()
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
function ArchivesListClass:splitStringByWidth(str, maxWidth)
	local words = {}
	for word in str:gmatch("%S+") do
		table.insert(words, word)
	end

	local lines = {}
	local currentLine = ""
	for i, word in ipairs(words) do
		local wordWidth = DrawStringWidth(16, self.font, word)
		if DrawStringWidth(16, self.font, currentLine .. " " .. word) <= maxWidth then
			currentLine = currentLine .. (currentLine == "" and "" or " ") .. word
		else
			table.insert(lines, currentLine)
			currentLine = word
		end
	end
	table.insert(lines, currentLine)

	return lines
end

-- wrappers for Drawing tools to apply scrolling
function ArchivesListClass:DrawImage(imgHandle, left, top, width, height)
	local _, y = self:GetPos()
	if top - self.controls.scrollBarV.offset >= y then
		DrawImage(imgHandle, left, top - self.controls.scrollBarV.offset, width, height)
	end
end

function ArchivesListClass:DrawString(left, top, align, height, font, text)
	local _, y = self:GetPos()
	if top - self.controls.scrollBarV.offset >= y then
		DrawString(left, top - self.controls.scrollBarV.offset, align, height, font, text)
	end
end

function ArchivesListClass:Draw(viewPort, noTooltip)
	-- clear button states
	wipeTable(self.previewButtons)
	wipeTable(self.importButtons)

	-- get variables
	local x, y = self:GetPos()
	local width, height = self:GetSize()

	-- drawing area
	SetDrawColor(0.5, 0.5, 0.5)
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
	if self.errMsg then
		self:DrawString(x, currentHeight, "LEFT", 16, self.font, self.errMsg)
	end

	local scrollBarV = self.controls.scrollBarV
	self.scrollOffsetV = scrollBarV.offset

	currentHeight = y - self.scrollOffsetV

	-- loop through builds
	for _, build in pairs(self.list) do
		if build.buildName and build.short_uuid then
			if build.ascendancy then
				self:DrawImage(nil, x + self.width() - 115, currentHeight - 1, 82, 82)
				local image = self:GetAscendancyImageHandle(build.ascendancy)
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
			if lineCount < 2 then
				currentHeight = currentHeight + (16 * (2 - lineCount))
			end

			-- decorator line
			currentHeight = currentHeight + 8
			SetDrawColor(0.5, 0.5, 0.5)
			self:DrawImage(nil, x - 10, currentHeight, self.width() - 115, 1)
			currentHeight = currentHeight + 8

			-- main skill, ascendancy
			SetDrawColor(1, 1, 1)
			if build.mainSkill then
				self:DrawString(x, currentHeight, "LEFT", 14, self.font, s_format('%s', build.mainSkill))
			else
				self:DrawString(x, currentHeight, "LEFT", 14, self.font, s_format('%s', '-'))
			end

			currentHeight = currentHeight + 20

			-- decorator line
			SetDrawColor(0.5, 0.5, 0.5)
			self:DrawImage(nil, x - 10, currentHeight, self.width() - 115, 1)
			currentHeight = currentHeight + 8
			SetDrawColor(1, 1, 1)

			-- author
			if build.author then
				self:DrawString(x, currentHeight, "LEFT", 14, self.font, s_format('%s', build.author))
			end


			currentHeight = currentHeight + 20

			-- decorator line
			SetDrawColor(0.5, 0.5, 0.5)
			self:DrawImage(nil, x - 10, currentHeight, self.width(), 1)
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
				lifeText = s_format('%s: %0.f', build.life > build.es and "Life" or "ES" , math.max(build.life, build.es))
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
				self:DrawImage(nil, x - 10, currentHeight, self.width(), 1)
			end


			-- import button
			local importButton = {
				build_link = build.build_link,
				buildName = build.buildName,
				x0 = x,
				y0 = currentHeight + 6,
				x1 = x + 47,
				y1 = currentHeight + 26
			}
			table.insert(self.importButtons, importButton)
			-- preview button
			local previewButton = {
				short_uuid = build.short_uuid,
				x0 = x + 50,
				y0 = currentHeight + 6,
				x1 = x + 115,
				y1 = currentHeight + 26
			}
			table.insert(self.previewButtons, previewButton)
			local hButton = self:GetHoveredButton()

			-- highlight if hovered
			if hButton and hButton.type == "import" and hButton.button.build_link == importButton.build_link then
				SetDrawColor(1, 1, 1)
				self:DrawImage(nil, x, currentHeight + 6, 47, 20)
				SetDrawColor(0.5, 0.5, 0.5)
			else
				self:DrawImage(nil, x, currentHeight + 6, 47, 20)
				SetDrawColor(0, 0, 0)
			end

			-- draw the button
			self:DrawImage(nil, x + 1, currentHeight + 7, 45, 18)
			if self.inTransition then
				SetDrawColor(0.5, 0.5, 0.5)
			else
				SetDrawColor(1, 1, 1)
			end
			self:DrawString(x + 5, currentHeight + 8, "LEFT", 14, self.font, 'Import')


			-- highlight if hovered
			if hButton and hButton.type == "preview" and hButton.button.short_uuid == previewButton.short_uuid then
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
			self:DrawImage(nil, x - 10, currentHeight, self.width() - 1, 1)
			currentHeight = currentHeight + 16
		end
	end

	-- set scroll bar height
	if not self.contentHeight and next(self.list) ~= nil then
		print('setting new content dimension', currentHeight, self.height(), x)
		scrollBarV:SetContentDimension(currentHeight - y - 10, self.height())
		self.contentHeight = currentHeight
	end
	self:DrawControls(viewPort, (noTooltip and not self.forceTooltip) and self)
end

function ArchivesListClass:GetBuilds()
	self.errMsg = "Loading.."
	wipeTable(self.list)
	self.contentHeight = nil
	launch:DownloadPage(self:GetApiUrl(), function(response, errMsg)
		if errMsg then
			self.errMsg = errMsg
			return
		end

		local obj = dkjson.decode(response.body)
		if not obj or not obj.builds or next(obj.builds) == nil then
			self.errMsg = "No builds found."
			return
		end


		for _, value in pairs(obj.builds) do
			local build = {}
			build.buildName = value.build_info.title
			build.author = value.build_info.author
			build.mainSkill = value.build_info.mainSkill
			if value.build_info.ascendancy ~= "None" then
				build.ascendancy = value.build_info.ascendancy
			end
			build.short_uuid = value.build_info.short_uuid
			build.build_link = value.build_info.build_link
			build.ehp = value.stats.TotalEHP
			build.life = value.stats.LifeUnreserved
			build.es = value.stats.EnergyShield
			build.dps = value.fullDPS
			t_insert(self.list, build)
		end

		self.errMsg = nil
	end, {})
end
