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

describe("Power report calculation requirements", function()
	before_each(function()
		newBuild()
	end)

	it("marks only the metrics that require eHP or Full DPS", function()
		local expectedEHPStats = {
			TotalEHP = true,
			SecondMinimalMaximumHitTaken = true,
			PhysicalTakenHit = true,
			LightningTakenHit = true,
			ColdTakenHit = true,
			FireTakenHit = true,
			ChaosTakenHit = true,
		}
		local eHPStatCount = 0
		local fullDPSStatCount = 0
		for _, powerStat in ipairs(data.powerStatList) do
			if powerStat.requiresEHP then
				eHPStatCount = eHPStatCount + 1
				assert.is_true(expectedEHPStats[powerStat.stat:gsub("^Minion", "")])
			end
			if powerStat.requiresFullDPS then
				fullDPSStatCount = fullDPSStatCount + 1
				assert.are.equal("FullDPS", powerStat.stat)
			end
		end

		assert.are.equal(14, eHPStatCount)
		assert.are.equal(1, fullDPSStatCount)
		assert.is_true(findPowerStat("MinionTotalEHP").requiresEHP)
		assert.is_nil(findPowerStat("MeleeAvoidChance").requiresEHP)
		assert.is_nil(findPowerStat("SpellAvoidChance").requiresEHP)
		assert.is_nil(findPowerStat("ProjectileAvoidChance").requiresEHP)
	end)
end)

describe("Power report calculator options", function()
	local calcs
	local originalCalcFullDPS
	local originalPerform

	before_each(function()
		newBuild()
		calcs = build.calcsTab.calcs
		originalCalcFullDPS = calcs.calcFullDPS
		originalPerform = calcs.perform
	end)

	after_each(function()
		calcs.calcFullDPS = originalCalcFullDPS
		calcs.perform = originalPerform
	end)

	local function makeCalculator()
		local state = {
			fullDPSCalls = 0,
			performSkipEHP = { },
		}
		calcs.calcFullDPS = function()
			state.fullDPSCalls = state.fullDPSCalls + 1
			return { skills = { { } }, combinedDPS = 1, TotalDotDPS = 0 }
		end
		calcs.perform = function(env, skipEHP)
			table.insert(state.performSkipEHP, skipEHP == nil and "nil" or skipEHP)
			return originalPerform(env, skipEHP)
		end

		local calcFunc = calcs.getMiscCalculator(build)
		state.fullDPSCalls = 0
		state.performSkipEHP = { }
		return calcFunc, state
	end

	it("honors explicit stage skips for each report type", function()
		build.viewMode = "TREE"
		local calcFunc, state = makeCalculator()

		calcFunc({ }, nil, { skipEHP = true, skipFullDPS = true })
		assert.are.same({ true }, state.performSkipEHP)
		assert.are.equal(0, state.fullDPSCalls)

		state.performSkipEHP = { }
		calcFunc({ }, true, { skipEHP = true, skipFullDPS = false })
		assert.are.same({ true }, state.performSkipEHP)
		assert.are.equal(1, state.fullDPSCalls)

		state.performSkipEHP = { }
		calcFunc({ }, false, { skipEHP = false, skipFullDPS = true })
		assert.are.same({ false }, state.performSkipEHP)
		assert.are.equal(1, state.fullDPSCalls)
	end)

	it("preserves legacy Tree calculations when options are omitted", function()
		build.viewMode = "TREE"
		local calcFunc, state = makeCalculator()

		calcFunc({ }, false)
		assert.are.same({ "nil" }, state.performSkipEHP)
		assert.are.equal(1, state.fullDPSCalls)
	end)

	it("preserves representative report values", function()
		build.viewMode = "TREE"
		local calcFunc, calcBase = calcs.getMiscCalculator(build)
		local testNode
		for nodeId, node in pairs(build.spec.nodes) do
			if not node.alloc and node.type ~= "Mastery" and node.modKey ~= "" and not build.calcsTab.mainEnv.grantedPassives[nodeId] then
				testNode = node
				break
			end
		end
		assert(testNode)
		local override = { addNodes = { [testNode] = true } }

		for _, stat in ipairs({ "Life", "TotalDPS", "FullDPS", "TotalEHP" }) do
			local powerStat = findPowerStat(stat)
			local useFullDPS = powerStat.requiresFullDPS or false
			local legacyOutput = calcFunc(override, useFullDPS)
			local optimizedOutput = calcFunc(override, useFullDPS, {
				skipEHP = not powerStat.requiresEHP,
				skipFullDPS = not useFullDPS,
			})
			assert.are.near(
				data.powerStatList.GetFromOutput(legacyOutput, powerStat),
				data.powerStatList.GetFromOutput(optimizedOutput, powerStat),
				10 ^ -9
			)
		end

		local legacyOutput = calcFunc(override, false)
		local optimizedOutput = calcFunc(override, false, { skipEHP = true, skipFullDPS = true })
		local legacyOffence, legacyDefence = build.calcsTab:CalculateCombinedOffDefStat(legacyOutput, calcBase)
		local optimizedOffence, optimizedDefence = build.calcsTab:CalculateCombinedOffDefStat(optimizedOutput, calcBase)
		assert.are.near(legacyOffence, optimizedOffence, 10 ^ -9)
		assert.are.near(legacyDefence, optimizedDefence, 10 ^ -9)
	end)
end)

