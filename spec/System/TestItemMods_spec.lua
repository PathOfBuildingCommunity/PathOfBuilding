describe("TetsItemMods", function()
	before_each(function()
		newBuild()
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in setup()
	end)

	local function setWickermanCustomMods(text)
		build.configTab.input.customMods = text
		build.configTab:BuildModList()
		runCallback("OnFrame")
	end

	it("exposes Hinder configuration when the modifier is present", function()
		setWickermanCustomMods("10% chance to Hinder Enemies on Hit with Spells")
		assert.is_truthy(build.calcsTab.mainEnv.enemyConditionsUsed.Hindered)
		setWickermanCustomMods("")
		assert.is_falsy(build.calcsTab.mainEnv.enemyConditionsUsed.Hindered)
	end)

	it("defaults missing unreserved life from Petrified Blood and lets zero override it", function()
		local common = "Regenerate 100 Life per second\n2% increased Life Recovery rate per 5% missing Unreserved Life"
		setWickermanCustomMods(common)
		assert.are.equal(1, build.calcsTab.mainOutput.LifeRecoveryRateMod)
		build.skillsTab:PasteSocketGroup("Petrified Blood 20/0  1")
		setWickermanCustomMods(common)
		assert.are.near(1.2, build.calcsTab.mainOutput.LifeRecoveryRateMod, 1e-9)
		setWickermanCustomMods(common.."\nYou count as on Low Life while at 55% of maximum Life or below")
		assert.are.near(1.18, build.calcsTab.mainOutput.LifeRecoveryRateMod, 1e-9)
		build.configTab.input.missingUnreservedLifePercent = 25
		setWickermanCustomMods(common)
		assert.are.near(1.1, build.calcsTab.mainOutput.LifeRecoveryRateMod, 1e-9)
		build.configTab.input.missingUnreservedLifePercent = nil
		setWickermanCustomMods(common.."\nReserves 25% of Life")
		assert.are.near(1.12, build.calcsTab.mainOutput.LifeRecoveryRateMod, 1e-9)
		setWickermanCustomMods(common.."\nReserves 50% of Life")
		assert.are.equal(1, build.calcsTab.mainOutput.LifeRecoveryRateMod)
		build.configTab.input.missingUnreservedLifePercent = 0
		setWickermanCustomMods(common)
		loadBuildFromXML(build:SaveDB("code"))
		assert.are.equal(0, build.calcsTab.mainOutput.MissingUnreservedLifePercent)
		assert.are.equal(1, build.calcsTab.mainOutput.LifeRecoveryRateMod)
		build.configTab.input.missingUnreservedLifePercent = nil
		build.configTab:BuildModList()
		runCallback("OnFrame")
		loadBuildFromXML(build:SaveDB("code"))
		assert.are.equal(50, build.calcsTab.mainOutput.MissingUnreservedLifePercent)
		assert.are.near(1.2, build.calcsTab.mainOutput.LifeRecoveryRateMod, 1e-9)
	end)

	it("poisons on melee critical strikes without granting poison to normal hits or spells", function()
		build.itemsTab:CreateDisplayItemFromRaw("Test Sword\nRusted Sword")
		build.itemsTab:AddDisplayItem()
		for _, skill in ipairs({ "Heavy Strike", "Fireball" }) do
			build.skillsTab:PasteSocketGroup(skill.." 20/0  1")
			build.mainSocketGroup = #build.skillsTab.socketGroupList
			setWickermanCustomMods("Melee Critical Strikes Poison the Enemy")
			local output = build.calcsTab.mainOutput.MainHand or build.calcsTab.mainOutput
			assert.are.equal(skill == "Heavy Strike" and 100 or 0, output.PoisonChanceOnCrit)
			assert.are.equal(0, output.PoisonChanceOnHit)
		end
	end)

	it("applies faster minion ailments without changing their hit damage", function()
		build.skillsTab:PasteSocketGroup("Raise Zombie 20/0  1")
		local common = "Minions have 100% chance to Poison on Hit\nMinions have 100% chance to cause Bleeding\nMinions have 100% chance to Ignite\nMinions gain 100% of Physical Damage as Extra Fire Damage"
		setWickermanCustomMods(common)
		local base = copyTable(build.calcsTab.mainEnv.minion.output, true)
		setWickermanCustomMods(common.."\nDamaging Ailments inflicted by Minions deal damage 20% Faster")
		local output = build.calcsTab.mainEnv.minion.output
		for _, ailment in ipairs({ "Poison", "Bleed", "Ignite" }) do
			assert.is_true(base[ailment.."Duration"] > 0)
			assert.are.near(base[ailment.."Duration"] / 1.2, output[ailment.."Duration"], 0.001)
		end
		assert.are.equal(base.AverageDamage, output.AverageDamage)
	end)

	it("checks both blind and sand stance for the enemy damage bonus", function()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1")
		setWickermanCustomMods("")
		local base = build.calcsTab.mainOutput.AverageDamage
		for _, sand in ipairs({ false, true }) do
			for _, blind in ipairs({ false, true }) do
				build.configTab.input.bloodSandStance = sand and "SAND" or "BLOOD"
				build.configTab.input.conditionEnemyBlinded = blind
				setWickermanCustomMods("Enemies you Blind while in Sand Stance take 20% increased Damage")
				assert.are.near(base * (sand and blind and 1.2 or 1), build.calcsTab.mainOutput.AverageDamage, 1)
			end
		end
		build.configTab.input.conditionEnemyBlinded = false
		for _, blind in ipairs({ false, true, false }) do
			build.configTab.input.conditionBlinded = blind
			setWickermanCustomMods("20% increased Damage while Blind")
			assert.are.near(base * (blind and 1.2 or 1), build.calcsTab.mainOutput.AverageDamage, 1)
		end
	end)

	it("grants influence-gated curses as item skills only while the requirement is met", function()
		for _, case in ipairs({ { "Vulnerability", "Hunter", "basilisk" }, { "Vulnerability", "Hunter", "basilisk", true }, { "Assassin's Mark", "Elder", "elder", true } }) do
			newBuild()
			build.skillsTab:PasteSocketGroup("Ethereal Knives 20/0  1")
			setWickermanCustomMods("")
			local baseDamage = build.calcsTab.mainOutput.AverageDamage
			local line = "Curse Enemies with "..case[1].." on Hit if 1 "..case[2].." Items are Equipped"
			local item = new("Item"):Item("Test Amulet\nPaua Amulet"..(case[4] and "" or "\n"..line))
			build.itemsTab:AddItem(item, true)
			build.itemsTab.slots.Amulet:SetSelItemId(item.id)
			if case[4] then setWickermanCustomMods(line) end
			for _, equipped in ipairs({ false, true, false }) do
				item[case[3]] = equipped
				build.buildFlag = true
				runCallback("OnFrame")
				local count = 0
				for _, group in ipairs(build.skillsTab.socketGroupList) do
					if (case[4] and group.source == "Config" or not case[4] and group.sourceItem == item) and group.gemList[1].nameSpec == case[1] then count = count + 1 end
				end
				assert.are.equal(equipped and 1 or 0, count)
				assert.are.equal(equipped, build.calcsTab.mainOutput.AverageDamage > baseDamage)
			end
			if case[4] then
				item[case[3]] = true
				setWickermanCustomMods(line)
				setWickermanCustomMods("")
				assert.are.equal(baseDamage, build.calcsTab.mainOutput.AverageDamage)
				for _, group in ipairs(build.skillsTab.socketGroupList) do assert.are_not.equal("Config", group.source) end
			end
		end
	end)

	it("scales only Iron Flask effects", function()
		local flask = new("Item"):Item("Rarity: NORMAL\nIron Flask\nQuality: 0")
		build.itemsTab:AddItem(flask, true)
		build.itemsTab.slots["Flask 1"]:SetSelItemId(flask.id)
		build.itemsTab.slots["Flask 1"].active = true
		setWickermanCustomMods("")
		local baseWard = build.calcsTab.mainOutput.Ward
		assert.is_true(baseWard > 0)
		setWickermanCustomMods("Iron Flasks applied to you have 50% increased Effect")
		assert.are.equal(baseWard * 1.5, build.calcsTab.mainOutput.Ward)
		assert.are.equal(0, build.calcsTab.mainEnv.player.modDB:Sum("INC", nil, "FlaskEffect"))
	end)

	it("adds offering damage to its recipients", function()
		build.skillsTab:PasteSocketGroup("Raise Zombie 20/0  1\n")
		build.skillsTab:PasteSocketGroup("Flesh Offering 20/0  1")
		setWickermanCustomMods("")
		local base = build.calcsTab.mainEnv.minion.output.TotalDPS
		setWickermanCustomMods("Offerings you create also grant 20% increased Damage")
		assert.are.near(base * 1.2, build.calcsTab.mainEnv.minion.output.TotalDPS, 1)
		assert.are.equal(0, build.calcsTab.mainEnv.player.modDB:Sum("INC", nil, "Damage"))
	end)

	it("limits boot-socketed mana cost efficiency to boots", function()
		for _, slot in ipairs({ "Boots", "Helmet" }) do
			newBuild()
			build.skillsTab:PasteSocketGroup("Slot: "..slot.."\nFireball 20/0  1")
			setWickermanCustomMods(slot == "Boots" and "20% increased Mana Cost Efficiency" or "")
			local expected = build.calcsTab.mainOutput.ManaCost
			setWickermanCustomMods("Skills socketed in Equipped Boots have 20% increased Mana Cost Efficiency")
			assert.are.equal(expected, build.calcsTab.mainOutput.ManaCost)
		end
	end)

	it("converts light radius and mana regeneration increases without converting more modifiers", function()
		local cases = {
			{ "Light Radius", "Life Regeneration Rate", "Increases and Reductions to Light Radius also apply to Life Regeneration Rate at 50% value", "LifeRegen", "Regenerate 100 Life per second" },
			{ "Mana Regeneration Rate", "Energy Shield Recharge Rate", "Increases and Reductions to Mana Regeneration Rate also apply to Energy Shield Recharge Rate at 50% of their value", "EnergyShieldRecharge", "+1000 to maximum Energy Shield" },
		}
		for _, case in ipairs(cases) do
			for _, value in ipairs({ 40, -20 }) do
				setWickermanCustomMods(case[5].."\n"..math.abs(value / 2).."% "..(value < 0 and "reduced " or "increased ")..case[2])
				local expected = build.calcsTab.mainOutput[case[4]]
				assert.is_true(expected > 0)
				setWickermanCustomMods(case[5].."\n"..math.abs(value).."% "..(value < 0 and "reduced " or "increased ")..case[1].."\n100% more "..case[1].."\n"..case[3])
				assert.are.equal(expected, build.calcsTab.mainOutput[case[4]])
			end
		end
	end)

	it("grants Onslaught only to recently created minions", function()
		build.skillsTab:PasteSocketGroup("Raise Zombie 20/0  1")
		setWickermanCustomMods("")
		local base = build.calcsTab.mainEnv.minion.output.MovementSpeedMod
		for _, enabled in ipairs({ false, true, false }) do
			build.configTab.input.minionsConditionCreatedRecently = enabled
			setWickermanCustomMods("Minions created Recently have Onslaught")
			assert.are.near(base + (enabled and 0.2 or 0), build.calcsTab.mainEnv.minion.output.MovementSpeedMod, 1e-9)
			assert.is_false(not not build.calcsTab.mainEnv.player.modDB:Flag(nil, "Condition:Onslaught"))
		end
	end)

	it("grants double damage only to skills with a positive life cost", function()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1")
		for _, costsLife in ipairs({ false, true, false }) do
			setWickermanCustomMods("Skills that Cost Life have 20% chance to deal Double Damage"..(costsLife and "\nSkills cost Life instead of Mana" or ""))
			assert.are.equal(costsLife and 20 or 0, build.calcsTab.mainOutput.DoubleDamageChance)
		end
	end)

	it("inverts only the specified elemental resistance", function()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1")
		build.configTab.input.enemyFireResist = 50
		build.configTab.input.enemyColdResist = 50
		build.configTab.input.enemyLightningResist = 50
		for _, element in ipairs({ "Cold", "Fire", "Lightning" }) do
			for _, chance in ipairs({ 0, 50, 100 }) do
				setWickermanCustomMods("Adds 100 to 100 Cold Damage to Spells\nAdds 100 to 100 Lightning Damage to Spells\nHits have "..chance.."% chance to treat Enemy Monster "..element.." Resistance values as inverted")
				for _, damageType in ipairs({ "Cold", "Fire", "Lightning" }) do
					assert.are.near(0.5 + (damageType == element and chance / 100 or 0), build.calcsTab.calcsOutput[damageType.."EffMult"], 1e-9)
				end
			end
		end
	end)

	it("adds to the maximum chill effect", function()
		build.skillsTab:PasteSocketGroup("Freezing Pulse 20/0  1")
		setWickermanCustomMods("+10% to Maximum Effect of Chill")
		assert.are.equal(40, build.calcsTab.mainOutput.MaximumChill)
		build.skillsTab:PasteSocketGroup("Cold Snap 20/0  1")
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		setWickermanCustomMods("+10% to Maximum Effect of Chill\n400% increased Effect of Chill")
		assert.are.equal(40, build.calcsTab.mainOutput.ChillSourceEffect)
		setWickermanCustomMods("")
		assert.are.equal(30, build.calcsTab.mainOutput.MaximumChill)
	end)

	it("applies the distance-worded cold bonus and scorch using the nearby model", function()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1")
		setWickermanCustomMods("Adds 20 to 30 Cold Damage\nNearby Enemies are Scorched")
		local expected = copyTable(build.calcsTab.mainOutput, true)
		setWickermanCustomMods("You and Allies within 10 metres deal 20 to 30 additional Cold Damage\nEnemies within 10 metres are Scorched")
		assert.are.equal(expected.AverageDamage, build.calcsTab.mainOutput.AverageDamage)
		assert.are.equal(10, build.calcsTab.mainOutput.CurrentScorch)
	end)

	for _, case in ipairs({
		{ "Minions deal 25% increased Damage if you've Hit Recently", "HitRecently", "conditionHitRecently", "TotalDPS", "Minions deal 25% increased Damage" },
		{ "Minions have 30% increased Movement Speed if you've used a Minion Skill Recently", "UsedMinionSkillRecently", "conditionUsedMinionSkillRecently", "MovementSpeedMod", "Minions have 30% increased Movement Speed" },
	}) do
		it("checks the player for conditional minion "..case[4], function()
			build.skillsTab:PasteSocketGroup("Raise Zombie 20/0  1")
			setWickermanCustomMods("")
			local base = build.calcsTab.mainEnv.minion.output[case[4]]
			local playerMovement = build.calcsTab.mainOutput.MovementSpeedMod
			-- The unconditional modifier provides a reference that preserves damage rounding.
			setWickermanCustomMods(case[5])
			local activeValue = build.calcsTab.mainEnv.minion.output[case[4]]
			for _, enabled in ipairs({ false, true, false }) do
				build.configTab.input[case[3]] = enabled
				setWickermanCustomMods(case[1])
				local env = build.calcsTab.mainEnv
				-- The minion satisfies the condition even while the player does not.
				assert.is_true(env.minion.modDB:GetCondition(case[2]))
				assert.are.equal(enabled and activeValue or base, env.minion.output[case[4]])
				assert.are.equal(playerMovement, env.player.output.MovementSpeedMod)
			end
		end)
	end

	it("supports Hinder immunity and removal", function()
		setWickermanCustomMods("Immune to Hinder")
		assert.is_true(build.calcsTab.mainOutput.HinderImmunity)
		setWickermanCustomMods("")
		assert.is_falsy(build.calcsTab.mainOutput.HinderImmunity)
	end)

	it("reduces burning damage taken without reducing hits or other damage over time", function()
		local base = copyTable(build.calcsTab.mainOutput, true)
		setWickermanCustomMods("7% reduced Burning Damage taken")
		local output = build.calcsTab.mainOutput
		assert.are.near(base.FireTakenDotMult * 0.93, output.FireTakenDotMult, 1e-9)
		assert.are.equal(base.FireTakenHitMult, output.FireTakenHitMult)
		assert.are.equal(base.ColdTakenDotMult, output.ColdTakenDotMult)
	end)

	for _, case in ipairs({
		{ "been Hit", "conditionBeenHitRecently", "conditionUsedMovementSkillRecently" },
		{ "used a Movement Skill", "conditionUsedMovementSkillRecently", "conditionBeenHitRecently" },
	}) do
		it("grants the conditional Constrictor projectile only after "..case[1], function()
			build.skillsTab:PasteSocketGroup("Fireball 20/0  1")
			setWickermanCustomMods("Skills fire an additional Projectile if you've "..case[1].." Recently")
			assert.are.equal(1, build.calcsTab.mainOutput.ProjectileCount)
			build.configTab.input[case[3]] = true
			build.configTab:BuildModList()
			runCallback("OnFrame")
			assert.are.equal(1, build.calcsTab.mainOutput.ProjectileCount)
			build.configTab.input[case[2]] = true
			build.configTab:BuildModList()
			runCallback("OnFrame")
			assert.are.equal(2, build.calcsTab.mainOutput.ProjectileCount)
		end)
	end

	for _, case in ipairs({ { "Armour", "Armour, Gloves, and" }, { "Evasion Rating", "Armour Gloves and" } }) do
		it("scales "..case[1].." only from the four named armour slots", function()
			for _, equipment in ipairs({
				{ "Helmet", "Iron Hat" }, { "Body Armour", "Plate Vest" },
				{ "Gloves", "Iron Gauntlets" }, { "Boots", "Iron Greaves" },
				{ "Weapon 2", "Splintered Tower Shield" },
			}) do
				local item = new("Item"):Item("Rarity: Normal\n"..equipment[2])
				-- Synthetic equal defences make shield exclusion and flat global bonuses observable.
				build.itemsTab:AddItem(item, true)
				item.armourData.Armour = 100
				item.armourData.Evasion = 100
				build.itemsTab.slots[equipment[1]]:SetSelItemId(item.id)
			end
			local stat = case[1] == "Armour" and "Armour" or "Evasion"
			local flat = "+100 to "..case[1]
			setWickermanCustomMods(flat)
			local base = build.calcsTab.mainOutput[stat]
			setWickermanCustomMods(flat.."\n50% increased "..case[1].." from Equipped Helmet, Body "..case[2].." Boots")
			assert.are.equal(base + 200, build.calcsTab.mainOutput[stat])
		end)
	end

	for _, case in ipairs({ { "Gloves", "Iron Gauntlets" }, { "Boots", "Iron Greaves" } }) do
		it("scales "..case[1].." bonuses from a synthetic Wickerman item independently of slot order", function()
			local target = new("Item"):Item("Rarity: Rare\nBonus target\n"..case[2].."\nImplicits: 0\n+100 to Strength\n+7 to Dexterity\n20% more maximum Mana")
			build.itemsTab:AddItem(target, true)
			build.itemsTab.slots[case[1]]:SetSelItemId(target.id)
			setWickermanCustomMods("")
			local base = copyTable(build.calcsTab.mainOutput, true)
			-- Use a normal slot with a synthetic type; no Wickerman base/slot/import framework is required.
			local source = new("Item"):Item("Rarity: Rare\nSynthetic Wickerman\nPaua Amulet\nImplicits: 0\n20% increased bonuses gained from Equipped "..case[1])
			source.type = "Wickerman Lower Limb"
			build.itemsTab:AddItem(source, true)
			build.itemsTab.slots.Amulet:SetSelItemId(source.id)
			for _, first in ipairs({ true, false }) do
				local slot = build.itemsTab.slots.Amulet
				for index, entry in ipairs(build.itemsTab.orderedSlots) do
					if entry == slot then table.remove(build.itemsTab.orderedSlots, index) break end
				end
				table.insert(build.itemsTab.orderedSlots, first and 1 or #build.itemsTab.orderedSlots + 1, slot)
				build.buildFlag = true
				runCallback("OnFrame")
				assert.are.equal(base.Str + 20, build.calcsTab.mainOutput.Str)
				assert.are.equal(base.Dex + 1, build.calcsTab.mainOutput.Dex)
				assert.are.near(1.24, build.calcsTab.mainEnv.player.modDB:More(nil, "Mana"), 1e-9)
			end
			setWickermanCustomMods("10% increased bonuses gained from Equipped "..case[1])
			assert.are.equal(base.Str + 30, build.calcsTab.mainOutput.Str)
			setWickermanCustomMods("30% reduced bonuses gained from Equipped "..case[1])
			assert.are.equal(base.Str - 10, build.calcsTab.mainOutput.Str)
			setWickermanCustomMods("20% reduced bonuses gained from Equipped "..case[1])
			assert.are.equal(base.Str, build.calcsTab.mainOutput.Str)
			build.itemsTab.slots.Amulet:SetSelItemId(0)
			setWickermanCustomMods("")
			assert.are.equal(base.Str, build.calcsTab.mainOutput.Str)
		end)
	end

	local function createCraftedRing()
		build.itemsTab:CreateDisplayItemFromRaw([[Rarity: Rare
			Test Ring
			Amethyst Ring
			Crafted: true
			Prefix: None
			Prefix: None
			Prefix: None
			Suffix: None
			Suffix: None
			Suffix: None
			Quality: 12
			Implicits: 0]])
		return build.itemsTab.displayItem
	end

	it("clears catalyst quality when no catalyst is selected", function()
		local item = createCraftedRing()
		local controls = build.itemsTab.controls
		local catalyst = controls.displayItemCatalyst
		local catalystQuality = controls.displayItemCatalystQualityEdit

		catalyst:SetSel(2)
		assert.are.equals(1, item.catalyst)
		assert.are.equals(20, item.catalystQuality)
		catalystQuality:SetText("17", true)
		assert.are.equals(17, item.catalystQuality)
		assert.is_truthy(item:BuildRaw():match("Catalyst: Abrasive"))
		assert.is_truthy(item:BuildRaw():match("CatalystQuality: 17"))

		catalyst:SetSel(1)
		assert.are.equals(0, item.catalyst)
		assert.is_nil(item.catalystQuality)
		assert.are.equals("0", catalystQuality.buf)
		assert.is_nil(item:BuildRaw():match("Catalyst:"))
		assert.is_nil(item:BuildRaw():match("CatalystQuality:"))

		item.catalystQuality = 20
		build.itemsTab:SetDisplayItem(item)
		assert.is_nil(item.catalystQuality)
		assert.are.equals("0", catalystQuality.buf)
		assert.is_nil(item:BuildRaw():match("CatalystQuality:"))
	end)

	for _, wording in ipairs({ "Increases", "Increase" }) do
		it("Scornflux applies Arcane Surge cast speed to movement speed with '" .. wording .. "' wording", function()
			build.itemsTab:CreateDisplayItemFromRaw("Scornflux\nSatin Slippers\n" .. wording .. " to Cast Speed from Arcane Surge also applies to Movement Speed")
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")
			local withoutArcaneSurge = build.calcsTab.mainOutput.MovementSpeedMod

			build.configTab.input.buffArcaneSurge = true
			build.configTab:BuildModList()
			runCallback("OnFrame")
			assert.are.near(withoutArcaneSurge + 0.2, build.calcsTab.mainOutput.MovementSpeedMod, 10 ^ -9)
		end)
	end

	for _, punctuation in ipairs({ ",", "" }) do
		it("Gamblesprint applies configured movement speed with '" .. punctuation .. "' punctuation", function()
			build.itemsTab:CreateDisplayItemFromRaw("Gamblesprint\nHydrascale Boots\nWhen Hit, gain a random Movement Speed modifier from 40% reduced to 100% increased" .. punctuation .. " until Hit again")
			build.itemsTab:AddDisplayItem()
			for _, movementSpeed in ipairs({ 100, -40 }) do
				build.configTab.input.GamblesprintMovementSpeed = movementSpeed
				build.configTab:BuildModList()
				runCallback("OnFrame")
				assert.are.near(1 + movementSpeed / 100, build.calcsTab.mainOutput.MovementSpeedMod, 10 ^ -9)
			end
		end)
	end

	for _, wording in ipairs({ "Item Rarity", "Rarity of Items found" }) do
		it("The Pariah grants rarity only for white sockets with '" .. wording .. "' wording", function()
			for _, colour in ipairs({ "W", "R" }) do
				local item = new("Item"):Item("Rarity: UNIQUE\nThe Pariah\nUnset Ring\nSockets: " .. colour .. "\nImplicits: 0\n60% increased " .. wording .. " per White Socket")
				build.itemsTab:AddItem(item, true)
				build.itemsTab.slots["Ring 1"]:SetSelItemId(item.id)
				build.buildFlag = true
				runCallback("OnFrame")
				assert.are.equals(colour == "W" and 60 or 0, build.calcsTab.mainEnv.player.modDB:Sum("INC", nil, "LootRarity"))
			end
		end)
	end

	for _, wording in ipairs({ "Enemy", "Enemy Monster" }) do
		it("Triumvirate Authority ignores physical reduction only for socketed Vaal skills with '" .. wording .. "' wording", function()
			build.itemsTab:CreateDisplayItemFromRaw("Triumvirate Authority\nUnset Ring\nSockets: G\nHits from Socketed Vaal Skills ignore " .. wording .. " Physical Damage Reduction")
			build.itemsTab:AddDisplayItem()
			build.skillsTab:PasteSocketGroup("Slot: Ring 1\nVaal Blade Vortex 20/0  1\n")
			build.skillsTab:PasteSocketGroup("Slot: Ring 1\nFireball 20/0  1\n")
			build.skillsTab:PasteSocketGroup("Slot: Helmet\nVaal Blade Vortex 20/0  1\n")
			runCallback("OnFrame")

			local affected, unaffected = 0, 0
			for _, skill in ipairs(build.calcsTab.mainEnv.player.activeSkillList) do
				local expected = skill.socketGroup.slot == "Ring 1" and skill.skillTypes[SkillType.Vaal] or false
				assert.are.equals(expected, skill.skillModList:Flag(skill.skillCfg, "IgnoreEnemyPhysicalDamageReduction") or false)
				if expected then
					affected = affected + 1
				else
					unaffected = unaffected + 1
				end
			end
			assert.are.equals(1, affected)
			assert.is_true(unaffected >= 2)
		end)
	end

	for _, case in ipairs({
		{ name = "current", line = "100% chance to Avoid being Chilled or Frozen if you have used a Fire Skill Recently" },
		{ name = "legacy", line = "Cannot be Frozen or Chilled if you've used a Fire Skill Recently" },
	}) do
		it("Hrimnor's Resolve grants conditional chill and freeze protection with " .. case.name .. " wording", function()
			build.itemsTab:CreateDisplayItemFromRaw("Hrimnor's Resolve\nSamnite Helmet\n" .. case.line)
			build.itemsTab:AddDisplayItem()
			for _, recently in ipairs({ false, true, false }) do
				build.configTab.input.conditionUsedFireSkillRecently = recently
				build.configTab:BuildModList()
				runCallback("OnFrame")
				assert.are.equals(recently and 100 or 0, build.calcsTab.mainOutput.ChillAvoidChance)
				assert.are.equals(recently and 100 or 0, build.calcsTab.mainOutput.FreezeAvoidChance)
			end
		end)
	end

	it("shows versioned reusable variant groups", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: Unique
			Grouped Test Item
			Plate Vest
			Version: Pre 3.28.0
			Version: Current
			Variant: Life
			Variant: Energy Shield
			Variant: Mana
			Variant: Armour
			Implicits: 0
			{version:1}{variant:1}{group:1,2}+10 to maximum Life
			{version:2}{variant:2}{group:1,2}+10 to maximum Energy Shield
			{variant:3}{group:1,2}+10 to maximum Mana
			{variant:4}{group:1,2}+10 to Armour
			]])

		local versionControl = build.itemsTab.controls.displayItemVersion
		local group1 = build.itemsTab.controls.displayItemVariant
		local group2 = build.itemsTab.controls.displayItemAltVariant
		assert.is_true(versionControl:IsShown())
		assert.are.equals(2, versionControl.selIndex)
		assert.are.equals("Energy Shield", group1.list[1].label)
		assert.are.equals("Mana", group2.list[1].label)

		group2:SetSel(2)
		group1:SetSel(2)
		assert.are.equals(3, build.itemsTab.displayItem.variantGroupSelections[1])
		versionControl:SetSel(1)
		assert.are.equals(3, build.itemsTab.displayItem.variantGroupSelections[1])
		assert.are.equals("Life", group1.list[1].label)
		assert.are.equals("Mana", group1.list[2].label)
		assert.are.equals("Life", group2.list[1].label)
		assert.are.equals("Armour", group2.list[2].label)
	end)

	it("Dialla's socket mods", function()
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nArc 20/0  1\nArc 20/0  1\n")
		runCallback("OnFrame")

		build.itemsTab:CreateDisplayItemFromRaw([[Dialla's Malefaction
		Sage's Robe
		Energy Shield: 95
		EnergyShieldBasePercentile: 0
		Variant: Pre 3.19.0
		Variant: Current
		Selected Variant: 2
		Sage's Robe
		Quality: 20
		Sockets: R-G-B-B-B-B
		LevelReq: 37
		Implicits: 0
		Gems can be Socketed in this Item ignoring Socket Colour
		{variant:1}Gems Socketed in Red Sockets have +1 to Level
		{variant:2}Gems Socketed in Red Sockets have +2 to Level
		{variant:1}Gems Socketed in Green Sockets have +10% to Quality
		{variant:2}Gems Socketed in Green Sockets have +30% to Quality
		{variant:1}Gems Socketed in Blue Sockets gain 25% increased Experience
		{variant:2}Gems Socketed in Blue Sockets gain 100% increased Experience
		Has no Attribute Requirements]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are.equals(build.calcsTab.mainEnv.player.activeSkillList[1].activeEffect.level, 22)
		assert.are.equals(build.calcsTab.mainEnv.player.activeSkillList[2].activeEffect.quality, 30)
	end)

	it("Malachai's Artifice socket mods", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Malachai's Artifice
		Unset Ring
		Variant: Pre 2.6.0
		Variant: Current
		Selected Variant: 2
		Unset Ring
		Sockets: W
		LevelReq: 5
		Implicits: 1
		Has 1 Socket
		{tags:jewellery_resistance}{variant:1}-25% to all Elemental Resistances
		{tags:jewellery_resistance}{variant:2}-20% to all Elemental Resistances
		{tags:jewellery_resistance}{range:0.5}+(75-100)% to Fire Resistance when Socketed with a Red Gem
		{tags:jewellery_resistance}{range:0.5}+(75-100)% to Cold Resistance when Socketed with a Green Gem
		{tags:jewellery_resistance}{range:0.5}+(75-100)% to Lightning Resistance when Socketed with a Blue Gem
		All Sockets are White
		Socketed Gems have Elemental Equilibrium]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local lightningResBefore = build.calcsTab.mainOutput.LightningResist

		build.skillsTab:PasteSocketGroup("Slot: Ring 1\nWrath 20/0  1\n")
		runCallback("OnFrame")

		assert.are_not.equals(lightningResBefore, build.calcsTab.mainOutput.LightningResist)
	end)

	it("caps socketed gem multipliers in gem order", function()
		build.itemsTab:CreateDisplayItemFromRaw("Test Gloves\nIron Gauntlets\nSockets: R-R-R-R")
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Slot: Gloves\nHeavy Strike 20/0  1\nHeavy Strike 20/0  1\nHeavy Strike 20/0  1\nHeavy Strike 20/0  1\nArc 20/0  1\n")
		runCallback("OnFrame")

		local multipliers = build.calcsTab.mainEnv.itemModDB.multipliers
		assert.are.equals(4, multipliers.SocketedGemsInGloves)
		assert.are.equals(4, multipliers.SocketedRedGemsInGloves)
		assert.are.equals(0, multipliers.SocketedBlueGemsInGloves)
	end)

	it("Doomsower vaal pact and extra phys as fire", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Doomsower
		Lion Sword
		Variant: Pre 2.6.0
		Variant: Pre 3.0.0
		Variant: Pre 3.8.0
		Variant: Pre 3.11.0
		Variant: Current
		Selected Variant: 5
		Lion Sword
		Quality: 20
		Sockets: G-G-G-G-G-G
		LevelReq: 65
		Implicits: 3
		{variant:1}18% increased Global Accuracy Rating
		{variant:2,3,4}+470 to Accuracy Rating
		{variant:5}+50 to Strength and Dexterity
		Socketed Melee Gems have 15% increased Area of Effect
		{variant:1,2,3}Socketed Red Gems get 10% Physical Damage as Extra Fire Damage
		{variant:1,2,3,4}{range:0.5}(50-70)% increased Physical Damage
		{variant:5}{range:0.5}(30-50)% increased Physical Damage
		{variant:1,2}{range:0.5}Adds (50-75) to (85-110) Physical Damage
		{variant:3,4,5}{range:0.5}Adds (65-75) to (100-110) Physical Damage
		{range:0.5}(6-12)% increased Attack Speed
		{variant:5,4}Attack Skills gain 5% of Physical Damage as Extra Fire Damage per Socketed Red Gem
		{variant:5,4}You have Vaal Pact while all Socketed Gems are Red]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nSmite 20/0  1\n")
		runCallback("OnFrame")

		assert.is_true(build.calcsTab.mainEnv.keystonesAdded["Vaal Pact"])
		assert.is_true(build.calcsTab.mainEnv.player.mainSkill.skillModList:Sum("BASE", build.calcsTab.mainEnv.player.mainSkill.skillCfg, "PhysicalDamageGainAsFire") > 0)
	end)

	it("Varunastra works with nightblade", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Varunastra
		Vaal Blade
		League: Perandus
		Variant: Pre 2.6.0
		Variant: Current
		Selected Variant: 2
		Vaal Blade
		Quality: 20
		Sockets: G-G-G
		LevelReq: 64
		Implicits: 2
		{variant:1}18% increased Global Accuracy Rating
		{variant:2}+460 to Accuracy Rating
		{range:0.5}(40-60)% increased Physical Damage
		{range:0.5}Adds (30-45) to (80-100) Physical Damage
		{range:0.5}+(2-3) Mana gained for each Enemy hit by Attacks
		Counts as all One Handed Melee Weapon Types]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Smite 20/0  1\nNightblade 20/0  1\n")
		runCallback("OnFrame")
		local nonElusiveCritMult = build.calcsTab.mainOutput.CritMultiplier

		build.configTab.input["buffElusive"] = true
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are_not.equals(nonElusiveCritMult, build.calcsTab.mainOutput.CritMultiplier)
	end)

	it("Runegraft of the Agile affects average Elusive effect", function()
		build.skillsTab:PasteSocketGroup("Smite 20/0  1\n")
		build.configTab.input.customMods = "Gain Elusive on Critical Strike"
		build.configTab.input.buffElusive = true
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(50, build.calcsTab.mainOutput.ElusiveEffectMod)

		build.configTab.input.customMods = [[Gain Elusive on Critical Strike
		Elusive's Effect on you is increased instead for the first 2 seconds]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.near(730 / 9, build.calcsTab.mainOutput.ElusiveEffectMod, 10 ^ -9)

		build.configTab.input.customMods = [[Gain Elusive on Critical Strike
		Elusive's Effect on you is increased instead for the first 2 seconds
		Elusive on you reduces in effect 50% slower
		Elusive is removed from you at 20% Effect]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.near(244 / 3, build.calcsTab.mainOutput.ElusiveEffectMod, 10 ^ -9)

		build.configTab.input.customMods = [[Gain Elusive on Critical Strike
		Elusive's Effect on you is increased instead for the first 2 seconds
		100% increased Elusive Effect
		Elusive is removed from you at 100% Effect]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.near(1630 / 9, build.calcsTab.mainOutput.ElusiveEffectMod, 10 ^ -9)

		build.configTab.input.overrideBuffElusive = 220
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(220, build.calcsTab.mainOutput.ElusiveEffectMod)
	end)

	it("Varunastra works with close combat support", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Varunastra
		Vaal Blade
		League: Perandus
		Variant: Pre 2.6.0
		Variant: Current
		Selected Variant: 2
		Vaal Blade
		Quality: 20
		Sockets: G-G-G
		LevelReq: 64
		Implicits: 2
		{variant:1}18% increased Global Accuracy Rating
		{variant:2}+460 to Accuracy Rating
		{range:0.5}(40-60)% increased Physical Damage
		{range:0.5}Adds (30-45) to (80-100) Physical Damage
		{range:0.5}+(2-3) Mana gained for each Enemy hit by Attacks
		Counts as all One Handed Melee Weapon Types]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		build.configTab.input["meleeDistance"] = 99
		build.configTab:BuildModList()
		runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Cyclone 20/0  1\nClose Combat 20/0  1\n")
		runCallback("OnFrame")

		local farDPS = build.calcsTab.mainOutput.TotalDPS

		build.configTab.input["meleeDistance"] = 1
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are_not.equals(farDPS, build.calcsTab.mainOutput.TotalDPS)
	end)

	it("Kalandra's Touch mod copy", function()
		local initialInt = build.calcsTab.mainOutput.Int

		build.itemsTab:CreateDisplayItemFromRaw([[New Item
		Ring
		Quality: 0
		LevelReq: 35
		Implicits: 0
		+30 to Intelligence]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local genericRingInt = build.calcsTab.mainOutput.Int

		build.itemsTab:CreateDisplayItemFromRaw([[Kalandra's Touch
		Ring
		League: Kalandra
		Implicits: 0
		Reflects your other Ring
		Mirrored]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are.equals(genericRingInt - initialInt, build.calcsTab.mainOutput.Int - genericRingInt)
	end)
	
	it("Kalandra's Touch influence copy", function()

		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nSmite 20/0  1\n")
		runCallback("OnFrame")

		local dmg = build.calcsTab.mainOutput.AverageDamage

		build.configTab.input.customMods = "\z
		Gain 5% of Elemental Damage as Extra Chaos Damage per Shaper Item Equipped\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(build.calcsTab.mainOutput.AverageDamage, dmg)

		build.itemsTab:CreateDisplayItemFromRaw([[New Item
		Cerulean Ring
		Shaper Item
		Crafted: true
		Prefix: None
		Prefix: None
		Prefix: None
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 0
		LevelReq: 80
		Implicits: 0]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.is_true(build.calcsTab.mainOutput.AverageDamage > dmg)

		local dmgOneRing = build.calcsTab.mainOutput.AverageDamage

		build.itemsTab:CreateDisplayItemFromRaw([[Kalandra's Touch
		Ring
		League: Kalandra
		Implicits: 0
		Reflects your other Ring
		Mirrored]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.is_true(build.calcsTab.mainOutput.AverageDamage > dmgOneRing)
	end)

	it("Both slots mod (evasion and es mastery)", function()

		build.configTab.input.customMods = "\z
		20% increased Maximum Energy Shield if both Equipped Rings have an Evasion Modifier\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		build.itemsTab:CreateDisplayItemFromRaw([[Energy Shield Boots
		Sorcerer Boots
		Energy Shield: 114
		EnergyShieldBasePercentile: 1
		Crafted: true
		Prefix: {range:0.5}IncreasedLife6
		Prefix: {range:0.5}LocalIncreasedEnergyShieldPercent5
		Prefix: {range:0.5}MovementVelocity5
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: B-B-B-B
		LevelReq: 67
		Implicits: 0
		74% increased Energy Shield
		+65 to maximum Life
		30% increased Movement Speed]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local baseEs = build.calcsTab.mainOutput.EnergyShield

		build.itemsTab:CreateDisplayItemFromRaw([[Chaos Resistance Ring
		Amethyst Ring
		LevelReq: 33
		Implicits: 1
		+71 to Evasion Rating
		{tags:chaos,resistance}{range:0.5}+(17-23)% to Chaos Resistance]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are.equals(baseEs, build.calcsTab.mainOutput.EnergyShield) -- No change in es with just one ring.

		build.itemsTab:CreateDisplayItemFromRaw([[Chaos Resistance Ring
		Amethyst Ring
		Crafted: true
		Prefix: {range:0.5}IncreasedEvasionRating4
		Prefix: None
		Prefix: None
		Suffix: None
		Suffix: None
		Suffix: None
		LevelReq: 33
		Implicits: 1
		{tags:chaos,resistance}{range:0.5}+(17-23)% to Chaos Resistance
		+71 to Evasion Rating]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are_not.equals(baseEs, build.calcsTab.mainOutput.EnergyShield)
		-- Es changes after adding another ring with mod. Regardless of the evasion mod on the first ring being implicit.
	end)

	it("Both slots explicit mod with mixed mod rings (evasion and es mastery)", function()
	
		build.configTab.input.customMods = "\z
		20% increased Maximum Energy Shield if both Equipped Rings have an Explicit Evasion Modifier\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		build.itemsTab:CreateDisplayItemFromRaw([[Energy Shield Boots
		Sorcerer Boots
		Energy Shield: 114
		EnergyShieldBasePercentile: 1
		Crafted: true
		Prefix: {range:0.5}IncreasedLife6
		Prefix: {range:0.5}LocalIncreasedEnergyShieldPercent5
		Prefix: {range:0.5}MovementVelocity5
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: B-B-B-B
		LevelReq: 67
		Implicits: 0
		74% increased Energy Shield
		+65 to maximum Life
		30% increased Movement Speed]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local baseEs = build.calcsTab.mainOutput.EnergyShield

		build.itemsTab:CreateDisplayItemFromRaw([[Chaos Resistance Ring
		Amethyst Ring
		LevelReq: 33
		Implicits: 1
		+71 to Evasion Rating
		{tags:chaos,resistance}{range:0.5}+(17-23)% to Chaos Resistance]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are.equals(baseEs, build.calcsTab.mainOutput.EnergyShield) -- No change in es with just one ring.

		build.itemsTab:CreateDisplayItemFromRaw([[Chaos Resistance Ring
		Amethyst Ring
		Crafted: true
		Prefix: {range:0.5}IncreasedEvasionRating4
		Prefix: None
		Prefix: None
		Suffix: None
		Suffix: None
		Suffix: None
		LevelReq: 33
		Implicits: 1
		{tags:chaos,resistance}{range:0.5}+(17-23)% to Chaos Resistance
		+71 to Evasion Rating]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are.equals(baseEs, build.calcsTab.mainOutput.EnergyShield)
		-- Es does not change after adding another ring with mod due to the first ring having an implicit evasion mod.
	end)

	it("Both slots explicit mod (evasion and es mastery)", function()

		build.configTab.input.customMods = "\z
		20% increased Maximum Energy Shield if both Equipped Rings have an Explicit Evasion Modifier\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		build.itemsTab:CreateDisplayItemFromRaw([[Energy Shield Boots
		Sorcerer Boots
		Energy Shield: 114
		EnergyShieldBasePercentile: 1
		Crafted: true
		Prefix: {range:0.5}IncreasedLife6
		Prefix: {range:0.5}LocalIncreasedEnergyShieldPercent5
		Prefix: {range:0.5}MovementVelocity5
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: B-B-B-B
		LevelReq: 67
		Implicits: 0
		74% increased Energy Shield
		+65 to maximum Life
		30% increased Movement Speed]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local baseEs = build.calcsTab.mainOutput.EnergyShield

		build.itemsTab:CreateDisplayItemFromRaw([[Chaos Resistance Ring
		Amethyst Ring
		Crafted: true
		Prefix: {range:0.5}IncreasedEvasionRating4
		Prefix: None
		Prefix: None
		Suffix: None
		Suffix: None
		Suffix: None
		LevelReq: 33
		Implicits: 1
		{tags:chaos,resistance}{range:0.5}+(17-23)% to Chaos Resistance
		+71 to Evasion Rating]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are.equals(baseEs, build.calcsTab.mainOutput.EnergyShield) -- No change in es with just one ring.

		build.itemsTab:CreateDisplayItemFromRaw([[Chaos Resistance Ring
		Amethyst Ring
		Crafted: true
		Prefix: {range:0.5}IncreasedEvasionRating4
		Prefix: None
		Prefix: None
		Suffix: None
		Suffix: None
		Suffix: None
		LevelReq: 33
		Implicits: 1
		{tags:chaos,resistance}{range:0.5}+(17-23)% to Chaos Resistance
		+71 to Evasion Rating]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are_not.equals(baseEs, build.calcsTab.mainOutput.EnergyShield)
		-- Es changes after adding two rings with explicit mods.
	end)

	it("Both slots explicit mod no rings (evasion and es mastery)", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Energy Shield Boots
		Sorcerer Boots
		Energy Shield: 114
		EnergyShieldBasePercentile: 1
		Crafted: true
		Prefix: {range:0.5}IncreasedLife6
		Prefix: {range:0.5}LocalIncreasedEnergyShieldPercent5
		Prefix: {range:0.5}MovementVelocity5
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: B-B-B-B
		LevelReq: 67
		Implicits: 0
		74% increased Energy Shield
		+65 to maximum Life
		30% increased Movement Speed]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local baseEs = build.calcsTab.mainOutput.EnergyShield

		build.configTab.input.customMods = "\z
		20% increased Maximum Energy Shield if both Equipped Rings have an Explicit Evasion Modifier\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(baseEs, build.calcsTab.mainOutput.EnergyShield) -- No change in es with no rings.

	end)

	it("mod if no mod on x slot", function()
		local baseLife = build.calcsTab.mainOutput.Life

		build.configTab.input.customMods = "\z
		15% increased maximum Life if there are no Life Modifiers on Equipped Body Armour\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are_not.equals(baseLife, build.calcsTab.mainOutput.Life)

		baseLife = build.calcsTab.mainOutput.Life

		build.itemsTab:CreateDisplayItemFromRaw([[Armour Chest
		Astral Plate
		Armour: 1696
		ArmourBasePercentile: 1
		Crafted: true
		Prefix: {range:0.5}LocalIncreasedPhysicalDamageReductionRating5
		Prefix: {range:0.5}LocalIncreasedPhysicalDamageReductionRatingPercent5
		Prefix: {range:0.5}IncreasedLife9
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: R-R-R-R-R-R
		LevelReq: 62
		Implicits: 1
		{tags:elemental,resistance}{range:0.5}+(8-12)% to all Elemental Resistances
		+92 to Armour
		74% increased Armour
		+95 to maximum Life]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are_not.equals(baseLife, build.calcsTab.mainOutput.Life)
	end)

	it("globalLimit mods", function()
		build.configTab.input.customMods = [[
			-1000% to cold resistance
		]]
		build.configTab:BuildModList()
		build.itemsTab:CreateDisplayItemFromRaw([[Replica Nebulis
			Void Sceptre
			League: Heist
			Quality: 20
			Sockets: B-B-B
			LevelReq: 68
			Implicits: 1
			40% increased Elemental Damage
			{fractured}{range:1}(15-20)% increased Cast Speed
			{range:1}(15-20)% increased Cold Damage per 1% Missing Cold Resistance, up to a maximum of 300%
			{range:1}(15-20)% increased Fire Damage per 1% Missing Fire Resistance, up to a maximum of 300%]])
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nFireball 20/0  1\n")
		runCallback("OnFrame")

		assert.are_not.equals(340, build.calcsTab.mainEnv.modDB:Sum("INC", "FireDamage"))
		assert.are_not.equals(340, build.calcsTab.mainEnv.modDB:Sum("INC", "ColdDamage"))

		newBuild()

		build.configTab.input.customMods = [[
			Gain 25% increased Armour per 5 Power for 8 seconds when you Warcry, up to a maximum of 100%
			Warcries have infinite Power
			warcries grant arcane surge to you and allies, with 10% increased effect per 5 power, up to 100%
		]]
		build.configTab:BuildModList()
		build.itemsTab:CreateDisplayItemFromRaw([[
			New Item
			Plate Vest
			Armour: 32
		]])
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Arc 20/0  1")

		assert.are_not.equals(40, build.calcsTab.mainEnv.modDB:Sum("INC", { flags = ModFlag.Cast }, "Speed"))
		assert.are_not.equals(64, build.calcsTab.mainOutput.Armour)
		runCallback("OnFrame")
	end)
	
	it("Heralds apply exposure with Heraldry", function()
		build.skillsTab:PasteSocketGroup("Arc 20/0  1\nHerald of Thunder 20/0  1\n")
		runCallback("OnFrame")
		
		assert.are.equals(0.5, build.calcsTab.calcsOutput.LightningEffMult)
				
		build.configTab.input.customMods = [[
		Nearby Enemies have Cold Exposure while you are affected by Herald of Ice
		Nearby Enemies have Fire Exposure while you are affected by Herald of Ash
		Nearby Enemies have Lightning Exposure while you are affected by Herald of Thunder
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(0.6, build.calcsTab.calcsOutput.LightningEffMult)
	end)
	
	it("Enemy self curse effect", function()
		build.skillsTab:PasteSocketGroup("Arc 20/0  1\nConductivity 14/0  1\n")
		runCallback("OnFrame")
		
		assert.are.equals(0.8, build.calcsTab.calcsOutput.LightningEffMult)
				
		build.configTab.input.customMods = [[
		Nearby Enemies have 20% increased Effect of Curses on them
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(0.86, build.calcsTab.calcsOutput.LightningEffMult)
	end)
	
	it("Max charges with conditional mod", function() -- see #9442
		build.skillsTab:PasteSocketGroup("Grace 20/20  1\n")
		runCallback("OnFrame")
		
		local baseFrenzyChargesMax = build.calcsTab.calcsOutput.FrenzyChargesMax
		local baseEnduranceChargesMax = build.calcsTab.calcsOutput.EnduranceChargesMax
		
		build.configTab.input.customMods = [[
			+1 to Maximum Frenzy Charges while affected by Grace
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(baseFrenzyChargesMax + 1, build.calcsTab.calcsOutput.FrenzyChargesMax)
		assert.are.equals(baseEnduranceChargesMax, build.calcsTab.calcsOutput.EnduranceChargesMax)
		
		build.configTab.input.customMods = [[
			Your Maximum Endurance Charges is equal to your Maximum Frenzy Charges
			+1 to Maximum Frenzy Charges while affected by Grace
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(baseFrenzyChargesMax + 1, build.calcsTab.calcsOutput.FrenzyChargesMax)
		assert.are.equals(baseEnduranceChargesMax + 1, build.calcsTab.calcsOutput.EnduranceChargesMax)
	end)

	it("adds life recoup to energy shield recoup", function()
		build.configTab.input.customMods = [[
			20% of Damage taken Recouped as Life
			10% of Physical Damage taken Recouped as Life
			Damage taken Recouped as Life is also Recouped as Energy Shield
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(20, build.calcsTab.calcsOutput.LifeRecoup)
		assert.are.equals(20, build.calcsTab.calcsOutput.EnergyShieldRecoup)
		assert.are.equals(10, build.calcsTab.calcsOutput.PhysicalLifeRecoup)
		assert.are.equals(10, build.calcsTab.calcsOutput.PhysicalEnergyShieldRecoup)
	end)

	it("supports Baleful Dominion recoup modifiers", function()
		build.configTab.input.customMods = [[
			15% of Damage taken Recouped as Life
			10% of Physical Damage taken Recouped as Life
			Life Recoup also recovers Mana
			50% less recovery from Recoup
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(7.5, build.calcsTab.calcsOutput.LifeRecoup)
		assert.are.equals(7.5, build.calcsTab.calcsOutput.ManaRecoup)
		assert.are.equals(5, build.calcsTab.calcsOutput.PhysicalLifeRecoup)
		assert.are.equals(5, build.calcsTab.calcsOutput.PhysicalManaRecoup)
		local lifeRecoupBreakdown = build.calcsTab.calcsEnv.player.breakdown.LifeRecoup
		assert.are.equals("7.5% over 4 seconds", lifeRecoupBreakdown[#lifeRecoupBreakdown])
		local physicalLifeRecoupBreakdown = build.calcsTab.calcsEnv.player.breakdown.PhysicalLifeRecoup
		assert.are.equals("= 5.0% over 4 seconds", physicalLifeRecoupBreakdown[#physicalLifeRecoupBreakdown])
	end)

	it("crafts modifiers from supported bases on rare-like uniques", function()
		local item = new("Item"):Item([[
			Item Class: Helmets
			Rarity: Unique
			Subsume the Source
			Faithful Helmet
			--------
			Item Level: 86
			--------
			{ Prefix Modifier "Hale" }
			+23 to maximum Life
			{ Unique Modifier }
			120% increased Explicit Modifier magnitudes
			{ Suffix Modifier "of Adaption" }
			+7 to all Attributes
			{ Unique Modifier }
			Cannot have non-Abyssal sockets
		]])

		assert.are.equals(4, item.affixLimit)
		assert.are.equals(4, item.prefixes.limit)
		assert.are.equals(0, item.suffixes.limit)
		assert.are.equals("AbyssJewelAddedLife1", item.prefixes[1].modId)
		assert.are.equals("AbyssAllAttributesJewel1", item.prefixes[2].modId)
		build.itemsTab.displayItem = item
		build.itemsTab:UpdateAffixControls()
		local lifeModAvailable = false
		for _, entry in ipairs(build.itemsTab.controls.displayItemAffix2.list) do
			for _, modId in ipairs(type(entry) == "table" and entry.modList or { }) do
				lifeModAvailable = lifeModAvailable or modId == "AbyssJewelAddedLife1"
			end
		end
		assert.is_true(lifeModAvailable)

		item:Craft()
		local raw = item:BuildRaw()
		assert.is_truthy(raw:find("increased Explicit Modifier magnitudes", 1, true))
		assert.is_truthy(raw:find("Cannot have non-Abyssal sockets", 1, true))
	end)

	it("uses the item base for rare-like modifier eligibility by default", function()
		local item = new("Item"):Item([[
			Item Class: Bows
			Rarity: Unique
			The Crimson Storm
			Steelwood Bow
			--------
			Item Level: 85
			--------
			{ Suffix Modifier "of the Order" }
			+24(24-28)% to Physical Damage over Time Multiplier
		]])

		assert.are.equals(1, item.affixLimit)
		assert.are.equals(0, item.prefixes.limit)
		assert.are.equals(1, item.suffixes.limit)
		assert.are.equals("JunMasterVeiledPhysicalDamageOverTimeMultiplier", item.suffixes[1].modId)
	end)

	it("keeps modifier metadata on duplicate variant tooltip lines", function()
		local item = new("Item"):Item([[
			Rarity: Unique
			Duplicate Variant Test
			Plate Vest
			Variant: First
			Variant: Second
			Selected Variant: 1
			Has Alt Variant: true
			Selected Alt Variant: 1
			Allow Duplicate Variants: true
			Implicits: 0
			{variant:1}+10 to maximum Life
		]])
		local tooltip = new("Tooltip"):Tooltip()
		build.itemsTab:AddItemTooltip(tooltip, item)

		local count = 0
		for _, line in ipairs(tooltip.lines) do
			if line.text and line.text:find("maximum Life", 1, true) then
				assert.are.equals(item.explicitModLines[1], line.modLine)
				count = count + 1
			end
		end
		assert.are.equals(2, count)
	end)

	it("does not sort cluster jewel modifiers when the sorting control is hidden", function()
		local item = new("Item"):Item([[
			Rarity: RARE
			New Item
			Large Cluster Jewel
			Crafted: true
			Prefix: {range:0.5}AfflictionNotableWickedPall_
			Prefix: {range:0.5}AfflictionNotableMiseryEverlasting
			Suffix: {range:0.5}AfflictionNotableUnholyGrace_
			Suffix: None
			Cluster Jewel Skill: affliction_chaos_damage
			Cluster Jewel Node Count: 8
			Quality: 0
			LevelReq: 40
			Implicits: 3
			{crafted}Adds 8 Passive Skills
			{crafted}2 Added Passive Skills are Jewel Sockets
			{crafted}Added Small Passive Skills grant: 12% increased Chaos Damage
			1 Added Passive Skill is Misery Everlasting
			1 Added Passive Skill is Unholy Grace
			1 Added Passive Skill is Wicked Pall
		]])
		local calcCount = 0
		build.itemsTab.displayItem = item
		build.itemsTab.controls.craftingSorting:SetSel(2, true)
		build.calcsTab.GetMiscCalculator = function()
			return function()
				calcCount = calcCount + 1
				return { }
			end
		end

		assert.is_false(build.itemsTab.controls.craftingSortingLabel.shown())
		build.itemsTab:UpdateAffixControls()
		assert.are.equals(0, calcCount)
	end)

	it("shows custom modifier controls when affix crafting is hidden", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			Test Item
			Iron Ring
			Implicits: 1
			Adds 1 to 4 Physical Damage to Attacks
			{crafted}+8 to Strength
		]])

		local controls = build.itemsTab.controls
		assert.is_falsy(build.itemsTab.displayItem.crafted)
		assert.is_falsy(controls.displayItemSectionAffix:IsShown())
		assert.is_true(controls.displayItemSectionCustom:IsShown())
		assert.is_true(controls.displayItemAddCustom:IsShown())
		assert.is_true(controls.displayItemCustomModifierRemove1:IsShown())
	end)

	it("hides custom modifier controls after saving the display item", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			Test Item
			Iron Ring
			Implicits: 1
			Adds 1 to 4 Physical Damage to Attacks
			{crafted}+8 to Strength
		]])

		local controls = build.itemsTab.controls
		assert.is_true(controls.displayItemCustomModifierRemove1:IsShown())
		assert.is_true(controls.displayItemCustomModifier1:IsShown())

		build.itemsTab:AddDisplayItem()

		assert.is_nil(build.itemsTab.displayItem)
		assert.is_falsy(controls.displayItemSectionCustom:IsShown())
		assert.is_falsy(controls.displayItemCustomModifierRemove1:IsShown())
		assert.is_falsy(controls.displayItemCustomModifier1:IsShown())
		assert.is_falsy(controls.displayItemCustomModifierLabel1:IsShown())
	end)

	it("shows affix controls for items crafted in Path of Building", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			New Item
			Cobalt Jewel
			Crafted: true
			Prefix: None
			Prefix: None
			Suffix: None
			Suffix: None
			Quality: 0
			LevelReq: 0
			Implicits: 0
		]])

		local controls = build.itemsTab.controls
		assert.is_true(controls.displayItemSectionAffix:IsShown())
		assert.is_true(controls.displayItemAffix1:IsShown())
	end)

	it("sorts crafted modifier replacements without retaining the selected modifier", function()
		local item = new("Item"):Item([[
			Rarity: RARE
			New Item
			Cobalt Jewel
			Crafted: true
			Prefix: {range:1}PercentIncreasedLifeJewel
			Prefix: None
			Suffix: None
			Suffix: None
			Quality: 0
			LevelReq: 0
			Implicits: 0
			7% increased maximum Life
		]])
		local calcCount = 0
		local retainedCount = 0
		build.itemsTab.displayItem = item
		build.itemsTab.controls.craftingSorting:SetSel(2, true)
		build.calcsTab.GetMiscCalculator = function()
			return function(args)
				calcCount = calcCount + 1
				for _, modLine in ipairs(args.repItem.explicitModLines) do
					if modLine.line == "7% increased maximum Life" then
						retainedCount = retainedCount + 1
						break
					end
				end
				return { }
			end
		end

		build.itemsTab:UpdateAffixControl(build.itemsTab.controls.displayItemAffix1, item, "Prefix", "prefixes", 1, { })
		assert.is_true(calcCount > 1)
		assert.are.equals(0, retainedCount)
	end)
	
	it("shows a fallback tooltip when an item's base is no longer supported", function()
		local item = new("Item"):Item([[
			Rarity: Unique
			Legacy Item
			Removed Base
		]])
		local tooltip = new("Tooltip"):Tooltip()

		assert.has_no.errors(function()
			build.itemsTab:AddItemTooltip(tooltip, item)
		end)
		assert.is_truthy(tooltip.lines[#tooltip.lines].text:find("Item base is not supported", 1, true))
	end)

	local function findActiveSkill(name)
		for _, activeSkill in ipairs(build.calcsTab.mainEnv.player.activeSkillList) do
			if activeSkill.activeEffect.grantedEffect.name == name then
				return activeSkill
			end
		end
	end

	local function countSupport(activeSkill, supportId)
		local count = 0
		for _, effect in ipairs(activeSkill.effectList) do
			if effect.grantedEffect.id == supportId then
				count = count + 1
			end
		end
		return count
	end

	local function hasSupport(activeSkill, supportId)
		return countSupport(activeSkill, supportId) > 0
	end

	local function addItem(raw)
		build.itemsTab:CreateDisplayItemFromRaw(raw)
		build.itemsTab:AddDisplayItem()
	end

	-- Pearl of Tsoatha: despite the "Socketed in" wording these support skills granted
	-- by the item in that slot as well, which ExtraSupport normally excludes
	it("ExtraSupport marked appliesToGrantedSkills supports an item granted skill", function()
		addItem("Granting Helmet\nEzomyte Burgonet\nGrants Level 20 Fireball")
		addItem("Supporting Ring\nPrismatic Ring\nSkills Socketed in your Helmet are Supported by level 20 Added Lightning Damage")
		runCallback("OnFrame")

		local fireball = findActiveSkill("Fireball")
		assert.is_not_nil(fireball)
		assert.is_true(hasSupport(fireball, "SupportAddedLightningDamage"))
		assert.is_true(fireball.skillModList:Sum("BASE", fireball.skillCfg, "LightningMin") > 0)
	end)

	it("ExtraSupport marked appliesToGrantedSkills still supports a socketed gem", function()
		addItem("Socketed Helmet\nEzomyte Burgonet\nSockets: B")
		addItem("Supporting Ring\nPrismatic Ring\nSkills Socketed in your Helmet are Supported by level 20 Added Lightning Damage")
		build.skillsTab:PasteSocketGroup("Slot: Helmet\nFireball 20/0  1\n")
		runCallback("OnFrame")

		local fireball = findActiveSkill("Fireball")
		assert.is_not_nil(fireball)
		assert.is_true(hasSupport(fireball, "SupportAddedLightningDamage"))
	end)

	it("ExtraSupport marked appliesToGrantedSkills does not cross slots", function()
		addItem("Granting Gloves\nSpiked Gloves\nGrants Level 20 Fireball")
		addItem("Supporting Ring\nPrismatic Ring\nSkills Socketed in your Helmet are Supported by level 20 Added Lightning Damage")
		runCallback("OnFrame")

		local fireball = findActiveSkill("Fireball")
		assert.is_not_nil(fireball)
		assert.is_false(hasSupport(fireball, "SupportAddedLightningDamage"))
	end)

	-- The relaxation is opt-in, so a Forbidden Shako style mod must keep the old behaviour
	it("plain ExtraSupport does not support an item granted skill", function()
		addItem("Shako Like Helmet\nEzomyte Burgonet\nGrants Level 20 Fireball\nSocketed Gems are Supported by Level 20 Added Cold Damage")
		runCallback("OnFrame")

		local fireball = findActiveSkill("Fireball")
		assert.is_not_nil(fireball)
		assert.is_false(hasSupport(fireball, "SupportAddedColdDamage"))
	end)

	local anointedTreeSkill = "Anointed Amulet\nAmber Amulet\nAllocates Radiant Crusade"
	local treePearl = "Tree Pearl\nPrismatic Ring\nSkills granted by your Passive Tree are Supported by level 20 Minion Damage"

	it("ExtraSupport marked appliesToGrantedSkills supports a tree granted skill", function()
		addItem(anointedTreeSkill)
		addItem(treePearl)
		runCallback("OnFrame")

		local sentinel = findActiveSkill("Summon Sentinel of Radiance")
		assert.is_not_nil(sentinel)
		assert.is_true(hasSupport(sentinel, "SupportMinionDamage"))
	end)

	-- Regression guard for the duplicate application fix: addExtraSupports has to go
	-- through addBestSupport, otherwise both rings insert their own copy of the support
	it("applies a tree ExtraSupport once when two items grant it", function()
		addItem(anointedTreeSkill)
		addItem(treePearl)
		addItem(treePearl)
		runCallback("OnFrame")

		local sentinel = findActiveSkill("Summon Sentinel of Radiance")
		assert.is_not_nil(sentinel)
		assert.are.equals(1, countSupport(sentinel, "SupportMinionDamage"))
	end)

	it("tree ExtraSupport does not support an item granted skill", function()
		addItem("Granting Helmet\nEzomyte Burgonet\nGrants Level 20 Fireball")
		addItem("Tree Pearl\nPrismatic Ring\nSkills granted by your Passive Tree are Supported by level 20 Added Lightning Damage")
		runCallback("OnFrame")

		local fireball = findActiveSkill("Fireball")
		assert.is_not_nil(fireball)
		assert.is_false(hasSupport(fireball, "SupportAddedLightningDamage"))
	end)

	it("tree ExtraSupport does not support a socketed gem", function()
		addItem("Socketed Helmet\nEzomyte Burgonet\nSockets: B")
		addItem("Tree Pearl\nPrismatic Ring\nSkills granted by your Passive Tree are Supported by level 20 Added Lightning Damage")
		build.skillsTab:PasteSocketGroup("Slot: Helmet\nFireball 20/0  1\n")
		runCallback("OnFrame")

		local fireball = findActiveSkill("Fireball")
		assert.is_not_nil(fireball)
		assert.is_false(hasSupport(fireball, "SupportAddedLightningDamage"))
	end)

	-- Every tree granted skill shares the synthetic "Passive Tree" slot, so each one pools
	-- the support lists of all the others. A second tree skill must not inflate the count.
	it("applies a tree ExtraSupport once when another tree skill shares the slot", function()
		addItem("Anointed Amulet\nAmber Amulet\nAllocates Radiant Crusade\nAllocates Avatar of the Wilds")
		addItem(treePearl)
		runCallback("OnFrame")

		assert.is_not_nil(findActiveSkill("Unbound Avatar"))
		local sentinel = findActiveSkill("Summon Sentinel of Radiance")
		assert.is_not_nil(sentinel)
		assert.are.equals(1, countSupport(sentinel, "SupportMinionDamage"))
	end)
end)
