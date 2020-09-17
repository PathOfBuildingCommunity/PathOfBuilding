-- Dat View
--
-- Class: GGPK File
-- GGPK File
--
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove

local function scandir(directory, ext)
	ext = ext or nil
    local i, t, popen = 0, {}, io.popen
    local pfile = popen('dir "'..directory..'" /b')
	for filename in pfile:lines() do
		--ConPrintf("%s\n", filename)
		if ext then
			if filename:match(ext) then
				i = i + 1
				t[i] = filename
			end
		else
			i = i + 1
			t[i] = filename
		end
    end
    pfile:close()
    return t
end

local GGPKClass = newClass("GGPKFile", function(self, path)
	self.path = path
	self.temp = io.popen"cd":read'*l'
	self.ooz_path = self.temp .. "\\ggpk\\"

	-- make the Metadata subdir
	--os.execute("mkdir " .. self.ooz_path .. "\\Metadata")

	self.ggpk = { }
	self.dat = { }
	self.txt = { }

	self:ReadRecord(self.ggpk)
	for i = 1, self.ggpk.numRecord do
		self:ReadRecord(self.ggpk.recordList[i])
	end
	
	self:ExtractFiles()

	self:AddDATFiles()
end)

function GGPKClass:ExtractFiles()
	datList, txtList = self:GetNeededFiles()
	
	local file_list = ''
	for _, fname in ipairs(datList) do
		file_list = file_list .. '"' .. fname .. '" '
	end
	for _, fname in ipairs(txtList) do
		file_list = file_list .. '"' .. fname .. '" '
	end
	
	cmd = 'cd ' .. self.ooz_path .. '&& bun_extract_file.exe "' .. self.path .. '" . ' .. file_list
	ConPrintf(cmd)
	os.execute(cmd)
end

function GGPKClass:AddDATFiles()
	dat_files = scandir(self.ooz_path .. "Data\\", '%w+%.dat$')
	for _, f in ipairs(dat_files) do
		record = { }
		record.name = f
		raw_file = io.open(self.ooz_path .. "Data\\" .. f, 'rb')
		record.data = raw_file:read("*all")
		raw_file:close()
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
		raw = self.file:read(nameLength * 2 + record.numRecord * 12) -- 12 as there is a u32 hash, u64 offset for each record
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
		record.hash = raw:sub(5) -- 32 bytes starting at [4:36]
		record.name = convertUTF16to8(self.file:read(nameLength * 2))
		local headLength = 44 + nameLength * 2 -- 44 = 36 read + (4 for rec_leng + 4 for type) pulled outside of 'if'
		record.dataOffset = record.offset + headLength
		record.dataLength = record.length - headLength
		--ConPrintf("FILE '%s': %d bytes", record.name, record.dataLength)
		--if self.dump then
		is_needed = self:RecordNeeded(record.name)
		if is_needed == 1 then
			self.file:seek("set", record.dataOffset)
			self:Write(record.name, self.file:read(record.dataLength))
		elseif is_needed == 2 then
			self.file:seek("set", record.dataOffset)
			self:Write("Metadata\\" .. record.name, self.file:read(record.dataLength))
		end
	elseif record.tag == "FREE" then
		record.nextFree = bytesToULong(self.file:read(8))
		--ConPrintf("FREE")
	else
		ConPrintf("Unhandled Tag: %s", record.tag)
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
		"Data/AlternatePassiveAdditions.dat",
		"Data/AlternatePassiveSkills.dat",
		"Data/AlternateTreeVersions.dat",
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
