-- Item data (c) Grinding Gear Games
local itemBases = ...

itemBases["Crude Bow"] = {
	type = "Bow",
	weapon = { PhysicalMin = 5, PhysicalMax = 13, critChanceBase = 5, attackRateBase = 1.4, },
	req = { level = 1, dex = 14, },
}
itemBases["Short Bow"] = {
	type = "Bow",
	weapon = { PhysicalMin = 6, PhysicalMax = 16, critChanceBase = 5, attackRateBase = 1.5, },
	req = { level = 5, dex = 26, },
}
itemBases["Long Bow"] = {
	type = "Bow",
	weapon = { PhysicalMin = 6, PhysicalMax = 25, critChanceBase = 6, attackRateBase = 1.3, },
	req = { level = 9, dex = 38, },
}
itemBases["Composite Bow"] = {
	type = "Bow",
	weapon = { PhysicalMin = 12, PhysicalMax = 26, critChanceBase = 6, attackRateBase = 1.3, },
	req = { level = 14, dex = 53, },
}
itemBases["Recurve Bow"] = {
	type = "Bow",
	weapon = { PhysicalMin = 11, PhysicalMax = 34, critChanceBase = 6.5, attackRateBase = 1.25, },
	req = { level = 18, dex = 65, },
}
itemBases["Bone Bow"] = {
	type = "Bow",
	weapon = { PhysicalMin = 12, PhysicalMax = 36, critChanceBase = 6, attackRateBase = 1.35, },
	req = { level = 23, dex = 80, },
}
itemBases["Royal Bow"] = {
	type = "Bow",
	implicit = "(20-24)% increased Elemental Damage with Weapons",
	weapon = { PhysicalMin = 10, PhysicalMax = 41, critChanceBase = 5, attackRateBase = 1.45, },
	req = { level = 28, dex = 95, },
}
itemBases["Death Bow"] = {
	type = "Bow",
	implicit = "(30-50)% increased Critical Strike Chance",
	weapon = { PhysicalMin = 20, PhysicalMax = 53, critChanceBase = 5, attackRateBase = 1.2, },
	req = { level = 32, dex = 107, },
}
itemBases["Grove Bow"] = {
	type = "Bow",
	weapon = { PhysicalMin = 15, PhysicalMax = 44, critChanceBase = 5, attackRateBase = 1.5, },
	req = { level = 35, dex = 116, },
}
itemBases["Reflex Bow"] = {
	type = "Bow",
	implicit = "4% increased Movement Speed",
	weapon = { PhysicalMin = 27, PhysicalMax = 40, critChanceBase = 5.5, attackRateBase = 1.4, },
	req = { level = 36, dex = 124, },
}
itemBases["Decurve Bow"] = {
	type = "Bow",
	weapon = { PhysicalMin = 17, PhysicalMax = 70, critChanceBase = 6, attackRateBase = 1.25, },
	req = { level = 38, dex = 125, },
}
itemBases["Compound Bow"] = {
	type = "Bow",
	weapon = { PhysicalMin = 24, PhysicalMax = 56, critChanceBase = 6, attackRateBase = 1.3, },
	req = { level = 41, dex = 134, },
}
itemBases["Sniper Bow"] = {
	type = "Bow",
	weapon = { PhysicalMin = 23, PhysicalMax = 68, critChanceBase = 6.5, attackRateBase = 1.25, },
	req = { level = 44, dex = 143, },
}
itemBases["Ivory Bow"] = {
	type = "Bow",
	weapon = { PhysicalMin = 21, PhysicalMax = 64, critChanceBase = 6, attackRateBase = 1.35, },
	req = { level = 47, dex = 152, },
}
itemBases["Highborn Bow"] = {
	type = "Bow",
	implicit = "(20-24)% increased Elemental Damage with Weapons",
	weapon = { PhysicalMin = 17, PhysicalMax = 66, critChanceBase = 5, attackRateBase = 1.45, },
	req = { level = 50, dex = 161, },
}
itemBases["Decimation Bow"] = {
	type = "Bow",
	implicit = "(30-50)% increased Critical Strike Chance",
	weapon = { PhysicalMin = 31, PhysicalMax = 81, critChanceBase = 5, attackRateBase = 1.2, },
	req = { level = 53, dex = 170, },
}
itemBases["Thicket Bow"] = {
	type = "Bow",
	weapon = { PhysicalMin = 22, PhysicalMax = 66, critChanceBase = 5, attackRateBase = 1.5, },
	req = { level = 56, dex = 179, },
}
itemBases["Steelwood Bow"] = {
	type = "Bow",
	implicit = "4% increased Movement Speed",
	weapon = { PhysicalMin = 40, PhysicalMax = 60, critChanceBase = 5.5, attackRateBase = 1.4, },
	req = { level = 57, dex = 190, },
}
itemBases["Citadel Bow"] = {
	type = "Bow",
	weapon = { PhysicalMin = 25, PhysicalMax = 101, critChanceBase = 6, attackRateBase = 1.25, },
	req = { level = 58, dex = 185, },
}
itemBases["Ranger Bow"] = {
	type = "Bow",
	weapon = { PhysicalMin = 34, PhysicalMax = 79, critChanceBase = 6, attackRateBase = 1.3, },
	req = { level = 60, dex = 212, },
}
itemBases["Assassin Bow"] = {
	type = "Bow",
	weapon = { PhysicalMin = 30, PhysicalMax = 89, critChanceBase = 6.5, attackRateBase = 1.25, },
	req = { level = 62, dex = 212, },
}
itemBases["Spine Bow"] = {
	type = "Bow",
	weapon = { PhysicalMin = 27, PhysicalMax = 80, critChanceBase = 6, attackRateBase = 1.35, },
	req = { level = 64, dex = 212, },
}
itemBases["Imperial Bow"] = {
	type = "Bow",
	implicit = "(20-24)% increased Elemental Damage with Weapons",
	weapon = { PhysicalMin = 19, PhysicalMax = 78, critChanceBase = 5, attackRateBase = 1.45, },
	req = { level = 66, dex = 212, },
}
itemBases["Harbinger Bow"] = {
	type = "Bow",
	implicit = "(30-50)% increased Critical Strike Chance",
	weapon = { PhysicalMin = 35, PhysicalMax = 91, critChanceBase = 5, attackRateBase = 1.2, },
	req = { level = 68, dex = 212, },
}
itemBases["Maraketh Bow"] = {
	type = "Bow",
	implicit = "6% increased Movement Speed",
	weapon = { PhysicalMin = 44, PhysicalMax = 65, critChanceBase = 5.5, attackRateBase = 1.4, },
	req = { level = 71, dex = 222, },
}
