-- Dat View
--
-- Class: GGPK File
-- GGPK File
--
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove

local function scanDir(directory, extension)
	local i = 0
	local t = { }
    local pFile = io.popen('dir "'..directory..'" /b')
	for filename in pFile:lines() do
		--ConPrintf("%s\n", filename)
		if extension then
			if filename:match(extension) then
				i = i + 1
				t[i] = filename
			end
		else
			i = i + 1
			t[i] = filename
		end
    end
    pFile:close()
    return t
end

local GGPKClass = newClass("GGPKFile", function(self, path)
	self.path = path
	self.temp = io.popen("cd"):read('*l')
	self.oozPath = self.temp .. "\\ggpk\\"

	-- prepare our tables
	self.ggpk = { }
	self.dat = { }
	self.txt = { }

	self:ReadRecord(self.ggpk)
	for i = 1, self.ggpk.numRecord do
		self:ReadRecord(self.ggpk.recordList[i])
	end
	
	self:ExtractFiles()
	self:AddDatFiles()
end)

function GGPKClass:ExtractFiles()
	datList, txtList = self:GetNeededFiles()
	
	local fileList = ''
	for _, fname in ipairs(datList) do
		fileList = fileList .. '"' .. fname .. '" '
	end
	for _, fname in ipairs(txtList) do
		fileList = fileList .. '"' .. fname .. '" '
	end
	
	cmd = 'cd ' .. self.oozPath .. '&& bun_extract_file.exe "' .. self.path .. '" . ' .. fileList
	ConPrintf(cmd)
	os.execute(cmd)
end

function GGPKClass:AddDatFiles()
	datFiles = scanDir(self.oozPath .. "Data\\", '%w+%.dat$')
	for _, f in ipairs(datFiles) do
		record = { }
		record.name = f
		local rawFile = io.open(self.oozPath .. "Data\\" .. f, 'rb')
		record.data = rawFile:read("*all")
		rawFile:close()
		--ConPrintf("FILENAME: %s", fname)
		t_insert(self.dat, record)
	end
end

function GGPKClass:Open()
	if not self.file then
		self.file = io.open(self.path, "rb")
	end
end

function GGPKClass:Close()
	if self.file then
		self.file:close()
		self.file = nil
	end
end

function GGPKClass:ReadRecord(record)
	self:Open()
	self.file:seek("set", record.offset)
	local raw = self.file:read(8)
	record.length = bytesToUInt(raw, 1)
	record.tag = raw:sub(5)
	if record.tag == "GGPK" then
		raw = self.file:read(4)
		local ggpkVersion = bytesToUInt(raw, 1)
		--ConPrintf("GGPK Version: %d\n", ggpkVersion)
		record.numRecord = 2
		raw = self.file:read(record.numRecord * 8)
		record.recordList = { }
		for i = 1, record.numRecord do
			record.recordList[i] = {
				offset = bytesToULong(raw, (i-1) * 8 + 1),
			}
		end
		--ConPrintf("GGPK: %d records", record.numRecord)
	elseif record.tag == "PDIR" then
		raw = self.file:read(40)
		local nameLength = bytesToUInt(raw, 1)
		record.numRecord = bytesToUInt(raw, 5)
		record.hash = raw:sub(9)
		-- Multiplier of 12 used below as there is a u32 hash, u64 offset for each record
		raw = self.file:read(nameLength * 2 + record.numRecord * 12)
		record.name = convertUTF16to8(raw)
		record.recordList = { }
		for i = 1, record.numRecord do
			record.recordList[i] = {
				nameHash = bytesToUInt(raw, nameLength * 2 + (i-1) * 12 + 1),
				offset = bytesToULong(raw, nameLength * 2 + (i-1) * 12 + 5),
			}
		end
		--ConPrintf("PDIR '%s': %d records", record.name, record.numRecord)
	elseif record.tag == "FILE" then
		raw = self.file:read(36)
		local nameLength = bytesToUInt(raw, 1)
		-- hash is 32 bytes at offset [4:36]
		record.hash = raw:sub(5)
		record.name = convertUTF16to8(self.file:read(nameLength * 2))
		-- 44 = 36 read + (4 for record.length + 4 for record.tag pulled outside of 'if')
		local headLength = 44 + nameLength * 2
		record.dataOffset = record.offset + headLength
		record.dataLength = record.length - headLength
		--ConPrintf("FILE '%s': %d bytes", record.name, record.dataLength)
	elseif record.tag == "FREE" then
		record.nextFree = bytesToULong(self.file:read(8))
		--ConPrintf("FREE")
	else
		ConPrintf("Unhandled Tag: '%s' found at offset: %d", record.tag, record.offset)
	end
	record.read = true
