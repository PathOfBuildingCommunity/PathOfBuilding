-- Path of Building
--
-- Module: Calcs View
-- Configures the display grid in the calculations breakdown tab
--
local grid = ...

local function fieldNames(pre, suf, spec)
	return { 
		spec:match("p") and (pre.."_physical"..suf) or false, 
		spec:match("l") and (pre.."_lightning"..suf) or false, 
		spec:match("c") and (pre.."_cold"..suf) or false, 
		spec:match("f") and (pre.."_fire"..suf) or false, 
		spec:match("h") and (pre.."_chaos"..suf) or false, 
		spec:match("a") and (pre.."_damage"..suf) or false,
		spec:match("e") and (pre.."_elemental"..suf) or false
	}
end

local columnWidths = {
	160, 60,
	160, 60,
	160, 60,
	160, 95, 95, 95, 95, 95, 95, 70
}

local columns = { }

local skillList = { }
local skillPartList = { }
local auxSkillList = { }

columns[1] = {
	{
		{ "Attributes:" },
		{ "output", "Gear Strength:", "gear_strBase" },
		{ "output", "Gear Dexterity:", "gear_dexBase" },
		{ "output", "Gear Intelligence:", "gear_intBase" },
		{ "output", data.colorCodes.STRENGTH.."Strength^7:", "total_str" },
		{ "output", data.colorCodes.DEXTERITY.."Dexterity^7:", "total_dex" },
		{ "output", data.colorCodes.INTELLIGENCE.."Intelligence^7:", "total_int" },
		{ },
		{ "Monsters:" },
		{ "input", "Monster level:", "monster_level" },
		{ "output", "Experience:", "monster_xp", formatPercent },
		{ },
		{ "Life:" },
		{ "output", "Base from Tree:", "spec_lifeBase" },
		{ "output", "Inc. from Tree %:", "spec_lifeInc" },
		{ "output", "Base from Gear:", "gear_lifeBase" },
		{ "output", "Inc. from Gear %:", "gear_lifeInc" },
		{ "output", "Total:", "total_life", formatRound },
		{ "output", "Reserved:", "total_lifeReserved", formatRound },
		{ "output", "Unreserved:", "total_lifeUnreserved", formatRound },
		{ "output", "Unreserved %:", "total_lifeUnreservedPercent", formatPercent },
		{ "output", "Regen from Tree %:", "spec_lifeRegenPercent" },
		{ "output", "Base Regen from Gear:", "gear_lifeRegenBase" },
		{ "output", "Regen from Gear %:", "gear_lifeRegenPercent" },
		{ "output", "Total Regen:", "total_lifeRegen", getFormatRound(1) },
		{ },
		{ "Mana:" },
		{ "output", "Base from Tree:", "spec_manaBase" },
		{ "output", "Inc. from Tree %:", "spec_manaInc" },
		{ "output", "Base from Gear:", "gear_manaBase" },
		{ "output", "Inc. from Gear:", "gear_manaInc" },
		{ "output", "Total:", "total_mana", formatRound },
		{ "output", "Reserved:", "total_manaReserved", formatRound },
		{ "output", "Unreserved:", "total_manaUnreserved", formatRound },
		{ "output", "Unreserved %:", "total_manaUnreservedPercent", formatPercent },
		{ "output", "Inc. Regen from Tree %:", "spec_manaRegenInc" },
		{ "output", "Base Regen from Gear:", "gear_manaRegenBase" },
		{ "output", "Inc. Regen from Gear %:", "gear_manaRegenInc" },
		{ "output", "Total Regen:", "total_manaRegen", getFormatRound(1) },
		{ },
		{ "Supporting Skills:" },
	}, 
	auxSkillList
}

