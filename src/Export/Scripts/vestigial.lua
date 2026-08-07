local utils = LoadModule("../Modules/Utils")

local vestigialUniqueBaseTypes = {
	Helmet = LoadModule("Uniques/helmet"),
	["Body Armour"] = LoadModule("Uniques/body"),
	Gloves = LoadModule("Uniques/gloves"),
	Boots = LoadModule("Uniques/boots"),
	Shield = LoadModule("Uniques/shield"),
}
local output = {}

local mods = LoadModule("../Data/ModItemExclusive")

for id, mod in pairs(mods) do
	if id:find("^Divergent") then
		output[id] = {}
		for baseType, itemList in pairs(vestigialUniqueBaseTypes) do
			for _, itemText in ipairs(itemList) do
				if itemText:find("[\n}]" .. id:gsub("^Divergent", "")) then
					-- first row should be unique title
					local title = itemText:match("([^\n]+)\n")
						-- äöå are too powerful for pob (ascii only)
						:gsub("ä", "a"):gsub("ö", "o"):gsub("å", "a")
					table.insert(output[id], title)
					break
				end
			end
		end
	end
end

-- pob's unique ids aren't perfect and are originally automatically generated,
-- which means many items have the wrong id despite the mod itself being
-- correct. these have been cross-referenced with the wiki, which is manually
-- confirmed to be correct in most cases. some of these also have ids that
-- aren't the same as the original. usually in cases where the effect is nerfed
-- in some way
local manualFixes = {
	-- no clue and these are not important anyway
	["DivergentAbyssJewelSocketUnique__3"] = false,
	["DivergentAbyssJewelSocketUnique__5"] = false,
	["DivergentAbyssJewelSocketUnique__7"] = false,
	-- this only seems to come from boots despite the item ID being on multiple base types
	["DivergentAdditionalCurseOnEnemiesUnique__1"] = { "Windscream" },
	["DivergentAbyssJewelSocketUnique__10"] = { "Command of the Pit" },
	["DivergentAbyssJewelSocketUnique__15"] = { "Shroud of the Lightless" },
	["DivergentAbyssJewelSocketUnique__18"] = { "Hale Negator" },
	["DivergentAllAttributesUnique__21"] = { "Forbidden Shako" },
	-- Skin of the Lords perhaps? The item can't actually be used as it is always corrupted
	["DivergentAllDefencesUnique__3"] = false,
	["DivergentAreaOfEffectPerEnemyKilledRecentlyCapped25Unique__1"] = { "Zeel's Amplifier" },
	["DivergentArmourAppliesToChaosDamagePercentUnique__1"] = { "The Fourth Vow" },
	["DivergentArmourAppliesToLightningDamagePercentUnique__1"] = { "Doryani's Prototype" },
	["DivergentBleedingImmunityUnique__1"] = { "Death's Door" },
	["DivergentCannotBeFrozenUnique__1"] = { "Vix Lunaris" },
	-- Complete mystery
	["DivergentCannotBeFrozenUnique__6"] = false,
	["DivergentChaosDamageDoesNotBypassEnergyShieldPercentUnique__2"] = { "Shavronne's Wrappings" },
	["DivergentFireDamageCanPoisonAndLessDurationUnique__1"] = { "Volkuur's Guidance" },
	["DivergentColdDamageCanPoisonAndLessDurationUnique__1"] = { "Volkuur's Guidance" },
	["DivergentLightningDamageCanPoisonAndLessDurationUnique__1"] = { "Volkuur's Guidance" },
	["DivergentConvertFireToChaosUniqueBodyInt4Updated"] = { "Infernal Mantle" },
	["DivergentCorpseWalkUnique__1"] = { "Corpsewalker" },
	["DivergentCurseOnHitCriticalWeaknessUniqueNewUnique__1"] = { "Oskarm" },
	["DivergentCurseOnHitTemporalChainsUnique__1"] = { "Asenath's Gentle Touch" },
	["DivergentEnemyExtraDamageRollsOnFullLifeUnique__2"] = { "Foxshade" },
	["DivergentEvasionIncreasedByUncappedColdResistanceUnique__2"] = { "The Perfect Form" },
	["DivergentGhostFurnace1"] = { "The Draugur's Lantern" },
	["DivergentIncreasedItemRarityUniqueShieldStrDex2"] = { "Wheel of the Stormsail" },
	["DivergentItemFoundRarityIncreaseUnique__7"] = { "Sadima's Touch" },
	["DivergentItemHasSixLinkedWhiteSocketsUniqueBodyInt6"] = { "Tabula Rasa" },
	["DivergentKeystoneAncestralBondUnique__2"] = { "Wilma's Requital" },
	["DivergentKeystoneCallToArmsUnique__2_"] = { "Mutewind Pennant" },
	["DivergentKeystoneCorruptedSoulUnique__2_"] = { "Mahuxotl's Machination" },
	["DivergentKeystoneEternalYouthUnique__2_"] = { "Mahuxotl's Machination" },
	["DivergentKeystoneSoulTetherUnique__2"] = { "Mahuxotl's Machination" },
	["DivergentKeystoneVaalPactUnique__2"] = { "Mahuxotl's Machination" },
	["DivergentLifeFromEnergyShieldArmourPercentUnique__1"] = { "The Apostate" },
	["DivergentLocalIncreaseSocketedGemLevelUnique__8"] = { "Honourhome" },
	["DivergentLocalIncreaseSocketedProjectileGemLevelUnique__1"] = { "Black Zenith" },
	["DivergentOnslaughtBuffOnKillUniqueHelmet1"] = { "Thrillsteel" },
	["DivergentPetrificationStatueUnique__1"] = { "Gorgon's Gaze" },
	["DivergentEnemiesCantLifeLeechUnique__1"] = { "Sin Trek" },
	["DivergentGrantsSummonArbalistsSkillUnique__1_"] = { "Vorana's March" },
	["DivergentMeleeWeaponCriticalStrikeMultiplierReplicaUniqueHelmetStr3"] = { "Replica Abyssus" },
	["DivergentMinimumEnduranceChargesUnique__1"] = { "Ralakesh's Impatience" },
	["DivergentMinimumFrenzyChargesUnique__1"] = { "Ralakesh's Impatience" },
	["DivergentMinimumPowerChargesUnique__1"] = { "Ralakesh's Impatience" },
	["DivergentZealotsOathUnique__1"] = { "Geofri's Sanctuary" },
	["DivergentSpellsCriticalChanceFinalRepeatUnique__1"] = { "Plume of Pursuit" },
	["DivergentSpellDamageFromMainHandWeaponDamageUnique__1"] = { "Sandstorm Visage" },
	["DivergentSocketedGemsSupportedByBlasphemyUnique__3"] = { "Heretic's Veil" },
	["DivergentSelfOfferingEffectUnique__2"] = { "The Queen's Hunger" },
	["DivergentSavageBarnacleMod_1"] = { "Seablister" },
	["DivergentRepeatingShockwaveUnique__1"] = { "Abberath's Hooves" },
	["DivergentRageCasterStats50PercentValueUnique__1"] = { "Ravenous Passion" },
	["DivergentPurityOfFireUnique__6"] = { "Doryani's Delusion" },
	["DivergentPurityOfIceUnique__6"] = { "Doryani's Delusion" },
	["DivergentPurityOfLightningUnique__6"] = { "Doryani's Delusion" },
	["DivergentProjectileSpeedUnique___1"] = { "Winds of Change" },
	["DivergentPhasingIfBlockedRecentlyReplicaUnique__1"] = { "Replica Mistwall" },
	["DivergentMovementVelocityPerEvasionLesserUnique__1"] = { "Queen of the Forest" },
	["DivergentMovementVelocityOverrideUnique__2"] = { "Replica Stampede" },
	["DivergentModifyableWhileCorruptedUnique__2"] = { "Hands of the High Templar" },
	-- No clue, but looks like a dupe anyyway
	["DivergentCannotBeFrozenOrChilledUnique__2"] = false,
}

for k, v in pairs(manualFixes) do
	output[k] = v and v or nil
end
utils.saveTableToFile("../Data/Vestigial.lua", output)
