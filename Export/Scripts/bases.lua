if not loadStatFile then
	dofile("statdesc.lua")
end
loadStatFile("stat_descriptions.txt")

local directiveTable = { }

directiveTable.type = function(state, args, out)
	state.type = args
end

directiveTable.subType = function(state, args, out)
	state.subType = args
end

directiveTable.baseTags = function(state, args, out)
	state.baseTags = { "default" }
	for tag in args:gmatch("[%w_]+") do
		table.insert(state.baseTags, tag)
	end
end

directiveTable.forceShow = function(state, args, out)
	state.forceShow = (args == "true")
end

directiveTable.forceHide = function(state, args, out)
	state.forceHide = (args == "true")
end

directiveTable.socketLimit = function(state, args, out)
	state.socketLimit = tonumber(args)
end

directiveTable.base = function(state, args, out)
	local baseTypeId, displayName = args:match("([%w/]+) (.+)")
	if not baseTypeId then
		baseTypeId = args
	end
	local baseItemType = dat"BaseItemTypes":GetRow("Id", baseTypeId)
	if not baseItemType then
		printf("Invalid Id %s", baseTypeId)
		return
	end
	if not displayName then
		displayName = baseItemType.Name
	end
	displayName = displayName:gsub("\195\182","o")
	out:write('itemBases["', displayName, '"] = {\n')
	out:write('\ttype = "', state.type, '",\n')
	if state.subType and #state.subType > 0 then
		out:write('\tsubType = "', state.subType, '",\n')
	end
	if (baseItemType.Hidden or state.forceHide) and not baseTypeId:match("Talisman") and not state.forceShow then
		out:write('\thidden = true,\n')
	end
	if state.socketLimit then	
		out:write('\tsocketLimit = ', state.socketLimit, ',\n')
	end
	out:write('\ttags = { ')
	for _, tag in ipairs(state.baseTags) do
		out:write(tag, ' = true, ')
	end
	for _, tag in ipairs(baseItemType.Tags) do
		out:write(tag.Id, ' = true, ')
	end
	out:write('},\n')
	local movementPenalty
	local implicitLines = { }
	for _, mod in ipairs(baseItemType.ImplicitMods) do
		for _, line in ipairs(describeMod(mod)) do
			table.insert(implicitLines, line)
		end
	end
	if #implicitLines > 0 then
		out:write('\timplicit = "', table.concat(implicitLines, "\\n"), '",\n')
	end
	local weaponType = dat"WeaponTypes":GetRow("BaseItemType", baseItemType)
	if weaponType then
		out:write('\tweapon = { ')
		out:write('PhysicalMin = ', weaponType.DamageMin, ', PhysicalMax = ', weaponType.DamageMax, ', ')
		out:write('CritChanceBase = ', weaponType.CritChance / 100, ', ')
		out:write('AttackRateBase = ', round(1000 / weaponType.Speed, 2), ', ')
		out:write('},\n')
	end
	local compArmour = dat"ComponentArmour":GetRow("BaseItemType", baseItemType.Id)
	if compArmour then
		out:write('\tarmour = { ')
		local shield = dat"ShieldTypes":GetRow("BaseItemType", baseItemType)
		if shield then
			out:write('BlockChance = ', shield.Block, ', ')
		end
		if compArmour.Armour > 0 then
			out:write('ArmourBase = ', compArmour.Armour, ', ')
		end
		if compArmour.Evasion > 0 then
			out:write('EvasionBase = ', compArmour.Evasion, ', ')
		end
		if compArmour.EnergyShield > 0 then
			out:write('EnergyShieldBase = ', compArmour.EnergyShield, ', ')
		end
		if compArmour.MovementPenalty ~= 0 then
			out:write('MovementPenalty = ', -compArmour.MovementPenalty, ', ')
		end
		out:write('},\n')
	end
	local flask = dat"Flasks":GetRow("BaseItemType", baseItemType)
	if flask then
		local compCharges = dat"ComponentCharges":GetRow("BaseItemType", baseItemType.Id)
		out:write('\tflask = { ')
		if flask.LifePerUse > 0 then
			out:write('life = ', flask.LifePerUse, ', ')
		end
		if flask.ManaPerUse > 0 then
			out:write('mana = ', flask.ManaPerUse, ', ')
		end
		out:write('duration = ', flask.RecoveryTime / 10, ', ')
		out:write('chargesUsed = ', compCharges.PerUse, ', ')
		out:write('chargesMax = ', compCharges.Max, ', ')
		if flask.Buff then
			local stats = { }
			for i, stat in ipairs(flask.Buff.Stats) do
				stats[stat.Id] = { min = flask.BuffMagnitudes[i], max = flask.BuffMagnitudes[i] }
			end
			out:write('buff = { "', table.concat(describeStats(stats), '", "'), '" }, ')
		end
		out:write('},\n')
	end
	out:write('\treq = { ')
	local reqLevel = 1
	if weaponType or compArmour then
		if baseItemType.DropLevel > 4 then
			reqLevel = baseItemType.DropLevel
		end
	end
	for _, mod in ipairs(baseItemType.ImplicitMods) do
		reqLevel = math.max(reqLevel, math.floor(mod.Level * 0.8))
	end
	if reqLevel > 1 then
		out:write('level = ', reqLevel, ', ')
	end
	local compAtt = dat"ComponentAttributeRequirements":GetRow("BaseItemType", baseItemType.Id)
	if compAtt then
		if compAtt.Str > 0 then
			out:write('str = ', compAtt.Str, ', ')
		end
		if compAtt.Dex > 0 then
			out:write('dex = ', compAtt.Dex, ', ')
		end
		if compAtt.Int > 0 then
			out:write('int = ', compAtt.Int, ', ')
		end
	end
	out:write('},\n}\n')
end

directiveTable.baseMatch = function(state, args, out)
	for i, baseItemType in ipairs(dat"BaseItemTypes":GetRowList("Id", args, true)) do
		directiveTable.base(state, baseItemType.Id, out)
	end
end

local itemTypes = {
	"axe",
	"bow",
	"claw",
	"dagger",
	"mace",
	"staff",
	"sword",
	"wand",
	"helmet",
	"body",
	"gloves",
	"boots",
	"shield",
	"quiver",
	"amulet",
	"ring",
	"belt",
	"jewel",
	"flask",
}
for _, name in pairs(itemTypes) do
	processTemplateFile(name, "Bases/", "../Data/3_0/Bases/", directiveTable)
end

print("Item bases exported.")