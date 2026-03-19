-- Path of Building
--
-- Class: Radius Jewel Finder
-- Popup that scores passive tree sockets for radius unique jewels.
-- Supports: The Light of Meaning, Might of the Meek, Unnatural Instinct,
--           Inspired Learning, Anatomical Knowledge, Thread of Hope, Lioneye's Fall,
--           Intuitive Leap, Tempered Flesh, Tempered Mind, Tempered Spirit,
--           Transcendent Flesh, Transcendent Mind, Transcendent Spirit,
--           Split Personality, Impossible Escape,
--           Energy From Within, Healthy Mind, Energised Armour,
--           Brute Force Solution, Careful Planning, Efficient Training,
--           Fertile Mind, Fluid Motion, Inertia,
--           Combat Focus (Crimson/Cobalt/Viridian),
--           The Red Dream, The Red Nightmare, The Green Dream, The Green Nightmare,
--           The Blue Dream, The Blue Nightmare.
--
local ipairs = ipairs
local pairs = pairs
local t_insert = table.insert
local t_sort = table.sort
local t_concat = table.concat
local s_format = string.format
local m_huge = math.huge

local function formatSignedValue(value)
	local sign = value >= 0 and "+" or ""
	local col = value > 0 and "^2" or (value < 0 and "^1" or "^8")
	return s_format("%s%s%.1f", col, sign, value)
end

local function formatSignedPercent(value)
	local sign = value >= 0 and "+" or ""
	local col = value > 0 and "^2" or (value < 0 and "^1" or "^8")
	return s_format("%s%s%.1f%%", col, sign, value)
end

local function formatPerPointDisplay(value, points)
	if points == 0 then
		return value > 0 and "^2Free" or (value < 0 and "^1Free" or "^8Free")
	end
	return formatSignedPercent(value)
end

local RadiusJewelResultsListClass = newClass("RadiusJewelResultsListControl", "ListControl", function(self, anchor, rect, build, socketViewer)
	self.ListControl(anchor, rect, 16, "VERTICAL", false)
	self.build = build
	self.socketViewer = socketViewer
	self.colLabels = true
	self.showRowSeparators = true
	self.defaultText = "^8Click Find to search"
	self.mode = "message"
	self.columnsByMode = {
		message = {
			{ width = rect[3] - 22, label = "" },
		},
		computeVariant = {
			{ width = 300, label = "Variant", sortable = true },
			{ width = 120, label = "Gain", sortable = true },
			{ width = 120, label = "%", sortable = true },
		},
		computeSocket = {
			{ width = 170, label = "Socket", sortable = true },
			{ width = 40, label = "Pts", sortable = true },
			{ width = 75, label = "Gain", sortable = true },
			{ width = 60, label = "%", sortable = true },
			{ width = 65, label = "%/Pt", sortable = true },
			{ width = 150, label = "Detail", sortable = true },
		},
		find = {
			{ width = 170, label = "Socket", sortable = true },
			{ width = 40, label = "Pts", sortable = true },
			{ width = 60, label = "Score", sortable = true },
			{ width = 70, label = "/Pt", sortable = true },
			{ width = 220, label = "Detail", sortable = true },
		},
		findThread = {
			{ width = 170, label = "Socket", sortable = true },
			{ width = 40, label = "Pts", sortable = true },
			{ width = 60, label = "Score", sortable = true },
			{ width = 70, label = "/Pt", sortable = true },
			{ width = 90, label = "Ring", sortable = true },
			{ width = 130, label = "Detail", sortable = true },
		},
	}
	self.defaultSortByMode = {
		computeVariant = 2,
		computeSocket = 5,
		find = 4,
		findThread = 4,
	}
	self.resultTooltip = new("Tooltip")
end)

function RadiusJewelResultsListClass:SetMode(mode, list, defaultText)
	self.mode = mode or "message"
	self.list = list or { }
	self.defaultText = defaultText or ""
	self.colList = self.columnsByMode[self.mode] or self.columnsByMode.message
	local defaultSort = self.defaultSortByMode[self.mode]
	if defaultSort and #self.list > 0 then
		self:ReSort(defaultSort)
	end
end

function RadiusJewelResultsListClass:ReSort(colIndex)
	if self.mode == "computeVariant" then
		if colIndex == 1 then
			t_sort(self.list, function(a, b) return a.variantLabel < b.variantLabel end)
		elseif colIndex == 2 then
			t_sort(self.list, function(a, b) return a.delta > b.delta end)
		elseif colIndex == 3 then
			t_sort(self.list, function(a, b) return a.pct > b.pct end)
		end
	elseif self.mode == "computeSocket" then
		if colIndex == 1 then
			t_sort(self.list, function(a, b) return a.socketLabel < b.socketLabel end)
		elseif colIndex == 2 then
			t_sort(self.list, function(a, b) return a.points < b.points end)
		elseif colIndex == 3 then
			t_sort(self.list, function(a, b) return a.delta > b.delta end)
		elseif colIndex == 4 then
			t_sort(self.list, function(a, b) return a.pct > b.pct end)
		elseif colIndex == 5 then
			t_sort(self.list, function(a, b) return a.sortPctPerPoint > b.sortPctPerPoint end)
		elseif colIndex == 6 then
			t_sort(self.list, function(a, b) return a.detailText < b.detailText end)
		end
	elseif self.mode == "find" or self.mode == "findThread" then
		if colIndex == 1 then
			t_sort(self.list, function(a, b) return a.socketLabel < b.socketLabel end)
		elseif colIndex == 2 then
			t_sort(self.list, function(a, b) return a.points < b.points end)
		elseif colIndex == 3 then
			t_sort(self.list, function(a, b) return a.score > b.score end)
		elseif colIndex == 4 then
			t_sort(self.list, function(a, b) return a.scorePerPointSort > b.scorePerPointSort end)
		elseif colIndex == 5 then
			if self.mode == "findThread" then
				t_sort(self.list, function(a, b) return a.variantLabel < b.variantLabel end)
			else
				t_sort(self.list, function(a, b) return a.detailText < b.detailText end)
			end
		elseif colIndex == 6 and self.mode == "findThread" then
			t_sort(self.list, function(a, b) return a.detailText < b.detailText end)
		end
	end
end

function RadiusJewelResultsListClass:GetRowValue(column, index, row)
	if self.mode == "message" then
		return column == 1 and row.text or ""
	elseif self.mode == "computeVariant" then
		return column == 1 and row.variantLabel
			or column == 2 and formatSignedValue(row.delta)
			or column == 3 and formatSignedPercent(row.pct)
			or ""
	elseif self.mode == "computeSocket" then
		return column == 1 and row.socketLabel
			or column == 2 and tostring(row.points)
			or column == 3 and formatSignedValue(row.delta)
			or column == 4 and formatSignedPercent(row.pct)
			or column == 5 and formatPerPointDisplay(row.pctPerPoint, row.points)
			or column == 6 and row.detailText
			or ""
	elseif self.mode == "find" then
		return column == 1 and row.socketLabel
			or column == 2 and tostring(row.points)
			or column == 3 and s_format("^7%d", row.score)
			or column == 4 and (row.points == 0 and (row.score > 0 and "^2Free" or "^8Free") or s_format("^7%.2f", row.scorePerPoint))
			or column == 5 and row.detailText
			or ""
	elseif self.mode == "findThread" then
		return column == 1 and row.socketLabel
			or column == 2 and tostring(row.points)
			or column == 3 and s_format("^7%d", row.score)
			or column == 4 and (row.points == 0 and (row.score > 0 and "^2Free" or "^8Free") or s_format("^7%.2f", row.scorePerPoint))
			or column == 5 and row.variantLabel
			or column == 6 and row.detailText
			or ""
	end
	return ""
end

function RadiusJewelResultsListClass:Draw(viewPort, noTooltip)
	self.ListControl.Draw(self, viewPort, true)
	if self.suppressTooltipFunc and self.suppressTooltipFunc() then
		return
	end
	local hoverData = self.hoverValue
	if not hoverData or main.popups[2] then
		return
	end

	local function clampRectPosition(x, y, width, height)
		x = math.max(viewPort.x, math.min(x, viewPort.x + viewPort.width - width))
		y = math.max(viewPort.y, math.min(y, viewPort.y + viewPort.height - height))
		return x, y
	end
	local function rectsOverlap(aX, aY, aW, aH, bX, bY, bW, bH)
		return aX < bX + bW and aX + aW > bX and aY < bY + bH and aY + aH > bY
	end
	local function placeResultTooltip(ttW, ttH, cursorX, cursorY, viewerRect)
		local candidates = {
			{ x = cursorX + 20, y = cursorY + 20 },
			{ x = cursorX - ttW - 20, y = cursorY + 20 },
			{ x = cursorX + 20, y = cursorY - ttH - 20 },
			{ x = cursorX - ttW - 20, y = cursorY - ttH - 20 },
		}
		if viewerRect then
			t_insert(candidates, 1, { x = viewerRect.x - ttW - 12, y = cursorY + 20 })
			t_insert(candidates, 2, { x = viewerRect.x + viewerRect.width + 12, y = cursorY + 20 })
			t_insert(candidates, 3, { x = viewerRect.x, y = viewerRect.y - ttH - 12 })
			t_insert(candidates, 4, { x = viewerRect.x, y = viewerRect.y + viewerRect.height + 12 })
		end
		for _, candidate in ipairs(candidates) do
			local ttX, ttY = clampRectPosition(candidate.x, candidate.y, ttW, ttH)
			if not viewerRect or not rectsOverlap(ttX, ttY, ttW, ttH, viewerRect.x, viewerRect.y, viewerRect.width, viewerRect.height) then
				return ttX, ttY
			end
		end
		return clampRectPosition(cursorX + 20, cursorY + 20, ttW, ttH)
	end

	local cursorX, cursorY = GetCursorPos()
	local viewerRect
	if hoverData.socketId then
		local node = self.build.spec.nodes[hoverData.socketId]
		if node then
			SetDrawLayer(nil, 15)
			local viewerX = cursorX + 20
			local viewerY = cursorY - 150
			if viewerX + 304 > viewPort.x + viewPort.width then viewerX = cursorX - 324 end
			if viewerY < viewPort.y then viewerY = viewPort.y elseif viewerY + 304 > viewPort.y + viewPort.height then viewerY = viewPort.y + viewPort.height - 304 end
			viewerRect = { x = viewerX, y = viewerY, width = 304, height = 304 }

			SetDrawColor(1, 1, 1)
			DrawImage(nil, viewerX, viewerY, 304, 304)
			self.socketViewer.zoom = 5
			local scale = self.build.spec.tree.size / 1500
			self.socketViewer.zoomX = -node.x / scale
			self.socketViewer.zoomY = -node.y / scale
			SetViewport(viewerX + 2, viewerY + 2, 300, 300)
			self.socketViewer:Draw(self.build, { x = 0, y = 0, width = 300, height = 300 }, { })
			SetDrawLayer(nil, 30)
			SetDrawColor(1, 1, 1, 0.2)
			DrawImage(nil, 149, 0, 2, 300)
			DrawImage(nil, 0, 149, 300, 2)
			SetViewport()
			SetDrawLayer(nil, 0)
		end
	end

	if hoverData.baseOutput and hoverData.compareOutput then
		SetDrawLayer(nil, 100)
		self.resultTooltip:Clear()
		local count = self.build:AddStatComparesToTooltip(self.resultTooltip, hoverData.baseOutput, hoverData.compareOutput,
			hoverData.tooltipHeader or "^7Socketing this jewel will give you:")
		if count == 0 then
			self.resultTooltip:AddLine(14, "^7No stat changes for this proposal.")
		end
		local ttW, ttH = self.resultTooltip:GetSize()
		local ttX, ttY = placeResultTooltip(ttW, ttH, cursorX, cursorY, viewerRect)
		self.resultTooltip:Draw(ttX, ttY, nil, nil, viewPort)
		SetDrawLayer(nil, 0)
	end
end

