-- Path of Building
--
-- Module: MCP Tools - Items
-- The Items tab: equipped items and item sets, the unique and rare template
-- databases, crafting with the tab's own controls and dialogs, and the
-- weighted trade search of PoB's trader.
--
local T = ...

local t_insert = table.insert
local t_concat = table.concat
local s_format = string.format
local m_min = math.min
local m_max = math.max

local dkjson = require("dkjson")
local tradeHelpers = require("Classes.TradeHelpers")

------------------------------------------------------------------------------
-- Shared helpers
------------------------------------------------------------------------------

local MOD_LINE_LISTS = { "enchantModLines", "scourgeModLines", "implicitModLines", "explicitModLines", "crucibleModLines" }

-- The text of a dropdown or list entry, without colour codes.
local function labelOf(entry)
	if type(entry) == "table" then
		entry = entry.label or entry.name
	end
	return T.Clean(tostring(entry or ""))
end

-- Selects a dropdown entry as a click does.
local function choose(control, index)
	control.selIndex = index
	if control.selFunc then
		control.selFunc(index, control.list[index])
	end
end

-- The index of the entry of a PoB list the client named: an entry isMatch
-- recognises (an id), the label (case-insensitive, without colour codes), or a
-- unique part of a label.
local function pick(list, want, what, isMatch, first)
	first = first or 1
	local wanted = T.Clean(tostring(want)):lower()
	local partial = { }
	for i = first, #list do
		local entry = list[i]
		if isMatch and isMatch(entry, want) then
			return i
		end
		local label = labelOf(entry):lower()
		if label == wanted then
			return i
		end
		if wanted ~= "" and label:find(wanted, 1, true) then
			t_insert(partial, i)
		end
	end
	if #partial == 1 then
		return partial[1]
	end
	local names = { }
	if #partial > 1 then
		for k = 1, m_min(#partial, 10) do
			t_insert(names, labelOf(list[partial[k]]))
		end
		T.Fail("The %s '%s' matches %d options, for example: %s. Give more of the text.", what, tostring(want), #partial, t_concat(names, " | "))
	end
	if #list - first + 1 <= 30 then
		for i = first, #list do
			t_insert(names, labelOf(list[i]))
		end
		T.Fail("No %s matches '%s'. Options: %s", what, tostring(want), t_concat(names, " | "))
	end
	T.Fail("No %s matches '%s'; leave it out to list the options.", what, tostring(want))
end

-- The entry of a "Sort by" list (data.powerStatList entries) for a stat key or label.
local function findSortIndex(list, sortBy)
	local wanted = (tostring(sortBy):lower():gsub("^sort by ", ""))
	local names = { }
	for i, entry in ipairs(list) do
		if type(entry) == "table" then
			local label = ((entry.label or ""):lower():gsub("^sort by ", ""))
			if (entry.stat and entry.stat:lower() == wanted) or label == wanted then
				return i
			end
			t_insert(names, entry.stat or (entry.label or ""):gsub("^Sort by ", ""))
		end
	end
	T.Fail("Unknown sort '%s'. Sort by one of: %s", tostring(sortBy), t_concat(names, ", "))
end

-- Lines a PoB item shows (enchants, implicits, explicits), for the selected variant.
local function modLines(item)
	local lines = { }
	for _, key in ipairs(MOD_LINE_LISTS) do
		for _, modLine in ipairs(item[key] or { }) do
			if item:CheckModLineVariant(modLine) then
				local line = itemLib.formatModLine(modLine)
				if line then
					t_insert(lines, T.Clean(line))
				end
			end
		end
	end
	return lines
end

-- Sockets as written in item text ("R-G-B B").
local function socketString(item)
	if not item.sockets or not item.sockets[1] then
		return nil
	end
	local parts = { }
	for i, socket in ipairs(item.sockets) do
		if i > 1 then
			t_insert(parts, socket.group == item.sockets[i - 1].group and "-" or " ")
		end
		t_insert(parts, socket.color)
	end
	return t_concat(parts)
end

-- An item as reported to the client; detail gives the full text PoB copies
-- (Ctrl+C in the item list: Item:BuildRaw).
local function describeItem(item, detail)
	local entry = {
		id = item.id,
		name = item.name,
		rarity = item.rarity,
		base = item.baseName,
		type = item.type,
	}
	if detail then
		entry.text = item:BuildRaw()
	else
		entry.quality = item.quality and item.quality > 0 and item.quality or nil
		entry.sockets = socketString(item)
		entry.corrupted = item.corrupted or nil
		entry.mods = T.Array(modLines(item))
	end
	return entry
end

-- An item already in the build, by id or name.
local function findItem(itemsTab, ref)
	local id = tonumber(ref)
	if id then
		local item = itemsTab.items[id]
		if not item then
			T.Fail("The build has no item with id %d; items_get lists the items and their ids.", id)
		end
		return item
	end
	local list = { }
	for _, itemId in ipairs(itemsTab.itemOrderList) do
		t_insert(list, itemsTab.items[itemId])
	end
	return T.Find(list, ref, function(item)
		return item.name
	end, "item in the build")
end

local function slotLabel(slot)
	return slot.label or slot.slotName
end

------------------------------------------------------------------------------
-- items_get
------------------------------------------------------------------------------

local function setTitle(itemSet)
	return itemSet.title or "Default"
end

local function listSets(itemsTab)
	local sets = { }
	for position, setId in ipairs(itemsTab.itemSetOrderList) do
		t_insert(sets, { position = position, title = setTitle(itemsTab.itemSets[setId]), active = setId == itemsTab.activeItemSetId })
	end
	return sets
end

T.Tool {
	name = "items_get",
	title = "Equipped items",
	description = "Returns what the Items tab shows for the open build: the active item set's equipped items by slot (weapons, both "
		.. "weapon sets when weapon swap is used, armour, jewellery, flasks and tinctures with whether each is switched on, abyssal "
		.. "sockets, and the jewels in allocated passive tree sockets), which visible slots are empty, the list of item sets, and the "
		.. "build's other items (not equipped in the active set), paged. Each item has its id (for items_equip), name, rarity, base "
		.. "and type, and either a short summary (quality, sockets, the modifier lines PoB shows) or, with detail, the full item text "
		.. "exactly as PoB copies it. Use it before recommending or changing items; it changes nothing.",
	readOnly = true,
	idempotent = true,
	input = {
		detail = { type = "boolean", description = "Return each item's full text (as PoB copies it) instead of a short summary." },
		slot = { type = "string", description = "Only this slot, for example 'Helmet', 'Ring 2', 'Flask 1', 'Weapon 1 Swap' or 'Socket #2'." },
		limit = T.PageArgs(25).limit,
		offset = T.PageArgs(25).offset,
	},
	run = function(args)
		local build = T.Build()
		local itemsTab = build.itemsTab
		-- As the tab does when drawing or showing a tooltip: socket labels and which sockets are allocated.
		itemsTab:UpdateSockets()
		local activeWeaponSet = itemsTab.activeItemSet.useSecondWeaponSet and 2 or 1
		local onlySlot = args.slot and T.FindSlot(build, args.slot)
		local equipped, empty = { }, { }
		local inActiveSet = { }
		for _, slot in ipairs(itemsTab.orderedSlots) do
			local otherWeaponSet = slot.weaponSet and slot.weaponSet ~= activeWeaponSet
			if not slot.inactive and (slot:IsShown() or otherWeaponSet) and (not onlySlot or onlySlot == slot) then
				local item = itemsTab.items[slot.selItemId]
				if item then
					inActiveSet[item.id] = true
					local entry = describeItem(item, args.detail)
					entry.slot = slot.slotName
					entry.label = slotLabel(slot)
					if slot.controls.activate then
						entry.active = slot.active and true or false
					end
					if otherWeaponSet then
						entry.inactiveWeaponSet = true
					end
					t_insert(equipped, entry)
				elseif not otherWeaponSet then
					t_insert(empty, slot.nodeId and (slotLabel(slot) .. " (" .. slot.slotName .. ")") or slot.slotName)
				end
			end
		end
		local result = {
			itemSet = setTitle(itemsTab.activeItemSet),
			weaponSet = activeWeaponSet,
			equipped = T.Array(equipped),
			emptySlots = T.Array(empty),
		}
		if onlySlot then
			return result
		end
		result.itemSets = listSets(itemsTab)
		local others = { }
		local itemList = itemsTab.controls.itemList
		for _, itemId in ipairs(itemsTab.itemOrderList) do
			local item = itemsTab.items[itemId]
			if item and not inActiveSet[itemId] then
				local entry = describeItem(item, args.detail)
				local _, otherSet = itemsTab:GetEquippedSlotForItem(item)
				local usedIn = otherSet and ("item set '" .. setTitle(otherSet) .. "'")
				if not usedIn then
					local tree = itemList:FindSocketedJewel(itemId, true)
					usedIn = tree and ("passive tree '" .. tree .. "'")
				end
				if not usedIn then
					local abyssSet = itemList:FindEquippedAbyssJewel(itemId, true)
					usedIn = abyssSet and ("item set '" .. abyssSet .. "'")
				end
				entry.usedIn = usedIn
				t_insert(others, entry)
			end
		end
		result.otherItems, result.otherItemsPage = T.Page(others, args, 25)
		return result
	end,
}

------------------------------------------------------------------------------
-- items_equip
------------------------------------------------------------------------------

T.Tool {
	name = "items_equip",
	title = "Equip or remove items",
	description = "Changes the open build's items as the Items tab does. action 'equip': with 'item' (item text copied from the game, "
		.. "a trade site or PoB) the item is added to the build with PoB's paste normalisation (quality raised to 20 where PoB "
		.. "assumes it, and the anoint and eldritch implicits of the item it replaces copied over, as pasting into the Items tab "
		.. "does) and equipped in 'slot'; without 'slot' it goes into the first empty slot that fits, like 'Add to build', or is only "
		.. "added with add_only. With 'item_ref' (an item id or name from items_get) an item already in the build is equipped, in "
		.. "'slot' or its usual slot. action 'unequip' empties 'slot' (the item stays in the build). action 'set_active' switches a "
		.. "flask or tincture on or off, like the slot's check box. action 'remove' deletes 'item_ref' from the build and every item "
		.. "set; only use it when the user explicitly asked to delete the item. To measure a change first, use simulate. The result "
		.. "says what was equipped or replaced and lists the side-bar stat changes.",
	modifies = true,
	destructive = true,
	input = {
		action = { type = "string", enum = { "equip", "unequip", "set_active", "remove" }, description = "What to do." },
		slot = { type = "string", description = "Slot name or label, for example 'Helmet', 'Ring 2', 'Weapon 1 Swap', 'Flask 3', 'Socket #2', 'Helmet Abyssal Socket 1'." },
		item = { type = "string", maxLength = 20000, description = "equip: the item text to add and equip." },
		item_ref = { type = { "string", "integer" }, description = "equip/remove: an item already in the build, by id or name (see items_get)." },
		add_only = { type = "boolean", description = "equip with 'item' and no slot: add the item to the build without equipping it." },
		active = { type = "boolean", description = "set_active: true switches the flask or tincture on, false off." },
	},
	required = { "action" },
	run = function(args, ctx)
		local build = T.Build()
		local itemsTab = build.itemsTab
		itemsTab:UpdateSockets()
		local action = args.action
		local slot = args.slot and T.FindSlot(build, args.slot)
		local function finish()
			itemsTab:PopulateSlots()
			itemsTab:AddUndoState()
			build.buildFlag = true
			ctx:Changed()
		end

		if action == "equip" then
			if (args.item ~= nil) == (args.item_ref ~= nil) then
				T.Fail("Give either item (new item text) or item_ref (an item already in the build).")
			end
			local item, isNew
			if args.item then
				item = T.ParseItem(build, args.item, slot and slot.slotName)
				isNew = true
			else
				item = findItem(itemsTab, args.item_ref)
				if not slot then
					-- As Ctrl+click in the item list: the item's primary slot, in the weapon set in use.
					local slotName = item:GetPrimarySlot()
					if not itemsTab.slots[slotName] then
						T.Fail("%s has no single usual slot; give slot.", item.name)
					end
					if itemsTab.slots[slotName].weaponSet == 1 and itemsTab.activeItemSet.useSecondWeaponSet then
						slotName = slotName .. " Swap"
					end
					slot = itemsTab.slots[slotName]
				end
			end
			if slot then
				if slot.inactive then
					T.Fail("%s is not available (an unallocated jewel socket, or an abyssal socket the item there does not have).", slotLabel(slot))
				end
				if not itemsTab:IsItemValidForSlot(item, slot.slotName) then
					T.Fail("%s cannot be equipped in %s.", item.name, slotLabel(slot))
				end
			end
			local replaced = slot and itemsTab.items[slot.selItemId]
			if isNew then
				itemsTab:AddItem(item, slot ~= nil or args.add_only == true)
			end
			if slot then
				slot:SetSelItemId(item.id)
			end
			if isNew then
				itemsTab:AddForbiddenJewelCounterpart(item)
			end
			finish()
			local where = itemsTab:GetEquippedSlotForItem(item)
			local result = {
				item = describeItem(item),
				added = isNew or nil,
				equippedIn = where and where.selItemId == item.id and where.slotName or nil,
				replaced = replaced and replaced ~= item and replaced.name or nil,
			}
			if slot and slot.selItemId ~= item.id then
				result.note = "Path of Building did not keep the item in " .. slotLabel(slot) .. "; check the slot with items_get."
			elseif not slot and not result.equippedIn and not args.add_only then
				result.note = "No empty slot fits this item, so it was only added to the build; equip it with item_ref and slot."
			end
			return result
		elseif action == "unequip" then
			if not slot then
				T.Fail("slot is required for unequip.")
			end
			local item = itemsTab.items[slot.selItemId]
			if not item then
				T.Fail("Nothing is equipped in %s.", slotLabel(slot))
			end
			slot:SetSelItemId(0)
			finish()
			return { unequipped = item.name, slot = slot.slotName, note = "The item stays in the build's item list." }
		elseif action == "set_active" then
			if not slot or not slot.controls.activate then
				T.Fail("set_active needs a flask slot, for example 'Flask 1'.")
			end
			if args.active == nil then
				T.Fail("active is required for set_active.")
			end
			local item = itemsTab.items[slot.selItemId]
			if not item then
				T.Fail("Nothing is equipped in %s.", slotLabel(slot))
			end
			local checkBox = slot.controls.activate
			if (slot.active and true or false) ~= args.active then
				-- The slot's check box.
				checkBox.state = args.active
				checkBox.changeFunc(args.active)
				ctx:Changed()
			end
			return { slot = slot.slotName, item = item.name, active = slot.active and true or false }
		else
			if args.item_ref == nil then
				T.Fail("item_ref is required for remove.")
			end
			local item = findItem(itemsTab, args.item_ref)
			local equippedSlot, equippedSet = itemsTab:GetEquippedSlotForItem(item)
			-- What the item list's Delete does once confirmed.
			itemsTab:DeleteItem(item)
			itemsTab.controls.itemList:UpdateList()
			build.buildFlag = true
			ctx:Changed()
			local wasIn = equippedSlot and (slotLabel(equippedSlot) .. (equippedSet and (" in item set '" .. setTitle(equippedSet) .. "'") or "")) or nil
			return { removed = item.name, wasEquippedIn = wasIn }
		end
	end,
}

------------------------------------------------------------------------------
-- items_sets
------------------------------------------------------------------------------

local function findSet(itemsTab, ref)
	local order = itemsTab.itemSetOrderList
	if type(ref) == "number" then
		if ref < 1 or ref > #order or ref % 1 ~= 0 then
			T.Fail("There is no item set at position %s; positions go from 1 to %d.", tostring(ref), #order)
		end
		return ref, order[ref]
	end
	local id = T.Find(order, ref, function(setId)
		return setTitle(itemsTab.itemSets[setId])
	end, "item set")
	return isValueInArray(order, id), id
end

T.Tool {
	name = "items_sets",
	title = "Manage item sets",
	description = "Lists and manages the open build's item sets (the Items tab's 'Item set' dropdown and its Manage dialog): 'list', "
		.. "'select' (makes a set the active one, which changes the calculated stats), 'new' (an empty set named 'title'), 'copy' "
		.. "(a copy of 'set' named 'title'), 'rename' and 'delete' (removes the set but not its items; the last set cannot be deleted; "
		.. "only delete when the user asked). A set is named by its title or by its 1-based position (an integer). It uses PoB's own "
		.. "set list and name dialogs, so the result is what the user would get by clicking. Returns the sets with which is active.",
	modifies = true,
	destructive = true,
	input = {
		action = { type = "string", enum = { "list", "select", "new", "copy", "rename", "delete" }, description = "What to do." },
		set = { type = { "string", "integer" }, description = "The set to select, copy, rename or delete: its title or 1-based position (default for copy: the active set)." },
		title = { type = "string", maxLength = 100, description = "Name for new, copy and rename." },
	},
	required = { "action" },
	run = function(args, ctx)
		local build = T.Build()
		local itemsTab = build.itemsTab
		local action = args.action
		if action == "list" then
			return { itemSets = listSets(itemsTab) }
		end
		local title
		if action == "new" or action == "copy" or action == "rename" then
			title = args.title and T.Sanitise(args.title)
			if not title or not title:match("%S") then
				T.Fail("title is required for %s.", action)
			end
		end
		local position, setId
		if args.set ~= nil then
			position, setId = findSet(itemsTab, args.set)
		elseif action == "copy" then
			setId = itemsTab.activeItemSetId
			position = isValueInArray(itemsTab.itemSetOrderList, setId)
		elseif action ~= "new" then
			T.Fail("set is required for %s.", action)
		end
		-- The Manage dialog's list, over the tab's own set order.
		local list = new("ItemSetListControl"):ItemSetListControl(nil, { 0, 0, 300, 200 }, itemsTab)
		list.selIndex, list.selValue = position, setId
		-- Fills and saves the name dialog RenameSet opened.
		local function saveName()
			local popup = main.popups[1]
			popup.controls.edit:SetText(title, true)
			popup.controls.save.onClick()
		end
		local result = { action = action }
		if action == "select" then
			if setId == itemsTab.activeItemSetId then
				result.note = "That set is already active."
			else
				list:OnSelClick(position, setId, true)
				ctx:Changed()
			end
		elseif action == "new" then
			list.controls.new.onClick()
			saveName()
			ctx:Changed()
		elseif action == "copy" then
			list.controls.copy.onClick()
			saveName()
			ctx:Changed()
		elseif action == "rename" then
			list.controls.rename.onClick()
			saveName()
			ctx:Changed()
		else
			if #itemsTab.itemSetOrderList < 2 then
				T.Fail("The build has only one item set, and PoB does not delete the last one.")
			end
			result.deleted = setTitle(itemsTab.itemSets[setId])
			list:OnSelDelete(position, setId)
			main.popups[1].controls.confirm.onClick()
			ctx:Changed()
		end
		result.itemSets = listSets(itemsTab)
		return result
	end,
}

------------------------------------------------------------------------------
-- items_db_search
------------------------------------------------------------------------------

T.Tool {
	name = "items_db_search",
	title = "Search the item databases",
	description = "Searches Path of Building's unique item database or its rare item templates, with the same filters and sorting as "
		.. "the Items tab's database lists: search text (anywhere, names only or modifiers only), slot, type, and for uniques league, "
		.. "requirements (what the character can use now) and source (obtainable, vendor recipe, boss drop, ...). Uniques can also be "
		.. "sorted by a stat, which PoB computes by equipping each item in the build's matching slot (slow for broad searches: narrow "
		.. "them first). Returns name, base, type, league and source, and the item text with include_text (pass it to simulate or "
		.. "items_equip; a unique with several variants uses its default variant unless the 'Selected Variant' line is changed). "
		.. "Pass list_filters to get the accepted filter values. Fails while PoB is still loading the databases after start-up.",
	readOnly = true,
	idempotent = true,
	input = {
		db = { type = "string", enum = { "unique", "rare" }, description = "Which database (default unique)." },
		search = { type = "string", maxLength = 100, description = "Search text, as typed in the list's search box (PoB's ' or ' and pattern rules apply)." },
		search_mode = { type = "string", description = "Anywhere (default), Names or Modifiers." },
		slot = { type = "string", description = "Slot filter, for example 'Helmet', 'Ring', 'Weapon 1', 'Jewel', 'Flask'." },
		type = { type = "string", description = "Type filter, for example 'Armour', 'Jewellery', 'One Handed Melee', 'Bow', 'Jewel'." },
		league = { type = "string", description = "Uniques: league filter, for example 'No league' (core items) or a league name." },
		requirement = { type = "string", description = "Uniques: 'Any requirements' (default), 'Current level', 'Current attributes' or 'Current useable'." },
		source = { type = "string", description = "Uniques: 'Obtainable' (default), 'Any source', 'Unobtainable', 'Vendor Recipe', 'Upgraded', 'Boss Item', 'Corruption' or 'Core Drop Pool'." },
		sort_by = { type = "string", description = "Uniques: 'Name' (default) or a stat to sort by, for example 'FullDPS', 'Life', 'TotalEHP'." },
		include_text = { type = "boolean", description = "Include each item's full text." },
		list_filters = { type = "boolean", description = "Also return the values each filter accepts." },
		limit = T.PageArgs(25, 100).limit,
		offset = T.PageArgs(25, 100).offset,
	},
	run = function(args)
		local build = T.Build()
		local itemsTab = build.itemsTab
		local dbType = args.db == "rare" and "RARE" or "UNIQUE"
		local db = dbType == "RARE" and main.rareDB or main.uniqueDB
		if db.loading then
			T.Fail("Path of Building is still loading its item databases; try again in a few seconds.")
		end
		-- A copy of the Items tab's database list, so the tab's own filters stay as the user left them.
		local control = new("ItemDBControl"):ItemDBControl(nil, { 0, 0, 360, 300 }, itemsTab, db, dbType)
		control:LoadLeaguesAndTypes()
		local c = control.controls
		local function filter(dropdown, value, what)
			if value == nil then
				return
			end
			if not dropdown then
				T.Fail("%s is only a filter of the unique database.", what)
			end
			dropdown.selIndex = pick(dropdown.list, value, what)
		end
		filter(c.slot, args.slot, "slot")
		filter(c.type, args.type, "type")
		filter(c.league, args.league, "league")
		filter(c.requirement, args.requirement, "requirement")
		filter(c.obtainable, args.source, "source")
		filter(c.searchMode, args.search_mode, "search_mode")
		if args.search then
			c.search:SetText(args.search)
		end
		local sortedByStat = false
		if args.sort_by and args.sort_by:lower() ~= "name" then
			if not c.sort then
				T.Fail("Only the unique database can be sorted by a stat.")
			end
			local entry = control.sortDropList[findSortIndex(control.sortDropList, args.sort_by)]
			control:SetSortMode(entry.sortMode)
			sortedByStat = entry.stat ~= nil
		end
		-- Sorting by a stat stores measuredPower on the shared database items; keep the values the tab's list has.
		local savedPower = { }
		for _, item in pairs(db.list) do
			savedPower[item] = item.measuredPower
		end
		-- The list is built by a coroutine the control resumes once per frame; finish it now.
		local builder = coroutine.create(control.ListBuilder)
		local ok, err
		repeat
			ok, err = coroutine.resume(builder, control)
		until not ok or coroutine.status(builder) == "dead"
		local page, paging = T.Page(ok and control.list or { }, args, 25, 100)
		local found = { }
		for _, item in ipairs(page) do
			t_insert(found, {
				name = item.name,
				base = item.baseName,
				type = item.type,
				league = item.league,
				source = item.source,
				levelRequirement = item.requirements and item.requirements.level or nil,
				variants = item.variantList and #item.variantList > 1 and #item.variantList or nil,
				sortValue = sortedByStat and T.Round(item.measuredPower) or nil,
				text = args.include_text and item.raw or nil,
			})
		end
		for item, power in pairs(savedPower) do
			item.measuredPower = power
		end
		if not ok then
			T.Fail("Path of Building's database search failed: %s", tostring(err))
		end
		local result = {
			db = dbType:lower(),
			items = T.Array(found),
			page = paging,
			sortedBy = sortedByStat and (control.sortDetail.label:gsub("^Sort by ", "")) or "Name",
		}
		if args.list_filters then
			local filters = { slot = control.slotList, type = control.typeList, searchMode = c.searchMode.list }
			if c.league then
				filters.league = control.leagueList
				filters.requirement = c.requirement.list
				filters.source = c.obtainable.list
				local sorts = { "Name" }
				for _, entry in ipairs(control.sortDropList) do
					if entry.stat then
						t_insert(sorts, entry.stat)
					end
				end
				filters.sortBy = sorts
			end
			result.filters = filters
		end
		return result
	end,
}

------------------------------------------------------------------------------
-- items_craft
------------------------------------------------------------------------------

local function parseCraftText(text)
	if type(text) ~= "string" or not text:match("%S") then
		T.Fail("item (the item text) is required for this action; start with action create.")
	end
	local item = new("Item"):Item((T.Sanitise((text:gsub("\r\n", "\n")))))
	if not item.base then
		T.Fail("Path of Building could not read that item (unknown base type). Use the text returned by items_craft or copied from the game or PoB.")
	end
	return item
end

-- Runs fn with item as the Items tab's display item (as double-clicking an item
-- does), then closes the dialogs it opened and puts back the display item and
-- the tab state its dialogs remember.
local function withDisplayItem(itemsTab, item, sortIndex, fn)
	local controls = itemsTab.controls
	local saved = {
		displayItem = itemsTab.displayItem,
		snapHScroll = itemsTab.snapHScroll,
		sorting = controls.craftingSorting.selIndex,
		lastCraftRaritySel = itemsTab.lastCraftRaritySel,
		lastCraftTypeSel = itemsTab.lastCraftTypeSel,
		lastCraftBaseSel = itemsTab.lastCraftBaseSel,
		enchantSlot = itemsTab.enchantSlot,
		anointEnchantSlot = itemsTab.anointEnchantSlot,
	}
	local popups = #main.popups
	-- The affix dropdowns are ordered by the tab's "Modifier sorting"; use this call's (Default unless asked).
	controls.craftingSorting.selIndex = sortIndex or 1
	local ok, result = pcall(function()
		if item then
			itemsTab:SetDisplayItem(item)
		end
		return fn()
	end)
	while #main.popups > popups do
		main:ClosePopup()
	end
	controls.craftingSorting.selIndex = saved.sorting
	itemsTab.lastCraftRaritySel, itemsTab.lastCraftTypeSel, itemsTab.lastCraftBaseSel = saved.lastCraftRaritySel, saved.lastCraftTypeSel, saved.lastCraftBaseSel
	itemsTab.enchantSlot, itemsTab.anointEnchantSlot = saved.enchantSlot, saved.anointEnchantSlot
	itemsTab:SetDisplayItem(saved.displayItem)
	itemsTab.snapHScroll = saved.snapHScroll
	if not ok then
		error(result, 0)
	end
	return result
end

-- Calls the Items tab function behind a button and returns the dialog's controls.
local function openDialog(open)
	local before = #main.popups
	open()
	if #main.popups ~= before + 1 then
		T.Fail("Path of Building did not open the dialog for this item.")
	end
	return main.popups[1].controls
end

-- Prefix and suffix choices of an item made with "Craft item..." (the displayItemAffix dropdowns).
local function affixSlots(itemsTab)
	local item = itemsTab.displayItem
	local slots = { }
	for i = 1, item.affixLimit or 0 do
		local control = itemsTab.controls["displayItemAffix" .. i]
		local affix = item[control.outputTable] and item[control.outputTable][control.outputIndex]
		local entry = {
			type = control.outputTable == "prefixes" and "prefix" or "suffix",
			index = control.outputIndex,
		}
		local mod = affix and item.affixes[affix.modId]
		if mod then
			local group = control.list[control.selIndex]
			local position = type(group) == "table" and group.modList and isValueInArray(group.modList, affix.modId)
			entry.modId = affix.modId
			entry.affix = mod.affix
			entry.lines = T.Array(copyTable(mod))
			entry.tier = position and (#group.modList - position + 1) or nil
			entry.tiers = position and #group.modList or nil
			entry.roll = type(affix.range) == "number" and T.Round(affix.range, 3) or nil
		else
			entry.empty = true
		end
		t_insert(slots, entry)
	end
	return slots
end

-- The result every crafting action returns: the item text and what it holds now.
local function craftResult(itemsTab, extra)
	local item = itemsTab.displayItem
	local result = extra or { }
	result.item = item:BuildRaw()
	result.name = item.name
	result.rarity = item.rarity
	result.base = item.baseName
	result.mods = T.Array(modLines(item))
	if item.crafted then
		result.affixes = affixSlots(itemsTab)
	end
	return result
end

-- A page of dropdown entries as options.
local function listOptions(list, args, first, describe)
	local options = { }
	for i = first or 1, #list do
		local entry = list[i]
		local option = { label = labelOf(entry) }
		if describe then
			describe(entry, option)
		end
		t_insert(options, option)
	end
	local page, paging = T.Page(options, args, 50)
	return { options = page, page = paging }
end

-- Ids of PoB's mod tables, so options can be named by a key that survives re-sorting.
local function modIdLookup(build, item)
	local ids
	return function(mod)
		if type(mod) ~= "table" then
			return nil
		end
		if not ids then
			ids = { }
			for _, pool in ipairs({ item.affixes or { }, build.data.veiledMods or { }, build.data.necropolisMods or { } }) do
				for id, candidate in pairs(pool) do
					if type(id) == "string" and type(candidate) == "table" and not ids[candidate] then
						ids[candidate] = id
					end
				end
			end
		end
		return ids[mod]
	end
end

local function chooseSort(control, sortBy)
	if sortBy then
		local index = findSortIndex(control.list, sortBy)
		if index ~= control.selIndex then
			choose(control, index)
		end
	end
end

local craftActions = { }

-- "Craft item..." (ItemsTab:CraftItem): its Type and Base lists.
function craftActions.bases(itemsTab, args)
	local p = openDialog(function() itemsTab:CraftItem() end)
	local types = p.type.list
	if not args.base_type and not args.search then
		local list = { }
		for i, typeName in ipairs(types) do
			choose(p.type, i)
			t_insert(list, { type = typeName, bases = #p.base.list })
		end
		p.cancel.onClick()
		return { baseTypes = list, note = "Pass base_type or search to list bases." }
	end
	local wantedType = args.base_type and pick(types, args.base_type, "base type")
	local search = args.search and args.search:lower()
	local bases = { }
	for i, typeName in ipairs(types) do
		if not wantedType or i == wantedType then
			choose(p.type, i)
			for _, entry in ipairs(p.base.list) do
				local haystack = (entry.searchFilter or entry.name):lower()
				if not search or haystack:find(search, 1, true) then
					t_insert(bases, {
						name = entry.name,
						type = typeName,
						level = entry.base.req and entry.base.req.level or nil,
						implicit = entry.base.implicit,
					})
				end
			end
		end
	end
	p.cancel.onClick()
	local page, paging = T.Page(bases, args, 50)
	return { bases = page, page = paging }
end

-- "Craft item...": Rarity, Name, Type and Base, then Create.
function craftActions.create(itemsTab, args)
	if not args.base then
		T.Fail("base is required for create (see action bases).")
	end
	local p = openDialog(function() itemsTab:CraftItem() end)
	p.rarity.selIndex = pick(p.rarity.list, args.rarity or "Rare", "rarity", function(entry, want)
		return entry.rarity == tostring(want):upper()
	end)
	if args.name then
		p.title:SetText((T.Sanitise(args.name)))
	end
	local wanted = args.base:lower()
	local found
	for i = 1, #p.type.list do
		choose(p.type, i)
		for b, entry in ipairs(p.base.list) do
			if entry.name:lower() == wanted then
				found = b
				break
			end
		end
		if found then
			break
		end
	end
	if not found then
		T.Fail("Path of Building has no item base named '%s'; find it with action bases.", args.base)
	end
	p.base.selIndex = found
	p.save.onClick()
	local result = craftResult(itemsTab)
	if not itemsTab.displayItem.crafted and itemsTab.displayItem.rarity ~= "NORMAL" then
		result.note = "PoB creates unique and relic items without modifiers (its text editor opens next): add them by editing the returned item text."
	end
	return result
end

-- The Prefix/Suffix dropdowns and roll sliders of a crafted magic or rare item.
function craftActions.affix(itemsTab, args)
	local item = itemsTab.displayItem
	if not item.crafted then
		T.Fail("Only items made with action create as magic or rare have prefix and suffix choices; use action modifier for other items.")
	end
	local outputTable = args.affix_type == "suffix" and "suffixes" or "prefixes"
	local control
	for i = 1, item.affixLimit do
		local candidate = itemsTab.controls["displayItemAffix" .. i]
		local affix = item[candidate.outputTable][candidate.outputIndex]
		if candidate.outputTable == outputTable
			and (args.affix_index and candidate.outputIndex == args.affix_index or not args.affix_index and (not affix or affix.modId == "None")) then
			control = candidate
			break
		end
	end
	if not control then
		if args.affix_index then
			T.Fail("This item has no %s %d.", args.affix_type or "prefix", args.affix_index)
		end
		T.Fail("Every %s of this item is taken; pass affix_index to replace one.", args.affix_type or "prefix")
	end
	local which = { type = outputTable == "prefixes" and "prefix" or "suffix", index = control.outputIndex }
	if args.remove then
		if not args.affix_index then
			T.Fail("Give affix_index to say which %s to remove.", which.type)
		end
		choose(control, 1)
		return craftResult(itemsTab, { removed = which })
	end
	if not args.modifier then
		local listing = listOptions(control.list, args, 2, function(entry, option)
			option.ids = T.Array(copyTable(entry.modList))
			option.tiers = #entry.modList
		end)
		listing.affixSlot = which
		listing.note = "Pass one of these labels (or a mod id) as modifier; tier 1 is the best tier."
		return listing
	end
	local matchedId
	local index = pick(control.list, args.modifier, "modifier", function(entry, want)
		if type(entry) == "table" and entry.modList then
			for _, modId in ipairs(entry.modList) do
				if modId == want then
					matchedId = modId
					return true
				end
			end
		end
	end, 2)
	local group = control.list[index]
	local count = #group.modList
	local position
	if matchedId then
		position = isValueInArray(group.modList, matchedId)
	else
		local tier = args.tier or 1
		if tier > count then
			T.Fail("This modifier has %d tier%s for this item.", count, count == 1 and "" or "s")
		end
		position = count - tier + 1
	end
	local roll = args.roll or main.defaultItemAffixQuality or 0.5
	if roll == 0 and position > 1 then
		-- As UpdateAffixControl: an exact boundary would select the tier below.
		roll = 1e-4
	end
	-- The roll slider spans every tier; the dropdown's handler reads it.
	control.slider.val = (position - 1 + roll) / count
	choose(control, index)
	return craftResult(itemsTab, { set = which })
end

-- The "Add modifier..." dialog (ItemsTab:AddCustomModifierToDisplayItem).
function craftActions.modifier(itemsTab, args, build)
	if not itemsTab.controls.displayItemAddCustom:GetProperty("shown") then
		T.Fail("PoB offers 'Add modifier...' only for magic and rare items (and rare-like uniques).")
	end
	local p = openDialog(function() itemsTab:AddCustomModifierToDisplayItem() end)
	local sources = p.source.list
	local sourceRef = args.source or (args.custom and "CUSTOM")
	if sourceRef then
		local index = pick(sources, sourceRef, "source", function(entry, want)
			return entry.sourceId:lower() == tostring(want):lower()
		end)
		if index ~= p.source.selIndex then
			choose(p.source, index)
		end
	end
	local source = sources[p.source.selIndex]
	local sourceLabels = { }
	for _, entry in ipairs(sources) do
		t_insert(sourceLabels, entry.label)
	end
	if source.sourceId == "CUSTOM" then
		if not args.custom then
			return { sources = sourceLabels, source = source.label, note = "Pass custom with the modifier line to add." }
		end
		p.custom:SetText((T.Sanitise(args.custom)))
		p.save.onClick()
		return craftResult(itemsTab, { added = args.custom })
	end
	chooseSort(p.sort, args.sort_by)
	local idOf = modIdLookup(build, itemsTab.displayItem)
	if not args.modifier then
		local listing = listOptions(p.modSelect.list, args, 1, function(entry, option)
			option.id = idOf(entry.mod)
			option.sortValue = T.Round(entry.sortValue)
		end)
		listing.sources = sourceLabels
		listing.source = source.label
		return listing
	end
	local index = pick(p.modSelect.list, args.modifier, "modifier", function(entry, want)
		return idOf(entry.mod) == want
	end)
	local chosen = p.modSelect.list[index]
	p.modSelect.selIndex = index
	p.save.onClick()
	return craftResult(itemsTab, { added = labelOf(chosen), source = source.label })
end

-- The "Add Implicit..." dialog (Modules/AddImplicitPopup).
function craftActions.implicit(itemsTab, args, build)
	local button = itemsTab.controls.displayItemAddImplicit
	if not button:GetProperty("shown") then
		T.Fail("PoB offers 'Add Implicit...' only for normal, magic and rare equipment, and corruptible items whose implicits can change.")
	end
	local p = openDialog(button.onClick)
	local sources = p.source.list
	local sourceRef = args.source or (args.custom and "CUSTOM")
	if sourceRef then
		local index = pick(sources, sourceRef, "source", function(entry, want)
			return entry.sourceId:lower() == tostring(want):lower()
		end)
		if index ~= p.source.selIndex then
			choose(p.source, index)
		end
	end
	local source = sources[p.source.selIndex]
	local sourceLabels = { }
	for _, entry in ipairs(sources) do
		t_insert(sourceLabels, entry.label)
	end
	if source.sourceId == "CUSTOM" then
		if not args.custom then
			return { sources = sourceLabels, source = source.label, note = "Pass custom with the implicit line to add." }
		end
		p.custom:SetText((T.Sanitise(args.custom)))
		p.save.onClick()
		return craftResult(itemsTab, { added = args.custom })
	end
	chooseSort(p.sort, args.sort_by)
	if not args.group then
		local listing = listOptions(p.modGroupSelect.list, args)
		listing.sources = sourceLabels
		listing.source = source.label
		listing.note = "These are implicit types: pass one as group" .. (p.modSelect:GetProperty("shown") and ", then a modifier of that type." or ".")
		return listing
	end
	choose(p.modGroupSelect, pick(p.modGroupSelect.list, args.group, "implicit type"))
	local added = labelOf(p.modGroupSelect.list[p.modGroupSelect.selIndex])
	if p.modSelect:GetProperty("shown") then
		local idOf = modIdLookup(build, itemsTab.displayItem)
		if not args.modifier then
			local listing = listOptions(p.modSelect.list, args, 1, function(entry, option)
				option.id = idOf(entry.mod)
			end)
			listing.group = added
			return listing
		end
		local index = pick(p.modSelect.list, args.modifier, "modifier", function(entry, want)
			return idOf(entry.mod) == want
		end)
		p.modSelect.selIndex = index
		added = labelOf(p.modSelect.list[index])
	end
	p.save.onClick()
	return craftResult(itemsTab, { added = added, source = source.label })
end

-- The "Change Enchantment..." dialogs (ItemsTab:EnchantDisplayItem).
function craftActions.enchant(itemsTab, args)
	local slotNum = args.enchant_slot or 1
	if slotNum > 2 then
		T.Fail("Items have at most two enchantment slots.")
	end
	local button = slotNum == 1 and itemsTab.controls.displayItemEnchant or itemsTab.controls.displayItemEnchant2
	if not button:GetProperty("shown") then
		T.Fail(slotNum == 1 and "PoB has no enchantments for this item." or "A second enchantment needs an item that can have two and already has one.")
	end
	local p = openDialog(function() itemsTab:EnchantDisplayItem(slotNum) end)
	if args.remove then
		p.remove.onClick()
		return craftResult(itemsTab, { removed = true })
	end
	if p.skill then
		if args.all_skills and p.allSkills:IsEnabled() and not p.allSkills.state then
			p.allSkills.state = true
			p.allSkills.changeFunc(true)
		end
		if args.skill then
			choose(p.skill, pick(p.skill.list, args.skill, "skill"))
		end
	end
	if args.source then
		choose(p.enchantmentSource, pick(p.enchantmentSource.list, args.source, "enchantment source", function(entry, want)
			return entry.name:lower() == tostring(want):lower()
		end))
	end
	chooseSort(p.sort, args.sort_by)
	if not args.modifier then
		local listing = listOptions(p.enchantment.list, args, 1, function(entry, option)
			option.sortValue = T.Round(entry.sortValue)
		end)
		if p.skill then
			listing.skill = labelOf(p.skill.list[p.skill.selIndex])
			listing.skills = #p.skill.list <= 60 and p.skill.list or nil
		end
		local sources = { }
		for _, entry in ipairs(p.enchantmentSource.list) do
			t_insert(sources, entry.label)
		end
		listing.sources = sources
		listing.source = p.enchantmentSource.list[p.enchantmentSource.selIndex].label
		return listing
	end
	local index = pick(p.enchantment.list, args.modifier, "enchantment")
	p.enchantment.selIndex = index
	local line = p.enchantment.list[index].line
	p.save.onClick()
	return craftResult(itemsTab, { added = line })
end

-- The "Anoint..." dialogs (ItemsTab:AnointDisplayItem and its NotableDBControl).
function craftActions.anoint(itemsTab, args, build)
	local slotNum = args.enchant_slot or 1
	local buttons = { "displayItemAnoint", "displayItemAnoint2", "displayItemAnoint3", "displayItemAnoint4" }
	local button = itemsTab.controls[buttons[slotNum]]
	if not button or not button:GetProperty("shown") then
		T.Fail(slotNum == 1 and "This item cannot be anointed." or "This item has no anoint slot %d yet (fill the earlier ones first).", slotNum)
	end
	local p = openDialog(function() itemsTab:AnointDisplayItem(slotNum) end)
	local notableDB = p.notableDB
	if args.remove then
		notableDB.selValue = nil
		p.save.onClick()
		return craftResult(itemsTab, { removed = true })
	end
	if not args.modifier then
		if args.search then
			notableDB.controls.search:SetText(args.search)
		end
		if args.sort_by then
			notableDB:SetSortMode(notableDB.sortDropList[findSortIndex(notableDB.sortDropList, args.sort_by)].sortMode)
		end
		local builder = coroutine.create(notableDB.ListBuilder)
		local ok, err
		repeat
			ok, err = coroutine.resume(builder, notableDB)
		until not ok or coroutine.status(builder) == "dead"
		if not ok then
			T.Fail("Path of Building's notable list failed: %s", tostring(err))
		end
		local sorted = notableDB.sortDetail and notableDB.sortDetail.stat
		local listing = listOptions(notableDB.list, args, 1, function(node, option)
			option.label = node.dn
			option.recipe = T.Array(copyTable(node.recipe))
			option.stats = T.Array(copyTable(node.sd))
			option.sortValue = sorted and T.Round(node.measuredPower) or nil
		end)
		listing.note = "Pass a notable's name as modifier."
		return listing
	end
	local notables = { }
	for _, node in pairs(build.spec.tree.nodes) do
		if node.recipe and #node.recipe >= 1 then
			t_insert(notables, node)
		end
	end
	local node = T.Find(notables, args.modifier, function(candidate)
		return candidate.dn
	end, "anointable notable")
	notableDB.selValue = node
	p.save.onClick()
	return craftResult(itemsTab, { added = "Allocates " .. node.dn })
end

-- The "Corrupt..." dialog (ItemsTab:CorruptDisplayItem).
function craftActions.corrupt(itemsTab, args, build)
	if not itemsTab.controls.displayItemCorrupt:GetProperty("shown") then
		T.Fail("PoB cannot corrupt this item (it is not corruptible, or already corrupted).")
	end
	local p = openDialog(function() itemsTab:CorruptDisplayItem() end)
	if args.source then
		local index = pick(p.source.list, args.source, "corruption source")
		if index ~= p.source.selIndex then
			choose(p.source, index)
		end
	end
	chooseSort(p.sort, args.sort_by)
	local slots = { }
	for i = 1, 5 do
		if p["implicit" .. i] and p["implicit" .. i].shown == true then
			t_insert(slots, i)
		end
	end
	local rollLines = { }
	for i = 1, #itemsTab.displayItem.explicitModLines do
		if p["rollRangeSlider" .. i] then
			t_insert(rollLines, { index = i, label = T.Clean(p["rollRangeLabel" .. i].label):gsub("\n", " ") })
		end
	end
	local idOf = modIdLookup(build, itemsTab.displayItem)
	if args.implicits == nil and args.rolls == nil then
		local implicitSlots = { }
		for _, i in ipairs(slots) do
			local listing = listOptions(p["implicit" .. i].list, args, 2, function(entry, option)
				option.id = idOf(entry.mod)
			end)
			listing.slot = i
			t_insert(implicitSlots, listing)
		end
		local lines = { }
		for _, line in ipairs(rollLines) do
			t_insert(lines, line.label)
		end
		return {
			source = p.source.list[p.source.selIndex],
			sources = p.source.list,
			implicitSlots = T.Array(implicitSlots),
			rollLines = lines[1] and lines or nil,
			implicitsCannotBeChanged = itemsTab.displayItem.implicitsCannotBeChanged or nil,
			note = "Pass implicits (one per slot, in order; [] corrupts without new implicits) or, for uniques, rolls.",
		}
	end
	if args.implicits and args.rolls then
		T.Fail("Pass implicits or rolls, not both: PoB corrupts with one or the other.")
	end
	local chosen = { }
	if args.rolls then
		if not rollLines[1] then
			T.Fail("PoB offers roll ranges only for unique and relic items with lines that can change.")
		end
		p.rolls.onClick()
		for _, roll in ipairs(args.rolls) do
			local line = rollLines[pick(rollLines, roll.line, "roll line")]
			local slider = p["rollRangeSlider" .. line.index]
			-- SetVal only calls its handler on a change.
			slider.val = -1
			slider:SetVal((roll.value - 0.78) / 0.44)
			t_insert(chosen, T.Clean(p["rollRangeLabel" .. line.index].label))
		end
	else
		if #args.implicits > 0 and not slots[1] then
			T.Fail("PoB cannot change the implicits of this item.")
		end
		for n, want in ipairs(args.implicits) do
			local slot = slots[n]
			if not slot then
				T.Fail("PoB shows %d implicit choice%s for this source.", #slots, #slots == 1 and "" or "s")
			end
			if want:match("%S") and want:lower() ~= "none" then
				-- Each choice rebuilds the other dropdowns, so it is found in the list as it is now.
				local control = p["implicit" .. slot]
				local index = pick(control.list, want, "implicit", function(entry, wanted)
					return idOf(entry.mod) == wanted
				end, 2)
				control.selIndex = index
				control.selFunc()
				t_insert(chosen, labelOf(control.list[control.selIndex]))
			end
		end
	end
	p.save.onClick()
	return craftResult(itemsTab, { chosen = T.Array(chosen) })
end

-- Parses "R-G-B B" into sockets { color, group }.
local function parseSockets(text)
	local sockets = { }
	local group = 0
	for word in text:upper():gmatch("%S+") do
		for color in word:gmatch("[^%-]+") do
			if not color:match("^[RGBW]$") then
				T.Fail("sockets must be written like 'R-G-B B' (colours R, G, B, W; '-' links, space separates groups).")
			end
			t_insert(sockets, { color = color, group = group })
		end
		group = group + 1
	end
	return sockets
end

-- The display item's own controls (ItemsTab constructor).
function craftActions.properties(itemsTab, args)
	local c = itemsTab.controls
	local applied = { }
	local function shown(control)
		return control:GetProperty("shown")
	end
	if args.influences then
		if not shown(c.displayItemInfluence) then
			T.Fail("PoB offers no influence for this item.")
		end
		local picks = { 1, 1 }
		for k, name in ipairs(args.influences) do
			if name:lower() ~= "none" then
				picks[k] = pick(c.displayItemInfluence.list, name, "influence", nil, 2)
			end
		end
		c.displayItemInfluence2.selIndex = picks[2]
		choose(c.displayItemInfluence, picks[1])
		applied.influences = true
	end
	if args.quality ~= nil then
		if not shown(c.displayItemQualityEdit) then
			T.Fail("This item has no quality in PoB.")
		end
		c.displayItemQualityEdit:SetText(tostring(args.quality), true)
		applied.quality = true
	end
	if args.catalyst then
		if not shown(c.displayItemCatalyst) then
			T.Fail("PoB offers catalysts only for crafted (or tagged) amulets, rings and belts.")
		end
		choose(c.displayItemCatalyst, pick(c.displayItemCatalyst.list, args.catalyst, "catalyst"))
		applied.catalyst = true
	end
	if args.catalyst_quality ~= nil then
		if not shown(c.displayItemCatalystQualityEdit) then
			T.Fail("Choose a catalyst first.")
		end
		c.displayItemCatalystQualityEdit:SetText(tostring(args.catalyst_quality), true)
		applied.catalystQuality = true
	end
	if args.variant then
		local item = itemsTab.displayItem
		if item.usesVariantGroups or not shown(c.displayItemVariant) then
			T.Fail("This item has no single variant list; change its 'Selected Variant' line in the item text instead.")
		end
		choose(c.displayItemVariant, pick(c.displayItemVariant.list, args.variant, "variant"))
		applied.variant = true
	end
	if args.cluster_skill then
		if not shown(c.displayItemClusterJewelSkill) then
			T.Fail("cluster_skill applies to cluster jewels made with action create.")
		end
		choose(c.displayItemClusterJewelSkill, pick(c.displayItemClusterJewelSkill.list, args.cluster_skill, "cluster jewel skill"))
		applied.clusterSkill = true
	end
	if args.cluster_passives then
		local cluster = itemsTab.displayItem.clusterJewel
		if not shown(c.displayItemClusterJewelSkill) or not cluster then
			T.Fail("cluster_passives applies to cluster jewels made with action create.")
		end
		if args.cluster_passives < cluster.minNodes or args.cluster_passives > cluster.maxNodes then
			T.Fail("cluster_passives must be %d-%d for this jewel.", cluster.minNodes, cluster.maxNodes)
		end
		local slider = c.displayItemClusterJewelNodeCount
		slider.val = -1
		slider:SetVal((args.cluster_passives - cluster.minNodes) / (cluster.maxNodes - cluster.minNodes))
		applied.clusterPassives = true
	end
	if args.sockets then
		local item = itemsTab.displayItem
		local wanted = parseSockets(args.sockets)
		local current = #item.sockets - item.abyssalSocketCount
		if #wanted > item.selectableSocketCount then
			T.Fail("This item can have at most %d sockets.", item.selectableSocketCount)
		elseif #wanted < current then
			T.Fail("PoB only adds sockets with its controls; to have fewer, change the 'Sockets:' line of the item text.")
		end
		for _ = current + 1, #wanted do
			c.displayItemAddSocket.onClick()
		end
		for i, socket in ipairs(wanted) do
			local drop = c["displayItemSocket" .. i]
			for index, entry in ipairs(drop.list) do
				if entry.color == socket.color and itemsTab.displayItem.sockets[i].color ~= socket.color then
					choose(drop, index)
				end
			end
			if i > 1 then
				local link = c["displayItemLink" .. (i - 1)]
				local linked = socket.group == wanted[i - 1].group
				if (itemsTab.displayItem.sockets[i].group == itemsTab.displayItem.sockets[i - 1].group) ~= linked then
					link.state = linked
					link.changeFunc(linked)
				end
			end
		end
		applied.sockets = true
	end
	if args.ranges then
		local item = itemsTab.displayItem
		for _, range in ipairs(args.ranges) do
			local list = itemsTab.displayItem.rangeLineList
			local index = pick(list, range.line, "range line", function(modLine, want)
				return T.Clean(modLine.line):lower() == tostring(want):lower()
			end)
			if main.showAllItemAffixes and item.rarity == "UNIQUE" then
				local slider = c["displayItemStackedRangeSlider" .. index]
				slider.val = -1
				slider:SetVal(range.roll)
			else
				local drop = c.displayItemRangeLine
				for d, entry in ipairs(drop.list) do
					if entry.modLine == list[index] then
						choose(drop, d)
					end
				end
				c.displayItemRangeSlider.val = -1
				c.displayItemRangeSlider:SetVal(range.roll)
			end
		end
		applied.ranges = true
	end
	if args.remove_modifiers then
		for _, want in ipairs(args.remove_modifiers) do
			-- The Remove buttons UpdateCustomControls made, in its order.
			local item = itemsTab.displayItem
			local removable = { }
			local lines = copyTable(item.explicitModLines, true)
			for _, modLine in ipairs(item.crucibleModLines or { }) do
				t_insert(lines, modLine)
			end
			for _, modLine in ipairs(lines) do
				if modLine.custom or modLine.crafted or modLine.crucible then
					local text = itemLib.formatModLine(modLine)
					if text then
						t_insert(removable, { label = T.Clean(text), button = c["displayItemCustomModifierRemove" .. (#removable + 1)] })
					end
				end
			end
			removable[pick(removable, want, "removable (crafted or custom) modifier")].button.onClick()
		end
		applied.removed = true
	end
	if not next(applied) then
		local item = itemsTab.displayItem
		local rangeLines = { }
		for _, modLine in ipairs(item.rangeLineList or { }) do
			t_insert(rangeLines, { line = T.Clean(modLine.line), roll = T.Round(modLine.range, 3) })
		end
		return craftResult(itemsTab, {
			quality = item.quality,
			sockets = socketString(item),
			maxSockets = item.selectableSocketCount > 0 and item.selectableSocketCount or nil,
			influenceOptions = shown(c.displayItemInfluence) and c.displayItemInfluence.list or nil,
			catalystOptions = shown(c.displayItemCatalyst) and c.displayItemCatalyst.list or nil,
			variants = not item.usesVariantGroups and shown(c.displayItemVariant) and item.variantList or nil,
			rangeLines = rangeLines[1] and rangeLines or nil,
			clusterSkills = shown(c.displayItemClusterJewelSkill) and c.displayItemClusterJewelSkill.list or nil,
		})
	end
	return craftResult(itemsTab)
end

T.Tool {
	name = "items_craft",
	title = "Craft an item",
	description = "Builds an item with Path of Building's own crafting controls and returns its text; nothing is added to the build "
		.. "(test it with simulate, add it with items_equip). Every action except bases and create takes the item text in 'item' and "
		.. "returns the changed text in 'item'; when the choice it needs is left out, it lists the options instead (paged, labels to "
		.. "pass back). Actions: 'bases' (base types, or bases of base_type / matching search), 'create' (a new item from 'base', "
		.. "rarity default rare, optional name), 'affix' (a crafted magic or rare item's prefix or suffix: modifier by label or mod id, "
		.. "tier 1 = best, roll 0-1, or remove), 'modifier' (the 'Add modifier...' dialog: source such as Crafting Bench, Essence, "
		.. "Veiled, Fossil, Prefix, Suffix, or custom text), 'implicit' (Searing Exarch, Eater of Worlds, Vestigial or custom "
		.. "implicits: group then modifier), 'enchant' (enchant_slot, skill, source, modifier or remove), 'anoint' (a notable by "
		.. "name, or search to list), 'corrupt' (implicits by name, or rolls for uniques), 'properties' (influences, quality, "
		.. "catalyst, variant, sockets such as 'R-G-B B', ranges of variable lines, remove crafted or custom modifiers, cluster "
		.. "jewel skill and passives; with none given it shows the current values and options). sort_by orders option lists by a "
		.. "stat PoB computes for this build (slow on long lists). The Items tab's own displayed item and settings are left as they were.",
	readOnly = true,
	idempotent = true,
	usesDialog = true,
	input = {
		action = { type = "string", enum = { "bases", "create", "affix", "modifier", "implicit", "enchant", "anoint", "corrupt", "properties" }, description = "What to do." },
		item = { type = "string", maxLength = 20000, description = "The item text to change (from create or a previous call, or copied from the game or PoB)." },
		base_type = { type = "string", description = "bases: the base type, for example 'Helmet: Armour' or 'Ring'." },
		search = { type = "string", maxLength = 100, description = "bases: text in the base name or implicit; anoint: notable search." },
		base = { type = "string", description = "create: the base, for example 'Hubris Circlet'." },
		rarity = { type = "string", description = "create: Normal, Magic, Rare (default), Unique or Relic." },
		name = { type = "string", maxLength = 100, description = "create: the name of a rare or unique item." },
		affix_type = { type = "string", enum = { "prefix", "suffix" }, description = "affix: prefix (default) or suffix." },
		affix_index = { type = "integer", minimum = 1, maximum = 6, description = "affix: which prefix or suffix (default: the first empty one)." },
		tier = { type = "integer", minimum = 1, maximum = 30, description = "affix: tier, 1 = best (default 1)." },
		roll = { type = "number", minimum = 0, maximum = 1, description = "affix: roll within the tier, 0 = lowest, 1 = highest (default PoB's affix quality setting)." },
		remove = { type = "boolean", description = "affix, enchant, anoint: remove instead of set." },
		source = { type = "string", description = "modifier, implicit, enchant, corrupt: the dialog's Source choice." },
		modifier = { type = "string", maxLength = 500, description = "affix, modifier, implicit, enchant, anoint: the option to apply, by label (or a unique part of it) or mod id." },
		group = { type = "string", maxLength = 500, description = "implicit: the implicit type." },
		custom = { type = "string", maxLength = 500, description = "modifier, implicit: a custom modifier line to add." },
		enchant_slot = { type = "integer", minimum = 1, maximum = 4, description = "enchant (1-2), anoint (1-4): which slot (default 1)." },
		skill = { type = "string", description = "enchant: the skill whose enchantments to use (helmet enchants)." },
		all_skills = { type = "boolean", description = "enchant: offer skills the build does not use." },
		implicits = { type = "array", items = { type = "string", maxLength = 500 }, maxItems = 5, description = "corrupt: the implicit for each choice in order ('None' to leave one empty; [] to corrupt without implicits)." },
		rolls = {
			type = "array", maxItems = 20, description = "corrupt (uniques): corrupted roll range for lines.",
			items = { type = "object", properties = { line = { type = "string" }, value = { type = "number", minimum = 0.78, maximum = 1.22 } }, required = { "line", "value" }, additionalProperties = false },
		},
		influences = { type = "array", items = { type = "string" }, maxItems = 2, description = "properties: up to two influences, for example ['Shaper', 'Hunter'] (['None'] clears)." },
		quality = { type = "integer", minimum = 0, maximum = 99, description = "properties: quality." },
		catalyst = { type = "string", description = "properties: catalyst for amulets, rings and belts, for example 'Prismatic'." },
		catalyst_quality = { type = "integer", minimum = 0, maximum = 99, description = "properties: catalyst quality." },
		variant = { type = "string", description = "properties: the variant of a unique with variants." },
		sockets = { type = "string", maxLength = 20, description = "properties: sockets like 'R-R-G B' (only adding sockets is possible)." },
		ranges = {
			type = "array", maxItems = 20, description = "properties: rolls of variable lines (for example on uniques), 0-1.",
			items = { type = "object", properties = { line = { type = "string" }, roll = { type = "number", minimum = 0, maximum = 1 } }, required = { "line", "roll" }, additionalProperties = false },
		},
		remove_modifiers = { type = "array", items = { type = "string", maxLength = 500 }, maxItems = 10, description = "properties: crafted or custom modifier lines to remove." },
		cluster_skill = { type = "string", description = "properties: a crafted cluster jewel's skill, for example 'Fire Damage'." },
		cluster_passives = { type = "integer", minimum = 2, maximum = 12, description = "properties: a crafted cluster jewel's number of added passives." },
		sort_by = { type = "string", description = "Order option lists by a stat, for example 'FullDPS' or 'Life'." },
		limit = T.PageArgs(50).limit,
		offset = T.PageArgs(50).offset,
	},
	required = { "action" },
	run = function(args)
		local build = T.Build()
		local itemsTab = build.itemsTab
		local action = args.action
		local item
		if action ~= "bases" and action ~= "create" then
			item = parseCraftText(args.item)
		end
		local sortIndex
		if action == "affix" and args.sort_by then
			sortIndex = findSortIndex(itemsTab.controls.craftingSorting.list, args.sort_by)
		end
		return withDisplayItem(itemsTab, item, sortIndex, function()
			return craftActions[action](itemsTab, args, build)
		end)
	end,
}

------------------------------------------------------------------------------
-- trade_query
------------------------------------------------------------------------------

-- The trader's listing types, in the order of its dropdown (TradeQuery:PriceItem)
-- and of the ids TradeQueryGenerator:FinishQuery sends.
local TRADE_TYPES = { "instant_buyout", "instant_or_in_person", "in_person_online_in_league", "in_person_online", "any" }

-- Currencies of the generator's "Max Price" dropdown (TradeQueryGenerator currencyTable).
local CURRENCIES = { "chaos", "divine", "alch", "alt", "chrome", "exalted", "blessed", "chisel", "gcp", "jewellers", "scour", "regret", "fusing", "chance", "regal", "vaal" }

-- Trade site stat id -> text, from the stat list PoB ships (Data/TradeSiteStats).
local tradeStatText
local function tradeStatLookup()
	if not tradeStatText then
		tradeStatText = { }
		for _, category in ipairs(tradeHelpers.getTradeStats()) do
			for _, entry in ipairs(category.entries or { }) do
				tradeStatText[entry.id] = entry.text
			end
		end
	end
	return tradeStatText
end

-- The weights the trader's "Adjust search weights" dialog offers (TradeQuery:SetStatWeights).
local function statWeights(list)
	local weights = { }
	for _, want in ipairs(list) do
		local found
		for _, stat in ipairs(data.powerStatList) do
			if not stat.ignoreForItems and stat.label ~= "Name" and stat.stat
				and (stat.stat:lower() == want.stat:lower() or stat.label:lower() == want.stat:lower()) then
				found = stat
			end
		end
		if not found then
			local names = { }
			for _, stat in ipairs(data.powerStatList) do
				if not stat.ignoreForItems and stat.stat then
					t_insert(names, stat.stat)
				end
			end
			T.Fail("Unknown weight stat '%s'. Stats: %s", want.stat, t_concat(names, ", "))
		end
		t_insert(weights, { label = found.label, stat = found.stat, transform = found.transform, weightMult = want.weight })
	end
	return weights
end

local function tradeStatFilters(list, what)
	if not list then
		return nil
	end
	local stats = tradeStatLookup()
	local filters = { }
	for _, entry in ipairs(list) do
		if not stats[entry.id] then
			T.Fail("'%s' in %s is not a trade site stat id PoB knows (for example 'explicit.stat_3299347043' or 'pseudo.pseudo_total_life').", entry.id, what)
		end
		t_insert(filters, { tradeId = entry.id, value = entry.min })
	end
	return filters
end

local function statFilterList(description)
	return {
		type = "array", maxItems = 5, description = description,
		items = { type = "object", properties = { id = { type = "string" }, min = { type = "number" } }, required = { "id" }, additionalProperties = false },
	}
end

T.Tool {
	name = "trade_query",
	title = "Weighted trade search",
	description = "Generates the weighted trade search Path of Building's trader ('Trade for these items', 'Find best') builds for "
		.. "an equipment slot or jewel socket of the open build: PoB measures every modifier that can appear on that item type with "
		.. "the build's calculator, weights each by how much it improves the chosen stats (default: the build's saved trader weights, "
		.. "else Full DPS 1.0 and Effective Hit Pool 0.5), and sets the minimum weighted sum to half the current item's value. Returns "
		.. "the query JSON for the pathofexile.com trade API, the weighted stats in readable form, and a trade site URL when a league "
		.. "is known (pass league, for example 'Standard' or the current challenge league) and compression is available. Nothing is "
		.. "sent to the trade site and nothing is bought; it uses only data PoB ships, and takes a few seconds. Options mirror the "
		.. "trader's Query Options dialog.",
	readOnly = true,
	idempotent = true,
	usesDialog = true,
	input = {
		slot = { type = "string", description = "Slot, for example 'Helmet', 'Ring 1', 'Weapon 1', 'Flask 2' or a jewel socket like 'Socket #1'." },
		league = { type = "string", maxLength = 100, description = "Trade league for the URL (default: the league chosen in PoB's trader, if any)." },
		realm = { type = "string", enum = { "pc", "xbox", "sony" }, description = "Trade realm for the URL (default pc)." },
		trade_type = { type = "string", enum = TRADE_TYPES, description = "Listings to search (default: the trader's choice, else instant_buyout)." },
		weights = {
			type = "array", maxItems = 20, description = "Stats to weight, for example [{stat:'FullDPS', weight:1}, {stat:'Life', weight:0.5}].",
			items = { type = "object", properties = { stat = { type = "string" }, weight = { type = "number", minimum = 0.01, maximum = 1 } }, required = { "stat", "weight" }, additionalProperties = false },
		},
		include_corrupted = { type = "boolean", description = "Weight corruption implicits (default true)." },
		include_mirrored = { type = "boolean", description = "Allow mirrored items (default true)." },
		include_scourge = { type = "boolean", description = "Weight scourge modifiers (default true in Standard and Hardcore, otherwise not offered)." },
		include_talisman = { type = "boolean", description = "Amulet: weight talisman modifiers (default false)." },
		eldritch = { type = "string", enum = { "Copy Current", "Keep regular", "Keep regular+presence", "Remove" }, description = "Helmet, body armour, gloves, boots, amulet: eldritch implicits ('Keep ...' weights them; default Copy Current)." },
		jewel_type = { type = "string", enum = { "Base", "Abyss" }, description = "Jewel sockets: which jewels to search (default Base)." },
		max_price = { type = "integer", minimum = 1, description = "Maximum price." },
		max_price_currency = { type = "string", enum = CURRENCIES, description = "Currency of max_price (default: chaos orb equivalent)." },
		max_level = { type = "integer", minimum = 1, maximum = 100, description = "Maximum level requirement." },
		sockets = { type = "integer", minimum = 1, maximum = 6, description = "Number of empty sockets." },
		links = { type = "integer", minimum = 1, maximum = 6, description = "Number of links." },
		required_stats = statFilterList("Stats the item must have, by trade site stat id (as in weightedStats), with an optional minimum."),
		blocked_stats = statFilterList("Stats the item must not have, by trade site stat id."),
	},
	required = { "slot" },
	run = function(args)
		local build = T.Build()
		local itemsTab = build.itemsTab
		itemsTab:UpdateSockets()
		local slot = T.FindSlot(build, args.slot)
		if slot.inactive then
			T.Fail("%s is not in use (an unallocated jewel socket or a missing abyssal socket).", slotLabel(slot))
		end
		local tradeQuery = itemsTab.tradeQuery
		local league = args.league or tradeQuery.pbLeague
		local weights
		if args.weights then
			weights = statWeights(args.weights)
		elseif tradeQuery.statSortSelectionList and tradeQuery.statSortSelectionList[1] then
			weights = tradeQuery.statSortSelectionList
		else
			weights = statWeights({ { stat = "FullDPS", weight = 1 }, { stat = "TotalEHP", weight = 0.5 } })
		end
		local isJewel = slot.slotName:find("Jewel") ~= nil
		local isAbyssal = slot.slotName:find("Abyssal") ~= nil
		-- The Query Options dialog's choices and its defaults (TradeQueryGenerator:RequestQuery).
		local options = {
			statWeights = weights,
			includeCorrupted = args.include_corrupted ~= false,
			includeMirrored = args.include_mirrored ~= false,
			maxPrice = args.max_price,
			maxPriceType = args.max_price and args.max_price_currency or nil,
			maxLevel = args.max_level,
			sockets = args.sockets,
			links = args.links,
			requiredMods = tradeStatFilters(args.required_stats, "required_stats"),
			blockedMods = tradeStatFilters(args.blocked_stats, "blocked_stats"),
		}
		if not isJewel and not isAbyssal and (league == "Standard" or league == "Hardcore") then
			options.includeScourge = args.include_scourge ~= false
		end
		if slot.slotName == "Amulet" then
			options.includeTalisman = args.include_talisman == true
		end
		if ({ ["Body Armour"] = true, Helmet = true, Gloves = true, Boots = true, Amulet = true })[slot.slotName] then
			options.includeEldritch = args.eldritch or "Copy Current"
		end
		if isAbyssal then
			options.jewelType = "Abyss"
		elseif isJewel then
			options.jewelType = args.jewel_type or "Base"
		end
		local tradeTypeIndex = args.trade_type and isValueInArray(TRADE_TYPES, args.trade_type) or tradeQuery.tradeTypeIndex or 1

		-- A generator of our own, so the trader's remembered choices stay as they are.
		local generator = new("TradeQueryGenerator"):TradeQueryGenerator(tradeQuery)
		local query, message
		generator.requesterContext = { }
		generator.requesterCallback = function(_, generated, errMsg)
			query, message = generated, errMsg
		end
		generator.tradeTypeIndex = tradeTypeIndex
		generator:StartQuery(slot, options)
		local co = generator.calcContext.co
		if not co then
			T.Fail("Path of Building's trader has no weighted search for %s.", slotLabel(slot))
		end
		-- The work TradeQueryGenerator:OnFrame spreads over frames, run to the end here.
		while coroutine.status(co) ~= "dead" do
			local ok, err = coroutine.resume(co, generator)
			if not ok then
				T.Fail("Path of Building could not weight the modifiers: %s", tostring(err))
			end
		end
		generator.calcContext.co = nil
		generator:FinishQuery()
		if message then
			T.Fail("%s", message)
		end
		if not query then
			T.Fail("Path of Building generated no trade query.")
		end
		local stats = tradeStatLookup()
		local weighted = { }
		for _, filter in ipairs(query.stats[1].filters) do
			t_insert(weighted, { id = filter.id, text = stats[filter.id], weight = T.Round(filter.value.weight) })
		end
		local usedWeights = { }
		for _, weight in ipairs(weights) do
			t_insert(usedWeights, { stat = weight.stat, label = weight.label, weight = T.Round(weight.weightMult) })
		end
		local result = {
			slot = slot.slotName,
			category = generator.calcContext.itemCategoryQueryStr,
			weights = usedWeights,
			minimumWeightedSum = T.Round(query.stats[1].value.min),
			weightedStats = T.Array(weighted),
			query = query,
		}
		-- As the trader composes the link when it is not logged in.
		local encoded = league and tradeHelpers.B64GzipEncode(dkjson.encode(query))
		if league and encoded and encoded ~= "" then
			local realm = args.realm or (tradeQuery.pbRealm ~= "" and tradeQuery.pbRealm) or "pc"
			result.url = tradeQuery.tradeQueryRequests:buildUrl(tradeQuery.hostName .. "trade/search", realm, league) .. "/" .. encoded
			result.league = league
		elseif not league then
			result.note = "Pass league to get a trade site link."
		else
			result.note = "Path of Building could not compress the query into a trade site link here; use the query with the trade site's search API."
		end
		return result
	end,
}
