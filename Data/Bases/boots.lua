-- Item data (c) Grinding Gear Games
local itemBases = ...

itemBases["Iron Greaves"] = {
	type = "Boots",
	subType = "Armour",
	armour = { armourBase = 6, },
	req = { },
}
itemBases["Steel Greaves"] = {
	type = "Boots",
	subType = "Armour",
	armour = { armourBase = 28, },
	req = { level = 9, str = 21, },
}
itemBases["Plated Greaves"] = {
	type = "Boots",
	subType = "Armour",
	armour = { armourBase = 67, },
	req = { level = 23, str = 44, },
}
itemBases["Reinforced Greaves"] = {
	type = "Boots",
	subType = "Armour",
	armour = { armourBase = 95, },
	req = { level = 33, str = 60, },
}
itemBases["Antique Greaves"] = {
	type = "Boots",
	subType = "Armour",
	armour = { armourBase = 106, },
	req = { level = 37, str = 67, },
}
itemBases["Ancient Greaves"] = {
	type = "Boots",
	subType = "Armour",
	armour = { armourBase = 132, },
	req = { level = 46, str = 82, },
}
itemBases["Goliath Greaves"] = {
	type = "Boots",
	subType = "Armour",
	armour = { armourBase = 154, },
	req = { level = 54, str = 95, },
}
itemBases["Vaal Greaves"] = {
	type = "Boots",
	subType = "Armour",
	armour = { armourBase = 191, },
	req = { level = 62, str = 117, },
}
itemBases["Titan Greaves"] = {
	type = "Boots",
	subType = "Armour",
	armour = { armourBase = 210, },
	req = { level = 68, str = 120, },
}


itemBases["Rawhide Boots"] = {
	type = "Boots",
	subType = "Evasion",
	armour = { evasionBase = 11, },
	req = { },
}
itemBases["Goathide Boots"] = {
	type = "Boots",
	subType = "Evasion",
	armour = { evasionBase = 36, },
	req = { level = 12, dex = 26, },
}
itemBases["Deerskin Boots"] = {
	type = "Boots",
	subType = "Evasion",
	armour = { evasionBase = 64, },
	req = { level = 22, dex = 42, },
}
itemBases["Nubuck Boots"] = {
	type = "Boots",
	subType = "Evasion",
	armour = { evasionBase = 98, },
	req = { level = 34, dex = 62, },
}
itemBases["Eelskin Boots"] = {
	type = "Boots",
	subType = "Evasion",
	armour = { evasionBase = 112, },
	req = { level = 39, dex = 70, },
}
itemBases["Sharkskin Boots"] = {
	type = "Boots",
	subType = "Evasion",
	armour = { evasionBase = 126, },
	req = { level = 44, dex = 79, },
}
itemBases["Shagreen Boots"] = {
	type = "Boots",
	subType = "Evasion",
	armour = { evasionBase = 157, },
	req = { level = 55, dex = 97, },
}
itemBases["Stealth Boots"] = {
	type = "Boots",
	subType = "Evasion",
	armour = { evasionBase = 191, },
	req = { level = 62, dex = 117, },
}
itemBases["Slink Boots"] = {
	type = "Boots",
	subType = "Evasion",
	armour = { evasionBase = 214, },
	req = { level = 69, dex = 120, },
}


itemBases["Wool Shoes"] = {
	type = "Boots",
	subType = "Energy Shield",
	armour = { energyShieldBase = 4, },
	req = { },
}
itemBases["Velvet Slippers"] = {
	type = "Boots",
	subType = "Energy Shield",
	armour = { energyShieldBase = 9, },
	req = { level = 9, int = 21, },
}
itemBases["Silk Slippers"] = {
	type = "Boots",
	subType = "Energy Shield",
	armour = { energyShieldBase = 20, },
	req = { level = 22, int = 42, },
}
itemBases["Scholar Boots"] = {
	type = "Boots",
	subType = "Energy Shield",
	armour = { energyShieldBase = 28, },
	req = { level = 32, int = 59, },
}
itemBases["Satin Slippers"] = {
	type = "Boots",
	subType = "Energy Shield",
	armour = { energyShieldBase = 32, },
	req = { level = 38, int = 69, },
}
itemBases["Samite Slippers"] = {
	type = "Boots",
	subType = "Energy Shield",
	armour = { energyShieldBase = 37, },
	req = { level = 44, int = 79, },
}
itemBases["Conjurer Boots"] = {
	type = "Boots",
	subType = "Energy Shield",
	armour = { energyShieldBase = 44, },
	req = { level = 53, int = 94, },
}
itemBases["Arcanist Slippers"] = {
	type = "Boots",
	subType = "Energy Shield",
	armour = { energyShieldBase = 59, },
	req = { level = 61, int = 119, },
}
itemBases["Sorcerer Boots"] = {
	type = "Boots",
	subType = "Energy Shield",
	armour = { energyShieldBase = 64, },
	req = { level = 67, int = 123, },
}


