local function uint16(value)
	return string.char(value % 256, math.floor(value / 256) % 256)
end

local parseAbyssJewel = select(4, LoadModule("Modules/DataAbyssJewelLookUpTableHelper"))

local function abyssModification(components)
	local encoded = { string.char(#components) }
	for _, component in ipairs(components) do
		encoded[#encoded + 1] = string.char(component.type, component.id, #component.rolls)
		for _, roll in ipairs(component.rolls) do
			encoded[#encoded + 1] = uint16(roll < 0 and roll + 65536 or roll)
		end
	end
	return table.concat(encoded)
end

local function abyssHeader(format, jewelType, seed)
	return format .. string.char(1, jewelType) .. uint16(seed) .. uint16(seed) .. uint16(1)
end

local function kurgalExampleData()
	local affectedNodes = {
		{ id = 4367, modification = abyssModification({ { type = 1, id = 24, rolls = { 6 } } }) },
		{ id = 15117, modification = abyssModification({ { type = 1, id = 19, rolls = { 8 } } }) },
		{ id = 20528, modification = abyssModification({ { type = 2, id = 207, rolls = { -15 } } }) },
		{ id = 21958, modification = abyssModification({ { type = 2, id = 211, rolls = { 12, 18 } } }) },
	}
	local encoded = { abyssHeader("ABYS", 9, 533), string.char(1, 60), uint16(61419), string.char(#affectedNodes) }
	for _, affectedNode in ipairs(affectedNodes) do
		encoded[#encoded + 1] = uint16(affectedNode.id)
		encoded[#encoded + 1] = affectedNode.modification
	end
	return table.concat(encoded)
end

local function zorathExampleData()
	local affectedNodes = {
		{ id = 23027, modification = abyssModification({ { type = 1, id = 90, rolls = { 8 } } }) },
		{ id = 34171, modification = abyssModification({ { type = 1, id = 116, rolls = { 19 } } }) },
		{ id = 36949, modification = abyssModification({ { type = 2, id = 4, rolls = { 2 } } }) },
		{ id = 41472, modification = abyssModification({ { type = 2, id = 41, rolls = { 12 } } }) },
		{ id = 50692, modification = abyssModification({ { type = 1, id = 77, rolls = { 1 } } }) },
		{ id = 53884, modification = abyssModification({ { type = 1, id = 78, rolls = { 1 } } }) },
		{ id = 60472, modification = abyssModification({ { type = 1, id = 102, rolls = { 4 } } }) },
	}
	local encoded = { abyssHeader("ABYN", 11, 6564), uint16(#affectedNodes) }
	for _, affectedNode in ipairs(affectedNodes) do
		encoded[#encoded + 1] = uint16(affectedNode.id)
	end
	for _, affectedNode in ipairs(affectedNodes) do
		encoded[#encoded + 1] = affectedNode.modification
	end
	encoded[#encoded + 1] = "ASCS" .. uint16(2)
		.. string.char(#"Inquisitor") .. "Inquisitor" .. string.char(1) .. uint16(53884)
		.. string.char(#"Chieftain") .. "Chieftain" .. string.char(1) .. uint16(50692)
	return table.concat(encoded)
end

local function newAbyssTimelessJewel(name, baseName, seedLine)
	return new("Item"):Item("Rarity: UNIQUE\n" .. name .. "\n" .. baseName .. "\n" ..
		"Limited to: 1 Historic\nImplicits: 0\n" .. seedLine .. "\n" ..
		"Passives affected are Conquered by the Abyssal\nHistoric\n")
end

local function allocatePathToNode(spec, targetNode)
	local classStart
	for _, node in pairs(spec.allocNodes) do
		if node.type == "ClassStart" then
			classStart = node
			break
		end
	end
	local queue = { classStart }
	local visited = { [classStart.id] = true }
	local parent = { }
	local head = 1
	while head <= #queue and not visited[targetNode.id] do
		local current = queue[head]
		head = head + 1
		for _, linked in ipairs(current.linked) do
			if not visited[linked.id] and linked.type ~= "Mastery" and linked.type ~= "AscendClassStart" then
				visited[linked.id] = true
				parent[linked.id] = current
				queue[#queue + 1] = linked
			end
		end
	end
	if not visited[targetNode.id] then
		return false
	end
	local current = targetNode
	while current do
		current.alloc = true
		spec.allocNodes[current.id] = current
		current = parent[current.id]
	end
	return true
end

local function equipJewel(spec, socketId, item)
	build.itemsTab:AddItem(item, true)
	spec.jewels[socketId] = item.id
	local slot = build.itemsTab.sockets[socketId]
	if slot then
		slot.selItemId = item.id
	end
	return slot
end

describe("Abyss timeless jewels", function()
	before_each(function()
		newBuild()
	end)

	after_each(function()
		data.timelessJewelLUTs[9] = nil
		data.timelessJewelLUTs[11] = nil
		if main.popups[1] and main.popups[1].title == "Find a Timeless Jewel" then
			main:ClosePopup()
		end
	end)

	it("parses the Kurgal and Zorath seed modifiers", function()
		local kurgal = newAbyssTimelessJewel("Baleful Dominion", "Hypnotic Eye Jewel",
			"Subjugating 533 souls in the thrall of Kurgal")
		local zorath = newAbyssTimelessJewel("Reclaimed Malevolence", "Assembled Eye Jewel",
			"Binding 6564 souls to phylacteries to sustain Zorath")

		assert.are.equal(533, kurgal.jewelData.conqueredBy.id)
		assert.are.equal("abyss_hypnotic", kurgal.jewelData.conqueredBy.conqueror.type)
		assert.are.equal(6564, zorath.jewelData.conqueredBy.id)
		assert.are.equal("abyss_special", zorath.jewelData.conqueredBy.conqueror.type)
	end)

	it("reads Kurgal seed 533 at socket 61419", function()
		data.timelessJewelLUTs[9] = parseAbyssJewel(9, kurgalExampleData())
		local affectedNodes = data.readAbyssJewelLUT(533, 61419, 9)

		assert.are.same({ type = 1, id = 622, rolls = { 8 } }, affectedNodes[15117][1])
		assert.are.same({ type = 1, id = 627, rolls = { 6 } }, affectedNodes[4367][1])
		assert.are.same({ type = 2, id = 207, rolls = { -15 } }, affectedNodes[20528][1])
		assert.are.same({ type = 2, id = 211, rolls = { 12, 18 } }, affectedNodes[21958][1])
		local changedNode = data.resolveAbyssJewelComponent(affectedNodes[21958][1], build.spec.tree.legion)
		local _, _, minimumRoll = data.getAbyssJewelComponentRoll(affectedNodes[21958][1], changedNode, 1)
		local _, _, maximumRoll = data.getAbyssJewelComponentRoll(affectedNodes[21958][1], changedNode, 2)
		assert.are.same({ 12, 18 }, { minimumRoll, maximumRoll })
		assert.is_nil(affectedNodes[53279])
	end)

	it("loads every part of the Kurgal archive in order", function()
		local loadJewelFile = LoadModule("Modules/DataJewelFileLoader")
		local originalInflate = _G.Inflate
		local compressedSize
		_G.Inflate = function(compressedData)
			compressedSize = #compressedData
			return compressedData:sub(1, 2) .. compressedData:sub(-4)
		end
		local ok, signature = pcall(loadJewelFile, "AbyssKurgal", false)
		_G.Inflate = originalInflate

		assert.is_true(ok)
		assert.are.equal(29419012, compressedSize)
		assert.are.equal(string.char(0x78, 0xDA, 0x51, 0x9B, 0xED, 0x9E), signature)
	end)

	it("applies the Kurgal example to the passive tree", function()
		local spec = build.spec
		assert.is_true(allocatePathToNode(spec, spec.nodes[61419]))
		spec:BuildAllDependsAndPaths()
		local unchangedName = spec.nodes[53279].dn
		local unchangedStats = table.concat(spec.nodes[53279].sd, "\n")

		data.timelessJewelLUTs[9] = parseAbyssJewel(9, kurgalExampleData())
		equipJewel(spec, 61419, newAbyssTimelessJewel("Baleful Dominion", "Hypnotic Eye Jewel",
			"Subjugating 533 souls in the thrall of Kurgal"))
		spec:BuildAllDependsAndPaths()

		assert.are.equal("Fire Resistance", spec.nodes[15117].dn)
		assert.are.equal("+8% to Fire Resistance", table.concat(spec.nodes[15117].sd, "\n"))
		assert.are.equal("Cold and Lightning Resistance", spec.nodes[4367].dn)
		assert.are.equal("+6% to Cold and Lightning Resistances", table.concat(spec.nodes[4367].sd, "\n"))
		assert.matches("15%% reduced Effect of Curses on you while on Consecrated Ground",
			table.concat(spec.nodes[20528].sd, "\n"))
		local addedDamageStats = table.concat(spec.nodes[21958].sd, "\n")
		assert.matches("12 to 18 Added Spell Cold Damage while Dual Wielding", addedDamageStats, nil, true)
		local _, addedDamageLineCount = addedDamageStats:gsub("Added Spell Cold Damage while Dual Wielding", "")
		assert.are.equal(1, addedDamageLineCount)
		assert.are.equal(unchangedName, spec.nodes[53279].dn)
		assert.are.equal(unchangedStats, table.concat(spec.nodes[53279].sd, "\n"))
	end)

	it("finds Kurgal seed 533 with rolled replacement and addition weights", function()
		data.timelessJewelLUTs[9] = parseAbyssJewel(9, kurgalExampleData())
		build.timelessData.jewelType = { id = 9 }
		build.timelessData.conquerorType = { }
		build.timelessData.jewelSocket = { id = 61419 }
		build.timelessData.searchList = table.concat({
			"abyss_hypnotic_small_attribute19, 1, 0",
			"abyss_hypnotic_notable_16, 1, 0",
		}, "\n")
		build.timelessData.searchListFallback = ""

		build.treeTab:FindTimelessJewel()
		local controls = main.popups[1].controls
		controls.searchButton.onClick()

		assert.are.equal(1, #build.timelessData.searchResults)
		assert.are.equal(533, build.timelessData.searchResults[1].seed)
		assert.are.equal(23, build.timelessData.searchResults[1].total)

		controls.searchResults:OnSelClick(1, build.timelessData.searchResults[1], true)
		local addedJewel
		for _, item in pairs(build.itemsTab.items) do
			if item.jewelData and item.jewelData.conqueredBy and item.jewelData.conqueredBy.id == 533 then
				addedJewel = item
				break
			end
		end
		assert.is_truthy(addedJewel)
		assert.are.equal("Hypnotic Eye Jewel", addedJewel.baseName)
		assert.are.equal("abyss_hypnotic", addedJewel.jewelData.conqueredBy.conqueror.type)
	end)

	it("shows and scores both stats of an added damage notable", function()
		data.timelessJewelLUTs[9] = parseAbyssJewel(9, kurgalExampleData())
		build.timelessData.jewelType = { id = 9 }
		build.timelessData.conquerorType = { }
		build.timelessData.jewelSocket = { id = 61419 }
		build.timelessData.searchList = "abyss_hypnotic_notable_20, 1, 0, 0"
		build.timelessData.searchListFallback = ""

		build.treeTab:FindTimelessJewel()
		local controls = main.popups[1].controls
		local addedDamageOption
		for _, option in ipairs(controls.nodeSelect.list) do
			if option.id == "abyss_hypnotic_notable_20" then
				addedDamageOption = option
				break
			end
		end
		assert.is_truthy(addedDamageOption)
		assert.are.same({
			"(12-14) to (17-19) Added Spell Cold Damage while Dual Wielding",
		}, addedDamageOption.descriptions)

		controls.searchButton.onClick()
		assert.are.equal(1, #build.timelessData.searchResults)
		assert.are.equal(12, build.timelessData.searchResults[1].total)

		controls.searchList:SetText("abyss_hypnotic_notable_20, 0, 1, 0", true)
		controls.searchButton.onClick()
		assert.are.equal(1, #build.timelessData.searchResults)
		assert.are.equal(18, build.timelessData.searchResults[1].total)

		local addedDamage
		for _, addition in pairs(build.spec.tree.legion.additions) do
			if addition.id == "abyss_hypnotic_notable_20" then
				addedDamage = addition
				break
			end
		end
		addedDamage.modListGenerated = nil
		controls.fallbackWeightsButton.onClick()
		local primaryValues, secondaryValues = { }, { }
		for _, mod in ipairs(addedDamage.modListGenerated[1].modList) do
			primaryValues[mod.name] = mod.value
		end
		for _, mod in ipairs(addedDamage.modListGenerated[2].modList) do
			secondaryValues[mod.name] = mod.value
		end
		assert.are.same({ ColdMin = 100, ColdMax = 0 }, primaryValues)
		assert.are.same({ ColdMin = 0, ColdMax = 100 }, secondaryValues)
	end)

	it("uses named notables and generates fallback weights for variable small nodes", function()
		local zorathCastSpeedNotable
		for _, addition in pairs(build.spec.tree.legion.additions) do
			if addition.id:match("^abyss_.+_notable_%d+$") then
				assert.is_nil(addition.dn:match("^Notable %d+$"), "Missing name for " .. addition.id)
			end
			if addition.id == "abyss_special_notable_17" then
				zorathCastSpeedNotable = addition
				break
			end
		end
		assert.are.equal("Cast Speed", zorathCastSpeedNotable.dn)

		build.skillsTab:PasteSocketGroup("Ethereal Knives 20/0  1\n")
		runCallback("OnFrame")
		build.timelessData.jewelType = { id = 11 }
		build.timelessData.conquerorType = { }
		build.timelessData.jewelSocket = { id = 26196 }
		build.treeTab:FindTimelessJewel()
		local controls = main.popups[1].controls
		controls.fallbackWeightsList.selIndex = 1 -- Full DPS
		controls.fallbackWeightsButton.onClick()

		assert.matches("abyss_special_notable_17, 1, 0, 0", build.timelessData.searchListFallback, nil, true)
		assert.matches("abyss_special_small_attribute25, 1, 0, 0", build.timelessData.searchListFallback, nil, true)
	end)

	it("reads Zorath seed 6564 node and Inquisitor ascendancy changes", function()
		data.timelessJewelLUTs[11] = parseAbyssJewel(11, zorathExampleData())
		local expected = {
			[23027] = { type = 1, id = 686, rolls = { 8 } },
			[34171] = { type = 1, id = 712, rolls = { 19 } },
			[36949] = { type = 2, id = 266, rolls = { 2 } },
			[41472] = { type = 2, id = 303, rolls = { 12 } },
			[53884] = { type = 1, id = 526, rolls = { 1 } },
			[60472] = { type = 1, id = 698, rolls = { 4 } },
		}
		local path = { }
		for nodeId in pairs(expected) do
			if nodeId ~= 53884 then
				path[nodeId] = true
			end
		end
		local affectedNodes = data.readAbyssJewelLUT(6564, nil, 11, path, "Inquisitor")
		for nodeId, component in pairs(expected) do
			assert.are.same(component, affectedNodes[nodeId][1])
		end
		assert.is_nil(affectedNodes[50692])
		local allAscendancies = data.readAbyssJewelLUT(6564, nil, 11, path)
		assert.are.same({ type = 1, id = 525, rolls = { 1 } }, allAscendancies[50692][1])
		assert.are.same(expected[53884], allAscendancies[53884][1])
	end)

	it("applies the Zorath path and selected Inquisitor ascendancy example", function()
		local spec = build.spec
		spec:SelectClass(spec.tree.classNameMap.Templar)
		spec:SelectAscendClass(spec.tree.ascendNameMap.Inquisitor.ascendClassId)
		-- This is the allocated path from socket 26196 to the Templar start in the supplied example.
		for _, nodeId in ipairs({
			26196, 34171, 60472, 23027, 6712, 36949, 10031, 15064, 12536, 30693,
			58453, 41472, 61471, 26866, 44908, 35556, 39916, 20228, 61525,
		}) do
			spec.nodes[nodeId].alloc = true
			spec.allocNodes[nodeId] = spec.nodes[nodeId]
		end
		local path = spec:GetShortestPathToClassStart(26196)
		assert.is_truthy(path)
		for _, nodeId in ipairs({ 34171, 60472, 23027, 36949, 41472 }) do
			assert.is_truthy(path[nodeId], "Expected Zorath path to contain node " .. nodeId)
		end
		data.timelessJewelLUTs[11] = parseAbyssJewel(11, zorathExampleData())
		equipJewel(spec, 26196, newAbyssTimelessJewel("Reclaimed Malevolence", "Assembled Eye Jewel",
			"Binding 6564 souls to phylacteries to sustain Zorath"))

		spec:BuildAllDependsAndPaths()

		assert.are.equal("Lightning Ailment Effect", spec.nodes[34171].dn)
		assert.are.equal("19% increased Effect of Lightning Ailments", table.concat(spec.nodes[34171].sd, "\n"))
		assert.are.equal("Chaos Resistance", spec.nodes[60472].dn)
		assert.are.equal("+4% to Chaos Resistance", table.concat(spec.nodes[60472].sd, "\n"))
		assert.are.equal("Intelligence", spec.nodes[23027].dn)
		assert.are.equal("+8 to Intelligence", table.concat(spec.nodes[23027].sd, "\n"))
		assert.matches("2%% additional Physical Damage Reduction if you weren't Damaged by a Hit Recently",
			table.concat(spec.nodes[36949].sd, "\n"))
		assert.matches("12%% increased Damage over Time while Dual Wielding",
			table.concat(spec.nodes[41472].sd, "\n"))
		assert.are.equal("Spiteful Allies", spec.nodes[53884].dn)
		assert.are.equal("Minions Impale on Hit", table.concat(spec.nodes[53884].sd, "\n"))
		assert.are.equal("From Below", spec.nodes[50692].dn)
	end)

	it("can protect an allocated ascendancy notable from Zorath", function()
		local spec = build.spec
		spec:SelectClass(spec.tree.classNameMap.Templar)
		spec:SelectAscendClass(spec.tree.ascendNameMap.Inquisitor.ascendClassId)
		assert.is_true(allocatePathToNode(spec, spec.nodes[26196]))
		spec:BuildAllDependsAndPaths()
		spec.nodes[53884].alloc = true
		spec.allocNodes[53884] = spec.nodes[53884]

		data.timelessJewelLUTs[11] = parseAbyssJewel(11, zorathExampleData())
		local baseNodeName = spec.tree.nodes[53884].dn
		-- Equipped timeless jewels rename nodes on the active tree. The protection
		-- list must still show the node's original name.
		spec.nodes[53884].dn = "Spiteful Allies"
		assert.are.equal("Spiteful Allies", spec.nodes[53884].dn)

		build.timelessData.jewelType = { id = 11 }
		build.timelessData.conquerorType = { }
		build.timelessData.jewelSocket = { id = 26196 }
		build.timelessData.socketFilter = true
		build.timelessData.searchList = ""
		build.timelessData.searchListFallback = ""
		build.treeTab:FindTimelessJewel()
		local controls = main.popups[1].controls
		local _, protectLabelY = controls.protectAllocatedLabel:GetPos()
		local _, requiredAscendancyY = controls.abyssAscendancySelect:GetPos()
		assert.is_true(requiredAscendancyY + controls.abyssAscendancySelect:GetProperty("height") < protectLabelY)
		for _, option in ipairs(controls.nodeSelect.list) do
			assert.is_nil(option.id and option.id:match("^abyss_special_ascendancy_notable_"))
		end
		for index, option in ipairs(controls.abyssAscendancySelect.list) do
			if option.id == "abyss_special_ascendancy_notable_3" then
				controls.abyssAscendancySelect.selIndex = index
				controls.abyssAscendancySelect.selFunc(index, option)
				break
			end
		end
		controls.searchButton.onClick()
		assert.are.equal(0, #build.timelessData.searchResults)
		for index, option in ipairs(controls.abyssAscendancySelect.list) do
			if option.id == "abyss_special_ascendancy_notable_4" then
				controls.abyssAscendancySelect.selIndex = index
				controls.abyssAscendancySelect.selFunc(index, option)
				break
			end
		end
		assert.matches("abyss_special_ascendancy_notable_4, 1, 0, 1", build.timelessData.searchList, nil, true)

		controls.searchButton.onClick()
		assert.are.equal(1, #build.timelessData.searchResults)

		local protectedOption
		for index, option in ipairs(controls.protectAllocatedSelect.list) do
			if option.label == baseNodeName then
				controls.protectAllocatedSelect.selIndex = index
				protectedOption = option
				break
			end
		end
		assert.are.equal(baseNodeName, controls.protectAllocatedSelect:GetSelValue().label)
		local tooltip = new("Tooltip"):Tooltip()
		controls.protectAllocatedSelect.tooltipFunc(tooltip, "DROP", controls.protectAllocatedSelect.selIndex, protectedOption)
		assert.is_true(#tooltip.lines > 0)
		assert.are.same(spec.tree.nodes[53884].sd, protectedOption.descriptions)
		controls.protectAllocatedButtonAdd.onClick()
		local _, requiredAscendancyYAfterAdd = controls.abyssAscendancySelect:GetPos()
		assert.are.equal(requiredAscendancyY, requiredAscendancyYAfterAdd)
		controls.searchButton.onClick()
		assert.are.equal(0, #build.timelessData.searchResults)
	end)

	it("shows passive stat differences for an Abyss timeless jewel", function()
		local spec = build.spec
		assert.is_true(allocatePathToNode(spec, spec.nodes[61419]))
		assert.is_true(allocatePathToNode(spec, spec.nodes[15117]))
		spec:BuildAllDependsAndPaths()
		runCallback("OnFrame")

		data.timelessJewelLUTs[9] = parseAbyssJewel(9, kurgalExampleData())
		local item = newAbyssTimelessJewel("Baleful Dominion", "Hypnotic Eye Jewel",
			"Subjugating 533 souls in the thrall of Kurgal")
		local slot = equipJewel(spec, 61419, item)
		assert.is_truthy(slot)
		assert.is_nil(item.jewelRadiusIndex)
		spec:BuildAllDependsAndPaths()
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equal("Fire Resistance", spec.nodes[15117].dn)

		local tooltip = new("Tooltip"):Tooltip()
		build.itemsTab:AddItemTooltip(tooltip, item, slot)

		local hasComparison
		for _, line in ipairs(tooltip.lines) do
			if (line.text or ""):find("Removing this item", 1, true) then
				hasComparison = true
				break
			end
		end
		assert.is_true(hasComparison)
	end)

	it("applies Zorath seed 4050 to the selected Chieftain notable", function()
		local spec = build.spec
		spec:SelectClass(spec.tree.classNameMap.Marauder)
		spec:SelectAscendClass(spec.tree.ascendNameMap.Chieftain.ascendClassId)
		assert.is_true(allocatePathToNode(spec, spec.nodes[61419]))
		spec:BuildAllDependsAndPaths()

		local affectedNode = {
			id = 50692,
			modification = abyssModification({ { type = 1, id = 77, rolls = { 1 } } }),
		}
		data.timelessJewelLUTs[11] = parseAbyssJewel(11, table.concat({
			abyssHeader("ABYN", 11, 4050),
			uint16(1),
			uint16(affectedNode.id),
			affectedNode.modification,
			"ASCS", uint16(1), string.char(#"Chieftain"), "Chieftain", string.char(1), uint16(affectedNode.id),
		}))
		equipJewel(spec, 61419, newAbyssTimelessJewel("Reclaimed Malevolence", "Assembled Eye Jewel",
			"Binding 4050 souls to phylacteries to sustain Zorath"))
		spec:BuildAllDependsAndPaths()

		assert.is_truthy(data.readAbyssJewelLUT(4050, nil, 11, { }, "Chieftain")[50692])
		assert.are.equal("From Below", spec.nodes[50692].dn)
		assert.are.equal("Sione, Sun's Roar", spec.nodes[31667].dn)
	end)
end)
