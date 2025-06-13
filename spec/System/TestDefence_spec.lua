describe("TestDefence", function()
	before_each(function()
		newBuild()
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in setup()
	end)

	-- a small helper function to calculate damage taken from limited test parameters
	local function takenHitFromTypeMaxHit(type, enemyDamageMulti)
		return build.calcsTab.calcs.takenHitFromDamage(build.calcsTab.calcsOutput[type.."MaximumHitTaken"] * (enemyDamageMulti or 1), type, build.calcsTab.calcsEnv.player)
	end

	local function poolsRemainingAfterTypeMaxHit(type, enemyDamageMulti)
		local _, takenDamages = takenHitFromTypeMaxHit(type, enemyDamageMulti)
		return build.calcsTab.calcs.reducePoolsByDamage(nil, takenDamages, build.calcsTab.calcsEnv.player)
	end

	-- boring part
	it("no armour max hits", function()
		build.configTab.input.enemyIsBoss = "None"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		
		assert.are.equals(60, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(38, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(38, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(38, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(38, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

		build.configTab.input.customMods = "\z
		+200 to all resistances\n\z
		200% additional Physical Damage Reduction\n\z
		"

		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(600, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(240, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(240, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(240, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(240, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

		build.configTab.input.customMods = "\z
		+200 to all resistances\n\z
		+200 to all maximum resistances\n\z
		200% additional Physical Damage Reduction\n\z
		"
		build.configTab.input.enemyPhysicalOverwhelm = 15 -- should result 75% DR
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(240, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(600, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(600, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(600, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(600, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

		build.configTab.input.customMods = "\z
		+200 to all resistances\n\z
		+200 to all maximum resistances\n\z
		50% reduced damage taken\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(120, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(1200, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(1200, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(1200, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(1200, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

		build.configTab.input.customMods = "\z
		+200 to all resistances\n\z
		+200 to all maximum resistances\n\z
		50% reduced damage taken\n\z
		50% less damage taken\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(240, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(2400, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(2400, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(2400, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(2400, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

		build.configTab.input.customMods = "\z
		+200 to all resistances\n\z
		+200 to all maximum resistances\n\z
		50% reduced damage taken\n\z
		50% less damage taken\n\z
		Nearby enemies deal 20% less damage\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(300, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(3000, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(3000, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(3000, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(3000, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
		local poolsRemaining = poolsRemainingAfterTypeMaxHit("Lightning", 0.8)
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))

		build.configTab.input.customMods = "\z
		+200 to all resistances\n\z
		+200 to all maximum resistances\n\z
		50% reduced damage taken\n\z
		50% less damage taken\n\z
		Nearby enemies deal 20% less damage\n\z
		Gain 100% of life as extra maximum energy shield\n\z
		intelligence provides no bonus to energy shield\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(600, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(6000, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(6000, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(6000, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(3000, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Lightning", 0.8)
		assert.are.equals(0, floor(poolsRemaining.EnergyShield))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
	end)
	
	-- a small helper function to calculate damage taken from limited test parameters
	local function takenHitFromTypeMaxHit(type, enemyDamageMulti)
		return build.calcsTab.calcs.takenHitFromDamage(build.calcsTab.calcsOutput[type.."MaximumHitTaken"] * (enemyDamageMulti or 1), type, build.calcsTab.calcsEnv.player)
	end
	
	it("progenesis and petrified blood", function()
		build.configTab.input.enemyIsBoss = "None"
		-- Petrified blood
		build.skillsTab:PasteSocketGroup("\z
		Petrified Blood 20/0 Default  1\n\z
		Arrogance 21/0 Default  1\n\z
		")  -- 50% petrified effect, when exactly half of the life is reserved, should make the life pool be equivalent to no petrified effect and full life.
		build.skillsTab:ProcessSocketGroup(build.skillsTab.socketGroupList[1])
		build.configTab.input.customMods = "\z
		+200 to all resistances\n\z
		+200 to all maximum resistances\n\z
		50% reduced damage taken\n\z
		50% less damage taken\n\z
		Nearby enemies deal 20% less damage\n\z
		40% increased reservation efficiency\n\z
		25% increased effect of buffs on you\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(300, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(3000, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(3000, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(3000, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(3000, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
		build.skillsTab.socketGroupList = {}
		
		build.skillsTab:PasteSocketGroup("\z
		Petrified Blood 20/0 Default  1\n\z
		Arrogance 21/0 Default  1\n\z
		")
		build.skillsTab:ProcessSocketGroup(build.skillsTab.socketGroupList[1])
		build.configTab.input.customMods = "\z
		+200 to all resistances\n\z
		+200 to all maximum resistances\n\z
		50% reduced damage taken\n\z
		50% less damage taken\n\z
		Nearby enemies deal 20% less damage\n\z
		100% less intelligence\n\z
		+60 to maximum energy shield\n\z
		40% increased reservation efficiency\n\z
		25% increased effect of buffs on you\n\z
		"  -- petrified blood should not interact with pools other than life.
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(600, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(6000, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(6000, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(6000, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(3000, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
		build.skillsTab.socketGroupList = {}
		
		build.skillsTab:PasteSocketGroup("\z
		Petrified Blood 20/0 Default  1\n\z
		")  -- 80% petrified effect, starting from full life, should make the life pool be equivalent to 0.5 * life (unprotected upper half) and then 5 * 0.5 * life (protected lower half), making it 3* bigger in total
		build.skillsTab:ProcessSocketGroup(build.skillsTab.socketGroupList[1])
		build.configTab.input.customMods = "\z
		+200 to all resistances\n\z
		+200 to all maximum resistances\n\z
		50% reduced damage taken\n\z
		50% less damage taken\n\z
		Nearby enemies deal 20% less damage\n\z
		100% increased effect of buffs on you\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(900, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(9000, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(9000, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(9000, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(9000, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
		build.skillsTab.socketGroupList = {}
	
		-- Progenesis
		build.configTab.input.customMods = "\z
		+200 to all resistances\n\z
		+200 to all maximum resistances\n\z
		50% reduced damage taken\n\z
		50% less damage taken\n\z
		Nearby enemies deal 20% less damage\n\z
		When Hit during effect, 50% of Life loss from Damage taken occurs over 4 seconds instead\n\z
		"   -- 50% progenesis should just simply double the life pool
		build.configTab.input.conditionUsingFlask = true
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(600, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(6000, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(6000, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(6000, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(6000, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
		
		build.configTab.input.customMods = "\z
		+200 to all resistances\n\z
		+200 to all maximum resistances\n\z
		50% reduced damage taken\n\z
		50% less damage taken\n\z
		Nearby enemies deal 20% less damage\n\z
		When Hit during effect, 50% of Life loss from Damage taken occurs over 4 seconds instead\n\z
		100% less intelligence\n\z
		+60 to maximum energy shield\n\z
		"  -- progenesis should not interact with pools other than life.
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(900, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(9000, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(9000, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(9000, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(6000, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
	
		-- Progenesis + petrified blood
		build.skillsTab:PasteSocketGroup("\z
		Petrified Blood 20/0 Default  1\n\z
		Arrogance 21/0 Default  1\n\z
		")
		build.skillsTab:ProcessSocketGroup(build.skillsTab.socketGroupList[1])
		build.configTab.input.customMods = "\z
		+200 to all resistances\n\z
		+200 to all maximum resistances\n\z
		50% reduced damage taken\n\z
		50% less damage taken\n\z
		Nearby enemies deal 20% less damage\n\z
		When Hit during effect, 50% of Life loss from Damage taken occurs over 4 seconds instead\n\z
		40% increased reservation efficiency\n\z
		25% increased effect of buffs on you\n\z
		"   -- With half of life reserved, both effects are active and multiplicative with each other, making the effective life pool 4 * half life = 2 * life (or same as no petrified, no reserve and 50% progenesis)
		build.configTab.input.conditionUsingFlask = true
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(600, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(6000, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(6000, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(6000, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(6000, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
		build.skillsTab.socketGroupList = {}
		
		build.skillsTab:PasteSocketGroup("\z
		Petrified Blood 20/0 Default  1\n\z
		")
		build.skillsTab:ProcessSocketGroup(build.skillsTab.socketGroupList[1])
		build.configTab.input.customMods = "\z
		+200 to all resistances\n\z
		+200 to all maximum resistances\n\z
		50% reduced damage taken\n\z
		50% less damage taken\n\z
		Nearby enemies deal 20% less damage\n\z
		When Hit during effect, 50% of Life loss from Damage taken occurs over 4 seconds instead\n\z
		25% increased effect of buffs on you\n\z
		"   -- With no life reserved, progenesis first doubles the pool of life above low, then both progenesis and petrified quadruple the pool of life below low, so effective pool is 3 * life
		build.configTab.input.conditionUsingFlask = true
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(900, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(9000, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(9000, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(9000, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(9000, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
		build.skillsTab.socketGroupList = {}
	
		build.skillsTab:PasteSocketGroup("\z
		Petrified Blood 20/0 Default  1\n\z
		")
		build.skillsTab:ProcessSocketGroup(build.skillsTab.socketGroupList[1])
		build.configTab.input.customMods = "\z
		+200 to all resistances\n\z
		+200 to all maximum resistances\n\z
		50% reduced damage taken\n\z
		50% less damage taken\n\z
		Nearby enemies deal 20% less damage\n\z
		When Hit during effect, 60% of Life loss from Damage taken occurs over 4 seconds instead\n\z
		100% less intelligence\n\z
		+60 to maximum energy shield\n\z
		"   -- wonkier numbers to test the pool reduction function
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(1300, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(13000, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(13000, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(13000, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(10000, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
		
		local _, takenDamages = takenHitFromTypeMaxHit("Fire", 0.8)
		local poolsRemaining = build.calcsTab.calcs.reducePoolsByDamage(nil, takenDamages, build.calcsTab.calcsEnv.player)
		assert.are.equals(0, poolsRemaining.EnergyShield)
		assert.are.equals(0, poolsRemaining.Life)
		assert.are.equals(120, poolsRemaining.LifeLossLostOverTime)
		assert.are.equals(20, poolsRemaining.LifeBelowHalfLossLostOverTime)
		
		build.skillsTab:PasteSocketGroup("\z
		Petrified Blood 20/0 Default  1\n\z
		")
		build.skillsTab:ProcessSocketGroup(build.skillsTab.socketGroupList[1])
		build.configTab.input.customMods = "\z
		+1950 to life\n\z
		+2960 to mana\n\z
		+3000 to energy shield\n\z
		100% less attributes\n\z
		100% less mana reserved\n\z
		+60% to all resistances\n\z
		chaos damage does not bypass energy shield\n\z
		mind over matter\n\z
		eldritch battery\n\z
		10% of lightning damage is taken from mana before life\n\z
		chaos damage is taken from mana before life\n\z
		When Hit during effect, 50% of Life loss from Damage taken occurs over 4 seconds instead\n\z
		25% increased effect of buffs on you\n\z
		"
		build.configTab.input.conditionUsingFlask = true
		build.configTab:BuildModList()
		runCallback("OnFrame")
		
		_, takenDamages = takenHitFromTypeMaxHit("Fire")
		poolsRemaining = build.calcsTab.calcs.reducePoolsByDamage(nil, takenDamages, build.calcsTab.calcsEnv.player)
		assert.are.equals(0, poolsRemaining.Life)
		assert.are.equals(0, poolsRemaining.EnergyShield)
		assert.is.not_false(poolsRemaining.Mana > 0)
		
		_, takenDamages = takenHitFromTypeMaxHit("Lightning")
		poolsRemaining = build.calcsTab.calcs.reducePoolsByDamage(nil, takenDamages, build.calcsTab.calcsEnv.player)
		assert.are.equals(0, poolsRemaining.Life)
		assert.are.equals(0, poolsRemaining.EnergyShield)
		assert.are.equals(0, poolsRemaining.Mana)
		
		_, takenDamages = takenHitFromTypeMaxHit("Chaos")
		poolsRemaining = build.calcsTab.calcs.reducePoolsByDamage(nil, takenDamages, build.calcsTab.calcsEnv.player)
		assert.are.equals(0, poolsRemaining.Life)
		assert.are.equals(0, poolsRemaining.EnergyShield)
		assert.are.equals(0, poolsRemaining.Mana)
		
		build.skillsTab.socketGroupList = {}
	end)

	-- fun part
	it("armoured max hits", function()
		build.configTab.input.enemyIsBoss = "None"
		build.configTab.input.customMods = "\z
		+940 to maximum life\n\z
		+10000 to armour\n\z
		" -- hit of 2000 on 10000 armour results in 50% DR which reduces the damage to 1000 - total HP
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(1000, takenHitFromTypeMaxHit("Physical"))
		assert.are.equals(625, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(625, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(625, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(625, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

		build.configTab.input.customMods = "\z
		+940 to maximum life\n\z
		+100000 to armour\n\z
		" -- hit of 5000 on 100000 armour results in 80% DR which reduces the damage to 1000 - total HP
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(1000, takenHitFromTypeMaxHit("Physical"))
		assert.are.equals(625, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(625, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(625, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(625, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

		build.configTab.input.customMods = "\z
		+940 to maximum life\n\z
		+1000000000 to armour\n\z
		" -- 90% DR cap
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(1000, takenHitFromTypeMaxHit("Physical"))
		assert.are.equals(625, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(625, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(625, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(625, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

		build.configTab.input.customMods = "\z
		+940 to maximum life\n\z
		+1000000000 to armour\n\z
		" -- 90% DR cap
		build.configTab.input.enemyPhysicalOverwhelm = 15 -- should result 75% DR
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(1000, takenHitFromTypeMaxHit("Physical"))
		assert.are.equals(625, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(625, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
		assert.are.equals(625, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(625, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

		build.configTab.input.customMods = "\z
		+940 to maximum life\n\z
		+10000 to armour\n\z
		+60% to all elemental resistances\n\z
		Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
		" -- with no resistances results should be same as physical
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(1000, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(1000, takenHitFromTypeMaxHit("Fire"))
		assert.are.equals(1000, takenHitFromTypeMaxHit("Cold"))
		assert.are.equals(1000, takenHitFromTypeMaxHit("Lightning"))
		assert.are.equals(625, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

		build.configTab.input.customMods = "\z
		+940 to maximum life\n\z
		+10000 to armour\n\z
		+110% to all elemental resistances\n\z
		Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
		" -- max hit should be 4000
		-- [max] [res]     [armour] [armour]      [max]  [res]
		-- 4000 * 0.5 * (1 - 10000 / (10000 + 5 * 4000 * 0.5)) = 1000
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(1000, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(1000, takenHitFromTypeMaxHit("Fire"))
		assert.are.equals(1000, takenHitFromTypeMaxHit("Cold"))
		assert.are.equals(1000, takenHitFromTypeMaxHit("Lightning"))
		assert.are.equals(625, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

		build.configTab.input.customMods = "\z
		+940 to maximum life\n\z
		+10000 to armour\n\z
		+110% to all elemental resistances\n\z
		Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
		50% less damage taken\n\z
		" -- max hit should be 6472
		-- [max] [res]     [armour] [armour]      [max]  [res]  [less]
		-- 6472 * 0.5 * (1 - 10000 / (10000 + 5 * 6472 * 0.5)) * 0.5 = 1000
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(2000, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(1000, takenHitFromTypeMaxHit("Fire"))
		assert.are.equals(1000, takenHitFromTypeMaxHit("Cold"))
		assert.are.equals(1000, takenHitFromTypeMaxHit("Lightning"))
		assert.are.equals(1250, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
	end)

	describe("Energy shield increased by spell block chance", function()

		it("energy shield increased by spell block chance if corresponding 'maximum es' flag is present", function()
			build.configTab.input.enemyIsBoss = "None"
			build.configTab.input.customMods = "\z
			You have no intelligence\n\z
			100 Energy shield \n\z
			maximum energy shield is increased by chance to block spell damage\n\z
			50% chance to block spell damage\n\z
			"
			build.configTab:BuildModList()
			runCallback("OnFrame")

			assert.are.equals(0, build.calcsTab.calcsOutput.SpellBlockChanceOverCap )
			assert.are.equals(50, build.calcsTab.calcsOutput.SpellBlockChance)
			assert.are.equals(150, build.calcsTab.calcsOutput.EnergyShield)
		end)

		it("energy shield increased by spell block chance if corresponding 'maximum es' flag is present should be capped to max block", function()
			build.configTab.input.enemyIsBoss = "None"

			build.configTab.input.customMods = "\z
			You have no intelligence\n\z
			100 Energy shield \n\z
			maximum energy shield is increased by chance to block spell damage\n\z
			100% chance to block spell damage\n\z
			"
			build.configTab:BuildModList()
			runCallback("OnFrame")

			assert.are.equals(25, build.calcsTab.calcsOutput.SpellBlockChanceOverCap )
			assert.are.equals(75, build.calcsTab.calcsOutput.SpellBlockChance)
			assert.are.equals(175, build.calcsTab.calcsOutput.EnergyShield)
		end)

	end)

	describe("enemy damage lessened by half of chill effect", function ()
		it("enemy damage lessened by half of chill effect if the corresponding conditions are fulfilled", function()
			build.configTab.input.enemyIsBoss = "None"
			build.configTab.input.conditionEnemyChilled = true
			-- default max chill effect
			build.configTab.input.conditionEnemyChilledEffect = 30
			build.configTab.input.customMods = "\z
			enemies chilled by your hits lessen their damage dealt by half of chill effect\n\z
			"
			build.configTab:BuildModList()
			runCallback("OnFrame")

			-- 15% less since it's half of current chill effect
			assert.are.equals(0.85, build.calcsTab.calcsOutput.PhysicalEnemyDamageMult)
			assert.are.equals(0.85, build.calcsTab.calcsOutput.LightningEnemyDamageMult)
			assert.are.equals(0.85, build.calcsTab.calcsOutput.ColdEnemyDamageMult)
			assert.are.equals(0.85, build.calcsTab.calcsOutput.FireEnemyDamageMult)
			assert.are.equals(0.85, build.calcsTab.calcsOutput.ChaosEnemyDamageMult)
		end)

		it("enemy damage is not lessened if the enemy is not chilled", function()
			build.configTab.input.enemyIsBoss = "None"
			build.configTab.input.customMods = "\z
			enemies chilled by your hits lessen their damage dealt by half of chill effect\n\z
			"
			build.configTab:BuildModList()
			runCallback("OnFrame")

			assert.are.equals(1, build.calcsTab.calcsOutput.PhysicalEnemyDamageMult)
			assert.are.equals(1, build.calcsTab.calcsOutput.LightningEnemyDamageMult)
			assert.are.equals(1, build.calcsTab.calcsOutput.ColdEnemyDamageMult)
			assert.are.equals(1, build.calcsTab.calcsOutput.FireEnemyDamageMult)
			assert.are.equals(1, build.calcsTab.calcsOutput.ChaosEnemyDamageMult)
		end)

		it("lessened enemy damage respects chill cap", function()
			build.configTab.input.enemyIsBoss = "None"
			build.configTab.input.conditionEnemyChilled = true
			-- default max chill effect is 30%, so this shouldn't affect the resulting enemy damage multiplier beyond the cap
			build.configTab.input.conditionEnemyChilledEffect = 100
			build.configTab.input.customMods = "\z
			enemies chilled by your hits lessen their damage dealt by half of chill effect\n\z
			"
			build.configTab:BuildModList()
			runCallback("OnFrame")

			assert.are.equals(0.85, build.calcsTab.calcsOutput.PhysicalEnemyDamageMult)
			assert.are.equals(0.85, build.calcsTab.calcsOutput.LightningEnemyDamageMult)
			assert.are.equals(0.85, build.calcsTab.calcsOutput.ColdEnemyDamageMult)
			assert.are.equals(0.85, build.calcsTab.calcsOutput.FireEnemyDamageMult)
			assert.are.equals(0.85, build.calcsTab.calcsOutput.ChaosEnemyDamageMult)
		end)
	end)

	local function withinTenPercent(value, otherValue)
		local ratio = otherValue / value
		return 0.9 < ratio and ratio < 1.1
	end
	it("damage conversion max hits", function()
		build.configTab.input.enemyIsBoss = "None"
		
		build.configTab.input.customMods = "\z
		+940 to maximum life\n\z
		+200 to all resistances\n\z
		+200 to all maximum resistances\n\z
		50% reduced damage taken\n\z
		50% less damage taken\n\z
		50% of physical damage taken as fire\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.is.not_false(withinTenPercent(1000, takenHitFromTypeMaxHit("Physical")))

		build.configTab.input.customMods = "\z
		+940 to maximum life\n\z
		+200 to all resistances\n\z
		+200 to all maximum resistances\n\z
		50% reduced damage taken\n\z
		50% less damage taken\n\z
		50% of physical damage taken as fire\n\z
		50% of cold damage taken as fire\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.is.not_false(withinTenPercent(1000, takenHitFromTypeMaxHit("Physical")))
		assert.is.not_false(withinTenPercent(1000, takenHitFromTypeMaxHit("Cold")))

		build.configTab.input.customMods = "\z
		+940 to maximum life\n\z
		+10000 to armour\n\z
		+110% to all elemental resistances\n\z
		Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
		50% of physical damage taken as fire\n\z
		50% of cold damage taken as fire\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.is.not_false(withinTenPercent(1000, takenHitFromTypeMaxHit("Physical")))
		assert.is.not_false(withinTenPercent(1000, takenHitFromTypeMaxHit("Cold")))

		build.configTab.input.customMods = "\z
		+940 to maximum life\n\z
		+10000 to armour\n\z
		+110% to all elemental resistances\n\z
		Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
		50% of physical damage taken as fire\n\z
		50% of cold damage taken as fire\n\z
		50% less fire damage taken\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.is.not_false(withinTenPercent(1000, takenHitFromTypeMaxHit("Physical")))
		assert.is.not_false(withinTenPercent(1000, takenHitFromTypeMaxHit("Cold")))
		
		build.configTab.input.customMods = "\z
		+940 to maximum life\n\z
		+10000 to armour\n\z
		+110% to fire resistance\n\z
		Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
		100% of cold damage taken as fire\n\z
		50% of lightning damage taken as fire\n\z
		50% less fire damage taken\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.is.not_false(withinTenPercent(1000, takenHitFromTypeMaxHit("Physical")))
		assert.is.not_false(withinTenPercent(1000, takenHitFromTypeMaxHit("Cold")))
	
		build.configTab.input.customMods = "\z
		+99 to energy shield\n\z
		100% less attributes\n\z
		+60% to all elemental resistances\n\z
		25% of Elemental Damage from Hits taken as Chaos Damage\n\z
		Chaos Inoculation\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		local poolsRemaining = poolsRemainingAfterTypeMaxHit("Cold")
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
	end)
	
	it("damage conversion to different size pools", function()
		-- conversion into a smaller pool
		build.configTab.input.customMods = "\z
		+40 to maximum life\n\z
		+950 to mana\n\z
		+10000 to armour\n\z
		+110% to all elemental resistances\n\z
		Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
		100% of Lightning Damage is taken from Mana before Life\n\z
		10% of lightning damage taken as cold damage\n\z
		"   -- Small amount of conversion into a smaller pool leads to the higher pool damage type (lightning) draining it's own excess pool (mana), and then joining back on the shared pools (life)
		build.configTab:BuildModList()
		runCallback("OnFrame")
		local poolsRemaining = poolsRemainingAfterTypeMaxHit("Lightning")
		assert.are.equals(0, floor(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
		
		build.configTab.input.customMods = "\z
		+40 to maximum life\n\z
		+950 to mana\n\z
		+10000 to armour\n\z
		+110% to all elemental resistances\n\z
		Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
		100% of Lightning Damage is taken from Mana before Life\n\z
		20% of lightning damage taken as cold damage\n\z
		"   -- This is a case where cold damage drains the whole life pool and lightning damage drains the entire mana pool, leaving nothing
		build.configTab:BuildModList()
		runCallback("OnFrame")
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Lightning")
		assert.are.equals(0, floor(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
	
		build.configTab.input.customMods = "\z
		+40 to maximum life\n\z
		+1950 to mana\n\z
		+10000 to armour\n\z
		+110% to all elemental resistances\n\z
		Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
		100% of Lightning Damage is taken from Mana before Life\n\z
		20% of lightning damage taken as cold damage\n\z
		"   -- Any extra mana in this case will not help and be left over after death, since life hits 0 from the cold damage alone
		build.configTab:BuildModList()
		runCallback("OnFrame")
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Lightning")
		assert.are.equals(1000, round(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
		
		-- conversion into a bigger pool
		build.configTab.input.customMods = "\z
		+40 to maximum life\n\z
		+950 to mana\n\z
		+10000 to armour\n\z
		+110% to all elemental resistances\n\z
		Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
		100% of Lightning Damage is taken from Mana before Life\n\z
		90% of cold damage taken as lightning damage\n\z
		"   -- With inverted conversion amounts the behaviour of converting into a bigger pool should be exactly the same as converting into a lower one.
		build.configTab:BuildModList()
		runCallback("OnFrame")
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Cold")
		assert.are.equals(0, floor(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
	
		build.configTab.input.customMods = "\z
		+40 to maximum life\n\z
		+950 to mana\n\z
		+10000 to armour\n\z
		+110% to all elemental resistances\n\z
		Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
		100% of Lightning Damage is taken from Mana before Life\n\z
		80% of cold damage taken as lightning damage\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Cold")
		assert.are.equals(0, floor(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
	
		build.configTab.input.customMods = "\z
		+40 to maximum life\n\z
		+1950 to mana\n\z
		+10000 to armour\n\z
		+110% to all elemental resistances\n\z
		Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
		100% of Lightning Damage is taken from Mana before Life\n\z
		80% of cold damage taken as lightning damage\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Cold")
		assert.are.equals(1000, round(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))

		build.configTab.input.customMods = "\z
		+940 to maximum life\n\z
		+950 to mana\n\z
		+1000 to energy shield\n\z
		+10000 to armour\n\z
		+110% to all elemental resistances\n\z
		Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
		100% of Lightning Damage is taken from Mana before Life\n\z
		80% of cold damage taken as lightning damage\n\z
		50% of fire damage taken as chaos damage\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Cold")
		assert.are.equals(0, floor(poolsRemaining.EnergyShield))
		assert.are.equals(0, floor(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Fire")
		assert.are.not_false(0 < floor(poolsRemaining.EnergyShield))
		assert.are.equals(1000, floor(poolsRemaining.Mana))
		assert.are.not_false(1 >= floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
	end)

	it("energy shield bypass tests #pet", function()
		build.configTab.input.enemyIsBoss = "None"
		-- Mastery
		build.configTab.input.customMods = [[
			+40 to maximum life
			+200 to energy shield
			50% of chaos damage taken does not bypass energy shield
			You have no intelligence
			+60% to all resistances
		]]

		build.configTab:BuildModList()
		runCallback("OnFrame")
		local poolsRemaining = poolsRemainingAfterTypeMaxHit("Chaos")
		assert.are.equals(100, round(poolsRemaining.EnergyShield))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
		assert.are.equals(300, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(200, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

		-- Negative overrides positive
		build.configTab.input.customMods = [[
			+40 to maximum life
			+100 to energy shield
			physical damage taken bypasses energy shield
			Chaos damage does not bypass energy shield
			You have no intelligence
			+60% to all resistances
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(100, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(200, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(200, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Physical")
		assert.are.equals(100, floor(poolsRemaining.EnergyShield))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Chaos")
		assert.are.equals(0, floor(poolsRemaining.EnergyShield))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
		-- Chaos damage should still bypass
		build.configTab.input.customMods = build.configTab.input.customMods .. "\nAll damage taken bypasses energy shield"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(100, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
		assert.are.equals(100, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(100, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

		-- Make sure we can't reach over 100% bypass
		build.configTab.input.customMods = [[
			+40 to maximum life
			+100 to energy shield
			Chaos damage does not bypass energy shield
			50% of chaos damage taken does not bypass energy shield
			You have no intelligence
			+60% to all resistances
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(200, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(200, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
		-- Chaos damage should still bypass
		build.configTab.input.customMods = build.configTab.input.customMods .. "\nAll damage taken bypasses energy shield"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(100, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(100, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Physical")
		assert.are.equals(100, floor(poolsRemaining.EnergyShield))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Chaos")
		assert.are.equals(100, round(poolsRemaining.EnergyShield))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))

		-- Bypass + MoM
		build.configTab.input.customMods = [[
			+40 to maximum life
			+50 to mana
			+200 to energy shield
			50% of non-chaos damage taken bypasses energy shield
			50% of chaos damage taken does not bypass energy shield
			50% of Lightning Damage is taken from Mana before Life
			intelligence provides no bonus to energy shield
			+60% to all resistances
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(400, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(200, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(200, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Chaos")
		assert.are.equals(100, round(poolsRemaining.EnergyShield))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Fire")
		assert.are.equals(100, round(poolsRemaining.EnergyShield))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Lightning")
		assert.are.equals(0, round(poolsRemaining.EnergyShield))
		assert.are.equals(0, floor(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))

		build.configTab.input.customMods = [[
			+40 to maximum life
			+150 to mana
			+300 to energy shield
			50% of non-chaos damage taken bypasses energy shield
			50% of chaos damage taken does not bypass energy shield
			50% of Lightning Damage is taken from Mana before Life
			intelligence provides no bonus to energy shield
			+60% to all resistances
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(400, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
		assert.are.equals(200, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(200, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Chaos")
		assert.are.equals(200, round(poolsRemaining.EnergyShield))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Fire")
		assert.are.equals(200, round(poolsRemaining.EnergyShield))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Lightning")
		assert.are.equals(100, round(poolsRemaining.EnergyShield))
		assert.are.equals(100, floor(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
	end)
	
	it("Unbreakable + Iron Reflexes", function()
		build.configTab.input.customMods = [[
			you have no dexterity
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		-- Get the base to make this test more adaptable to changes
		local baseArmour = build.calcsTab.mainOutput.Armour
		local baseEvasion = build.calcsTab.mainOutput.Evasion

		build.configTab.input.customMods = [[
			Converts all Evasion Rating to Armour. Dexterity provides no bonus to Evasion Rating
			you have no dexterity
		]]
		build.itemsTab:CreateDisplayItemFromRaw([[
			New Item
			Shabby Jerkin
			Quality: 20
		]])
		build.itemsTab:AddDisplayItem()
		build.configTab:BuildModList()
		runCallback("OnFrame")

		-- Get the base + Shabby Jerkin to make this test more adaptable to changes
		local ironReflexesArmour = build.calcsTab.mainOutput.Armour - baseArmour - baseEvasion

		print("build.calcsTab.mainOutput.Armour:" .. build.calcsTab.mainOutput.Armour)

		build.configTab.input.customMods = [[
			Armour from Equipped Body Armour is doubled
			Converts all Evasion Rating to Armour. Dexterity provides no bonus to Evasion Rating
			you have no dexterity
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		-- Evasion from Body Armour is converted to Armour before being doubled
		assert.are.equals(2*ironReflexesArmour + baseArmour + baseEvasion, build.calcsTab.mainOutput.Armour)

		build.configTab.input.customMods = [[
			Armour from Equipped Body Armour is doubled
			Converts all Evasion Rating to Armour. Dexterity provides no bonus to Evasion Rating
			Gain no armour from equipped body armour
			you have no dexterity
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		-- Only the base armour from the chest is affected.
		-- Armour converted with Iron Reflexes still applies
		assert.are.equals(2*ironReflexesArmour + baseArmour + baseEvasion, build.calcsTab.mainOutput.Armour)
		build.configTab.input.customMods = [[
			Armour from Equipped Body Armour is doubled
			Converts all Evasion Rating to Armour. Dexterity provides no bonus to Evasion Rating
			Gain no armour from equipped body armour
			defences from equipped body armour are doubled if it has no socketed gems
			you have no dexterity
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		-- Oath Of Maji double defences stack with Unbreakable
		assert.are.equals(2*2*ironReflexesArmour + baseArmour + baseEvasion, build.calcsTab.mainOutput.Armour)

		build.configTab.input.customMods = [[
			Armour from Equipped Body Armour is doubled
			Armour from Equipped Body Armour is doubled
			Converts all Evasion Rating to Armour. Dexterity provides no bonus to Evasion Rating
			Gain no armour from equipped body armour
			defences from equipped body armour are doubled if it has no socketed gems
			you have no dexterity
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		-- Mod form unbreakable should apply only once
		assert.are.equals(2*2*ironReflexesArmour + baseArmour + baseEvasion, build.calcsTab.mainOutput.Armour)

		build.configTab.input.customMods = [[
			Armour from Equipped Body Armour is doubled
			Armour from Equipped Body Armour is doubled
			Converts all Evasion Rating to Armour. Dexterity provides no bonus to Evasion Rating
			Gain no armour from equipped body armour
			defences from equipped body armour are doubled if it has no socketed gems
			defences from equipped body armour are doubled if it has no socketed gems
			you have no dexterity
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		-- Oath Of Maji should apply only once
		assert.are.equals(2*2*ironReflexesArmour + baseArmour + baseEvasion, build.calcsTab.mainOutput.Armour)
	end)
	
	it("MoM + EB", function()
		build.configTab.input.enemyIsBoss = "None"
		-- enough mana and es, 0% and 100% bypass
		build.configTab.input.customMods = [[
			50% of damage is taken from mana before life
			energy shield protects mana instead of life
			+40 to maximum life
			+1960 to mana
			+2000 to energy shield
			You have no intelligence
			+60% to all resistances
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(200, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(200, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
		local poolsRemaining = poolsRemainingAfterTypeMaxHit("Chaos")
		assert.are.equals(2000, round(poolsRemaining.EnergyShield))
		assert.are.equals(1900, round(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Fire")
		assert.are.equals(1900, round(poolsRemaining.EnergyShield))
		assert.are.equals(2000, round(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
		
		-- enough mana and es, 50% bypass
		build.configTab.input.customMods = [[
			50% of damage is taken from mana before life
			energy shield protects mana instead of life
			50% of non-chaos damage taken bypasses energy shield
			+40 to maximum life
			+1960 to mana
			+2000 to energy shield
			You have no intelligence
			+60% to all resistances
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(200, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Fire")
		assert.are.equals(1950, round(poolsRemaining.EnergyShield))
		assert.are.equals(1950, round(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))

		-- es bottleneck, 0% and 100% bypass
		build.configTab.input.customMods = [[
			50% of damage is taken from mana before life
			energy shield protects mana instead of life
			+40 to maximum life
			+1960 to mana
			+50 to energy shield
			You have no intelligence
			+60% to all resistances
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(200, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(200, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Chaos")
		assert.are.equals(50, round(poolsRemaining.EnergyShield))
		assert.are.equals(1900, round(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Fire")
		assert.are.equals(0, round(poolsRemaining.EnergyShield))
		assert.are.equals(1950, round(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))

		-- es bottleneck, 50% bypass
		build.configTab.input.customMods = [[
			50% of damage is taken from mana before life
			energy shield protects mana instead of life
			50% of non-chaos damage taken bypasses energy shield
			+40 to maximum life
			+1960 to mana
			+40 to energy shield
			You have no intelligence
			+60% to all resistances
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(200, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Fire")
		assert.are.equals(0, round(poolsRemaining.EnergyShield))
		assert.are.equals(1940, round(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
		
		-- mana bottleneck, 0% and 100% bypass
		build.configTab.input.customMods = [[
			50% of damage is taken from mana before life
			energy shield protects mana instead of life
			+40 to maximum life
			+2000 to energy shield
			You have no intelligence
			+60% to all resistances
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(200, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(140, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Chaos")
		assert.are.equals(2000, round(poolsRemaining.EnergyShield))
		assert.are.equals(0, round(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Fire")
		assert.are.equals(1900, round(poolsRemaining.EnergyShield))
		assert.are.equals(40, round(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))

		-- mana bottleneck, 50% bypass
		-- taking 160 damage in this scenario:
		-- 160 damage is split to 80 damage straight to life, 80 damage to MoM pools
		-- 50% of the 80 MoM pool damage is taken by ES and 50% bypasses
		-- pool of 20 mana takes 40 damage, gets depleted and the remaining damage continues on to life, for a total of 100 damage to life
		build.configTab.input.customMods = [[
			50% of damage is taken from mana before life
			energy shield protects mana instead of life
			50% of non-chaos damage taken bypasses energy shield
			+40 to maximum life
			-20 to mana
			+2000 to energy shield
			You have no intelligence
			+60% to all resistances
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(160, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Fire")
		assert.are.equals(1960, round(poolsRemaining.EnergyShield))
		assert.are.equals(0, round(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))

		-- mana+es bottleneck, 0% and 100% bypass
		build.configTab.input.customMods = [[
			50% of damage is taken from mana before life
			energy shield protects mana instead of life
			+940 to maximum life
			+50 to energy shield
			You have no intelligence
			+60% to all resistances
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(1090, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		assert.are.equals(1040, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Chaos")
		assert.are.equals(50, round(poolsRemaining.EnergyShield))
		assert.are.equals(0, round(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Fire")
		assert.are.equals(0, round(poolsRemaining.EnergyShield))
		assert.are.equals(0, round(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))

		-- mana+es bottleneck, 50% bypass
		build.configTab.input.customMods = [[
			50% of damage is taken from mana before life
			energy shield protects mana instead of life
			50% of non-chaos damage taken bypasses energy shield
			+940 to maximum life
			+50 to energy shield
			You have no intelligence
			+60% to all resistances
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(1090, build.calcsTab.calcsOutput.FireMaximumHitTaken)
		poolsRemaining = poolsRemainingAfterTypeMaxHit("Fire")
		assert.are.equals(0, round(poolsRemaining.EnergyShield))
		assert.are.equals(0, round(poolsRemaining.Mana))
		assert.are.equals(0, floor(poolsRemaining.Life))
		assert.are.equals(0, floor(poolsRemaining.OverkillDamage))
	end)
end)