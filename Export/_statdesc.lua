
loadDat("Mods")
loadDat("Stats")
loadDat("Tags")
loadDat("ItemClasses")

local nk = { }

local statDescriptor = { }
do
	local curLang
	local curDescriptor = { }
	for line in io.lines("stat_descriptions.txt") do
		local noDesc = line:match("no_description ([%w_%+%-%%]+)")
		if noDesc then
			statDescriptor[noDesc] = { }
		elseif line:match("description") then	
			curLang = { }
			curDescriptor = { lang = { ["English"] = curLang } }
		elseif not curDescriptor.stats then
			local stats = line:match("%d+ ([%w_%+%-%% ]+)")
			if stats then
				curDescriptor.stats = { }
				for stat in stats:gmatch("[%w_%+%-%%]+") do
					table.insert(curDescriptor.stats, stat)
					statDescriptor[stat] = curDescriptor
				end
			end
		else
			local langName = line:match('lang ".+"')
			if langName then
				curLang = { }
				curDescriptor.lang[langName] = curLang
			else
				local statLimits, text, special = line:match('([%d%-#| ]+) "(.-)"%s*(.*)')
				if statLimits then
					local desc = { text = text, special = { }, limit = { } }
					for statLimit in statLimits:gmatch("[%d%-#|]+") do
						local limit = { }
						if statLimit == "#" then
							limit.min = "#"
							limit.max = "#"
						elseif statLimit:match("^%d+$") then
							limit.min = tonumber(statLimit)
							limit.max = tonumber(statLimit)
						else
							limit.min, limit.max = statLimit:match("([%d%-#]+)|([%d%-#]+)")
							limit.min = tonumber(limit.min) or limit.min
							limit.max = tonumber(limit.max) or limit.max
						end
						table.insert(desc.limit, limit)
					end
					for k, v in special:gmatch("([%w%%_]+) (%w+)") do
						table.insert(desc.special, {
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
end

for k, v in pairs(nk) do
	--print("'"..k.."' = '"..v.."'")
end

local function matchLimit(lang, val) 
	for _, desc in ipairs(lang) do
		local match = true
		for i, limit in ipairs(desc.limit) do
			if (limit.max ~= "#" and val[i].min > limit.max) or (limit.min ~= "#" and val[i].min < limit.min) then
				match = false
				break
			end
		end
		if match then
			return desc
		end
	end
end

function describeMod(mod)
	local out = { }
	local stats = { }
	for i = 1, 5 do
		if mod["StatsKey"..i] then
			stats[Stats[mod["StatsKey"..i]].Id] = { min = mod["Stat"..i.."Min"], max = mod["Stat"..i.."Max"], fmt = "d" }
		end
	end
	local descriptors = { }
	for s, v in pairs(stats) do
		if (v.min ~= 0 or v.max ~= 0) and statDescriptor[s] then
			descriptors[statDescriptor[s]] = true
		end
	end
	for descriptor in pairs(descriptors) do
		local val = { }
		for i, s in ipairs(descriptor.stats) do
			val[i] = stats[s]
		end
		local desc = matchLimit(descriptor.lang["English"], val)
		if desc then
			for _, spec in ipairs(desc.special) do
				if spec.k == "negate" then
					val[spec.v].max, val[spec.v].min = -val[spec.v].min, -val[spec.v].max
				elseif spec.k == "divide_by_one_hundred" then
					val[spec.v].min = round(val[spec.v].min / 100, 1)
					val[spec.v].max = round(val[spec.v].max / 100, 1)
					val[spec.v].fmt = "g"
				elseif spec.k == "divide_by_one_hundred_2dp" then
					val[spec.v].min = round(val[spec.v].min / 100, 2)
					val[spec.v].max = round(val[spec.v].max / 100, 2)
					val[spec.v].fmt = "g"
				elseif spec.k == "per_minute_to_per_second" then
					val[spec.v].min = round(val[spec.v].min / 60, 1)
					val[spec.v].max = round(val[spec.v].max / 60, 1)
					val[spec.v].fmt = "g"
				elseif spec.k == "per_minute_to_per_second_0dp" then
					val[spec.v].min = val[spec.v].min / 60
					val[spec.v].max = val[spec.v].max / 60
				elseif spec.k == "milliseconds_to_seconds" then
					val[spec.v].min = val[spec.v].min / 1000
					val[spec.v].max = val[spec.v].max / 1000
					val[spec.v].fmt = ".2f"
				elseif spec.k == "milliseconds_to_seconds_0dp" then
					val[spec.v].min = val[spec.v].min / 1000
					val[spec.v].max = val[spec.v].max / 1000
				elseif spec.k == "deciseconds_to_seconds" then
					val[spec.v].min = val[spec.v].min / 10
					val[spec.v].max = val[spec.v].max / 10
					val[spec.v].fmt = ".2f"
				elseif spec.k == "60%_of_value" then
					val[spec.v].min = val[spec.v].min * 0.6
					val[spec.v].max = val[spec.v].max * 0.6
				elseif spec.k == "mod_value_to_item_class" then
					val[spec.v].min = ItemClasses[val[spec.v].min].Name
					val[spec.v].max = ItemClasses[val[spec.v].max].Name
					val[spec.v].fmt = "s"
				elseif spec.k == "multiplicative_damage_modifier" then
					val[spec.v].min = 100 + val[spec.v].min
					val[spec.v].max = 100 + val[spec.v].max
				end
			end
			table.insert(out, (desc.text:gsub("%%(%d)%%", function(n) 
				local v = val[tonumber(n)]
				if v.min == v.max then
					return string.format("%"..v.fmt, v.min)
				else
					return string.format("(%"..v.fmt.."-%"..v.fmt..")", v.min, v.max)
				end
			end):gsub("%%d", function() 
				local v = val[1]
				if v.min == v.max then
					return string.format("%"..v.fmt, v.min)
				else
					return string.format("(%"..v.fmt.."-%"..v.fmt..")", v.min, v.max)
				end
			end):gsub("%%(%d)$(%+?d)", function(n, fmt)
				local v = val[tonumber(n)]
				if v.min == v.max then
					return string.format("%"..fmt, v.min)
				elseif fmt == "+d" then
					if v.max < 0 then
						return string.format("-(%d-%d)", -v.min, -v.max)
					else
						return string.format("+(%d-%d)", v.min, v.max)
					end
				else
					return string.format("(%"..fmt.."-%"..fmt..")", v.min, v.max)
				end
			end):gsub("%%%%","%%")))
		end
	end
	return out
end

