local mode
local ess = { }
local curEss
for line in io.lines("essence.txt") do
	if not mode then
		if line == "Rarity: Currency" then
			mode = "NAME"
		end
	elseif mode == "NAME" then
		curEss = { }
		ess[line] = curEss
		mode = "UPGRADES"
	elseif mode == "UPGRADES" and line:match("^Upgrades") then
		mode = "STAT"
	elseif mode == "STAT" then
		if line == "--------" then
			mode = nil
		else
			local type, mod = line:match("(.+): (.+)")
			if type then
				curEss[type] = { mod:gsub("^(%(%d+%-%d+%)%%? to)", "+%1"):gsub("^(%(%d+%-%d+%)%%? Chance)", "+%1") }
			end
		end
	end
end

local out = io.open("essence.csv", "w")
local h = { }
for name, index in pairs(Essences.headerMap) do
	if name:match("ModsKey") and not name:match("ModsKeys") then
		table.insert(h, name)
	end
end
table.sort(h, function(a,b) return Essences.headerMap[a] < Essences.headerMap[b] end)
out:write('Name;', table.concat(h, ';'), '\n')
for essenceKey = 0, Essences.maxRow do
	local essence = Essences[essenceKey]
	if essence.Tier >= 7 then
		local name = BaseItemTypes[essence.BaseItemTypesKey].Name
		out:write(name, ';')
		for _, h in ipairs(h) do
			local k = essence[h]
			if k then
				local md = describeMod(M[k])
				if md[1] then
					local foo = { }
					for type, mod in pairs(ess[name]) do
						if mod[1] == md[1] then
							table.insert(foo, type)
							mod.match = true
						end
					end
					out:write(table.concat(foo, ','), ';')
					--out:write(md[1]:gsub("(%a%a%a)%a+","%1"), ';')
				else
					out:write(';')
				end
			else
				out:write(';')
			end
		end
		out:write('\n')
	end
end
out:write('\nNo match:\n')
for name, ess in pairs(ess) do
	for type, mod in pairs(ess) do
		if not mod.match then
			out:write(name, ';', type, ';', mod[1], '\n')
		end
	end
end
out:close()
