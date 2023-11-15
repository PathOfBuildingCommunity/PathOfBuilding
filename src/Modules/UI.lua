-- Path of Building
--
-- Module: UI
-- User interface utilities nad theme management
--

local ipairs = ipairs
local t_insert = table.insert

UI = { }

--- Default color theme
--- @type table<string, string> 
local CC = { name = "Classic" }

-- Text
CC.TEXT_PRIMARY = "^7"
CC.TEXT_SECONDARY = "^8"
CC.TEXT_TIP = "^x80A080"
CC.TEXT_URL = "^x4040FF"
CC.TEXT_ACCENT1 = "^x5CF0BB"
CC.TEXT_ACCENT2 = "^xFF9922"
CC.TEXT_ACCENT3 = "^x40AA40"
CC.TEXT_DISABLED = "^9"
CC.TEXT_REMINDER = "^xA0A080"

-- Miscellaneous
CC.ERROR = "^1"
CC.WARNING = "^xFF9922"
CC.OK = "^x33FF77"
CC.SPECIAL = "^1"

-- tree tab bg: 0.05, 0.05, 0.05
CC.BACKGROUND_0 = "^x000000" -- 0.0
CC.BACKGROUND_1 = "^x1A1A1A"
CC.BACKGROUND_2 = "^x040709"
CC.HEADER = "^x999999"

CC.SECTION_BORDER = "^xD9D9D9" -- 0.85
CC.SECTION_BACKGROUND = "^x191919" -- 0.1
CC.SECTION_HEADER_BACKGROUND = "^x333333" -- 0.2
CC.CONTROL_BORDER = "^x808080" -- 0.5
CC.CONTROL_BORDER_INACTIVE = "^x555555" -- 0.33
CC.CONTROL_BORDER_HOVER = "^xFFFFFF" -- 0.1
CC.CONTROL_BACKGROUND = "^x000000" -- 0.0
CC.CONTROL_BACKGROUND_INACTIVE = "^x000000" -- 0.0
CC.CONTROL_BACKGROUND_HOVER = "^x555555" -- 0.33
CC.CONTROL_BACKGROUND_IMAGE_INACTIVE = "^x555555" -- 0.33
CC.CONTROL_TEXT = "^7" -- 1.0
CC.CONTROL_TEXT_INACTIVE = "^x555555" -- 0.33
CC.CONTROL_TEXT_HOVER = "^xFFFFFF" -- 1.0
CC.CONTROL_TEXT_MUTED = "^xAAAAAA" -- 0.66
CC.CONTROL_ITEM = "^x808080" -- 0.5
CC.CONTROL_ITEM_INACTIVE = "^x555555" -- 0.33
CC.CONTROL_ITEM_HOVER = "^xFFFFFF" -- 1.0
CC.CONTROL_ITEM_ACTIVE = "^xBFBFBF" -- 0.75
CC.CONTROL_RECEIVE_DRAG_BACKGROUND = "^xx00FF0040" -- 0.0 1.0 0.0 0.25
CC.CONTROL_SEARCH_BACKGROUND = "^xxFFFF0033"
CC.CONTROL_SEARCH_TEXT = "^xFFFFFF"
CC.TOOLTIP_BORDER = "^x7f4c00" -- 0.5 0.3 0.0
CC.TOOLTIP_BACKGROUND = "^xx000000d8" -- 0.0 0.0 0.0 0.85
CC.TOOLTIP_TEXT = "^xFFFFFF" -- 1.0
CC.TOOLTIP_SECTION_BORDER = "^x55AA55"
CC.TOOLTIP_SECTION_BORDER_HOVER = "^x40FF40"
CC.TOOLTIP_TREE_BORDER = "^xFFFFFF"
CC.TOOLTIP_TREE_ITEM = "^xFF0000"
CC.TOOLTIP_RADIUS_BORDER = "^xFFFFFF"
CC.TOOLTIP_RADIUS_ITEM = "^xx80FF8055" -- 0.5 1 0.5 0.33
--CC.CALC_SECTION_BORDER = "^x7f4c00" -- 0.5 0.3 0.0
CC.CALC_SECTION_BORDER_SKILL = nil -- CC.ITEM_RARITY_NORMAL
CC.CALC_SECTION_BORDER_ATTRIBUTES = nil -- CC.ITEM_RARITY_NORMAL
CC.CALC_SECTION_BORDER_OFFENCE = nil -- CC.BUILD_OFFENCE
CC.CALC_SECTION_BORDER_DEFENCE = nil -- CC.BUILD_DEFENCE
CC.CALC_SECTION_BACKGROUND = "^x191919" -- 0.1
--CC.CALC_SECTION_TEXT = "^xFFFFFF" -- 1.0
CC.CALC_SECTION_HEADER_BACKGROUND = "^x000000"
CC.CALC_SECTION_ROW_BACKGROUND = "^x000000"

