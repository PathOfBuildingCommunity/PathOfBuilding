-- Dat View
--
-- Class: GGPK Data
-- GGPK Data
--
local ipairs = ipairs
local t_insert = table.insert

local function scanDir(directory, extension)
	local i = 0
	local t = { }
	local pFile = io.popen('dir "'..directory..'" /b')
	for filename in pFile:lines() do
		filename = filename:gsub('\r?$', '')
		--ConPrintf("%s\n", filename)
		if extension then
			if filename:match(extension) then
				i = i + 1
				t[i] = filename
			else
				--ConPrintf("No Files Found matching extension '%s'", extension)
			end
		else
			i = i + 1
			t[i] = filename
		end
	end
	pFile:close()
	return t
end

-- Path can be in any format recognized by the extractor at oozPath, ie,
-- a .ggpk file or a Steam Path of Exile directory
local GGPKClass = newClass("GGPKData", function(self, path, datPath, reExport)
	if datPath then
		self.oozPath = datPath:match("\\$") and datPath or (datPath .. "\\")
	else
		self.path = path
		self.oozPath = GetWorkDir() .. "\\ggpk\\"
		self:CleanDir(reExport)
		self:ExtractFiles(reExport)
	end

	self.dat = { }
	self.txt = { }
	self.ot = { }
	
	self:AddDat64Files()
end)

function GGPKClass:CleanDir(reExport)
	if reExport then
		local cmd = 'del ' .. self.oozPath .. 'Data ' .. self.oozPath .. 'Metadata /Q /S'
		ConPrintf(cmd)
		os.execute(cmd)
	end
end

function GGPKClass:ExtractFilesWithBun(fileListStr, useRegex)
	local useRegex = useRegex or false
	local cmd = 'cd ' .. self.oozPath .. ' && bun_extract_file.exe extract-files ' .. (useRegex and '--regex "' or '"') .. self.path .. '" . ' .. fileListStr
	ConPrintf(cmd)
	os.execute(cmd)
end

-- Use manifest files to avoid command line limit and reduce cmd calls
function GGPKClass:ExtractFilesWithBunFromTable(fileTable, useRegex)
	local useRegex = useRegex or false
	local manifest = self.oozPath .. "extract_list.txt"
	local f = assert(io.open(manifest, "w"))
	for _, fname in ipairs(fileTable) do
		f:write(string.lower(fname), "\n")
	end
	f:close()
	local cmd = 'cd "' .. self.oozPath .. '" && bun_extract_file.exe extract-files ' .. (useRegex and '--regex "' or '"') .. self.path .. '" . < "' .. manifest .. '"'
	ConPrintf(cmd)
	os.execute(cmd)
	os.remove(manifest)
end

