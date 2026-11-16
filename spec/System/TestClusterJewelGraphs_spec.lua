describe("Cluster jewel subgraphs", function()
	local function countSubgraphs(spec)
		local count = 0
		for _ in pairs(spec.subGraphs) do
			count = count + 1
		end
		return count
	end

	local function getOuterSocket(spec)
		for nodeId in pairs(spec.tree.sockets) do
			local node = spec.nodes[nodeId]
			if node and node.expansionJewel and node.expansionJewel.size == 2 then
				return node
			end
		end
	end

	local function addItem(raw)
		local item = new("Item"):Item(raw)
		build.itemsTab:AddItem(item, true)
		return item
	end

	local function addKeystoneCluster()
		return addItem([[Rarity: UNIQUE
One With Nothing
Small Cluster Jewel
Implicits: 0
Adds Hollow Palm Technique]])
	end

	before_each(function()
		newBuild()
	end)

	it("updates the graph when an outer socket allocation changes", function()
		local spec = build.spec
		local socket = getOuterSocket(spec)
		local jewel = addKeystoneCluster()
		spec.jewels[socket.id] = jewel.id
		spec.extended_hashes = { 123 }
		spec.jewel_data = {
			[socket.id] = {
				subgraph = {
					groups = {
						keystone = { proxy = socket.expansionJewel.proxy, nodes = { "123" } },
					},
					nodes = {
						["123"] = { group = "keystone", isKeystone = true, orbitIndex = 0 },
					},
				},
			},
		}

		spec:BuildClusterJewelGraphs()
		assert.are.equal(0, countSubgraphs(spec))

		spec:AllocNode(socket)
		assert.are.equal(1, countSubgraphs(spec))
		local _, subgraph = next(spec.subGraphs)
		assert.is_true(subgraph.nodes[1].alloc)

		spec:DeallocNode(socket)
		assert.are.equal(0, countSubgraphs(spec))
	end)

	it("only builds nested graphs for allocated cluster sockets", function()
		local spec = build.spec
		local outerSocket = getOuterSocket(spec)
		spec:AllocNode(outerSocket)

		local largeCluster = addItem([[Rarity: RARE
New Item
Large Cluster Jewel
Cluster Jewel Skill: affliction_chaos_damage
Cluster Jewel Node Count: 8
Implicits: 3
Adds 8 Passive Skills
2 Added Passive Skills are Jewel Sockets
Added Small Passive Skills grant: 12% increased Chaos Damage]])
		spec.jewels[outerSocket.id] = largeCluster.id
		spec:BuildClusterJewelGraphs()

		local nestedSocket
		for _, subgraph in pairs(spec.subGraphs) do
			for _, node in ipairs(subgraph.nodes) do
				if node.type == "Socket" then
					nestedSocket = node
					break
				end
			end
			if nestedSocket then
				break
			end
		end
		assert.is_truthy(nestedSocket)

		local nestedJewel = addKeystoneCluster()
		spec.jewels[nestedSocket.id] = nestedJewel.id
		spec:BuildClusterJewelGraphs()
		assert.are.equal(1, countSubgraphs(spec))

		nestedSocket = spec.nodes[nestedSocket.id]
		spec:AllocNode(nestedSocket)
		assert.are.equal(2, countSubgraphs(spec))

		spec:BuildClusterJewelGraphs()
		assert.are.equal(2, countSubgraphs(spec))

		nestedSocket = spec.nodes[nestedSocket.id]
		spec:DeallocNode(nestedSocket)
		assert.are.equal(1, countSubgraphs(spec))
	end)

	it("restores all cluster allocations on the first undo after loading a build", function()
		local spec = build.spec
		local outerSocket = getOuterSocket(spec)
		spec:AllocNode(outerSocket)
		spec.jewels[outerSocket.id] = addItem([[Rarity: RARE
New Item
Large Cluster Jewel
Cluster Jewel Skill: affliction_chaos_damage
Cluster Jewel Node Count: 8
Implicits: 3
Adds 8 Passive Skills
2 Added Passive Skills are Jewel Sockets
Added Small Passive Skills grant: 12% increased Chaos Damage]]).id
		spec:BuildClusterJewelGraphs()
		local _, graph = next(spec.subGraphs)
		local nestedSocketId
		for _, node in ipairs(graph.nodes) do
			if node.id then
				spec:AllocNode(spec.nodes[node.id])
				if node.type == "Socket" then
					nestedSocketId = node.id
				end
			end
		end
		spec.jewels[assert(nestedSocketId)] = addKeystoneCluster().id
		spec:BuildClusterJewelGraphs()
		for _, subgraph in pairs(spec.subGraphs) do
			for _, node in ipairs(subgraph.nodes) do
				if node.id then
					spec:AllocNode(spec.nodes[node.id])
				end
			end
		end
		runCallback("OnFrame")
		local function allocatedIds()
			local ids = { }
			for id in pairs(build.spec.allocNodes) do
				table.insert(ids, id)
			end
			table.sort(ids)
			return ids
		end
		local before = allocatedIds()
		loadBuildFromXML(build:SaveDB("code"))
		spec = build.spec
		assert.are.same(before, allocatedIds())
		assert.are.equal(2, countSubgraphs(spec))
		local leaf
		for _, node in pairs(spec.allocNodes) do
			if node.expansionSkill and node.type == "Normal" and #node.depends == 1 then
				leaf = node
				break
			end
		end
		spec:DeallocNode(assert(leaf))
		spec:AddUndoState()
		runCallback("OnFrame")
		local after = allocatedIds()
		assert.are.equal(#before - 1, #after)
		spec:Undo()
		runCallback("OnFrame")
		assert.are.same(before, allocatedIds())
		spec:Redo()
		runCallback("OnFrame")
		assert.are.same(after, allocatedIds())

		-- Removing a parent socket temporarily removes its nested cluster graph.
		spec:DeallocNode(spec.nodes[nestedSocketId])
		spec:AddUndoState()
		runCallback("OnFrame")
		local withoutNested = allocatedIds()
		assert.are.equal(1, countSubgraphs(spec))
		spec:Undo()
		runCallback("OnFrame")
		assert.are.same(after, allocatedIds())
		assert.are.equal(2, countSubgraphs(spec))
		spec:Redo()
		runCallback("OnFrame")
		assert.are.same(withoutNested, allocatedIds())
		spec:Undo()
		runCallback("OnFrame")
		assert.are.same(after, allocatedIds())
	end)

	it("does not revive deallocated cluster nodes when undoing later tree edits", function()
		local spec = build.spec
		local socket = getOuterSocket(spec)
		spec:AllocNode(socket)
		spec.jewels[socket.id] = addKeystoneCluster().id
		spec.extended_hashes = { 123 }
		spec.jewel_data = {
			[socket.id] = {
				subgraph = {
					groups = { keystone = { proxy = socket.expansionJewel.proxy, nodes = { "123" } } },
					nodes = { ["123"] = { group = "keystone", isKeystone = true, orbitIndex = 0 } },
				},
			},
		}
		spec:BuildClusterJewelGraphs()
		local _, graph = next(spec.subGraphs)
		local clusterId = graph.nodes[1].id
		spec:AllocNode(spec.nodes[clusterId])
		-- Rebuilding also occurs when loading equipped cluster jewels.
		spec:BuildClusterJewelGraphs()
		spec:ResetUndo()
		spec:DeallocNode(spec.nodes[clusterId])
		spec:AddUndoState()

		for step = 1, 20 do
			local candidates = { }
			for id, node in pairs(spec.nodes) do
				if node.type == "Normal" and not node.expansionSkill and not node.alloc and node.path and #node.path > 0 then
					table.insert(candidates, id)
				end
			end
			table.sort(candidates)
			spec:AllocNode(spec.nodes[assert(candidates[1])])
			spec:AddUndoState()
		end
		assert.is_nil(spec.allocNodes[clusterId])
		spec:Undo()
		assert.is_nil(spec.allocNodes[clusterId])
		spec:Redo()
		assert.is_nil(spec.allocNodes[clusterId])
		for step = 1, 21 do
			spec:Undo()
		end
		assert.is_truthy(spec.allocNodes[clusterId])
		spec:Redo()
		assert.is_nil(spec.allocNodes[clusterId])
	end)

end)