columns[3] = {
	{
		{ "Energy Shield:" },
		{ "output", "Base from Tree:", "spec_energyShieldBase" },
		{ "output", "Inc. from Tree %:", "spec_energyShieldInc" },
		{ "output", "Base from Gear:", "total_gear_energyShieldBase" },
		{ "output", "Inc. from Gear %:", "gear_energyShieldInc" },
		{ "output", "Total:", "total_energyShield", formatRound },
		{ "output", "Recharge rate:", "total_energyShieldRecharge", getFormatRound(1) },
		{ "output", "Recharge delay:", "total_energyShieldRechargeDelay", getFormatSec(2) },
		{ "output", "Regen:", "total_energyShieldRegen", getFormatRound(1) },
		{ },
		{ "Evasion:" },
		{ "output", "Base from Tree:", "spec_evasionBase" },
		{ "output", "Inc. from Tree %:", "spec_evasionInc" },
		{ "output", "Base from Gear:", "total_gear_evasionBase" },
		{ "output", "Inc. from Gear %:", "gear_evasionInc" },
		{ "output", "Total:", "total_evasion", formatRound },
		{ "input", "Use Monster Level?", "misc_evadeMonsterLevel", "check" },
		{ "output", "Evade Chance:", "total_evadeChance", formatPercent },
		{ },
		{ "Armour:" },
		{ "output", "Base from Tree:", "spec_armourBase" },
		{ "output", "Inc. from Tree %:", "spec_armourInc" },
		{ "output", "Base from Gear:", "total_gear_armourBase" },
		{ "output", "Inc. from Gear %:", "gear_armourInc" },
		{ "output", "Total:", "total_armour", formatRound },
		{ },
		{ "Block and Stun:" },
		{ "output", "Attack Block Chance:", "total_blockChance", formatPercent },
		{ "output", "Spell Block Chance:", "total_spellBlockChance", formatPercent },
		{ "output", "Chance to Avoid Stun:", "stun_avoidChance", formatPercent },
		{ "output", "Stun Duration on You:", "stun_duration", getFormatSec(2) },
		{ "output", "Block Duration on You:", "stun_blockDuration", getFormatSec(2) },
		{ "output", "Duration on Enemies:", "stun_enemyDuration", getFormatSec(2) },
		{ "output", "Enemy Threshold Mod:", "stun_enemyThresholdMod", formatPercent },
	}
}

