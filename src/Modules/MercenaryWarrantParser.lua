-- Path of Building
--
-- Module: Mercenary Warrant Parser
-- Parses in-game Mercenary Warrant clipboard text into SPEC-001/SPEC-002 structures.
--
local t_insert = table.insert
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local M = {}

local buildArchetypeToType = {
	["Stormhand"] = "Intelligence",
	["Kineticist"] = "Intelligence",
	["Winterpriest"] = "Intelligence",
	["Flamecaller"] = "Intelligence",
	["Sanguimancer"] = "StrInt",
	["Warpriest"] = "StrInt",
	["Bastion"] = "Strength",
	["Striker"] = "Strength",
	["Eruptor"] = "Strength",
	["Earthshaker"] = "Strength",
	["Ripper"] = "StrDex",
	["Manyshot"] = "Dexterity",
	["Sniper"] = "Dexterity",
	["Toxicologist"] = "DexInt",
	["Trapmaster"] = "DexInt",
}

local supportAliases = {
	["Increased Area of Effect"] = "Increased Area of Effect Support",
	["Greater Area of Effect"] = "Increased Area of Effect Support",
	["Less Duration"] = "Less Duration Support",
	["Greater Less Duration"] = "Less Duration Support",
	["Elemental Focus"] = "Elemental Focus Support",
	["Greater Elemental Focus"] = "Elemental Focus Support",
	["Greater Critical Chance"] = "Increased Critical Strikes Support",
	["Increased Critical Chance"] = "Increased Critical Strikes Support",
	["Second Wind"] = "Second Wind Support",
	["Faster Casting"] = "Faster Casting Support",
	["Brutality"] = "Brutality Support",
	["Concentrated Effect"] = "Concentrated Effect Support",
	["Greater Concentrated Effect"] = "Concentrated Effect Support",
	["Pulverise"] = "Pulverise Support",
	["Greater Pulverise"] = "Pulverise Support",
	["Faster Attacks"] = "Faster Attacks Support",
	["Greater Faster Attacks"] = "Faster Attacks Support",
}

local function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function isNonSkillSection(lines)
	local first = lines[1] or ""
	if first:match("^Right click")
		or first:match("^Open a portal")
		or first:match("^Note:")
		or first:match("^Item Level:")
		or first:match("^Item Class:")
		or first:match("^Rarity:")
		or first == "Corrupted"
		or first == "Mirrored"
		or first == "Unidentified" then
		return true
	end
	return false
end

---@param text string?
---@return boolean
function M.IsWarrantText(text)
	if type(text) ~= "string" then
		return false
	end
	for line in text:gmatch("([^\r\n]+)") do
		local cleaned = trim(line)
		if cleaned == "--------" then
			return false
		elseif cleaned == "Mercenary Warrant" then
			return true
		end
	end
	return false
end

---@param buildName string?
---@return string?
function M.BuildToType(buildName)
	return buildName and buildArchetypeToType[buildName] or nil
end

---@param rawName string
---@param isSupport boolean
---@param skillsTab SkillsTab?
---@return string nameSpec, string? gemId
function M.ResolveGemName(rawName, isSupport, skillsTab)
	local candidate = isSupport and (supportAliases[rawName] or rawName) or rawName
	if skillsTab and skillsTab.FindSkillGem then
		local errMsg, gemData = skillsTab:FindSkillGem(candidate)
		if not errMsg and gemData then
			return gemData.name, gemData.id
		end
	end
	return rawName, nil
end

---@param text string
---@param skillsTab SkillsTab?
---@return table? parsed, string? errMsg
function M.Parse(text, skillsTab)
	if not M.IsWarrantText(text) then
		return nil, "Not a Mercenary Warrant"
	end

	-- Split into sections separated by "--------"
	local sections = {}
	local current = {}
	for line in text:gmatch("([^\r\n]+)") do
		local cleaned = trim(line)
		if cleaned == "--------" then
			if #current > 0 then
				t_insert(sections, current)
				current = {}
			end
		elseif cleaned ~= "" then
			t_insert(current, cleaned)
		end
	end
	if #current > 0 then
		t_insert(sections, current)
	end

	local result = {
		name = sections[2] and sections[2][1] or "",
		build = nil,
		level = nil,
		type = nil,
		skillGroups = {},
	}

	-- Section 3 holds Build: and Mercenary Level:
	local metaIndex = 3
	if sections[metaIndex] then
		local hasMeta = false
		for _, line in ipairs(sections[metaIndex]) do
			local b = line:match("^Build:%s*(.+)$")
			local lvl = line:match("^Mercenary Level:%s*(%d+)$")
			if b then
				result.build = trim(b)
				result.type = M.BuildToType(result.build)
				hasMeta = true
			elseif lvl then
				result.level = tonumber(lvl)
				hasMeta = true
			end
		end
		if hasMeta then
			metaIndex = 4
		end
	end

	local defaultLevel = result.level and m_min(20, m_max(1, m_floor(result.level / 3.5))) or 20
	for i = metaIndex, #sections do
		local lines = sections[i]
		if #lines > 0 and not isNonSkillSection(lines) then
			local group = {
				label = lines[1],
				enabled = true,
				isMercenary = true,
				gemList = {},
			}
			for j, line in ipairs(lines) do
				local isSupport = j > 1
				local rawName, tier = line:match("^(.+)%s*%(Tier:%s*(%d+)%)$")
				if rawName then
					rawName = trim(rawName)
					tier = tonumber(tier)
				else
					rawName = line
				end
				local nameSpec, gemId = M.ResolveGemName(rawName, isSupport, skillsTab)
				t_insert(group.gemList, {
					nameSpec = nameSpec,
					gemId = gemId,
					level = defaultLevel,
					quality = 0,
					mercTier = tier,
					enabled = true,
					enableGlobal1 = true,
					enableGlobal2 = true,
					count = 1,
				})
			end
			t_insert(result.skillGroups, group)
		end
	end

	return result
end

---@param build table
---@param text string
---@return boolean ok, table|string resultOrErr
function M.ApplyWarrant(build, text)
	local parsed, errMsg = M.Parse(text, build.skillsTab)
	if not parsed then
		return false, errMsg
	end

	local itemsTab = build.itemsTab
	local skillsTab = build.skillsTab
	local partyTab = build.partyTab

	local processedSkills = {}
	for _, group in ipairs(parsed.skillGroups) do
		if skillsTab then
			skillsTab:ProcessSocketGroup(group)
		end
		t_insert(processedSkills, group)
	end

	if partyTab and partyTab.UpsertMercenary then
		partyTab:UpsertMercenary({
			name = parsed.name,
			build = parsed.build,
			type = parsed.type,
			level = parsed.level,
			skills = processedSkills,
			items = {},
		})
		if itemsTab then itemsTab:AddUndoState() end
		if skillsTab then skillsTab:AddUndoState() end
	else
		if itemsTab and itemsTab.activeItemSet then
			itemsTab.activeItemSet.mercenaryName = parsed.name
			itemsTab.activeItemSet.mercenaryBuild = parsed.build
			itemsTab.activeItemSet.mercenaryLevel = parsed.level
			if parsed.type then
				itemsTab.activeItemSet.mercenaryType = parsed.type
			end
			itemsTab:AddUndoState()
		end
		if skillsTab and skillsTab.mercenarySocketGroupList then
			wipeTable(skillsTab.mercenarySocketGroupList)
			for _, group in ipairs(processedSkills) do
				t_insert(skillsTab.mercenarySocketGroupList, group)
			end
			skillsTab:AddUndoState()
		end
	end

	build.buildFlag = true
	return true, parsed
end

return M