--Item
CC.ITEM_RARITY_NORMAL = "^xC8C8C8"
CC.ITEM_RARITY_MAGIC = "^x8888FF"
CC.ITEM_RARITY_RARE = "^xFFFF77"
CC.ITEM_RARITY_UNIQUE = "^xAF6025"
CC.ITEM_RARITY_RELIC = "^x60C060"

CC.ITEM_TEXT = "^x7F7F7F"
CC.ITEM_MOD = "^x8888FF"
CC.ITEM_UNSUPPORTED = "^xF05050"
CC.ITEM_GEM = "^x1AA29B"
CC.ITEM_GEM_RED = "^xE05030"
CC.ITEM_GEM_GREEN = "^x70FF70"
CC.ITEM_GEM_BLUE = "^x7070FF"
CC.ITEM_GEM_WHITE = "^xC8C8C8"
CC.ITEM_ABYSSAL = "^xB0B0B0"
CC.ITEM_PROPHECY = "^xB54BFF"
CC.ITEM_CURRENCY = "^xAA9E82"
CC.ITEM_CRAFTED = "^xB8DAF1"
CC.ITEM_CUSTOM = "^x5CF0BB"
CC.ITEM_VARIANT = "^xFFFF30"
CC.ITEM_SOURCE = "^x88FFFF"
CC.ITEM_LEAGUE = "^xFF5555"
CC.ITEM_FRACTURED = "^xA29160"
CC.ITEM_CRUCIBLE = "^xFF00FF"
CC.ITEM_CORRUPTED = "^xFF0000"
CC.ITEM_SHAPER = "^x55BBFF"
CC.ITEM_ELDER = "^xAA77CC"
CC.ITEM_ADJUDICATOR = "^xE9F831"
CC.ITEM_BASILISK = "^x00CB3A"
CC.ITEM_CRUSADER = "^x2946FC"
CC.ITEM_EYRIE = "^xAAB7B8"
CC.ITEM_CLEANSING = "^xF24141"
CC.ITEM_TANGLE = "^x038C8C"
CC.ITEM_SCOURGE = "^xFF6E25"

CC.CLASS_SCION = "^xFFF0F0"
CC.CLASS_MARAUDER = "^xE05030"
CC.CLASS_RANGER = "^x70FF70"
CC.CLASS_WITCH = "^x7070FF"
CC.CLASS_DUELIST = "^xE0E070"
CC.CLASS_TEMPLAR = "^xC040FF"
CC.CLASS_SHADOW = "^x30C0D0"

CC.STAT_FIRE = "^xB97123"
CC.STAT_COLD = "^x3F6DB3"
CC.STAT_LIGHTNING = "^xADAA47"
CC.STAT_CHAOS = "^xD02090"
CC.STAT_PHYS = "^xC8C8C8"
CC.STAT_STRENGTH = "^xE05030"
CC.STAT_DEXTERITY = "^x70FF70"
CC.STAT_INTELLIGENCE = "^x7070FF"
CC.STAT_OMNISCIENCE = "^xFFFF77"
CC.STAT_LIFE = "^xE05030"
CC.STAT_MANA = "^x7070FF"
CC.STAT_ES = "^x88FFFF"
CC.STAT_WARD = "^xFFFF77"
CC.STAT_EVASION = "^x33FF77"
CC.STAT_ARMOUR = "^xC8C8C8"
CC.STAT_RAGE = "^xFF9922"

