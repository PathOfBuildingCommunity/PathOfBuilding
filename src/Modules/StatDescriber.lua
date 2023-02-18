-- Path of Building
--
-- Module: Stat Describer
-- Manages stat description files, and provides stat descriptions
--
local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local s_format = string.format

local scopes = { }

local function getScope(scopeName)
	if not scopes[scopeName] then
		local scope = LoadModule("Data/StatDescriptions/"..scopeName)
		scope.name = scopeName
		if scope.parent then
			local parentScope = getScope(scope.parent)
			scope.scopeList = copyTable(parentScope.scopeList, true)
		else
			scope.scopeList = { }
		end
		t_insert(scope.scopeList, 1, scope)
		scopes[scopeName] = scope
		return scope
	else
		return scopes[scopeName]
	end
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

local function applySpecial(val, spec)
	if spec.k == "negate" then
		val[spec.v].max, val[spec.v].min = -val[spec.v].min, -val[spec.v].max
	elseif spec.k == "negate_and_double" then
		val[spec.v].max, val[spec.v].min = -2 * val[spec.v].min, -2 * val[spec.v].max
	elseif spec.k == "divide_by_two_0dp" then
		val[spec.v].min = val[spec.v].min / 2
		val[spec.v].max = val[spec.v].max / 2
	elseif spec.k == "divide_by_ten_0dp" then
		val[spec.v].min = val[spec.v].min / 10
		val[spec.v].max = val[spec.v].max / 10
	elseif spec.k == "divide_by_fifteen_0dp" then
		val[spec.v].min = val[spec.v].min / 15
		val[spec.v].max = val[spec.v].max / 15
	elseif spec.k == "divide_by_five" then
		val[spec.v].min = val[spec.v].min / 5
		val[spec.v].max = val[spec.v].max / 5
		val[spec.v].fmt = "g"
	elseif spec.k == "divide_by_six" then
		val[spec.v].min = val[spec.v].min / 6
		val[spec.v].max = val[spec.v].max / 6
		val[spec.v].fmt = "g"
	elseif spec.k == "divide_by_ten_1dp_if_required" then
		val[spec.v].min = round(val[spec.v].min / 10, 1)
		val[spec.v].max = round(val[spec.v].max / 10, 1)
		val[spec.v].fmt = "g"
	elseif spec.k == "divide_by_twelve" then
		val[spec.v].min = val[spec.v].min / 12
		val[spec.v].max = val[spec.v].max / 12
		val[spec.v].fmt = "g"
	elseif spec.k == "divide_by_one_hundred" then
		val[spec.v].min = val[spec.v].min / 100
		val[spec.v].max = val[spec.v].max / 100
		val[spec.v].fmt = "g"
	elseif spec.k == "divide_by_one_hundred_2dp_if_required" or spec.k == "divide_by_one_hundred_2dp" then
		val[spec.v].min = round(val[spec.v].min / 100, 2)
		val[spec.v].max = round(val[spec.v].max / 100, 2)
		val[spec.v].fmt = "g"
	elseif spec.k == "divide_by_one_hundred_and_negate" then
		val[spec.v].min = -round(val[spec.v].min / 100, 1)
		val[spec.v].max = -round(val[spec.v].max / 100, 1)
		val[spec.v].fmt = "g"
	elseif spec.k == "divide_by_twenty_then_double_0dp" then -- O_O
		val[spec.v].min = round(val[spec.v].min / 20) * 2
		val[spec.v].max = round(val[spec.v].max / 20) * 2
	elseif spec.k == "divide_by_one_thousand" then
		val[spec.v].min = val[spec.v].min / 1000
		val[spec.v].max = val[spec.v].max / 1000
		val[spec.v].fmt = "g"
	elseif spec.k == "per_minute_to_per_second" then
		val[spec.v].min = round(val[spec.v].min / 60, 1)
		val[spec.v].max = round(val[spec.v].max / 60, 1)
		val[spec.v].fmt = "g"
	elseif spec.k == "per_minute_to_per_second_0dp" then
		val[spec.v].min = val[spec.v].min / 60
		val[spec.v].max = val[spec.v].max / 60
	elseif spec.k == "per_minute_to_per_second_1dp" then
		val[spec.v].min = round(val[spec.v].min / 60, 1)
		val[spec.v].max = round(val[spec.v].max / 60, 1)
		val[spec.v].fmt = "g"
	elseif spec.k == "per_minute_to_per_second_2dp" then
		val[spec.v].min = round(val[spec.v].min / 60, 2)
		val[spec.v].max = round(val[spec.v].max / 60, 2)
		val[spec.v].fmt = "g"
	elseif spec.k == "per_minute_to_per_second_2dp_if_required" then
		val[spec.v].min = round(val[spec.v].min / 60, 2)
		val[spec.v].max = round(val[spec.v].max / 60, 2)
		val[spec.v].fmt = "g"
	elseif spec.k == "milliseconds_to_seconds" then
		val[spec.v].min = val[spec.v].min / 1000
		val[spec.v].max = val[spec.v].max / 1000
		val[spec.v].fmt = "g"
	elseif spec.k == "milliseconds_to_seconds_0dp" then
		val[spec.v].min = val[spec.v].min / 1000
		val[spec.v].max = val[spec.v].max / 1000
	elseif spec.k == "milliseconds_to_seconds_1dp" then
		val[spec.v].min = round(val[spec.v].min / 1000, 1)
		val[spec.v].max = round(val[spec.v].max / 1000, 1)
		val[spec.v].fmt = "g"
	elseif spec.k == "milliseconds_to_seconds_2dp" then
		val[spec.v].min = round(val[spec.v].min / 1000, 2)
		val[spec.v].max = round(val[spec.v].max / 1000, 2)
		val[spec.v].fmt = "g"					
	elseif spec.k == "milliseconds_to_seconds_2dp_if_required" then
		val[spec.v].min = round(val[spec.v].min / 1000, 2)
		val[spec.v].max = round(val[spec.v].max / 1000, 2)
		val[spec.v].fmt = "g"					
	elseif spec.k == "deciseconds_to_seconds" then
		val[spec.v].min = val[spec.v].min / 10
		val[spec.v].max = val[spec.v].max / 10
		val[spec.v].fmt = ".2f"
	elseif spec.k == "30%_of_value" then
		val[spec.v].min = val[spec.v].min * 0.3
		val[spec.v].max = val[spec.v].max * 0.3
	elseif spec.k == "60%_of_value" then
		val[spec.v].min = val[spec.v].min * 0.6
		val[spec.v].max = val[spec.v].max * 0.6
	elseif spec.k == "multiplicative_damage_modifier" then
		val[spec.v].min = 100 + val[spec.v].min
		val[spec.v].max = 100 + val[spec.v].max
	elseif spec.k == "multiplicative_permyriad_damage_modifier" then
		val[spec.v].min = 100 + round(val[spec.v].min / 100, 1)
		val[spec.v].max = 100 + round(val[spec.v].max / 100, 1)
		val[spec.v].fmt = "g"
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

