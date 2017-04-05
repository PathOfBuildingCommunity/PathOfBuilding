-- Item data (c) Grinding Gear Games
local itemBases = ...

itemBases["Rustic Sash"] = {
	type = "Belt",
	implicit = "(12-24)% increased Physical Damage",
	req = { },
}
itemBases["Chain Belt"] = {
	type = "Belt",
	implicit = "+(9-20) to maximum Energy Shield",
	req = { },
}
itemBases["Leather Belt"] = {
	type = "Belt",
	implicit = "+(25-40) to maximum Life",
	req = { level = 8, },
}
itemBases["Heavy Belt"] = {
	type = "Belt",
	implicit = "+(25-35) to Strength",
	req = { level = 8, },
}
itemBases["Studded Belt"] = {
	type = "Belt",
	implicit = "(20-30)% increased Stun Duration on enemies",
	req = { level = 16, },
}
itemBases["Cloth Belt"] = {
	type = "Belt",
	implicit = "(15-25)% increased Stun Recovery",
	req = { level = 16, },
}
itemBases["Vanguard Belt"] = {
	type = "Belt",
	implicit = "+(260-320) to Armour and Evasion Rating",
	req = { level = 70 },
}
itemBases["Crystal Belt"] = {
	type = "Belt",
	implicit = "+(60-80) to maximum Energy Shield",
	req = { level = 79 },
}
