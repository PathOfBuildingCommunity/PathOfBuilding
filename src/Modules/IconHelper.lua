local slot_map = {
    ["Weapon 1"] = { icon = NewImageHandle(), path = "Assets/icon_weapon.png" },
    ["Weapon 2"] = { icon = NewImageHandle(), path = "Assets/icon_weapon_2.png" },
    ["Weapon 1 Swap"] = { icon = NewImageHandle(), path = "Assets/icon_weapon_swap.png" },
    ["Weapon 2 Swap"] = { icon = NewImageHandle(), path = "Assets/icon_weapon_2_swap.png" },
    ["Bow"] = { icon = NewImageHandle(), path = "Assets/icon_bow.png" },
    ["Quiver"] = { icon = NewImageHandle(), path = "Assets/icon_quiver.png" },
    ["Shield"] = { icon = NewImageHandle(), path = "Assets/icon_shield.png" },
    ["Shield Swap"] = { icon = NewImageHandle(), path = "Assets/icon_shield_swap.png" },
    ["Helmet"] = { icon = NewImageHandle(), path = "Assets/icon_helmet.png" },
    ["Body Armour"] = { icon = NewImageHandle(), path = "Assets/icon_body_armour.png" },
    ["Gloves"] = { icon = NewImageHandle(), path = "Assets/icon_gloves.png" },
    ["Boots"] = { icon = NewImageHandle(), path = "Assets/icon_boots.png" },
    ["Amulet"] = { icon = NewImageHandle(), path = "Assets/icon_amulet.png" },
    ["Ring 1"] = { icon = NewImageHandle(), path = "Assets/icon_ring_left.png" },
    ["Ring 2"] = { icon = NewImageHandle(), path = "Assets/icon_ring_right.png" },
    ["Belt"] = { icon = NewImageHandle(), path = "Assets/icon_belt.png" },
    ["Jewel"] = { icon = NewImageHandle(), path = "Assets/icon_jewel.png" },
    ["Flask 1"] = { icon = NewImageHandle(), path = "Assets/icon_flask.png" },
}

for k, x in pairs(slot_map) do
    x.icon:Load(x.path)
end

icons = {}

function icons.getIconForSlot(slot)
    return slot_map[slot] and slot_map[slot].icon
end
