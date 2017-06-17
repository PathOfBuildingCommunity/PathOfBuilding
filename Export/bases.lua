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

directiveTable.base = function(state, args, out)
	local baseTypeId, displayName = args:match("([%w/]+) (.+)")
	if not baseTypeId then
		baseTypeId = args
	end
	local baseItemTypeKey = BaseItemTypes.Id(baseTypeId)[1]
	if not baseItemTypeKey then
		printf("Invalid Id %s", baseTypeId)
		return
	end
	local baseItemType = BaseItemTypes[baseItemTypeKey]
	if not displayName then
		displayName = baseItemType.Name
	end
	out:write('itemBases["', displayName, '"] = {\n')
	out:write('\ttype = "', state.type, '",\n')
	if state.subType and #state.subType > 0 then
		out:write('\tsubType = "', state.subType, '",\n')
	end
	if baseItemType.Flag0 and not baseTypeId:match("Talisman") and not state.forceShow then
		out:write('\thidden = true,\n')
	end
	out:write('\ttags = { ')
	for _, tag in ipairs(state.baseTags) do
		out:write(tag, ' = true, ')
	end
	for _, tagKey in ipairs(baseItemType.TagsKeys) do
		out:write(Tags[tagKey].Id, ' = true, ')
	end
	out:write('},\n')
	local movementPenalty
	local implicitLines = { }
	for _, modKey in ipairs(baseItemType.Implicit_ModsKeys) do
		local mod = Mods[modKey]
		if mod.CorrectGroup == "MovementVelocityPenalty" then
			movementPenalty = -mod.Stat1Min
		else
			for _, line in ipairs(describeMod(mod)) do
				table.insert(implicitLines, line)
			end
		end
	end
	if #implicitLines > 0 then
		out:write('\timplicit = "', table.concat(implicitLines, "\\n"), '",\n')
	end
	local weaponTypeKey = WeaponTypes.BaseItemTypesKey(baseItemTypeKey)[1]
	if weaponTypeKey then
		local weaponType = WeaponTypes[weaponTypeKey]
		out:write('\tweapon = { ')
		out:write('PhysicalMin = ', weaponType.DamageMin, ', PhysicalMax = ', weaponType.DamageMax, ', ')
		out:write('CritChanceBase = ', weaponType.Critical / 100, ', ')
		out:write('AttackRateBase = ', round(1000 / weaponType.Speed, 2), ', ')
		out:write('},\n')
	end
	local compArmourKey = ComponentArmour.BaseItemTypesKey(baseTypeId)[1]
	if compArmourKey then
		local compArmour = ComponentArmour[compArmourKey]
		out:write('\tarmour = { ')
		local shieldKey = ShieldTypes.BaseItemTypesKey(baseItemTypeKey)[1]
		if shieldKey then
			local shield = ShieldTypes[shieldKey]
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
		if movementPenalty then
			out:write('MovementPenalty = ', movementPenalty, ', ')
		end
		out:write('},\n')
	end
	local flaskKey = Flasks.BaseItemTypesKey(baseItemTypeKey)[1]
	if flaskKey then
		local flask = Flasks[flaskKey]
		local compCharges = ComponentCharges[ComponentCharges.BaseItemTypesKey(baseTypeId)[1]]
		out:write('\tflask = { ')
		if flask.LifePerUse > 0 then
			out:write('life = ', flask.LifePerUse, ', ')
		end
		if flask.ManaPerUse > 0 then
			out:write('mana = ', flask.ManaPerUse, ', ')
		end
		out:write('duration = ', flask.RecoveryTime / 10, ', ')
		out:write('chargesUsed = ', compCharges.PerCharge, ', ')
		out:write('chargesMax = ', compCharges.MaxCharges, ', ')
		if flask.BuffDefinitionsKey then
			local buffDef = BuffDefinitions[flask.BuffDefinitionsKey]
			local stats = { }
			for i, statKey in ipairs(buffDef.StatsKeys) do
				stats[Stats[statKey].Id] = { min = flask.BuffStatValues[i], max = flask.BuffStatValues[i] }
			end
			out:write('buff = { "', table.concat(describeStats(stats), '", "'), '" }, ')
		end
		out:write('},\n')
	end
	out:write('\treq = { ')
	local reqLevel = 1
	if weaponTypeKey or compArmourKey then
		if baseItemType.DropLevel > 4 then
			reqLevel = baseItemType.DropLevel
		end
	end
	for _, modKey in ipairs(baseItemType.Implicit_ModsKeys) do
		reqLevel = math.max(reqLevel, math.floor(Mods[modKey].Level * 0.8))
	end
	if reqLevel > 1 then
		out:write('level = ', reqLevel, ', ')
	end
	local compAttKey = ComponentAttributeRequirements.BaseItemTypesKey(baseTypeId)[1]
	if compAttKey then
		local compAtt = ComponentAttributeRequirements[compAttKey]
		if compAtt.ReqStr > 0 then
			out:write('str = ', compAtt.ReqStr, ', ')
		end
		if compAtt.ReqDex > 0 then
			out:write('dex = ', compAtt.ReqDex, ', ')
		end
		if compAtt.ReqInt > 0 then
			out:write('int = ', compAtt.ReqInt, ', ')
		end
	end
	out:write('},\n}\n')
end

directiveTable.baseMatch = function(state, args, out)
	for _, baseItemTypesKey in ipairs(BaseItemTypes.Id(args, true)) do
		directiveTable.base(state, BaseItemTypes[baseItemTypesKey].Id, out)
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
	processTemplateFile("Bases/"..name, directiveTable)
end

os.execute("xcopy Bases\\*.lua ..\\Data\\3_0\\Bases\\ /Y /Q")

print("Item bases exported.")