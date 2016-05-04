-- Item data (c) Grinding Gear Games
local itemBases = ...

itemBases["Crude Bow"] = {
	type = "Bow",
	weapon = { physicalMin = 5, physicalMax = 13, critChanceBase = 5, attackRateBase = 1.4, },
	req = { level = 1, dex = 14, },
}
itemBases["Short Bow"] = {
	type = "Bow",
	weapon = { physicalMin = 6, physicalMax = 16, critChanceBase = 5, attackRateBase = 1.5, },
	req = { level = 5, dex = 26, },
}
itemBases["Long Bow"] = {
	type = "Bow",
	weapon = { physicalMin = 6, physicalMax = 25, critChanceBase = 6, attackRateBase = 1.3, },
	req = { level = 9, dex = 38, },
}
itemBases["Composite Bow"] = {
	type = "Bow",
	weapon = { physicalMin = 12, physicalMax = 26, critChanceBase = 6, attackRateBase = 1.3, },
	req = { level = 14, dex = 53, },
}
itemBases["Recurve Bow"] = {
	type = "Bow",
	weapon = { physicalMin = 11, physicalMax = 34, critChanceBase = 6.5, attackRateBase = 1.25, },
	req = { level = 18, dex = 65, },
}
itemBases["Bone Bow"] = {
	type = "Bow",
	weapon = { physicalMin = 12, physicalMax = 36, critChanceBase = 6, attackRateBase = 1.35, },
	req = { level = 23, dex = 80, },
}
itemBases["Royal Bow"] = {
	type = "Bow",
	implicit = "(6 to 12)% increased Elemental Damage with Weapons",
	weapon = { physicalMin = 10, physicalMax = 41, critChanceBase = 5, attackRateBase = 1.45, },
	req = { level = 28, dex = 95, },
}
itemBases["Death Bow"] = {
	type = "Bow",
	implicit = "(30 to 50)% increased Critical Strike Chance",
	weapon = { physicalMin = 20, physicalMax = 53, critChanceBase = 5, attackRateBase = 1.2, },
	req = { level = 32, dex = 107, },
}
itemBases["Grove Bow"] = {
	type = "Bow",
	weapon = { physicalMin = 15, physicalMax = 44, critChanceBase = 5, attackRateBase = 1.5, },
	req = { level = 35, dex = 116, },
}
itemBases["Reflex Bow"] = {
	type = "Bow",
	implicit = "4% increased Movement Speed",
	weapon = { physicalMin = 27, physicalMax = 40, critChanceBase = 5.5, attackRateBase = 1.4, },
	req = { level = 36, dex = 124, },
}
itemBases["Decurve Bow"] = {
	type = "Bow",
	weapon = { physicalMin = 17, physicalMax = 70, critChanceBase = 6, attackRateBase = 1.25, },
	req = { level = 38, dex = 125, },
}
itemBases["Compound Bow"] = {
	type = "Bow",
	weapon = { physicalMin = 24, physicalMax = 56, critChanceBase = 6, attackRateBase = 1.3, },
	req = { level = 41, dex = 134, },
}
itemBases["Sniper Bow"] = {
	type = "Bow",
	weapon = { physicalMin = 23, physicalMax = 68, critChanceBase = 6.5, attackRateBase = 1.25, },
	req = { level = 44, dex = 143, },
}
itemBases["Ivory Bow"] = {
	type = "Bow",
	weapon = { physicalMin = 21, physicalMax = 64, critChanceBase = 6, attackRateBase = 1.35, },
	req = { level = 47, dex = 152, },
}
itemBases["Highborn Bow"] = {
	type = "Bow",
	implicit = "(6 to 12)% increased Elemental Damage with Weapons",
	weapon = { physicalMin = 17, physicalMax = 66, critChanceBase = 5, attackRateBase = 1.45, },
	req = { level = 50, dex = 161, },
}
itemBases["Decimation Bow"] = {
	type = "Bow",
	implicit = "(30 to 50)% increased Critical Strike Chance",
	weapon = { physicalMin = 31, physicalMax = 81, critChanceBase = 5, attackRateBase = 1.2, },
	req = { level = 53, dex = 170, },
}
itemBases["Thicket Bow"] = {
	type = "Bow",
	weapon = { physicalMin = 22, physicalMax = 66, critChanceBase = 5, attackRateBase = 1.5, },
	req = { level = 56, dex = 179, },
}
itemBases["Steelwood Bow"] = {
	type = "Bow",
	implicit = "4% increased Movement Speed",
	weapon = { physicalMin = 40, physicalMax = 60, critChanceBase = 5.5, attackRateBase = 1.4, },
	req = { level = 57, dex = 190, },
}
itemBases["Citadel Bow"] = {
	type = "Bow",
	weapon = { physicalMin = 25, physicalMax = 101, critChanceBase = 6, attackRateBase = 1.25, },
	req = { level = 58, dex = 185, },
}
itemBases["Ranger Bow"] = {
	type = "Bow",
	weapon = { physicalMin = 34, physicalMax = 79, critChanceBase = 6, attackRateBase = 1.3, },
	req = { level = 60, dex = 212, },
}
itemBases["Assassin Bow"] = {
	type = "Bow",
	weapon = { physicalMin = 30, physicalMax = 89, critChanceBase = 6.5, attackRateBase = 1.25, },
	req = { level = 62, dex = 212, },
}
itemBases["Spine Bow"] = {
	type = "Bow",
	weapon = { physicalMin = 27, physicalMax = 80, critChanceBase = 6, attackRateBase = 1.35, },
	req = { level = 64, dex = 212, },
}
itemBases["Imperial Bow"] = {
	type = "Bow",
	implicit = "(6 to 12)% increased Elemental Damage with Weapons",
	weapon = { physicalMin = 19, physicalMax = 78, critChanceBase = 5, attackRateBase = 1.45, },
	req = { level = 66, dex = 212, },
}
itemBases["Harbinger Bow"] = {
	type = "Bow",
	implicit = "(30 to 50)% increased Critical Strike Chance",
	weapon = { physicalMin = 35, physicalMax = 91, critChanceBase = 5, attackRateBase = 1.2, },
	req = { level = 68, dex = 212, },
}
itemBases["Maraketh Bow"] = {
	type = "Bow",
	implicit = "6% increased Movement Speed",
	weapon = { physicalMin = 44, physicalMax = 65, critChanceBase = 5.5, attackRateBase = 1.4, },
	req = { level = 71, dex = 222, },
}
