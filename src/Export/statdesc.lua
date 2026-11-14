local nk = { }

local statDescriptor
local statDescriptors = { }

local function parseStatFile(target, order, fileName)
	local curLang
	local curDescriptor = { }
	local function processLine(line)
		local include = line:match('include "Metadata/StatDescriptions/(.+)"$')
		if include then
			local text = convertUTF16to8(getFile("Metadata/StatDescriptions/"..include))
			for line in text:gmatch("[^\r\n]+") do
				processLine(line)
			end
			return
		end
		local noDesc = line:match("no_description ([%w_%+%-%%]+)")
		if noDesc then
			target[noDesc] = { order = 0 }
		elseif line:match("handed_description") or (line:match("description") and not line:match("_description")) then
			local name = line:match("description ([%w_]+)")
			curLang = { }
			curDescriptor = { curLang, order = order, name = name }
			order = order + 1
		elseif not curDescriptor.stats then
			local stats = line:match("%d+%s+([%w_%+%-%% ]+)")
			if stats then
				curDescriptor.stats = { }
				for stat in stats:gmatch("[%w_%+%-%%]+") do
					table.insert(curDescriptor.stats, stat)
					target[stat] = curDescriptor
				end
			end
		else
			local langName = line:match('lang "(.+)"')
			if langName then
				curLang = { }
				--curDescriptor.lang[langName] = curLang
			elseif not line:match('table_only') then
				local statLimits, quality, text, special = line:match('([%d%-#| !]+)%s*([%w_]*)%s*"(.-)"%s*(.*)')
				if statLimits then
					local desc = { text = escapeGGGString(text), limit = { } }
					for statLimit in statLimits:gmatch("[!%d%-#|]+") do
						local limit = { }

						if statLimit == "#" then
							limit[1] = "#"
							limit[2] = "#"
						elseif statLimit:match("^%-?%d+$") then
							limit[1] = tonumber(statLimit)
							limit[2] = tonumber(statLimit)
						else
							local negate = statLimit:match("^!(-?%d+)$")
							if negate then
								limit[1] = "!"
								limit[2] = tonumber(negate)
							else
								-- 3.30 stat_descriptions has the typo "1|99#"
								limit[1], limit[2] = statLimit:gsub("(%d)#", "%1"):match("([%d%-#]+)|([%d%-#]+)")
								limit[1] = tonumber(limit[1]) or limit[1]
								limit[2] = tonumber(limit[2]) or limit[2]
							end
						end
						table.insert(desc.limit, limit)
					end
					local specialTokens = { }
					for token in special:gmatch("([%w%%_]+)") do
						table.insert(specialTokens, token)
					end
					local tokenIndex = 1
					while tokenIndex <= #specialTokens do
						local token = specialTokens[tokenIndex]
						if token == "canonical_line" then
							table.insert(desc, {
								k = "canonical_line",
								v = true,
							})
							nk["canonical_line"] = true
							tokenIndex = tokenIndex + 1
						else
							local value = specialTokens[tokenIndex + 1]
							if value then
								table.insert(desc, {
									k = token,
									v = tonumber(value) or value,
								})
								nk[token] = value
								tokenIndex = tokenIndex + 2
							else
								tokenIndex = tokenIndex + 1
							end
						end
					end
					if quality:match("gem_quality") then
						desc[quality] = true
						nk["gem_quality"] = true
					end
					table.insert(curLang, desc)
				end
			end
		end
	end
	local text = convertUTF16to8(getFile("Metadata/StatDescriptions/"..fileName))
	for line in text:gmatch("[^\r\n]+") do
		processLine(line)
	end
	return order
end

local function getNextOrder(target)
	local nextOrder = 1
	for _, descriptor in pairs(target) do
		if type(descriptor) == "table" and descriptor.order and descriptor.order >= nextOrder then
			nextOrder = descriptor.order + 1
		end
	end
	return nextOrder
end

