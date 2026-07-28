-- Path of Building
--
-- Module: CalcFormat
-- Format helpers for calc section cells/labels. Resolves a small placeholder
-- language against an actor's output/modDB:
--   {output:Key}, {ns.var} variant            -> actor.output value
--   {p:output:Key}                            -> rounded + thousand-separated
--   {p:mod:indices}                           -> combined mod total (INC/MORE/...)
--
local t_insert = table.insert

function formatCalcVal(val, p)
	return formatNumSep(tostring(round(val, p)))
end

function formatCalcStr(str, actor, colData)
	if not actor then return "" end
	str = str:gsub("{output:([%a%.:]+)}", function(c)
		local ns, var = c:match("^(%a+)%.(%a+)$")
		if ns then
			return actor.output[ns] and actor.output[ns][var] or ""
		else
			return actor.output[c] or ""
		end
	end)
	str = str:gsub("{(%d+):output:([%a%.:]+)}", function(p, c)
		local ns, var = c:match("^(%a+)%.(%a+)$")
		if ns then
			return formatCalcVal(actor.output[ns] and actor.output[ns][var] or 0, tonumber(p))
		else
			return formatCalcVal(actor.output[c] or 0, tonumber(p))
		end
	end)
	str = str:gsub("{(%d+):mod:([%d,]+)}", function(p, n)
		local numList = { }
		for num in n:gmatch("%d+") do
			t_insert(numList, tonumber(num))
		end
		if not colData[numList[1]] or not colData[numList[1]].modType then
			return "?"
		end
		local modType = colData[numList[1]].modType
		local modTotal = modType == "MORE" and 1 or 0
		for _, num in ipairs(numList) do
			local sectionData = colData[num]
			if not sectionData then break end
			local modCfg = (sectionData.cfg and actor.mainSkill and actor.mainSkill[sectionData.cfg.."Cfg"]) or { }
			if sectionData.modSource then
				modCfg.source = sectionData.modSource
			end
			if sectionData.actor then
				modCfg.actor = sectionData.actor
			end
			local modVal
			local modStore = (sectionData.enemy and actor.enemy and actor.enemy.modDB) or (sectionData.cfg and actor.mainSkill and actor.mainSkill.skillModList) or actor.modDB
			if not modStore then break end
			if type(sectionData.modName) == "table" then
				modVal = modStore:Combine(sectionData.modType, modCfg, unpack(sectionData.modName))
			else
				modVal = modStore:Combine(sectionData.modType, modCfg, sectionData.modName)
			end
			if modType == "MORE" then
				modTotal = modTotal * modVal
			else
				modTotal = modTotal + modVal
			end
		end
		if modType == "MORE" then
			modTotal = (modTotal - 1) * 100
		end
		return formatCalcVal(modTotal, tonumber(p))
	end)
	return str
end
