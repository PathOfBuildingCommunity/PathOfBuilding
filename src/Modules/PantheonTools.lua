-- Various functions for Pantheon
--

pantheon = { }

function pantheon.applySoulMod(db, modParser, god)
	for _, soul in pairs(god.souls) do
		for _, soulMod in pairs(soul.mods) do
			local modList, extra = modParser(soulMod.line)
			if modList and not extra then
				for _, mod in pairs(modList) do
					local godName = god.souls[1].name
					mod.source = "Pantheon:"..godName
				end
				db:AddList(modList)
			end
		end
	end
end

function pantheon.applySelectedSoulMod(db, modParser, god, selectedSouls)
	for i, soul in pairs(god.souls) do
		if selectedSouls[i] then --only parse the mods of selected souls
			for _, soulMod in pairs(soul.mods) do
				local modList, extra = modParser(soulMod.line)
				if modList and not extra then
					for _, mod in pairs(modList) do
						local godName = god.souls[1].name 
						mod.source = "Pantheon:"..godName
					end
					db:AddList(modList)
				end
			end
		end
	end
end

---Return a table which contains selected souls checkboxes state
---@param input table
---@param godSource string God list control name
---@param godName string
---@return table
function pantheon.getGodSouls(input, godSource, godName)
	local godSouls = { true } --forcing to true the god, since it has been selected for sure
	local soulSource = godSource..'Soul' -- building checkbox name based on godSource (pantheonMajorGodSoul/pantheonMinorGodSoul)
	local indexEnd = data.pantheons[godName].isMajorGod and 4 or 2 -- keep the same logic as the for loop in Modules/ConfigOption
	for i = 2, indexEnd do
		table.insert(godSouls, input[soulSource..tostring(i-1)]) -- (i-1) because checkboxes names are numbered starting by 1
	end
	return godSouls
end