columns[5] = {
	{
		{ "Conditions:" },
		{ "input", "Always on Low Life?", "Cond_LowLife", "check" },
		{ "input", "Always on Full Life?", "Cond_FullLife", "check" },
		{ },
		{ "Buffs:" },
		{ "input", "Power Charges?", "buff_power", "check" },
	}, {
		flag = "havePower",
		{ "output", "Max Power:", "powerMax" },
	}, {
		{ "input", "Frenzy Charges?", "buff_frenzy", "check" },
	}, {
		flag = "haveFrenzy",
		{ "output", "Max Frenzy:", "frenzyMax" },
	}, {
		{ "input", "Endurance Charges?", "buff_endurance", "check" },
	}, {
		flag = "haveEndurance",
		{ "output", "Max Endurance:", "enduranceMax" },
	}, {
		{ "input", "Onslaught?", "CondBuff_Onslaught", "check" },
		{ "input", "Phasing?", "CondBuff_Phasing", "check" },
		{ "input", "Fortify?", "CondBuff_Fortify", "check" },
		{ "input", "Using a Flask?", "CondBuff_UsingFlask", "check" },
		{ "input", "Pendulum of Dest.?", "buff_pendulum", "check" },
	}, {
		{ },
		{ "For Effective DPS:" },
		{ "input", "Enemy is Cursed?", "CondEff_EnemyCursed", "check" },
		{ "input", "Enemy is Bleeding?", "CondEff_EnemyBleeding", "check" },
		{ "input", "Enemy is Poisoned?", "CondEff_EnemyPoisoned", "check" },
		{ "input", "Enemy is Burning?", "CondEff_EnemyBurning", "check" },
		{ "input", "Enemy is Ignited?", "CondEff_EnemyIgnited", "check" },
		{ "input", "Enemy is Chilled?", "CondEff_EnemyChilled", "check" },
		{ "input", "Enemy is Frozen?", "CondEff_EnemyFrozen", "check" },
		{ "input", "Enemy is Shocked?", "CondEff_EnemyShocked", "check" },
		{ "input", "Enemy Phys. Red. %:", "effective_physicalRed" },
		{ "input", "Enemy Fire Resist:", "effective_fireResist" },
		{ "input", "Enemy Cold Resist:", "effective_coldResist" },
		{ "input", "Enemy Lightning Resist:", "effective_lightningResist" },
		{ "input", "Enemy Chaos Resist:", "effective_chaosResist" },
		{ "input", "Enemy is a Boss?", "effective_enemyIsBoss", "check" },
		{ },
		{ "Crit Chance:" },
	}, {
		flag = "attack",
		{ "output", "Weapon Crit %:", "gear_weapon1_critChanceBase" },
	}, {
		{ "output", "Tree Global Crit %:", "spec_critChanceInc" },
		{ "output", "Gear Global Crit %:", "gear_global_critChanceInc" },
	}, {
		flag = "spell",
		{ "output", "Tree Spell Crit %:", "spec_spell_critChanceInc" },
		{ "output", "Gear Spell Crit %:", "gear_spell_critChanceInc" },
	}, {
		flag = "melee",
		{ "output", "Tree Melee Crit %:", "spec_melee_critChanceInc" },
	}, {
		flag = "totem",
		{ "output", "Tree Totem Crit %:", "spec_totem_critChanceInc" },
	}, {
		flag = "trap",
		{ "output", "Tree Trap Crit %:", "spec_trap_critChanceInc" },
	}, {
		flag = "mine",
		{ "output", "Tree Mine Crit %:", "spec_mine_critChanceInc" },
	}, {
		{ "output", "Crit Chance:", "total_critChance", getFormatPercent(2) },
		{ "output", "Tree Global Multi %:", "spec_critMultiplier" },
		{ "output", "Gear Global Multi %:", "gear_critMultiplier" },
	}, {
		flag = "spell",
		{ "output", "Tree Spell Multi %:", "spec_spell_critMultiplier" },
	}, {
		flag = "melee",
		{ "output", "Tree Melee Multi %:", "spec_melee_critMultiplier" },
	}, {
		flag = "totem",
		{ "output", "Tree Totem Multi %:", "spec_totem_critMultiplier" },
	}, {
		flag = "trap",
		{ "output", "Tree Trap Multi %:", "spec_trap_critMultiplier" },
	}, {
		flag = "mine",
		{ "output", "Tree Mine Multi %:", "spec_mine_critMultiplier" },
	}, {
		{ "output", "Multiplier:", "total_critMultiplier", formatPercent },
	}, {
		flag = "attack",
		{ },
		{ "Accuracy:" },
		{ "output", "Tree Accuracy+:", "spec_accuracyBase" },
		{ "output", "Tree Accuracy %:", "spec_accuracyInc" },
		{ "output", "Gear Accuracy+:", "gear_accuracyBase" },
		{ "output", "Gear Accuracy %:", "gear_accuracyInc" },
		{ "output", "Total Accuracy:", "total_accuracy", formatRound },
		{ "input", "Use Monster Level?", "misc_hitMonsterLevel", "check" },
		{ "output", "Chance to Hit:", "total_hitChance", formatPercent },
	}
}

