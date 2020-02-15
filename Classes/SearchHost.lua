-- Path of Building
--
-- Class: Search Host
-- Search host
--

local SearchHostClass = newClass("SearchHost", function(self, listAccessor, valueAccessor)
	self.searchListAccessor = listAccessor
	self.valueAccessor = valueAccessor
	self.searchTerm = ""
	self.searchInfos = {}
end)

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
	self.searchTerm = ""
	self.matchCount = 0
	self.searchInfos = {}
end

function SearchHostClass:GetSearchTermPretty()
	local color = self:IsSearchActive() and self.matchCount > 0 and "^xFFFFFF" or "^xFF0000"
	return color .. self.searchTerm
end