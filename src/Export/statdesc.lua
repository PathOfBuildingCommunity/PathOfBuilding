local nk = { }

local statDescriptor
local statDescriptors = { }
function loadStatFile(fileName)
	if statDescriptors[fileName] then
		statDescriptor = statDescriptors[fileName]
		return
	end
	statDescriptor = { }
	statDescriptors[fileName] = statDescriptor 
	local curLang
	local curDescriptor = { }
	local order = 1
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
			statDescriptor[noDesc] = { order = 0 }
		elseif line:match("handed_description") or (line:match("description") and not line:match("_description")) then	
			local name = line:match("description ([%w_]+)")
			curLang = { }
			curDescriptor = { lang = { ["English"] = curLang }, order = order, name = name }
			order = order + 1
		elseif not curDescriptor.stats then
			local stats = line:match("%d+%s+([%w_%+%-%% ]+)")
			if stats then
				curDescriptor.stats = { }
				for stat in stats:gmatch("[%w_%+%-%%]+") do
					table.insert(curDescriptor.stats, stat)
					statDescriptor[stat] = curDescriptor
				end
			end
		else
			local langName = line:match('lang "(.+)"')
			if langName then
				curLang = { }
				curDescriptor.lang[langName] = curLang
			else
				local statLimits, text, special = line:match('([%d%-#| ]+) "(.-)"%s*(.*)')
				if statLimits then
					local desc = { text = text, limit = { } }
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
								limit[1], limit[2] = statLimit:match("([%d%-#]+)|([%d%-#]+)")
								limit[1] = tonumber(limit[1]) or limit[1]
								limit[2] = tonumber(limit[2]) or limit[2]
							end
						end
						table.insert(desc.limit, limit)
					end
					for k, v in special:gmatch("([%w%%_]+) (%w+)") do
						table.insert(desc, {
							k = k,
							v = tonumber(v) or v,
						})
						nk[k] = v
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
	print(fileName.. " loaded. ("..order.." stats)")
end

for k, v in pairs(nk) do
	print("'"..k.."' = '"..v.."'")
end

local function matchLimit(lang, val)
	for _, desc in ipairs(lang) do
		local match = true
		for i, limit in ipairs(desc.limit) do
			if (limit[2] ~= "#" and val[i].min > limit[2]) or (limit[1] ~= "#" and val[i].min < limit[1]) then
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
		local desc = matchLimit(descriptor.lang["English"], val)
		if desc then
			for _, spec in ipairs(desc) do
				if spec.k == "negate" then
					val[spec.v].max, val[spec.v].min = -val[spec.v].min, -val[spec.v].max
				elseif spec.k == "negate_and_double" then
					val[spec.v].max, val[spec.v].min = -2 * val[spec.v].min, -2 * val[spec.v].max
				elseif spec.k == "divide_by_five" then
					val[spec.v].min = round(val[spec.v].min / 5, 1)
					val[spec.v].max = round(val[spec.v].max / 5, 1)
					val[spec.v].fmt = "g"
				elseif spec.k == "divide_by_six" then
					val[spec.v].min = round(val[spec.v].min / 6, 1)
					val[spec.v].max = round(val[spec.v].max / 6, 1)
					val[spec.v].fmt = "g"
				elseif spec.k == "divide_by_ten_1dp_if_required" then
					val[spec.v].min = round(val[spec.v].min / 10, 1)
					val[spec.v].max = round(val[spec.v].max / 10, 1)
					val[spec.v].fmt = "g"
				elseif spec.k == "divide_by_twelve" then
					val[spec.v].min = round(val[spec.v].min / 12, 1)
					val[spec.v].max = round(val[spec.v].max / 12, 1)
					val[spec.v].fmt = "g"
				elseif spec.k == "divide_by_one_hundred" then
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
				elseif spec.k == "per_minute_to_per_second_2dp_if_required" or spec.k == "per_minute_to_per_second_2dp" then
					val[spec.v].min = round(val[spec.v].min / 60, 2)
					val[spec.v].max = round(val[spec.v].max / 60, 2)
					val[spec.v].fmt = "g"
				elseif spec.k == "per_minute_to_per_second_0dp" then
					val[spec.v].min = val[spec.v].min / 60
					val[spec.v].max = val[spec.v].max / 60
				elseif spec.k == "milliseconds_to_seconds" then
					val[spec.v].min = val[spec.v].min / 1000
					val[spec.v].max = val[spec.v].max / 1000
					val[spec.v].fmt = "g"
				elseif spec.k == "milliseconds_to_seconds_0dp" then
					val[spec.v].min = val[spec.v].min / 1000
					val[spec.v].max = val[spec.v].max / 1000
				elseif spec.k == "milliseconds_to_seconds_2dp_if_required" then
					val[spec.v].min = round(val[spec.v].min / 1000, 2)
					val[spec.v].max = round(val[spec.v].max / 1000, 2)
					val[spec.v].fmt = "g"	
				elseif spec.k == "deciseconds_to_seconds" then
					val[spec.v].min = val[spec.v].min / 10
					val[spec.v].max = val[spec.v].max / 10
					val[spec.v].fmt = ".2f"
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
				elseif spec.k == "reminderstring" or spec.k == "canonical_line" or spec.k == "_stat" then
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
			end):gsub("{(%d?):(%+?)d}", function(n, fmt)
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

function describeMod(mod)
	local stats = { }
	for i = 1, 6 do
		if mod["Stat"..i] then
			stats[mod["Stat"..i].Id] = { min = mod["Stat"..i.."Value"][1], max = mod["Stat"..i.."Value"][2] }
		end
	end
	if mod.Type then
		stats.Type = mod.Type
	end
	local out, orders = describeStats(stats)
	out.modTags = describeModTags(mod.ImplicitTags)
	return out, orders
end
