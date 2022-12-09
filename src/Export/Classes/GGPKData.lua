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
local GGPKClass = newClass("GGPKData", function(self, path, datPath)
	if datPath then
		self.oozPath = datPath:match("\\$") and datPath or (datPath .. "\\")
	else
		self.path = path
		self.temp = io.popen("cd"):read('*l')
		self.oozPath = self.temp .. "\\ggpk\\"
		self:ExtractFiles()
	end

	self.dat = { }
	self.txt = { }

	if USE_DAT64 then
		self:AddDat64Files()
	else
		self:AddDatFiles()
	end
end)

function GGPKClass:ExtractFiles()
	local datList, txtList, otList = self:GetNeededFiles()
	
	local fileList = ''
	for _, fname in ipairs(datList) do
		if USE_DAT64 then
			fileList = fileList .. '"' .. fname .. '64" '
		else
			fileList = fileList .. '"' .. fname .. '" '
		end
	end
	for _, fname in ipairs(txtList) do
		fileList = fileList .. '"' .. fname .. '" '
	end
	for _, fname in ipairs(otList) do
		fileList = fileList .. '"' .. fname .. '" '
	end
	
	local cmd = 'cd ' .. self.oozPath .. ' && bun_extract_file.exe extract-files "' .. self.path .. '" . ' .. fileList
	ConPrintf(cmd)
	os.execute(cmd)
end

function GGPKClass:AddDatFiles()
	local datFiles = scanDir(self.oozPath .. "Data\\", '%w+%.dat$')
	for _, f in ipairs(datFiles) do
		local record = { }
		record.name = f
		local rawFile = io.open(self.oozPath .. "Data\\" .. f, 'rb')
		record.data = rawFile:read("*all")
		rawFile:close()
		--ConPrintf("FILENAME: %s", fname)
		t_insert(self.dat, record)
	end
end

function GGPKClass:AddDat64Files()
	local datFiles = scanDir(self.oozPath .. "Data\\", '%w+%.dat64$')
	for _, f in ipairs(datFiles) do
		local record = { }
		record.name = f
		local rawFile = io.open(self.oozPath .. "Data\\" .. f, 'rb')
		record.data = rawFile:read("*all")
		rawFile:close()
		--ConPrintf("FILENAME: %s", fname)
		t_insert(self.dat, record)
	end
end