end

function GGPKClass:GetRecord(name)
	self:Open()
	local record = self.ggpk.recordList[1]
	for part in name:gmatch("[^\\/]+") do
		if not record.recordList then
			self:ReadRecord(record)
		end
		local hash = murmurHash2(convertUTF8to16(part:lower()))
		local found
		for _, record in ipairs(record.recordList) do
			if record.nameHash == hash then
				found = record
				break
			end
		end
		if not found then
			return 
		end
		record = found
	end
	return record
end

function GGPKClass:ReadFile(name)
	local record = self:GetRecord(name)
	if record then
		if not record.read then
			self:ReadRecord(record)
		end
		if record.tag == "FILE" then
			self.file:seek("set", record.dataOffset)
			return self.file:read(record.dataLength)
		end
	end
end

function GGPKClass:GetNeededFiles()
	local datFiles = {
		"Data/Stats.dat",
		"Data/BaseItemTypes.dat",
		"Data/WeaponTypes.dat",
		"Data/ShieldTypes.dat",
		"Data/ComponentArmour.dat",
		"Data/Flasks.dat",
		"Data/ComponentCharges.dat",
		"Data/ComponentAttributeRequirements.dat",
		"Data/PassiveSkills.dat",
		"Data/PassiveSkillBuffs.dat",
		"Data/PassiveTreeExpansionJewelSizes.dat",
		"Data/PassiveTreeExpansionJewels.dat",
		"Data/PassiveJewelSlots.dat",
		"Data/PassiveTreeExpansionSkills.dat",
		"Data/PassiveTreeExpansionSpecialSkills.dat",
		"Data/Mods.dat",
		"Data/ModType.dat",
		"Data/ModDomains.dat",
		"Data/ModGenerationType.dat",
		"Data/ModFamily.dat",
		"Data/ModAuraFlags.dat",
		"Data/ActiveSkills.dat",
		"Data/ActiveSkillTargetTypes.dat",
		"Data/ActiveSkillType.dat",
		"Data/Ascendancy.dat",
		"Data/ClientStrings.dat",
		"Data/ItemClasses.dat",
		"Data/SkillTotems.dat",
		"Data/SkillTotemVariations.dat",
		"Data/SkillMines.dat",
		"Data/Essences.dat",
		"Data/EssenceType.dat",
		"Data/Characters.dat",
		"Data/BuffDefinitions.dat",
		"Data/BuffCategories.dat",
		"Data/BuffVisuals.dat",
		"Data/HideoutNPCs.dat",
		"Data/NPCs.dat",
		"Data/CraftingBenchOptions.dat",
		"Data/CraftingItemClassCategories.dat",
		"Data/CraftingBenchUnlockCategories.dat",
		"Data/MonsterVarieties.dat",
		"Data/MonsterResistances.dat",
		"Data/MonsterTypes.dat",
		"Data/DefaultMonsterStats.dat",
		"Data/SkillGems.dat",
		"Data/GrantedEffects.dat",
		"Data/GrantedEffectsPerLevel.dat",
		"Data/ItemExperiencePerLevel.dat",
		"Data/EffectivenessCostConstants.dat",
		"Data/StatInterpolationTypes.dat",
		"Data/Tags.dat",
		"Data/GemTags.dat",
		"Data/ItemVisualIdentity.dat",
		"Data/AchievementItems.dat",
		"Data/MultiPartAchievements.dat",
		"Data/PantheonPanelLayout.dat",
	}
	local txtFiles = {
		"Metadata/StatDescriptions/passive_skill_aura_stat_descriptions.txt",
		"Metadata/StatDescriptions/passive_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/active_skill_gem_stat_descriptions.txt",
		"Metadata/StatDescriptions/advanced_mod_stat_descriptions.txt",
		"Metadata/StatDescriptions/aura_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/banner_aura_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/beam_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/brand_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/buff_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/curse_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/debuff_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/gem_stat_descriptions.txt",
		"Metadata/StatDescriptions/minion_attack_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/minion_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/minion_spell_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/monster_stat_descriptions.txt",
		"Metadata/StatDescriptions/offering_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/skillpopup_stat_filters.txt",
		"Metadata/StatDescriptions/skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/stat_descriptions.txt",
		"Metadata/StatDescriptions/variable_duration_skill_stat_descriptions.txt",
	}
	return datFiles, txtFiles
end
