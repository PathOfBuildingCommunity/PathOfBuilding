describe("Veiled mods on jewels", function()
	local initialPopupCount

	before_each(function()
		newBuild()
		main:SelectControl()
		initialPopupCount = #main.popups
	end)

	after_each(function()
		main:SelectControl()
		while #main.popups > initialPopupCount do
			main:ClosePopup()
		end
	end)

	local function openCustomModifierPopup(raw)
		build.itemsTab:CreateDisplayItemFromRaw(raw)
		build.itemsTab:AddCustomModifierToDisplayItem()
		return main.popups[1].controls
	end

	local function selectVeiledMods(controls)
		for i, source in ipairs(controls.source.list) do
			if source.sourceId == "VEILED" then
				controls.source:SetSel(i)
				local ids = { }
				for _, listMod in ipairs(controls.modSelect.list) do
					for modId, mod in pairs(data.veiledMods) do
						if mod == listMod.mod then
							ids[modId] = true
						end
					end
				end
				return ids
			end
		end
	end

	it("offers jewel unveiled mods on a rare jewel", function()
		local ids = selectVeiledMods(openCustomModifierPopup("Rarity: RARE\nTest Jewel\nCobalt Jewel"))
		assert.is_truthy(ids)
		assert.is_true(ids["JunMasterVeiledJewelChargeDuration"])
		assert.is_nil(ids["JunMasterVeiledAbyssSharedCDR"])
		assert.is_nil(ids["JunMasterVeiledDoubleDamageChance1h"])
	end)

	it("offers abyss unveiled mods on a rare abyss jewel", function()
		local ids = selectVeiledMods(openCustomModifierPopup("Rarity: RARE\nTest Jewel\nGhastly Eye Jewel"))
		assert.is_truthy(ids)
		assert.is_true(ids["JunMasterVeiledAbyssSharedCDR"])
		assert.is_true(ids["JunMasterVeiledAbyssGhastlyMinionConvertFire"])
		assert.is_nil(ids["JunMasterVeiledAbyssMurderousRageAxeSword"])
		assert.is_nil(ids["JunMasterVeiledJewelChargeDuration"])
	end)

	it("does not offer veiled mods on cluster jewels", function()
		local ids = selectVeiledMods(openCustomModifierPopup("Rarity: RARE\nTest Jewel\nLarge Cluster Jewel"))
		assert.is_nil(ids)
	end)
end)