function GGPKClass:GetNeededFiles()
	local datFiles = {
		"Data/Stats.dat",
		"Data/StatSemantics.dat",
		"Data/VirtualStatContextFlags.dat",
		"Data/BaseItemTypes.dat",
		"Data/WeaponTypes.dat",
		"Data/ArmourTypes.dat",
		"Data/ShieldTypes.dat",
		"Data/Flasks.dat",
		"Data/ComponentCharges.dat",
		"Data/ComponentAttributeRequirements.dat",
		"Data/PassiveSkills.dat",
		"Data/PassiveSkillTypes.dat",
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
		"Data/ModDomains.dat",
		"Data/ModGenerationType.dat",
		"Data/ModFamily.dat",
		"Data/ModAuraFlags.dat",
		"Data/ActiveSkills.dat",
		"Data/ActiveSkillTargetTypes.dat",
		"Data/ActiveSkillType.dat",
		"Data/AlternateSkillTargetingBehaviours.dat",
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
		"Data/BuffTemplates.dat",
		"Data/BuffVisuals.dat",
		"Data/BuffVisualSets.dat",
		"Data/BuffVisualSetEntries.dat",
		"Data/BuffVisualsArtVariations.dat",
		"Data/BuffVisualOrbs.dat",
		"Data/BuffVisualOrbTypes.dat",
		"Data/BuffVisualOrbArt.dat",
		"Data/GenericBuffAuras.dat",
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
		"Data/GrantedEffectQualityTypes.dat",
		"Data/GrantedEffectQualityStats.dat",
		"Data/GrantedEffectGroups.dat",
		"Data/AegisVariations.dat",
		"Data/CostTypes.dat",
		"Data/PassiveJewelRadii.dat",
		"Data/SoundEffects.dat",
		"Data/MavenJewelRadiusKeystones.dat",
		"Data/TableCharge.dat",
		"Data/GrantedEffectStatSets.dat",
		"Data/GrantedEffectStatSetsPerLevel.dat",
		"Data/MonsterMapDifficulty.dat",
		"Data/MonsterMapBossDifficulty.dat",
		"Data/ReminderText.dat",
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
	}
	local otFiles = {
		"Metadata/Items/Quivers/AbstractQuiver.ot",
		"Metadata/Items/Rings/AbstractRing.ot",
		"Metadata/Items/Belts/AbstractBelt.ot",
		"Metadata/Items/Flasks/AbstractUtilityFlask.ot",
		"Metadata/Items/Jewels/AbstractJewel.ot",
		"Metadata/Items/Flasks/CriticalUtilityFlask.ot",
		"Metadata/Items/Flasks/AbstractHybridFlask.ot",
		"Metadata/Items/Flasks/AbstractManaFlask.ot",
		"Metadata/Items/Weapons/TwoHandWeapons/Staves/AbstractWarstaff.ot",
		"Metadata/Items/Weapons/OneHandWeapons/OneHandMaces/AbstractSceptre.ot",
		"Metadata/Items/Weapons/OneHandWeapons/OneHandSwords/AbstractOneHandSwordThrusting.ot",
		"Metadata/Items/Weapons/OneHandWeapons/Claws/AbstractClaw.ot",
		"Metadata/Items/Armours/Shields/AbstractShield.ot",
		"Metadata/Items/Weapons/TwoHandWeapons/Bows/AbstractBow.ot",
		"Metadata/Items/Weapons/TwoHandWeapons/FishingRods/AbstractFishingRod.ot",
		"Metadata/Items/Weapons/TwoHandWeapons/TwoHandMaces/AbstractTwoHandMace.ot",
		"Metadata/Items/Armours/Boots/AbstractBoots.ot",
		"Metadata/Items/Jewels/AbstractAbyssJewel.ot",
		"Metadata/Items/Armours/BodyArmours/AbstractBodyArmour.it",
		"Metadata/Items/Armours/AbstractArmour.it",
		"Metadata/Items/Weapons/OneHandWeapons/Daggers/AbstractRuneDagger.ot",
		"Metadata/Items/Weapons/TwoHandWeapons/Staves/AbstractStaff.ot",
		"Metadata/Items/Weapons/TwoHandWeapons/TwoHandAxes/AbstractTwoHandAxe.ot",
		"Metadata/Items/Weapons/OneHandWeapons/OneHandAxes/AbstractOneHandAxe.ot",
		"Metadata/Items/Weapons/TwoHandWeapons/TwoHandSwords/AbstractTwoHandSword.ot",
		"Metadata/Items/Weapons/OneHandWeapons/OneHandMaces/AbstractOneHandMace.ot",
		"Metadata/Items/Armours/Gloves/AbstractGloves.ot",
		"Metadata/Items/Weapons/OneHandWeapons/Daggers/AbstractDagger.ot",
		"Metadata/Items/Weapons/OneHandWeapons/OneHandSwords/AbstractOneHandSword.ot",
		"Metadata/Items/Amulets/AbstractAmulet.ot",
		"Metadata/Items/Flasks/AbstractLifeFlask.ot",
		"Metadata/Items/Weapons/OneHandWeapons/Wands/AbstractWand.ot",
		"Metadata/Items/Armours/Helmets/AbstractHelmet.ot",
		"Metadata/Items/Flasks/AbstractFlask.ot",
		"Metadata/Items/Weapons/TwoHandWeapons/AbstractTwoHandWeapon.ot",
		"Metadata/Items/Item.ot",
		"Metadata/Items/Weapons/OneHandWeapons/AbstractOneHandWeapon.ot",
		"Metadata/Items/Equipment.ot",
		"Metadata/Items/Weapons/AbstractWeapon.ot",
	}
	return datFiles, txtFiles, otFiles
end
