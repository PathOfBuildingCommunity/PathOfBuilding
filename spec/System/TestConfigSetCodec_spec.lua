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

	-- Mirrors the serialisation logic in ConfigTabClass:OpenExportConfigSetPopup.
	local function encodeConfigSet(configSet, configTab)
		local xmlNode = { elem = "ConfigSet", attrib = { title = configSet.title } }
		for k, v in pairs(configSet.input) do
			if v ~= configTab:GetDefaultState(k, type(v)) then
				local node = { elem = "Input", attrib = { name = k } }
				if type(v) == "number" then
					node.attrib.number = tostring(v)
				elseif type(v) == "boolean" then
					node.attrib.boolean = tostring(v)
				else
					node.attrib.string = tostring(v)
				end
				table.insert(xmlNode, node)
			end
		end
		for k, v in pairs(configSet.placeholder) do
			local node = { elem = "Placeholder", attrib = { name = k } }
			if type(v) == "number" then
				node.attrib.number = tostring(v)
			else
				node.attrib.string = tostring(v)
			end
			table.insert(xmlNode, node)
		end
		local xmlText = common.xml.ComposeXML(xmlNode)
		return common.base64.encode(Deflate(xmlText)):gsub("+", "-"):gsub("/", "_")
	end

	-- Mirrors the deserialisation logic in ConfigTabClass:OpenImportConfigSetPopup.
	local function decodeConfigSet(code, configTab, name)
		local xmlText = Inflate(common.base64.decode(code:gsub("-", "+"):gsub("_", "/")))
		if not xmlText or #xmlText == 0 then
			return nil, "decode failed"
		end
		local parsedXML, errMsg = common.xml.ParseXML(xmlText)
		if errMsg or not parsedXML or not parsedXML[1] or parsedXML[1].elem ~= "ConfigSet" then
			return nil, errMsg or "invalid config set code"
		end
		local xmlConfigSet = parsedXML[1]
		local newConfigSet = configTab:NewConfigSet(nil, name or xmlConfigSet.attrib.title or "Imported")
		for _, child in ipairs(xmlConfigSet) do
			if child.elem == "Input" and child.attrib.name then
				if child.attrib.number then
					newConfigSet.input[child.attrib.name] = tonumber(child.attrib.number)
				elseif child.attrib.boolean then
					newConfigSet.input[child.attrib.name] = child.attrib.boolean == "true"
				elseif child.attrib.string then
					newConfigSet.input[child.attrib.name] = child.attrib.string
				end
			elseif child.elem == "Placeholder" and child.attrib.name then
				if child.attrib.number then
					newConfigSet.placeholder[child.attrib.name] = tonumber(child.attrib.number)
				elseif child.attrib.string then
					newConfigSet.placeholder[child.attrib.name] = child.attrib.string
				end
			end
		end
		return newConfigSet, nil
	end

	it("export produces a non-empty base64 code", function()
		local configTab = build.configTab
		local configSet = configTab.configSets[configTab.activeConfigSetId]
		configSet.input["usePowerCharges"] = true
		local code = encodeConfigSet(configSet, configTab)
		assert.is_not_nil(code)
		assert.is_true(#code > 0)
	end)

	it("roundtrip preserves boolean inputs", function()
		local configTab = build.configTab
		local configSet = configTab.configSets[configTab.activeConfigSetId]
		configSet.input["usePowerCharges"] = true
		local code = encodeConfigSet(configSet, configTab)
		local imported, err = decodeConfigSet(code, configTab, "Test")
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
		local code = encodeConfigSet(configSet, configTab)
		local imported, err = decodeConfigSet(code, configTab, "Test")
		assert.is_nil(err)
		assert.is_not_nil(imported)
		assert.are.equal(75, imported.input["enemyLevel"])
	end)

	it("roundtrip preserves string inputs", function()
		local configTab = build.configTab
		local configSet = configTab.configSets[configTab.activeConfigSetId]
		-- "Uber" is non-default (default is "Pinnacle" from defaultIndex=3)
		configSet.input["enemyIsBoss"] = "Uber"
		local code = encodeConfigSet(configSet, configTab)
		local imported, err = decodeConfigSet(code, configTab, "Test")
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
		local code = encodeConfigSet(configSet, configTab)
		local imported, err = decodeConfigSet(code, configTab, "Multi")
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
		local code = encodeConfigSet(configSet, configTab)
		local imported, err = decodeConfigSet(code, configTab, "Custom Name")
		assert.is_nil(err)
		assert.is_not_nil(imported)
		assert.are.equal("Custom Name", imported.title)
	end)

	it("export and re-import of an unmodified config set succeeds", function()
		local configTab = build.configTab
		local configSet = configTab.configSets[configTab.activeConfigSetId]
		local code = encodeConfigSet(configSet, configTab)
		assert.is_true(#code > 0)
		local imported, err = decodeConfigSet(code, configTab, "Imported")
		assert.is_nil(err)
		assert.is_not_nil(imported)
		assert.are.equal("Imported", imported.title)
	end)

	it("returns error for garbage input", function()
		local configTab = build.configTab
		local _, err = decodeConfigSet("!!!not_valid!!!", configTab, "Test")
		assert.is_not_nil(err)
	end)

	it("returns error when decoded XML root is not a ConfigSet", function()
		local configTab = build.configTab
		local xmlText = "<PathOfBuilding></PathOfBuilding>"
		local code = common.base64.encode(Deflate(xmlText)):gsub("+", "-"):gsub("/", "_")
		local _, err = decodeConfigSet(code, configTab, "Test")
		assert.is_not_nil(err)
	end)
end)
