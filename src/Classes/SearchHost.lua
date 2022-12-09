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

local function splitWords(s)
	local words = {}
	for word in s:gmatch("%S+") do
		table.insert(words, word)
	end
	return words
end

local function letterToCaselessPattern(c)
	return string.format("[%s%s]", string.lower(c), string.upper(c))
end

local function wordsToCaselessPatterns(words)
	local patterns = {}
	for idx = 1, #words do
		-- escape all non alphanumeric chars
		patterns[idx] = string.gsub(words[idx], "%W", "%%%1")
		-- make pattern case insensitive
		patterns[idx] = string.gsub(patterns[idx], "%a", letterToCaselessPattern)
	end
	return patterns
end

local function matchWords(searchWords, entry, valueAccessor)
	local value = valueAccessor and valueAccessor(entry) or entry
	local searchInfo = { ranges = {}, matches = true }
	local lastMatchEnd = 0
	for _, word in ipairs(searchWords) do
		local from, to = string.find(value, word, lastMatchEnd + 1)
		if (from) then
			local range = { from = from, to = to }
			table.insert(searchInfo.ranges, range)
			lastMatchEnd = to
		else
			-- at least one search word did not match at least once (respecting order)
			searchInfo.matches = false
		end
	end
	return searchInfo
end

local function matchTerm(searchTerm, list, valueAccessor)
	if not searchTerm or searchTerm == "" or not list then
		return {}
	end

	local searchInfos = {}
	local searchPatterns = wordsToCaselessPatterns(splitWords(searchTerm))
	for idx, entry in ipairs(list) do
		searchInfos[idx] = matchWords(searchPatterns, entry, valueAccessor)
	end
	return searchInfos
end

function SearchHostClass:IsSearchActive()
	return self.searchTerm and self.searchTerm ~= ""
end

function SearchHostClass:OnSearchChar(char)
	if char:match("%s") then
		-- don't allow space char if search is empty or last character is already a space char
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
		self.searchInfos = matchTerm(self.searchTerm, self.searchListAccessor(), self.valueAccessor)
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