CC.BUILD_POSITIVE = "^x33FF77"
CC.BUILD_NEGATIVE = "^xDD0022"
CC.BUILD_OFFENCE = "^xE07030"
CC.BUILD_DEFENCE = "^x8080E0"
CC.BUILD_MAINHAND = "^x50FF50"
CC.BUILD_MAINHANDBG = "^x071907"
CC.BUILD_OFFHAND = "^xB7B7FF"
CC.BUILD_OFFHANDBG = "^x070719"

CC.CHILLBG = "^x151e26"
CC.FREEZEBG = "^x0c262b"
CC.SHOCKBG = "^x191732"
CC.SCORCHBG = "^x270b00"
CC.BRITTLEBG = "^x00122b"
CC.SAPBG = "^x261500"

CC.CALC_SECTION_BORDER_SKILL = CC.CALC_SECTION_BORDER_SKILL or CC.ITEM_RARITY_NORMAL
CC.CALC_SECTION_BORDER_ATTRIBUTES= CC.CALC_SECTION_BORDER_ATTRIBUTES or CC.ITEM_RARITY_NORMAL
CC.CALC_SECTION_BORDER_OFFENCE = CC.CALC_SECTION_BORDER_OFFENCE or CC.BUILD_OFFENCE
CC.CALC_SECTION_BORDER_DEFENCE = CC.CALC_SECTION_BORDER_DEFENCE or CC.BUILD_DEFENCE

CC.DRAG_TEXT = "^xx262626BF"
CC.CONTROL_TEXT = "^xFFFFFF"
CC.CONTROL_TEXT_ACTIVE = "^xFFFFFF"
CC.CONTROL_TEXT_MUTED = "^x999999"
CC.CONTROL_TEXT_SECONDARY = "^xBFBFBF"
CC.CONTROL_TEXT_INACTIVE = "^x545454"
CC.CONTROL_TEXT_HOVER = "^xFFFFFF"
CC.CONTROL_TEXT_SEARCH = "^xxFFFF0033"
CC.CONTROL_BACKGROUND_INACTIVE = "^x000000"
CC.CONTROL_BACKGROUND_INACTIVE_HOVER = CC.CONTROL_BACKGROUND_INACTIVE
CC.CONTROL_BACKGROUND = "^x000000"
CC.CONTROL_BACKGROUND_HOVER = "^x545454"
CC.CONTROL_BACKGROUND_SELECTION = "^x80664d"
CC.CONTROL_BACKGROUND_ACTIVE = "^x808080"
CC.CONTROL_BACKGROUND_RECEIVE_DRAG = "^xx00FF0040"
CC.CONTROL_BORDER = "^x808080"
CC.CONTROL_BORDER_HOVER = "^xFFFFFF"
CC.CONTROL_BORDER_INACTIVE = "^x545454"
CC.CONTROL_BORDER_INACTIVE_HOVER = CC.CONTROL_BORDER_INACTIVE
CC.CONTROL_BORDER_RECEIVE_DRAG = "^x33A833" --0.2, 0.6, 0.2
CC.CONTROL_HIGHLIGHT = "^x00FF00"
CC.TREE_HIGHLIGHT_RING = "^xFF0000"
CC.RANGE_HIGHLIGHT = "^xx80FF8054"

defaultColorCodes = copyTable(CC)
function updateColorCode(code, color)
 	if CC[code] then
		CC[code] = color:gsub("^0", "^")
	end
end

--- Mapping from gem color integer to color key
--- @type table<string>
local skillColorMap = { "ITEM_GEM_RED", "ITEM_GEM_GREEN", "ITEM_GEM_BLUE", "ITEM_GEM_WHITE" }

UI.skillColorMap = setmetatable({ }, {
	__index = function(_, k)
		local key = skillColorMap[k]
		assert(key, "Invalid gem color: " .. tostring(k))
		return UI.CC[key]
	end})

