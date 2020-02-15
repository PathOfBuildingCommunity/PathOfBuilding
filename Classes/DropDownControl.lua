-- Path of Building
--
-- Class: DropDown Control
-- Basic drop down control.
--
local ipairs = ipairs
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local DropDownClass = newClass("DropDownControl", "Control", "ControlHost", "TooltipHost", "SearchHost", function(self, anchor, x, y, width, height, list, selFunc, tooltipText)
	self.Control(anchor, x, y, width, height)
	self.ControlHost()
	self.TooltipHost(tooltipText)
	self.SearchHost(
			-- list to filter
			function()
				return self.list
			end,
			-- value mapping function
			function(listVal)
				return StripEscapes(type(listVal) == "table" and listVal.label or listVal)
			end
	)
	self.controls.scrollBar = new("ScrollBarControl", {"TOPRIGHT",self,"TOPRIGHT"}, -1, 0, 18, 0, (height - 4) * 4)
	self.controls.scrollBar.height = function()
		return self.dropHeight + 2
	end
	self.controls.scrollBar.shown = function()
		return self.dropped and self.controls.scrollBar.enabled
	end
	self.dropHeight = 0
	self.list = list or { }
	self.selIndex = 1
	self.selFunc = selFunc
end)

-- maps the actual dropdown row index (after eventual filtering) to the original (unfiltered) list index
function DropDownClass:DropIndexToListIndex(dropIndex)
	-- 1:1
	if not self:IsSearchActive() then
		return dropIndex
	end
	-- out of bounds
	if not dropIndex or dropIndex <= 0 or dropIndex > self:GetDropCount() then
		return nil
	end
	-- actual mapping
	for listIndex, info in ipairs(self.searchInfos) do
		if info and info.matches then
			dropIndex = dropIndex - 1
			if (dropIndex <= 0) then
				return listIndex
			end
		end
	end
end

-- maps the the original (unfiltered) list index to the actual dropdown row index (after eventual filtering)
function DropDownClass:ListIndexToDropIndex(listIndex, default)
	-- 1:1
	if not self:IsSearchActive() then
		return listIndex
	end
	-- out of bounds
	if not listIndex or listIndex <= 0 or listIndex > #self.list then
		return nil
	end
	-- actual mapping
	local dropIndex = 0
	for listIndexLoop, info in ipairs(self.searchInfos) do
		if info and info.matches then
			dropIndex = dropIndex + 1
			if (listIndex == listIndexLoop) then
				return dropIndex
			end
		end
	end
	-- given listIndex is currently filtered out
	return default
end

function DropDownClass:GetDropCount()
	if self:IsSearchActive() then
		return self:GetMatchCount()
	else
		return #self.list
	end
end

function DropDownClass:DrawSearchHighlights(label, searchInfo, x, y, width, height)
	if searchInfo and searchInfo.matches then
		local startX = 0
		local endX = 0
		local last = 0
		SetDrawColor(1, 1, 0, 0.2)
		for _, range in ipairs(searchInfo.ranges) do
			if range.from - last - 1 > 0 then
				startX = DrawStringWidth(height, "VAR", label:sub(last + 1, range.from - 1)) + x + endX
			else
				startX = endX
			end
			endX = DrawStringWidth(height, "VAR", label:sub(range.from, range.to)) + x + startX
			last = range.to

			DrawImage(nil, startX, y, endX - startX, height)
		end
		SetDrawColor(1, 1, 1)
	end
end


function DropDownClass:SelByValue(value, key)
	for index, listVal in ipairs(self.list) do
		if type(listVal) == "table" then
			if listVal[key] == value then
				self.selIndex = index
				return
			end
		else
			if listVal == value then
				self.selIndex = index
				return
			end
		end
	end
end

function DropDownClass:GetSelValue(key)
	return self.list[self.selIndex][key]
end

function DropDownClass:SetSel(newSel)
	newSel = m_max(1, m_min(self:GetDropCount(), newSel))
	newSel = self:DropIndexToListIndex(newSel)
	if newSel and newSel ~= self.selIndex then
		self.selIndex = newSel
		if self.selFunc then
			self.selFunc(newSel, self.list[newSel])
		end
	end
end

function DropDownClass:ScrollSelIntoView()
	local width, height = self:GetSize()
	local scrollBar = self.controls.scrollBar
	scrollBar:SetContentDimension((height - 4) * self:GetDropCount(), self.dropHeight)
	scrollBar:ScrollIntoView((self:ListIndexToDropIndex(self.selIndex, 1) - 2) * (height - 4), 3 * (height - 4))