function loadStatFile(fileName, ...)
	local args = { ... }
	if #args > 0 and type(args[1]) ~= "boolean" then
		loadStatFile(fileName)
		for _, name in ipairs(args) do
			loadStatFile(name, true)
		end
		return
	end
	local append = args[1] == true
	if append and statDescriptor then
		local base = statDescriptor
		local startOrder = getNextOrder(base)
		local newDescriptor = { }
		local finalOrder = parseStatFile(newDescriptor, startOrder, fileName)
		local cachedDescriptor = { }
		local descriptorCopies = { }
		local normalisedDescriptors = { }
		for stat, descriptor in pairs(newDescriptor) do
			if type(descriptor) == "table" and descriptor.order and descriptor.order > 0 and not normalisedDescriptors[descriptor] then
				descriptor.order = descriptor.order - startOrder + 1
				if descriptor.order < 1 then
					descriptor.order = 1
				end
				normalisedDescriptors[descriptor] = true
			end
			base[stat] = descriptor
			local copy = descriptorCopies[descriptor]
			if not copy then
				copy = copyTable(descriptor, true)
				if copy.order and copy.order > 0 then
					copy.order = copy.order - startOrder + 1
				end
				descriptorCopies[descriptor] = copy
			end
			cachedDescriptor[stat] = copy
		end
		statDescriptors[fileName] = cachedDescriptor
		print(fileName.. " loaded. ("..(finalOrder - startOrder).." stats)")
		return
	end
	if statDescriptors[fileName] then
		statDescriptor = statDescriptors[fileName]
		return
	end
	statDescriptor = { }
	statDescriptors[fileName] = statDescriptor
	local finalOrder = parseStatFile(statDescriptor, 1, fileName)
	print(fileName.. " loaded. ("..finalOrder.." stats)")
end

for k, v in pairs(nk) do
	print("'"..k.."' = '"..v.."'")
end

-- 3.30 replaced the per-value descriptions of these stats with formatter functions. The stat value is a row number in these tables
local formatterNames
function getDescriptionFormatterNames()
	if formatterNames then
		return formatterNames
	end
	local function rowNames(datName, getName)
		local names = { }
		for row in dat(datName):Rows() do
			table.insert(names, getName(row))
		end
		return names
	end
	local pearlSlots = { }
	for row in dat("ClientStrings"):Rows() do
		if row.Id:match("^PelagicPearlSlotType") then
			table.insert(pearlSlots, row.Text)
		end
	end
	formatterNames = {
		passive_jewel_radius = rowNames("PassiveJewelRadii", function(row) return row.Name.Text end),
		fishing_lure_type = rowNames("FishingLureTypes", function(row) return row.Name end),
		fishing_hook_type = rowNames("FishingHookTypes", function(row) return row.Name end),
		pelagic_pearl_slot = pearlSlots,
		shaper_apparition_ability = rowNames("ShaperApparitionAbility", function(row) return row.Name end),
		minion_doubling_type = rowNames("MinionDoublingStatTypes", function(row) return row.Name end),
		atlas_exile_citadel_index = rowNames("AtlasExiles", function(row) return row.CitadelName end),
		elder_guardian_index = rowNames("ElderGuardians", function(row) return row.Name end),
	}
	return formatterNames
end

local function matchLimit(lang, val)
	for _, desc in ipairs(lang) do
		local match = true
		for i, limit in ipairs(desc.limit) do
			if limit[1] == "!" then
				if val[i].min == limit[2] then
					match = false
					break
				end
			elseif (limit[2] ~= "#" and val[i].min > limit[2]) or (limit[1] ~= "#" and val[i].min < limit[1]) then
				match = false
				break
			end
		end
		if match then
			return desc
		end
	end
end

function describeModTags(modTags)
	if not modTags then
		return ""
	end

	local tagsDat = dat("Tags")
	local modTagsText = ""
	for i=1,#modTags do
		local curModTagIndex = modTags[i]._rowIndex
		if #modTagsText > 0 then
			modTagsText = modTagsText..', '
		end
		modTagsText = modTagsText..'"'..tagsDat:ReadCellText(curModTagIndex, 1)..'"'
	end
	return modTagsText
end

