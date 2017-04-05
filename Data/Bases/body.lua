-- Item data (c) Grinding Gear Games
local itemBases = ...

itemBases["Plate Vest"] = {
	type = "Body Armour",
	subType = "Armour",
	armour = { armourBase = 14, movementPenalty = 3, },
	req = { },
}
itemBases["Chestplate"] = {
	type = "Body Armour",
	subType = "Armour",
	armour = { armourBase = 49, movementPenalty = 5, },
	req = { level = 6, str = 25, },
}
itemBases["Copper Plate"] = {
	type = "Body Armour",
	subType = "Armour",
	armour = { armourBase = 126, movementPenalty = 5, },
	req = { level = 17, str = 53, },
}
itemBases["War Plate"] = {
	type = "Body Armour",
	subType = "Armour",
	armour = { armourBase = 154, movementPenalty = 5, },
	req = { level = 21, str = 63, },
}
itemBases["Full Plate"] = {
	type = "Body Armour",
	subType = "Armour",
	armour = { armourBase = 203, movementPenalty = 5, },
	req = { level = 28, str = 81, },
}
itemBases["Arena Plate"] = {
	type = "Body Armour",
	subType = "Armour",
	armour = { armourBase = 231, movementPenalty = 5, },
	req = { level = 32, str = 91, },
}
itemBases["Lordly Plate"] = {
	type = "Body Armour",
	subType = "Armour",
	armour = { armourBase = 252, movementPenalty = 5, },
	req = { level = 35, str = 99, },
}
itemBases["Bronze Plate"] = {
	type = "Body Armour",
	subType = "Armour",
	armour = { armourBase = 266, movementPenalty = 5, },
	req = { level = 37, str = 104, },
}
itemBases["Battle Plate"] = {
	type = "Body Armour",
	subType = "Armour",
	armour = { armourBase = 294, movementPenalty = 5, },
	req = { level = 41, str = 114, },
}
itemBases["Sun Plate"] = {
	type = "Body Armour",
	subType = "Armour",
	armour = { armourBase = 322, movementPenalty = 5, },
	req = { level = 45, str = 124, },
}
itemBases["Colosseum Plate"] = {
	type = "Body Armour",
	subType = "Armour",
	armour = { armourBase = 350, movementPenalty = 5, },
	req = { level = 49, str = 134, },
}
itemBases["Majestic Plate"] = {
	type = "Body Armour",
	subType = "Armour",
	armour = { armourBase = 378, movementPenalty = 5, },
	req = { level = 53, str = 144, },
}
itemBases["Golden Plate"] = {
	type = "Body Armour",
	subType = "Armour",
	armour = { armourBase = 399, movementPenalty = 5, },
	req = { level = 56, str = 152, },
}
itemBases["Crusader Plate"] = {
	type = "Body Armour",
	subType = "Armour",
	armour = { armourBase = 428, movementPenalty = 5, },
	req = { level = 59, str = 160, },
}
itemBases["Astral Plate"] = {
	type = "Body Armour",
	subType = "Armour",
	implicit = "+(8-12)% to all Elemental Resistances",
	armour = { armourBase = 507, movementPenalty = 5, },
	req = { level = 62, str = 180, },
}
itemBases["Gladiator Plate"] = {
	type = "Body Armour",
	subType = "Armour",
	armour = { armourBase = 526, movementPenalty = 5, },
	req = { level = 65, str = 177, },
}
itemBases["Glorious Plate"] = {
	type = "Body Armour",
	subType = "Armour",
	armour = { armourBase = 553, },
	req = { level = 68, str = 191, },
}


