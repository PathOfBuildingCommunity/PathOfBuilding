-- Mercenary-spec fixtures. Loaded by Mercenary suites via dofile; not a busted spec.
local MercenaryTest = { }

function MercenaryTest.selectScionLuminary()
	local scionId
	for classId, class in pairs(build.spec.tree.classes) do
		if class.name == "Scion" then scionId = classId break end
	end
	build.spec:SelectClass(assert(scionId))
	local luminaryId
	for ascendClassId, ascendClass in pairs(build.spec.curClass.classes) do
		if ascendClass.name == "Luminary" then luminaryId = ascendClassId break end
	end
	build.spec:SelectAscendClass(assert(luminaryId))
end

function MercenaryTest.allocate(name)
	local node
	for _, candidate in pairs(build.spec.nodes) do
		if candidate.name == name and (not node or candidate.id < node.id) then node = candidate end
	end
	node = node or build.spec.tree.ascendancyMap[name]
	node = node or build.spec.tree.ascendancyMap[name:lower()]
	node = assert(node, name)
	node = build.spec.nodes[node.id] or node
	if node.path then
		build.spec:AllocNode(node)
	else
		node.alloc = true
		build.spec.allocNodes[node.id] = node
	end
	return node
end

function MercenaryTest.allocatePermanentHire()
	MercenaryTest.selectScionLuminary()
	MercenaryTest.allocate("Noble Blood")
end

function MercenaryTest.calculateBuild(enemyLevel)
	build.configTab.input.enemyLevel = enemyLevel or 83
	build.configTab:BuildModList()
	build.spec.modFlag = true
	build.buildFlag = true
	runCallback("OnFrame")
	runCallback("OnFrame")
	return build.calcsTab.mainEnv
end

return MercenaryTest