columns[7] = {
	{
		{ "input", "View Skill Details:", "skill_number", "choice", 4, skillList },
	}, {
		flag = "multiPart",
		{ "input", "Skill Part:", "skill_part", "choice", 2, skillPartList },
	}, {
		{ },
		{ "input", "Mode:", "misc_buffMode", "choice", 2, { {label="Unbuffed",val="UNBUFFED"}, {label="With buffs",val="BUFFED"}, {label="Effective DPS with buffs",val="EFFECTIVE"} } },
		{ },
	}, {
		flag = "attack",
		{ { "Attack:", "Physical", "Lightning", "Cold", "Fire", "Chaos", "Combined", "Elemental" } },
	}, {
		flag = "weapon1Attack",
		{ "output", "Main Hand:", "gear_weapon1_name", "string", 3 },
		{ "output", "Weapon Min:", fieldNames("gear_weapon1", "Min", "plcfh") },
		{ "output", "Weapon Max:", fieldNames("gear_weapon1", "Max", "plcfh") },
		{ "output", "Weapon APS:", "gear_weapon1_attackRate" },
		{ "output", "Weapon DPS:", fieldNames("gear_weapon1", "DPS", "plcfhae"), getFormatRound(2) },
	}, {
		flag = "weapon2Attack",
		{ "output", "Off Hand:", "gear_weapon2_name", "string", 3 },
		{ "output", "Weapon Min:", fieldNames("gear_weapon2", "Min", "plcfh") },
		{ "output", "Weapon Max:", fieldNames("gear_weapon2", "Max", "plcfh") },
		{ "output", "Weapon APS:", "gear_weapon2_attackRate" },
		{ "output", "Weapon DPS:", fieldNames("gear_weapon2", "DPS", "plcfhae"), getFormatRound(2) },
	}, {
		flag = "attack",
		{ "output", "Tree Attack Dmg %:", fieldNames("spec_attack", "Inc", "pa") },
		{ "output", "Tree Weapon Dmg %:", fieldNames("spec_weapon", "Inc", "plcfae") },
		{ "output", "Gear Weapon Dmg %:", fieldNames("gear_weapon", "Inc", "plcfae") },
	}, {
		flag = "spell",
		{ { "Spell:", "Physical", "Lightning", "Cold", "Fire", "Chaos", "Combined", "Elemental" } },
		{ "output", "Tree Spell Dmg %:", fieldNames("spec_spell", "Inc", "a") },
		{ "output", "Gear Spell Dmg %:", fieldNames("gear_spell", "Inc", "a") },
	}, {
		flag = "projectile",
		{ "output", "Tree Projectile Dmg %:", fieldNames("spec_projectile", "Inc", "a") },
		{ "output", "Gear Projectile Dmg %:", fieldNames("gear_projectile", "Inc", "a") },
	}, {
		flag = "aoe",
		{ "output", "Tree Area Dmg %:", fieldNames("spec_aoe", "Inc", "a") },
		{ "output", "Gear Area Dmg %:", fieldNames("gear_aoe", "Inc", "a") },
	}, {
		flag = "totem",
		{ "output", "Tree Totem Dmg %:", fieldNames("spec_totem", "Inc", "a") },
		{ "output", "Gear Totem Dmg %:", fieldNames("gear_totem", "Inc", "a") },
	}, {
		flag = "trap",
		{ "output", "Tree Trap Dmg %:", fieldNames("spec_trap", "Inc", "a") },
		{ "output", "Gear Trap Dmg %:", fieldNames("gear_trap", "Inc", "a") },
	}, {
		flag = "mine",
		{ "output", "Tree Mine Dmg %:", fieldNames("spec_mine", "Inc", "a") },
		{ "output", "Gear Mine Dmg %:", fieldNames("gear_mine", "Inc", "a") },
	}, {
		{ "output", "Tree Global %:", fieldNames("spec", "Inc", "plcfhe") },
		{ "output", "Gear Global %:", fieldNames("gear", "Inc", "plcfhae") },
	}, {
		flag = "attack",
		{ "output", "Gear Attack Min+:", fieldNames("gear_attack", "Min", "plcfh") },
		{ "output", "Gear Attack Max+:", fieldNames("gear_attack", "Max", "plcfh") },
	}, {
		flag = "spell",
		{ "output", "Gear Spell Min+:", fieldNames("gear_spell", "Min", "plcfh") },
		{ "output", "Gear Spell Max+:", fieldNames("gear_spell", "Max", "plcfh") },
	}, {
		flag = "attack",
		{ "output", "Tree Attack Speed %:", "spec_attackSpeedInc" },
		{ "output", "Gear Attack Speed %:", "gear_attackSpeedInc" },
		{ "output", "Tree Attack&Cast Sp. %:", "spec_speedInc" },
		{ "output", "Gear Attack&Cast Sp. %:", "gear_speedInc" },
		{ "output", "Enemy Resists:", fieldNames("enemy", "Resist", "lcfh") },
		{ "output", "Attack Damage:", fieldNames("total", "", "plcfha") },
		{ "output", "Average Hit:", "total_averageHit", getFormatRound(1) },
		{ "output", "Attack Speed:", "total_speed", getFormatRound(2) },
		{ "output", "Attack Time:", "total_time", getFormatSec(2) },
		{ "output", "Attack DPS:", "total_dps", getFormatRound(1) },
	}, {
		flag = "spell",
		{ "output", "Tree Cast Speed %:", "spec_castSpeedInc" },
		{ "output", "Gear Cast Speed %:", "gear_castSpeedInc" },
		{ "output", "Tree Attack&Cast Sp. %:", "spec_speedInc" },
		{ "output", "Gear Attack&Cast Sp. %:", "gear_speedInc" },
		{ "output", "Enemy Resists:", fieldNames("enemy", "Resist", "lcfh") },
		{ "output", "Spell Damage:", fieldNames("total", "", "plcfha") },
		{ "output", "Average Hit:", "total_averageHit", getFormatRound(1) },
		{ "output", "Cast Rate:", "total_speed", getFormatRound(2) },
		{ "output", "Cast Time:", "total_time", getFormatSec(2) },
		{ "output", "Spell DPS:", "total_dps", getFormatRound(1) },
	}, {
		flag = "cast",
		{ "output", "Tree Cast Speed %:", "spec_castSpeedInc" },
		{ "output", "Gear Cast Speed %:", "gear_castSpeedInc" },
		{ "output", "Tree Attack&Cast Sp. %:", "spec_speedInc" },
		{ "output", "Gear Attack&Cast Sp. %:", "gear_speedInc" },
		{ "output", "Enemy Resists:", fieldNames("enemy", "Resist", "lcfh") },
		{ "output", "Secondary Damage:", fieldNames("total", "", "plcfha") },
		{ "output", "Average Hit:", "total_averageHit", getFormatRound(1) },
		{ "output", "Cast Rate:", "total_speed", getFormatRound(2) },
		{ "output", "Cast Time:", "total_time", getFormatSec(2) },
	}, {
		{ "output", "Mana Cost:", "total_manaCost", formatRound }
	}, {
		flag = "projectile",
		{ "output", "Projectile Count:", "total_projectileCount" },
		{ "output", "Tree Pierce Chance %:", "spec_pierceChance" },
		{ "output", "Gear Pierce Chance %:", "gear_pierceChance" },
		{ "output", "Pierce Chance:", "total_pierce", formatPercent },
		{ "output", "Projectile Speed Mod:", "total_projectileSpeedMod", formatPercent },
	}, {
		flag = "aoe",
		{ "output", "AoE Radius Mod:", "total_aoeRadiusMod", formatPercent },
	}, {
		flag = "duration",
		{ "output", "Tree Duration %:", "spec_durationInc" },
		{ "output", "Skill Duration Mod:", "total_durationMod", formatPercent },
		{ "output", "Skill Duration:", "total_duration", getFormatSec(2) },
	}, {
		flag = "trap",
		{ "output", "Active Trap Limit:", "total_activeTrapLimit" },
		{ "output", "Trap Cooldown:", "total_trapCooldown", getFormatSec(2) },
	}, {
		flag = "mine",
		{ "output", "Active Mine Limit:", "total_activeMineLimit" },
	}, {
		flag = "dot",
		{ "output", "Tree DoT Dmg %:", fieldNames("spec_dot", "Inc", "pfa") },
		{ "output", "Gear DoT Dmg %:", fieldNames("gear_dot", "Inc", "pfa") },
		{ "output", "DoT:", fieldNames("total", "Dot", "plcfha"), getFormatRound(1) },
	}, {
		flag = "bleed",
		{ "output", "Tree Bleed Chance %:", "spec_bleedChance" },
		{ "output", "Gear Bleed Chance %:", "gear_bleedChance" },
		{ "output", "Bleed Chance:", "bleed_chance", formatPercent },
		{ "output", "Bleed DPS:", "bleed_dps", getFormatRound(1) },
		{ "output", "Bleed Duration:", "bleed_duration", getFormatSec(2) },
	}, {
		flag = "poison",
		{ "output", "Tree Poison Chance %:", "spec_poisonChance" },
		{ "output", "Gear Poison Chance %:", "gear_poisonChance" },
		{ "output", "Tree Poison Dmg %:", "spec_poison_damageInc" },
		{ "output", "Poison Chance:", "poison_chance", formatPercent },
		{ "output", "Poison DPS:", "poison_dps", getFormatRound(1) },
		{ "output", "Poison Duration:", "poison_duration", getFormatSec(2) },
	}, {
		flag = "ignite",
		{ "output", "Tree Ignite Chance %:", "spec_igniteChance" },
		{ "output", "Gear Ignite Chance %:", "gear_igniteChance" },
		{ "output", "Ignite Chance:", "ignite_chance", formatPercent },
		{ "output", "Ignite DPS:", "ignite_dps", getFormatRound(1) },
		{ "output", "Ignite Duration:", "ignite_duration", getFormatSec(2) },
	}, {
		flag = "shock",
		{ "output", "Tree Shock Chance %:", "spec_shockChance" },
		{ "output", "Gear Shock Chance %:", "gear_shockChance" },
		{ "output", "Shock Chance:", "shock_chance", formatPercent },
		{ "output", "Shock Duration Mod:", "shock_durationMod", formatPercent },
	}, {
		flag = "freeze",
		{ "output", "Tree Freeze Chance %:", "spec_freezeChance" },
		{ "output", "Gear Freeze Chance %:", "gear_freezeChance" },
		{ "output", "Freeze Chance:", "freeze_chance", formatPercent },
		{ "output", "Freeze Duration Mod:", "freeze_durationMod", formatPercent },
	}
}

