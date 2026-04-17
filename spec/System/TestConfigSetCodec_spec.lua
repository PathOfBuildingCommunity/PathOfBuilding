describe("TestConfigSetCodec", function()
	local savedDeflate, savedInflate

	before_each(function()
		newBuild()
		-- Headless stubs for Deflate/Inflate return "",
		-- which would break encode/decode.
		-- Replaced them with identity functions,
		-- so that the base64 + XML layer is tested in isolation.
		savedDeflate = Deflate
		savedInflate = Inflate
		_G.Deflate = function(data) return data end
		_G.Inflate = function(data) return data end
	end)

	after_each(function()
		_G.Deflate = savedDeflate
		_G.Inflate = savedInflate
	end)

	it("export produces a non-empty base64 code", function()
		local configTab = build.configTab
		local configSet = configTab.configSets[configTab.activeConfigSetId]
		configSet.input["usePowerCharges"] = true
		local code = configTab:EncodeConfigSet(configSet)
		assert.is_not_nil(code)
		assert.is_true(#code > 0)
	end)

	it("roundtrip preserves boolean inputs", function()
		local configTab = build.configTab
		local configSet = configTab.configSets[configTab.activeConfigSetId]
		configSet.input["usePowerCharges"] = true
		local code = configTab:EncodeConfigSet(configSet)
		local imported, err = configTab:DecodeConfigSet(code, "Test")
		assert.is_nil(err)
		assert.is_not_nil(imported)
		assert.are.equal(true, imported.input["usePowerCharges"])
	end)

	it("roundtrip preserves numeric inputs", function()
		local configTab = build.configTab
		local configSet = configTab.configSets[configTab.activeConfigSetId]
		-- Use 75 to avoid matching any boss-level placeholder (83/84/85),
		-- which would cause GetDefaultState skip export.
		configSet.input["enemyLevel"] = 75
		local code = configTab:EncodeConfigSet(configSet)
		local imported, err = configTab:DecodeConfigSet(code, "Test")
		assert.is_nil(err)
		assert.is_not_nil(imported)
		assert.are.equal(75, imported.input["enemyLevel"])
	end)

	it("roundtrip preserves string inputs", function()
		local configTab = build.configTab
		local configSet = configTab.configSets[configTab.activeConfigSetId]
		-- "Uber" is non-default (default is "Pinnacle" from defaultIndex=3)
		configSet.input["enemyIsBoss"] = "Uber"
		local code = configTab:EncodeConfigSet(configSet)
		local imported, err = configTab:DecodeConfigSet(code, "Test")
		assert.is_nil(err)
		assert.is_not_nil(imported)
		assert.are.equal("Uber", imported.input["enemyIsBoss"])
	end)

	it("roundtrip preserves multiple values simultaneously", function()
		local configTab = build.configTab
		local configSet = configTab.configSets[configTab.activeConfigSetId]
		configSet.input["usePowerCharges"] = true
		configSet.input["enemyLevel"] = 75
		configSet.input["enemyIsBoss"] = "Uber"
		local code = configTab:EncodeConfigSet(configSet)
		local imported, err = configTab:DecodeConfigSet(code, "Multi")
		assert.is_nil(err)
		assert.is_not_nil(imported)
		assert.are.equal(true, imported.input["usePowerCharges"])
		assert.are.equal(75, imported.input["enemyLevel"])
		assert.are.equal("Uber", imported.input["enemyIsBoss"])
	end)

	it("import uses the provided name, not the exported title", function()
		local configTab = build.configTab
		local configSet = configTab.configSets[configTab.activeConfigSetId]
		configSet.title = "Original Title"
		local code = configTab:EncodeConfigSet(configSet)
		local imported, err = configTab:DecodeConfigSet(code, "Custom Name")
		assert.is_nil(err)
		assert.is_not_nil(imported)
		assert.are.equal("Custom Name", imported.title)
	end)

	it("export and re-import of an unmodified config set succeeds", function()
		local configTab = build.configTab
		local configSet = configTab.configSets[configTab.activeConfigSetId]
		local code = configTab:EncodeConfigSet(configSet)
		assert.is_true(#code > 0)
		local imported, err = configTab:DecodeConfigSet(code, "Imported")
		assert.is_nil(err)
		assert.is_not_nil(imported)
		assert.are.equal("Imported", imported.title)
	end)

	it("returns error for garbage input", function()
		local configTab = build.configTab
		local _, err = configTab:DecodeConfigSet("!!!not_valid!!!", "Test")
		assert.is_not_nil(err)
	end)

	it("returns error when decoded XML root is not a ConfigSet", function()
		local configTab = build.configTab
		local xmlText = "<PathOfBuilding></PathOfBuilding>"
		local code = common.base64.encode(Deflate(xmlText)):gsub("+", "-"):gsub("/", "_")
		local _, err = configTab:DecodeConfigSet(code, "Test")
		assert.is_not_nil(err)
	end)
end)
