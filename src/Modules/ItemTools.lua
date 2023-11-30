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
local CC = UI.CC

itemLib = { }

-- Info table for all types of item influence
itemLib.influenceInfo = {
	{ key = "shaper", display = "Shaper", color = CC.ITEM_SHAPER },
	{ key = "elder", display = "Elder", color = CC.ITEM_ELDER },
	{ key = "adjudicator", display = "Warlord", color = CC.ITEM_ADJUDICATOR },
	{ key = "basilisk", display = "Hunter", color = CC.ITEM_BASILISK },
	{ key = "crusader", display = "Crusader", color = CC.ITEM_CRUSADER },
	{ key = "eyrie", display = "Redeemer", color = CC.ITEM_EYRIE },
	{ key = "cleansing", display = "Searing Exarch", color = CC.ITEM_CLEANSING },
	{ key = "tangle", display = "Eater of Worlds", color = CC.ITEM_TANGLE },
}

-- Apply a value scalar to the first n of any numbers present
function itemLib.applyValueScalar(line, valueScalar, numbers, precision)
	if valueScalar and type(valueScalar) == "number" and valueScalar ~= 1 then
		if precision then
			return line:gsub("(%d+%.?%d*)", function(num)
				local power = 10 ^ precision
				local numVal = m_floor(tonumber(num) * valueScalar * power) / power
				return tostring(numVal)
			end, numbers)
		else
			return line:gsub("(%d+)([^%.])", function(num, suffix)
				local numVal = m_floor(num * valueScalar + 0.001)
				return tostring(numVal)..suffix
			end, numbers)
		end
	end
	return line
end

local antonyms = {
	["increased"] = "reduced",
	["reduced"] = "increased",
	["more"] = "less",
	["less"] = "more",
}

local function antonymFunc(num, word)
	local antonym = antonyms[word]
	return antonym and (num.." "..antonym) or ("-"..num.." "..word)
end

-- Apply range value (0 to 1) to a modifier that has a range: "(x-x)" or "(x-x) to (x-x)"
function itemLib.applyRange(line, range, valueScalar)
	local precisionSame = true
	-- Create a line with ranges removed to check if the mod is a high precision mod.
	local testLine = not line:find("-", 1, true) and line or
		line:gsub("(%+?)%((%-?%d+%.?%d*)%-(%-?%d+%.?%d*)%)",
		function(plus, min, max)
			min = tonumber(min)
			local maxPrecision = min + range * (tonumber(max) - min)
			local minPrecision = m_floor(maxPrecision + 0.5)
			if minPrecision ~= maxPrecision then
				precisionSame = false
			end
			return (minPrecision < 0 and "" or plus) .. tostring(minPrecision)
		end)
		:gsub("%-(%d+%%) (%a+)", antonymFunc)

	if precisionSame and (not valueScalar or valueScalar == 1) then
		return testLine
	end

	local precision = nil
	local modList, extra = modLib.parseMod(testLine)
	if modList and not extra then
		for _, mod in pairs(modList) do
			local subMod = mod
			if type(mod.value) == "table" and mod.value.mod then
				subMod = mod.value.mod
			end
			if type(subMod.value) == "number" and data.highPrecisionMods[subMod.name] and data.highPrecisionMods[subMod.name][subMod.type] then
				precision = data.highPrecisionMods[subMod.name][subMod.type]
			end
		end
	end
	if not precision and line:match("(%d+%.%d*)") then
		precision = data.defaultHighPrecision
	end

	local numbers = 0
	line = line:gsub("(%+?)%((%-?%d+%.?%d*)%-(%-?%d+%.?%d*)%)",
		function(plus, min, max)
			numbers = numbers + 1
			local power = 10 ^ (precision or 0)
			local numVal = m_floor((tonumber(min) + range * (tonumber(max) - tonumber(min))) * power + 0.5) / power
			return (numVal < 0 and "" or plus) .. tostring(numVal)
		end)
		:gsub("%-(%d+%%) (%a+)", antonymFunc)

	if numbers == 0 and line:match("(%d+%.?%d*)%%? ") then --If a mod contains x or x% and is not already a ranged value, then only the first number will be scalable as any following numbers will always be conditions or unscalable values.
		numbers = 1
	end

	return itemLib.applyValueScalar(line, valueScalar, numbers, precision)
end

--- Clean item text by removing or replacing unsupported or redundant characters or sequences
---@param text string
---@return string
function itemLib.sanitiseItemText(text)
	-- Something something unicode support something grumble
	-- Only do these replacements if a char from 128-255 or '<' is found first
	return text:find("[\128-\255<]") and text
		:gsub("%b<>", "")
		:gsub("\226\128\144", "-") -- U+2010 HYPHEN
		:gsub("\226\128\145", "-") -- U+2011 NON-BREAKING HYPHEN
		:gsub("\226\128\146", "-") -- U+2012 FIGURE DASH
		:gsub("\226\128\147", "-") -- U+2013 EN DASH
		:gsub("\226\128\148", "-") -- U+2014 EM DASH
		:gsub("\226\128\149", "-") -- U+2015 HORIZONTAL BAR
		:gsub("\226\136\146", "-") -- U+2212 MINUS SIGN
		:gsub("\195\164", "a") -- U+00E4 LATIN SMALL LETTER A WITH DIAERESIS
		:gsub("\195\182", "o") -- U+00F6 LATIN SMALL LETTER O WITH DIAERESIS
		-- single-byte: Windows-1252 and similar
		:gsub("\150", "-") -- U+2013 EN DASH
		:gsub("\151", "-") -- U+2014 EM DASH
		:gsub("\228", "a") -- U+00E4 LATIN SMALL LETTER A WITH DIAERESIS
		:gsub("\246", "o") -- U+00F6 LATIN SMALL LETTER O WITH DIAERESIS
		-- unsupported
		:gsub("[\128-\255]", "?")
		or text
end

function itemLib.formatModLine(modLine, dbMode)
	local line = (not dbMode and modLine.range and itemLib.applyRange(modLine.line, modLine.range, modLine.valueScalar)) or modLine.line
	if line:match("^%+?0%%? ") or (line:match(" %+?0%%? ") and not line:match("0 to [1-9]")) or line:match(" 0%-0 ") or line:match(" 0 to 0 ") then -- Hack to hide 0-value modifiers
		return
	end
	local colorCode
	if modLine.extra then
		colorCode = CC.ITEM_UNSUPPORTED
		if launch.devModeAlt then
			line = line..CC.SPECIAL.."   '"..modLine.extra.."'"
		end
	else
		colorCode = (modLine.crafted and CC.ITEM_CRAFTED) or (modLine.scourge and CC.ITEM_SCOURGE) or (modLine.custom and CC.ITEM_CUSTOM) or (modLine.fractured and CC.ITEM_FRACTURED) or (modLine.crucible and CC.ITEM_CRUCIBLE) or CC.ITEM_MOD
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
		itemLib.wiki.triggered = true
	end,
	matchesKey = function(key)
		return key == itemLib.wiki.key
	end,
	triggered = false
}