function describeStats(stats)
	local out = { }
	local orders = { }
	local descriptors = { }
	for s, v in pairs(stats) do
		if s ~= "Type" and (v.min ~= 0 or v.max ~= 0) and statDescriptor[s] and statDescriptor[s].stats then
			descriptors[statDescriptor[s]] = true
		end
	end
	local descOrdered = { }
	for descriptor in pairs(descriptors) do
		table.insert(descOrdered, descriptor)
	end
	table.sort(descOrdered, function(a, b) return a.order < b.order end)
	for _, descriptor in ipairs(descOrdered) do
		local val = { }
		for i, s in ipairs(descriptor.stats) do
			val[i] = stats[s] or { min = 0, max = 0 }
			val[i].fmt = "d"
		end
		local desc = matchLimit(descriptor[1], val)
		-- Hack to handle ranges starting or ending at 0 where no descriptor is defined for 0
		-- Attempt to adapt existing ranges
		if not desc then
			for _, s in ipairs(val) do
				if s.min == 0 and s.max > 0 then
					s.min = 1
					s.minZ = true
				elseif s.min < 0 and s.max == 0 then
					s.max = -1
					s.maxZ = true
				end
			end
			desc = matchLimit(descriptor[1], val)
			for _, s in ipairs(val) do
				if s.minZ then s.min = 0 end
				if s.maxZ then s.max = 0 end
			end
		end
		if desc then
			for _, spec in ipairs(desc) do
				if spec.k == "negate" then
					val[spec.v].max, val[spec.v].min = -val[spec.v].min, -val[spec.v].max
				elseif spec.k == "invert_chance" then
					val[spec.v].max, val[spec.v].min = 100 - val[spec.v].min, 100 - val[spec.v].max
				elseif spec.k == "negate_and_double" then
					val[spec.v].max, val[spec.v].min = -2 * val[spec.v].min, -2 * val[spec.v].max
				elseif spec.k == "passive_hash" then
					-- handled elsewhere
					if val[spec.v].min < 0 then
						val[spec.v].min = val[spec.v].min + 65536
						val[spec.v].max = val[spec.v].max + 65536
					end
				elseif spec.k == "divide_by_two_0dp" then
					val[spec.v].min = val[spec.v].min / 2
					val[spec.v].max = val[spec.v].max / 2
				elseif spec.k == "divide_by_ten_0dp" then
					val[spec.v].min = val[spec.v].min / 10
					val[spec.v].max = val[spec.v].max / 10
				elseif spec.k == "divide_by_fifteen_0dp" then
					val[spec.v].min = val[spec.v].min / 15
					val[spec.v].max = val[spec.v].max / 15
				elseif spec.k == "divide_by_four" then
					val[spec.v].min = val[spec.v].min / 4
					val[spec.v].max = val[spec.v].max / 4
					val[spec.v].fmt = "g"
				elseif spec.k == "divide_by_five" then
					val[spec.v].min = val[spec.v].min / 5
					val[spec.v].max = val[spec.v].max / 5
					val[spec.v].fmt = "g"
				elseif spec.k == "divide_by_six" then
					val[spec.v].min = val[spec.v].min / 6
					val[spec.v].max = val[spec.v].max / 6
					val[spec.v].fmt = "g"
				elseif spec.k == "divide_by_ten_1dp_if_required" or spec.k == "divide_by_ten_1dp" then
					val[spec.v].min = round(val[spec.v].min / 10, 1)
					val[spec.v].max = round(val[spec.v].max / 10, 1)
					val[spec.v].fmt = "g"
				elseif spec.k == "divide_by_twelve" then
					val[spec.v].min = val[spec.v].min / 12
					val[spec.v].max = val[spec.v].max / 12
					val[spec.v].fmt = "g"
				elseif spec.k == "divide_by_twenty" then
					val[spec.v].min = val[spec.v].min / 20
					val[spec.v].max = val[spec.v].max / 20
					val[spec.v].fmt = "g"
				elseif spec.k == "divide_by_one_hundred" then
					val[spec.v].min = val[spec.v].min / 100
					val[spec.v].max = val[spec.v].max / 100
					val[spec.v].fmt = "g"
				elseif spec.k == "divide_by_one_hundred_1dp" then
					val[spec.v].min = round(val[spec.v].min / 100, 1)
					val[spec.v].max = round(val[spec.v].max / 100, 1)
					val[spec.v].fmt = "g"
				elseif spec.k == "divide_by_one_hundred_2dp" then
					val[spec.v].min = round(val[spec.v].min / 100, 2)
					val[spec.v].max = round(val[spec.v].max / 100, 2)
					val[spec.v].fmt = "g"
				elseif spec.k == "divide_by_one_hundred_2dp_if_required" then
					val[spec.v].min = round(val[spec.v].min / 100, 2)
					val[spec.v].max = round(val[spec.v].max / 100, 2)
					val[spec.v].fmt = "g"
				elseif spec.k == "divide_by_one_thousand" then
					val[spec.v].min = round(val[spec.v].min / 1000, 1)
					val[spec.v].max = round(val[spec.v].max / 1000, 1)
					val[spec.v].fmt = "g"
				elseif spec.k == "per_minute_to_per_second" then
					val[spec.v].min = round(val[spec.v].min / 60, 1)
					val[spec.v].max = round(val[spec.v].max / 60, 1)
					val[spec.v].fmt = "g"
				elseif spec.k == "permyriad_per_minute_to_%_per_second" then
					val[spec.v].min = round(val[spec.v].min / 60 / 100, 1)
					val[spec.v].max = round(val[spec.v].max / 60 / 100, 1)
					val[spec.v].fmt = "g"
				elseif spec.k == "per_minute_to_per_second_2dp_if_required" or spec.k == "per_minute_to_per_second_2dp" then
					val[spec.v].min = round(val[spec.v].min / 60, 2)
					val[spec.v].max = round(val[spec.v].max / 60, 2)
					val[spec.v].fmt = "g"
				elseif spec.k == "per_minute_to_per_second_0dp" then
					val[spec.v].min = val[spec.v].min / 60
					val[spec.v].max = val[spec.v].max / 60
				elseif spec.k == "per_minute_to_per_second_1dp" then
					val[spec.v].min = round(val[spec.v].min / 60, 1)
					val[spec.v].max = round(val[spec.v].max / 60, 1)
					val[spec.v].fmt = "g"
				elseif spec.k == "milliseconds_to_seconds" then
					val[spec.v].min = val[spec.v].min / 1000
					val[spec.v].max = val[spec.v].max / 1000
					val[spec.v].fmt = "g"
				elseif spec.k == "milliseconds_to_seconds_0dp" then
					val[spec.v].min = val[spec.v].min / 1000
					val[spec.v].max = val[spec.v].max / 1000
				elseif spec.k == "milliseconds_to_seconds_2dp_if_required" or spec.k == "milliseconds_to_seconds_2dp" then
					val[spec.v].min = round(val[spec.v].min / 1000, 2)
					val[spec.v].max = round(val[spec.v].max / 1000, 2)
					val[spec.v].fmt = "g"
				elseif spec.k == "deciseconds_to_seconds" then
					val[spec.v].min = val[spec.v].min / 10
					val[spec.v].max = val[spec.v].max / 10
					val[spec.v].fmt = "g"
				elseif spec.k == "locations_to_metres" then
					val[spec.v].min = val[spec.v].min / 10
					val[spec.v].max = val[spec.v].max / 10
					val[spec.v].fmt = "g"
				elseif spec.k == "60%_of_value" then
					val[spec.v].min = val[spec.v].min * 0.6
					val[spec.v].max = val[spec.v].max * 0.6
				elseif spec.k == "30%_of_value" then
					val[spec.v].min = val[spec.v].min * 0.3
					val[spec.v].max = val[spec.v].max * 0.3
				elseif spec.k == "mod_value_to_item_class" then
					val[spec.v].min = ItemClasses[val[spec.v].min].Name
					val[spec.v].max = ItemClasses[val[spec.v].max].Name
					val[spec.v].fmt = "s"
				elseif getDescriptionFormatterNames()[spec.k] then
					-- Ranges describe the lowest value, as the per-value descriptions did before 3.30
					val[spec.v].min = getDescriptionFormatterNames()[spec.k][val[spec.v].min] or val[spec.v].min
					val[spec.v].max = val[spec.v].min
					val[spec.v].fmt = "s"
				elseif spec.k == "multiplicative_damage_modifier" then
					val[spec.v].min = 100 + val[spec.v].min
					val[spec.v].max = 100 + val[spec.v].max
				elseif spec.k == "multiply_by_four" then
					val[spec.v].min = val[spec.v].min * 4
					val[spec.v].max = val[spec.v].max * 4
				elseif spec.k == "times_one_point_five" then
					val[spec.v].min = val[spec.v].min * 1.5
					val[spec.v].max = val[spec.v].max * 1.5
				elseif spec.k == "times_twenty" then
					val[spec.v].min = val[spec.v].min * 20
					val[spec.v].max = val[spec.v].max * 20
				elseif spec.k == "double" then
					val[spec.v].min = val[spec.v].min * 2
					val[spec.v].max = val[spec.v].max * 2
				elseif spec.k == "plus_two_hundred" then
					val[spec.v].min = val[spec.v].min + 200
					val[spec.v].max = val[spec.v].max + 200
				elseif spec.k == "reminderstring" or spec.k == "canonical_line" or spec.k == "canonical_stat" or spec.k == "_stat" then
				elseif spec.k then
					ConPrintf("Unknown description function: %s", spec.k)
				end
			end
			local statDesc = desc.text:gsub("{(%d)}", function(n)
				local v = val[tonumber(n)+1]
				if v.min == v.max then
					return string.format("%"..v.fmt, v.min)
				else
					return string.format("(%"..v.fmt.."-%"..v.fmt..")", v.min, v.max)
				end
			end):gsub("{}", function()
				local v = val[1]
				if v.min == v.max then
					return string.format("%"..v.fmt, v.min)
				else
					return string.format("(%"..v.fmt.."-%"..v.fmt..")", v.min, v.max)
				end
			end):gsub("{(%d?):(%+?)d?}", function(n, fmt)
				-- Most forms are {0:1}, however Chain Hook enchantment is {0:}
				-- the above pattern supports both cases.
				n = n ~= "" and n or "0"
				local v = val[tonumber(n)+1]
				if v.min == v.max then
					return string.format("%"..fmt..v.fmt, v.min)
				elseif fmt == "+" then
					if v.max < 0 then
						return string.format("-(%" .. v.fmt .. "-%" .. v.fmt .. ")", -v.min, -v.max)
					else
						return string.format("+(%" .. v.fmt .. "-%" .. v.fmt .. ")", v.min, v.max)
					end
				else
					return string.format("(%"..fmt..v.fmt.."-%"..fmt..v.fmt..")", v.min, v.max)
				end
			end):gsub("%%%%","%%")
			local order = descriptor.order
			for line in (statDesc.."\\n"):gmatch("([^\\]+)\\n") do
				table.insert(out, line)
				table.insert(orders, order)
				order = order + 0.1
			end
		end
	end
	return out, orders
