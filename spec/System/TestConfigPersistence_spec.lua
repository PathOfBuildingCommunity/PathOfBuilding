describe("Configuration persistence", function()
	before_each(function()
		newBuild()
	end)

	it("omits untouched defaults while retaining existing non-default settings", function()
		local configTab = build.configTab
		local function savedInputs()
			local xml = { }
			configTab:Save(xml)
			local inputs = { }
			for _, node in ipairs(xml[1]) do
				if node.elem == "Input" then
					inputs[node.attrib.name] = node.attrib
				end
			end
			return inputs
		end
		local defaults = {
			"resistancePenalty", "GamblesprintMovementSpeed", "bloodsoakedBannerStages",
			"conditionCorruptingCryStages", "touchedDebuffsCount", "maniaDebuffsCount",
		}
		local inputs = savedInputs()
		for _, var in ipairs(defaults) do
			assert.is_not_nil(configTab.input[var])
			assert.is_nil(inputs[var])
		end
		assert.is_nil(inputs.overridePowerCharges)
		-- Selecting a numeric dropdown's default must not create a saved override.
		configTab.input.EHPUnluckyWorstOf = 1
		assert.is_nil(savedInputs().EHPUnluckyWorstOf)

		configTab.input.resistancePenalty = 0
		configTab.input.EHPUnluckyWorstOf = 2
		configTab.varControls.maniaDebuffsCount:SetText("2", true)
		inputs = savedInputs()
		assert.are.equal("0", inputs.resistancePenalty.number)
		assert.are.equal("2", inputs.EHPUnluckyWorstOf.number)
		assert.are.equal("2", inputs.maniaDebuffsCount.number)
		loadBuildFromXML(build:SaveDB("code"))
		assert.are.equal(0, build.configTab.input.resistancePenalty)
		assert.are.equal(2, build.configTab.input.EHPUnluckyWorstOf)
		assert.are.equal(2, build.configTab.input.maniaDebuffsCount)
	end)

	it("preserves explicit numeric inputs separately from blank fields in every config set", function()
		local configTab = build.configTab
		local vars = { "overrideEnduranceCharges", "overrideCrabBarriers", "conditionStationary" }
		for id = 1, 3 do
			if id > 1 then
				configTab:NewConfigSet(id, "Config " .. id)
				table.insert(configTab.configSetOrderList, id)
			end
			configTab:SetActiveConfigSet(id)
			for _, var in ipairs(vars) do
				configTab.varControls[var]:SetText(id == 1 and "0" or id == 2 and "2" or "", true)
				configTab.placeholder[var] = 0
			end
		end

		loadBuildFromXML(build:SaveDB("code"))

		configTab = build.configTab
		for id = 1, 3 do
			configTab:SetActiveConfigSet(id)
			for _, var in ipairs(vars) do
				assert.are.equal(id == 1 and "0" or id == 2 and "2" or "", configTab.varControls[var].buf)
				if id == 3 then
					assert.is_nil(configTab.input[var])
				else
					assert.are.equal(id == 1 and 0 or 2, configTab.input[var])
				end
				assert.are.equal(0, configTab.placeholder[var])
			end
		end
	end)

	for _, minion in ipairs({ false, true }) do
		it("calculates saved charge overrides for " .. (minion and "minions" or "the player"), function()
			build.skillsTab:PasteSocketGroup("Raise Zombie 20/0  1")
			for _, text in ipairs({ "0", "2", "" }) do
				local configTab = build.configTab
				for _, charge in ipairs({ "Power", "Frenzy", "Endurance" }) do
					configTab.input[(minion and "minionsUse" or "use") .. charge .. "Charges"] = true
					configTab.varControls[(minion and "minionsOverride" or "override") .. charge .. "Charges"]:SetText(text, true)
				end
				loadBuildFromXML(build:SaveDB("code"))
				runCallback("OnFrame")
				local output = minion and build.calcsTab.mainEnv.minion.output or build.calcsTab.mainOutput
				for _, charge in ipairs({ "Power", "Frenzy", "Endurance" }) do
					assert.are.equal(3, output[charge .. "ChargesMax"])
					assert.are.equal(tonumber(text) or 3, output[charge .. "Charges"])
				end
			end
		end)
	end
end)
