-- Path of Building
--
-- Module: Item Slot Icons
-- Provides the icon used for each item slot.
--
local M = { }

local slotMap = {
	["Weapon 1"] = "Assets/icon_weapon.png",
	["Weapon 2"] = "Assets/icon_weapon_2.png",
	["Weapon 1 Swap"] = "Assets/icon_weapon_swap.png",
	["Weapon 2 Swap"] = "Assets/icon_weapon_2_swap.png",
	["Bow"] = "Assets/icon_bow.png",
	["Quiver"] = "Assets/icon_quiver.png",
	["Shield"] = "Assets/icon_shield.png",
	["Shield Swap"] = "Assets/icon_shield_swap.png",
	["Helmet"] = "Assets/icon_helmet.png",
	["Body Armour"] = "Assets/icon_body_armour.png",
	["Gloves"] = "Assets/icon_gloves.png",
	["Boots"] = "Assets/icon_boots.png",
	["Amulet"] = "Assets/icon_amulet.png",
	["Ring 1"] = "Assets/icon_ring_left.png",
	["Ring 2"] = "Assets/icon_ring_right.png",
	["Ring 3"] = "Assets/icon_ring_right.png",
	["Belt"] = "Assets/icon_belt.png",
	["Jewel"] = "Assets/icon_jewel.png",
	["Flask 1"] = "Assets/icon_flask.png",
}

for slot, path in pairs(slotMap) do
	local icon = NewImageHandle()
	icon:Load(path)
	slotMap[slot] = icon
end

function M.Get(slot)
	return slotMap[slot]
end

return M
