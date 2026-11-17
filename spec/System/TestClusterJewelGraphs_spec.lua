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

	describe("Putrid Seed", function()
		local function seedRaw(...)
			local raw = [[
				Rarity: UNIQUE
				Putrid Seed
				Mycelium Core
				Limited to: 1
			]] .. "Implicits: " .. select("#", ...) .. "\n"
			for _, name in ipairs({ ... }) do
				raw = raw .. "1 Added Passive Skill is " .. name .. " (enchant)\n"
			end
			return raw .. [[
				Grows four random Passive Skills when Anointed
				Passive Skills grown are influenced by Oils used when Anointing
			]]
		end

		-- Returns the Large Jewel Socket with the lowest id that has proxy passives, and its layout
		local function getSeedSocket(spec)
			local socketId
			for id in pairs(spec.tree.blightcoreLayouts) do
				if not socketId or id < socketId then
					socketId = id
				end
			end
			return spec.nodes[socketId], spec.tree.blightcoreLayouts[socketId]
		end

		-- Returns the layout node that grows the passive with the given enchant index
		local function getGrownNode(spec, layout, index)
			for _, node in ipairs(layout) do
				if build.data.clusterJewels.blightcoreNotableIndex[node.id] == index then
					return spec.nodes[node.id]
				end
			end
		end

		local function socketSeed(spec, socket, item)
			build.itemsTab:AddItem(item, true)
			spec.jewels[socket.id] = item.id
			build.itemsTab.sockets[socket.id].selItemId = item.id
			spec:AllocNode(socket)
			spec:BuildClusterJewelGraphs()
		end

		local function recalc()
			build.buildFlag = true
			runCallback("OnFrame")
		end

		it("parses its modifiers and can be anointed four times", function()
			local item = new("Item"):Item(seedRaw("Constitution", "Heart of Oak"))
			for _, modLine in ipairs(item.explicitModLines) do
				assert.is_nil(modLine.extra, modLine.line)
			end
			assert.is_true(item.canBeAnointed)
			assert.is_true(item.canHaveFourEnchants)
			assert.are.same({ "constitution", "heart of oak" }, item.jewelData.blightcoreNotables)
		end)

		it("only fits in Large Jewel Sockets", function()
			local item = new("Item"):Item(seedRaw())
			local itemsTab = build.itemsTab
			local socket = getSeedSocket(build.spec)
			assert.is_true(itemsTab:IsItemValidForSlot(item, "Jewel " .. socket.id))
			for nodeId, node in pairs(build.spec.tree.sockets) do
				if node.expansionJewel and node.expansionJewel.size < 2 or not node.expansionJewel and not node.charmSocket then
					assert.is_falsy(itemsTab:IsItemValidForSlot(item, "Jewel " .. nodeId), node.name)
				end
			end
		end)

		it("anoints and reads back grown passives", function()
			local itemsTab = build.itemsTab
			itemsTab:SetDisplayItem(new("Item"):Item(seedRaw()))
			local notable = build.spec.tree.notableMap["constitution"]
			itemsTab.anointEnchantSlot = 1
			local item = itemsTab:anointItem(notable)
			assert.are.equal("1 Added Passive Skill is Constitution", item.enchantModLines[1].line)
			assert.are.same({ "constitution" }, itemsTab:getAnoint(item))
			assert.are.same({ "constitution" }, item.jewelData.blightcoreNotables)
			assert.are.equal(3, itemsTab:getMissingAnointCount(item))
		end)

		it("maps Large Jewel Sockets to their proxy passives", function()
			local tree = build.spec.tree
			assert.is_truthy(next(tree.blightcoreLayouts))
			for socketId, layout in pairs(tree.blightcoreLayouts) do
				assert.are.equal(2, tree.nodes[socketId].expansionJewel.size)
				local indices = { }
				for _, node in ipairs(layout) do
					assert.is_true(node.isProxy)
					assert.are.equal(layout[1].proxyKey, node.proxyKey)
					local index = build.data.clusterJewels.blightcoreNotableIndex[node.id]
					if index then
						table.insert(indices, index)
					end
				end
				table.sort(indices)
				assert.are.same({ 1, 2, 3, 4 }, indices)
			end
		end)

		it("grows the anointed notables from an allocated socket", function()
			local spec = build.spec
			local socket, layout = getSeedSocket(spec)
			socketSeed(spec, socket, new("Item"):Item(seedRaw("Constitution", "Heart of Oak")))

			local subGraph = spec.subGraphs[socket.id]
			assert.is_truthy(subGraph)
			assert.are.equal(#layout, #subGraph.nodes)
			assert.is_truthy(subGraph.entranceNodes[1])
			for _, entrance in ipairs(subGraph.entranceNodes) do
				assert.is_truthy(isValueInArray(socket.linked, entrance))
			end

			assert.are.equal("Constitution", getGrownNode(spec, layout, 1).dn)
			assert.are.equal("Heart of Oak", getGrownNode(spec, layout, 2).dn)
			for _, treeNode in ipairs(layout) do
				local node = spec.nodes[treeNode.id]
				assert.is_true(node.isBlightcore)
				assert.is_false(node.isProxy)
				-- the tree's own proxy nodes are left untouched
				assert.are_not.equal(treeNode, node)
				assert.is_true(treeNode.isProxy)
			end
			-- passives without a matching anoint stay as they are on the tree
			local unanointed = getGrownNode(spec, layout, 3)
			assert.are.equal(spec.tree.nodes[unanointed.id].dn, unanointed.dn)
			assert.are_not.equal("Constitution", unanointed.dn)
		end)

		it("removes grown passives when the socket is deallocated", function()
			local spec = build.spec
			local socket = getSeedSocket(spec)
			socketSeed(spec, socket, new("Item"):Item(seedRaw("Constitution")))
			assert.is_truthy(spec.subGraphs[socket.id])

			spec:DeallocNode(socket)
			assert.is_nil(spec.subGraphs[socket.id])
		end)

		it("grants the stats of allocated grown notables", function()
			local spec = build.spec
			local socket, layout = getSeedSocket(spec)
			socketSeed(spec, socket, new("Item"):Item(seedRaw("Constitution")))
			recalc()
			local baseIncLife = build.calcsTab.mainEnv.modDB:Sum("INC", nil, "Life")

			local grown = getGrownNode(spec, layout, 1)
			spec:AllocNode(grown)
			recalc()
			-- the grown node survives rebuilding the tree
			assert.are.equal("Constitution", spec.nodes[grown.id].dn)
			assert.is_true(spec.nodes[grown.id].alloc)
			assert.are.equal(baseIncLife + 10, build.calcsTab.mainEnv.modDB:Sum("INC", nil, "Life"))
		end)
	end)
end)
