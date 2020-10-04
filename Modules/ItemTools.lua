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
		return line:gsub("(%d+%.%d*)", function(num)
			local numVal = (m_floor(tonumber(num) * valueScalar * 10 + 0.001) / 10)
			return tostring(numVal)
		end)
		:gsub("(%d+)([^%.])", function(num, suffix)
			local numVal = m_floor(num * valueScalar + 0.001)
			return tostring(numVal)..suffix
		end)
	end
	return line
end

-- Get the min and max of a mod line
function itemLib.getLineRangeMinMax(line, range, valueScalar)
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

-- Clean item text by removing or replacing unsupported or redundant characters or sequences
function itemLib.sanitiseItemText(text)
	-- Something something unicode support something grumble
	return text:gsub("^%s+",""):gsub("%s+$",""):gsub("\r\n","\n"):gsub("%b<>",""):gsub("–","-"):gsub("\226\128\147","-"):gsub("\226\136\146","-"):gsub("ö","o"):gsub("\195\182","o"):gsub("[\128-\255]","?")
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
		colorCode = (modLine.crafted and colorCodes.CRAFTED) or (modLine.custom and colorCodes.CUSTOM) or (modLine.fractured and colorCodes.FRACTURED) or colorCodes.MAGIC
	end
	return colorCode..line
end