itemBases["Shabby Jerkin"] = {
	type = "Body Armour",
	subType = "Evasion",
	armour = { evasionBase = 21, movementPenalty = 3, },
	req = { dex = 14, },
}
itemBases["Strapped Leather"] = {
	type = "Body Armour",
	subType = "Evasion",
	armour = { evasionBase = 70, movementPenalty = 3, },
	req = { level = 9, dex = 32, },
}
itemBases["Buckskin Tunic"] = {
	type = "Body Armour",
	subType = "Evasion",
	armour = { evasionBase = 126, movementPenalty = 3, },
	req = { level = 17, dex = 53, },
}
itemBases["Wild Leather"] = {
	type = "Body Armour",
	subType = "Evasion",
	armour = { evasionBase = 182, movementPenalty = 3, },
	req = { level = 25, dex = 73, },
}
itemBases["Full Leather"] = {
	type = "Body Armour",
	subType = "Evasion",
	armour = { evasionBase = 203, movementPenalty = 3, },
	req = { level = 28, dex = 81, },
}
itemBases["Sun Leather"] = {
	type = "Body Armour",
	subType = "Evasion",
	armour = { evasionBase = 231, movementPenalty = 3, },
	req = { level = 32, dex = 91, },
}
itemBases["Thief's Garb"] = {
	type = "Body Armour",
	subType = "Evasion",
	armour = { evasionBase = 252, movementPenalty = 3, },
	req = { level = 35, dex = 99, },
}
itemBases["Eelskin Tunic"] = {
	type = "Body Armour",
	subType = "Evasion",
	armour = { evasionBase = 266, movementPenalty = 3, },
	req = { level = 37, dex = 104, },
}
itemBases["Frontier Leather"] = {
	type = "Body Armour",
	subType = "Evasion",
	armour = { evasionBase = 294, movementPenalty = 3, },
	req = { level = 41, dex = 114, },
}
itemBases["Glorious Leather"] = {
	type = "Body Armour",
	subType = "Evasion",
	armour = { evasionBase = 322, movementPenalty = 3, },
	req = { level = 45, dex = 124, },
}
itemBases["Coronal Leather"] = {
	type = "Body Armour",
	subType = "Evasion",
	armour = { evasionBase = 350, movementPenalty = 3, },
	req = { level = 49, dex = 134, },
}
itemBases["Cutthroat's Garb"] = {
	type = "Body Armour",
	subType = "Evasion",
	armour = { evasionBase = 378, movementPenalty = 3, },
	req = { level = 53, dex = 144, },
}
itemBases["Sharkskin Tunic"] = {
	type = "Body Armour",
	subType = "Evasion",
	armour = { evasionBase = 399, movementPenalty = 3, },
	req = { level = 56, dex = 152, },
}
itemBases["Destiny Leather"] = {
	type = "Body Armour",
	subType = "Evasion",
	armour = { evasionBase = 428, movementPenalty = 3, },
	req = { level = 59, dex = 160, },
}
itemBases["Exquisite Leather"] = {
	type = "Body Armour",
	subType = "Evasion",
	armour = { evasionBase = 502, movementPenalty = 3, },
	req = { level = 62, dex = 170, },
}
itemBases["Zodiac Leather"] = {
	type = "Body Armour",
	subType = "Evasion",
	armour = { evasionBase = 609, movementPenalty = 3, },
	req = { level = 65, dex = 197, },
}
itemBases["Assassin's Garb"] = {
	type = "Body Armour",
	subType = "Evasion",
	implicit = "3% increased Movement Speed",
	armour = { evasionBase = 525, },
	req = { level = 68, dex = 183, },
}


