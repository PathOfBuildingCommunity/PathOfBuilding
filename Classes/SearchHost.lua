-- Path of Building
--
-- Class: Search Host
-- Search host
--

-- always show search popup if list size to filter > threshold
-- this can be removed once users know that there is a search feature
local alwaysShowThreshold = 10

local SearchHostClass = newClass("SearchHost", function(self, listAccessor, valueAccessor)
	self.searchListAccessor = listAccessor
	self.valueAccessor = valueAccessor
	self.searchTerm = ""
	self.searchInfos = {}
end)

function SearchHostClass:GetSearchPos(viewPort, dir)
	local x, y = self:GetPos()
	local width, height = self:GetSearchSize()
	if (dir == "BOTTOM") then
		return x, math.min(viewPort.height + viewPort.y, y + height + 1)
	else
		return x, math.max(viewPort.y, y - height - 1)
	end
end

function SearchHostClass:GetSearchSize()
	local height = self:GetProperty("height")
	return DrawStringWidth(height - 4, "VAR", self:GetSearchText()) + 4, height
end

function SearchHostClass:IsSearchActive()
	return self.searchTerm and self.searchTerm ~= ""
end

function SearchHostClass:OnSearchChar(char)
	if char:match("%s") then
		-- dont allow space char if search is empty or last character is already a space char
		if self.searchTerm == "" or self.searchTerm:sub(-1):match("%s") then
			return self
		end
	end
	if not char:match("%c") then
		self.searchTerm = self.searchTerm .. char
		self:UpdateSearch()
	end
	return self
end

function SearchHostClass:OnSearchKeyDown(key)
	if self:IsSearchActive() and key == "ESCAPE" then
		self:ResetSearch()
		return self
	elseif self:IsSearchActive() and key == "BACK" then
		self.searchTerm = self.searchTerm:sub(1, -2)
		self:UpdateSearch()
		return self
	end
end

function SearchHostClass:UpdateMatchCount()
		local matchCount = 0
		for _, info in ipairs(self.searchInfos) do
			if (info and info.matches) then
				matchCount = matchCount + 1
			end
		end
		self.matchCount = matchCount
end

function SearchHostClass:GetMatchCount()
	return self.matchCount
end

function SearchHostClass:UpdateSearch()
	if self.searchListAccessor then
		self.searchInfos = search.match(self.searchTerm, self.searchListAccessor(), self.valueAccessor)
		self:UpdateMatchCount()
	end
end

function SearchHostClass:ResetSearch()
	if self:IsSearchActive() then
		self.searchTerm = ""
		self.matchCount = 0
		self.searchInfos = {}
	end
end

function SearchHostClass:GetSearchText()
	local color = self:IsSearchActive() and self.matchCount > 0 and "^xFFFFFF" or "^xFF0000"
	return "Search: " .. color .. self.searchTerm
end

function SearchHostClass:IsShowSearch()
	if self:IsSearchActive() then
		return true
	end
	local listSize = self.searchListAccessor and self.searchListAccessor() and #self.searchListAccessor() or 0
	return listSize > alwaysShowThreshold
end

function SearchHostClass:DrawSearch(viewPort, dir)
	if not self:IsShowSearch() then
		return
	end

	local text = self:GetSearchText()
	local width, height = self:GetSearchSize()
	local x, y = self:GetSearchPos(viewPort, dir)

	-- background
	SetDrawLayer(nil, 95)
	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(nil, x, y, width + 5, height)
	SetDrawColor(0.1, 0.1, 0.1)
	DrawImage(nil, x + 1, y + 1, width + 3, height - 2)

	-- text
	SetDrawLayer(nil, 100)
	SetDrawColor(0.75, 0.75, 0.75)
	DrawString(x + 2, y + 2, "LEFT", height - 4, "VAR", text)

	-- reset
	SetDrawColor(1, 1, 1)
	SetDrawLayer(nil, 0)
end