itemBases["Leatherscale Boots"] = {
	type = "Boots",
	subType = "Armour/Evasion",
	armour = { armourBase = 11, evasionBase = 11, },
	req = { level = 6, },
}
itemBases["Ironscale Boots"] = {
	type = "Boots",
	subType = "Armour/Evasion",
	armour = { armourBase = 29, evasionBase = 29, },
	req = { level = 18, str = 19, dex = 19, },
}
itemBases["Bronzescale Boots"] = {
	type = "Boots",
	subType = "Armour/Evasion",
	armour = { armourBase = 48, evasionBase = 48, },
	req = { level = 30, str = 30, dex = 30, },
}
itemBases["Steelscale Boots"] = {
	type = "Boots",
	subType = "Armour/Evasion",
	armour = { armourBase = 57, evasionBase = 57, },
	req = { level = 36, str = 35, dex = 35, },
}
itemBases["Serpentscale Boots"] = {
	type = "Boots",
	subType = "Armour/Evasion",
	armour = { armourBase = 66, evasionBase = 66, },
	req = { level = 42, str = 40, dex = 40, },
}
itemBases["Wyrmscale Boots"] = {
	type = "Boots",
	subType = "Armour/Evasion",
	armour = { armourBase = 80, evasionBase = 80, },
	req = { level = 51, str = 48, dex = 48, },
}
itemBases["Hydrascale Boots"] = {
	type = "Boots",
	subType = "Armour/Evasion",
	armour = { armourBase = 92, evasionBase = 92, },
	req = { level = 59, str = 56, dex = 56, },
}
itemBases["Dragonscale Boots"] = {
	type = "Boots",
	subType = "Armour/Evasion",
	armour = { armourBase = 105, evasionBase = 105, },
	req = { level = 65, str = 62, dex = 62, },
}
itemBases["Two-Toned Boots (Armour/Evasion)"] = {
	type = "Boots",
	subType = "Armour/Evasion",
	implicit = "+(15-20)% to Fire and Cold Resistances",
	armour = { armourBase = 109, evasionBase = 109 },
	req = { level = 72, str = 62, dex = 62 },
}


itemBases["Chain Boots"] = {
	type = "Boots",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 9, energyShieldBase = 3, },
	req = { level = 5, },
}
itemBases["Ringmail Boots"] = {
	type = "Boots",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 22, energyShieldBase = 7, },
	req = { level = 13, str = 15, int = 15, },
}
itemBases["Mesh Boots"] = {
	type = "Boots",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 45, energyShieldBase = 13, },
	req = { level = 28, str = 28, int = 28, },
}
itemBases["Riveted Boots"] = {
	type = "Boots",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 57, energyShieldBase = 17, },
	req = { level = 36, str = 35, int = 35, },
}
itemBases["Zealot Boots"] = {
	type = "Boots",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 63, energyShieldBase = 19, },
	req = { level = 40, str = 38, int = 38, },
}
itemBases["Soldier Boots"] = {
	type = "Boots",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 77, energyShieldBase = 23, },
	req = { level = 49, str = 47, int = 47, },
}
itemBases["Legion Boots"] = {
	type = "Boots",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 91, energyShieldBase = 27, },
	req = { level = 58, str = 54, int = 54, },
}
itemBases["Crusader Boots"] = {
	type = "Boots",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 105, energyShieldBase = 31, },
	req = { level = 64, str = 62, int = 62, },
}
itemBases["Two-Toned Boots (Armour/Energy Shield)"] = {
	type = "Boots",
	subType = "Armour/Energy Shield",
	implicit = "+(15-20)% to Fire and Lightning Resistances",
	armour = { armourBase = 109, energyShieldBase = 32 },
	req = { level = 72, str = 62, int = 62 },
}


itemBases["Wrapped Boots"] = {
	type = "Boots",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 11, energyShieldBase = 4, },
	req = { level = 6, },
}
itemBases["Strapped Boots"] = {
	type = "Boots",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 26, energyShieldBase = 8, },
	req = { level = 16, dex = 18, int = 18, },
}
itemBases["Clasped Boots"] = {
	type = "Boots",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 43, energyShieldBase = 13, },
	req = { level = 27, dex = 27, int = 27, },
}
itemBases["Shackled Boots"] = {
	type = "Boots",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 54, energyShieldBase = 16, },
	req = { level = 34, dex = 34, int = 34, },
}
itemBases["Trapper Boots"] = {
	type = "Boots",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 65, energyShieldBase = 19, },
	req = { level = 41, dex = 40, int = 40, },
}
itemBases["Ambush Boots"] = {
	type = "Boots",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 74, energyShieldBase = 22, },
	req = { level = 47, dex = 45, int = 45, },
}
itemBases["Carnal Boots"] = {
	type = "Boots",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 86, energyShieldBase = 25, },
	req = { level = 55, dex = 52, int = 52, },
}
itemBases["Assassin's Boots"] = {
	type = "Boots",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 105, energyShieldBase = 31, },
	req = { level = 63, dex = 62, int = 62, },
}
itemBases["Murder Boots"] = {
	type = "Boots",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 161, energyShieldBase = 22, },
	req = { level = 69, dex = 82, int = 42, },
}
itemBases["Two-Toned Boots (Evasion/Energy Shield)"] = {
	type = "Boots",
	subType = "Evasion/Energy Shield",
	implicit = "+(15-20)% to Cold and Lightning Resistances",
	armour = { evasionBase = 109, energyShieldBase = 32 },
	req = { level = 72, dex = 62, int = 62 },
}