itemBases["Simple Robe"] = {
	type = "Body Armour",
	subType = "Energy Shield",
	armour = { energyShieldBase = 11, movementPenalty = 3, },
	req = { int = 17, },
}
itemBases["Silken Vest"] = {
	type = "Body Armour",
	subType = "Energy Shield",
	armour = { energyShieldBase = 27, movementPenalty = 3, },
	req = { level = 11, int = 37, },
}
itemBases["Scholar's Robe"] = {
	type = "Body Armour",
	subType = "Energy Shield",
	armour = { energyShieldBase = 41, movementPenalty = 3, },
	req = { level = 18, int = 55, },
}
itemBases["Silken Garb"] = {
	type = "Body Armour",
	subType = "Energy Shield",
	armour = { energyShieldBase = 55, movementPenalty = 3, },
	req = { level = 25, int = 73, },
}
itemBases["Mage's Vestment"] = {
	type = "Body Armour",
	subType = "Energy Shield",
	armour = { energyShieldBase = 61, movementPenalty = 3, },
	req = { level = 28, int = 81, },
}
itemBases["Silk Robe"] = {
	type = "Body Armour",
	subType = "Energy Shield",
	armour = { energyShieldBase = 69, movementPenalty = 3, },
	req = { level = 32, int = 91, },
}
itemBases["Cabalist Regalia"] = {
	type = "Body Armour",
	subType = "Energy Shield",
	armour = { energyShieldBase = 75, movementPenalty = 3, },
	req = { level = 35, int = 99, },
}
itemBases["Sage's Robe"] = {
	type = "Body Armour",
	subType = "Energy Shield",
	armour = { energyShieldBase = 79, movementPenalty = 3, },
	req = { level = 37, int = 104, },
}
itemBases["Silken Wrap"] = {
	type = "Body Armour",
	subType = "Energy Shield",
	armour = { energyShieldBase = 87, movementPenalty = 3, },
	req = { level = 41, int = 114, },
}
itemBases["Conjurer's Vestment"] = {
	type = "Body Armour",
	subType = "Energy Shield",
	armour = { energyShieldBase = 95, movementPenalty = 3, },
	req = { level = 45, int = 124, },
}
itemBases["Spidersilk Robe"] = {
	type = "Body Armour",
	subType = "Energy Shield",
	armour = { energyShieldBase = 103, movementPenalty = 3, },
	req = { level = 49, int = 134, },
}
itemBases["Destroyer Regalia"] = {
	type = "Body Armour",
	subType = "Energy Shield",
	armour = { energyShieldBase = 111, movementPenalty = 3, },
	req = { level = 53, int = 144, },
}
itemBases["Savant's Robe"] = {
	type = "Body Armour",
	subType = "Energy Shield",
	armour = { energyShieldBase = 117, movementPenalty = 3, },
	req = { level = 56, int = 152, },
}
itemBases["Necromancer Silks"] = {
	type = "Body Armour",
	subType = "Energy Shield",
	armour = { energyShieldBase = 125, movementPenalty = 3, },
	req = { level = 59, int = 160, },
}
itemBases["Occultist's Vestment"] = {
	type = "Body Armour",
	subType = "Energy Shield",
	implicit = "(3-10)% increased Spell Damage",
	armour = { energyShieldBase = 140, movementPenalty = 3, },
	req = { level = 62, int = 180, },
}
itemBases["Widowsilk Robe"] = {
	type = "Body Armour",
	subType = "Energy Shield",
	armour = { energyShieldBase = 161, movementPenalty = 3, },
	req = { level = 65, int = 187, },
}
itemBases["Vaal Regalia"] = {
	type = "Body Armour",
	subType = "Energy Shield",
	armour = { energyShieldBase = 175, movementPenalty = 3, },
	req = { level = 68, int = 194, },
}


itemBases["Scale Vest"] = {
	type = "Body Armour",
	subType = "Armour/Evasion",
	armour = { armourBase = 19, evasionBase = 19, movementPenalty = 3, },
	req = { },
}
itemBases["Light Brigandine"] = {
	type = "Body Armour",
	subType = "Armour/Evasion",
	armour = { armourBase = 35, evasionBase = 35, movementPenalty = 3, },
	req = { level = 8, str = 16, dex = 16, },
}
itemBases["Scale Doublet"] = {
	type = "Body Armour",
	subType = "Armour/Evasion",
	armour = { armourBase = 69, evasionBase = 69, movementPenalty = 3, },
	req = { level = 17, str = 28, dex = 28, },
}
itemBases["Infantry Brigandine"] = {
	type = "Body Armour",
	subType = "Armour/Evasion",
	armour = { armourBase = 85, evasionBase = 85, movementPenalty = 3, },
	req = { level = 21, str = 34, dex = 34, },
}
itemBases["Full Scale Armour"] = {
	type = "Body Armour",
	subType = "Armour/Evasion",
	armour = { armourBase = 112, evasionBase = 112, movementPenalty = 3, },
	req = { level = 28, str = 43, dex = 43, },
}
itemBases["Soldier's Brigandine"] = {
	type = "Body Armour",
	subType = "Armour/Evasion",
	armour = { armourBase = 127, evasionBase = 127, movementPenalty = 3, },
	req = { level = 32, str = 48, dex = 48, },
}
itemBases["Field Lamellar"] = {
	type = "Body Armour",
	subType = "Armour/Evasion",
	armour = { armourBase = 138, evasionBase = 138, movementPenalty = 3, },
	req = { level = 35, str = 53, dex = 53, },
}
itemBases["Wyrmscale Doublet"] = {
	type = "Body Armour",
	subType = "Armour/Evasion",
	armour = { armourBase = 150, evasionBase = 150, movementPenalty = 3, },
	req = { level = 38, str = 57, dex = 57, },
}
itemBases["Hussar Brigandine"] = {
	type = "Body Armour",
	subType = "Armour/Evasion",
	armour = { armourBase = 165, evasionBase = 165, movementPenalty = 3, },
	req = { level = 42, str = 62, dex = 62, },
}
itemBases["Full Wyrmscale"] = {
	type = "Body Armour",
	subType = "Armour/Evasion",
	armour = { armourBase = 181, evasionBase = 181, movementPenalty = 3, },
	req = { level = 46, str = 68, dex = 68, },
}
itemBases["Commander's Brigandine"] = {
	type = "Body Armour",
	subType = "Armour/Evasion",
	armour = { armourBase = 196, evasionBase = 196, movementPenalty = 3, },
	req = { level = 50, str = 73, dex = 73, },
}
itemBases["Battle Lamellar"] = {
	type = "Body Armour",
	subType = "Armour/Evasion",
	armour = { armourBase = 212, evasionBase = 212, movementPenalty = 3, },
	req = { level = 54, str = 79, dex = 79, },
}
itemBases["Dragonscale Doublet"] = {
	type = "Body Armour",
	subType = "Armour/Evasion",
	armour = { armourBase = 223, evasionBase = 223, movementPenalty = 3, },
	req = { level = 57, str = 83, dex = 83, },
}
itemBases["Desert Brigandine"] = {
	type = "Body Armour",
	subType = "Armour/Evasion",
	armour = { armourBase = 268, evasionBase = 268, movementPenalty = 3, },
	req = { level = 60, str = 96, dex = 96, },
}
itemBases["Full Dragonscale"] = {
	type = "Body Armour",
	subType = "Armour/Evasion",
	armour = { armourBase = 335, evasionBase = 266, movementPenalty = 3, },
	req = { level = 63, str = 115, dex = 94, },
}
itemBases["General's Brigandine"] = {
	type = "Body Armour",
	subType = "Armour/Evasion",
	armour = { armourBase = 296, evasionBase = 296, movementPenalty = 3, },
	req = { level = 66, str = 103, dex = 103, },
}
itemBases["Triumphant Lamellar"] = {
	type = "Body Armour",
	subType = "Armour/Evasion",
	armour = { armourBase = 271, evasionBase = 340, movementPenalty = 3, },
	req = { level = 69, str = 95, dex = 116, },
}


