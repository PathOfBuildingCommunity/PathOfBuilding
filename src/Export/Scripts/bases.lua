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
	local baseTypeId, displayName = args:match("([%w/_]+) (.+)")
	if not baseTypeId then
		baseTypeId = args
	end
	local baseItemType = dat("BaseItemTypes"):GetRow("Id", baseTypeId)
	if not baseItemType then
		printf("Invalid Id %s", baseTypeId)
		return
	end
	local function getBaseItemTags(baseItemType)
		if baseItemType == "nothing" then -- base case
			return {}
		end
		local file = getFile(baseItemType .. ".it")
		if not file then return nil end
		local text = convertUTF16to8(file)
		local tags = {}
		for line in text:gmatch("[^\r\n]+") do
			local superClass = line:match("extends \"(.+)\"")
			if superClass then
				local superClassTags = getBaseItemTags(superClass)
				if superClassTags then
					for _, tag in ipairs(superClassTags) do
						table.insert(tags, tag)
					end
				end
			elseif line:match("tag") then
				table.insert(tags, line:match("tag = \"(.+)\""))
			end
		end
		return tags
	end
	local baseItemTags = getBaseItemTags(baseItemType.BaseType)
	if not displayName then
		displayName = baseItemType.Name
	end
	displayName = displayName:gsub("\195\182","o")
	displayName = displayName:gsub("^%s*(.-)%s*$", "%1") -- trim spaces GGG might leave in by accident
	displayName = displayName ~= "Energy Blade" and displayName or (state.type == "One Handed Sword" and "Energy Blade One Handed" or "Energy Blade Two Handed")
	out:write('itemBases["', displayName, '"] = {\n')
	out:write('\ttype = "', state.type, '",\n')
	if state.subType and #state.subType > 0 then
		out:write('\tsubType = "', state.subType, '",\n')
	end
	if (baseItemType.Hidden == 0 or state.forceHide) and not baseTypeId:match("Talisman") and not state.forceShow then
		out:write('\thidden = true,\n')
	end
	if state.socketLimit then
		out:write('\tsocketLimit = ', state.socketLimit, ',\n')
	end
	out:write('\ttags = { ')
	local combinedTags = { }
	for _, tag in ipairs(state.baseTags) do
		combinedTags[tag] = tag
	end
	for _, tag in ipairs(baseItemTags) do
		combinedTags[tag] = tag
	end
	for _, tag in ipairs(baseItemType.Tags) do
		combinedTags[tag.Id] = tag.Id
	end
	for _, tag in pairs(combinedTags) do
		out:write(tag, ' = true, ')
	end
	out:write('},\n')
	local movementPenalty
	local implicitLines = { }
	local implicitModTypes = { }
	for _, mod in ipairs(baseItemType.ImplicitMods) do
		local modDesc = describeMod(mod)
		for _, line in ipairs(modDesc) do
			table.insert(implicitLines, line)
			table.insert(implicitModTypes, modDesc.modTags)
		end
	end
	if #implicitLines > 0 then
		out:write('\timplicit = "', table.concat(implicitLines, "\\n"), '",\n')
	end
	out:write('\timplicitModTypes = { ')
	for i=1,#implicitModTypes do
		out:write('{ ', implicitModTypes[i], ' }, ')
	end
	out:write('},\n')
	local weaponType = dat("WeaponTypes"):GetRow("BaseItemType", baseItemType)
	if weaponType then
		out:write('\tweapon = { ')
		out:write('PhysicalMin = ', weaponType.DamageMin, ', PhysicalMax = ', weaponType.DamageMax, ', ')
		out:write('CritChanceBase = ', weaponType.CritChance / 100, ', ')
		out:write('AttackRateBase = ', round(1000 / weaponType.Speed, 2), ', ')
		out:write('Range = ', weaponType.Range, ', ')
		out:write('},\n')
	end
	local armourType = dat("ArmourTypes"):GetRow("BaseItemType", baseItemType)
	if armourType then
		out:write('\tarmour = { ')
		local shield = dat("ShieldTypes"):GetRow("BaseItemType", baseItemType)
		if shield then
			out:write('BlockChance = ', shield.Block, ', ')
		end
		if armourType.ArmourMin > 0 then
			out:write('ArmourBaseMin = ', armourType.ArmourMin, ', ')
			out:write('ArmourBaseMax = ', armourType.ArmourMax, ', ')
		end
		if armourType.EvasionMin > 0 then
			out:write('EvasionBaseMin = ', armourType.EvasionMin, ', ')
			out:write('EvasionBaseMax = ', armourType.EvasionMax, ', ')
		end
		if armourType.EnergyShieldMin > 0 then
			out:write('EnergyShieldBaseMin = ', armourType.EnergyShieldMin, ', ')
			out:write('EnergyShieldBaseMax = ', armourType.EnergyShieldMax, ', ')
		end
		if armourType.MovementPenalty ~= 0 then
			out:write('MovementPenalty = ', -armourType.MovementPenalty, ', ')
		end
		if armourType.WardMin > 0 then
			out:write('WardBaseMin = ', armourType.WardMin, ', ')
			out:write('WardBaseMax = ', armourType.WardMax, ', ')
		end
		out:write('},\n')
	end
	local flask = dat("Flasks"):GetRow("BaseItemType", baseItemType)
	if flask then
		local compCharges = dat("ComponentCharges"):GetRow("BaseItemType", baseItemType.Id)
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
			for i, stat in ipairs(flask.Buff.GrantedFlags) do
				stats[stat.Id] = { min = 1, max = 1 }
			end
			out:write('buff = { "', table.concat(describeStats(stats), '", "'), '" }, ')
		end
		out:write('},\n')
	end
	out:write('\treq = { ')
	local reqLevel = 1
	if weaponType or armourType then
		if baseItemType.DropLevel > 4 then
			reqLevel = baseItemType.DropLevel
		end
	end
	if flask then
		if baseItemType.DropLevel > 2 then
			reqLevel = baseItemType.DropLevel
		end
	end
	for _, mod in ipairs(baseItemType.ImplicitMods) do
		reqLevel = math.max(reqLevel, math.floor(mod.Level * 0.8))
	end
	if reqLevel > 1 then
		out:write('level = ', reqLevel, ', ')
	end
	local compAtt = dat("ComponentAttributeRequirements"):GetRow("BaseItemType", baseItemType.Id)
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

directiveTable.baseMatch = function(state, argstr, out)
	-- Default to look at the Id column for matching
	local key = "Id"
	local args = {}
	for i in string.gmatch(argstr, "%S+") do
	   table.insert(args, i)
	end
	local value = args[1]
	-- If column name is specified, use that
	if args[2] then
		key = args[1]
		value = args[2]
	end
	for i, baseItemType in ipairs(dat("BaseItemTypes"):GetRowList(key, value, true)) do
		if not string.find(baseItemType.Id, "Royale") then
			directiveTable.base(state, baseItemType.Id, out)
		end
	end
end

local itemTypes = {
	"axe",
	"bow",
	"claw",
	"dagger",
	"fishing",
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
	processTemplateFile(name, "Bases/", "../Data/Bases/", directiveTable)
end

print("Item bases exported.")