function GGPKClass:ExtractFiles(reExport)
	if reExport then
		local datList, txtList, otList, itList = self:GetNeededFiles()
		local datFiles = {}
		for _, fname in ipairs(datList) do
			datFiles[#datFiles + 1] = fname .. "c64"
		end

		-- non-regex chunk: dat files + txtList + itList
		for i = 1, #txtList do
			datFiles[#datFiles + 1] = itList[i]
		end
		for i = 1, #itList do
			datFiles[#datFiles + 1] = itList[i]
		end
		self:ExtractFilesWithBunFromTable(datFiles, false)

		-- regex chunk: otList
		local regexFiles = {}
		for i = 1, #otList do
			regexFiles[#regexFiles + 1] = otList[i]
		end
		self:ExtractFilesWithBunFromTable(regexFiles, true)
	end

	-- Overwrite Enums
	local errMsg = PLoadModule("Scripts/enums.lua")
	if errMsg then
		print(errMsg)
	end
end

function GGPKClass:ExtractList(listToExtract, cache, useRegex)
	useRegex = useRegex or false
	printf("Extracting ...")
	local fileTable = {}
	for _, fname in ipairs(listToExtract) do
		-- we are going to validate if the file is already extracted in this session
		if not cache[fname] then
			cache[fname] = true
			fileTable[#fileTable + 1] = fname
		end
	end
	self:ExtractFilesWithBunFromTable(fileTable, useRegex)
end

function GGPKClass:AddDat64Files()
	local datFiles = self:GetNeededFiles()
	for _, fname in ipairs(datFiles) do
		local record = { }
		record.name = fname:match("([^/\\]+)$") .. "c64"
		local rawFile = io.open(self.oozPath .. fname:gsub("/", "\\") .. "c64", 'rb')
		record.data = rawFile:read("*all")
		rawFile:close()
		t_insert(self.dat, record)
	end
end

function GGPKClass:GetNeededFiles()
	local datFiles = {
		"Data/Stats.dat",
		"Data/VirtualStatContextFlags.dat",
		"Data/BaseItemTypes.dat",
		"Data/WeaponTypes.dat",
		"Data/ArmourTypes.dat",
		"Data/ShieldTypes.dat",
		"Data/Flasks.dat",
		"Data/ComponentCharges.dat",
		"Data/ComponentAttributeRequirements.dat",
		"Data/PassiveSkills.dat",
		"Data/PassiveSkillStatCategories.dat",
		"Data/PassiveSkillMasteryGroups.dat",
		"Data/PassiveSkillMasteryEffects.dat",
		"Data/PassiveTreeExpansionJewelSizes.dat",
		"Data/PassiveTreeExpansionJewels.dat",
		"Data/PassiveJewelSlots.dat",
		"Data/PassiveTreeExpansionSkills.dat",
		"Data/PassiveTreeExpansionSpecialSkills.dat",
		"Data/Mods.dat",
		"Data/ModType.dat",
		"Data/ModFamily.dat",
		"Data/ModSellPriceTypes.dat",
		"Data/ModEffectStats.dat",
		"Data/ActiveSkills.dat",
		"Data/ActiveSkillType.dat",
		"Data/AlternateSkillTargetingBehaviours.dat",
		"Data/Ascendancy.dat",
		"Data/ClientStrings.dat",
		"Data/FlavourText.dat",
		"Data/Words.dat",
		"Data/ItemClasses.dat",
		"Data/SkillTotemVariations.dat",
		"Data/Essences.dat",
		"Data/EssenceType.dat",
		"Data/Characters.dat",
		"Data/BuffDefinitions.dat",
		"Data/BuffTemplates.dat",
		"Data/BuffVisuals.dat",
		"Data/BuffVisualSetEntries.dat",
		"Data/BuffVisualsArtVariations.dat",
		"Data/BuffVisualOrbs.dat",
		"Data/BuffVisualOrbTypes.dat",
		"Data/BuffVisualOrbArt.dat",
		"Data/GenericBuffAuras.dat",
		"Data/AddBuffToTargetVarieties.dat",
		"Data/NPCs.dat",
		"Data/CraftingBenchOptions.dat",
		"Data/CraftingItemClassCategories.dat",
		"Data/CraftingBenchSortCategories.dat",
		"Data/MonsterVarieties.dat",
		"Data/MonsterResistances.dat",
		"Data/MonsterTypes.dat",
		"Data/DefaultMonsterStats.dat",
		"Data/SkillGems.dat",
		"Data/GrantedEffects.dat",
		"Data/GrantedEffectsPerLevel.dat",
		"Data/ItemExperiencePerLevel.dat",
		"Data/EffectivenessCostConstants.dat",
		"Data/Tags.dat",
		"Data/GemTags.dat",
		"Data/ItemVisualIdentity.dat",
		"Data/AchievementItems.dat",
		"Data/MultiPartAchievements.dat",
		"Data/PantheonPanelLayout.dat",
		"Data/AlternatePassiveAdditions.dat",
		"Data/AlternatePassiveSkills.dat",
		"Data/AlternateTreeVersions.dat",
		"Data/GrantedEffectQualityStats.dat",
		"Data/AegisVariations.dat",
		"Data/CostTypes.dat",
		"Data/PassiveJewelRadii.dat",
		"Data/SoundEffects.dat",
		"Data/MavenJewelRadiusKeystones.dat",
		"Data/GrantedEffectStatSets.dat",
		"Data/GrantedEffectStatSetsPerLevel.dat",
		"Data/MonsterMapDifficulty.dat",
		"Data/MonsterMapBossDifficulty.dat",
		"Data/ReminderText.dat",
		"Data/Projectiles.dat",
		"Data/AnimateWeaponUniques.dat",
		"Data/ItemExperienceTypes.dat",
		"Data/WeaponPassiveSkills.dat",
		"Data/WeaponPassiveSkillTypes.dat",
		"Data/WeaponPassiveTreeBalancePerItemLevel.dat",
		"Data/WeaponPassiveTreeUniqueBaseTypes.dat",
		"Data/CrucibleTags.dat",
		"Data/UniqueStashLayout.dat",
		"Data/UniqueStashTypes.dat",
		"Data/Shrines.dat",
		"Data/PassiveOverrideLimits.dat",
		"Data/PassiveSkillOverrides.dat",
		"Data/PassiveSkillOverrideTypes.dat",
		"Data/PassiveSkillTattoos.dat",
		"Data/PassiveSkillTattooTargetSets.dat",
		"Data/DisplayMinionMonsterType.dat",
		"Data/tinctures.dat",
		"Data/GemEffects.dat",
		"Data/ActionTypes.dat",
		"Data/CorpseTypeTags.dat",
		"Data/ItemisedCorpse.dat",
		"Data/IndexableSkillGems.dat",
		"Data/IndexableSupportGems.dat",
		"Data/ItemClassCategories.dat",
		"Data/MinionType.dat",
		"Data/SummonedSpecificMonsters.dat",
		"Data/GameConstants.dat",
		"Data/AlternateQualityTypes.dat",
		"Data/WeaponClasses.dat",
		"Data/MonsterConditions.dat",
		"Data/Rarity.dat",
		"Data/Commands.dat",
		"Data/ModEquivalencies.dat",
		"Data/InfluenceTags.dat",
		"Data/LeagueNames.dat",
		"Data/DivinationBuffTemplates.dat",
		"Data/MinionDoublingStatTypes.dat",
		"Data/MercenaryAttributes.dat",
		"Data/MercenaryBuilds.dat",
		"Data/MercenaryClasses.dat",
		"Data/MercenarySkillFamilies.dat",
		"Data/MercenarySkills.dat",
		"Data/MercenarySupportCounts.dat",
		"Data/MercenarySupportFamilies.dat",
		"Data/MercenarySupports.dat",
		"Data/MercenaryWieldableTypes.dat",
		"Data/SkillArtVariations.dat",
		"Data/MiscAnimated.dat",
		"Data/MiscAnimatedArtVariations.dat",
		"Data/MiscBeamsArtVariations.dat",
		"Data/MiscBeams.dat",
		"Data/MiscEffectPacksArtVariations.dat",
		"Data/ProjectilesArtVariations.dat",
		"Data/MonsterVarietiesArtVariations.dat",
		"Data/PreloadGroups.dat",
		"Data/BrequelGraftTypes.dat",
		"Data/BrequelGraftSkillStats.dat",
		"Data/BrequelGraftGrantedSkillLevels.dat",
		"Data/VillageBalancePerLevelShared.dat",
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
		"Metadata/StatDescriptions/secondary_debuff_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/gem_stat_descriptions.txt",
		"Metadata/StatDescriptions/minion_attack_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/minion_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/minion_spell_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/minion_spell_damage_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/monster_stat_descriptions.txt",
		"Metadata/StatDescriptions/offering_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/single_minion_spell_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/skillpopup_stat_filters.txt",
		"Metadata/StatDescriptions/skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/stat_descriptions.txt",
		"Metadata/StatDescriptions/variable_duration_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/tincture_stat_descriptions.txt",
		"Metadata/StatDescriptions/graft_stat_descriptions.txt",
	}
	local otFiles = {
		"^Metadata/Monsters/(?:[\\w-]+/)*[\\w-]+\\.ot$",
		"^Metadata/Characters/(?:[\\w-]+/)*[\\w-]+\\.ot$",
	}
	local itFiles = {
		"Metadata/Items/Quivers/AbstractQuiver.it",
		"Metadata/Items/Rings/AbstractRing.it",
		"Metadata/Items/Belts/AbstractBelt.it",
		"Metadata/Items/Flasks/AbstractUtilityFlask.it",
		"Metadata/Items/Jewels/AbstractJewel.it",
		"Metadata/Items/Flasks/CriticalUtilityFlask.it",
		"Metadata/Items/Flasks/AbstractHybridFlask.it",
		"Metadata/Items/Flasks/AbstractManaFlask.it",
		"Metadata/Items/Weapons/TwoHandWeapons/Staves/AbstractWarstaff.it",
		"Metadata/Items/Weapons/OneHandWeapons/OneHandMaces/AbstractSceptre.it",
		"Metadata/Items/Weapons/OneHandWeapons/OneHandSwords/AbstractOneHandSwordThrusting.it",
		"Metadata/Items/Weapons/OneHandWeapons/Claws/AbstractClaw.it",
		"Metadata/Items/Armours/Shields/AbstractShield.it",
		"Metadata/Items/Weapons/TwoHandWeapons/Bows/AbstractBow.it",
		"Metadata/Items/Weapons/TwoHandWeapons/FishingRods/AbstractFishingRod.it",
		"Metadata/Items/Weapons/TwoHandWeapons/TwoHandMaces/AbstractTwoHandMace.it",
		"Metadata/Items/Armours/Boots/AbstractBoots.it",
		"Metadata/Items/Jewels/AbstractAbyssJewel.it",
		"Metadata/Items/Armours/BodyArmours/AbstractBodyArmour.it",
		"Metadata/Items/Armours/AbstractArmour.it",
		"Metadata/Items/Weapons/OneHandWeapons/Daggers/AbstractRuneDagger.it",
		"Metadata/Items/Weapons/TwoHandWeapons/Staves/AbstractStaff.it",
		"Metadata/Items/Weapons/TwoHandWeapons/TwoHandAxes/AbstractTwoHandAxe.it",
		"Metadata/Items/Weapons/OneHandWeapons/OneHandAxes/AbstractOneHandAxe.it",
		"Metadata/Items/Weapons/TwoHandWeapons/TwoHandSwords/AbstractTwoHandSword.it",
		"Metadata/Items/Weapons/OneHandWeapons/OneHandMaces/AbstractOneHandMace.it",
		"Metadata/Items/Armours/Gloves/AbstractGloves.it",
		"Metadata/Items/Weapons/OneHandWeapons/Daggers/AbstractDagger.it",
		"Metadata/Items/Weapons/OneHandWeapons/OneHandSwords/AbstractOneHandSword.it",
		"Metadata/Items/Amulets/AbstractAmulet.it",
		"Metadata/Items/Flasks/AbstractLifeFlask.it",
		"Metadata/Items/Weapons/OneHandWeapons/Wands/AbstractWand.it",
		"Metadata/Items/Armours/Helmets/AbstractHelmet.it",
		"Metadata/Items/Flasks/AbstractFlask.it",
		"Metadata/Items/Weapons/TwoHandWeapons/AbstractTwoHandWeapon.it",
		"Metadata/Items/Item.it",
		"Metadata/Items/Weapons/OneHandWeapons/AbstractOneHandWeapon.it",
		"Metadata/Items/Equipment.it",
		"Metadata/Items/Weapons/AbstractWeapon.it",
		"Metadata/Items/Tinctures/AbstractTincture.it",
		"Metadata/Items/Jewels/AbstractAnimalCharm.it",
	}
	return datFiles, txtFiles, otFiles, itFiles
end