end

-- Maps granted effect ids to gem names and their number of levels
-- Secondary effects such as Snipe Support have their own name instead of the gem's
local grantedEffectNames, grantedEffectLevelCounts
local function getGrantedEffectData()
	if not grantedEffectNames then
		grantedEffectNames = {}
		for gem in dat("SkillGems"):Rows() do
			for _, gemEffect in ipairs(gem.GemVariants) do
				if gemEffect.GrantedEffect then
					grantedEffectNames[gemEffect.GrantedEffect.Id] = grantedEffectNames[gemEffect.GrantedEffect.Id] or gem.BaseItemType.Name
				end
				if gemEffect.GrantedEffect2 then
					local name = gemEffect.SecondarySupportName
					if name == "" then
						name = gem.BaseItemType.Name
					end
					grantedEffectNames[gemEffect.GrantedEffect2.Id] = grantedEffectNames[gemEffect.GrantedEffect2.Id] or name
				end
			end
		end
		grantedEffectLevelCounts = {}
		for levelRow in dat("GrantedEffectsPerLevel"):Rows() do
			local id = levelRow.GrantedEffect.Id
			grantedEffectLevelCounts[id] = (grantedEffectLevelCounts[id] or 0) + 1
		end
	end
	return grantedEffectNames, grantedEffectLevelCounts
