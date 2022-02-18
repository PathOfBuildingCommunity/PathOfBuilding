-- Path of Building
--
-- Module: Item Tools
-- Various functions for dealing with items.
--
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

itemLib = { }

-- Info table for all types of item influence
itemLib.influenceInfo = {
	{ key="shaper", display="Shaper", color=colorCodes.SHAPER },
	{ key="elder", display="Elder", color=colorCodes.ELDER },
	{ key="adjudicator", display="Warlord", color=colorCodes.ADJUDICATOR },
	{ key="basilisk", display="Hunter", color=colorCodes.BASILISK },
	{ key="crusader", display="Crusader", color=colorCodes.CRUSADER },
	{ key="eyrie", display="Redeemer", color=colorCodes.EYRIE },
}

-- Apply a value scalar to any numbers present
function itemLib.applyValueScalar(line, valueScalar)
	if valueScalar and type(valueScalar) == "number" and valueScalar ~= 1 then
		if line:match("(%d+%.%d*)") then
			return line:gsub("(%d+%.%d*)", function(num)
				local numVal = (m_floor(tonumber(num) * valueScalar * 100 + 0.001) / 100)
				return tostring(numVal)
			end)
		else
			return line:gsub("(%d+)([^%.])", function(num, suffix)
				local numVal = m_floor(num * valueScalar + 0.001)
				return tostring(numVal)..suffix
			end)
		end
	end
	return line
end

-- Get the min and max of a mod line
function itemLib.getLineRangeMinMax(line)
	local rangeMin, rangeMax
	line:gsub("%((%d+)%-(%d+) to (%d+)%-(%d+)%)", "(%1-%2) to (%3-%4)")
		:gsub("(%+?)%((%-?%d+) to (%d+)%)", "%1(%2-%3)")
		:gsub("(%+?)%((%-?%d+)%-(%d+)%)", 
		function(plus, min, max)
			rangeMin = min
			rangeMax = max
			-- Don't need to return anything here
			return ""
		end)
		:gsub("%((%d+%.?%d*)%-(%d+%.?%d*)%)",
		function(min, max) 
			rangeMin = min
			rangeMax = max
			return "" 
		end)
	-- may be returning nil, nil due to not being a range
	-- will be strings if successful
	return rangeMin, rangeMax
end

-- Apply range value (0 to 1) to a modifier that has a range: (x to x) or (x-x to x-x)
function itemLib.applyRange(line, range, valueScalar)
	line = line:gsub("%((%d+)%-(%d+) to (%d+)%-(%d+)%)", "(%1-%2) to (%3-%4)")
		:gsub("(%+?)%((%-?%d+) to (%d+)%)", "%1(%2-%3)")
		:gsub("(%+?)%((%-?%d+)%-(%d+)%)",
		function(plus, min, max)
			local numVal = m_floor(tonumber(min) + range * (tonumber(max) - tonumber(min)) + 0.5)
			if numVal < 0 then
				if plus == "+" then
					plus = ""
				end
			end
			return plus .. tostring(numVal)
		end)
		:gsub("%((%d+%.?%d*)%-(%d+%.?%d*)%)",
		function(min, max)
			local numVal = m_floor((tonumber(min) + range * (tonumber(max) - tonumber(min))) * 10 + 0.5) / 10
			return tostring(numVal)
		end)
		:gsub("%-(%d+%%) increased", function(num) return num.." reduced" end)
	return itemLib.applyValueScalar(line, valueScalar)
end

--- Clean item text by removing or replacing unsupported or redundant characters or sequences
---@param text string
---@return string
function itemLib.sanitiseItemText(text)
	-- Something something unicode support something grumble
	local replacements = {
		{ "^%s+", "" }, { "%s+$", "" }, { "\r\n", "\n" }, { "%b<>", "" },
		-- UTF-8
		{ "\226\128\144", "-" }, -- U+2010 HYPHEN
		{ "\226\128\145", "-" }, -- U+2011 NON-BREAKING HYPHEN
		{ "\226\128\146", "-" }, -- U+2012 FIGURE DASH
		{ "\226\128\147", "-" }, -- U+2013 EN DASH
		{ "\226\128\148", "-" }, -- U+2014 EM DASH
		{ "\226\128\149", "-" }, -- U+2015 HORIZONTAL BAR
		{ "\226\136\146", "-" }, -- U+2212 MINUS SIGN
		{ "\195\164", "a" }, -- U+00E4 LATIN SMALL LETTER A WITH DIAERESIS
		{ "\195\182", "o" }, -- U+00F6 LATIN SMALL LETTER O WITH DIAERESIS
		-- single-byte: Windows-1252 and similar
		{ "\150", "-" }, -- U+2013 EN DASH
		{ "\151", "-" }, -- U+2014 EM DASH
		{ "\228", "a" }, -- U+00E4 LATIN SMALL LETTER A WITH DIAERESIS
		{ "\246", "o" }, -- U+00F6 LATIN SMALL LETTER O WITH DIAERESIS
		-- unsupported
		{ "[\128-\255]", "?" },
	}
	for _, r in ipairs(replacements) do
		text = text:gsub(r[1], r[2])
	end
	return text
end

function itemLib.formatModLine(modLine, dbMode)
	local line = (not dbMode and modLine.range and itemLib.applyRange(modLine.line, modLine.range, modLine.valueScalar)) or modLine.line
	if line:match("^%+?0%%? ") or (line:match(" %+?0%%? ") and not line:match("0 to [1-9]")) or line:match(" 0%-0 ") or line:match(" 0 to 0 ") then -- Hack to hide 0-value modifiers
		return
	end
	local colorCode
	if modLine.extra then
		colorCode = colorCodes.UNSUPPORTED
		if launch.devModeAlt then
			line = line .. "   ^1'" .. modLine.extra .. "'"
		end
	else
		colorCode = (modLine.crafted and colorCodes.CRAFTED) or (modLine.scourge and colorCodes.SCOURGE) or (modLine.custom and colorCodes.CUSTOM) or (modLine.fractured and colorCodes.FRACTURED) or colorCodes.MAGIC
	end
	return colorCode..line
end

itemLib.wiki = {
	key = "F1",
	openGem = function(gemData)
		local name = gemData.name;

		if gemData.tags.support then
			name = name .. " Support"
		end

		itemLib.wiki.open(name)
	end,
	openItem = function(item)
		local name = item.rarity == "UNIQUE" and item.title or item.baseName

		itemLib.wiki.open(name)
	end,
	open = function(name)
		local route = string.gsub(name, " ", "_")

		OpenURL("https://www.poewiki.net/wiki/" .. route)
	end,
	matchesKey = function(key)
		return key == itemLib.wiki.key
	end
}