end

function DropDownClass:IsMouseOver()
	if not self:IsShown() then
		return false
	end
	if self:GetMouseOverControl() then
		return true
	end
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local cursorX, cursorY = GetCursorPos()
	local dropExtra = self.dropped and self.dropHeight + 2 or 0
	local mOver
	if self.dropUp then
		mOver = cursorX >= x and cursorY >= y - dropExtra and cursorX < x + width and cursorY < y + height
	else
		mOver = cursorX >= x and cursorY >= y and cursorX < x + width and cursorY < y + height + dropExtra
	end
	local mOverComp
	if mOver then
		if cursorY >= y and cursorY < y + height then
			mOverComp = "BODY"
		else
			mOverComp = "DROP"
		end
	end
	return mOver, mOverComp
end

function DropDownClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local enabled = self:IsEnabled()
	local mOver, mOverComp = self:IsMouseOver()
	local scrollBar = self.controls.scrollBar
	local lineHeight = height - 4
	self.dropHeight = lineHeight * m_min(#self.list, 30)
	scrollBar.y = height + 1
	if y + height + self.dropHeight + 4 <= viewPort.y + viewPort.height then
		-- Drop fits below body
		self.dropUp = false
	else
		local linesAbove = m_floor((y - viewPort.y - 4) / lineHeight)
		local linesBelow = m_floor((viewPort.y + viewPort.height - y - height - 4) / lineHeight)
		if linesAbove > linesBelow then
			-- There's more room above the body than below
			self.dropUp = true
			if y - viewPort.y < self.dropHeight + 4 then
				-- Still doesn't fit, so clip it
				self.dropHeight = lineHeight * linesAbove
			end
			scrollBar.y = -self.dropHeight - 3
		else
			-- Doesn't fit below body, so clip it
			self.dropUp = false
			self.dropHeight = lineHeight * linesBelow
		end
	end

	if self:IsSearchActive() and not self.dropped then
		self:ResetSearch()
	end

	local dropExtra = self.dropHeight + 4
	scrollBar:SetContentDimension(lineHeight * self:GetDropCount(), self.dropHeight)
	local dropY = self.dropUp and y - dropExtra or y + height
	if not enabled then
		SetDrawColor(0.33, 0.33, 0.33)
	elseif mOver or self.dropped then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	DrawImage(nil, x, y, width, height)
	if self.dropped then
		SetDrawLayer(nil, 5)
		DrawImage(nil, x, dropY, width, dropExtra)
		SetDrawLayer(nil, 0)
	end
	if not enabled then
		SetDrawColor(0, 0, 0)
	elseif self.dropped then
		SetDrawColor(0.5, 0.5, 0.5)
	elseif mOver then
		SetDrawColor(0.33, 0.33, 0.33)
	else
		SetDrawColor(0, 0, 0)
	end
	DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
	if not enabled then
		SetDrawColor(0.33, 0.33, 0.33)
	elseif mOver or self.dropped then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	main:DrawArrow(x + width - height/2, y + height/2, height/2, height/2, "DOWN")
	if self.dropped then
		SetDrawLayer(nil, 5)
		SetDrawColor(0, 0, 0)
		DrawImage(nil, x + 1, dropY + 1, width - 2, dropExtra - 2)
		SetDrawLayer(nil, 0)
	end
	if self.otherDragSource then
		SetDrawColor(0, 1, 0, 0.25)
		DrawImage(nil, x, y, width, height)
	end
	if enabled then
		if (mOver or self.dropped) and mOverComp ~= "DROP" then
			SetDrawLayer(nil, 100)
			self:DrawTooltip(
				x, y - (self.dropped and self.dropUp and dropExtra or 0), 
				width, height + (self.dropped and dropExtra or 0), 
				viewPort,
				mOver and "BODY" or "OUT", self.selIndex, self.list[self.selIndex])
			SetDrawLayer(nil, 0)
		end
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.66, 0.66, 0.66)
	end
	local selLabel = self.list[self.selIndex]
	if type(selLabel) == "table" then
		selLabel = selLabel.label
	end
	if self:IsSearchActive() then
		selLabel = "Search: " .. self:GetSearchTermPretty()
	end
	SetViewport(x + 2, y + 2, width - height, lineHeight)
	DrawString(0, 0, "LEFT", lineHeight, "VAR", selLabel or "")
	SetViewport()
	if self.dropped then
		SetDrawLayer(nil, 5)
		self:DrawControls(viewPort)
		local cursorX, cursorY = GetCursorPos()
		self.hoverSelDrop = mOver and not scrollBar:IsMouseOver() and math.floor((cursorY - dropY + scrollBar.offset) / lineHeight) + 1
		self.hoverSel = self:DropIndexToListIndex(self.hoverSelDrop)
		if self.hoverSel and not self.list[self.hoverSel] then
			self.hoverSel = nil
		end
		if self.hoverSel then
			SetDrawLayer(nil, 100)	
			self:DrawTooltip(
				x, dropY + 2 + (self.hoverSelDrop - 1) * lineHeight - scrollBar.offset,
				width, lineHeight, 
				viewPort,
				"HOVER", self.hoverSel, self.list[self.hoverSel])
			SetDrawLayer(nil, 5)
		end
		SetViewport(x + 2, dropY + 2, scrollBar.enabled and width - 22 or width - 4, self.dropHeight)
		local dropIndex = 0
		for index, listVal in ipairs(self.list) do
			local searchInfo = self.searchInfos[index]
			if not self:IsSearchActive() or searchInfo.matches then
				dropIndex = dropIndex + 1
				local y = (dropIndex - 1) * lineHeight - scrollBar.offset
				if index == self.hoverSel then
					SetDrawColor(0.5, 0.4, 0.3)
					DrawImage(nil, 0, y, width - 4, lineHeight)
				end
				if index == self.hoverSel or index == self.selIndex then
					SetDrawColor(1, 1, 1)
				else
					SetDrawColor(0.66, 0.66, 0.66)
				end
				local label = StripEscapes(type(listVal) == "table" and listVal.label or listVal)
				DrawString(0, y, "LEFT", lineHeight, "VAR", label)
				self:DrawSearchHighlights(label, searchInfo, 0, y, width - 4, lineHeight)
			end
		end
		SetViewport()
		SetDrawColor(1, 1, 1)
		SetDrawLayer(nil, 0)
	end