end

-- 3.30 moved the gem and level of most "Supported by" and "Grants" mods from their display stats, which are now 0, into a GrantedEffect column on the mod row
-- The display stat may still hold a level when describing legacy values
local function describeGrantedEffects(mod, stats)
	local hasDisplayStat, level
	-- Only handle display stats that GGG zeroed. If a legacy value is given for one that still has a description, describeStats handles it
	for i = 1, 6 do
		local stat = mod["Stat" .. i]
		if stat and stat.Id:match("^local_display_") and mod["Stat" .. i .. "Value"][1] == 0 and mod["Stat" .. i .. "Value"][2] == 0 then
			local value = stats[stat.Id]
			if value and (value.min ~= 0 or value.max ~= 0) then
				if statDescriptor[stat.Id] then
					return
				end
				level = value
			end
			hasDisplayStat = true
		end
	end
	if not hasDisplayStat then
		return
	end
	local names, levelCounts = getGrantedEffectData()
	local out, orders, seen = {}, {}, {}
	for _, levelRow in ipairs(mod.GrantedEffect) do
		local grantedEffect = levelRow.GrantedEffect
		-- Supports are named after their gem and actives after their skill. The stat order of a remaining descriptor of the same kind is borrowed
		local name, template, orderStat
		if grantedEffect.IsSupport then
			name, template, orderStat = names[grantedEffect.Id], "ModGrantsSupportEffect", "local_random_support_gem_level"
		else
			name, template, orderStat = grantedEffect.ActiveSkill?.DisplayName, "ModGrantsEffect", "local_display_grants_skill_frostbite_level"
		end
		if not name or name == "" then
			print("Granted effect '" .. grantedEffect.Id .. "' of mod '" .. mod.Id .. "' has no name")
		elseif not seen[name] then
			seen[name] = true
			local levelText
			if level then
				levelText = tostring(level.min)
				if level.min ~= level.max then
					levelText = "(" .. level.min .. "-" .. level.max .. ")"
				end
			-- Single level effects such as Harbinger skills are shown without a level
			elseif levelCounts[grantedEffect.Id] > 1 then
				levelText = tostring(levelRow.Level)
			end
			if levelText then
				template = template .. "WithLevel"
			end
			-- The same templates the client uses, e.g. "Socketed Gems are Supported by Level {1} {0}"
			local text = dat("ClientStrings"):GetRow("Id", template).Text:gsub("{0}", name):gsub("{1}", levelText or "")
			table.insert(out, text)
			table.insert(orders, statDescriptor[orderStat].order)
		end
	end
	return out, orders