itemBases["Chainmail Vest"] = {
	type = "Body Armour",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 19, energyShieldBase = 7, movementPenalty = 5, },
	req = { },
}
itemBases["Chainmail Tunic"] = {
	type = "Body Armour",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 35, energyShieldBase = 11, movementPenalty = 5, },
	req = { level = 8, str = 16, int = 16, },
}
itemBases["Ringmail Coat"] = {
	type = "Body Armour",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 69, energyShieldBase = 21, movementPenalty = 5, },
	req = { level = 17, str = 28, int = 28, },
}
itemBases["Chainmail Doublet"] = {
	type = "Body Armour",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 85, energyShieldBase = 26, movementPenalty = 5, },
	req = { level = 21, str = 34, int = 34, },
}
itemBases["Full Ringmail"] = {
	type = "Body Armour",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 112, energyShieldBase = 33, movementPenalty = 5, },
	req = { level = 28, str = 43, int = 43, },
}
itemBases["Full Chainmail"] = {
	type = "Body Armour",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 127, energyShieldBase = 38, movementPenalty = 5, },
	req = { level = 32, str = 48, int = 48, },
}
itemBases["Holy Chainmail"] = {
	type = "Body Armour",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 138, energyShieldBase = 41, movementPenalty = 5, },
	req = { level = 35, str = 53, int = 53, },
}
itemBases["Latticed Ringmail"] = {
	type = "Body Armour",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 154, energyShieldBase = 46, movementPenalty = 5, },
	req = { level = 39, str = 59, int = 59, },
}
itemBases["Crusader Chainmail"] = {
	type = "Body Armour",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 169, energyShieldBase = 50, movementPenalty = 5, },
	req = { level = 43, str = 64, int = 64, },
}
itemBases["Ornate Ringmail"] = {
	type = "Body Armour",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 185, energyShieldBase = 54, movementPenalty = 5, },
	req = { level = 47, str = 69, int = 69, },
}
itemBases["Chain Hauberk"] = {
	type = "Body Armour",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 200, energyShieldBase = 59, movementPenalty = 5, },
	req = { level = 51, str = 75, int = 75, },
}
itemBases["Devout Chainmail"] = {
	type = "Body Armour",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 215, energyShieldBase = 63, movementPenalty = 5, },
	req = { level = 55, str = 80, int = 80, },
}
itemBases["Loricated Ringmail"] = {
	type = "Body Armour",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 232, energyShieldBase = 68, movementPenalty = 5, },
	req = { level = 58, str = 84, int = 84, },
}
itemBases["Conquest Chainmail"] = {
	type = "Body Armour",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 276, energyShieldBase = 81, movementPenalty = 5, },
	req = { level = 61, str = 96, int = 96, },
}
itemBases["Elegant Ringmail"] = {
	type = "Body Armour",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 269, energyShieldBase = 94, movementPenalty = 5, },
	req = { level = 64, str = 90, int = 105, },
}
itemBases["Saint's Hauberk"] = {
	type = "Body Armour",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 315, energyShieldBase = 78, movementPenalty = 5, },
	req = { level = 67, str = 109, int = 94, },
}
itemBases["Saintly Chainmail"] = {
	type = "Body Armour",
	subType = "Armour/Energy Shield",
	armour = { armourBase = 286, energyShieldBase = 98, movementPenalty = 5, },
	req = { level = 70, str = 99, int = 115, },
}


