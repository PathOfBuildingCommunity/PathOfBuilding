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