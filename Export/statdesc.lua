local nk = { }

function processStatFile(name)
	local statDescriptor = { }
	local curLang
	local curDescriptor = { }
	local f = io.open("StatDescriptions/"..name..".txt", "rb")
	local text = convertUTF16to8(f:read("*a"))
	f:close()
	for line in text:gmatch("[^\r\n]+") do
		local parent = line:match('include "Metadata/StatDescriptions/(.+)%.txt"$')
		if parent then
			statDescriptor.parent = parent
		else
			local noDesc = line:match("no_description ([%w_%+%-%%]+)")
			if noDesc then
				table.insert(statDescriptor, { stats = { noDesc } })
				statDescriptor[noDesc] = #statDescriptor
			elseif line:match("description") then	
				local name = line:match("description ([%w_]+)")
				curLang = { }
				curDescriptor = { lang = { ["English"] = curLang }, order = order, name = name }
				table.insert(statDescriptor, curDescriptor)
			elseif not curDescriptor.stats then
				local stats = line:match("%d+%s+([%w_%+%-%% ]+)")
				if stats then
					curDescriptor.stats = { }
					for stat in stats:gmatch("[%w_%+%-%%]+") do
						table.insert(curDescriptor.stats, stat)
						statDescriptor[stat] = #statDescriptor
					end
				end
			else
				local langName = line:match('lang "(.+)"')
				if langName then
					curLang = nil--{ }
					curDescriptor.lang[langName] = curLang
				elseif curLang then
					local statLimits, text, special = line:match('([%d%-#| ]+) "(.-)"%s*(.*)')
					if statLimits then
						local desc = { text = text, limit = { } }
						for statLimit in statLimits:gmatch("[%d%-#|]+") do
							local limit = { }
							if statLimit == "#" then
								limit[1] = "#"
								limit[2] = "#"
							elseif statLimit:match("^%-?%d+$") then
								limit[1] = tonumber(statLimit)
								limit[2] = tonumber(statLimit)
							else
								limit[1], limit[2] = statLimit:match("([%d%-#]+)|([%d%-#]+)")
								limit[1] = tonumber(limit[1]) or limit[1]
								limit[2] = tonumber(limit[2]) or limit[2]
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
	end
	local out = io.open("../Data/3_0/StatDescriptions/"..name..".lua", "w")
	out:write("return ")
	writeLuaTable(out, statDescriptor)
	out:close()
end

local statFileList = {
	"active_skill_gem_stat_descriptions",
	"aura_skill_stat_descriptions",
	"banner_aura_skill_stat_descriptions",
	"beam_skill_stat_descriptions",
	"brand_skill_stat_descriptions",
	"curse_skill_stat_descriptions",
	"debuff_skill_stat_descriptions",
	"gem_stat_descriptions",
	"minion_attack_skill_stat_descriptions",
	"minion_skill_stat_descriptions",
	"minion_spell_skill_stat_descriptions",
	"monster_stat_descriptions",
	"offering_skill_stat_descriptions",
	"skill_stat_descriptions",
	"stat_descriptions",
	"variable_duration_skill_stat_descriptions",
}
for _, name in ipairs(statFileList) do
	processStatFile(name)
end

for k, v in pairs(nk) do
	print("'"..k.."' = '"..v.."'")
end