local RadiusJewelFinderClass = newClass("RadiusJewelFinder", function(self, treeTab)
	self.treeTab = treeTab
	self.build = treeTab.build
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Light of Meaning variants
-- ─────────────────────────────────────────────────────────────────────────────

local LIGHT_OF_MEANING_VARIANTS = {
	{ name = "Life",             mod = "+5 to Maximum Life",                  bonus = "+5 Life" },
	{ name = "Energy Shield",    mod = "3% increased Energy Shield",           bonus = "3% inc ES" },
	{ name = "Mana",             mod = "+5 to Maximum Mana",                  bonus = "+5 Mana" },
	{ name = "Armour",           mod = "7% increased Armour",                 bonus = "7% inc Armour" },
	{ name = "Evasion Rating",   mod = "7% increased Evasion Rating",         bonus = "7% inc Evasion" },
	{ name = "Attributes",       mod = "+2 to all Attributes",                bonus = "+2 Attributes" },
	{ name = "Global Crit",      mod = "5% increased Global Critical Strike", bonus = "5% inc Crit" },
	{ name = "Physical Damage",  mod = "6% increased Physical Damage",        bonus = "6% inc Phys" },
	{ name = "Lightning Damage", mod = "6% increased Lightning Damage",       bonus = "6% inc Lightning" },
	{ name = "Cold Damage",      mod = "6% increased Cold Damage",            bonus = "6% inc Cold" },
	{ name = "Fire Damage",      mod = "6% increased Fire Damage",            bonus = "6% inc Fire" },
	{ name = "Chaos Damage",     mod = "6% increased Chaos Damage",           bonus = "6% inc Chaos" },
	{ name = "Chaos Resistance", mod = "+4% to Chaos Resistance",             bonus = "+4% Chaos Res" },
}

-- LOM raw item text (verbatim copy from jewel.lua, used for impact calculation)
local LOM_RAW_TEXT = [[The Light of Meaning
Prismatic Jewel
Variant: Life
Variant: Energy Shield
Variant: Mana
Variant: Armour
Variant: Evasion Rating
Variant: Attributes
Variant: Global Crit Chance
Variant: Physical Damage
Variant: Lightning Damage
Variant: Cold Damage
Variant: Fire Damage
Variant: Chaos Damage
Variant: Chaos Resistance
Selected Variant: 1
Source: King of The Mists
Limited to: 1
Radius: Large
{variant:1}Passive Skills in Radius also grant +5 to Maximum Life
{variant:2}Passive Skills in Radius also grant 3% increased Energy Shield
{variant:3}Passive Skills in Radius also grant +5 to Maximum Mana
{variant:4}Passive Skills in Radius also grant 7% increased Armour
{variant:5}Passive Skills in Radius also grant 7% increased Evasion Rating
{variant:6}Passive Skills in Radius also grant +2 to all Attributes
{variant:7}Passive Skills in Radius also grant 5% Increased Global Critical Strike Chance
{variant:8}Passive Skills in Radius also grant 6% increased Physical Damage
{variant:9}Passive Skills in Radius also grant 6% increased Lightning Damage
{variant:10}Passive Skills in Radius also grant 6% increased Cold Damage
{variant:11}Passive Skills in Radius also grant 6% increased Fire Damage
{variant:12}Passive Skills in Radius also grant 6% increased Chaos Damage
{variant:13}Passive Skills in Radius also grant +4% to Chaos Resistance]]

local MIGHT_OF_MEEK_RAW_TEXT = [[Might of the Meek
Crimson Jewel
Radius: Large
50% increased Effect of non-Keystone Passive Skills in Radius
Notable Passive Skills in Radius grant nothing]]

local MIGHT_OF_MEEK_FOULBORN_V1_RAW_TEXT = [[Might of the Meek
Crimson Jewel
Radius: Medium
75% increased Effect of non-Keystone Passive Skills in Radius
Notable Passive Skills in Radius grant nothing]]

local MIGHT_OF_MEEK_FOULBORN_V2_RAW_TEXT = [[Might of the Meek
Crimson Jewel
Radius: Small
100% increased Effect of non-Keystone Passive Skills in Radius
Notable Passive Skills in Radius grant nothing]]

local UNNATURAL_INSTINCT_RAW_TEXT = [[Unnatural Instinct
Viridian Jewel
Limited to: 1
Radius: Small
Allocated Small Passive Skills in Radius grant nothing
Grants all bonuses of Unallocated Small Passive Skills in Radius]]

local UNNATURAL_INSTINCT_FOULBORN_RAW_TEXT = [[Unnatural Instinct
Viridian Jewel
Limited to: 1
Radius: Small
Allocated Notable Passive Skills in Radius grant nothing
Grants all bonuses of Unallocated Notable Passive Skills in Radius]]

local INSPIRED_LEARNING_RAW_TEXT = [[Inspired Learning
Crimson Jewel
Radius: Small
With 4 Notables Allocated in Radius, When you Kill a Rare monster, you gain 1 of its Modifiers for 20 seconds]]

local INSPIRED_LEARNING_FOULBORN_LARGE_RAW_TEXT = [[Inspired Learning
Crimson Jewel
Radius: Large
If no Notables Allocated in Radius, When you Kill a Rare monster, you gain 1 of its Modifiers for 20 seconds]]

local INSPIRED_LEARNING_FOULBORN_SMALL_RAW_TEXT = [[Inspired Learning
Crimson Jewel
Radius: Small
With (8-12) Small Passives Allocated in Radius, When you Kill a Rare monster, you gain 1 of its Modifiers for 20 seconds]]

local ANATOMICAL_KNOWLEDGE_RAW_TEXT = [[Anatomical Knowledge
Cobalt Jewel
Source: No longer obtainable
Radius: Large
8% increased maximum Life
Adds 1 to Maximum Life per 3 Intelligence Allocated in Radius]]

local LIONEYES_FALL_RAW_TEXT = [[Lioneye's Fall
Viridian Jewel
Radius: Medium
Melee and Melee Weapon Type modifiers in Radius are Transformed to Bow Modifiers]]

local LIONEYES_FALL_FOULBORN_RAW_TEXT = [[Lioneye's Fall
Viridian Jewel
Radius: Medium
Increases and Reductions to Evasion Rating in Radius are Transformed to apply to Armour]]

local INTUITIVE_LEAP_RAW_TEXT = [[Intuitive Leap
Viridian Jewel
Radius: Small
Passives in Radius can be Allocated without being connected to your tree]]

local INTUITIVE_LEAP_FOULBORN_RAW_TEXT = [[Intuitive Leap
Viridian Jewel
Radius: Massive
Keystone Passive Skills in Radius can be Allocated without being connected to your tree]]

local THREAD_OF_HOPE_RAW_TEXT = [[Thread of Hope
Crimson Jewel
Source: Drops from unique{Sirus, Awakener of Worlds}
Variant: Small Ring
Variant: Medium Ring
Variant: Large Ring
Variant: Very Large Ring
Variant: Massive Ring (Uber)
Radius: Variable
Implicits: 0
{variant:1}Only affects Passives in Small Ring
{variant:2}Only affects Passives in Medium Ring
{variant:3}Only affects Passives in Large Ring
{variant:4}Only affects Passives in Very Large Ring
{variant:5}Only affects Passives in Massive Ring
Passive Skills in Radius can be Allocated without being connected to your tree
-(20-10)% to all Elemental Resistances]]

local TEMPERED_FLESH_RAW_TEXT = [[Tempered Flesh
Crimson Jewel
League: Incursion
Source: Drops from unique{The Vaal Omnitect}
Upgrade: Upgrades to unique{Transcendent Flesh} via currency{Vial of Transcendence}
Radius: Medium
-1 Strength per 1 Strength on Allocated Passives in Radius
2% increased Life Recovery Rate per 10 Strength on Allocated Passives in Radius]]

local TRANSCENDENT_FLESH_RAW_TEXT = [[Transcendent Flesh
Crimson Jewel
League: Incursion
Source: Upgraded from unique{Tempered Flesh} via currency{Vial of Transcendence}
Radius: Medium
-1 Strength per 1 Strength on Allocated Passives in Radius
3% increased Life Recovery Rate per 10 Strength on Allocated Passives in Radius
2% reduced Life Recovery Rate per 10 Strength on Unallocated Passives in Radius
+7% to Critical Strike Multiplier per 10 Strength on Unallocated Passives in Radius]]

local TEMPERED_MIND_RAW_TEXT = [[Tempered Mind
Cobalt Jewel
League: Incursion
Source: Drops from unique{The Vaal Omnitect}
Upgrade: Upgrades to unique{Transcendent Mind} via currency{Vial of Transcendence}
Radius: Medium
-1 Intelligence per 1 Intelligence on Allocated Passives in Radius
2% increased Mana Recovery Rate per 10 Intelligence on Allocated Passives in Radius]]

local TRANSCENDENT_MIND_RAW_TEXT = [[Transcendent Mind
Cobalt Jewel
League: Incursion
Source: Upgraded from unique{Tempered Mind} via currency{Vial of Transcendence}
Radius: Medium
-1 Intelligence per 1 Intelligence on Allocated Passives in Radius
+3% to Damage over Time Multiplier per 10 Intelligence on Unallocated Passives in Radius
3% increased Mana Recovery Rate per 10 Intelligence on Allocated Passives in Radius
2% reduced Mana Recovery Rate per 10 Intelligence on Unallocated Passives in Radius]]

local TEMPERED_SPIRIT_RAW_TEXT = [[Tempered Spirit
Viridian Jewel
League: Incursion
Source: Drops from unique{The Vaal Omnitect}
Upgrade: Upgrades to unique{Transcendent Spirit} via currency{Vial of Transcendence}
Radius: Medium
-1 Dexterity per 1 Dexterity on Allocated Passives in Radius
2% increased Movement Speed per 10 Dexterity on Allocated Passives in Radius]]

local TRANSCENDENT_SPIRIT_RAW_TEXT = [[Transcendent Spirit
Viridian Jewel
League: Incursion
Source: Upgraded from unique{Tempered Spirit} via currency{Vial of Transcendence}
Radius: Medium
-1 Dexterity per 1 Dexterity on Allocated Passives in Radius
3% increased Movement Speed per 10 Dexterity on Allocated Passives in Radius
2% reduced Movement Speed per 10 Dexterity on Unallocated Passives in Radius
+125 to Accuracy Rating per 10 Dexterity on Unallocated Passives in Radius]]

local ENERGY_FROM_WITHIN_RAW_TEXT = [[Energy From Within
Cobalt Jewel
Radius: Large
3% increased maximum Energy Shield
Increases and Reductions to Life in Radius are Transformed to apply to Energy Shield]]

local HEALTHY_MIND_RAW_TEXT = [[Healthy Mind
Cobalt Jewel
Radius: Large
15% increased maximum Mana
Increases and Reductions to Life in Radius are Transformed to apply to Mana at 200% of their value]]

local ENERGISED_ARMOUR_RAW_TEXT = [[Energised Armour
Crimson Jewel
Radius: Large
15% increased Armour
Increases and Reductions to Energy Shield in Radius are Transformed to apply to Armour at 200% of their value]]

local BRUTE_FORCE_SOLUTION_RAW_TEXT = [[Brute Force Solution
Cobalt Jewel
Radius: Large
+16 to Intelligence
Strength from Passives in Radius is Transformed to Intelligence]]

local CAREFUL_PLANNING_RAW_TEXT = [[Careful Planning
Viridian Jewel
Radius: Large
+16 to Dexterity
Intelligence from Passives in Radius is Transformed to Dexterity]]

local EFFICIENT_TRAINING_RAW_TEXT = [[Efficient Training
Crimson Jewel
Radius: Large
+16 to Strength
Intelligence from Passives in Radius is Transformed to Strength]]

local FERTILE_MIND_RAW_TEXT = [[Fertile Mind
Cobalt Jewel
Radius: Large
+16 to Intelligence
Dexterity from Passives in Radius is Transformed to Intelligence]]

local FLUID_MOTION_RAW_TEXT = [[Fluid Motion
Viridian Jewel
Radius: Large
+16 to Dexterity
Strength from Passives in Radius is Transformed to Dexterity]]

local INERTIA_RAW_TEXT = [[Inertia
Crimson Jewel
Radius: Large
+16 to Strength
Dexterity from Passives in Radius is Transformed to Strength]]

local COMBAT_FOCUS_CRIMSON_RAW_TEXT = [[Combat Focus
Crimson Jewel
Radius: Medium
10% increased Elemental Damage
With 40 total Strength and Intelligence in Radius, Prismatic Skills cannot choose Cold
With 40 total Strength and Intelligence in Radius, Prismatic Skills deal 50% less Cold Damage]]

local COMBAT_FOCUS_COBALT_RAW_TEXT = [[Combat Focus
Cobalt Jewel
Radius: Medium
10% increased Elemental Damage
With 40 total Intelligence and Dexterity in Radius, Prismatic Skills cannot choose Fire
With 40 total Intelligence and Dexterity in Radius, Prismatic Skills deal 50% less Fire Damage]]

local COMBAT_FOCUS_VIRIDIAN_RAW_TEXT = [[Combat Focus
Viridian Jewel
Radius: Medium
10% increased Elemental Damage
With 40 total Dexterity and Strength in Radius, Prismatic Skills cannot choose Lightning
With 40 total Dexterity and Strength in Radius, Prismatic Skills deal 50% less Lightning Damage]]

local THE_RED_DREAM_RAW_TEXT = [[The Red Dream
Crimson Jewel
Radius: Large
Gain (6-10)% of Fire Damage as Extra Chaos Damage
Passives granting Fire Resistance or all Elemental Resistances in Radius also grant an equal chance to gain an Endurance Charge on Kill]]

local THE_RED_DREAM_FOULBORN_RAW_TEXT = [[The Red Dream
Crimson Jewel
Radius: Large
Gain (6-10)% of Fire Damage as Extra Chaos Damage
Passives granting Fire Resistance or all Elemental Resistances in Radius also grant increased Maximum Life at 50% of its value]]

local THE_RED_NIGHTMARE_RAW_TEXT = [[The Red Nightmare
Crimson Jewel
Radius: Large
Gain (6-10)% of Fire Damage as Extra Chaos Damage
Passives granting Fire Resistance or all Elemental Resistances in Radius also grant Chance to Block Attack Damage at 50% of its value]]

local THE_RED_NIGHTMARE_FOULBORN_RAW_TEXT = [[The Red Nightmare
Crimson Jewel
Radius: Large
Gain (6-10)% of Fire Damage as Extra Chaos Damage
Passives granting Fire Resistance or all Elemental Resistances in Radius also grant Fire Damage Converted to Chaos Damage at 100% of its value]]

local THE_GREEN_DREAM_RAW_TEXT = [[The Green Dream
Viridian Jewel
Radius: Large
Gain (6-10)% of Cold Damage as Extra Chaos Damage
Passives granting Cold Resistance or all Elemental Resistances in Radius also grant an equal chance to gain a Frenzy Charge on Kill]]

local THE_GREEN_DREAM_FOULBORN_RAW_TEXT = [[The Green Dream
Viridian Jewel
Radius: Large
Gain (6-10)% of Cold Damage as Extra Chaos Damage
Passives granting Cold Resistance or all Elemental Resistances in Radius also grant increased Maximum Mana at 75% of its value]]

local THE_GREEN_NIGHTMARE_RAW_TEXT = [[The Green Nightmare
Viridian Jewel
Radius: Large
Gain (6-10)% of Cold Damage as Extra Chaos Damage
Passives granting Cold Resistance or all Elemental Resistances in Radius also grant Chance to Suppress Spell Damage at 70% of its value]]

local THE_GREEN_NIGHTMARE_FOULBORN_RAW_TEXT = [[The Green Nightmare
Viridian Jewel
Radius: Large
Gain (6-10)% of Cold Damage as Extra Chaos Damage
Passives granting Cold Resistance or all Elemental Resistances in Radius also grant Cold Damage Converted to Chaos Damage at 100% of its value]]

local THE_BLUE_DREAM_RAW_TEXT = [[The Blue Dream
Cobalt Jewel
Radius: Large
Gain (6-10)% of Lightning Damage as Extra Chaos Damage
Passives granting Lightning Resistance or all Elemental Resistances in Radius also grant an equal chance to gain a Power Charge on Kill]]

local THE_BLUE_DREAM_FOULBORN_RAW_TEXT = [[The Blue Dream
Cobalt Jewel
Radius: Large
Gain (6-10)% of Lightning Damage as Extra Chaos Damage
Passives granting Lightning Resistance or all Elemental Resistances in Radius also grant increased Maximum Energy Shield at 75% of its value]]

local THE_BLUE_NIGHTMARE_RAW_TEXT = [[The Blue Nightmare
Cobalt Jewel
Radius: Large
Gain (6-10)% of Lightning Damage as Extra Chaos Damage
Passives granting Lightning Resistance or all Elemental Resistances in Radius also grant Chance to Block Spell Damage at 50% of its value]]

local THE_BLUE_NIGHTMARE_FOULBORN_RAW_TEXT = [[The Blue Nightmare
Cobalt Jewel
Radius: Large
Gain (6-10)% of Lightning Damage as Extra Chaos Damage
Passives granting Lightning Resistance or all Elemental Resistances in Radius also grant Lightning Damage Converted to Chaos Damage at 100% of its value]]

local function buildJewelRawText(name, itemType, radius, mods, extra)
	local lines = { name, itemType }
	if extra then
		for _, meta in ipairs(extra) do
			t_insert(lines, meta)
		end
	end
	t_insert(lines, "Radius: " .. radius)
	for _, mod in ipairs(mods) do
		t_insert(lines, mod)
	end
	return t_concat(lines, "\n")
end

local function scoreGainLoss(nodes, allocNodes, gainType, lossType)
	local gained, lost = 0, 0
	for nodeId, node in pairs(nodes) do
		if gainType and node.type == gainType and not allocNodes[nodeId] then
			gained = gained + 1
		end
		if lossType and node.type == lossType and allocNodes[nodeId] then
			lost = lost + 1
		end
	end
	return gained - lost
end

local function buildSplitPersonalityRawText(modLine)
	return buildJewelRawText("Split Personality", "Crimson Jewel", "Variable", {
		"This Jewel's Socket has 25% increased effect per Allocated Passive Skill between it and your Class' starting location",
		modLine,
		"Corrupted",
	}, { "Limited to: 2", "Source: Drops from the Simulacrum Encounter" })
end

local function buildImpossibleEscapeRawText(keystoneName)
	return buildJewelRawText("Impossible Escape", "Viridian Jewel", "Small", {
		"Passive Skills in radius of " .. keystoneName .. " can be allocated without being connected to your tree",
		"Corrupted",
	}, { "Limited to: 1", "Source: Drops from The Maven (Uber)" })
end

local function buildImpossibleEscapeVariants()
	local variants = { }
	for _, rawText in ipairs(data.uniques.generated or { }) do
		if type(rawText) == "string" and rawText:match("^Impossible Escape\n") then
			for line in rawText:gmatch("[^\n]+") do
				local name = line:match("^Variant: (.+)$")
				if name and name ~= "Everything (QoL Test Variant)" then
					t_insert(variants, {
						name = name,
						dropdownLabel = name,
						keystoneName = name,
						rawText = buildImpossibleEscapeRawText(name),
						scoreLabel = "unalloc notable/keystone near keystone",
					})
				end
			end
			break
		end
	end
	return variants
end

local function getRadiusPassiveAttributeTotals(nodes, allocNodes, attribute)
	local allocated = 0
	local unallocated = 0
	for nodeId, node in pairs(nodes) do
		if node.type ~= "Socket" and node.type ~= "ClassStart" and node.type ~= "AscendClassStart" then
			local amount = node.modList and node.modList:Sum("BASE", nil, attribute) or 0
			if amount ~= 0 then
				if allocNodes[nodeId] then
					allocated = allocated + amount
				else
					unallocated = unallocated + amount
				end
			end
		end
	end
	return allocated, unallocated
end

local function scoreRadiusAttributes(nodes, allocNodes, attribute, includeAllocated, includeUnallocated)
	local allocated, unallocated = getRadiusPassiveAttributeTotals(nodes, allocNodes, attribute)
	local score = 0
	if includeAllocated then
		score = score + allocated
	end
	if includeUnallocated then
		score = score + unallocated
	end
	return score
end

local function makeRadiusAttributeDetail(attributeLabel, includeAllocated, includeUnallocated)
	return function(nodes, allocNodes)
		local allocated, unallocated = getRadiusPassiveAttributeTotals(nodes, allocNodes, attributeLabel)
		if includeAllocated and includeUnallocated then
			return s_format("%s alloc %d | %s unalloc %d", attributeLabel, allocated, attributeLabel, unallocated)
		elseif includeAllocated then
			return s_format("%s alloc %d", attributeLabel, allocated)
		end
		return s_format("%s unalloc %d", attributeLabel, unallocated)
	end
end

local function makeTemperedVariant(name, rawText, attribute, includeAllocated, includeUnallocated)
	local detailBuilder = makeRadiusAttributeDetail(attribute, includeAllocated, includeUnallocated)
	return {
		name = name,
		rawText = rawText,
		scoreLabel = includeAllocated and includeUnallocated and (attribute:lower() .. " alloc+unalloc")
			or includeAllocated and (attribute:lower() .. " alloc")
			or (attribute:lower() .. " unalloc"),
		score = function(nodes, allocNodes)
			return scoreRadiusAttributes(nodes, allocNodes, attribute, includeAllocated, includeUnallocated)
		end,
		detailBuilder = detailBuilder,
	}
end

local TEMPERED_TRANSCENDENT_VARIANTS = {
	makeTemperedVariant("Tempered Flesh", TEMPERED_FLESH_RAW_TEXT, "Str", true, false),
	makeTemperedVariant("Transcendent Flesh", TRANSCENDENT_FLESH_RAW_TEXT, "Str", true, true),
	makeTemperedVariant("Tempered Mind", TEMPERED_MIND_RAW_TEXT, "Int", true, false),
	makeTemperedVariant("Transcendent Mind", TRANSCENDENT_MIND_RAW_TEXT, "Int", true, true),
	makeTemperedVariant("Tempered Spirit", TEMPERED_SPIRIT_RAW_TEXT, "Dex", true, false),
	makeTemperedVariant("Transcendent Spirit", TRANSCENDENT_SPIRIT_RAW_TEXT, "Dex", true, true),
}

local SPLIT_PERSONALITY_VARIANTS = {
	{ name = "Strength", rawText = buildSplitPersonalityRawText("+5 to Strength") },
	{ name = "Dexterity", rawText = buildSplitPersonalityRawText("+5 to Dexterity") },
	{ name = "Intelligence", rawText = buildSplitPersonalityRawText("+5 to Intelligence") },
	{ name = "Life", rawText = buildSplitPersonalityRawText("+5 to maximum Life") },
	{ name = "Mana", rawText = buildSplitPersonalityRawText("+5 to maximum Mana") },
	{ name = "Energy Shield", rawText = buildSplitPersonalityRawText("+5 to maximum Energy Shield") },
	{ name = "Armour", rawText = buildSplitPersonalityRawText("+40 to Armour") },
	{ name = "Evasion Rating", rawText = buildSplitPersonalityRawText("+40 to Evasion Rating") },
	{ name = "Accuracy Rating", rawText = buildSplitPersonalityRawText("+40 to Accuracy Rating") },
}

local IMPOSSIBLE_ESCAPE_VARIANTS = buildImpossibleEscapeVariants()

local UNNATURAL_INSTINCT_FOULBORN_VARIANTS = {
	{
		name = "Notables grant nothing",
		dropdownLabel = "Small gain / notable loss",
		scoreLabel = "unalloc small - alloc notable",
		rawText = buildJewelRawText("Unnatural Instinct", "Viridian Jewel", "Small", {
			"Allocated Notable Passive Skills in Radius grant nothing",
			"Grants all bonuses of Unallocated Small Passive Skills in Radius",
		}, { "Limited to: 1" }),
		score = function(nodes, allocNodes)
			return scoreGainLoss(nodes, allocNodes, "Normal", "Notable")
		end,
	},
	{
		name = "Unallocated Notables",
		dropdownLabel = "Notable gain / small loss",
		scoreLabel = "unalloc notable - alloc small",
		rawText = buildJewelRawText("Unnatural Instinct", "Viridian Jewel", "Small", {
			"Allocated Small Passive Skills in Radius grant nothing",
			"Grants all bonuses of Unallocated Notable Passive Skills in Radius",
		}, { "Limited to: 1" }),
		score = function(nodes, allocNodes)
			return scoreGainLoss(nodes, allocNodes, "Notable", "Normal")
		end,
	},
	{
		name = "Both Foulborn mods",
		dropdownLabel = "Notable swap",
		scoreLabel = "unalloc notable - alloc notable",
		rawText = UNNATURAL_INSTINCT_FOULBORN_RAW_TEXT,
		score = function(nodes, allocNodes)
			return scoreGainLoss(nodes, allocNodes, "Notable", "Notable")
		end,
	},
}

local scoreAllocPassives

local function buildDualModFoulbornVariants(itemName, itemType, baseMods, baseLabels, radiusVariant, altDamageVariants)
	local variants = { }
	local extra = { "Limited to: 1" }
	local function addVariant(label, dropdownLabel, mod1, mod2)
		local shortItemName = itemName:gsub("^The ", "")
		t_insert(variants, {
			name = itemName .. " (" .. label .. ")",
			dropdownLabel = shortItemName .. ": " .. dropdownLabel,
			family = itemName,
			scoreLabel = "alloc passives",
			rawText = buildJewelRawText(itemName, itemType, "Large", { mod1, mod2 }, extra),
			score = function(nodes, allocNodes)
				return scoreAllocPassives(nodes, allocNodes)
			end,
		})
	end

	addVariant(radiusVariant.label, radiusVariant.label .. " + " .. baseLabels[1], baseMods[1], radiusVariant.mod)
	for _, alt in ipairs(altDamageVariants) do
		addVariant(alt.label, alt.label .. " + " .. baseLabels[2], alt.mod, baseMods[2])
		addVariant(radiusVariant.label .. " + " .. alt.shortLabel, radiusVariant.label .. " + " .. alt.shortLabel, alt.mod, radiusVariant.mod)
	end
	return variants
end

local DREAMS_NIGHTMARES_FOULBORN_VARIANTS = { }
for _, variant in ipairs(buildDualModFoulbornVariants("The Red Dream", "Crimson Jewel", {
	"Gain (6-10)% of Fire Damage as Extra Chaos Damage",
	"Passives granting Fire Resistance or all Elemental Resistances in Radius also grant an equal chance to gain an Endurance Charge on Kill",
}, { "Extra Chaos", "Endurance on Kill" }, {
	label = "Max Life",
	mod = "Passives granting Fire Resistance or all Elemental Resistances in Radius also grant increased Maximum Life at 50% of its value",
}, {
	{ label = "Chaos Res per Endurance", shortLabel = "Chaos Res", mod = "+4% to Chaos Resistance per Endurance Charge" },
	{ label = "Fire Lucky", shortLabel = "Fire Lucky", mod = "Fire Damage with Hits is Lucky if you've Blocked an Attack Recently" },
})) do
	t_insert(DREAMS_NIGHTMARES_FOULBORN_VARIANTS, variant)
end
for _, variant in ipairs(buildDualModFoulbornVariants("The Red Nightmare", "Crimson Jewel", {
	"Gain (6-10)% of Fire Damage as Extra Chaos Damage",
	"Passives granting Fire Resistance or all Elemental Resistances in Radius also grant Chance to Block Attack Damage at 50% of its value",
}, { "Extra Chaos", "Block" }, {
	label = "Fire Conv to Chaos",
	mod = "Passives granting Fire Resistance or all Elemental Resistances in Radius also grant Fire Damage Converted to Chaos Damage at 100% of its value",
}, {
	{ label = "Chaos Res per Endurance", shortLabel = "Chaos Res", mod = "+4% to Chaos Resistance per Endurance Charge" },
	{ label = "Fire Lucky", shortLabel = "Fire Lucky", mod = "Fire Damage with Hits is Lucky if you've Blocked an Attack Recently" },
})) do
	t_insert(DREAMS_NIGHTMARES_FOULBORN_VARIANTS, variant)
end
for _, variant in ipairs(buildDualModFoulbornVariants("The Green Dream", "Viridian Jewel", {
	"Gain (6-10)% of Cold Damage as Extra Chaos Damage",
	"Passives granting Cold Resistance or all Elemental Resistances in Radius also grant an equal chance to gain a Frenzy Charge on Kill",
}, { "Extra Chaos", "Frenzy on Kill" }, {
	label = "Max Mana",
	mod = "Passives granting Cold Resistance or all Elemental Resistances in Radius also grant increased Maximum Mana at 75% of its value",
}, {
	{ label = "Move Speed per Frenzy", shortLabel = "Move Speed", mod = "1% increased Movement Speed per Frenzy Charge" },
	{ label = "Cold Lucky", shortLabel = "Cold Lucky", mod = "Cold Damage with Hits is Lucky if you've Suppressed Spell Damage Recently" },
})) do
	t_insert(DREAMS_NIGHTMARES_FOULBORN_VARIANTS, variant)
end
for _, variant in ipairs(buildDualModFoulbornVariants("The Green Nightmare", "Viridian Jewel", {
	"Gain (6-10)% of Cold Damage as Extra Chaos Damage",
	"Passives granting Cold Resistance or all Elemental Resistances in Radius also grant Chance to Suppress Spell Damage at 70% of its value",
}, { "Extra Chaos", "Suppress" }, {
	label = "Cold Conv to Chaos",
	mod = "Passives granting Cold Resistance or all Elemental Resistances in Radius also grant Cold Damage Converted to Chaos Damage at 100% of its value",
}, {
	{ label = "Move Speed per Frenzy", shortLabel = "Move Speed", mod = "1% increased Movement Speed per Frenzy Charge" },
	{ label = "Cold Lucky", shortLabel = "Cold Lucky", mod = "Cold Damage with Hits is Lucky if you've Suppressed Spell Damage Recently" },
})) do
	t_insert(DREAMS_NIGHTMARES_FOULBORN_VARIANTS, variant)
end
for _, variant in ipairs(buildDualModFoulbornVariants("The Blue Dream", "Cobalt Jewel", {
	"Gain (6-10)% of Lightning Damage as Extra Chaos Damage",
	"Passives granting Lightning Resistance or all Elemental Resistances in Radius also grant an equal chance to gain a Power Charge on Kill",
}, { "Extra Chaos", "Power on Kill" }, {
	label = "Max ES",
	mod = "Passives granting Lightning Resistance or all Elemental Resistances in Radius also grant increased Maximum Energy Shield at 75% of its value",
}, {
	{ label = "Crit Multi per Power Charge", shortLabel = "Crit Multi", mod = "+3% to Critical Strike Multiplier per Power Charge" },
	{ label = "Lightning Lucky", shortLabel = "Lightning Lucky", mod = "Lightning Damage with Hits is Lucky if you've Blocked Spell Damage Recently" },
})) do
	t_insert(DREAMS_NIGHTMARES_FOULBORN_VARIANTS, variant)
end
for _, variant in ipairs(buildDualModFoulbornVariants("The Blue Nightmare", "Cobalt Jewel", {
	"Gain (6-10)% of Lightning Damage as Extra Chaos Damage",
	"Passives granting Lightning Resistance or all Elemental Resistances in Radius also grant Chance to Block Spell Damage at 50% of its value",
}, { "Extra Chaos", "Spell Block" }, {
	label = "Lightning Conv to Chaos",
	mod = "Passives granting Lightning Resistance or all Elemental Resistances in Radius also grant Lightning Damage Converted to Chaos Damage at 100% of its value",
}, {
	{ label = "Crit Multi per Power Charge", shortLabel = "Crit Multi", mod = "+3% to Critical Strike Multiplier per Power Charge" },
	{ label = "Lightning Lucky", shortLabel = "Lightning Lucky", mod = "Lightning Damage with Hits is Lucky if you've Blocked Spell Damage Recently" },
})) do
	t_insert(DREAMS_NIGHTMARES_FOULBORN_VARIANTS, variant)
end

local function makeVariantDropdownEntry(variant)
	local label = variant.dropdownLabel or variant.name
	if label == variant.name then
		return label
	end
	return {
		label = label,
		searchFilter = variant.name,
	}
end

-- Stats available for LOM impact calculation
local IMPACT_STATS = {
	{ field = "FullDPS",      label = "Full DPS" },
	{ field = "CombinedDPS",  label = "Combined DPS" },
	{ field = "Life",         label = "Life" },
	{ field = "EnergyShield", label = "Energy Shield" },
	{ field = "Armour",       label = "Armour" },
	{ field = "Evasion",      label = "Evasion" },
	{ field = "BlockChance",            label = "Attack Block" },
	{ field = "SpellBlockChance",       label = "Spell Block" },
	{ field = "SpellSuppressionChance", label = "Spell Suppress" },
	{ field = "TotalEHP",     label = "Total EHP" },
	{ field = "Mana",         label = "Mana" },
}

local CONNECTIONLESS_COMPUTE_METHODS = {
	{ id = "fast", label = "Fast" },
	{ id = "simulated_greedy", label = "Simulated" },
}

local function findConnectionlessComputeMethod(methodId)
	for _, method in ipairs(CONNECTIONLESS_COMPUTE_METHODS) do
		if method.id == methodId then
			return method
		end
	end
	return CONNECTIONLESS_COMPUTE_METHODS[1]
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Jewel preview data (formatted TextListControl lines per jewel)
-- ─────────────────────────────────────────────────────────────────────────────

local COL_UNIQUE = "^xAF6025"
local COL_MOD    = "^7"
local COL_META   = "^8"
local COL_NEG    = "^1"

local function previewHeader(name, itemType, radius, extra, isFoulborn)
	local prefix = isFoulborn and "Foulborn " or ""
	radius = radius or "?"
	local lines = {
		{ height = 20, [1] = COL_UNIQUE .. prefix .. name },
		{ height = 16, [1] = COL_META   .. itemType },
		{ height = 6,  [1] = "" },
		{ height = 16, [1] = COL_META .. "Radius: " .. radius },
	}
	if extra then
		for _, e in ipairs(extra) do
			t_insert(lines, { height = 16, [1] = COL_META .. e })
		end
	end
	t_insert(lines, { height = 6, [1] = "" })
	return lines
end

local function previewFromRawText(rawText, isFoulborn, displayName, extraPreviewMeta)
	local rawLines = { }
	for line in rawText:gmatch("[^\n]+") do
		t_insert(rawLines, line)
	end
	local itemName = displayName or rawLines[1] or "Unknown Jewel"
	local itemType = rawLines[2] or "Jewel"
	local radius = "?"
	local extra = { }
	local mods = { }
	for i = 3, #rawLines do
		local line = rawLines[i]
		if line:match("^Radius:%s+") then
			radius = line:gsub("^Radius:%s+", "")
		elseif line:match("^Limited to:") or line:match("^Source:") or line:match("^League:") or line:match("^Upgrade:") then
			t_insert(extra, line)
		else
			t_insert(mods, line)
		end
	end
	local lines = previewHeader(itemName, itemType, radius, extra, isFoulborn)
	if extraPreviewMeta then
		for _, meta in ipairs(extraPreviewMeta) do
			t_insert(lines, { height = 16, [1] = COL_META .. meta })
		end
		t_insert(lines, { height = 6, [1] = "" })
	end
	for _, mod in ipairs(mods) do
		local col = mod:match("^%-") and COL_NEG or COL_MOD
		t_insert(lines, { height = 16, [1] = col .. mod })
	end
	return lines
end

local jewelPreviewFn  -- forward-declare so group functions can reference it by upvalue
jewelPreviewFn = {
	["The Light of Meaning"] = function(variant, isFoulborn)
		local lines = previewHeader("The Light of Meaning", "Prismatic Jewel", "Large",
			{ "Limited to: 1", "Source: King of The Mists" }, isFoulborn)
		if variant then
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Passive Skills in Radius also grant:" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "  " .. variant.mod })
		else
			for _, v in ipairs(LIGHT_OF_MEANING_VARIANTS) do
				t_insert(lines, { height = 14, [1] = COL_META .. "  " .. v.name .. ": " .. v.mod })
			end
		end
		return lines
	end,

	["Might of the Meek"] = function(variant, isFoulborn)
		if isFoulborn and variant then
			local lines = previewHeader("Might of the Meek", "Crimson Jewel", variant.radiusLabel, nil, isFoulborn)
			t_insert(lines, { height = 16, [1] = COL_MOD .. variant.effect .. " increased Effect of non-Keystone" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Passive Skills in Radius" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Notable Passive Skills in Radius grant nothing" })
			return lines
		else
			local lines = previewHeader("Might of the Meek", "Crimson Jewel", "Large", nil, isFoulborn)
			t_insert(lines, { height = 16, [1] = COL_MOD .. "50% increased Effect of non-Keystone" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Passive Skills in Radius" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Notable Passive Skills in Radius grant nothing" })
		end
		return lines
	end,

	["Unnatural Instinct"] = function(variant, isFoulborn)
		if isFoulborn and variant and variant.rawText then
			return previewFromRawText(variant.rawText, isFoulborn, "Unnatural Instinct (" .. variant.name .. ")")
		end
		local lines = previewHeader("Unnatural Instinct", "Viridian Jewel", "Small",
			{ "Limited to: 1" }, isFoulborn)
		if isFoulborn then
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Allocated Notable Passive Skills in" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Radius grant nothing" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Grants all bonuses of Unallocated" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Notable Passive Skills in Radius" })
		else
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Allocated Small Passive Skills in" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Radius grant nothing" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Grants all bonuses of Unallocated" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Small Passive Skills in Radius" })
		end
		return lines
	end,

	["Inspired Learning"] = function(variant, isFoulborn)
		if isFoulborn and variant and variant.rawText then
			return previewFromRawText(variant.rawText, isFoulborn, "Inspired Learning (" .. variant.name .. ")")
		end
		local lines = previewHeader("Inspired Learning", "Crimson Jewel", "Small", nil, isFoulborn)
		t_insert(lines, { height = 16, [1] = COL_MOD .. "With 4 Notables Allocated in Radius," })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "When you Kill a Rare monster, you gain" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "1 of its Modifiers for 20 seconds" })
		return lines
	end,

	["Anatomical Knowledge"] = function(isFoulborn)
		local lines = previewHeader("Anatomical Knowledge", "Cobalt Jewel", "Large",
			{ "Source: No longer obtainable" }, isFoulborn)
		t_insert(lines, { height = 16, [1] = COL_MOD .. "(6-8)% increased maximum Life" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Adds 1 to Maximum Life per 3" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Intelligence Allocated in Radius" })
		return lines
	end,

	["Lioneye's Fall"] = function(isFoulborn)
		local lines = previewHeader("Lioneye's Fall", "Viridian Jewel", "Medium", nil, isFoulborn)
		if isFoulborn then
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Increases and Reductions to Evasion Rating" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "in Radius are Transformed to apply to Armour" })
		else
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Melee and Melee Weapon Type modifiers" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "in Radius are Transformed to Bow Modifiers" })
		end
		return lines
	end,

	["Intuitive Leap"] = function(isFoulborn)
		local radius = isFoulborn and "Massive" or "Small"
		local lines = previewHeader("Intuitive Leap", "Viridian Jewel", radius, nil, isFoulborn)
		if isFoulborn then
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Keystone Passive Skills in Radius can be" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Allocated without being connected to your tree" })
		else
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives in Radius can be Allocated" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "without being connected to your tree" })
		end
		return lines
	end,

	["Tempered & Transcendent"] = function(variant, isFoulborn)
		if variant and variant.rawText then
			return previewFromRawText(variant.rawText, isFoulborn, variant.name)
		end
		local lines = previewHeader("Tempered & Transcendent", "Unique Jewel", "Medium", nil, isFoulborn)
		t_insert(lines, { height = 14, [1] = COL_META .. "Tempered Flesh / Transcendent Flesh" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Tempered Mind / Transcendent Mind" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Tempered Spirit / Transcendent Spirit" })
		return lines
	end,

	["Split Personality"] = function(variant, isFoulborn)
		if variant and variant.rawText then
			return previewFromRawText(variant.rawText, isFoulborn, "Split Personality (" .. variant.name .. ")")
		end
		local lines = previewHeader("Split Personality", "Crimson Jewel", "Variable",
			{ "Limited to: 2", "Source: Drops from the Simulacrum Encounter" }, isFoulborn)
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Socket effect scales with distance to class start" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Variants: Strength, Dexterity, Intelligence, Life" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Mana, Energy Shield, Armour, Evasion, Accuracy" })
		return lines
	end,

	["Impossible Escape"] = function(variant, isFoulborn)
		if variant and variant.rawText then
			return previewFromRawText(variant.rawText, isFoulborn, "Impossible Escape (" .. variant.name .. ")")
		end
		local lines = previewHeader("Impossible Escape", "Viridian Jewel", "Small",
			{ "Limited to: 1", "Source: Drops from The Maven (Uber)" }, isFoulborn)
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Passive Skills in radius of the chosen" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Keystone can be allocated without connection" })
		return lines
	end,

	["Energy From Within"] = function(isFoulborn)
		local lines = previewHeader("Energy From Within", "Cobalt Jewel", "Large", nil, isFoulborn)
		t_insert(lines, { height = 16, [1] = COL_MOD .. "3% increased maximum Energy Shield" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Life mods in Radius apply to Energy Shield" })
		return lines
	end,

	["Healthy Mind"] = function(isFoulborn)
		local lines = previewHeader("Healthy Mind", "Cobalt Jewel", "Large",
			{ "Limited to: 1" }, isFoulborn)
		t_insert(lines, { height = 16, [1] = COL_MOD .. "15% increased maximum Mana" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Life mods in Radius apply to Mana at 200%" })
		return lines
	end,

	["Energised Armour"] = function(isFoulborn)
		local lines = previewHeader("Energised Armour", "Crimson Jewel", "Large", nil, isFoulborn)
		t_insert(lines, { height = 16, [1] = COL_MOD .. "15% increased Armour" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "ES mods in Radius apply to Armour at 200%" })
		return lines
	end,

	["Brute Force Solution"] = function(isFoulborn)
		local lines = previewHeader("Brute Force Solution", "Cobalt Jewel", "Large", nil, isFoulborn)
		t_insert(lines, { height = 16, [1] = COL_MOD .. "+16 to Intelligence" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Strength from Passives -> Intelligence" })
		return lines
	end,

	["Careful Planning"] = function(isFoulborn)
		local lines = previewHeader("Careful Planning", "Viridian Jewel", "Large", nil, isFoulborn)
		t_insert(lines, { height = 16, [1] = COL_MOD .. "+16 to Dexterity" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Intelligence from Passives -> Dexterity" })
		return lines
	end,

	["Efficient Training"] = function(isFoulborn)
		local lines = previewHeader("Efficient Training", "Crimson Jewel", "Large", nil, isFoulborn)
		t_insert(lines, { height = 16, [1] = COL_MOD .. "+16 to Strength" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Intelligence from Passives -> Strength" })
		return lines
	end,

	["Fertile Mind"] = function(isFoulborn)
		local lines = previewHeader("Fertile Mind", "Cobalt Jewel", "Large", nil, isFoulborn)
		t_insert(lines, { height = 16, [1] = COL_MOD .. "+16 to Intelligence" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Dexterity from Passives -> Intelligence" })
		return lines
	end,

	["Fluid Motion"] = function(isFoulborn)
		local lines = previewHeader("Fluid Motion", "Viridian Jewel", "Large", nil, isFoulborn)
		t_insert(lines, { height = 16, [1] = COL_MOD .. "+16 to Dexterity" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Strength from Passives -> Dexterity" })
		return lines
	end,

	["Inertia"] = function(isFoulborn)
		local lines = previewHeader("Inertia", "Crimson Jewel", "Large", nil, isFoulborn)
		t_insert(lines, { height = 16, [1] = COL_MOD .. "+16 to Strength" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Dexterity from Passives -> Strength" })
		return lines
	end,

	["Combat Focus (Crimson)"] = function(isFoulborn)
		local lines = previewHeader("Combat Focus", "Crimson Jewel", "Medium",
			{ "Limited to: 2", "Source: Vendor Recipe" }, isFoulborn)
		t_insert(lines, { height = 16, [1] = COL_MOD .. "10% increased Elemental Damage" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Prismatic Skills lose Cold" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "with 40 total Str+Int in Radius" })
		return lines
	end,

	["Combat Focus (Cobalt)"] = function(isFoulborn)
		local lines = previewHeader("Combat Focus", "Cobalt Jewel", "Medium",
			{ "Limited to: 2", "Source: Vendor Recipe" }, isFoulborn)
		t_insert(lines, { height = 16, [1] = COL_MOD .. "10% increased Elemental Damage" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Prismatic Skills lose Fire" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "with 40 total Int+Dex in Radius" })
		return lines
	end,

	["Combat Focus (Viridian)"] = function(isFoulborn)
		local lines = previewHeader("Combat Focus", "Viridian Jewel", "Medium",
			{ "Limited to: 2", "Source: Vendor Recipe" }, isFoulborn)
		t_insert(lines, { height = 16, [1] = COL_MOD .. "10% increased Elemental Damage" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Prismatic Skills lose Lightning" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "with 40 total Dex+Str in Radius" })
		return lines
	end,

	["Attribute Conversion"] = function(variant, isFoulborn)
		if variant and jewelPreviewFn[variant.name] then
			return jewelPreviewFn[variant.name](isFoulborn)
		end
		local lines = previewHeader("Attribute Conversion", "Corrupted Jewel", "Large", nil, isFoulborn)
		t_insert(lines, { height = 14, [1] = COL_META .. "Brute Force Solution: Str -> Int" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Careful Planning:     Int -> Dex" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Efficient Training:   Int -> Str" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Fertile Mind:         Dex -> Int" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Fluid Motion:         Str -> Dex" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Inertia:              Dex -> Str" })
		return lines
	end,

	["Stat Conversion"] = function(variant, isFoulborn)
		if variant and jewelPreviewFn[variant.name] then
			return jewelPreviewFn[variant.name](isFoulborn)
		end
		local lines = previewHeader("Stat Conversion", "Corrupted Jewel", "Large", nil, isFoulborn)
		t_insert(lines, { height = 14, [1] = COL_META .. "Energy From Within: Life -> Energy Shield" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Healthy Mind:       Life -> Mana (200%)" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Energised Armour:   ES   -> Armour (200%)" })
		return lines
	end,

	["Combat Focus"] = function(variant, isFoulborn)
		if variant and jewelPreviewFn[variant.name] then
			return jewelPreviewFn[variant.name](isFoulborn)
		end
		local lines = previewHeader("Combat Focus", "Jewel", "Medium",
			{ "Limited to: 2", "Source: Vendor Recipe" }, isFoulborn)
		t_insert(lines, { height = 14, [1] = COL_META .. "Crimson:  lose Cold    (Str+Int >= 40)" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Cobalt:   lose Fire    (Int+Dex >= 40)" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Viridian: lose Lightning (Dex+Str >= 40)" })
		return lines
	end,

	["Dreams & Nightmares"] = function(variant, isFoulborn)
		if variant and variant.rawText then
			local extraPreviewMeta = nil
			if isFoulborn and variant.family then
				extraPreviewMeta = { "Family: " .. variant.family:gsub("^The ", "") }
			end
			return previewFromRawText(variant.rawText, isFoulborn, variant.name, extraPreviewMeta)
		end
		if variant and jewelPreviewFn[variant.name] then
			return jewelPreviewFn[variant.name](isFoulborn)
		end
		local lines = previewHeader("Dreams & Nightmares", "Unique Jewel", "Large", nil, isFoulborn)
		if isFoulborn then
			t_insert(lines, { height = 14, [1] = COL_META .. "The Red Dream:       Fire Res -> Max Life" })
			t_insert(lines, { height = 14, [1] = COL_META .. "The Red Nightmare:   Fire Res -> Chaos Conv" })
			t_insert(lines, { height = 14, [1] = COL_META .. "The Green Dream:     Cold Res -> Max Mana" })
			t_insert(lines, { height = 14, [1] = COL_META .. "The Green Nightmare: Cold Res -> Chaos Conv" })
			t_insert(lines, { height = 14, [1] = COL_META .. "The Blue Dream:      Lightning Res -> Max ES" })
			t_insert(lines, { height = 14, [1] = COL_META .. "The Blue Nightmare:  Lightning Res -> Chaos Conv" })
		else
			t_insert(lines, { height = 14, [1] = COL_META .. "The Red Dream:       Fire Res -> Endurance on Kill" })
			t_insert(lines, { height = 14, [1] = COL_META .. "The Red Nightmare:   Fire Res -> Block" })
			t_insert(lines, { height = 14, [1] = COL_META .. "The Green Dream:     Cold Res -> Frenzy on Kill" })
			t_insert(lines, { height = 14, [1] = COL_META .. "The Green Nightmare: Cold Res -> Suppress" })
			t_insert(lines, { height = 14, [1] = COL_META .. "The Blue Dream:      Lightning Res -> Power on Kill" })
			t_insert(lines, { height = 14, [1] = COL_META .. "The Blue Nightmare:  Lightning Res -> Spell Block" })
		end
		return lines
	end,

	["The Red Dream"] = function(isFoulborn)
		local lines = previewHeader("The Red Dream", "Crimson Jewel", "Large", nil, isFoulborn)
		if isFoulborn then
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives granting Fire/All Res in Radius" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "also grant increased Maximum Life at 50%" })
		else
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives granting Fire/All Res in Radius" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "also grant Endurance Charge on Kill" })
		end
		return lines
	end,

	["The Red Nightmare"] = function(isFoulborn)
		local lines = previewHeader("The Red Nightmare", "Crimson Jewel", "Large", nil, isFoulborn)
		if isFoulborn then
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives granting Fire/All Res in Radius" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "also grant Fire Damage -> Chaos Conv at 100%" })
		else
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives granting Fire/All Res in Radius" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "also grant Chance to Block at 50%" })
		end
		return lines
	end,

	["The Green Dream"] = function(isFoulborn)
		local lines = previewHeader("The Green Dream", "Viridian Jewel", "Large", nil, isFoulborn)
		if isFoulborn then
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives granting Cold/All Res in Radius" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "also grant increased Maximum Mana at 75%" })
		else
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives granting Cold/All Res in Radius" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "also grant Frenzy Charge on Kill" })
		end
		return lines
	end,

	["The Green Nightmare"] = function(isFoulborn)
		local lines = previewHeader("The Green Nightmare", "Viridian Jewel", "Large", nil, isFoulborn)
		if isFoulborn then
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives granting Cold/All Res in Radius" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "also grant Cold Damage -> Chaos Conv at 100%" })
		else
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives granting Cold/All Res in Radius" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "also grant Chance to Suppress at 70%" })
		end
		return lines
	end,

	["The Blue Dream"] = function(isFoulborn)
		local lines = previewHeader("The Blue Dream", "Cobalt Jewel", "Large", nil, isFoulborn)
		if isFoulborn then
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives granting Lightning/All Res in Radius" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "also grant increased Maximum ES at 75%" })
		else
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives granting Lightning/All Res in Radius" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "also grant Power Charge on Kill" })
		end
		return lines
	end,

	["The Blue Nightmare"] = function(isFoulborn)
		local lines = previewHeader("The Blue Nightmare", "Cobalt Jewel", "Large", nil, isFoulborn)
		if isFoulborn then
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives granting Lightning/All Res in Radius" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "also grant Lightning Damage -> Chaos Conv at 100%" })
		else
			t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives granting Lightning/All Res in Radius" })
			t_insert(lines, { height = 16, [1] = COL_MOD .. "also grant Spell Block at 50%" })
		end
		return lines
	end,

	["Thread of Hope"] = function(ringName, isFoulborn)
		local ring = ringName or "?"
		local lines = previewHeader("Thread of Hope", "Crimson Jewel", "Variable",
			{ "Source: Drops from Sirus, Awakener of Worlds" }, isFoulborn)
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Only affects Passives in " .. ring .. " Ring" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Passive Skills in Radius can be Allocated" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "without being connected to your tree" })
		t_insert(lines, { height = 6,  [1] = "" })
		t_insert(lines, { height = 16, [1] = COL_NEG  .. "-(20-10)% to all Elemental Resistances" })
		return lines
	end,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Build jewel socket list
-- ─────────────────────────────────────────────────────────────────────────────

function RadiusJewelFinderClass:buildJewelSockets(largeRadiusIndex)
	local treeData  = self.build.spec.tree
	local allocNodes = self.build.spec.allocNodes
	local sockets = { }
	for socketId, socketData in pairs(self.build.spec.nodes) do
		if socketData.isJewelSocket and socketData.name ~= "Charm Socket" then
			local keystone = "Unknown"
			local minDist = m_huge
			local socketNode = treeData.nodes[socketId]
			if socketNode and socketNode.nodesInRadius and socketNode.nodesInRadius[largeRadiusIndex] then
				for _, n in pairs(socketNode.nodesInRadius[largeRadiusIndex]) do
					if n.isKeystone then
						local dx = n.x - socketData.x
						local dy = n.y - socketData.y
						local d = dx * dx + dy * dy
						if d < minDist then keystone = n.dn or n.name or "Unknown"; minDist = d end
					end
				end
			end
			local prefix = allocNodes[socketId] and "# " or ""
			local pd = socketData.pathDist or 0
			local classStartDist = self:getSocketDistanceToClassStart(socketId)
			local distStr = (not allocNodes[socketId] and pd < 999) and s_format(" [+%d]", pd) or ""
			local label = prefix .. keystone .. " (" .. socketId .. ")" .. distStr
				t_insert(sockets, { label = label, id = socketId, pathDist = pd, classStartDist = classStartDist })
		end
	end
	t_sort(sockets, function(a, b) return a.label < b.label end)
	return sockets
end

-- ─────────────────────────────────────────────────────────────────────────────
-- LOM variant impact: equip each variant, rebuild, measure stat delta
-- ─────────────────────────────────────────────────────────────────────────────

local function progressTick(progress, done, total, label)
	if progress and progress.tick then
		progress:tick(done, total, label)
	end
end

local function progressChild(progress, startFraction, spanFraction)
	if progress and progress.child then
		return progress:child(startFraction, spanFraction)
	end
	return progress
end

local function buildDisplayedConnectionlessPlans(result, socketBasePoints, baseline)
	if not result.planSteps or #result.planSteps == 0 then
		return { result }
	end
	local displayedPlans = { }
	local bestPctPerPoint = -math.huge
	for _, step in ipairs(result.planSteps) do
		local totalPoints = socketBasePoints + (step.addedNodeCount or 0)
		local pct = baseline ~= 0 and (step.delta / baseline * 100) or 0
		local pctPerPoint = totalPoints > 0 and (pct / totalPoints) or pct
		if pctPerPoint > bestPctPerPoint + 1e-9 then
			t_insert(displayedPlans, step)
			bestPctPerPoint = pctPerPoint
		end
	end
	local finalPlan = result
	local lastDisplayed = displayedPlans[#displayedPlans]
	if not lastDisplayed or (lastDisplayed.addedNodeCount or 0) ~= (finalPlan.addedNodeCount or 0) then
		t_insert(displayedPlans, finalPlan)
	end
	return displayedPlans
end

function RadiusJewelFinderClass:computeVariantImpact(socketId, statField, progress)
	local itemsTab = self.build.itemsTab
	local calcsTab = self.build.calcsTab

	-- CalcSetup reads jewels from slot.selItemId, not spec.jewels
	local slot = itemsTab.sockets[socketId]
	if not slot then return { }, 0 end

	-- Save current state
	local prevSelItemId = slot.selItemId

	-- Baseline: no jewel at this socket
	slot.selItemId = 0
	self.build.spec.jewels[socketId] = 0
	self.build.spec:BuildAllDependsAndPaths()
	calcsTab:BuildOutput()
	local baseline = calcsTab.mainOutput[statField] or 0
	local baselineOutput = copyTableSafe(calcsTab.mainOutput, false, true)

	local variantResults = { }

	for i, variant in ipairs(LIGHT_OF_MEANING_VARIANTS) do
		progressTick(progress, i, #LIGHT_OF_MEANING_VARIANTS, variant.name)
		local text = LOM_RAW_TEXT
		local item = new("Item", "Rarity: Unique\n" .. text)
		item.variant = i
		item:BuildModList()
		itemsTab:AddItem(item, true)
		slot.selItemId = item.id
		self.build.spec.jewels[socketId] = item.id

			local value = 0
			local compareOutput
			local ok, err = pcall(function()
				self.build.spec:BuildAllDependsAndPaths()
				calcsTab:BuildOutput()
				value = calcsTab.mainOutput[statField] or 0
				compareOutput = copyTableSafe(calcsTab.mainOutput, false, true)
			end)

		-- Cleanup: unequip then remove from items tab
		slot.selItemId = prevSelItemId
		self.build.spec.jewels[socketId] = prevSelItemId
		itemsTab.items[item.id] = nil
		for idx, id in ipairs(itemsTab.itemOrderList) do
			if id == item.id then
				table.remove(itemsTab.itemOrderList, idx)
				break
			end
		end

		if not ok then
			error(err)
		end

			t_insert(variantResults, {
				variant    = variant,
				variantIdx = i,
				value      = value,
				delta      = value - baseline,
				baseOutput = baselineOutput,
				compareOutput = compareOutput,
			})
		end

	t_sort(variantResults, function(a, b) return a.delta > b.delta end)
	return variantResults, baseline
end

-- Compute jewel impact across all empty sockets (for non-variant jewels)
function RadiusJewelFinderClass:computeSocketImpact(sockets, rawText, statField, isFoulborn, progress, maxTotalPoints)
	local calcFunc, baseOutput = self.build.calcsTab:GetMiscCalculator()
	local realBaseline = baseOutput[statField] or 0

	local results = { }
	for socketIndex, socket in ipairs(sockets) do
		progressTick(progress, socketIndex - 1, #sockets, socket.label)
		local slot = self.build.itemsTab.sockets[socket.id]
		if slot and slot.selItemId == 0 and (not maxTotalPoints or (socket.pathDist or 0) <= maxTotalPoints) then
			local socketNode = self.build.spec.nodes[socket.id]
			local slotName = "Jewel " .. tostring(socket.id)

			local emptyJewel = new("Item", "Rarity: Normal\nCobalt Jewel")
			emptyJewel:BuildModList()
			local baselineOutput = calcFunc({ 
				addNodes = { [socketNode] = true },
				repSlotName = slotName, 
				repItem = emptyJewel 
			})
			local baseline = baselineOutput[statField] or 0

			local text = rawText
			local item = new("Item", "Rarity: Unique\n" .. text)
			item:BuildModList()
			
			local output = calcFunc({ 
				addNodes = { [socketNode] = true },
				repSlotName = slotName, 
				repItem = item 
			})
			local value = output[statField] or 0

			t_insert(results, {
				socket = socket,
				value = value,
				delta = value - baseline,
				baseOutput = copyTableSafe(baselineOutput, false, true),
				compareOutput = copyTableSafe(output, false, true),
			})
		end
		progressTick(progress, socketIndex, #sockets, socket.label)
	end

	t_sort(results, function(a, b) return a.delta > b.delta end)
	return results, realBaseline
end

function RadiusJewelFinderClass:computeBestVariantSocketImpact(sockets, variants, statField, progress, maxTotalPoints)
	local calcFunc, baseOutput = self.build.calcsTab:GetMiscCalculator()
	local realBaseline = baseOutput[statField] or 0

	local results = { }
	for socketIndex, socket in ipairs(sockets) do
		progressTick(progress, socketIndex - 1, #sockets, socket.label)
		local socketProgress = progressChild(progress, (socketIndex - 1) / #sockets, 1 / #sockets)
		local slot = self.build.itemsTab.sockets[socket.id]
		if slot and slot.selItemId == 0 and (not maxTotalPoints or (socket.pathDist or 0) <= maxTotalPoints) then
			local socketNode = self.build.spec.nodes[socket.id]
			local slotName = "Jewel " .. tostring(socket.id)

			local emptyJewel = new("Item", "Rarity: Normal\nCobalt Jewel")
			emptyJewel:BuildModList()
			local baselineOutput = calcFunc({
				addNodes = { [socketNode] = true },
				repSlotName = slotName,
				repItem = emptyJewel
			})
			local baseline = baselineOutput[statField] or 0

			local bestResult
			for variantIdx, variant in ipairs(variants) do
				progressTick(socketProgress, variantIdx, #variants, socket.label .. " | " .. (variant.dropdownLabel or variant.name))
				local item = new("Item", "Rarity: Unique\n" .. variant.rawText)
				item:BuildModList()

				local output = calcFunc({
					addNodes = { [socketNode] = true },
					repSlotName = slotName,
					repItem = item
				})
				local value = output[statField] or 0
				local delta = value - baseline

				if not bestResult or delta > bestResult.delta then
					bestResult = {
						socket = socket,
						variant = variant,
						variantIdx = variantIdx,
						value = value,
						delta = delta,
						baseOutput = copyTableSafe(baselineOutput, false, true),
						compareOutput = copyTableSafe(output, false, true),
					}
				end
			end

			if bestResult then
				t_insert(results, bestResult)
			end
			progressTick(socketProgress, 1, 1, socket.label)
		end
	end

	t_sort(results, function(a, b)
		if a.delta ~= b.delta then
			return a.delta > b.delta
		end
		return (a.variant.dropdownLabel or a.variant.name) < (b.variant.dropdownLabel or b.variant.name)
	end)
	return results, realBaseline
end

local function isConnectionlessCandidateNode(node, keystoneOnly)
	if not node then
		return false
	end
	if node.type == "Socket" or node.type == "ClassStart" or node.type == "AscendClassStart" or node.type == "Mastery" then
		return false
	end
	if keystoneOnly then
		return node.type == "Keystone"
	end
	return true
end

local function getPassiveNodeLabel(node)
	return node.dn or node.name or tostring(node.id or "?")
end

local function buildChosenNodesSummary(nodes, variantLabel)
	local labels = { }
	for _, node in ipairs(nodes) do
		t_insert(labels, getPassiveNodeLabel(node))
	end
	t_sort(labels)
	local prefix = #labels == 1 and "1 node" or s_format("%d nodes", #labels)
	if #labels == 0 then
		return variantLabel and (variantLabel .. " | jewel only") or "jewel only"
	end
	local summary = labels[1]
	if #labels >= 2 then
		summary = summary .. ", " .. labels[2]
	end
	if #labels > 2 then
		summary = summary .. s_format(", +%d more", #labels - 2)
	end
	if variantLabel and variantLabel ~= "" then
		return s_format("%s | %s: %s", variantLabel, prefix, summary)
	end
	return s_format("%s: %s", prefix, summary)
end

local function copyNodeList(nodes)
	local out = { }
	for i, node in ipairs(nodes) do
		out[i] = node
	end
	return out
end

local function buildConnectionlessPlanStep(baseOutput, statField, value, compareOutput, chosenNodes, variantLabel)
	local snapshotNodes = copyNodeList(chosenNodes)
	return {
		value = value,
		delta = value - (baseOutput[statField] or 0),
		baseOutput = copyTableSafe(baseOutput, false, true),
		compareOutput = copyTableSafe(compareOutput, false, true),
		chosenNodes = snapshotNodes,
		addedNodeCount = #snapshotNodes,
		detailText = buildChosenNodesSummary(snapshotNodes, variantLabel),
	}
end

function RadiusJewelFinderClass:getSocketDistanceToClassStart(socketId)
	local spec = self.build.spec
	local socketNode = spec.nodes[socketId]
	if not socketNode then
		return 0
	end
	if socketNode.alloc and socketNode.connectedToStart then
		return socketNode.distanceToClassStart or 0
	end

	local targetNodeId = spec.curClass.startNodeId
	local nodeDistanceToRoot = { [socketNode.id] = 0 }
	local queue = { socketNode }
	local outIndex, inIndex = 1, 2
	while outIndex < inIndex do
		local node = queue[outIndex]
		outIndex = outIndex + 1
		local curDist = nodeDistanceToRoot[node.id] + 1
		for _, other in ipairs(node.linked) do
			if other.id == targetNodeId then
				return curDist - 1
			end
			if node.type ~= "Mastery"
			and other.type ~= "ClassStart"
			and other.type ~= "AscendClassStart"
			and not nodeDistanceToRoot[other.id]
			and (node.ascendancyName == other.ascendancyName or (nodeDistanceToRoot[node.id] == 0 and not other.ascendancyName)) then
				nodeDistanceToRoot[other.id] = curDist
				queue[inIndex] = other
				inIndex = inIndex + 1
			end
		end
	end

	return 0
end

function RadiusJewelFinderClass:collectConnectionlessCandidates(socketNode, options)
	local allocNodes = self.build.spec.allocNodes
	local candidates = { }
	local seen = { }
	local sourceNodes
	if options.collectNodes then
		sourceNodes = options.collectNodes(socketNode)
	else
		sourceNodes = socketNode and socketNode.nodesInRadius and options.radiusIndex and socketNode.nodesInRadius[options.radiusIndex]
	end
	if not sourceNodes then
		return candidates
	end
	for nodeId, node in pairs(sourceNodes) do
		if not seen[nodeId] and not allocNodes[nodeId] and isConnectionlessCandidateNode(node, options.keystoneOnly) then
			t_insert(candidates, node)
			seen[nodeId] = true
		end
	end
	t_sort(candidates, function(a, b)
		if a.type ~= b.type then
			if a.type == "Keystone" then
				return true
			end
			if b.type == "Keystone" then
				return false
			end
			if a.type == "Notable" then
				return true
			end
			if b.type == "Notable" then
				return false
			end
		end
		return getPassiveNodeLabel(a) < getPassiveNodeLabel(b)
	end)
	return candidates
end

function RadiusJewelFinderClass:computeConnectionlessSimulatedPlan(calcFunc, baseOutput, socketNode, slotName, item, statField, candidates, variantLabel, progressLabel, progress, maxAdditionalNodes)
	local addNodes = { [socketNode] = true }
	local function calculate(extraNode)
		local nextNodes = copyTable(addNodes, true)
		if extraNode then
			nextNodes[extraNode] = true
		end
		local output = calcFunc({
			addNodes = nextNodes,
			repSlotName = slotName,
			repItem = item,
		})
		return output, output[statField] or 0
	end

	local currentOutput, currentValue = calculate()
	local chosenNodes = { }
	local chosenNodeIds = { }
	if maxAdditionalNodes and maxAdditionalNodes <= 0 then
		return buildConnectionlessPlanStep(baseOutput, statField, currentValue, currentOutput, chosenNodes, variantLabel)
	end
	local planSteps = { }

	while true do
		if maxAdditionalNodes and #chosenNodes >= maxAdditionalNodes then
			break
		end
		local bestCandidate
		for candidateIndex, node in ipairs(candidates) do
			progressTick(progress, candidateIndex, #candidates, progressLabel)
			if not chosenNodeIds[node.id] then
				local output, value = calculate(node)
				local marginalDelta = value - currentValue
				if not bestCandidate
				or marginalDelta > bestCandidate.marginalDelta
				or (marginalDelta == bestCandidate.marginalDelta and getPassiveNodeLabel(node) < getPassiveNodeLabel(bestCandidate.node)) then
					bestCandidate = {
						node = node,
						output = output,
						value = value,
						marginalDelta = marginalDelta,
					}
				end
			end
		end
		if not bestCandidate or bestCandidate.marginalDelta <= 0 then
			break
		end
		chosenNodeIds[bestCandidate.node.id] = true
		addNodes[bestCandidate.node] = true
		t_insert(chosenNodes, bestCandidate.node)
		currentOutput = bestCandidate.output
		currentValue = bestCandidate.value
		t_insert(planSteps, buildConnectionlessPlanStep(baseOutput, statField, currentValue, currentOutput, chosenNodes, variantLabel))
	end

	local result = buildConnectionlessPlanStep(baseOutput, statField, currentValue, currentOutput, chosenNodes, variantLabel)
	result.planSteps = planSteps
	return result
end

function RadiusJewelFinderClass:computeConnectionlessFastPlan(calcFunc, baseOutput, socketNode, slotName, item, statField, candidates, variantLabel, deltaCache, progressLabel, progress, maxAdditionalNodes)
	local baseValue = baseOutput[statField] or 0
	local jewelOnlyOutput = calcFunc({
		addNodes = { [socketNode] = true },
		repSlotName = slotName,
		repItem = item,
	})
	local jewelOnlyValue = jewelOnlyOutput[statField] or 0
	if maxAdditionalNodes and maxAdditionalNodes <= 0 then
		local chosenNodes = { }
		return buildConnectionlessPlanStep(baseOutput, statField, jewelOnlyValue, jewelOnlyOutput, chosenNodes, variantLabel)
	end
	local scoredCandidates = { }
	for candidateIndex, node in ipairs(candidates) do
		progressTick(progress, candidateIndex, #candidates, progressLabel)
		local delta = deltaCache[node.id]
		if delta == nil then
			local output = calcFunc({
				addNodes = { [socketNode] = true, [node] = true },
				repSlotName = slotName,
				repItem = item,
			})
			delta = (output[statField] or 0) - jewelOnlyValue
			deltaCache[node.id] = delta
		end
		if delta > 0 then
			t_insert(scoredCandidates, {
				node = node,
				delta = delta,
			})
		end
	end
	t_sort(scoredCandidates, function(a, b)
		if a.delta ~= b.delta then
			return a.delta > b.delta
		end
		return getPassiveNodeLabel(a.node) < getPassiveNodeLabel(b.node)
	end)

	local chosenNodes = { }
	for i, entry in ipairs(scoredCandidates) do
		if maxAdditionalNodes and i > maxAdditionalNodes then
			break
		end
		t_insert(chosenNodes, entry.node)
	end
	local planSteps = { }

	local addNodes = { [socketNode] = true }
	local prefixNodes = { }
	for _, node in ipairs(chosenNodes) do
		t_insert(prefixNodes, node)
		addNodes[node] = true
		local prefixOutput = calcFunc({
			addNodes = addNodes,
			repSlotName = slotName,
			repItem = item,
		})
		local prefixValue = prefixOutput[statField] or 0
		t_insert(planSteps, buildConnectionlessPlanStep(baseOutput, statField, prefixValue, prefixOutput, prefixNodes, variantLabel))
	end
	local finalOutput = calcFunc({
		addNodes = addNodes,
		repSlotName = slotName,
		repItem = item,
	})
	local finalValue = finalOutput[statField] or 0

	local result = buildConnectionlessPlanStep(baseOutput, statField, finalValue, finalOutput, chosenNodes, variantLabel)
	result.planSteps = planSteps
	return result
end

function RadiusJewelFinderClass:computeIntuitiveLeapSocketImpact(sockets, statField, isFoulborn, methodId, planCache, progress, maxTotalPoints)
	local calcFunc, baseOutput = self.build.calcsTab:GetMiscCalculator()
	local realBaseline = baseOutput[statField] or 0
	local radiusLookup = { }
	for i, radius in ipairs(data.jewelRadius) do
		if radius.inner == 0 and not radiusLookup[radius.label] then
			radiusLookup[radius.label] = i
		end
	end

	local function collectMassiveNodes(socketNode)
		local nodes = { }
		if not socketNode or not socketNode.nodesInRadius then
			return nodes
		end
		for idx, radius in ipairs(data.jewelRadius) do
			if radius.outer <= 2400 and socketNode.nodesInRadius[idx] then
				for nodeId, node in pairs(socketNode.nodesInRadius[idx]) do
					nodes[nodeId] = node
				end
			end
		end
		return nodes
	end

	local candidateOptions = isFoulborn and {
		collectNodes = collectMassiveNodes,
		keystoneOnly = true,
	} or {
		radiusIndex = radiusLookup["Small"],
		keystoneOnly = false,
	}

	local results = { }
	for socketIndex, socket in ipairs(sockets) do
		progressTick(progress, socketIndex - 1, #sockets, socket.label)
		local socketProgress = progressChild(progress, (socketIndex - 1) / #sockets, 1 / #sockets)
		local slot = self.build.itemsTab.sockets[socket.id]
		if slot and slot.selItemId == 0 and (not maxTotalPoints or (socket.pathDist or 0) <= maxTotalPoints) then
			local socketNode = self.build.spec.tree.nodes[socket.id]
			local slotName = "Jewel " .. tostring(socket.id)
			local item = new("Item", "Rarity: Unique\n" .. (isFoulborn and INTUITIVE_LEAP_FOULBORN_RAW_TEXT or INTUITIVE_LEAP_RAW_TEXT))
			item:BuildModList()
			local candidates = self:collectConnectionlessCandidates(socketNode, candidateOptions)
			local maxAdditionalNodes = maxTotalPoints and math.max(maxTotalPoints - (socket.pathDist or 0), 0) or nil
			local result
			if methodId == "fast" then
				local cacheKey = s_format("IL|%s|%s|%d", statField, isFoulborn and "1" or "0", socket.id)
				planCache[cacheKey] = planCache[cacheKey] or { }
				result = self:computeConnectionlessFastPlan(calcFunc, baseOutput, socketNode, slotName, item, statField, candidates, nil, planCache[cacheKey], socket.label, socketProgress, maxAdditionalNodes)
			else
				result = self:computeConnectionlessSimulatedPlan(calcFunc, baseOutput, socketNode, slotName, item, statField, candidates, nil, socket.label, socketProgress, maxAdditionalNodes)
			end
			result.socket = socket
			t_insert(results, result)
			progressTick(socketProgress, 1, 1, socket.label)
		end
	end

	t_sort(results, function(a, b) return a.delta > b.delta end)
	return results, realBaseline
end

function RadiusJewelFinderClass:computeThreadOfHopeSocketImpact(sockets, statField, threadVariants, methodId, planCache, progress, maxTotalPoints)
	local calcFunc, baseOutput = self.build.calcsTab:GetMiscCalculator()
	local realBaseline = baseOutput[statField] or 0
	local results = { }

	for socketIndex, socket in ipairs(sockets) do
		progressTick(progress, socketIndex - 1, #sockets, socket.label)
		local socketProgress = progressChild(progress, (socketIndex - 1) / #sockets, 1 / #sockets)
		local slot = self.build.itemsTab.sockets[socket.id]
		if slot and slot.selItemId == 0 and (not maxTotalPoints or (socket.pathDist or 0) <= maxTotalPoints) then
			local socketNode = self.build.spec.tree.nodes[socket.id]
			local slotName = "Jewel " .. tostring(socket.id)
			local bestResult
			for variantIndex, threadVariant in ipairs(threadVariants) do
				local variantProgress = progressChild(socketProgress, (variantIndex - 1) / #threadVariants, 1 / #threadVariants)
				local item = new("Item", "Rarity: Unique\n" .. THREAD_OF_HOPE_RAW_TEXT)
				item.variant = variantIndex
				item:BuildModList()
				local candidates = self:collectConnectionlessCandidates(socketNode, {
					radiusIndex = threadVariant.radiusIndex,
				})
				local maxAdditionalNodes = maxTotalPoints and math.max(maxTotalPoints - (socket.pathDist or 0), 0) or nil
				local result
				if methodId == "fast" then
					local cacheKey = s_format("TOH|%s|%d|%d", statField, socket.id, variantIndex)
					planCache[cacheKey] = planCache[cacheKey] or { }
					result = self:computeConnectionlessFastPlan(calcFunc, baseOutput, socketNode, slotName, item, statField, candidates, threadVariant.name .. " Ring", planCache[cacheKey], socket.label .. " | " .. threadVariant.name .. " Ring", variantProgress, maxAdditionalNodes)
				else
					result = self:computeConnectionlessSimulatedPlan(calcFunc, baseOutput, socketNode, slotName, item, statField, candidates, threadVariant.name .. " Ring", socket.label .. " | " .. threadVariant.name .. " Ring", variantProgress, maxAdditionalNodes)
				end
				result.variant = threadVariant
				if not bestResult
				or result.delta > bestResult.delta
				or (result.delta == bestResult.delta and result.addedNodeCount < bestResult.addedNodeCount)
				or (result.delta == bestResult.delta and result.addedNodeCount == bestResult.addedNodeCount and threadVariant.radiusIndex < bestResult.variant.radiusIndex) then
					bestResult = result
				end
			end
			if bestResult then
				bestResult.socket = socket
				t_insert(results, bestResult)
			end
			progressTick(socketProgress, 1, 1, socket.label)
		end
	end

	t_sort(results, function(a, b)
		if a.delta ~= b.delta then
			return a.delta > b.delta
		end
		return a.variant.radiusIndex < b.variant.radiusIndex
	end)
	return results, realBaseline
end

function RadiusJewelFinderClass:computeSplitPersonalitySocketImpact(sockets, statField, variants, progress, maxTotalPoints)
	local calcFunc, baseOutput = self.build.calcsTab:GetMiscCalculator()
	local realBaseline = baseOutput[statField] or 0
	local results = { }

	for socketIndex, socket in ipairs(sockets) do
		progressTick(progress, socketIndex - 1, #sockets, socket.label)
		local socketProgress = progressChild(progress, (socketIndex - 1) / #sockets, 1 / #sockets)
		local slot = self.build.itemsTab.sockets[socket.id]
		if slot and slot.selItemId == 0 and (not maxTotalPoints or (socket.pathDist or 0) <= maxTotalPoints) then
			local socketNode = self.build.spec.nodes[socket.id]
			local slotName = "Jewel " .. tostring(socket.id)
			local splitDistance = socket.classStartDist or self:getSocketDistanceToClassStart(socket.id)
			local previousDistance = socketNode.distanceToClassStart

			local emptyJewel = new("Item", "Rarity: Normal\nCobalt Jewel")
			emptyJewel:BuildModList()
			socketNode.distanceToClassStart = splitDistance
			local baselineOutput = calcFunc({
				addNodes = { [socketNode] = true },
				repSlotName = slotName,
				repItem = emptyJewel,
			})
			local baseline = baselineOutput[statField] or 0

			local bestResult
			for variantIdx, variant in ipairs(variants) do
				progressTick(socketProgress, variantIdx, #variants, socket.label .. " | " .. variant.name)
				local item = new("Item", "Rarity: Unique\n" .. variant.rawText)
				item:BuildModList()
				local output = calcFunc({
					addNodes = { [socketNode] = true },
					repSlotName = slotName,
					repItem = item,
				})
				local value = output[statField] or 0
				local delta = value - baseline
				if not bestResult or delta > bestResult.delta then
					bestResult = {
						socket = socket,
						variant = variant,
						variantIdx = variantIdx,
						value = value,
						delta = delta,
						baseOutput = copyTableSafe(baselineOutput, false, true),
						compareOutput = copyTableSafe(output, false, true),
						detailText = s_format("Dist %d | %s", splitDistance, variant.name),
					}
				end
			end

			socketNode.distanceToClassStart = previousDistance
			if bestResult then
				bestResult.splitDistance = splitDistance
				t_insert(results, bestResult)
			end
			progressTick(socketProgress, 1, 1, socket.label)
		end
	end

	t_sort(results, function(a, b)
		if a.delta ~= b.delta then
			return a.delta > b.delta
		end
		return (a.splitDistance or 0) > (b.splitDistance or 0)
	end)
	return results, realBaseline
end

function RadiusJewelFinderClass:computeImpossibleEscapeSocketImpact(sockets, statField, variants, methodId, planCache, progress, maxTotalPoints)
	local calcFunc, baseOutput = self.build.calcsTab:GetMiscCalculator()
	local realBaseline = baseOutput[statField] or 0
	local results = { }
	local smallRadiusIndex
	for i, radius in ipairs(data.jewelRadius) do
		if radius.label == "Small" and radius.inner == 0 then
			smallRadiusIndex = i
			break
		end
	end

	local eligibleSockets = { }
	local groupedSockets = { }
	local groupedBudgets = { }
	for _, socket in ipairs(sockets) do
		local slot = self.build.itemsTab.sockets[socket.id]
		if slot and slot.selItemId == 0 and (not maxTotalPoints or (socket.pathDist or 0) <= maxTotalPoints) then
			t_insert(eligibleSockets, socket)
			local remainingBudget = maxTotalPoints and math.max(maxTotalPoints - (socket.pathDist or 0), 0) or -1
			if not groupedSockets[remainingBudget] then
				groupedSockets[remainingBudget] = { }
				t_insert(groupedBudgets, remainingBudget)
			end
			t_insert(groupedSockets[remainingBudget], socket)
		end
	end
	if #eligibleSockets == 0 then
		return results, realBaseline
	end

	t_sort(groupedBudgets, function(a, b) return a > b end)
	local representativeSocket = eligibleSockets[1]
	local representativeSocketNode = self.build.spec.tree.nodes[representativeSocket.id]
	local representativeSlotName = "Jewel " .. tostring(representativeSocket.id)
	local bestResultByBudget = { }
	local totalPlanCount = #groupedBudgets * #variants
	local currentPlanIndex = 0

	for _, remainingBudget in ipairs(groupedBudgets) do
		local bestResult
		for _, variant in ipairs(variants) do
			currentPlanIndex = currentPlanIndex + 1
			local planProgress = progressChild(progress, (currentPlanIndex - 1) / totalPlanCount, 1 / totalPlanCount)
			local keystoneNode = self.build.spec.tree.keystoneMap[variant.keystoneName]
			if keystoneNode and keystoneNode.nodesInRadius and keystoneNode.nodesInRadius[smallRadiusIndex] then
				local item = new("Item", "Rarity: Unique\n" .. variant.rawText)
				item:BuildModList()
				local candidates = self:collectConnectionlessCandidates(representativeSocketNode, {
					collectNodes = function()
						return keystoneNode.nodesInRadius[smallRadiusIndex]
					end,
				})
				local maxAdditionalNodes = remainingBudget >= 0 and remainingBudget or nil
				local result
				if methodId == "fast" then
					local cacheKey = s_format("IE|%s|%s", statField, variant.name)
					planCache[cacheKey] = planCache[cacheKey] or { }
					result = self:computeConnectionlessFastPlan(calcFunc, baseOutput, representativeSocketNode, representativeSlotName, item, statField, candidates, variant.name, planCache[cacheKey], variant.name, planProgress, maxAdditionalNodes)
				else
					result = self:computeConnectionlessSimulatedPlan(calcFunc, baseOutput, representativeSocketNode, representativeSlotName, item, statField, candidates, variant.name, variant.name, planProgress, maxAdditionalNodes)
				end
				result.variant = variant
				if not bestResult
				or result.delta > bestResult.delta
				or (result.delta == bestResult.delta and result.addedNodeCount < bestResult.addedNodeCount)
				or (result.delta == bestResult.delta and result.addedNodeCount == bestResult.addedNodeCount and variant.name < bestResult.variant.name) then
					bestResult = result
				end
			end
		end
		bestResultByBudget[remainingBudget] = bestResult
	end

	for _, remainingBudget in ipairs(groupedBudgets) do
		local bestResult = bestResultByBudget[remainingBudget]
		if bestResult then
			for _, socket in ipairs(groupedSockets[remainingBudget]) do
				local projectedResult = copyTableSafe(bestResult, false, true)
				projectedResult.socket = socket
				t_insert(results, projectedResult)
			end
		end
	end

	t_sort(results, function(a, b)
		if a.delta ~= b.delta then
			return a.delta > b.delta
		end
		return a.variant.name < b.variant.name
	end)
	return results, realBaseline
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Jewel type definitions
-- ─────────────────────────────────────────────────────────────────────────────

-- Shared score: count allocated non-trivial passives in radius
scoreAllocPassives = function(nodes, allocNodes)
	local s = 0
	for nodeId, node in pairs(nodes) do
		if allocNodes[nodeId] and node.type ~= "Socket" and node.type ~= "ClassStart"
				and node.type ~= "AscendClassStart" and node.type ~= "Mastery" then
			s = s + 1
		end
	end
	return s
end

local function scoreUnallocPassives(nodes, allocNodes)
	local s = 0
	for nodeId, node in pairs(nodes) do
		if not allocNodes[nodeId] and node.type ~= "Socket" and node.type ~= "ClassStart"
				and node.type ~= "AscendClassStart" and node.type ~= "Mastery" then
			s = s + 1
		end
	end
	return s
end

local function buildJewelTypes(radiusIndexByLabel, isFoulborn)
	local mightOfTheMeek
	local inspiredLearning
	if isFoulborn then
		mightOfTheMeek = {
			name = "Might of the Meek",
			supportsFoulborn = true,
			scoreLabel = "alloc small passives",
			hasCompute = true,
			variants = {
				{
					name = "Medium Radius (75%)",
					radiusIndex = radiusIndexByLabel["Medium"],
					radiusLabel = "Medium",
					effect = "75%",
					rawText = MIGHT_OF_MEEK_FOULBORN_V1_RAW_TEXT,
				},
				{
					name = "Small Radius (100%)",
					radiusIndex = radiusIndexByLabel["Small"],
					radiusLabel = "Small",
					effect = "100%",
					rawText = MIGHT_OF_MEEK_FOULBORN_V2_RAW_TEXT,
				}
			},
			score = function(nodes, allocNodes)
				local s = 0
				for nodeId, node in pairs(nodes) do
					if allocNodes[nodeId] and node.type == "Normal" then
						s = s + 1
					end
				end
				return s
				end,
			}
		inspiredLearning = {
			name = "Inspired Learning",
			supportsFoulborn = true,
			hasCompute = true,
			scoreLabel = "no alloc notables",
			variants = {
				{
					name = "No allocated notables",
					dropdownLabel = "Large radius / no notables",
					radiusIndex = radiusIndexByLabel["Large"],
					rawText = INSPIRED_LEARNING_FOULBORN_LARGE_RAW_TEXT,
					scoreLabel = "no alloc notables",
					score = function(nodes, allocNodes)
						for nodeId, node in pairs(nodes) do
							if allocNodes[nodeId] and node.type == "Notable" then
								return 0
							end
						end
						return 1
					end,
				},
				{
					name = "Small passive threshold",
					dropdownLabel = "Small radius / 8-12 small passives",
					radiusIndex = radiusIndexByLabel["Small"],
					rawText = INSPIRED_LEARNING_FOULBORN_SMALL_RAW_TEXT,
					scoreLabel = "alloc small passives",
					score = function(nodes, allocNodes)
						local s = 0
						for nodeId, node in pairs(nodes) do
							if allocNodes[nodeId] and node.type == "Normal" then
								s = s + 1
							end
						end
						return s
					end,
				},
			},
		}
	else
		mightOfTheMeek = {
			name = "Might of the Meek",
			supportsFoulborn = true,
			radiusIndex = radiusIndexByLabel["Large"],
			scoreLabel = "alloc small passives",
			hasCompute = true,
			rawText = MIGHT_OF_MEEK_RAW_TEXT,
			score = function(nodes, allocNodes)
				local s = 0
				for nodeId, node in pairs(nodes) do
					if allocNodes[nodeId] and node.type == "Normal" then
						s = s + 1
					end
				end
					return s
				end,
			}
		inspiredLearning = {
			name = "Inspired Learning",
			supportsFoulborn = true,
			hasCompute = true,
			radiusIndex = radiusIndexByLabel["Small"],
			scoreLabel = "alloc notables",
			rawText = INSPIRED_LEARNING_RAW_TEXT,
			score = function(nodes, allocNodes)
				local s = 0
				for nodeId, node in pairs(nodes) do
					if allocNodes[nodeId] and node.type == "Notable" then
						s = s + 1
					end
				end
				return s
			end,
		}
	end

	local jewelTypes = { }
	t_insert(jewelTypes, {
		name = "The Light of Meaning",
		radiusIndex = radiusIndexByLabel["Large"],
		scoreLabel = "alloc passives",
		isLightOfMeaning = true,
		score = scoreAllocPassives,
	})
	t_insert(jewelTypes, mightOfTheMeek)
	t_insert(jewelTypes, {
		name = "Unnatural Instinct",
		supportsFoulborn = true,
		radiusIndex = radiusIndexByLabel["Small"],
		scoreLabel = isFoulborn and "unalloc notable - alloc notable" or "unalloc small - alloc small",
		hasCompute = true,
		rawText = isFoulborn and UNNATURAL_INSTINCT_FOULBORN_RAW_TEXT or UNNATURAL_INSTINCT_RAW_TEXT,
		variants = isFoulborn and UNNATURAL_INSTINCT_FOULBORN_VARIANTS or nil,
		score = function(nodes, allocNodes)
			local gained, lost = 0, 0
			local targetType = isFoulborn and "Notable" or "Normal"
			for nodeId, node in pairs(nodes) do
				if node.type == targetType then
					if allocNodes[nodeId] then lost = lost + 1
					else gained = gained + 1 end
				end
			end
			return gained - lost
		end,
	})
	t_insert(jewelTypes, inspiredLearning)
	t_insert(jewelTypes, {
		name = "Anatomical Knowledge",
		radiusIndex = radiusIndexByLabel["Large"],
		scoreLabel = "alloc passives",
		hasCompute = true,
		isLegacy = true,
		rawText = ANATOMICAL_KNOWLEDGE_RAW_TEXT,
		score = scoreAllocPassives,
	})
	t_insert(jewelTypes, {
		name = "Tempered & Transcendent",
		radiusIndex = radiusIndexByLabel["Medium"],
		scoreLabel = "attr in radius",
		hasCompute = true,
		score = function(nodes, allocNodes)
			return TEMPERED_TRANSCENDENT_VARIANTS[1].score(nodes, allocNodes)
		end,
		variants = TEMPERED_TRANSCENDENT_VARIANTS,
	})
	t_insert(jewelTypes, {
		name = "Lioneye's Fall",
		supportsFoulborn = true,
		radiusIndex = radiusIndexByLabel["Medium"],
		scoreLabel = "alloc passives",
		hasCompute = true,
		rawText = isFoulborn and LIONEYES_FALL_FOULBORN_RAW_TEXT or LIONEYES_FALL_RAW_TEXT,
		score = scoreAllocPassives,
	})
	t_insert(jewelTypes, {
		name = "Intuitive Leap",
		supportsFoulborn = true,
		radiusIndex = radiusIndexByLabel["Small"],
		scoreLabel = isFoulborn and "unalloc keystones" or "unalloc passives",
		hasCompute = true,
		computeMethods = CONNECTIONLESS_COMPUTE_METHODS,
		rawText = isFoulborn and INTUITIVE_LEAP_FOULBORN_RAW_TEXT or INTUITIVE_LEAP_RAW_TEXT,
		score = function(nodes, allocNodes)
			if isFoulborn then
				local s = 0
				for nodeId, node in pairs(nodes) do
					if not allocNodes[nodeId] and node.type == "Keystone" then
						s = s + 1
					end
				end
				return s
			end
			return scoreUnallocPassives(nodes, allocNodes)
		end,
	})
	t_insert(jewelTypes, {
		name = "Impossible Escape",
		isImpossibleEscape = true,
		scoreLabel = "unalloc notable/keystone near keystone",
		hasCompute = true,
		computeMethods = CONNECTIONLESS_COMPUTE_METHODS,
		score = function(nodes, allocNodes)
			local s = 0
			for nodeId, node in pairs(nodes) do
				if not allocNodes[nodeId] and (node.type == "Notable" or node.type == "Keystone") then
					s = s + 1
				end
			end
			return s
		end,
		variants = IMPOSSIBLE_ESCAPE_VARIANTS,
	})
	t_insert(jewelTypes, {
		name = "Split Personality",
		isSplitPersonality = true,
		scoreLabel = "dist to start",
		hasCompute = true,
		score = function()
			return 0
		end,
		variants = SPLIT_PERSONALITY_VARIANTS,
	})
	t_insert(jewelTypes, {
		name = "Stat Conversion",
		radiusIndex = radiusIndexByLabel["Large"],
		scoreLabel = "alloc passives",
		hasCompute = true,
		score = scoreAllocPassives,
		variants = {
			{ name = "Energy From Within", rawText = ENERGY_FROM_WITHIN_RAW_TEXT },
			{ name = "Healthy Mind",       rawText = HEALTHY_MIND_RAW_TEXT },
			{ name = "Energised Armour",   rawText = ENERGISED_ARMOUR_RAW_TEXT },
		},
	})
	t_insert(jewelTypes, {
		name = "Attribute Conversion",
		radiusIndex = radiusIndexByLabel["Large"],
		scoreLabel = "alloc passives",
		hasCompute = true,
		score = scoreAllocPassives,
		variants = {
			{ name = "Brute Force Solution", rawText = BRUTE_FORCE_SOLUTION_RAW_TEXT },
			{ name = "Careful Planning",     rawText = CAREFUL_PLANNING_RAW_TEXT },
			{ name = "Efficient Training",   rawText = EFFICIENT_TRAINING_RAW_TEXT },
			{ name = "Fertile Mind",         rawText = FERTILE_MIND_RAW_TEXT },
			{ name = "Fluid Motion",         rawText = FLUID_MOTION_RAW_TEXT },
			{ name = "Inertia",              rawText = INERTIA_RAW_TEXT },
		},
	})
	t_insert(jewelTypes, {
		name = "Combat Focus",
		radiusIndex = radiusIndexByLabel["Medium"],
		scoreLabel = "alloc passives",
		hasCompute = true,
		score = scoreAllocPassives,
		variants = {
			{ name = "Combat Focus (Crimson)",  rawText = COMBAT_FOCUS_CRIMSON_RAW_TEXT },
			{ name = "Combat Focus (Cobalt)",   rawText = COMBAT_FOCUS_COBALT_RAW_TEXT },
			{ name = "Combat Focus (Viridian)", rawText = COMBAT_FOCUS_VIRIDIAN_RAW_TEXT },
		},
	})
	t_insert(jewelTypes, {
		name = "Dreams & Nightmares",
		supportsFoulborn = true,
		radiusIndex = radiusIndexByLabel["Large"],
		scoreLabel = "alloc passives",
		hasCompute = true,
		score = scoreAllocPassives,
		variants = isFoulborn and DREAMS_NIGHTMARES_FOULBORN_VARIANTS or {
			{ name = "The Red Dream",       rawText = THE_RED_DREAM_RAW_TEXT },
			{ name = "The Red Nightmare",   rawText = THE_RED_NIGHTMARE_RAW_TEXT },
			{ name = "The Green Dream",     rawText = THE_GREEN_DREAM_RAW_TEXT },
			{ name = "The Green Nightmare", rawText = THE_GREEN_NIGHTMARE_RAW_TEXT },
			{ name = "The Blue Dream",      rawText = THE_BLUE_DREAM_RAW_TEXT },
			{ name = "The Blue Nightmare",  rawText = THE_BLUE_NIGHTMARE_RAW_TEXT },
		},
	})
	t_insert(jewelTypes, {
		name = "Thread of Hope",
		isThread = true,
		scoreLabel = "unalloc notable/keystone in ring",
		hasCompute = true,
		computeMethods = CONNECTIONLESS_COMPUTE_METHODS,
		rawText = nil,
		score = function(nodes, allocNodes)
			local s = 0
			for nodeId, node in pairs(nodes) do
				if not allocNodes[nodeId] and (node.type == "Notable" or node.type == "Keystone") then
					s = s + 1
				end
			end
			return s
		end,
	})
	return jewelTypes
end

local function jewelTypeSortOrder(jt)
	if jt.isLightOfMeaning then return 10 end
	if jt.name == "Might of the Meek" then return 20 end
	if jt.name == "Unnatural Instinct" then return 30 end
	if jt.name == "Inspired Learning" then return 40 end
	if jt.name == "Anatomical Knowledge" then return 50 end
	if jt.name == "Tempered & Transcendent" then return 55 end
	if jt.name == "Lioneye's Fall" then return 60 end
	if jt.name == "Intuitive Leap" then return 70 end
	if jt.isImpossibleEscape then return 75 end
	if jt.isSplitPersonality then return 80 end
	if jt.name == "Stat Conversion" then return 90 end
	if jt.name == "Attribute Conversion" then return 100 end
	if jt.name == "Combat Focus" then return 110 end
	if jt.name == "Dreams & Nightmares" then return 120 end
	if jt.isThread then return 130 end
	return 1000
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Open popup
-- ─────────────────────────────────────────────────────────────────────────────

function RadiusJewelFinderClass:Open()
	local treeData = self.build.spec.tree

	-- Radius index map
	local radiusIndexByLabel = { }
	for i, r in ipairs(data.jewelRadius) do
		if r.inner == 0 and not radiusIndexByLabel[r.label] then
			radiusIndexByLabel[r.label] = i
		end
	end

	-- Thread of Hope ring variants (annuli: inner > 0)
	local threadVariants = { }
	local threadNames = { "Small", "Medium", "Large", "Very Large", "Massive" }
	local tIdx = 1
	for i, r in ipairs(data.jewelRadius) do
		if r.inner > 0 then
			local ringName = threadNames[tIdx] or ("Ring " .. tIdx)
			t_insert(threadVariants, { name = ringName, radiusIndex = i })
			tIdx = tIdx + 1
		end
	end

	local LARGE_IDX    = radiusIndexByLabel["Large"]
	local jewelTypes
	local jewelSockets = self:buildJewelSockets(LARGE_IDX)

	-- Mutable state
	local showLegacy             = false
	local isFoulborn             = false
	local activeJewelTypes       = { }   -- filtered view of jewelTypes
	local selectedJewelType      = nil   -- set after first filter build
	local selectedThreadVariant  = threadVariants[1]
	local selectedLOMVariant     = LIGHT_OF_MEANING_VARIANTS[1]
	local selectedJewelVariant   = nil  -- set when jewel type has built-in variants
	local selectedComputeMethod  = CONNECTIONLESS_COMPUTE_METHODS[2]
	local selectedMaxPoints      = nil
	local dreamFamilyOptions     = {
		{ name = "All", value = "ALL" },
		{ name = "Red Dream", value = "The Red Dream" },
		{ name = "Red Nightmare", value = "The Red Nightmare" },
		{ name = "Green Dream", value = "The Green Dream" },
		{ name = "Green Nightmare", value = "The Green Nightmare" },
		{ name = "Blue Dream", value = "The Blue Dream" },
		{ name = "Blue Nightmare", value = "The Blue Nightmare" },
	}
	local selectedDreamFamily    = dreamFamilyOptions[1]

	local TL       = { "TOPLEFT", nil, "TOPLEFT" }
	local controls = { }

	-- ── Dropdown label lists ──────────────────────────────────────────────────
	-- (jtLabels is built dynamically via rebuildJewelTypeDropdown)
	local jtLabels = { }

	local tvLabels = { }
	for _, tv in ipairs(threadVariants) do t_insert(tvLabels, tv.name .. " Ring") end

	local lomLabels = { }
	for _, v in ipairs(LIGHT_OF_MEANING_VARIANTS) do t_insert(lomLabels, v.name) end

	local selectedSocket = jewelSockets[1]
	local socketViewer = new("PassiveTreeView")

	local impactStatLabels = { }
	for _, s in ipairs(IMPACT_STATS) do t_insert(impactStatLabels, s.label) end
	local selectedImpactStat = IMPACT_STATS[1]
	local finderState = self.build.radiusJewelFinderState or { }
	self.build.radiusJewelFinderState = finderState
	finderState.findCache = finderState.findCache or { }
	finderState.computeCache = finderState.computeCache or { }
	finderState.resultViewByKey = finderState.resultViewByKey or { }
	finderState.connectionlessPlanCache = finderState.connectionlessPlanCache or { }
	local suppressFinderStateSave = false
	local runFind
	local computeContext
	local cancelComputeTask

	local function saveFinderState()
		if suppressFinderStateSave then
			return
		end
		finderState.showLegacy = showLegacy
		finderState.isFoulborn = isFoulborn
		finderState.jewelTypeName = selectedJewelType and selectedJewelType.name or nil
		finderState.jewelVariantName = selectedJewelVariant and (selectedJewelVariant.dropdownLabel or selectedJewelVariant.name) or nil
		finderState.lomVariantName = selectedLOMVariant and selectedLOMVariant.name or nil
		finderState.threadVariantName = selectedThreadVariant and selectedThreadVariant.name or nil
		finderState.dreamFamilyValue = selectedDreamFamily and selectedDreamFamily.value or nil
		finderState.impactStatLabel = selectedImpactStat and selectedImpactStat.label or nil
		finderState.computeMethodId = selectedComputeMethod and selectedComputeMethod.id or nil
		finderState.maxPoints = selectedMaxPoints
		finderState.socketId = selectedSocket and selectedSocket.id or nil
	end

	local function getSelectionKey()
		local supportsComputeMethods = selectedJewelType and selectedJewelType.computeMethods and #selectedJewelType.computeMethods > 0
		local computeMethodKey = supportsComputeMethods and selectedComputeMethod and selectedComputeMethod.id or ""
		return table.concat({
			tostring(showLegacy and 1 or 0),
			tostring((isFoulborn and selectedJewelType and selectedJewelType.supportsFoulborn == true) and 1 or 0),
			selectedJewelType and selectedJewelType.name or "",
			selectedJewelVariant and (selectedJewelVariant.dropdownLabel or selectedJewelVariant.name) or "",
			selectedLOMVariant and selectedLOMVariant.name or "",
			selectedThreadVariant and selectedThreadVariant.name or "",
			selectedDreamFamily and selectedDreamFamily.value or "",
			selectedImpactStat and selectedImpactStat.field or "",
			computeMethodKey,
			selectedMaxPoints and tostring(selectedMaxPoints) or "",
			selectedSocket and tostring(selectedSocket.id) or "",
		}, "|")
	end

	local function restoreCachedResults()
		local key = getSelectionKey()
		local preferredView = finderState.resultViewByKey[key]
		local cache = preferredView == "compute" and finderState.computeCache[key] or finderState.findCache[key]
		if not cache and preferredView == "compute" then
			cache = finderState.findCache[key]
		elseif not cache and preferredView == "find" then
			cache = finderState.computeCache[key]
		end
		if not cache then
			cache = finderState.findCache[key] or finderState.computeCache[key]
		end
		if not cache then
			return false
		end
		controls.resultsList:SetMode(cache.mode, copyTableSafe(cache.rows, false, true), cache.defaultText)
		controls.statusLabel.label = cache.statusLabel or controls.statusLabel.label
		return true
	end
	local function saveResultCache(viewName, mode, rows, defaultText, statusLabel, makePreferred)
		local key = getSelectionKey()
		local targetCache = viewName == "compute" and finderState.computeCache or finderState.findCache
		targetCache[key] = {
			mode = mode,
			rows = copyTableSafe(rows, false, true),
			defaultText = defaultText,
			statusLabel = statusLabel,
		}
		if makePreferred then
			finderState.resultViewByKey[key] = viewName
		end
	end
	local function formatComputeStatus(itemLabel, statLabel, baseline, methodLabel)
		if methodLabel and methodLabel ~= "" then
			return s_format("^7%s | %s %.1f | %s | %%/pt", itemLabel, statLabel, baseline, methodLabel)
		end
		return s_format("^7%s | %s %.1f | %%/pt", itemLabel, statLabel, baseline)
	end
	local function formatVariantStatus(label, statLabel, baseline)
		return s_format("^7%s | %s %.1f", label, statLabel, baseline)
	end
	local function setComputeProgress(message)
		controls.statusLabel.label = message
		controls.resultsList:SetMode("message", {
			{ text = message },
		}, message)
	end
	cancelComputeTask = function(statusMessage)
		if not computeContext then
			return
		end
		main.onFrameFuncs["RadiusJewelFinderCompute"] = nil
		computeContext = nil
		if controls.computeButton then
			controls.computeButton.label = "Compute"
		end
		if statusMessage then
			controls.statusLabel.label = statusMessage
		end
	end
	local function isSelectedFoulbornActive()
		return isFoulborn and selectedJewelType and selectedJewelType.supportsFoulborn == true
	end
	local function selectedJewelSupportsComputeMethods()
		return selectedJewelType and selectedJewelType.computeMethods and #selectedJewelType.computeMethods > 0
	end

	local function getDisplayedVariants()
		if not selectedJewelType or not selectedJewelType.variants then
			return nil
		end
			if isSelectedFoulbornActive() and selectedJewelType.name == "Dreams & Nightmares" and selectedDreamFamily and selectedDreamFamily.value ~= "ALL" then
				local variants = { }
			for _, variant in ipairs(selectedJewelType.variants) do
				if variant.family == selectedDreamFamily.value then
					t_insert(variants, variant)
				end
			end
			return variants
		end
	return selectedJewelType.variants
end

local function buildPreviewLinesForJewelType(jewelType, previewIsFoulborn)
	if not jewelType then
			return nil
		end
		local fn = jewelPreviewFn[jewelType.name]
		if not fn then
			return nil
	end
	local selectedTypeMatches = selectedJewelType and selectedJewelType.name == jewelType.name
	if jewelType.isLightOfMeaning then
		return fn(selectedLOMVariant, previewIsFoulborn)
	elseif jewelType.isThread then
		return fn(selectedThreadVariant and selectedThreadVariant.name, previewIsFoulborn)
	elseif jewelType.variants then
		local previewVariant = (selectedTypeMatches and selectedJewelVariant) or jewelType.variants[1]
		return fn(previewVariant, previewIsFoulborn)
	end
	return fn(nil, previewIsFoulborn)
end
	local function isAnyFinderDropdownDropped()
		return (controls.jewelTypeSelect and controls.jewelTypeSelect.dropped)
			or (controls.jewelVariantSelect and controls.jewelVariantSelect.dropped)
			or (controls.lomVariantSelect and controls.lomVariantSelect.dropped)
			or (controls.threadVariantSelect and controls.threadVariantSelect.dropped)
			or (controls.variantFamilySelect and controls.variantFamilySelect.dropped)
			or (controls.impactStatSelect and controls.impactStatSelect.dropped)
			or (controls.socketSelect and controls.socketSelect.dropped)
	end

	local function syncDisplayedVariants()
		local variants = getDisplayedVariants()
		if not variants then
			controls.jewelVariantSelect:SetList({ })
			controls.jewelVariantSelect.selIndex = nil
			selectedJewelVariant = nil
			saveFinderState()
			return
		end
		if #variants == 0 then
			controls.jewelVariantSelect:SetList({ })
			controls.jewelVariantSelect.selIndex = nil
			selectedJewelVariant = nil
			saveFinderState()
			return
		end
		local variantNames = { }
		for _, v in ipairs(variants) do
			t_insert(variantNames, makeVariantDropdownEntry(v))
		end
		controls.jewelVariantSelect:SetList(variantNames)
		local varIdx = 1
		if selectedJewelVariant then
			for i, variant in ipairs(variants) do
				if variant == selectedJewelVariant then
					varIdx = i
					break
				end
			end
		else
			varIdx = controls.jewelVariantSelect.selIndex or 1
		end
		if varIdx > #variants then
			varIdx = 1
		end
		controls.jewelVariantSelect.selIndex = varIdx
		selectedJewelVariant = variants[varIdx]
		saveFinderState()
	end

	-- ── Preview list (right panel) ────────────────────────────────────────────
	local previewListData = { }
	controls.previewList = new("TextListControl", TL, { 600, 70, 440, 360 },
		{ { x = 0, align = "LEFT" }, { x = 210, align = "LEFT" } }, previewListData)
	controls.previewList.shown = function()
		return not (controls.jewelTypeSelect and controls.jewelTypeSelect.dropped)
	end

	local function updatePreview()
		wipeTable(previewListData)
		if controls.jewelTypeSelect and controls.jewelTypeSelect.dropped then
			return
		end
		if not selectedJewelType then
			t_insert(previewListData, { height = 16, [1] = COL_META .. "(no preview)" })
			return
		end
		local lines = buildPreviewLinesForJewelType(selectedJewelType, isSelectedFoulbornActive())
		if type(lines) ~= "table" then
			t_insert(previewListData, { height = 16, [1] = COL_META .. "(no preview)" })
			return
		end
		for _, line in ipairs(lines) do
			t_insert(previewListData, line)
		end
	end

		-- ── Results list (left panel) ─────────────────────────────────────────────
		controls.resultsList = new("RadiusJewelResultsListControl", TL, { 10, 70, 580, 360 }, self.build, socketViewer)
		controls.resultsList.suppressTooltipFunc = isAnyFinderDropdownDropped
		controls.resultsList:SetMode("message", { }, COL_META .. "Click Find to search")

	-- ── Helper: rebuild jewel type dropdown after filter change ──────────────
	local function rebuildJewelTypeDropdown()
		jewelTypes = buildJewelTypes(radiusIndexByLabel, isFoulborn)
		activeJewelTypes = { }
		jtLabels = { }
		for _, jt in ipairs(jewelTypes) do
			if showLegacy or not jt.isLegacy then
				t_insert(activeJewelTypes, jt)
			end
		end
		t_sort(activeJewelTypes, function(a, b)
			local ao, bo = jewelTypeSortOrder(a), jewelTypeSortOrder(b)
			if ao ~= bo then
				return ao < bo
			end
			if a.isLegacy ~= b.isLegacy then
				return a.isLegacy == false
			end
			return a.name < b.name
		end)
		for _, jt in ipairs(activeJewelTypes) do
			t_insert(jtLabels, jt.name)
		end
		if controls.jewelTypeSelect then
			controls.jewelTypeSelect:SetList(jtLabels)
			-- keep current selection if still visible, else reset to first
			local selIdx = 1
				for i, jt in ipairs(activeJewelTypes) do
					if selectedJewelType and jt.name == selectedJewelType.name then selIdx = i; break end
			end
			controls.jewelTypeSelect.selIndex = selIdx
			selectedJewelType = activeJewelTypes[selIdx]
			
				local hasVariants = selectedJewelType.variants ~= nil
				controls.jewelVariantLabel.shown = hasVariants
				controls.jewelVariantSelect.shown = hasVariants
				if hasVariants then
					syncDisplayedVariants()
				else
					selectedJewelVariant = nil
				end
			saveFinderState()
		else
			-- initial build before controls exist
			selectedJewelType = activeJewelTypes[1]
		end
	end
	rebuildJewelTypeDropdown()  -- initial build (controls.jewelTypeSelect not yet created)

	-- ── Header controls ───────────────────────────────────────────────────────
	controls.jewelTypeLabel = new("LabelControl", TL, { 10, 10, 0, 16 }, "^7Type:")

	controls.computeMethodLabel = new("LabelControl", TL, { 600, 10, 0, 16 }, "^7Method:")
	controls.computeMethodSelect = new("DropDownControl", TL, { 600, 26, 160, 20 }, { }, function(idx)
		cancelComputeTask()
		if selectedJewelType and selectedJewelType.computeMethods then
			selectedComputeMethod = selectedJewelType.computeMethods[idx]
		end
		saveFinderState()
	end)
	controls.computeMethodLabel.shown = false
	controls.computeMethodSelect.shown = false

	-- Right panel: socket selector (shown when LOM selected)
	controls.socketLabel = new("LabelControl", TL, { 600, 10, 0, 16 }, "^7Socket:")
	controls.socketSelect = new("TimelessJewelSocketControl", TL, { 600, 26, 210, 20 }, jewelSockets, function(_idx, value)
		cancelComputeTask()
		selectedSocket = value
		saveFinderState()
	end, self.build, socketViewer)
	controls.socketLabel.shown = true
	controls.socketSelect.shown = true

	-- Impact stat selector (shown when jewel has compute)
	controls.impactStatLabel = new("LabelControl", TL, { 820, 10, 0, 16 }, "^7Stat:")
	controls.impactStatSelect = new("DropDownControl", TL, { 820, 26, 140, 20 }, impactStatLabels, function(idx)
		cancelComputeTask()
		selectedImpactStat = IMPACT_STATS[idx]
		saveFinderState()
	end)
	controls.impactStatLabel.shown = true
	controls.impactStatSelect.shown = true

	controls.maxPointsLabel = new("LabelControl", TL, { 120, 444, 0, 16 }, "^7Max pts:")
	controls.maxPointsEdit = new("EditControl", TL, { 182, 442, 56, 20 }, "", nil, "%D", 3, function(buf)
		cancelComputeTask()
		selectedMaxPoints = buf ~= "" and tonumber(buf) or nil
		saveFinderState()
	end)
	controls.maxPointsLabel.shown = true
	controls.maxPointsEdit.shown = true

	-- LOM variant selector (shown when LOM selected)
	controls.lomVariantLabel = new("LabelControl", TL, { 278, 10, 0, 16 }, "^7Variant:")
	controls.lomVariantSelect = new("DropDownControl", TL, { 278, 26, 200, 20 }, lomLabels, function(idx)
		cancelComputeTask()
		selectedLOMVariant = LIGHT_OF_MEANING_VARIANTS[idx]
		saveFinderState()
		updatePreview()
		runFind(false)
	end)
	controls.lomVariantLabel.shown = true
	controls.lomVariantSelect.shown = true

		-- Thread ring selector (shown when Thread of Hope selected)
		controls.threadVariantLabel = new("LabelControl", TL, { 278, 10, 0, 16 }, "^7Preview ring:")
	controls.threadVariantSelect = new("DropDownControl", TL, { 278, 26, 200, 20 }, tvLabels, function(idx)
		cancelComputeTask()
		selectedThreadVariant = threadVariants[idx]
		saveFinderState()
		updatePreview()
		runFind(false)
	end)
		controls.threadVariantLabel.shown = false
		controls.threadVariantSelect.shown = false

		controls.variantFamilyLabel = new("LabelControl", TL, { 550, 10, 0, 16 }, "^7Family:")
		controls.variantFamilySelect = new("DropDownControl", TL, { 550, 26, 220, 20 }, {
			"All",
			"Red Dream",
			"Red Nightmare",
			"Green Dream",
			"Green Nightmare",
			"Blue Dream",
			"Blue Nightmare",
		}, function(idx)
			cancelComputeTask()
			selectedDreamFamily = dreamFamilyOptions[idx]
			controls.jewelVariantSelect.selIndex = 1
			selectedJewelVariant = nil
			syncDisplayedVariants()
			saveFinderState()
			updatePreview()
			runFind(false)
		end)
		controls.variantFamilyLabel.shown = false
		controls.variantFamilySelect.shown = false

		-- Jewel variant selector (shown when jewel type has built-in variants)
		controls.jewelVariantLabel = new("LabelControl", TL, { 278, 10, 0, 16 }, "^7Variant:")
		controls.jewelVariantSelect = new("DropDownControl", TL, { 278, 26, 260, 20 }, {}, function(idx)
			cancelComputeTask()
			local variants = getDisplayedVariants()
			if variants then
				selectedJewelVariant = variants[idx]
				saveFinderState()
				updatePreview()
			end
		end)
		controls.jewelVariantSelect.enableDroppedWidth = true
		controls.jewelVariantSelect.maxDroppedWidth = 520
		controls.jewelVariantLabel.shown = false
		controls.jewelVariantSelect.shown = false

		local function syncSelectedJewelTypeControls()
			local isLOM = selectedJewelType.isLightOfMeaning == true
			local isThread = selectedJewelType.isThread == true
			local hasVariants = selectedJewelType.variants ~= nil
			local hasVariantFamilyFilter = isSelectedFoulbornActive() and selectedJewelType.name == "Dreams & Nightmares"
			local hasComputeMethods = selectedJewelSupportsComputeMethods()

			controls.lomVariantLabel.shown     = isLOM
			controls.lomVariantSelect.shown    = isLOM
			controls.threadVariantLabel.shown  = isThread
			controls.threadVariantSelect.shown = isThread
			controls.variantFamilyLabel.shown  = hasVariantFamilyFilter
			controls.variantFamilySelect.shown = hasVariantFamilyFilter
			controls.jewelVariantLabel.shown   = hasVariants
			controls.jewelVariantSelect.shown  = hasVariants
			controls.computeMethodLabel.shown  = hasComputeMethods
			controls.computeMethodSelect.shown = hasComputeMethods
			controls.socketLabel.shown         = isLOM
			controls.socketSelect.shown        = isLOM
			controls.impactStatLabel.shown     = isLOM or selectedJewelType.hasCompute
			controls.impactStatSelect.shown    = isLOM or selectedJewelType.hasCompute
			if controls.computeButton then
				controls.computeButton.shown = isLOM or selectedJewelType.hasCompute
			end

			if hasVariants then
				if not hasVariantFamilyFilter then
					selectedDreamFamily = dreamFamilyOptions[1]
					controls.variantFamilySelect.selIndex = 1
				end
				syncDisplayedVariants()
			else
				selectedJewelVariant = nil
			end
			if hasComputeMethods then
				local methodLabels = { }
				for _, method in ipairs(selectedJewelType.computeMethods) do
					t_insert(methodLabels, method.label)
				end
				local selectedIndex = 1
				for i, method in ipairs(selectedJewelType.computeMethods) do
					if selectedComputeMethod and method.id == selectedComputeMethod.id then
						selectedIndex = i
						break
					end
				end
				selectedComputeMethod = selectedJewelType.computeMethods[selectedIndex]
				controls.computeMethodSelect:SetList(methodLabels)
				controls.computeMethodSelect.selIndex = selectedIndex
			end
	end

	-- Jewel type dropdown (defined after variant controls so :Click() is safe)
	controls.jewelTypeSelect = new("DropDownControl", TL, { 10, 26, 260, 20 }, jtLabels, function(idx)
		cancelComputeTask()
		selectedJewelType = activeJewelTypes[idx]
		controls.jewelVariantSelect.selIndex = 1
		syncSelectedJewelTypeControls()
		saveFinderState()
		updatePreview()
		runFind(false)
	end)
	controls.jewelTypeSelect.tooltipFunc = function(tooltip, mode, index)
		local jewelType = activeJewelTypes[index]
		local lines = buildPreviewLinesForJewelType(jewelType, isFoulborn and jewelType and jewelType.supportsFoulborn == true)
		if type(lines) ~= "table" then
			return
		end
		tooltip:Clear(true)
		for _, line in ipairs(lines) do
			tooltip:AddLine(line.height or 16, line[1], line.font)
		end
	end
	syncSelectedJewelTypeControls()

	-- Compute button: LOM = variant ranking at socket, others = socket ranking
	-- Results go into the left panel (resultListData); jewel preview stays intact.
	local function makeComputeProgressTracker()
		local tracker
		local function setFraction(self, fraction, label)
			local clamped = math.max(0, math.min(fraction or 0, 1))
			if clamped < self.fraction then
				clamped = self.fraction
			end
			self.fraction = clamped
			local pct = math.floor(clamped * 100)
			local text = label and s_format("^7Computing... %d%% | %s", pct, label) or s_format("^7Computing... %d%%", pct)
			setComputeProgress(text)
			local now = GetTime()
			if now - self.lastYield > 50 then
				self.lastYield = now
				coroutine.yield()
			end
		end
		local function makeChild(root, startFraction, spanFraction)
			return {
				root = root,
				startFraction = startFraction or 0,
				spanFraction = spanFraction or 1,
				tick = function(self, done, total, label)
					local localFraction = total and total > 0 and (done / total) or 0
					self.root:setFraction(self.startFraction + localFraction * self.spanFraction, label)
				end,
				child = function(self, childStartFraction, childSpanFraction)
					return makeChild(
						self.root,
						self.startFraction + (childStartFraction or 0) * self.spanFraction,
						(childSpanFraction or 1) * self.spanFraction
					)
				end,
			}
		end
		tracker = {
			lastYield = GetTime(),
			fraction = 0,
			setFraction = setFraction,
			tick = function(self, done, total, label)
				local fraction = total and total > 0 and (done / total) or 0
				self:setFraction(fraction, label)
			end,
			child = function(self, startFraction, spanFraction)
				return makeChild(self, startFraction, spanFraction)
			end,
		}
		return tracker
	end
	controls.computeButton = new("ButtonControl", TL, { 968, 26, 72, 20 }, "Compute", function()
		if computeContext then
			cancelComputeTask("^8Compute cancelled")
			restoreCachedResults()
			return
		end

		controls.computeButton.label = "Cancel"
		setComputeProgress("^7Computing...")
		local progress = makeComputeProgressTracker()
		computeContext = {
			co = coroutine.create(function()
				local ok, err = pcall(function()
			local statField = selectedImpactStat.field
			local statLabel = selectedImpactStat.label
			local selectedFoulbornActive = isSelectedFoulbornActive()
			local computeMethod = selectedComputeMethod or findConnectionlessComputeMethod(nil)
			local computeMethodLabel = selectedJewelSupportsComputeMethods() and computeMethod.label or nil

				if selectedJewelType.isLightOfMeaning then
					if not selectedSocket then return end
					if selectedMaxPoints and (selectedSocket.pathDist or 0) > selectedMaxPoints then
						controls.resultsList:SetMode("computeVariant", { }, COL_META .. "(socket exceeds max points)")
						controls.statusLabel.label = formatVariantStatus(selectedSocket.label, statLabel, 0)
						saveResultCache("compute", "computeVariant", { }, COL_META .. "(socket exceeds max points)", controls.statusLabel.label, true)
						return
					end
					local variantResults, baseline =
						self:computeVariantImpact(selectedSocket.id, statField, progress)
					local rows = { }
					for rank, r in ipairs(variantResults) do
						local pct  = baseline ~= 0 and (r.delta / baseline * 100) or 0
						t_insert(rows, {
							variantLabel = s_format("%02d. %s", rank, r.variant.name),
							delta = r.delta,
							pct = pct,
							socketId = selectedSocket.id,
							baseOutput = r.baseOutput,
							compareOutput = r.compareOutput,
							tooltipHeader = "^7Socketing this variant will give you:",
						})
					end
					controls.resultsList:SetMode("computeVariant", rows, COL_META .. "(no variants)")
					controls.statusLabel.label = formatVariantStatus(selectedSocket.label, statLabel, baseline)
					saveResultCache("compute", "computeVariant", rows, COL_META .. "(no variants)", controls.statusLabel.label, true)
				else
					local displayedVariants = getDisplayedVariants()
					local itemLabel = selectedJewelType.name
					local socketResults, baseline
					if selectedJewelType.name == "Intuitive Leap" then
						socketResults, baseline =
							self:computeIntuitiveLeapSocketImpact(jewelSockets, statField, selectedFoulbornActive, computeMethod.id, finderState.connectionlessPlanCache, progress, selectedMaxPoints)
					elseif selectedJewelType.isThread then
						socketResults, baseline =
							self:computeThreadOfHopeSocketImpact(jewelSockets, statField, threadVariants, computeMethod.id, finderState.connectionlessPlanCache, progress, selectedMaxPoints)
					elseif selectedJewelType.isImpossibleEscape then
						socketResults, baseline =
							self:computeImpossibleEscapeSocketImpact(jewelSockets, statField, displayedVariants or IMPOSSIBLE_ESCAPE_VARIANTS, computeMethod.id, finderState.connectionlessPlanCache, progress, selectedMaxPoints)
					elseif selectedJewelType.isSplitPersonality then
						socketResults, baseline =
							self:computeSplitPersonalitySocketImpact(jewelSockets, statField, displayedVariants or SPLIT_PERSONALITY_VARIANTS, progress, selectedMaxPoints)
					elseif displayedVariants and #displayedVariants > 0 then
						if selectedFoulbornActive and selectedJewelType.name == "Dreams & Nightmares"
						and selectedDreamFamily and selectedDreamFamily.value ~= "ALL" then
							itemLabel = selectedDreamFamily.name
						end
						socketResults, baseline =
							self:computeBestVariantSocketImpact(displayedVariants and jewelSockets or jewelSockets, displayedVariants, statField, progress, selectedMaxPoints)
					else
						local rawText = selectedJewelType.rawText
						socketResults, baseline =
							self:computeSocketImpact(jewelSockets, rawText, statField, selectedFoulbornActive, progress, selectedMaxPoints)
					end
					local rows = { }
					for _, r in ipairs(socketResults) do
						local points = r.socket.pathDist or 0
						local variantLabel = r.variant and (r.variant.dropdownLabel or r.variant.name) or ""
						local displayedPlans = (selectedJewelType.name == "Intuitive Leap" or selectedJewelType.isThread or selectedJewelType.isImpossibleEscape)
							and buildDisplayedConnectionlessPlans(r, points, baseline)
							or { r }
						for _, plan in ipairs(displayedPlans) do
							local pct = baseline ~= 0 and (plan.delta / baseline * 100) or 0
							local totalPoints = points + (plan.addedNodeCount or 0)
							local detailText = plan.detailText or variantLabel
							t_insert(rows, {
								socketLabel = r.socket.label,
								socketId = r.socket.id,
								points = totalPoints,
								delta = plan.delta,
								pct = pct,
								pctPerPoint = totalPoints > 0 and (pct / totalPoints) or pct,
								sortPctPerPoint = totalPoints > 0 and (pct / totalPoints) or (pct >= 0 and math.huge or -math.huge),
								detailText = detailText,
								baseOutput = plan.baseOutput,
								compareOutput = plan.compareOutput,
								tooltipHeader = selectedJewelType.isThread and "^7Socketing this jewel and allocating the best ring plan here will give you:"
									or selectedJewelType.name == "Intuitive Leap" and "^7Socketing this jewel and allocating the best nodes here will give you:"
									or selectedJewelType.isImpossibleEscape and "^7Socketing this jewel and allocating the best keystone plan here will give you:"
									or variantLabel ~= "" and "^7Socketing the best variant here will give you:"
									or "^7Socketing this jewel will give you:",
							})
						end
					end
					controls.resultsList:SetMode("computeSocket", rows, COL_META .. "(no empty sockets)")
					controls.statusLabel.label = formatComputeStatus(itemLabel, statLabel, baseline, computeMethodLabel)
					saveResultCache("compute", "computeSocket", rows, COL_META .. "(no empty sockets)", controls.statusLabel.label, true)
				end
				end)
				if not ok then
					error(err)
				end
			end),
		}
		main.onFrameFuncs["RadiusJewelFinderCompute"] = function()
			if not computeContext then
				main.onFrameFuncs["RadiusJewelFinderCompute"] = nil
				return
			end
			local res, errMsg = coroutine.resume(computeContext.co)
			if not res then
				cancelComputeTask()
				controls.statusLabel.label = "^1Error: " .. tostring(errMsg)
				controls.resultsList:SetMode("message", {
					{ text = "^1" .. tostring(errMsg) },
				}, "^1Error")
				return
			end
			if coroutine.status(computeContext.co) == "dead" then
				cancelComputeTask()
			end
		end
	end)
	controls.computeButton.shown = true

	-- Status label
	controls.statusLabel = new("LabelControl", TL, { 10, 54, 400, 16 }, COL_META .. "Click Find to search")
	controls.showLegacyCheck = new("CheckBoxControl", TL, { 700, 54, 18 }, "Show legacy", function(state)
		cancelComputeTask()
		showLegacy = state
		saveFinderState()
		rebuildJewelTypeDropdown()
		syncSelectedJewelTypeControls()
		updatePreview()
		runFind(false)
	end)
	controls.foulbornCheck = new("CheckBoxControl", TL, { 810, 54, 18 }, "Foulborn", function(state)
		cancelComputeTask()
		isFoulborn = state
		saveFinderState()
		rebuildJewelTypeDropdown()
		syncSelectedJewelTypeControls()
		updatePreview()
		runFind(false)
	end)

	-- ── Find button ───────────────────────────────────────────────────────────
	runFind = function(makePreferred)
			controls.statusLabel.label = "^7Searching..."
			local ok, err = pcall(function()
					local allocNodes  = self.build.spec.allocNodes
					local isThreadBestVariantSearch = selectedJewelType.isThread == true
					local isImpossibleEscapeBestVariantSearch = selectedJewelType.isImpossibleEscape == true
					local isSplitPersonalitySearch = selectedJewelType.isSplitPersonality == true
					local selectedFoulbornActive = isSelectedFoulbornActive()
					local radiusIndex
					local smallRadiusIndex
					if isImpossibleEscapeBestVariantSearch then
						for i, radius in ipairs(data.jewelRadius) do
							if radius.label == "Small" and radius.inner == 0 then
								smallRadiusIndex = i
								break
							end
						end
					end
					if isThreadBestVariantSearch then
						if selectedThreadVariant then
							radiusIndex = selectedThreadVariant.radiusIndex
						end
					elseif isImpossibleEscapeBestVariantSearch or isSplitPersonalitySearch then
						radiusIndex = nil
				elseif selectedJewelType.name == "Intuitive Leap" and selectedFoulbornActive then
				-- Le rayon Massive plein n'existe pas en natif, nous le gérons ci-dessous.
			elseif selectedJewelType.variants and selectedJewelVariant and selectedJewelVariant.radiusIndex then
				radiusIndex = selectedJewelVariant.radiusIndex
			else
				radiusIndex = selectedJewelType.radiusIndex
				end
				
				-- Sécurité : si le rayon n'est pas défini ou introuvable, on arrête la recherche.
				if not isThreadBestVariantSearch and not isImpossibleEscapeBestVariantSearch and not isSplitPersonalitySearch
				and not radiusIndex and not (selectedJewelType.name == "Intuitive Leap" and selectedFoulbornActive) then
					return
				end

				local results = { }
				local impossibleEscapeBestResult
				if isImpossibleEscapeBestVariantSearch then
					local variants = getDisplayedVariants() or selectedJewelType.variants or { }
					for _, variant in ipairs(variants) do
						local keystoneNode = treeData.keystoneMap[variant.keystoneName]
						local nodes = keystoneNode and keystoneNode.nodesInRadius and smallRadiusIndex and keystoneNode.nodesInRadius[smallRadiusIndex]
						if nodes then
							local score = selectedJewelType.score(nodes, allocNodes) or 0
							local topNodes = { }
							for _, n in pairs(nodes) do
								if n.type == "Notable" or n.type == "Keystone" then
									t_insert(topNodes, n.dn or n.name or "Unknown")
								end
							end
							t_sort(topNodes)
							local candidate = {
								score = score,
								topNodes = topNodes,
								variant = variant,
								detailText = variant.name,
							}
							if not impossibleEscapeBestResult
							or candidate.score > impossibleEscapeBestResult.score
							or (candidate.score == impossibleEscapeBestResult.score and candidate.variant.name < impossibleEscapeBestResult.variant.name) then
								impossibleEscapeBestResult = candidate
							end
						end
					end
				end
				for _, socket in ipairs(jewelSockets) do
					local socketNode = treeData.nodes[socket.id]
					if socketNode and (socketNode.nodesInRadius or isSplitPersonalitySearch) then
						if isThreadBestVariantSearch then
							local bestThreadResult
							for _, threadVariant in ipairs(threadVariants) do
								local nodes = socketNode.nodesInRadius[threadVariant.radiusIndex]
								if nodes then
									local score = selectedJewelType.score(nodes, allocNodes) or 0
									local topNodes = { }
									for _, n in pairs(nodes) do
										if n.type == "Notable" or n.type == "Keystone" then
											t_insert(topNodes, n.dn or n.name or "Unknown")
										end
									end
									t_sort(topNodes)
									local candidate = {
										socket = socket,
										score = score,
										topNodes = topNodes,
										variant = threadVariant,
									}
									if not bestThreadResult
									or candidate.score > bestThreadResult.score
									or (candidate.score == bestThreadResult.score and candidate.variant.radiusIndex < bestThreadResult.variant.radiusIndex) then
										bestThreadResult = candidate
									end
								end
							end
							if bestThreadResult then
								t_insert(results, bestThreadResult)
							end
						elseif isImpossibleEscapeBestVariantSearch and impossibleEscapeBestResult then
							t_insert(results, {
								socket = socket,
								score = impossibleEscapeBestResult.score,
								topNodes = impossibleEscapeBestResult.topNodes,
								variant = impossibleEscapeBestResult.variant,
								detailText = impossibleEscapeBestResult.detailText,
							})
						elseif isSplitPersonalitySearch then
							local score = socket.classStartDist or self:getSocketDistanceToClassStart(socket.id)
							t_insert(results, {
								socket = socket,
								score = score,
								topNodes = { },
								detailText = s_format("dist to start %d", score),
							})
						else
							local nodes
							if selectedJewelType.name == "Intuitive Leap" and selectedFoulbornActive then
								-- Construction manuelle du cercle complet "Massive" (2400)
								nodes = { }
								for idx, r in ipairs(data.jewelRadius) do
									if r.outer <= 2400 and socketNode.nodesInRadius[idx] then
										for nid, n in pairs(socketNode.nodesInRadius[idx]) do
											nodes[nid] = n
										end
									end
								end
							else
								nodes = socketNode.nodesInRadius[radiusIndex]
							end

							if nodes then
								local scoreFn = (selectedJewelType.variants and selectedJewelVariant and selectedJewelVariant.score)
									or selectedJewelType.score
								local score = scoreFn(nodes, allocNodes)
								local detailBuilder = (selectedJewelType.variants and selectedJewelVariant and selectedJewelVariant.detailBuilder)
									or selectedJewelType.detailBuilder
								local topNodes = { }
								for _, n in pairs(nodes) do
									if n.type == "Notable" or n.type == "Keystone" then
										t_insert(topNodes, n.dn or n.name or "Unknown")
									end
								end
								t_sort(topNodes)
								t_insert(results, {
									socket = socket,
									score = score or 0,
									topNodes = topNodes,
									detailText = detailBuilder and detailBuilder(nodes, allocNodes) or nil,
								})
							end
						end
					end
				end

					t_sort(results, function(a, b) return (a.score or 0) > (b.score or 0) end)

					local rows = { }
					for _, r in ipairs(results) do
						local topStr = t_concat(r.topNodes, ", ")
						if #topStr > 50 then
							topStr = topStr:sub(1, 47) .. "..."
						end

						local scoreLabel = (selectedJewelType.variants and selectedJewelVariant and selectedJewelVariant.scoreLabel)
							or selectedJewelType.scoreLabel
						local points = r.socket.pathDist or 0
						local scorePerPoint = points > 0 and (r.score / points) or r.score
						local scorePerPointSort = points > 0 and scorePerPoint or (r.score >= 0 and math.huge or -math.huge)
						local detailText = r.detailText
						if not detailText or detailText == "" then
							detailText = #topStr > 0 and (scoreLabel .. "  " .. topStr) or scoreLabel
						elseif #topStr > 0 and (isThreadBestVariantSearch or isImpossibleEscapeBestVariantSearch) then
							detailText = detailText .. " | " .. topStr
						end
						t_insert(rows, {
							socketLabel = r.socket.label,
							socketId = r.socket.id,
							points = points,
							score = r.score or 0,
							scorePerPoint = scorePerPoint,
							scorePerPointSort = scorePerPointSort,
							variantLabel = r.variant and (r.variant.name .. " Ring") or "",
							detailText = detailText,
						})
					end
					controls.resultsList:SetMode(isThreadBestVariantSearch and "findThread" or "find", rows, COL_META .. "(no results)")
					controls.statusLabel.label = isThreadBestVariantSearch
						and s_format("^7Thread of Hope | %d | score/pt", #results)
						or isImpossibleEscapeBestVariantSearch
						and s_format("^7Impossible Escape | %d | score/pt", #results)
						or isSplitPersonalitySearch
						and s_format("^7Split Personality | %d | score/pt", #results)
						or s_format("^7%d results | score/pt", #results)
					saveResultCache("find", isThreadBestVariantSearch and "findThread" or "find", rows, COL_META .. "(no results)", controls.statusLabel.label, makePreferred)
					if not makePreferred then
						restoreCachedResults()
					end
			end)
			if not ok then
				controls.statusLabel.label = "^1Error: " .. tostring(err)
				controls.resultsList:SetMode("message", {
					{ text = "^1" .. tostring(err) },
				}, "^1Error")
			end
		end
		controls.findButton = new("ButtonControl", TL, { 10, 444, 100, 20 }, "Find", function()
			cancelComputeTask()
			runFind(true)
		end)

	local function restoreFinderState()
		if not finderState.jewelTypeName then
			updatePreview()
			return
		end
		suppressFinderStateSave = true

		if finderState.showLegacy ~= nil then
			showLegacy = finderState.showLegacy
			controls.showLegacyCheck.state = showLegacy
		end
		if finderState.isFoulborn ~= nil then
			isFoulborn = finderState.isFoulborn
			controls.foulbornCheck.state = isFoulborn
		end
		rebuildJewelTypeDropdown()

		local jewelTypeIndex
		for i, jt in ipairs(activeJewelTypes) do
			if jt.name == finderState.jewelTypeName then
				jewelTypeIndex = i
				break
			end
		end
		if jewelTypeIndex then
			controls.jewelTypeSelect.selIndex = jewelTypeIndex
			selectedJewelType = activeJewelTypes[jewelTypeIndex]
		end

		if finderState.dreamFamilyValue then
			for i, option in ipairs(dreamFamilyOptions) do
				if option.value == finderState.dreamFamilyValue then
					selectedDreamFamily = option
					controls.variantFamilySelect.selIndex = i
					break
				end
			end
		end

		syncSelectedJewelTypeControls()

		if finderState.impactStatLabel then
			for i, stat in ipairs(IMPACT_STATS) do
				if stat.label == finderState.impactStatLabel then
					selectedImpactStat = stat
					controls.impactStatSelect.selIndex = i
					break
				end
			end
		end
		if finderState.maxPoints ~= nil then
			selectedMaxPoints = finderState.maxPoints
			controls.maxPointsEdit.buf = tostring(finderState.maxPoints)
		end
		if finderState.computeMethodId and selectedJewelType and selectedJewelType.computeMethods then
			for i, method in ipairs(selectedJewelType.computeMethods) do
				if method.id == finderState.computeMethodId then
					selectedComputeMethod = method
					controls.computeMethodSelect.selIndex = i
					break
				end
			end
		end
		if finderState.socketId then
			for i, socket in ipairs(jewelSockets) do
				if socket.id == finderState.socketId then
					selectedSocket = socket
					controls.socketSelect.selIndex = i
					break
				end
			end
		end

		if selectedJewelType and selectedJewelType.isLightOfMeaning and finderState.lomVariantName then
			for i, variant in ipairs(LIGHT_OF_MEANING_VARIANTS) do
				if variant.name == finderState.lomVariantName then
					selectedLOMVariant = variant
					controls.lomVariantSelect.selIndex = i
					break
				end
			end
		elseif selectedJewelType and selectedJewelType.isThread and finderState.threadVariantName then
			for i, variant in ipairs(threadVariants) do
				if variant.name == finderState.threadVariantName then
					selectedThreadVariant = variant
					controls.threadVariantSelect.selIndex = i
					break
				end
			end
		elseif selectedJewelType and selectedJewelType.variants and finderState.jewelVariantName then
			local variants = getDisplayedVariants() or { }
			for i, variant in ipairs(variants) do
				local variantName = variant.dropdownLabel or variant.name
				if variantName == finderState.jewelVariantName then
					selectedJewelVariant = variant
					controls.jewelVariantSelect.selIndex = i
					break
				end
			end
		end

		suppressFinderStateSave = false
		saveFinderState()
		updatePreview()
		runFind(false)
	end

	-- Close button
	controls.closeButton = new("ButtonControl", TL, { 950, 444, 100, 20 }, "Close", function()
		cancelComputeTask()
		main:ClosePopup()
	end)

	-- Initialise preview and open popup
	restoreFinderState()
	return main:OpenPopup(1060, 474, "Find Radius Jewel", controls)
end
