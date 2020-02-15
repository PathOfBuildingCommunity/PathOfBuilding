search = { }

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

local function match(searchWords, entry, valueAccessor)
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

function search.match(searchTerm, list, valueAccessor)
	if not searchTerm or searchTerm == "" or not list then
		return {}
	end

	local searchInfos = {}
	local searchPatterns = wordsToCaselessPatterns(splitWords(searchTerm))
	for idx, entry in ipairs(list) do
		searchInfos[idx] = match(searchPatterns, entry, valueAccessor)
	end
	return searchInfos
end