-- Item data (c) Grinding Gear Games
local itemBases = ...

itemBases["Rustic Sash"] = {
	type = "Belt",
	implicit = "(12 to 24)% increased Physical Damage",
	req = { },
}
itemBases["Chain Belt"] = {
	type = "Belt",
	implicit = "+(9 to 20) to maximum Energy Shield",
	req = { },
}
itemBases["Leather Belt"] = {
	type = "Belt",
	implicit = "+(25 to 40) to maximum Life",
	req = { level = 8, },
}
itemBases["Heavy Belt"] = {
	type = "Belt",
	implicit = "+(25 to 35) to Strength",
	req = { level = 8, },
}
itemBases["Studded Belt"] = {
	type = "Belt",
	implicit = "(20 to 30)% increased Stun Duration on enemies",
	req = { level = 16, },
}
itemBases["Cloth Belt"] = {
	type = "Belt",
	implicit = "(15 to 25)% increased Stun Recovery",
	req = { level = 16, },
}