local function mkField(x, y, fieldType, name, format, width, list)
	local isFunc = type(format) == "function"
	grid:SetElem(x, y, { 
		type = fieldType,
		name = name,
		format = (isFunc or not format) and "number" or format,
		formatFunc = isFunc and format,
		align = (format == "string" or format == "choice") and "LEFT" or "RIGHT",
		width = width,
		list = list,
	})
end

local function mkFieldWithLabel(x, y, fieldType, label, name, format, width, list)
	grid:SetElem(x, y, {
		type = "label",
		text = label,
		align = "RIGHT"
	})
	if type(name) == "table" then
		for i, n in ipairs(name) do
			if n then
				mkField(x + i, y, fieldType, n, format)
			end
		end
	else
		mkField(x + 1, y, fieldType, name, format, width, list)
	end
end

local function mkFieldTable(x, y, tbl)
	for i, v in ipairs(tbl) do
		if #v == 1 then
			if type(v[1]) == "table" then
				for c, l in ipairs(v[1]) do
					grid:SetElem(x + c - 1, y + i - 1, { type = "label", text = l, align = c == 1 and "RIGHT" or "CENTER" })
				end
			else
				grid:SetElem(x, y + i - 1, { type = "label", text = v[1], align = "RIGHT" })
			end
		elseif #v > 1 then
			mkFieldWithLabel(x, y + i - 1, unpack(v))
		end
	end