--- List of all loaded themes
--- @type table<int, table>
UI.themeList = { }

--- 
--- @type table<string, table>
local themes = { }

local function addTheme(theme, id)
	themes[id] = theme
	t_insert(UI.themeList, { label = theme.name .. (theme.version and (" (" .. theme.version .. ")") or ""), id = id })
end


--- Attempts to parse theme definition
--- @param xml table @root (Theme) xml section
--- @return table, table @A pair of theme table and warnings
local function parseTheme(xml)
	local theme = { }
	local warnings = { }
	local function checkAttributes(node, attributes)
		local res = true
		for _, attrib in ipairs(attributes) do
			if not node.attrib[attrib] then
				t_insert(warnings, "'" .. node.elem .. "' element is missing '" .. attrib .. "' attribute")
				res = false
			end
		end
		return res
	end
	if not checkAttributes(xml, { "name" }) then
		return nil, warnings
	else
		theme.name = xml.attrib.name
	end
	theme.parent = xml.attrib.parent or "default"
	theme.version = xml.attrib.version
	for _, node in ipairs(xml) do
		if type(node) == "table" and node.elem == "colors" then
			for _, node in ipairs(node) do
				if checkAttributes(node, { "name", "value" }) then
					local name, value = node.attrib.name, node.attrib.value
					if not CC[name] then
						t_insert(warnings, "Skipping unrecognized element: '" .. name .. "'")
					else
						if value:match("^" .. ("%x"):rep(6) .. "$") then
							theme[name] = "^x" .. value
						elseif value:match("^" .. ("%x"):rep(8) .. "$") then
							theme[name] = "^xx" .. value
						else
							t_insert(warnings, "Skipping unrecognized color code: '" .. value .. "'")
						end
					end
				end
			end
		end
	end
	return theme, warnings
end

--- Loads all themes from files
--- Do not call before main:userPath is set
function UI.loadThemes()
	ConPrintf("Loading themes...")

	wipeTable(UI.themeList)
	wipeTable(themes)
	addTheme(CC, "default")

	local handle = NewFileSearch(main.userPath .. "Themes/*.xml")
	if not handle then return end

	repeat
		local fileName = handle:GetFileName()
		local id = fileName:gsub("%.xml$","")
		if id ~= "default" then
			local fileHnd = io.open(main.userPath .. "Themes/" .. fileName, "r")
			if fileHnd then
				local xml, errMsg = common.xml.ParseXML(fileHnd:read("*a"))
				if not xml then
					launch:ShowErrMsg("%sError loading '%s': %s", CC.ERROR, fileName, errMsg)
				elseif not xml[1] or xml[1].elem ~= "Theme" then
					launch:ShowErrMsg("%sError parsing '%s': 'Theme' root element missing", CC.ERROR, fileName)
				else
					local theme, errMsg = parseTheme(xml[1])
					local c = CC.WARNING
					if not theme then
						c = CC.ERROR
					else
						addTheme(setmetatable(theme, { __index = themes.default }), id)
					end
					for _, msg in ipairs(errMsg) do
						ConPrintf(c .. fileName .. ": " .. msg)
					end
				end
			end
		end
	until not handle:NextFile()
end

--- The current theme, dynamically redirects references to current data
--- @type table<string, string>
UI.CC = { }

--- Sets current theme
--- @param id string @Id of theme to activate
--- @return boolean @Whether theme was found
function UI.setTheme(id)
	local newTheme = themes[id]
	if newTheme then
		-- Redirect existing references
		setmetatable(UI.CC, { __index = newTheme })
		return true
	else
		ConPrintf(CC.WARNING .. "Missing theme: " .. id)
		return false
	end
end

local cache = setmetatable({ }, {
	__index = function(t, k)
		if not rawget(t, k) then
			rawset(t, k, k:gsub("{([%u_]+)}", UI.CC))
		end
		return t[k]
	end
})
function UI.colorFormat(str, ...)
	return cache[str]:format(...)
end

addTheme(CC, "default")
UI.setTheme("default")
