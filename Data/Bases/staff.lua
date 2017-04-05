-- Item data (c) Grinding Gear Games
local itemBases = ...

itemBases["Gnarled Branch"] = {
	type = "Staff",
	implicit = "18% Chance to Block",
	weapon = { PhysicalMin = 8, PhysicalMax = 17, critChanceBase = 6, attackRateBase = 1.3, },
	req = { },
}
itemBases["Primitive Staff"] = {
	type = "Staff",
	implicit = "18% Chance to Block",
	weapon = { PhysicalMin = 9, PhysicalMax = 28, critChanceBase = 6.2, attackRateBase = 1.25, },
	req = { level = 9, str = 20, int = 20, },
}
itemBases["Long Staff"] = {
	type = "Staff",
	implicit = "18% Chance to Block",
	weapon = { PhysicalMin = 17, PhysicalMax = 28, critChanceBase = 6, attackRateBase = 1.3, },
	req = { level = 13, str = 27, int = 27, },
}
itemBases["Iron Staff"] = {
	type = "Staff",
	implicit = "18% Chance to Block",
	weapon = { PhysicalMin = 16, PhysicalMax = 47, critChanceBase = 6.4, attackRateBase = 1.2, },
	req = { level = 18, str = 35, int = 35, },
}
itemBases["Coiled Staff"] = {
	type = "Staff",
	implicit = "20% Chance to Block",
	weapon = { PhysicalMin = 23, PhysicalMax = 48, critChanceBase = 6, attackRateBase = 1.2, },
	req = { level = 23, str = 43, int = 43, },
}
itemBases["Royal Staff"] = {
	type = "Staff",
	implicit = "18% Chance to Block",
	weapon = { PhysicalMin = 23, PhysicalMax = 70, critChanceBase = 6.5, attackRateBase = 1.15, },
	req = { level = 28, str = 51, int = 51, },
}
itemBases["Vile Staff"] = {
	type = "Staff",
	implicit = "18% Chance to Block",
	weapon = { PhysicalMin = 33, PhysicalMax = 62, critChanceBase = 6.1, attackRateBase = 1.25, },
	req = { level = 33, str = 59, int = 59, },
}
itemBases["Crescent Staff"] = {
	type = "Staff",
	implicit = "80% increased Global Critical Strike Chance",
	weapon = { PhysicalMin = 35, PhysicalMax = 73, critChanceBase = 6, attackRateBase = 1.2, },
	req = { level = 36, str = 66, int = 66, },
}
itemBases["Woodful Staff"] = {
	type = "Staff",
	implicit = "18% Chance to Block",
	weapon = { PhysicalMin = 29, PhysicalMax = 88, critChanceBase = 6.2, attackRateBase = 1.15, },
	req = { level = 37, str = 65, int = 65, },
}
itemBases["Quarterstaff"] = {
	type = "Staff",
	implicit = "18% Chance to Block",
	weapon = { PhysicalMin = 41, PhysicalMax = 68, critChanceBase = 6, attackRateBase = 1.3, },
	req = { level = 41, str = 72, int = 72, },
}
itemBases["Military Staff"] = {
	type = "Staff",
	implicit = "18% Chance to Block",
	weapon = { PhysicalMin = 34, PhysicalMax = 101, critChanceBase = 6.4, attackRateBase = 1.2, },
	req = { level = 45, str = 78, int = 78, },
}
itemBases["Serpentine Staff"] = {
	type = "Staff",
	implicit = "20% Chance to Block",
	weapon = { PhysicalMin = 46, PhysicalMax = 95, critChanceBase = 6, attackRateBase = 1.2, },
	req = { level = 49, str = 85, int = 85, },
}
itemBases["Highborn Staff"] = {
	type = "Staff",
	implicit = "18% Chance to Block",
	weapon = { PhysicalMin = 42, PhysicalMax = 125, critChanceBase = 6.5, attackRateBase = 1.15, },
	req = { level = 52, str = 89, int = 89, },
}
itemBases["Foul Staff"] = {
	type = "Staff",
	implicit = "18% Chance to Block",
	weapon = { PhysicalMin = 55, PhysicalMax = 103, critChanceBase = 6.1, attackRateBase = 1.25, },
	req = { level = 55, str = 94, int = 94, },
}
itemBases["Moon Staff"] = {
	type = "Staff",
	implicit = "80% increased Global Critical Strike Chance",
	weapon = { PhysicalMin = 57, PhysicalMax = 118, critChanceBase = 6, attackRateBase = 1.2, },
	req = { level = 57, str = 101, int = 101, },
}
itemBases["Primordial Staff"] = {
	type = "Staff",
	implicit = "18% Chance to Block",
	weapon = { PhysicalMin = 47, PhysicalMax = 141, critChanceBase = 6.2, attackRateBase = 1.15, },
	req = { level = 58, str = 99, int = 99, },
}
itemBases["Lathi"] = {
	type = "Staff",
	implicit = "18% Chance to Block",
	weapon = { PhysicalMin = 62, PhysicalMax = 103, critChanceBase = 6, attackRateBase = 1.3, },
	req = { level = 60, str = 113, int = 113, },
}
itemBases["Ezomyte Staff"] = {
	type = "Staff",
	implicit = "18% Chance to Block",
	weapon = { PhysicalMin = 46, PhysicalMax = 138, critChanceBase = 6.4, attackRateBase = 1.2, },
	req = { level = 62, str = 113, int = 113, },
}
itemBases["Maelstrom Staff"] = {
	type = "Staff",
	implicit = "20% Chance to Block",
	weapon = { PhysicalMin = 57, PhysicalMax = 119, critChanceBase = 6, attackRateBase = 1.2, },
	req = { level = 64, str = 113, int = 113, },
}
itemBases["Imperial Staff"] = {
	type = "Staff",
	implicit = "18% Chance to Block",
	weapon = { PhysicalMin = 49, PhysicalMax = 147, critChanceBase = 6.5, attackRateBase = 1.15, },
	req = { level = 66, str = 113, int = 113, },
}
itemBases["Judgement Staff"] = {
	type = "Staff",
	implicit = "18% Chance to Block",
	weapon = { PhysicalMin = 61, PhysicalMax = 113, critChanceBase = 6.1, attackRateBase = 1.25, },
	req = { level = 68, str = 113, int = 113, },
}
itemBases["Eclipse Staff"] = {
	type = "Staff",
	implicit = "100% increased Global Critical Strike Chance",
	weapon = { PhysicalMin = 60, PhysicalMax = 125, critChanceBase = 6, attackRateBase = 1.2, },
	req = { level = 70, str = 117, int = 117, },
}
