local directiveTable = { }

-- #boss <Type> <Name>
directiveTable.boss = function(state, args, out)
    state.id = nil
    state.name = nil
    for arg in args:gmatch("%S+") do
        if state.id == nil then
			state.id = arg
        elseif state.name == nil then
            if arg == "#" then
                state.name = state.id
            else
                state.name = arg
            end
        end
    end

    local isUber = args:match("{Uber}")

    local monsterType = dat("MonsterTypes"):GetRow("Id", state.id)
    if not monsterType then
		print("Invalid Type: "..state.varietyId)
		return
	end

    out:write('bosses["', state.name, '"] = {\n')
    out:write('\tarmourMult = ', monsterType.Armour, ',\n')
    out:write('\tevasionMult = ', monsterType.Evasion, ',\n')
    out:write('\tisUber = ', isUber and "true" or "false", ',\n')
	out:write('}\n')
end

processTemplateFile("Bosses", "Enemies/", "../Data/", directiveTable)

print("Enemy data exported.")