return function(stats, scopeName)
	local rootScope = getScope(scopeName)

	-- Figure out which descriptions we need, and identify them by the first stat that they describe
	local describeStats = { }
	for s, v in pairs(stats) do
		if (type(v) == "number" and v ~= 0) or (type(v) == "table" and (v.min ~= 0 or v.max ~= 0)) then	
			for depth, scope in ipairs(rootScope.scopeList) do
				if scope[s] then
					local descriptor = scope[scope[s]]
					if descriptor.lang then
						describeStats[descriptor.stats[1]] = { depth = depth, order = scope[s], description = scope[scope[s]] }
					end
					break
				end
			end
		end
	end

	-- Sort them by depth/order
	local descOrdered = { }
	for s, descriptor in pairs(describeStats) do
		t_insert(descOrdered, descriptor)
	end
	table.sort(descOrdered, function(a, b) if a.depth ~= b.depth then return a.depth > b.depth else return a.order < b.order end end)

	-- Describe the stats
	local out = { }
	local lineMap = { }
	for _, descriptor in ipairs(descOrdered) do
		local val = { }
		local stat
		for i, s in ipairs(descriptor.description.stats) do
			if stats[s] then
				if type(stats[s]) == "number" then
					val[i] = { min = stats[s], max = stats[s] }
				else
					val[i] = stats[s]
				end
				stat = s
			else
				val[i] = { min = 0, max = 0 }
			end
			val[i].fmt = "d"
		end
		local desc = matchLimit(descriptor.description.lang["English"], val)
		if desc then
			for _, spec in ipairs(desc) do
				applySpecial(val, spec)
			end
			local statDesc = desc.text:gsub("{(%d)}", function(n) 
				local v = val[tonumber(n)+1]
				if v.min == v.max then
					return s_format("%"..v.fmt, v.min)
				else
					return s_format("(%"..v.fmt.."-%"..v.fmt..")", v.min, v.max)
				end
			end):gsub("{}", function() 
				local v = val[1]
				if v.min == v.max then
					return s_format("%"..v.fmt, v.min)
				else
					return s_format("(%"..v.fmt.."-%"..v.fmt..")", v.min, v.max)
				end
			end):gsub("{:%+?d}", function() 
				local v = val[1]
				if v.min == v.max then
					return s_format("%"..v.fmt, v.min)
				else
					return s_format("(%"..v.fmt.."-%"..v.fmt..")", v.min, v.max)
				end
			end):gsub("{(%d):(%+?)d}", function(n, fmt)
				local v = val[tonumber(n)+1]
				if v.min == v.max then
					return s_format("%"..fmt..v.fmt, v.min)
				elseif fmt == "+" then
					if v.max < 0 then
						return s_format("-(%d-%d)", -v.min, -v.max)
					else
						return s_format("+(%d-%d)", v.min, v.max)
					end
				else
					return s_format("(%"..fmt..v.fmt.."-%"..fmt..v.fmt..")", v.min, v.max)
				end
			end):gsub("%%%%","%%")
			for line in (statDesc.."\\n"):gmatch("([^\\]+)\\n") do
				t_insert(out, line)
				lineMap[line] = stat
			end
		end
	end
	return out, lineMap
end
