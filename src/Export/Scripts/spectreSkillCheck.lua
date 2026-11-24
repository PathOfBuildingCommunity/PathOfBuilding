--
-- Check for Spectres that have no skills in PoB yet.
--

-- Build skill lookup (Spectre + Minion + Other)
local skillLookup = {}

local function loadSkillFile(path)
	local f = io.open(path, "r")
	if f then
		for line in f:lines() do
			local skillId = line:match('skills%[%"(.-)%"%]')
			if skillId then
				skillLookup[skillId] = true
			end
		end
		f:close()
	end
end

-- Load all skill sources
loadSkillFile("../Data/Skills/Spectre.lua")
loadSkillFile("../Data/Skills/Minion.lua")
loadSkillFile("../Data/Skills/Other.lua")

-- Parse Spectres.lua for ids + skillLists
local spectres = {}
local file = io.open("../Data/Spectres.lua", "r")

if file then
	local currentId = nil
	local inSkillList = false

	for line in file:lines() do
		-- detect new spectre
		local id = line:match('minions%[%"(.-)%"%]')
		if id then
			currentId = id
			spectres[currentId] = { skills = {} }
		end

		-- detect skillList start
		if line:find("skillList%s*=%s*{") then
			inSkillList = true
		end

		-- read skills
		if inSkillList and currentId then
			for skillId in line:gmatch('%"(.-)%"') do
				table.insert(spectres[currentId].skills, skillId)
			end
		end

		-- detect end of skillList
		if inSkillList and line:find("}") then
			inSkillList = false
		end
	end

	file:close()
end

local notFoundSpectres = {}
-- Validate
for id, data in pairs(spectres) do
	local found = false

	for _, skillId in ipairs(data.skills) do
		-- skip default attack if you want (optional)
		if skillLookup[skillId] then
			found = true
			break
		end
	end

	if not found then
		table.insert(notFoundSpectres, id)
		print("No spectre skill: " .. id)
	end
end

print("Total Spectres without at least one skill: " .. tostring(#notFoundSpectres))