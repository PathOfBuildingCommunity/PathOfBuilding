describe("Scaeva empty sockets", function()
	before_each(function()
		newBuild()
		build.configTab.input.customMods = "+1000 to Armour\n+1000 to Evasion Rating\n+1000 to maximum Energy Shield\n+1000 to Ward"
		build.configTab:BuildModList()
	end)

	local function equip(raw, slot)
		local item = new("Item"):Item(raw)
		build.itemsTab:AddItem(item, true)
		build.itemsTab.slots[slot]:SetSelItemId(item.id)
		build.buildFlag = true
		return item
	end

	for _, slot in ipairs({ "Weapon 1", "Weapon 2" }) do
		it("applies global defences only per empty socket in " .. slot, function()
			-- Other equipped sockets must not contribute to Scaeva's bonus.
			equip("Rarity: NORMAL\nIron Hat\nSockets: W-W-W-W\nImplicits: 0", "Helmet")
			for _, occupied in ipairs({ 0, 1, 3 }) do
				build.skillsTab.socketGroupList = { }
				build.skillsTab:PasteSocketGroup("Slot: " .. slot .. "\n" .. ("Fireball 1/0  1\n"):rep(occupied))
				equip("Rarity: UNIQUE\nScaeva\nGladius\nSockets: R-G-B\nImplicits: 0\n8% increased Global Defences per Empty Socket", slot)
				runCallback("OnFrame")
				local actual = build.calcsTab.mainOutput
				local armour, evasion, energyShield = actual.Armour, actual.Evasion, actual.EnergyShield
				local ward = actual.Ward
				assert.is_true(ward > 0)

				-- Three sockets minus the occupied ones, at 8% per empty socket.
				local bonus = 8 * (3 - occupied)
				equip("Rarity: UNIQUE\nScaeva\nGladius\nSockets: R-G-B\nImplicits: 0\n" .. bonus .. "% increased Global Defences", slot)
				runCallback("OnFrame")
				assert.are.equals(build.calcsTab.mainOutput.Armour, armour)
				assert.are.equals(build.calcsTab.mainOutput.Evasion, evasion)
				assert.are.equals(build.calcsTab.mainOutput.EnergyShield, energyShield)
				assert.are.equals(build.calcsTab.mainOutput.Ward, ward)
			end
		end)
	end
end)