end

-- describeStats with the granted effect lines of the mod inserted by stat order
function describeModStats(mod, stats)
	local grantedOut, grantedOrders = describeGrantedEffects(mod, stats)
	local out, orders = describeStats(stats)
	for i, line in ipairs(grantedOut or {}) do
		local index = #orders + 1
		for j, order in ipairs(orders) do
			if order > grantedOrders[i] then
				index = j
				break
			end
		end
		table.insert(out, index, line)
		table.insert(orders, index, grantedOrders[i])
	end
	return out, orders
end
function describeMod(mod)
	local stats = { }
	local buffTemplateStats = { }
	for _, buffTemplateKey in ipairs({ "BuffTemplate1", "BuffTemplate2" }) do
		local buffTemplate = mod[buffTemplateKey]
		if buffTemplate and buffTemplate.Stats then
			for _, stat in ipairs(buffTemplate.Stats) do
				if stat and stat.Id then
					buffTemplateStats[stat.Id] = true
				end
			end
		end
	end
	for i = 1, 6 do
		if mod["Stat"..i] and not buffTemplateStats[mod["Stat"..i].Id] then
			stats[mod["Stat"..i].Id] = { min = mod["Stat"..i.."Value"][1], max = mod["Stat"..i.."Value"][2] }
		end
	end
	if mod.Type then
		stats.Type = mod.Type
	end
	local out, orders = describeModStats(mod, stats)
	out.modTags = describeModTags(mod.ImplicitTags)
	return out, orders
end

function getStatDescriptors(fileName)
	if not statDescriptors[fileName] then
		loadStatFile(fileName)
	end
	return statDescriptors[fileName]
end
function describeScalability(fileName)
	local out = {}
	local stats = dat("stats")
	for stat, statDescription in pairsSortByKey(statDescriptors[fileName]) do
		local scalability = {}
		if statDescription.stats then
			for i, stat in ipairs(statDescription.stats) do
				-- assume unscalable for invalid reference where ID doesn't exist
				table.insert(scalability, stats:GetRow("Id", stat)?.IsScalable or false)
			end
			for _, wordings in ipairs(statDescription[1]) do
				local wordingFormats = {}
				local inOrderScalability = {}
				for _, format in ipairs(wordings) do
					if type(format.v) == "number" then
						if wordingFormats[tonumber(format.v)] then
							table.insert(wordingFormats[tonumber(format.v)], format.k)
						else
							wordingFormats[tonumber(format.v)] = { format.k }
						end
					end
				end
				local strippedLine = wordings.text:gsub("[%+%-]?(%b{})", function(num)
					local statNum = (num:match("%d") or 0) + 1
					table.insert(inOrderScalability,
						{ isScalable = scalability[statNum], formats = wordingFormats[statNum] })
					return "#"
				end)
				if not strippedLine:match("^DNT") then
					if out[strippedLine] then -- we want to use the format with the least oddities in it. If their are less formats then that will be used instead.
						for j, priorScalability in ipairs(out[strippedLine]) do
							if (priorScalability.formats and #priorScalability.formats or 0) > (wordingFormats[j] and #wordingFormats[j] or 0) then
								out[strippedLine][j] = inOrderScalability[j]
							end
						end
					else -- no present
						out[strippedLine] = inOrderScalability
					end
				end
			end
		end
	end
	return out
end