describe("PowerBuilder calculation options", function()
	before_each(function()
		newBuild()
	end)

	it("uses one selected-metric option set for all candidate calculations", function()
		local output = {
			Life = 101,
			TotalEHP = 101,
			FullDPS = 101,
			CombinedDPS = 101,
			LifeUnreserved = 101,
			Armour = 101,
			EnergyShield = 101,
			Evasion = 101,
			LifeRegenRecovery = 101,
			EnergyShieldRegenRecovery = 101,
			Minion = { TotalEHP = 101, CombinedDPS = 101 },
		}
		local baseOutput = output

		local function runPowerBuilder(powerStat, expectedOptions)
			local callCount = 0
			build.calcsTab.powerStat = powerStat
			build.calcsTab.powerMax = nil
			build.calcsTab.nodePowerMaxDepth = 1
			build.calcsTab.miscCalculator = { function(override, useFullDPS, options)
				callCount = callCount + 1
				assert.are.same(expectedOptions, options)
				assert.are.equal(not expectedOptions.skipFullDPS, useFullDPS)
				return output
			end, baseOutput }

			build.calcsTab:PowerBuilder(true)
			assert.is_true(callCount > 0)
		end

		runPowerBuilder(findPowerStat("Life"), { skipEHP = true, skipFullDPS = true })
		runPowerBuilder(findPowerStat("FullDPS"), { skipEHP = true, skipFullDPS = false })
		runPowerBuilder(findPowerStat("TotalEHP"), { skipEHP = false, skipFullDPS = true })
		runPowerBuilder(findPowerStat("MinionTotalEHP"), { skipEHP = false, skipFullDPS = true })
		runPowerBuilder(findPowerStat("MeleeAvoidChance"), { skipEHP = true, skipFullDPS = true })
		runPowerBuilder(data.powerStatList[1], { skipEHP = true, skipFullDPS = true })
	end)
end)

