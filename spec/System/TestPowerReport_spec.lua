describe("PowerReportListControl", function()
	local PowerReportListControl

	before_each(function()
		LoadModule("Classes/PowerReportListControl")
		PowerReportListControl = common.classes.PowerReportListControl
	end)

	local function relist(originalList, showClusters, allocated)
		local control = {
			originalList = originalList,
			showClusters = showClusters or false,
			allocated = allocated or false,
		}
		PowerReportListControl.ReList(control)
		return control.list
	end

	it("Show Unallocated excludes allocated nodes", function()
		local list = relist({
			{ name = "allocated", power = 10, pathDist = 1, allocated = true },
			{ name = "unallocated", power = 5, pathDist = 1, allocated = false },
		}, false, false)

		assert.are.equal(1, #list)
		assert.are.equal("unallocated", list[1].name)
	end)

	it("Show Allocated includes allocated nodes", function()
		local list = relist({
			{ name = "allocated", power = -10, pathDist = 1, allocated = true },
			{ name = "unallocated", power = 5, pathDist = 1, allocated = false },
		}, false, true)

		assert.are.equal(1, #list)
		assert.are.equal("allocated", list[1].name)
	end)
end)

local function findPowerStat(stat)
	for _, powerStat in ipairs(data.powerStatList) do
		if powerStat.stat == stat then
			return powerStat
		end
	end
end

describe("Power report candidate context", function()
	before_each(function()
		newBuild()
	end)

	it("distinguishes identical allocated modifiers inside and outside a jewel radius", function()
		build.characterLevel = 100
		build.characterLevelAutoMode = false
		local spec = build.spec
		for _, id in ipairs({ 60735, 3469, 12412 }) do
			spec:AllocNode(assert(spec.nodes[id]))
		end
		local jewel = new("Item"):Item([[Rarity: UNIQUE
The Light of Meaning
Prismatic Jewel
Radius: Large
Implicits: 0
Passive Skills in Radius also grant +5 to maximum Life
]])
		build.itemsTab:AddItem(jewel, true)
		spec.jewels[60735] = jewel.id
		build.itemsTab.sockets[60735].selItemId = jewel.id
		build.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")

		local outside, inside = spec.nodes[3469], spec.nodes[12412]
		assert(outside.alloc and inside.alloc, "Both Dexterity nodes must be allocated")
		assert(outside.modKey == inside.modKey, "The nodes must have identical modifiers")
		local tab = build.calcsTab
		tab.powerStat = findPowerStat("Life")
		tab.nodePowerMaxDepth = 0
		tab:PowerBuilder()

		local calc, base = tab:GetMiscCalculator()
		for _, node in ipairs({ outside, inside }) do
			local output = calc({ removeNodes = { [node] = true } }, false)
			local expected = tab:CalculatePowerStat(tab.powerStat, output, base)
			assert(math.abs(expected - node.power.singleStat) < 10 ^ -9, "Removal must use this node's jewel context")
		end
		assert(outside.power.singleStat == 0, "Dexterity outside the radius must not grant Life")
		assert(inside.power.singleStat < 0, "Removing Dexterity inside the radius must lose Life")

		-- Rebuilding after removing the jewel must discard the previous radius context.
		spec.jewels[60735] = nil
		build.itemsTab.sockets[60735].selItemId = 0
		build.buildFlag = true
		runCallback("OnFrame")
		tab:PowerBuilder()
		assert.are.equal(0, outside.power.singleStat)
		assert.are.equal(0, inside.power.singleStat)
	end)

	it("does not reuse a mastery bonus for an identical cluster notable", function()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1")
		build.configTab.input.customMods = "2% more Damage for each different type of Mastery you have Allocated"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		local mastery = assert(build.spec.nodes[60210])
		assert(mastery.name == "Poison Mastery" and mastery.allMasteryOptions)
		-- Limit traversal while retaining the real mastery effects and calculator.
		mastery.pathDist = 0
		local tab = build.calcsTab
		tab.powerStat = findPowerStat("TotalDPS")
		tab.nodePowerMaxDepth = 0
		tab:PowerBuilder()

		local cluster = assert(build.spec.tree.clusterNodeMap["Low Tolerance"])
		local effect = assert(build.spec.tree.masteryEffects[34563])
		local effectNode = { id = mastery.id, type = mastery.type, name = mastery.name, sd = effect.sd }
		build.spec.tree:ProcessStats(effectNode)
		assert(effectNode.modKey == cluster.modKey, "The mastery and notable must have identical modifiers")
		assert(cluster.power.singleStat == 0, "Low Tolerance must not grant a mastery damage bonus")
		assert(mastery.power.masteryEffects[effect.id].singleStat > 0, "Allocating a new mastery type must grant the damage bonus")
	end)

	it("includes passive effect added after modifier parsing", function()
		local candidates = { }
		for _, node in pairs(build.spec.nodes) do
			if not node.alloc and node.type == "Normal" and #node.modList == 1 and node.modList[1].name == "Dex" and node.modList[1].value == 10 then
				table.insert(candidates, node)
			end
		end
		table.sort(candidates, function(a, b) return a.id < b.id end)
		local plain, scaled = candidates[1], candidates[2]
		assert(plain and scaled and plain.modKey == scaled.modKey)
		-- Cluster small-passive effect is appended after ProcessStats creates modKey.
		local modList = new("ModList"):ModList()
		modList:AddList(scaled.modList)
		scaled.modList = modList
		scaled.modList:NewMod("PassiveSkillEffect", "INC", 100)
		for _, node in ipairs({ plain, scaled }) do
			node.pathDist = 0
		end
		local tab = build.calcsTab
		tab.powerStat = findPowerStat("Dex")
		tab.nodePowerMaxDepth = 0
		tab:PowerBuilder()
		assert.are.equal(10, plain.power.singleStat)
		assert.are.equal(20, scaled.power.singleStat)
	end)
end)
