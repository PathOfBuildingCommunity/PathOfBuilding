describe("TestVestigialReducedImplicits", function()
	local function equip(base, lines, explicit)
		local raw = "Rarity: RARE\nVestigial Test\n" .. base .. "\nImplicits: " .. #lines .. "\n"
		for _, line in ipairs(lines) do
			raw = raw .. "{vestigial}" .. line .. "\n"
		end
		build.itemsTab:CreateDisplayItemFromRaw(raw .. (explicit or ""))
		local item = build.itemsTab.displayItem
		build.itemsTab:AddDisplayItem()
		return item
	end

	local function calculate(lines, options)
		options = options or { }
		newBuild()
		build.skillsTab:PasteSocketGroup((options.skill or "Arc") .. " 20/0  1\n")
		build.mainSocketGroup = 1
		build.configTab.input.customMods = options.custom or ""
		build.configTab.input.multiplierRage = options.rage or 0
		build.configTab:BuildModList()
		local item = equip(options.base or "Iron Hat", lines, options.explicit)
		if options.configure then
			options.configure()
		end
		for _ = 1, 5 do
			runCallback("OnFrame")
		end
		local env = build.calcsTab.mainEnv
		local skill = env.player.mainSkill
		assert.are.equal(options.skill or "Arc", skill.activeEffect.grantedEffect.name)
		local result = copyTable(build.calcsTab.mainOutput, true)
		result.item = item
		result.spellIncrease = skill.skillModList:Sum("INC", { flags = ModFlag.Spell }, "Damage")
		result.evasionIncrease = skill.skillModList:Sum("INC", { }, "Evasion")
		result.damageMore = env.player.modDB:More(skill.skillCfg, "Damage")
		result.attackDamageMore = env.player.modDB:More({ flags = ModFlag.Attack }, "Damage")
		local armourIncreases = env.player.modDB:Tabulate("INC", nil, "Armour")
		result.armourIncreaseSource = armourIncreases[1] and armourIncreases[1].mod.source
		for _, value in ipairs(env.player.modDB:Tabulate("MAX", nil, "ArmourIncreasedByOvercappedFireRes")) do
			if value.value == 100 then
				result.fullArmourSource = value.mod.source
			end
		end
		result.hitTaken = build.calcsTab.calcs.takenHitFromDamage(1000, "Lightning", env.player)
		result.pools = build.calcsTab.calcs.reducePoolsByDamage({ Life = 1000, Mana = 1000, EnergyShield = options.poolEnergyShield or 0, Ward = 0 }, { Chaos = 200 }, env.player)
		return result
	end

	local form = "Armour is increased by Overcapped Fire Resistance"
	local formHalf = "Armour is increased by 50% of Overcapped Fire Resistance"
	local eye = "Increases and Reductions to your Evasion Rating also apply to your Spell Damage"
	local eyeHalf = eye .. " at 50% of their value"
	local rage = "Rage grants Spell Damage instead of Attack Damage"
	local rageHalf = rage .. " at 50% of the value"
	local apostate = "Gain Maximum Life instead of Maximum Energy Shield from Equipped Armour Items"
	local apostateHalf = apostate .. " at 50% of the value"
	local doryani = "Armour also applies to Lightning Damage taken from Hits"
	local doryaniTenth = "10% of " .. doryani
	local ivory = "Chaos Damage is taken from Mana before Life"
	local ivoryHalf = "50% of " .. ivory
	local entropic = "Critical Strikes with Spells inflict Impale"
	local entropicHalf = "Critical Strikes with Spells have 50% chance to inflict Impale"
	local gamble = "When Hit, gain a random Movement Speed modifier from 40% reduced to 100% increased, until Hit again"
	local gambleHalf = "When Hit, gain a random Movement Speed modifier from 20% reduced to 50% increased, until Hit again"
	local asenath = "Trigger a Socketed Spell when you Attack with a Bow, with a 0.3 second Cooldown"
	local asenathTenth = "10% chance to " .. asenath

	it("ingests reduced Vestigial implicit text as complete item modifiers", function()
		for _, line in ipairs({ formHalf, eyeHalf, rageHalf, apostateHalf, doryaniTenth, ivoryHalf, entropicHalf, gambleHalf, asenathTenth }) do
			local item = new("Item"):Item("Rarity: UNIQUE\nVestigial Test\nIron Hat\nImplicits: 1\n{vestigial}" .. line .. "\n")
			assert.is_true(item.vestigial)
			assert.is_nil(item.implicitModLines[1].extra, line)
			assert.is_true(#item.implicitModLines[1].modList > 0)
		end
	end)

	it("scales overcapped fire resistance into armour once using the strongest source", function()
		local options = { custom = "+1000 to Armour\n+200% to Fire Resistance" }
		local control = calculate({ }, options)
		local half = calculate({ formHalf }, options)
		local full = calculate({ form }, options)
		assert.are.equal(math.floor(control.Armour * (1 + control.FireResistOverCap / 200) + 0.5), half.Armour)
		assert.are.equal(math.floor(control.Armour * (1 + control.FireResistOverCap / 100) + 0.5), full.Armour)
		assert.are.equal(full.Armour, calculate({ formHalf, form }, options).Armour)
		assert.are.equal(half.Armour, calculate({ formHalf, formHalf }, options).Armour)
		options.custom = options.custom .. "\n" .. form
		local mixedSources = calculate({ formHalf }, options)
		assert.are.equal(mixedSources.fullArmourSource, mixedSources.armourIncreaseSource)
		options.custom = "+1000 to Armour"
		assert.are.equal(calculate({ }, options).Armour, calculate({ formHalf }, options).Armour)
	end)

	it("converts evasion increases and reductions into spell damage at the stated value", function()
		for _, increase in ipairs({ "100% increased Evasion Rating", "100% reduced Evasion Rating" }) do
			local options = { custom = increase .. "\n100% more Evasion Rating" }
			local control = calculate({ }, options)
			local half = calculate({ eyeHalf }, options)
			local full = calculate({ eye }, options)
			assert.are.equal(control.spellIncrease + control.evasionIncrease / 2, half.spellIncrease)
			assert.are.equal(control.spellIncrease + control.evasionIncrease, full.spellIncrease)
			assert.is_true(half.AverageDamage > math.min(control.AverageDamage, full.AverageDamage))
			assert.is_true(half.AverageDamage < math.max(control.AverageDamage, full.AverageDamage))
			assert.are.equal(full.spellIncrease, calculate({ eyeHalf, eye }, options).spellIncrease)
		end
	end)

	it("scales bounded evasion tags and keeps conversion out of attack damage", function()
		local options = { configure = function()
			build.configTab.modList:NewMod("Multiplier:TestEvasion", "BASE", 3, "Test")
			build.configTab.modList:NewMod("Evasion", "INC", 10, "Test", { type = "Multiplier", var = "TestEvasion", limit = 20, limitTotal = true })
		end }
		local control = calculate({ }, options)
		local half = calculate({ eyeHalf }, options)
		assert.are.equal(control.spellIncrease + control.evasionIncrease / 2, half.spellIncrease)
		assert.is_true(half.AverageDamage > control.AverageDamage)
		options = { skill = "Split Arrow", custom = "100% increased Evasion Rating", configure = function()
			equip("Short Bow", { })
		end }
		assert.are.equal(calculate({ }, options).AverageDamage, calculate({ eyeHalf }, options).AverageDamage)
	end)

	it("scales post-effect rage spell damage while replacing attack damage", function()
		local options = { custom = "Gain 1 Rage on Attack Hit\n50% increased Rage Effect", rage = 20 }
		local control = calculate({ }, options)
		local half = calculate({ rageHalf }, options)
		local full = calculate({ rage }, options)
		assert.are.equal(30, half.RageEffect)
		assert.are.equal(1.15, half.damageMore)
		assert.are.equal(1.3, full.damageMore)
		assert.are.equal(1.3, control.attackDamageMore)
		assert.are.equal(1, half.attackDamageMore)
		assert.are.equal(1, full.attackDamageMore)
		assert.is_true(control.AverageDamage < half.AverageDamage and half.AverageDamage < full.AverageDamage)
		assert.are.equal(full.damageMore, calculate({ rageHalf, rage }, options).damageMore)
		options.rage = 0
		assert.are.equal(1, calculate({ rageHalf }, options).damageMore)
	end)

	it("gains half the armour-item energy shield as life without retaining the replaced energy shield", function()
		local options = { base = "Vaal Regalia", custom = "100% increased maximum Life\n100% increased maximum Energy Shield" }
		local control = calculate({ }, options)
		local half = calculate({ apostateHalf }, options)
		local full = calculate({ apostate }, options)
		assert.is_true(control.EnergyShield > 0)
		assert.are.equal(0, full.EnergyShield)
		assert.are.equal(0, half.EnergyShield)
		assert.are.equal(control.Life + (full.Life - control.Life) / 2, half.Life)
		assert.are.equal(full.Life, calculate({ apostateHalf, apostate }, options).Life)
		options.configure = function()
			equip("Hubris Circlet", { })
			equip("Twig Spirit Shield", { })
		end
		control = calculate({ }, options)
		half = calculate({ apostateHalf }, options)
		full = calculate({ apostate }, options)
		assert.are.equal(0, half.EnergyShield)
		assert.are.equal(control.Life + (full.Life - control.Life) / 2, half.Life)
	end)

	it("applies one tenth of armour to lightning hits through the final mitigation calculation", function()
		local options = { base = "Simple Robe", custom = "+10000 to Armour" }
		local control = calculate({ }, options)
		local tenth = calculate({ doryaniTenth }, options)
		local full = calculate({ doryani }, options)
		assert.are.equal(1000, tenth.LightningEffectiveAppliedArmour)
		assert.are.equal(0, tenth.FireEffectiveAppliedArmour)
		assert.is_true(full.hitTaken < tenth.hitTaken and tenth.hitTaken < control.hitTaken)
		assert.is_true(control.LightningMaximumHitTaken < tenth.LightningMaximumHitTaken and tenth.LightningMaximumHitTaken < full.LightningMaximumHitTaken)
	end)

	it("redirects half of chaos damage to mana and retains the shared redirection cap", function()
		local options = { base = "Simple Robe", custom = "+1000 to maximum Life\n+1000 to maximum Mana" }
		local half = calculate({ ivoryHalf }, options)
		assert.are.equal(50, half.ChaosMindOverMatter)
		assert.are.equal(900, half.pools.Life)
		assert.are.equal(900, half.pools.Mana)
		local full = calculate({ ivory }, options)
		assert.are.equal(1000, full.pools.Life)
		assert.are.equal(800, full.pools.Mana)
		options.custom = options.custom .. "\n60% of Damage is taken from Mana before Life"
		assert.are.equal(40, calculate({ ivoryHalf }, options).ChaosMindOverMatter)
		options.custom = "+1000 to maximum Life\n+1000 to maximum Mana\n+100 to maximum Energy Shield\nEldritch Battery"
		options.poolEnergyShield = 100
		local battery = calculate({ ivoryHalf }, options)
		assert.are.equal(900, battery.pools.Life)
		assert.are.equal(900, battery.pools.Mana)
		assert.are.equal(100, battery.pools.EnergyShield)
	end)

	it("halves critical spell impale chance and actual impale damage without affecting non-critical hits", function()
		local options = { base = "Wool Gloves", skill = "Blade Vortex" }
		local half = calculate({ entropicHalf }, options)
		local full = calculate({ entropic }, options)
		assert.are.equal(50, half.ImpaleChanceOnCrit)
		assert.are.equal(0, half.ImpaleChance)
		assert.is_true(half.ImpaleDPS > 0)
		-- ImpaleDPS subtracts one from a multiplier, then applies total DPS.
		-- Bound binary64 round-off at the pre-subtraction DPS scale.
		assert.is_true(math.abs(full.ImpaleDPS / 2 - half.ImpaleDPS) <= full.TotalDPS * 2^-48)
		options.skill = "Split Arrow"
		options.configure = function() equip("Short Bow", { }) end
		local attack = calculate({ entropicHalf }, options)
		assert.is_true(attack.TotalDPS > 0)
		assert.is_nil(attack.ImpaleDPS)
	end)

	it("preserves saved Gamblesprint rolls and applies the reduced range once", function()
		for _, value in ipairs({ -40, 0, 30, 100 }) do
			newBuild()
			build.configTab.input.GamblesprintMovementSpeed = value
			build.configTab:BuildModList()
			equip("Wool Shoes", { gambleHalf, gambleHalf })
			for _ = 1, 5 do runCallback("OnFrame") end
			assert.are.equal(value / 2, build.calcsTab.mainEnv.player.modDB:Sum("INC", nil, "MovementSpeed"))
			assert.are.equal(1 + value / 200, build.calcsTab.mainOutput.MovementSpeedMod)
			loadBuildFromXML(build:SaveDB("code"))
			assert.are.equal(value, build.configTab.input.GamblesprintMovementSpeed)
			assert.are.equal(1 + value / 200, build.calcsTab.mainOutput.MovementSpeedMod)
		end
		newBuild()
		build.configTab.input.GamblesprintMovementSpeed = 100
		build.configTab:BuildModList()
		local item = equip("Wool Shoes", { gambleHalf, gamble })
		for _ = 1, 5 do runCallback("OnFrame") end
		assert.are.equal(2, build.calcsTab.mainOutput.MovementSpeedMod)
		build.itemsTab:DeleteItem(item, true)
		runCallback("OnFrame")
		assert.are.equal(1, build.calcsTab.mainOutput.MovementSpeedMod)
	end)

	local function triggerRate(lines, weapon, attack, spellSlot)
		newBuild()
		equip("Iron Hat", lines, "Sockets: B\n")
		equip(weapon or "Short Bow", { }, "Sockets: G\n")
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\n" .. (attack or "Split Arrow") .. " 20/0  1\n")
		build.skillsTab:PasteSocketGroup("Slot: " .. (spellSlot or "Helmet") .. "\nArc 20/0  1\n")
		build.mainSocketGroup = 2
		for _ = 1, 5 do runCallback("OnFrame") end
		local env = build.calcsTab.mainEnv
		assert.are.equal("Arc", env.player.mainSkill.activeEffect.grantedEffect.name)
		return build.calcsTab.mainOutput.SkillTriggerRate or 0
	end

	it("applies the bow trigger probability at the final rate without leaking between slots", function()
		local full = triggerRate({ asenath })
		local tenth = triggerRate({ asenathTenth })
		assert.is_true(full > 0 and full < 1 / 0.3)
		assert.is_true(math.abs(full - tenth * 10) <= full * 2^-48)
		assert.are.equal(full, triggerRate({ asenathTenth, asenath }))
		assert.are.equal(full, triggerRate({ asenath, asenathTenth }))
		assert.are.equal(tenth, triggerRate({ asenathTenth, asenathTenth }))
		assert.are.equal(0, triggerRate({ asenathTenth }, "Rusted Sword", "Cleave"))
		assert.are.equal(0, triggerRate({ asenathTenth }, nil, nil, "Body Armour"))
	end)
end)