describe("Power report cluster calculations", function()
	local calcsTab, originalCalculator, originalTime, originalProgress, originalComplete
	local clusterNodes, clusterCalls, hitDPS

	before_each(function()
		newBuild()
		runCallback("OnFrame")
		calcsTab = build.calcsTab
		calcsTab.nodePowerMaxDepth = 1
		originalCalculator = calcsTab.miscCalculator[1]
		originalTime = GetTime
		originalProgress = build.powerBuilderProgressCallback
		originalComplete = build.powerBuilderCallback
		clusterNodes = { }
		clusterCalls = 0
		for _, node in pairs(build.spec.tree.clusterNodeMap) do
			clusterNodes[node] = true
		end
		for _, stat in ipairs(data.powerStatList) do
			if stat.stat == "TotalDPS" then
				hitDPS = stat
				break
			end
		end
		calcsTab.miscCalculator[1] = function(mod, ...)
			for node in pairs(mod.addNodes or { }) do
				if clusterNodes[node] then
					clusterCalls = clusterCalls + 1
					break
				end
			end
			return originalCalculator(mod, ...)
		end
	end)

	after_each(function()
		calcsTab.miscCalculator[1] = originalCalculator
		_G.GetTime = originalTime
		build.powerBuilderProgressCallback = originalProgress
		build.powerBuilderCallback = originalComplete
		calcsTab.powerBuilder = nil
		calcsTab.powerBuildFlag = false
		build.treeTab.viewer.showHeatMap = false
	end)

	it("skips cluster calculations for Offence/Defence while initializing power tables", function()
		calcsTab.powerStat = data.powerStatList[1]
		calcsTab:PowerBuilder()
		assert.are.equal(0, clusterCalls)
		assert.is_not_nil(next(clusterNodes))
		for node in pairs(clusterNodes) do
			assert.same({ }, node.power)
		end
	end)

	it("clears Hit DPS cluster values in Offence/Defence and restores them on returning", function()
		calcsTab.powerStat = hitDPS
		calcsTab:PowerBuilder()
		assert.is_true(clusterCalls > 0)
		local initialCalls = clusterCalls
		local initialPowers = { }
		for node in pairs(clusterNodes) do
			initialPowers[node] = copyTable(node.power)
			if not node.alloc and node.modKey ~= "" and not calcsTab.mainEnv.grantedPassives[node.id] then
				assert.is_number(node.power.singleStat)
			end
		end

		clusterCalls = 0
		calcsTab.powerStat = data.powerStatList[1]
		calcsTab:PowerBuilder()
		assert.are.equal(0, clusterCalls)
		for node in pairs(clusterNodes) do
			assert.same({ }, node.power)
		end

		calcsTab.powerStat = hitDPS
		calcsTab:PowerBuilder()
		assert.are.equal(initialCalls, clusterCalls)
		for node in pairs(clusterNodes) do
			assert.same(initialPowers[node], node.power)
		end
	end)

	it("reports progress and completes only the replacement after a metric switch", function()
		local clock = 0
		_G.GetTime = function()
			clock = clock + 101
			return clock
		end
		-- Exercise real traversal and coroutine scheduling without repeating the stat calculations.
		calcsTab.miscCalculator[1] = function()
			return calcsTab.miscCalculator[2]
		end
		local progress = { }
		local completions = 0
		build.powerBuilderProgressCallback = function(percent)
			assert.is_true(percent >= 0 and percent <= 100)
			assert.is_true(percent >= (progress[#progress] or 0))
			table.insert(progress, percent)
		end
		build.powerBuilderCallback = function()
			completions = completions + 1
			originalComplete()
		end

		build.treeTab:SetPowerCalc(hitDPS)
		calcsTab:BuildPower()
		local abandonedBuilder = calcsTab.powerBuilder
		calcsTab:BuildPower()
		assert.is_true(#progress > 0)
		assert.are.equal(0, completions)
		build.treeTab:SetPowerCalc(data.powerStatList[1])
		assert.same({ }, build.treeTab.controls.powerReportList.originalList)
		progress = { }
		calcsTab:BuildPower()
		assert.is_not.equal(abandonedBuilder, calcsTab.powerBuilder)
		for _ = 1, 10000 do
			if not calcsTab.powerBuilder then
				break
			end
			calcsTab:BuildPower()
		end
		assert.is_nil(calcsTab.powerBuilder)
		assert.is_true(#progress > 0)
		assert.are.equal(1, completions)
		assert.same({ }, build.treeTab.controls.powerReportList.originalList)
		assert.are.equal("suspended", coroutine.status(abandonedBuilder))
		calcsTab:BuildPower()
		assert.are.equal(1, completions)
	end)

	it("applies a depth decrease to the running builder without replacing it", function()
		local clock = 0
		_G.GetTime = function() clock = clock + 101; return clock end
		calcsTab.miscCalculator[1] = function() return calcsTab.miscCalculator[2] end
		calcsTab.nodePowerMaxDepth = 10
		calcsTab.powerStat = data.powerStatList[1]
		calcsTab.powerBuildFlag = true
		calcsTab:BuildPower()
		local builder = calcsTab.powerBuilder
		calcsTab:BuildPower()
		calcsTab.nodePowerMaxDepth = 1
		for _ = 1, 10000 do
			if not calcsTab.powerBuilder then break end
			assert.are.equal(builder, calcsTab.powerBuilder)
			calcsTab:BuildPower()
		end
		assert.is_nil(calcsTab.powerBuilder)
		assert.are.equal("dead", coroutine.status(builder))
	end)

end)

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


describe("Power report relevance", function()
	before_each(function()
		newBuild()
		runCallback("OnFrame")
	end)

	it("records absent public queries and seals inherited observers", function()
		local calcs = build.calcsTab.calcs
		local observation = calcs.newQueryObserver()
		local parent = new("ModDB"):ModDB(nil, observation)
		local child = new("ModList"):ModList(parent)
		child:Sum("BASE", nil, "Absent", nil)
		child:More(nil, "MoreAbsent")
		child:Flag(nil, "FlagAbsent")
		child:Override(nil, "OverrideAbsent")
		child:List(nil, "ListAbsent")
		child:Tabulate(nil, nil, "WildcardAbsent")
		parent:HasMod("INC", nil, "HasAbsent")
		for _, name in ipairs({ "Absent", "MoreAbsent", "FlagAbsent", "OverrideAbsent", "ListAbsent", "WildcardAbsent", "HasAbsent" }) do
			assert.is_not_nil(observation.queries[name])
		end
		observation:Seal()
		child:Sum("BASE", nil, "AfterSeal")
		assert.is_nil(observation.queries.AfterSeal)
	end)

	local function assertReportParity()
		local tab = build.calcsTab
		tab.powerStat = findPowerStat("TotalDPS")
		tab.nodePowerMaxDepth = 1
		local function snapshot()
			local result = { nodes = { }, clusters = { }, maximum = copyTable(tab.powerMax) }
			for id, node in pairs(build.spec.nodes) do result.nodes[id] = copyTable(node.power) end
			for id, node in pairs(build.spec.tree.clusterNodeMap) do result.clusters[id] = copyTable(node.power) end
			return result
		end
		tab:PowerBuilder(true)
		local expected = snapshot()
		tab:PowerBuilder()
		local actual = snapshot()
		for group, values in pairs(expected) do
			for key, value in pairs(values) do
				assert.same(value, actual[group][key], group .. ":" .. tostring(key))
			end
		end
	end


	local function auditedRecording()
		local calcs = build.calcsTab.calcs
		local calc = calcs.getMiscCalculator(build)
		local observation = calcs.newQueryObserver()
		local originals, missing = { }, { }
		local observed = 0
		for _, className in ipairs({ "ModDB", "ModList" }) do
			local store = common.classes[className]
			originals[store] = { }
			for _, method in ipairs({ "Sum", "More", "Flag", "Override", "List", "Tabulate", "HasMod" }) do
				local original = store[method]
				originals[store][method] = original
				store[method] = function(self, ...)
					if self.queryObserver ~= observation then
						missing[debug.traceback(method, 2)] = true
					else
						observed = observed + 1
					end
					return original(self, ...)
				end
			end
		end
		local ok, err = pcall(calc, { }, true, { skipEHP = false, skipFullDPS = false, queryObserver = observation })
		for store, methods in pairs(originals) do
			for method, original in pairs(methods) do store[method] = original end
		end
		assert(ok, tostring(err))
		local failures = { }
		for trace in pairs(missing) do table.insert(failures, trace) end
		assert.are.equal(0, #failures, table.concat(failures, "\n"))
		assert.is_true(observed > 0)
		assert.is_true(observation.recorded)
		assert.is_not_nil(observation.queries.Dex)
		observation:Seal()
		local queries = copyTable(observation.queries)
		calc({ }, false, { skipEHP = false, skipFullDPS = false })
		assert.same(queries, observation.queries)
		return observation
	end

	it("audits every queried store during a recording and isolates the next execution", function()
		auditedRecording()
	end)

	it("observes nested minion and Full DPS calculations", function()
		build.skillsTab:PasteSocketGroup("Summon Raging Spirit 20/0  1\nMinion Damage 20/0  1")
		for _, group in ipairs(build.skillsTab.socketGroupList) do group.includeInFullDPS = true end
		build.buildFlag = true
		runCallback("OnFrame")
		assert.is_not_nil(build.calcsTab.mainOutput.Minion)
		local observation = auditedRecording()
		assert.is_not_nil(observation.queries.Damage)
		assertReportParity()
	end)

	it("disables pruning when Manaforged reuses a calculated skill", function()
		build.itemsTab:CreateDisplayItemFromRaw("Rarity: RARE\nTest Bow\nThicket Bow\nImplicits: 0")
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Frenzy 20/0  1\nManaforged Arrows 20/0  1")
		build.skillsTab:PasteSocketGroup("Rain of Arrows 20/0  1")
		runCallback("OnFrame")
		assert.is_not_nil(build.calcsTab.mainOutput.SkillTriggerRate)
		local observation = auditedRecording()
		assert.are.equal("cached calculation", observation.unsafe)
		assertReportParity()
	end)

	it("disables pruning when Reflection reuses a calculated active skill", function()
		build.itemsTab:CreateDisplayItemFromRaw("Rarity: UNIQUE\nThe Saviour\nLegion Sword\nImplicits: 0\nTriggers Level 20 Reflection when Equipped")
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Cyclone 20/0  1")
		runCallback("OnFrame")
		for index, group in ipairs(build.skillsTab.socketGroupList) do
			if group.gemList[1] and group.gemList[1].skillId == "UniqueMirageWarriors" then
				build.mainSocketGroup = index
			end
		end
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equal("UniqueMirageWarriors", build.skillsTab.socketGroupList[build.mainSocketGroup].gemList[1].skillId)
		local observation = auditedRecording()
		assert.are.equal("cached calculation", observation.unsafe)
		assertReportParity()
	end)

	it("keeps probes immutable and requires complete add-only path evidence", function()
		local calcs = build.calcsTab.calcs
		local observation = calcs.newQueryObserver()
		observation:Query("BASE", 0, 0, nil, "Life")
		observation.recorded = true
		observation:Seal()
		local relevance = calcs.newNodeRelevance(build.calcsTab.mainEnv, observation, { })
		local node = { id = -1, type = "Normal", modList = { modLib.createMod("Unused", "BASE", 1) }, grantedSkills = { "untouched" } }
		local matching = { id = -1, type = "Normal", modList = { modLib.createMod("Life", "BASE", 0) } }
		local before = copyTable(node)
		assert.is_true(relevance:CanSkip({ addNodes = { [node] = true } }))
		assert.same(before, node)
		assert.is_false(relevance:CanSkip({ addNodes = { [node] = true, [matching] = true } }))
		assert.is_false(relevance:CanSkip({ addNodes = { } }))
		assert.is_false(relevance:CanSkip({ addNodes = { [123] = true } }))
		assert.is_false(relevance:CanSkip({ addNodes = { [node] = true }, removeNodes = { } }))
		local allocation = { }
		local observedIDs = calcs.newQueryObserver()
		observedIDs:ObserveNodes(allocation)
		assert.is_nil(allocation[node.id])
		observedIDs.recorded = true
		observedIDs:Seal()
		assert.is_false(calcs.newNodeRelevance(build.calcsTab.mainEnv, observedIDs, { }):IsIrrelevant(node))
		local radiusEnv = { radiusJewelList = { { nodes = { [node.id] = node } } }, extraRadiusNodeList = { } }
		assert.is_false(calcs.newNodeRelevance(radiusEnv, observation, { }):IsIrrelevant(node))
		for _, mod in ipairs({
			modLib.createMod("ExtraSkill", "LIST", { name = "Fireball", skillId = "Fireball", level = 1 }),
			modLib.createMod("CanExplode", "FLAG", true),
		}) do
			local product = { id = -2, type = "Normal", modList = { mod } }
			assert.is_false(relevance:IsIrrelevant(product))
		end
		local countObserver = calcs.newQueryObserver()
		countObserver:Query("BASE", 0, 0, nil, "Multiplier:AllocatedNotable")
		countObserver.recorded = true
		countObserver:Seal()
		assert.is_false(calcs.newNodeRelevance(build.calcsTab.mainEnv, countObserver, { }):IsIrrelevant({ id = -3, type = "Notable", modList = { } }))
		observation.unsafe = "cached calculation"
		assert.is_false(calcs.newNodeRelevance(build.calcsTab.mainEnv, observation, { }):CanSkip({ addNodes = { [node] = true } }))
	end)

	it("preserves every node, mastery, cluster and maximum in a synchronous report", function()
		assertReportParity()
	end)
end)