end

function DropDownClass:OnChar(key)
	if not self:IsShown() or not self:IsEnabled() or not self.dropped then
		return
	end
	return self:OnSearchChar(key)
end

function DropDownClass:OnKeyDown(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if self.dropped then
		if self:OnSearchKeyDown(key) then
			return self
		end
	end
	local mOverControl = self:GetMouseOverControl()
	if mOverControl and mOverControl.OnKeyDown then
		self.selControl = mOverControl
		return mOverControl:OnKeyDown(key) and self
	else
		self.selControl = nil
	end
	if key == "LEFTBUTTON" or key == "RIGHTBUTTON" then
		local mOver, mOverComp = self:IsMouseOver()
		if not mOver or (self.dropped and mOverComp == "BODY") then
			self.dropped = false
			return self
		end
		if not self.dropped then
			self.dropped = true
			self:ScrollSelIntoView()
		end
	elseif key == "ESCAPE" then
		self.dropped = false
	end
	return self.dropped and self
end

function DropDownClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if self.selControl then
		local newSel = self.selControl:OnKeyUp(key)
		if newSel then
			return self
		else
			self.selControl = nil
		end
		return self
	end
	if key == "LEFTBUTTON" or key == "RIGHTBUTTON" then
		local mOver, mOverComp = self:IsMouseOver()
		if not mOver then
			self.dropped = false
		elseif mOverComp == "DROP" then
			local x, y = self:GetPos()
			local width, height = self:GetSize()
			local cursorX, cursorY = GetCursorPos()
			local dropExtra = self.dropHeight + 4
			local dropY = self.dropUp and y - dropExtra or y + height
			self:SetSel(math.floor((cursorY - dropY + self.controls.scrollBar.offset) / (height - 4)) + 1)
			self.dropped = false
		end
	elseif key == "WHEELDOWN" then
		if self.dropped and self.controls.scrollBar.enabled then
			self.controls.scrollBar:Scroll(1)
		else
			self:SetSel(self:ListIndexToDropIndex(self.selIndex, 0) + 1)
		end
		return self
	elseif key == "DOWN" then
		self:SetSel(self:ListIndexToDropIndex(self.selIndex, 0) + 1)
		self:ScrollSelIntoView()
		return self
	elseif key == "WHEELUP" then
		if self.dropped and self.controls.scrollBar.enabled then
			self.controls.scrollBar:Scroll(-1)
		else
			self:SetSel(self:ListIndexToDropIndex(self.selIndex, 0) - 1)
		end
		return self
	elseif key == "UP" then
		self:SetSel(self:ListIndexToDropIndex(self.selIndex, 0) - 1)
		self:ScrollSelIntoView()
		return self
	end
	return self.dropped and self
end
