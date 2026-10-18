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
end)
