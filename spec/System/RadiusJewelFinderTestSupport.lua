-- Shared fixture helpers and state checks for Radius Jewel system specs.

local support = { }

support.occVortex = LoadModule("../spec/TestBuilds/3.13/OccVortex.lua")
support.mirageArcherToxicRain = LoadModule("../spec/TestBuilds/3.13/Mirage Archer Toxic Rain.lua")
support.RadiusJewelData = LoadModule("Classes/RadiusJewelData")

support.MIGHT_OF_MEEK_RAW_TEXT = [[Might of the Meek
Crimson Jewel
Radius: Large
50% increased Effect of non-Keystone Passive Skills in Radius
Notable Passive Skills in Radius grant nothing]]

support.UNNATURAL_INSTINCT_RAW_TEXT = [[Unnatural Instinct
Viridian Jewel
Limited to: 1
Radius: Small
Allocated Small Passive Skills in Radius grant nothing
Grants all bonuses of Unallocated Small Passive Skills in Radius]]

support.ANATOMICAL_KNOWLEDGE_RAW_TEXT = [[Anatomical Knowledge
Cobalt Jewel
Source: No longer obtainable
Radius: Large
8% increased maximum Life
Adds 1 to Maximum Life per 3 Intelligence Allocated in Radius]]

function support.buildSplitPersonalityRawText(modLine)
	return table.concat({
		"Split Personality",
		"Crimson Jewel",
		"Variable",
		"This Jewel's Socket has 25% increased effect per Allocated Passive Skill between it and your Class' starting location",
		modLine,
		"Corrupted",
	}, "\n")
end

function support.buildImpossibleEscapeRawText(keystoneName)
	return table.concat({
		"Impossible Escape",
		"Viridian Jewel",
		"Limited to: 1",
		"Small",
		"Passive Skills in radius of " .. keystoneName .. " can be allocated without being connected to your tree",
		"Corrupted",
	}, "\n")
end

function support.makeFinder()
	return new("RadiusJewelFinder"):RadiusJewelFinder({ build = build })
end

local function getRadiusIndex(label)
	local radiusIndexByLabel = { }
	for i, radius in ipairs(data.jewelRadius) do
		if radius.inner == 0 and not radiusIndexByLabel[radius.label] then
			radiusIndexByLabel[radius.label] = i
		end
	end
	return radiusIndexByLabel[label]
end

function support.getLargeRadiusIndex()
	return getRadiusIndex("Large")
end

function support.getSmallRadiusIndex()
	return getRadiusIndex("Small")
end

function support.getRadiusIndexFromRawText(rawText)
	local item = new("Item"):Item("Rarity: Unique\n" .. rawText)
	return item.jewelRadiusIndex
end

function support.makeImpossibleEscapeTestVariant()
	local smallRadiusIndex = support.getSmallRadiusIndex()
	local allocNodes = build.spec.allocNodes
	for keystoneName, node in pairs(build.spec.tree.keystoneMap or { }) do
		if node and node.nodesInRadius and node.nodesInRadius[smallRadiusIndex] then
			local hasCandidate = false
			for nodeId, radiusNode in pairs(node.nodesInRadius[smallRadiusIndex]) do
				if not allocNodes[nodeId] and not radiusNode.ascendancyName
						and radiusNode.type ~= "Socket" and radiusNode.type ~= "ClassStart"
						and radiusNode.type ~= "AscendClassStart" and radiusNode.type ~= "Mastery" then
					hasCandidate = true
					break
				end
			end
			if hasCandidate then
				return {
					name = keystoneName,
					keystoneName = keystoneName,
					rawText = support.buildImpossibleEscapeRawText(keystoneName),
				}
			end
		end
	end
end

function support.makeThreadVariants()
	local names = { "Small", "Medium", "Large", "Very Large", "Massive" }
	local variants = { }
	local variantIndex = 1
	for radiusIndex, radius in ipairs(data.jewelRadius) do
		if radius.inner > 0 then
			variants[#variants + 1] = {
				name = names[variantIndex] or ("Ring " .. variantIndex),
				radiusIndex = radiusIndex,
			}
			variantIndex = variantIndex + 1
		end
	end
	return variants
end

function support.isSorted(results, key)
	for i = 2, #results do
		if results[i - 1][key] < results[i][key] then
			return false
		end
	end
	return true
end

function support.snapshotFinderState()
	local socketSelItemIds = { }
	for socketId, slot in pairs(build.itemsTab.sockets) do
		socketSelItemIds[socketId] = slot.selItemId
	end

	local itemOrderList = { }
	for i, itemId in ipairs(build.itemsTab.itemOrderList) do
		itemOrderList[i] = itemId
	end

	local itemCount = 0
	for _ in pairs(build.itemsTab.items) do
		itemCount = itemCount + 1
	end

	return {
		socketSelItemIds = socketSelItemIds,
		itemOrderList = itemOrderList,
		itemCount = itemCount,
		jewels = copyTable(build.spec.jewels, true),
	}
end

function support.assertFinderStateUnchanged(before, check)
	local after = support.snapshotFinderState()
	check.are.same(before.socketSelItemIds, after.socketSelItemIds)
	check.are.same(before.itemOrderList, after.itemOrderList)
	check.are.equal(before.itemCount, after.itemCount)
	check.are.same(before.jewels, after.jewels)
end

return support
