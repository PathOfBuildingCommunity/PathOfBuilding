-- Data and variant tests for RadiusJewelData.

local support = LoadModule("../spec/System/RadiusJewelFinderTestSupport.lua")
local occVortex = support.occVortex
local RadiusJewelData = support.RadiusJewelData
local makeFinder = support.makeFinder
local getSmallRadiusIndex = support.getSmallRadiusIndex
local getRadiusIndexFromRawText = support.getRadiusIndexFromRawText

describe("RadiusJewelData #radius-jewel", function()

	before_each(function()
		loadBuildFromXML(occVortex.xml, "OccVortex")
	end)

	-- ── buildVariantsFromUniqueItem ──────────────────────────────────────────

	describe("buildVariantsFromUniqueItem", function()

		it("builds Light of Meaning variants with valid name and rawText", function()
			local variants = RadiusJewelData.buildVariantsFromUniqueItem("The Light of Meaning")
			assert.is_true(#variants > 0, "expected at least one Light of Meaning variant")
			for _, v in ipairs(variants) do
				assert.is_string(v.name)
				assert.is_string(v.rawText)
				assert.is_true(#v.name > 0, "variant name should not be empty")
				assert.is_true(#v.rawText > 0, "variant rawText should not be empty")
				assert.are.equal(getRadiusIndexFromRawText(v.rawText), v.radiusIndex,
					"variant radiusIndex should come from raw unique text: " .. v.name)
			end
		end)

		it("builds Split Personality variants with unique names", function()
			local variants = RadiusJewelData.buildVariantsFromUniqueItem("Split Personality")
			assert.is_true(#variants > 0, "expected at least one Split Personality variant")
			local seenNames = {}
			for _, v in ipairs(variants) do
				assert.is_string(v.name)
				assert.is_string(v.rawText)
				assert.is_nil(seenNames[v.name], "duplicate variant name: " .. v.name)
				seenNames[v.name] = true
			end
		end)

		it("variant rawText contains Selected Variant header", function()
			local variants = RadiusJewelData.buildVariantsFromUniqueItem("The Light of Meaning")
			for _, v in ipairs(variants) do
				assert.is_not_nil(v.rawText:match("Selected Variant: %d+"), "rawText should contain Selected Variant: " .. v.name)
			end
		end)

	end)

	-- ── buildJewelTypes ──────────────────────────────────────────────────────

	describe("buildJewelTypes", function()

		it("assigns canonical identities to grouped variants and Thread rings", function()
			local jewelTypes = RadiusJewelData.buildJewelTypes()
			local function findJewelType(name)
				for _, jewelType in ipairs(jewelTypes) do
					if jewelType.name == name then
						return jewelType
					end
				end
			end
			local function findVariant(jewelType, name)
				for _, variant in ipairs(jewelType.variants or { }) do
					if variant.name == name then
						return variant
					end
				end
			end

			for _, expected in ipairs({
				{ family = "Dreams & Nightmares", variant = "The Red Nightmare", uniqueName = "The Red Nightmare", limit = 1 },
				{ family = "Stat Conversion", variant = "Healthy Mind", uniqueName = "Healthy Mind", limit = 1 },
				{ family = "Tempered & Transcendent", variant = "Tempered Flesh", uniqueName = "Tempered Flesh" },
			}) do
				local variant = findVariant(findJewelType(expected.family), expected.variant)
				assert.is_not_nil(variant, "missing grouped variant " .. expected.variant)
				assert.are.equal(expected.family, variant.variantIdentity.family)
				assert.are.equal(expected.uniqueName, variant.variantIdentity.uniqueName)
				assert.are.equal(expected.uniqueName, variant.variantIdentity.limitKey)
				assert.are.equal(expected.limit, variant.variantIdentity.limit)
				assert.are.equal(variant.rawText, variant.variantIdentity.rawText)
				assert.are.equal(variant.radiusIndex, variant.variantIdentity.radiusIndex)
			end

			local threadVariants = RadiusJewelData.getThreadOfHopeVariants()
			assert.is_true(#threadVariants > 0, "expected Thread of Hope ring variants")
			for _, variant in ipairs(threadVariants) do
				assert.are.equal("Thread of Hope", variant.variantIdentity.family)
				assert.are.equal("Thread of Hope", variant.variantIdentity.uniqueName)
				assert.are.equal("Thread of Hope", variant.variantIdentity.limitKey)
				assert.are.equal(variant.rawText, variant.variantIdentity.rawText)
				assert.are.equal(getRadiusIndexFromRawText(variant.rawText), variant.radiusIndex)
			end
		end)

		it("keeps raw-backed radius indexes aligned with item data", function()
			local jewelTypes = RadiusJewelData.buildJewelTypes()
			local checkedTypes = 0
			local checkedVariants = 0

			for _, jewelType in ipairs(jewelTypes) do
				if jewelType.rawText then
					local radiusIndex = getRadiusIndexFromRawText(jewelType.rawText)
					if radiusIndex then
						assert.are.equal(radiusIndex, jewelType.radiusIndex,
							"jewel type radiusIndex should match raw unique text: " .. jewelType.name)
						checkedTypes = checkedTypes + 1
					end
				end
				for _, variant in ipairs(jewelType.variants or { }) do
					if variant.rawText then
						local radiusIndex = getRadiusIndexFromRawText(variant.rawText)
						if radiusIndex then
							assert.are.equal(radiusIndex, variant.radiusIndex,
								"variant radiusIndex should match raw unique text: "
								.. (variant.dropdownLabel or variant.name))
							checkedVariants = checkedVariants + 1
						end
					end
				end
			end

			assert.is_true(checkedTypes > 0, "expected at least one raw-backed jewel type")
			assert.is_true(checkedVariants > 0, "expected at least one raw-backed jewel variant")
		end)

		it("keeps Foulborn Dream and Nightmare variants in their jewel family", function()
			local jewelTypes = RadiusJewelData.buildJewelTypes()
			local dreamsAndNightmares
			for _, jewelType in ipairs(jewelTypes) do
				if jewelType.name == "Dreams & Nightmares" then
					dreamsAndNightmares = jewelType
					break
				end
			end
			assert.is_not_nil(dreamsAndNightmares)

			local expectedFamilies = {
				"The Red Dream", "The Red Nightmare", "The Green Dream",
				"The Green Nightmare", "The Blue Dream", "The Blue Nightmare",
			}
			for _, family in ipairs(expectedFamilies) do
				local familyVariants = { }
				for _, variant in ipairs(dreamsAndNightmares.variants) do
					if variant.variantGroup == family then
						familyVariants[#familyVariants + 1] = variant
					end
				end
				assert.are.equal(4, #familyVariants, "expected normal plus three Foulborn subsets for " .. family)
				local foulbornCount = 0
				for _, variant in ipairs(familyVariants) do
					if variant.isFoulborn then
						foulbornCount = foulbornCount + 1
						local item = new("Item"):Item("Rarity: Unique\n" .. variant.rawText)
						assert.is_true(item.foulborn, "expected Foulborn item data for " .. variant.name)
					end
				end
				assert.are.equal(3, foulbornCount, "expected three Foulborn subsets for " .. family)
			end
		end)

	end)

	-- ── Foulborn radius-jewel variants ───────────────────────────────────────

	describe("buildFoulbornVariants", function()

		local function countEntries(tbl)
			local count = 0
			for _ in pairs(tbl) do
				count = count + 1
			end
			return count
		end

		local function hasMutation(variant, modId)
			for _, newModId in ipairs(variant.newModIds) do
				if newModId == modId then
					return true
				end
			end
			return false
		end

		local function hasMutatedMod(item, modId)
			for _, modLine in ipairs(item.explicitModLines) do
				if modLine.modId == modId and modLine.mutated then
					return true
				end
			end
			return false
		end

		it("uses the current Foulborn map instead of generated unique data", function()
			local map = data.foulbornMap
			assert.are.equal(1, countEntries(map["Might of the Meek"]))
			assert.are.equal(2, countEntries(map["Unnatural Instinct"]))
			assert.are.equal(1, countEntries(map["Inspired Learning"]))
			assert.are.equal(1, countEntries(map["Lioneye's Fall"]))
			assert.are.equal(1, countEntries(map["Intuitive Leap"]))
			assert.are.equal(
				"MutatedUniqueJewel3GainRandomRareMonsterModOnKillWhileXSmallPassivesAllocatedInRadius",
				map["Inspired Learning"]["StealRareModUniqueJewel3"])
			assert.are.equal(
				"MutatedUniqueJewel125AllocatedNotablePassiveSkillsInRadiusDoNothing",
				map["Unnatural Instinct"]["AllocatedNonNotablesGrantNothingUnique__1_"])
			assert.are.equal(
				"MutatedUniqueJewel125GrantsAllBonusesOfUnallocatedNotablesInRadius",
				map["Unnatural Instinct"]["GrantsStatsFromNonNotablesInRadiusUnique__1"])
			assert.are.equal(
				"MutatedUniqueJewel6KeystoneCanBeAllocatedInMassiveRadiusWithoutBeingConnected",
				map["Intuitive Leap"]["JewelUniqueAllocateDisconnectedPassives"])
		end)

		it("accepts an injected map fixture and round-trips the mutation", function()
			local originalModId, newModId = next(data.foulbornMap["Unnatural Instinct"])
			local variants = RadiusJewelData.buildFoulbornVariants("Unnatural Instinct", nil, {
				["Unnatural Instinct"] = { [originalModId] = newModId },
			})
			assert.are.equal(1, #variants)
			assert.are.same({ newModId }, variants[1].newModIds)

			local imported = new("Item"):Item("Rarity: Unique\n" .. variants[1].rawText)
			assert.is_true(imported.foulborn)
			assert.is_true(hasMutatedMod(imported, newModId))
		end)

		it("returns no variants when a unique has no Foulborn mapping", function()
			assert.are.equal(0, #RadiusJewelData.buildFoulbornVariants("Anatomical Knowledge"))
		end)

		it("builds every non-empty Unnatural Instinct mutation subset", function()
			local variants = RadiusJewelData.buildFoulbornVariants("Unnatural Instinct")
			assert.are.equal(3, #variants)

			for _, variant in ipairs(variants) do
				assert.is_true(variant.isFoulborn)
				assert.is_true(#variant.newModIds >= 1)
				assert.is_true(#variant.newModIds <= 2)
				assert.is_string(variant.name)
				assert.is_string(variant.rawText)

				local imported = new("Item"):Item("Rarity: Unique\n" .. variant.rawText)
				assert.is_true(imported.foulborn)
				for _, newModId in ipairs(variant.newModIds) do
					assert.is_true(hasMutatedMod(imported, newModId))
				end
			end
		end)

		it("scores each Unnatural Instinct Foulborn combination from its mutations", function()
			local gainNotable = "MutatedUniqueJewel125GrantsAllBonusesOfUnallocatedNotablesInRadius"
			local loseNotable = "MutatedUniqueJewel125AllocatedNotablePassiveSkillsInRadiusDoNothing"
			local nodes = {
				allocatedNormalA = { type = "Normal" },
				allocatedNormalB = { type = "Normal" },
				allocatedNotableA = { type = "Notable" },
				allocatedNotableB = { type = "Notable" },
				allocatedNotableC = { type = "Notable" },
				allocatedNotableD = { type = "Notable" },
				unallocatedNormalA = { type = "Normal" },
				unallocatedNormalB = { type = "Normal" },
				unallocatedNormalC = { type = "Normal" },
				unallocatedNotableA = { type = "Notable" },
				unallocatedNotableB = { type = "Notable" },
				unallocatedNotableC = { type = "Notable" },
				unallocatedNotableD = { type = "Notable" },
				unallocatedNotableE = { type = "Notable" },
			}
			local allocNodes = {
				allocatedNormalA = true,
				allocatedNormalB = true,
				allocatedNotableA = true,
				allocatedNotableB = true,
				allocatedNotableC = true,
				allocatedNotableD = true,
			}

			for _, variant in ipairs(RadiusJewelData.buildFoulbornVariants("Unnatural Instinct")) do
				local expectedScore
				if hasMutation(variant, gainNotable) and hasMutation(variant, loseNotable) then
					expectedScore = 1 -- 5 unallocated notables - 4 allocated notables
				elseif hasMutation(variant, gainNotable) then
					expectedScore = 3 -- 5 unallocated notables - 2 allocated small passives
				else
					expectedScore = -1 -- 3 unallocated small passives - 4 allocated notables
				end
				assert.are.equal(expectedScore, variant.score(nodes, allocNodes))
			end
		end)

		it("uses the mapped Inspired Learning mutation and excludes Foulborn Might of the Meek", function()
			local inspired = RadiusJewelData.buildFoulbornVariants("Inspired Learning")
			assert.are.equal(1, #inspired)
			assert.are.equal("alloc small passives", inspired[1].scoreLabel)
			assert.are.equal(2, inspired[1].score({
				allocatedNormalA = { type = "Normal" },
				allocatedNormalB = { type = "Normal" },
				unallocatedNotable = { type = "Notable" },
			}, {
				allocatedNormalA = true,
				allocatedNormalB = true,
			}))

			assert.is_not_nil(data.foulbornMap["Might of the Meek"])
			assert.are.equal(0, #RadiusJewelData.buildFoulbornVariants("Might of the Meek"))
		end)

		it("marks Foulborn Intuitive Leap as Massive Radius keystone-only in preview and compute", function()
			local previousJewelRadius = data.jewelRadius
			local previousMaxJewelRadius = data.maxJewelRadius
			data.setJewelRadiiGlobally("3_29")
			local variants = RadiusJewelData.buildFoulbornVariants("Intuitive Leap")
			assert.are.equal(1, #variants)
			local variant = variants[1]
			assert.is_true(variant.isMassiveRadius)
			assert.is_true(variant.keystoneOnly)
			assert.are.same({ "Massive Radius", "Keystone Passive Skills only" }, variant.previewMeta)

			local preview = RadiusJewelData.jewelPreviewFn["Intuitive Leap"](variant)
			local previewText = { }
			for _, line in ipairs(preview) do
				if line[1] then
					previewText[#previewText + 1] = line[1]
				end
			end
			assert.is_true(table.concat(previewText, "\n"):find("Massive Radius", 1, true) ~= nil)
			assert.is_true(table.concat(previewText, "\n"):find("Keystone Passive Skills only", 1, true) ~= nil)

			local finder = makeFinder()
			local capturedOptions
			local originalCollect = finder.compute.collectDisconnectedPassiveCandidates
			function finder.compute:collectDisconnectedPassiveCandidates(socketNode, options)
				capturedOptions = options
				return { }
			end
			local sockets = finder:buildJewelSockets(getSmallRadiusIndex())
			finder.compute:computeIntuitiveLeapSocketImpact({
				sockets = { sockets[1] },
				impactStat = "Life",
				variant = variant,
				methodId = "fast",
				planCache = { },
				occupiedMode = { id = "all" },
			})
			finder.compute.collectDisconnectedPassiveCandidates = originalCollect

			assert.is_not_nil(capturedOptions)
			assert.is_true(capturedOptions.keystoneOnly)

			local massiveRadiusIndex = RadiusJewelData.getJewelRadiusIndex("Massive")
			assert.is_not_nil(massiveRadiusIndex, "expected canonical Massive radius data")
			assert.are.equal(2880, data.jewelRadius[massiveRadiusIndex].outer)
			assert.are.equal(massiveRadiusIndex, variant.radiusIndex)
			assert.are.equal(massiveRadiusIndex, capturedOptions.radiusIndex)
			assert.is_nil(capturedOptions.collectNodes)
			local massiveKeystone = { id = "foulbornMassiveKeystone", type = "Keystone" }
			local syntheticSocket = {
				nodesInRadius = {
					[getSmallRadiusIndex()] = { normalPassive = { id = "normalPassive", type = "Normal" } },
					[massiveRadiusIndex] = { foulbornMassiveKeystone = massiveKeystone },
				},
			}
			local candidates = finder.compute:collectDisconnectedPassiveCandidates(syntheticSocket, capturedOptions)
			assert.are.same({ massiveKeystone }, candidates)
			data.jewelRadius = previousJewelRadius
			data.maxJewelRadius = previousMaxJewelRadius
		end)

		it("compares Intuitive Leap normal and Foulborn variants while retaining the winner", function()
			local intuitiveVariants
			for _, jewelType in ipairs(RadiusJewelData.buildJewelTypes()) do
				if jewelType.name == "Intuitive Leap" then
					intuitiveVariants = jewelType.variants
					break
				end
			end
			assert.are.equal(2, #intuitiveVariants)

			local finder = makeFinder()
			local computedVariants = { }
			function finder.compute:computeIntuitiveLeapSocketImpact(request)
				computedVariants[#computedVariants + 1] = request.variant
				return {
					{
						socket = request.sockets[1],
						delta = request.variant.isFoulborn and 2 or 1,
						addedNodeCount = 0,
					},
				}, 100
			end
			local results, baseline = finder.compute:computeBestIntuitiveLeapSocketImpact({
				sockets = { { id = "testSocket" } },
				impactStat = "Life",
				variants = intuitiveVariants,
				methodId = "fast",
				planCache = { },
			})
			assert.are.equal(2, #computedVariants)
			assert.are.equal(100, baseline)
			assert.are.equal(1, #results)
			assert.is_true(results[1].variant.isFoulborn)
			assert.is_true(results[1].variant.rawText:find("{mutated}", 1, true) ~= nil)
		end)

	end)

end)