end

local curFlags

return function(env, skills)
	wipeTable(skillList)
	if #skills > 0 then
		for i, skill in pairs(skills) do
			skillList[i] = { val = i, label = skill.displayLabel }
		end
	else
		skillList[1] = { val = 1, label = "No skills found. Go to the Skills page and create a skill." }
	end
	wipeTable(skillPartList)
	for i, partName in pairs(env.skillParts) do
		skillPartList[i] = { val = i, label = partName }
	end
	wipeTable(auxSkillList)
	for i in pairs(env.auxSkills) do
		auxSkillList[i] = { "output", "Skill "..i..":", "buff_label"..i, "string", 3 }
	end
	if curFlags then
		local noNewFlags = true
		local sub = copyTable(curFlags)
		for flag in pairs(env.skillFlags) do
			if curFlags[flag] then
				sub[flag] = nil
			else
				noNewFlags = false
				break
			end
		end
		if noNewFlags and not next(sub) then
			return
		end
	end
	curFlags = copyTable(env.skillFlags)

	grid:Clear()

	for colX, colTables in pairs(columns) do
		local y = 1
		for _, data in ipairs(colTables) do
			if not data.flag or curFlags[data.flag] then
				mkFieldTable(colX, y, data)
				y = y + #data
			end
		end
	end

	for col, width in ipairs(columnWidths) do
		grid:SetColWidth(col, width)
	end
end