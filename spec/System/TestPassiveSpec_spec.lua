describe("TestPassiveSpec", function()
	before_each(function()
		newBuild()
	end)

	local function firstLoadedSocketNode(spec)
		for nodeId in pairs(spec.tree.sockets) do
			if spec.nodes[nodeId] then
				return nodeId
			end
		end
	end

	it("keeps socketed jewels when loading a build", function()
		local socketNodeId = firstLoadedSocketNode(build.spec)
		local jewel = new("Item"):Item("Rarity: RARE\nTest Spark\nCrimson Jewel\n+10 to maximum Life")
		build.itemsTab:AddItem(jewel, true)
		build.itemsTab.sockets[socketNodeId]:SetSelItemId(jewel.id)

		loadBuildFromXML(build:SaveDB("code"))

		-- Sockets are checked against the loaded items, so the items must load before the tree
		assert.are.equal(jewel.id, build.spec.jewels[socketNodeId])
	end)

	it("ignores stale jewel socket item ids when loading saved builds", function()
		local spec = new("PassiveSpec"):PassiveSpec(build, latestTreeVersion)
		local socketNodeId = firstLoadedSocketNode(spec)

		spec:Load({
			attrib = { title = "Stale Socket Test" },
			{
				elem = "Sockets",
				{
					elem = "Socket",
					attrib = {
						nodeId = tostring(socketNodeId),
						itemId = "999999",
					}
				}
			}
		}, "stale_socket.xml")

		assert.is_nil(spec.jewels[socketNodeId])
	end)
end)
