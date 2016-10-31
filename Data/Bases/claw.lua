-- Item data (c) Grinding Gear Games
local itemBases = ...

itemBases["Nailed Fist"] = {
	type = "Claw",
	implicit = "+3 Life gained for each enemy hit by your Attacks",
	weapon = { PhysicalMin = 4, PhysicalMax = 9, critChanceBase = 6.2, attackRateBase = 1.6, },
	req = { level = 3, dex = 11, int = 11, },
}
itemBases["Sharktooth Claw"] = {
	type = "Claw",
	implicit = "+6 Life gained for each enemy hit by your Attacks",
	weapon = { PhysicalMin = 6, PhysicalMax = 15, critChanceBase = 6.5, attackRateBase = 1.4, },
	req = { level = 7, dex = 14, int = 20, },
}
itemBases["Awl"] = {
	type = "Claw",
	implicit = "+5 Life gained for each enemy hit by your Attacks",
	weapon = { PhysicalMin = 6, PhysicalMax = 20, critChanceBase = 6.3, attackRateBase = 1.5, },
	req = { level = 12, dex = 25, int = 25, },
}
itemBases["Cat's Paw"] = {
	type = "Claw",
	implicit = "1.6% of Physical Attack Damage Leeched as Life",
	weapon = { PhysicalMin = 10, PhysicalMax = 19, critChanceBase = 6, attackRateBase = 1.6, },
	req = { level = 17, dex = 39, int = 27, },
}
itemBases["Blinder"] = {
	type = "Claw",
	implicit = "+10 Life gained for each enemy hit by your Attacks",
	weapon = { PhysicalMin = 10, PhysicalMax = 27, critChanceBase = 6.3, attackRateBase = 1.5, },
	req = { level = 22, dex = 41, int = 41, },
}
itemBases["Timeworn Claw"] = {
	type = "Claw",
	implicit = "2% of Physical Attack Damage Leeched as Life",
	weapon = { PhysicalMin = 14, PhysicalMax = 36, critChanceBase = 6.5, attackRateBase = 1.3, },
	req = { level = 26, dex = 39, int = 56, },
}
itemBases["Sparkling Claw"] = {
	type = "Claw",
	implicit = "+10 Life gained for each enemy hit by your Attacks",
	weapon = { PhysicalMin = 12, PhysicalMax = 32, critChanceBase = 6, attackRateBase = 1.6, },
	req = { level = 30, dex = 64, int = 44, },
}
itemBases["Fright Claw"] = {
	type = "Claw",
	implicit = "2% of Physical Attack Damage Leeched as Life",
	weapon = { PhysicalMin = 9, PhysicalMax = 37, critChanceBase = 6.3, attackRateBase = 1.5, },
	req = { level = 34, dex = 61, int = 61, },
}
itemBases["Double Claw"] = {
	type = "Claw",
	implicit = "+6 Life and Mana gained for each Enemy hit",
	weapon = { PhysicalMin = 13, PhysicalMax = 40, critChanceBase = 6.3, attackRateBase = 1.5, },
	req = { level = 36, dex = 67, int = 67, },
}
itemBases["Thresher Claw"] = {
	type = "Claw",
	implicit = "+21 Life gained for each Enemy hit by Attacks",
	weapon = { PhysicalMin = 18, PhysicalMax = 48, critChanceBase = 6.5, attackRateBase = 1.3, },
	req = { level = 37, dex = 53, int = 77, },
}
itemBases["Gouger"] = {
	type = "Claw",
	implicit = "+13 Life gained for each enemy hit by your Attacks",
	weapon = { PhysicalMin = 13, PhysicalMax = 46, critChanceBase = 6.3, attackRateBase = 1.5, },
	req = { level = 40, dex = 70, int = 70, },
}
itemBases["Tiger's Paw"] = {
	type = "Claw",
	implicit = "1.6% of Physical Attack Damage Leeched as Life",
	weapon = { PhysicalMin = 21, PhysicalMax = 38, critChanceBase = 6, attackRateBase = 1.6, },
	req = { level = 43, dex = 88, int = 61, },
}
itemBases["Gut Ripper"] = {
	type = "Claw",
	implicit = "+21 Life gained for each enemy hit by your Attacks",
	weapon = { PhysicalMin = 18, PhysicalMax = 48, critChanceBase = 6.3, attackRateBase = 1.5, },
	req = { level = 46, dex = 80, int = 80, },
}
itemBases["Prehistoric Claw"] = {
	type = "Claw",
	implicit = "2% of Physical Attack Damage Leeched as Life",
	weapon = { PhysicalMin = 23, PhysicalMax = 61, critChanceBase = 6.5, attackRateBase = 1.3, },
	req = { level = 49, dex = 69, int = 100, },
}
itemBases["Noble Claw"] = {
	type = "Claw",
	implicit = "+18 Life gained for each Enemy hit by Attacks",
	weapon = { PhysicalMin = 19, PhysicalMax = 50, critChanceBase = 6, attackRateBase = 1.6, },
	req = { level = 52, dex = 105, int = 73, },
}
itemBases["Eagle Claw"] = {
	type = "Claw",
	implicit = "2% of Physical Attack Damage Leeched as Life",
	weapon = { PhysicalMin = 14, PhysicalMax = 56, critChanceBase = 6.3, attackRateBase = 1.5, },
	req = { level = 55, dex = 94, int = 94, },
}
itemBases["Twin Claw"] = {
	type = "Claw",
	implicit = "+10 Life and Mana gained for each Enemy hit",
	weapon = { PhysicalMin = 20, PhysicalMax = 60, critChanceBase = 6.3, attackRateBase = 1.5, },
	req = { level = 57, dex = 103, int = 103, },
}
itemBases["Great White Claw"] = {
	type = "Claw",
	implicit = "+34 Life gained for each Enemy hit by Attacks",
	weapon = { PhysicalMin = 27, PhysicalMax = 70, critChanceBase = 6.5, attackRateBase = 1.3, },
	req = { level = 58, dex = 81, int = 117, },
}
itemBases["Throat Stabber"] = {
	type = "Claw",
	implicit = "+21 Life gained for each Enemy hit by Attacks",
	weapon = { PhysicalMin = 19, PhysicalMax = 65, critChanceBase = 6.3, attackRateBase = 1.5, },
	req = { level = 60, dex = 113, int = 113, },
}
itemBases["Hellion's Paw"] = {
	type = "Claw",
	implicit = "1.6% of Physical Attack Damage Leeched as Life",
	weapon = { PhysicalMin = 27, PhysicalMax = 51, critChanceBase = 6, attackRateBase = 1.6, },
	req = { level = 62, dex = 131, int = 95, },
}
itemBases["Eye Gouger"] = {
	type = "Claw",
	implicit = "+31 Life gained for each enemy hit by Attacks",
	weapon = { PhysicalMin = 23, PhysicalMax = 61, critChanceBase = 6.3, attackRateBase = 1.5, },
	req = { level = 64, dex = 113, int = 113, },
}
itemBases["Vaal Claw"] = {
	type = "Claw",
	implicit = "2% of Physical Attack Damage Leeched as Life",
	weapon = { PhysicalMin = 27, PhysicalMax = 72, critChanceBase = 6.5, attackRateBase = 1.3, },
	req = { level = 66, dex = 95, int = 131, },
}
itemBases["Imperial Claw"] = {
	type = "Claw",
	implicit = "+25 Life gained for each Enemy hit by Attacks",
	weapon = { PhysicalMin = 22, PhysicalMax = 57, critChanceBase = 6, attackRateBase = 1.6, },
	req = { level = 68, dex = 131, int = 95, },
}
itemBases["Terror Claw"] = {
	type = "Claw",
	implicit = "2% of Physical Attack Damage Leeched as Life",
	weapon = { PhysicalMin = 15, PhysicalMax = 60, critChanceBase = 6.3, attackRateBase = 1.5, },
	req = { level = 70, dex = 113, int = 113, },
}
itemBases["Gemini Claw"] = {
	type = "Claw",
	implicit = "+14 Life and Mana gained for each Enemy hit",
	weapon = { PhysicalMin = 21, PhysicalMax = 63, critChanceBase = 6.3, attackRateBase = 1.5, },
	req = { level = 72, dex = 121, int = 121, },
}