itemBases["Padded Vest"] = {
	type = "Body Armour",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 19, energyShieldBase = 7, movementPenalty = 3, },
	req = { },
}
itemBases["Oiled Vest"] = {
	type = "Body Armour",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 38, energyShieldBase = 13, movementPenalty = 3, },
	req = { level = 9, dex = 17, int = 17, },
}
itemBases["Padded Jacket"] = {
	type = "Body Armour",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 73, energyShieldBase = 22, movementPenalty = 3, },
	req = { level = 18, dex = 30, int = 30, },
}
itemBases["Oiled Coat"] = {
	type = "Body Armour",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 88, energyShieldBase = 27, movementPenalty = 3, },
	req = { level = 22, dex = 35, int = 35, },
}
itemBases["Scarlet Raiment"] = {
	type = "Body Armour",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 112, energyShieldBase = 33, movementPenalty = 3, },
	req = { level = 28, dex = 43, int = 43, },
}
itemBases["Waxed Garb"] = {
	type = "Body Armour",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 127, energyShieldBase = 38, movementPenalty = 3, },
	req = { level = 32, dex = 48, int = 48, },
}
itemBases["Bone Armour"] = {
	type = "Body Armour",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 138, energyShieldBase = 41, movementPenalty = 3, },
	req = { level = 35, dex = 53, int = 53, },
}
itemBases["Quilted Jacket"] = {
	type = "Body Armour",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 158, energyShieldBase = 47, movementPenalty = 3, },
	req = { level = 40, dex = 60, int = 60, },
}
itemBases["Sleek Coat"] = {
	type = "Body Armour",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 173, energyShieldBase = 51, movementPenalty = 3, },
	req = { level = 44, dex = 65, int = 65, },
}
itemBases["Crimson Raiment"] = {
	type = "Body Armour",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 189, energyShieldBase = 55, movementPenalty = 3, },
	req = { level = 48, dex = 71, int = 71, },
}
itemBases["Lacquered Garb"] = {
	type = "Body Armour",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 204, energyShieldBase = 60, movementPenalty = 3, },
	req = { level = 52, dex = 76, int = 76, },
}
itemBases["Crypt Armour"] = {
	type = "Body Armour",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 219, energyShieldBase = 64, movementPenalty = 3, },
	req = { level = 56, dex = 82, int = 82, },
}
itemBases["Sentinel Jacket"] = {
	type = "Body Armour",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 235, energyShieldBase = 69, movementPenalty = 3, },
	req = { level = 59, dex = 86, int = 86, },
}
itemBases["Varnished Coat"] = {
	type = "Body Armour",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 276, energyShieldBase = 81, movementPenalty = 3, },
	req = { level = 62, dex = 96, int = 96, },
}
itemBases["Blood Raiment"] = {
	type = "Body Armour",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 311, energyShieldBase = 75, movementPenalty = 3, },
	req = { level = 65, dex = 107, int = 90, },
}
itemBases["Sadist Garb"] = {
	type = "Body Armour",
	subType = "Evasion/Energy Shield",
	armour = { evasionBase = 304, energyShieldBase = 95, movementPenalty = 3, },
	req = { level = 68, dex = 103, int = 109, },
}
itemBases["Carnal Armour"] = {
	type = "Body Armour",
	subType = "Evasion/Energy Shield",
	implicit = "+(20-25) to maximum Mana",
	armour = { evasionBase = 251, energyShieldBase = 105, movementPenalty = 3, },
	req = { level = 71, dex = 88, int = 122, },
}


itemBases["Sacrificial Garb"] = {
	type = "Body Armour",
	subType = "Armour/Evasion/Energy Shield",
	armour = { armourBase = 234, evasionBase = 234, energyShieldBase = 69, movementPenalty = 3 },
	req = { level = 72, str = 66, dex = 66, int = 66, },
}
