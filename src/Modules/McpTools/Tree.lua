-- Path of Building
--
-- Module: MCP Tools - Tree
-- The passive tree: reading and searching it, allocating nodes and masteries,
-- managing the tree list, node power, the timeless jewel finder and tattoos.
--
local T = ...

local t_insert = table.insert
local t_concat = table.concat
local t_sort = table.sort
local s_format = string.format
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

-- The node categories the search filters accept; ascendancy nodes form their own category.
local NODE_CATEGORIES = { "normal", "notable", "keystone", "mastery", "socket", "ascendancy" }

local function nodeCategory(node)
	if node.ascendancyName then
		return "ascendancy"
	end
	return node.type:lower()
end

local function cleanLines(lines)
	local out = { }
	for _, line in ipairs(lines or { }) do
		t_insert(out, T.Clean(line))
	end
	return T.Array(out)
end

local function isStartNode(node)
	return node.type == "ClassStart" or node.type == "AscendClassStart"
end

local function specTitle(spec)
	return spec.title or "Default"
end

local function className(spec)
	return spec.curAscendClassId ~= 0 and spec.curAscendClassName or spec.curClassName
end

-- A failure raised by T.Fail, as a message; other errors are raised again.
local function failureText(err)
	if type(err) == "table" and err.mcpFailure then
		return err.mcpFailure
	end
	error(err, 0)
end

-- Select a dropdown entry as a click does (selIndex, then its selFunc).
local function selectEntry(control, index)
	control.selIndex = index
	if control.selFunc then
		control.selFunc(index, control.list[index])
	end
end

-- The index of a dropdown entry: by id (numbers), then exact text in one of
-- fields, then a unique partial match of its label.
local function pickEntry(list, query, what, fields)
	fields = fields or { "label" }
	local wanted = T.Clean(tostring(query)):lower()
	for i, entry in ipairs(list) do
		if type(query) == "number" and entry.id == query then
			return i
		end
		for _, field in ipairs(fields) do
			if entry[field] ~= nil and T.Clean(tostring(entry[field])):lower() == wanted then
				return i
			end
		end
	end
	local entries = { }
	for i, entry in ipairs(list) do
		if entry.label then
			t_insert(entries, { index = i, label = entry.label })
		end
	end
	return T.Find(entries, tostring(query), function(entry) return entry.label end, what).index
end

local function labels(list)
	local out = { }
	for _, entry in ipairs(list or { }) do
		t_insert(out, T.Clean(type(entry) == "table" and entry.label or tostring(entry)))
	end
	return T.Array(out)
end

-- Open one of PoB's dialogs, use it, and close whatever it left open.
local function withDialog(open, use, openFailure)
	local before = #main.popups
	local opened, openErr = pcall(open)
	if not opened or #main.popups <= before then
		while #main.popups > before do
			main:ClosePopup()
		end
		if not opened and type(openErr) == "table" and openErr.mcpFailure then
			error(openErr, 0)
		end
		T.Fail(openFailure or "Path of Building did not open its dialog%s", opened and "" or (": " .. tostring(openErr)))
	end
	local ok, result = pcall(use, main.popups[1])
	while #main.popups > before do
		main:ClosePopup()
	end
	if not ok then
		error(result, 0)
	end
	return result
end

-- The trees in the tree list.
local function specList(treeTab)
	local list = { }
	for index, spec in ipairs(treeTab.specList) do
		local used = spec:CountAllocNodes()
		t_insert(list, {
			index = index,
			title = specTitle(spec),
			class = spec.curClassName,
			ascendancy = spec.curAscendClassId ~= 0 and spec.curAscendClassName or nil,
			points = used,
			treeVersion = treeVersions[spec.treeVersion] and treeVersions[spec.treeVersion].display or spec.treeVersion,
			current = index == treeTab.activeSpec,
		})
	end
	return list
end

-- The PoB tattoo count: tattoos replacing nodes, not counting Runegrafts (TreeTab:ModifyNodePopup).
local function tattooCount(spec)
	local count = 0
	for _, override in pairs(spec.hashOverrides) do
		if override.isTattoo and not override.dn:find("Runegraft") then
			count = count + 1
		end
	end
	return count
end

-- The mastery effects a node offers, and whether each can still be chosen
-- there (TreeTab:OpenMasteryPopup leaves out effects chosen on another mastery).
local function masteryEffects(spec, node)
	local effects = { }
	for _, option in ipairs(node.masteryEffects or { }) do
		local assignedNodeId = isValueInTable(spec.masterySelections, option.effect)
		local effect = spec.tree.masteryEffects[option.effect]
		t_insert(effects, {
			id = option.effect,
			text = T.Clean(t_concat(effect and effect.sd or option.stats or { }, " / ")),
			selected = assignedNodeId == node.id or nil,
			available = not assignedNodeId or assignedNodeId == node.id,
		})
	end
	return effects
end

------------------------------------------------------------------------------
-- Reading the tree
------------------------------------------------------------------------------

T.Tool {
	name = "tree_get",
	title = "Read the passive tree",
	description = "Returns the passive tree of the open build: class, ascendancy, secondary ascendancy (bloodline), tree version, "
		.. "the tree list (every tree with its index, title, class and points; the current one is used for calculations), the top "
		.. "bar's point counter and its tooltip (required level, estimated act), allocated keystones, notables, ascendancy notables, "
		.. "masteries with their chosen effect, jewel sockets with the jewel in them, tattooed nodes (with PoB's 50-tattoo count) and "
		.. "nodes changed by timeless jewels, plus the official tree link. Pass detail 'nodes' to page through every allocated node "
		.. "with its id, type and stats. Use tree_search to find nodes that are not allocated.",
	readOnly = true,
	idempotent = true,
	input = {
		detail = { type = "string", enum = { "summary", "nodes" }, description = "summary (default), or nodes: every allocated node, paged." },
		limit = T.PageArgs(100).limit,
		offset = T.PageArgs(100).offset,
	},
	run = function(args)
		local build = T.Build()
		build:ProcessBuildFlag()
		local spec = build.spec
		local treeTab = build.treeTab
		local tree = spec.tree
		local used, ascUsed, secondaryUsed, sockets = spec:CountAllocNodes()
		local result = {
			class = spec.curClassName,
			ascendancy = spec.curAscendClassId ~= 0 and spec.curAscendClassName or nil,
			secondaryAscendancy = spec.curSecondaryAscendClassId and spec.curSecondaryAscendClassId ~= 0 and spec.curSecondaryAscendClassName or nil,
			treeVersion = treeVersions[spec.treeVersion] and treeVersions[spec.treeVersion].display or spec.treeVersion,
			treeVersionOutdated = treeTab.showConvert and true or false,
			activeSpec = { index = treeTab.activeSpec, title = specTitle(spec) },
			specs = specList(treeTab),
			points = { passives = used, ascendancy = ascUsed, secondaryAscendancy = secondaryUsed, jewelSockets = sockets },
		}
		local pointDisplay = build.controls.pointDisplay
		if pointDisplay.str then
			result.pointCounter = (T.Clean(pointDisplay.str):gsub("^%s+", ""):gsub("%s+$", ""))
		end
		if pointDisplay.req then
			local lines = { }
			for line in T.Clean(pointDisplay.req):gmatch("[^\n]+") do
				t_insert(lines, (line:gsub("^%s+", "")))
			end
			result.pointCounterTooltip = lines
		end

		local ids = { }
		for id, node in pairs(spec.allocNodes) do
			if not isStartNode(node) then
				t_insert(ids, id)
			end
		end
		t_sort(ids)

		if args.detail == "nodes" then
			local nodes = { }
			for _, id in ipairs(ids) do
				local node = spec.allocNodes[id]
				t_insert(nodes, { id = id, name = node.dn, type = nodeCategory(node), ascendancy = node.ascendancyName, stats = cleanLines(node.sd) })
			end
			result.nodes, result.page = T.Page(nodes, args, 100, 200)
			return result
		end

		local keystones, notables, ascendancyNodes, masteries, jewels, conquered = { }, { }, { }, { }, { }, { }
		for _, id in ipairs(ids) do
			local node = spec.allocNodes[id]
			if node.ascendancyName then
				if node.type == "Notable" then
					t_insert(ascendancyNodes, node.dn)
				end
			elseif node.type == "Keystone" then
				t_insert(keystones, node.dn)
			elseif node.type == "Notable" then
				t_insert(notables, node.dn)
			elseif node.type == "Mastery" then
				t_insert(masteries, { id = id, name = node.dn, effectId = spec.masterySelections[id], effect = T.Clean(t_concat(node.sd or { }, " / ")) })
			end
			if node.type == "Socket" then
				local itemId = spec.jewels[id]
				local item = itemId and build.itemsTab.items[itemId]
				t_insert(jewels, { id = id, socket = node.dn, jewel = item and item.name or nil })
			end
			if node.conqueredBy and tree.nodes[id] then
				t_insert(conquered, { id = id, original = tree.nodes[id].dn, name = node.dn, stats = cleanLines(node.sd) })
			end
		end
		local tattoos = { }
		for id, override in pairs(spec.hashOverrides) do
			local base = tree.nodes[id]
			t_insert(tattoos, {
				id = id,
				node = base and base.dn,
				tattoo = override.dn,
				stats = cleanLines(override.sd),
				allocated = spec.nodes[id] and spec.nodes[id].alloc or false,
			})
		end
		t_sort(tattoos, function(a, b) return a.id < b.id end)

		result.keystones = T.Array(keystones)
		result.notables = T.Array(notables)
		result.ascendancyNotables = T.Array(ascendancyNodes)
		result.masteries = T.Array(masteries)
		result.jewelSockets = T.Array(jewels)
		result.tattoos = T.Array(tattoos)
		result.tattooCount = tattooCount(spec)
		result.tattooLimit = 50
		result.conqueredNodes = T.Array(conquered)
		local version = treeVersions[spec.treeVersion]
		if version and version.url then
			local ok, url = pcall(spec.EncodeURL, spec, version.url)
			if ok then
				result.url = url
			end
		end
		return result
	end,
}

T.Tool {
	name = "tree_search",
	title = "Search the passive tree",
	description = "Finds passive nodes with the Tree tab's own search: the words must all appear in a node's name, stats, modifier "
		.. "names or type (Lua patterns work; \"quoted text\" is one word; start with 'oil:' to search anoint recipes). Filter by "
		.. "allocation and by node type. Each node comes with its id, name, type, stats, whether it is allocated, the points needed "
		.. "to reach it (null when it cannot be reached from the allocated tree), its ascendancy, and for masteries the effects it "
		.. "offers (with ids, and whether each is still available). Without a query it lists every node passing the filters. Pass "
		.. "the ids to tree_edit or simulate.",
	readOnly = true,
	idempotent = true,
	input = {
		query = { type = "string", maxLength = 100, description = "Search text, as typed in the Tree tab's search box, for example 'life regeneration' or 'oil:amber'." },
		allocated = { type = "string", enum = { "any", "allocated", "unallocated" }, description = "Which nodes to include (default any)." },
		types = { type = "array", items = { type = "string", enum = NODE_CATEGORIES }, maxItems = 6,
			description = "Node types to include (default all). 'ascendancy' covers every ascendancy node; the other types then only match nodes outside ascendancies." },
		limit = T.PageArgs(25).limit,
		offset = T.PageArgs(25).offset,
	},
	run = function(args)
		local build = T.Build()
		local spec = build.spec
		local viewer = build.treeTab.viewer
		local words = viewer:ParseSearchString(args.query or "")
		local proxy = { searchParams = words }
		local types
		if args.types and args.types[1] then
			types = { }
			for _, name in ipairs(args.types) do
				types[name] = true
			end
		end
		local matches = { }
		for _, node in pairs(spec.nodes) do
			local include = node.dn and not isStartNode(node) and not node.isProxy and not (node.group and node.group.isProxy)
				and not (node.type == "Mastery" and not node.masteryEffects)
			if include and args.allocated == "allocated" then
				include = node.alloc
			elseif include and args.allocated == "unallocated" then
				include = not node.alloc
			end
			if include and types then
				include = types[nodeCategory(node)]
			end
			if include and words[1] then
				include = viewer.DoesNodeMatchSearchParams(proxy, node)
			end
			if include then
				t_insert(matches, node)
			end
		end
		t_sort(matches, function(a, b)
			if (a.alloc and true or false) ~= (b.alloc and true or false) then
				return a.alloc and true or false
			end
			local da, db = a.path and #a.path or 100000, b.path and #b.path or 100000
			if da ~= db then
				return da < db
			end
			if a.dn ~= b.dn then
				return a.dn < b.dn
			end
			return a.id < b.id
		end)
		local nodes = { }
		for _, node in ipairs(matches) do
			local entry = {
				id = node.id,
				name = node.dn,
				type = nodeCategory(node),
				ascendancy = node.ascendancyName,
				allocated = node.alloc and true or false,
				pointsNeeded = not node.alloc and node.path and #node.path or nil,
			}
			if node.type == "Mastery" and node.masteryEffects then
				entry.effects = masteryEffects(spec, node)
				if node.alloc then
					entry.stats = cleanLines(node.sd)
				end
			else
				entry.stats = cleanLines(node.sd)
			end
			t_insert(nodes, entry)
		end
		local page, paging = T.Page(nodes, args, 25)
		return { query = args.query, words = T.Array(words), nodes = page, page = paging }
	end,
}

------------------------------------------------------------------------------
-- Changing the tree
------------------------------------------------------------------------------

-- Switch to the ascendancy (or bloodline) of an ascendancy node, as a left
-- click on it does in PassiveTreeView. Returns a description of the switch.
local function switchAscendancyFor(build, node, resetTree)
	local spec = build.spec
	if node.isBloodline and spec.tree.alternate_ascendancies then
		if not spec.curSecondaryAscendClass or node.ascendancyName ~= spec.curSecondaryAscendClass.id then
			for bloodlineId, bloodline in pairs(spec.tree.alternate_ascendancies) do
				if bloodline.id == node.ascendancyName then
					spec:SelectSecondaryAscendClass(bloodlineId)
					spec:AddUndoState()
					spec:SetWindowTitleWithBuildClass()
					build.buildFlag = true
					return "secondary ascendancy " .. bloodline.name
				end
			end
		end
		return
	end
	if spec.curAscendClassId ~= 0 and node.ascendancyName == spec.curAscendClassBaseName then
		return
	end
	if spec.curSecondaryAscendClass and node.ascendancyName == spec.curSecondaryAscendClass.id then
		return
	end
	for ascendClassId, ascendClass in pairs(spec.curClass.classes) do
		if ascendClass.id == node.ascendancyName then
			spec:SelectAscendClass(ascendClassId)
			spec:AddUndoState()
			spec:SetWindowTitleWithBuildClass()
			build.buildFlag = true
			return "ascendancy " .. ascendClass.name
		end
	end
	for _, class in pairs(spec.tree.classes) do
		for _, ascendClass in pairs(class.classes) do
			if ascendClass.id == node.ascendancyName then
				T.SelectClass(build, class.name, ascendClass.name, resetTree)
				return "class " .. class.name .. ", ascendancy " .. ascendClass.name
			end
		end
	end
end

-- Choose a mastery effect through PoB's mastery dialog (TreeTab:OpenMasteryPopup,
-- then a click on the effect, which calls TreeTab:SaveMasteryPopup).
local function chooseMastery(build, node, wanted)
	local spec = build.spec
	if node.type ~= "Mastery" or not node.masteryEffects then
		T.Fail("%s (%d) is not a mastery.", node.dn, node.id)
	end
	local effects = masteryEffects(spec, node)
	local effect
	local wantedId = tonumber(wanted)
	if wantedId then
		for _, entry in ipairs(effects) do
			if entry.id == wantedId then
				effect = entry
			end
		end
		if not effect then
			T.Fail("%s has no effect with id %d; its effects are listed by tree_search.", node.dn, wantedId)
		end
	else
		effect = T.Find(effects, wanted, function(entry) return entry.text end, node.dn .. " effect")
	end
	if spec.masterySelections[node.id] == effect.id and node.alloc then
		return false
	end
	if not effect.available then
		local otherId = isValueInTable(spec.masterySelections, effect.id)
		T.Fail("'%s' is already chosen on another mastery (%s, id %d); a mastery effect can only be taken once.", effect.text, spec.nodes[otherId] and spec.nodes[otherId].dn or "?", otherId)
	end
	if not node.alloc and not node.path then
		T.Fail("%s (%d) cannot be reached from the allocated tree.", node.dn, node.id)
	end
	withDialog(function()
		build.treeTab:OpenMasteryPopup(node)
	end, function(popup)
		local list = popup.controls.effect
		for index, entry in ipairs(list.list) do
			if entry.id == effect.id then
				list.selIndex = index
				list.selValue = entry
				list:OnSelClick(index, entry, false)
				return
			end
		end
		T.Fail("Path of Building does not offer '%s' on %s.", effect.text, node.dn)
	end, "Path of Building offers no effect for this mastery%s")
	return true
end

T.Tool {
	name = "tree_edit",
	title = "Edit the passive tree",
	description = "Changes the current tree of the open build the way clicks on the Tree tab do: allocate nodes (with the shortest "
		.. "path to them; an ascendancy node of another ascendancy switches to it, as a click does), remove nodes (with every node "
		.. "that depends on them), choose mastery effects (allocating the mastery if needed), and change the class, ascendancy or "
		.. "secondary ascendancy (bloodline). Steps run in that order: class, secondary ascendancy, remove, allocate, masteries. "
		.. "Nodes are given by id or exact name (find them with tree_search). It reports the nodes actually added and removed and "
		.. "every request that failed (unreachable, unknown, mastery effect taken elsewhere) without stopping the others. Measure "
		.. "first with simulate; changes are unsaved until build_save.",
	idempotent = true,
	destructive = true,
	modifies = true,
	input = {
		class = { type = "string", description = "Change the class, for example 'Witch'. Keeps the tree when it reaches the new class's start; otherwise needs reset_tree." },
		ascendancy = { type = "string", description = "Change the ascendancy (of the class after 'class'), for example 'Necromancer'." },
		reset_tree = { type = "boolean", description = "Allow a class change that resets the tree (only if the user agreed)." },
		secondary_ascendancy = { type = "string", description = "Choose the secondary ascendancy (bloodline) by name, or 'None' to remove it." },
		allocate = { type = "array", items = { type = { "string", "integer" } }, maxItems = 100, description = "Nodes to allocate, by id or name." },
		deallocate = { type = "array", items = { type = { "string", "integer" } }, maxItems = 100, description = "Allocated nodes to remove, by id or name; nodes that depend on them are removed too." },
		masteries = {
			type = "array", maxItems = 50,
			items = {
				type = "object",
				properties = {
					node = { type = { "string", "integer" }, description = "Mastery node id (names are shared by several masteries)." },
					effect = { type = { "string", "integer" }, description = "Effect id, or its text (exact or a unique part)." },
				},
				required = { "node", "effect" },
				additionalProperties = false,
			},
			description = "Mastery effects to choose: [{node, effect}].",
		},
	},
	run = function(args, ctx)
		local build = T.Build()
		local spec = build.spec
		local before = { }
		for id, node in pairs(spec.allocNodes) do
			before[id] = node.dn
		end
		local failed, deallocated, masteries, switched = { }, { }, { }, { }
		local changed = false
		local classBefore = { spec.curClassId, spec.curAscendClassId, spec.curSecondaryAscendClassId }

		if args.class or args.ascendancy then
			T.SelectClass(build, args.class, args.ascendancy, args.reset_tree)
			spec = build.spec
		end
		if args.secondary_ascendancy then
			build:UpdateSecondaryAscendancyDropdown(true)
			local drop = build.controls.secondaryAscendDrop
			if #drop.list <= 1 and args.secondary_ascendancy:lower() ~= "none" then
				T.Fail("This tree version has no secondary ascendancies.")
			end
			local index = pickEntry(drop.list, args.secondary_ascendancy, "secondary ascendancy")
			if drop.list[index].ascendClassId ~= (spec.curSecondaryAscendClassId or 0) then
				selectEntry(drop, index)
			end
		end

		for _, ref in ipairs(args.deallocate or { }) do
			local ok, err = pcall(function()
				local node = T.FindNode(spec, ref)
				if isStartNode(node) then
					T.Fail("%s is a class start; change the class instead.", node.dn)
				end
				if not node.alloc then
					T.Fail("%s (%d) is not allocated.", node.dn, node.id)
				end
				local dependents = { }
				for _, depNode in ipairs(node.depends) do
					if depNode ~= node then
						t_insert(dependents, depNode.dn)
					end
				end
				spec:DeallocNode(node)
				spec:AddUndoState()
				build.buildFlag = true
				changed = true
				t_insert(deallocated, { id = node.id, name = node.dn, alsoRemoved = T.Array(dependents) })
			end)
			if not ok then
				t_insert(failed, { node = ref, action = "deallocate", reason = failureText(err) })
			end
		end

		for _, ref in ipairs(args.allocate or { }) do
			local ok, err = pcall(function()
				local node = T.FindNode(spec, ref)
				if isStartNode(node) then
					T.Fail("%s is a class start; change the class instead.", node.dn)
				end
				if node.alloc then
					return
				end
				if node.ascendancyName then
					local switch = switchAscendancyFor(build, node, args.reset_tree)
					if switch then
						changed = true
						t_insert(switched, switch)
					end
				end
				if node.type == "Mastery" and node.masteryEffects then
					T.Fail("%s (%d) is a mastery: choose its effect with masteries [{node, effect}].", node.dn, node.id)
				end
				if not node.path then
					T.Fail("%s (%d) cannot be reached from the allocated tree.", node.dn, node.id)
				end
				spec:AllocNode(node)
				spec:AddUndoState()
				build.buildFlag = true
				changed = true
			end)
			if not ok then
				t_insert(failed, { node = ref, action = "allocate", reason = failureText(err) })
			end
		end

		for _, entry in ipairs(args.masteries or { }) do
			local ok, err = pcall(function()
				local node = T.FindNode(spec, entry.node)
				if chooseMastery(build, node, entry.effect) then
					changed = true
					t_insert(masteries, { id = node.id, name = node.dn, effect = T.Clean(t_concat(node.sd, " / ")) })
				end
			end)
			if not ok then
				t_insert(failed, { node = entry.node, action = "mastery", reason = failureText(err) })
			end
		end

		if classBefore[1] ~= spec.curClassId or classBefore[2] ~= spec.curAscendClassId or classBefore[3] ~= spec.curSecondaryAscendClassId then
			changed = true
		end
		if changed then
			ctx:Changed()
		end
		local added, removed = { }, { }
		for id, node in pairs(spec.allocNodes) do
			if not before[id] and not isStartNode(node) then
				t_insert(added, { id = id, name = node.dn })
			end
		end
		for id, name in pairs(before) do
			local node = spec.nodes[id]
			if not spec.allocNodes[id] and not (node and isStartNode(node)) then
				t_insert(removed, { id = id, name = name })
			end
		end
		t_sort(added, function(a, b) return a.id < b.id end)
		t_sort(removed, function(a, b) return a.id < b.id end)
		local used, ascUsed = spec:CountAllocNodes()
		return {
			class = spec.curClassName,
			ascendancy = spec.curAscendClassId ~= 0 and spec.curAscendClassName or nil,
			secondaryAscendancy = spec.curSecondaryAscendClassId and spec.curSecondaryAscendClassId ~= 0 and spec.curSecondaryAscendClassName or nil,
			switched = switched[1] and switched or nil,
			added = T.Array(added),
			removed = T.Array(removed),
			deallocated = deallocated[1] and deallocated or nil,
			masteries = masteries[1] and masteries or nil,
			failed = T.Array(failed),
			points = { passives = used, ascendancy = ascUsed },
		}
	end,
}

------------------------------------------------------------------------------
-- The tree list
------------------------------------------------------------------------------

-- A tree in the list, by 1-based index or title.
local function findSpec(treeTab, ref)
	if ref == nil then
		T.Fail("Give the tree with 'spec' (its index or title); tree_get lists them.")
	end
	local index = tonumber(ref)
	if index then
		if not treeTab.specList[index] then
			T.Fail("There is no tree %d; the build has %d.", index, #treeTab.specList)
		end
		return index
	end
	local entries = { }
	for i, spec in ipairs(treeTab.specList) do
		t_insert(entries, { index = i, title = specTitle(spec) })
	end
	return T.Find(entries, tostring(ref), function(entry) return entry.title end, "tree").index
end

-- Fill in and save the tree name dialog PassiveSpecListControl:RenameSpec opened.
local function saveSpecName(popup, title)
	local controls = popup.controls
	if title then
		controls.edit:SetText((T.Sanitise(title)), true)
	else
		controls.edit:SetText(controls.edit.buf, true)
	end
	if not controls.save.enabled then
		T.Fail("Give the tree a title with 'title'.")
	end
	controls.save.onClick()
end

T.Tool {
	name = "tree_specs",
	title = "Manage the tree list",
	description = "Manages the build's list of passive trees (the Tree tab's 'Manage trees...' list): list them, select the one "
		.. "used for calculations, add a new empty tree (same class and ascendancy), copy a tree, rename one, or delete one (PoB "
		.. "asks for confirmation; this call confirms, so only delete when the user asked). Trees are identified by their 1-based "
		.. "index or title, as listed. New and copied trees go to the end of the list and are not selected; select them to edit "
		.. "them with tree_edit. The last remaining tree cannot be deleted.",
	destructive = true,
	modifies = true,
	input = {
		action = { type = "string", enum = { "list", "select", "new", "copy", "rename", "delete" }, description = "What to do." },
		spec = { type = { "integer", "string" }, description = "The tree to select, copy, rename or delete: index (1-based) or title." },
		title = { type = "string", maxLength = 100, description = "Title for a new, copied or renamed tree (a copy keeps the original's title by default)." },
	},
	required = { "action" },
	run = function(args, ctx)
		local build = T.Build()
		local treeTab = build.treeTab
		local action = args.action
		local result = { action = action }
		if action == "select" then
			local index = findSpec(treeTab, args.spec)
			if index ~= treeTab.activeSpec then
				-- The tree dropdown's own steps.
				build.modFlag = true
				treeTab:SetActiveSpec(index)
				ctx:Changed()
			end
		elseif action ~= "list" then
			local listControl = new("PassiveSpecListControl"):PassiveSpecListControl(nil, { 0, 0, 350, 200 }, treeTab)
			local function selectSpec()
				local index = findSpec(treeTab, args.spec)
				listControl.selIndex = index
				listControl.selValue = treeTab.specList[index]
				return index
			end
			if action == "new" then
				if not args.title then
					T.Fail("Give the new tree a title with 'title'.")
				end
				withDialog(listControl.controls.new.onClick, function(popup)
					saveSpecName(popup, args.title)
				end)
				result.index = #treeTab.specList
			elseif action == "copy" then
				selectSpec()
				withDialog(listControl.controls.copy.onClick, function(popup)
					saveSpecName(popup, args.title)
				end)
				result.index = #treeTab.specList
			elseif action == "rename" then
				if not args.title then
					T.Fail("Give the new title with 'title'.")
				end
				result.index = selectSpec()
				withDialog(listControl.controls.rename.onClick, function(popup)
					saveSpecName(popup, args.title)
				end)
			elseif action == "delete" then
				local index = selectSpec()
				if #treeTab.specList <= 1 then
					T.Fail("The build has only one tree, and the last tree cannot be deleted.")
				end
				result.deleted = specTitle(treeTab.specList[index])
				withDialog(listControl.controls.delete.onClick, function(popup)
					popup.controls.confirm.onClick()
				end)
			end
			ctx:Changed()
		end
		result.specs = specList(treeTab)
		result.activeSpec = treeTab.activeSpec
		return result
	end,
}

------------------------------------------------------------------------------
-- Node power
------------------------------------------------------------------------------

-- The stats the Tree tab's "Show Node Power" offers (TreeTab.powerStatList).
local function nodePowerStats()
	local list = { }
	for _, stat in ipairs(data.powerStatList) do
		if not stat.ignoreForNodes then
			t_insert(list, stat)
		end
	end
	return list
end

-- Run CalcsTab:PowerBuilder to completion for one stat. PoB resumes it as a
-- coroutine over several frames (CalcsTab:BuildPower); here it is resumed
-- until it finishes, with the Tree tab's own stat and depth put back after.
local function runPowerBuilder(build, stat, maxDepth)
	local calcsTab = build.calcsTab
	local savedStat, savedDepth, savedProgress = calcsTab.powerStat, calcsTab.nodePowerMaxDepth, build.powerBuilderProgressCallback
	calcsTab.powerStat = stat
	calcsTab.nodePowerMaxDepth = maxDepth
	-- The progress callback only drives the Tree tab's toast.
	build.powerBuilderProgressCallback = nil
	local co = coroutine.create(calcsTab.PowerBuilder)
	local ok, err = true, nil
	while coroutine.status(co) ~= "dead" do
		local resumed, message = coroutine.resume(co, calcsTab)
		if not resumed then
			ok, err = false, message
			break
		end
	end
	calcsTab.powerStat, calcsTab.nodePowerMaxDepth = savedStat, savedDepth
	build.powerBuilderProgressCallback = savedProgress
	-- The node power now holds this stat; a heat map shown in the Tree tab rebuilds with its own.
	calcsTab.powerBuildFlag = true
	if not ok then
		T.Fail("Path of Building could not calculate node power: %s", tostring(err))
	end
end

local POWER_SORT_COLUMNS = { type = 1, power = 3, points = 4, per_point = 5 }

T.Tool {
	name = "tree_node_power",
	title = "Node power report",
	description = "Runs the Tree tab's 'Show Node Power' calculation for one stat and returns its Power Report: for every node, "
		.. "how much the stat changes by allocating it (or, with filter 'allocated', by removing it), the change per point spent on "
		.. "the path to it, and the points needed ('Cluster' for cluster jewel notables). Percentage stats are scaled by 100 as PoB "
		.. "shows them. It calculates every node, which can take a while on large trees; max_depth limits it to nodes within that "
		.. "many points. Use it to find the best passives to take or the weakest to drop, then confirm with simulate.",
	readOnly = true,
	input = {
		stat = { type = "string", description = "Stat key or label from the Tree tab's node power list, for example 'CombinedDPS', 'Full DPS', 'Life', 'TotalEHP' (default CombinedDPS)." },
		filter = { type = "string", enum = { "unallocated", "unallocated_and_clusters", "allocated" }, description = "Which nodes to report (default unallocated)." },
		sort = { type = "string", enum = { "power", "per_point", "points", "type" }, description = "Sort order, as the report's columns (default power)." },
		types = { type = "array", items = { type = "string", enum = { "normal", "notable", "keystone", "mastery" } }, maxItems = 4, description = "Node types to include (default all)." },
		show_masteries = { type = "boolean", description = "Include mastery effects (default true)." },
		max_depth = { type = "integer", minimum = 1, maximum = 100, description = "Only calculate nodes within this many points (PoB's node power depth limit); default all." },
		limit = T.PageArgs(25).limit,
		offset = T.PageArgs(25).offset,
	},
	run = function(args)
		local build = T.Build()
		build:ProcessBuildFlag()
		local wanted = (args.stat or "CombinedDPS"):lower()
		local stat
		local choices = { }
		for _, entry in ipairs(nodePowerStats()) do
			if entry.stat then
				t_insert(choices, entry.stat .. " (" .. entry.label .. ")")
			end
			if (entry.stat and entry.stat:lower() == wanted) or entry.label:lower() == wanted then
				stat = entry
			end
		end
		if not stat then
			T.Fail("Unknown node power stat '%s'. Choices: %s", args.stat, t_concat(choices, ", "))
		end
		if not stat.stat then
			T.Fail("'%s' only colours the heat map and has no power report; choose a specific stat: %s", stat.label, t_concat(choices, ", "))
		end
		local filter = args.filter or "unallocated"
		local sort = args.sort or "power"
		runPowerBuilder(build, stat, args.max_depth)

		local report = build.treeTab:BuildPowerReportList(stat)
		local list = new("PowerReportListControl"):PowerReportListControl(nil, { 0, 0, 700, 170 }, nil)
		list:SetReport(stat, report)
		list.showClusters = filter == "unallocated_and_clusters"
		list.allocated = filter == "allocated"
		list.showMasteries = args.show_masteries ~= false
		list:ReList()
		list:ReSort(POWER_SORT_COLUMNS[sort])

		local types
		if args.types and args.types[1] then
			types = { }
			for _, name in ipairs(args.types) do
				types[name] = true
			end
		end
		local entries = { }
		for _, entry in ipairs(list.list) do
			if not types or types[tostring(entry.type):lower()] then
				t_insert(entries, {
					id = entry.id,
					name = T.Clean(entry.name),
					type = entry.type,
					power = T.Round(entry.power),
					perPoint = T.Round(entry.pathPower),
					points = entry.pathDist == 1000 and "Anoint" or entry.pathDist,
					allocated = entry.allocated and true or false,
					stats = cleanLines(entry.sd),
				})
			end
		end
		local displayStat
		for _, ds in ipairs(build.displayStats) do
			if ds.stat == stat.stat then
				displayStat = ds
				break
			end
		end
		local _, calcBase = build.calcsTab:GetMiscCalculator()
		local page, paging = T.Page(entries, args, 25)
		return {
			stat = stat.stat,
			label = stat.label,
			current = T.Round(data.powerStatList.GetFromOutput(calcBase, stat)),
			percentScaled = displayStat and (displayStat.pc or displayStat.mod) and true or false,
			lowerIsBetter = displayStat and displayStat.lowerIsBetter or false,
			filter = filter,
			sort = sort,
			maxDepth = args.max_depth,
			nodes = page,
			page = paging,
		}
	end,
}

------------------------------------------------------------------------------
-- Timeless jewels
------------------------------------------------------------------------------

local TRADE_TYPES = { securable = 1, available = 2, onlineleague = 3, online = 4, any = 5 }
local REALMS = { pc = 1, sony = 2, xbox = 3 }

-- Run fn with OpenURL and Copy capturing the trade link instead of opening a
-- browser, and without the league list download the finder starts.
local function withTradeStubs(fn)
	local requests = common.classes.TradeQueryRequests
	if not requests then
		LoadModule("Classes/TradeQueryRequests")
		requests = common.classes.TradeQueryRequests
	end
	local savedOpen, savedCopy, savedFetch = OpenURL, Copy, requests.FetchLeagues
	local captured = { }
	OpenURL = function(url)
		t_insert(captured, url)
	end
	Copy = function() end
	requests.FetchLeagues = function() end
	local ok, result = pcall(fn, captured)
	OpenURL, Copy, requests.FetchLeagues = savedOpen, savedCopy, savedFetch
	if not ok then
		error(result, 0)
	end
	return result
end

-- The finder keeps its settings and results in build.timelessData (saved
-- with the build) and some choices on the Tree tab; a query puts them back.
local TREE_TAB_TIMELESS_FIELDS = { "tradeTypeIndex", "selectedRealmIndex", "timelessJewelLeagueSelect", "lastSearchMore", "allocatedNodesInRadiusCount", "tradeQueryRequests" }

local function withTimelessStateRestored(build, fn)
	local treeTab = build.treeTab
	local timelessData = build.timelessData
	local savedData = { }
	for key, value in pairs(timelessData) do
		savedData[key] = { value = value, contents = type(value) == "table" and copyTable(value, true) or nil }
	end
	local savedTab = { }
	for _, key in ipairs(TREE_TAB_TIMELESS_FIELDS) do
		savedTab[key] = treeTab[key]
	end
	local savedLeagues = copyTable(treeTab.tradeLeaguesList, true)
	local savedModFlag, savedTreeModFlag = build.modFlag, treeTab.modFlag
	local ok, result = pcall(fn)
	for key in pairs(timelessData) do
		if not savedData[key] then
			timelessData[key] = nil
		end
	end
	for key, saved in pairs(savedData) do
		if saved.contents then
			wipeTable(saved.value)
			for k, v in pairs(saved.contents) do
				saved.value[k] = v
			end
		end
		timelessData[key] = saved.value
	end
	for _, key in ipairs(TREE_TAB_TIMELESS_FIELDS) do
		treeTab[key] = savedTab[key]
	end
	wipeTable(treeTab.tradeLeaguesList)
	for k, v in pairs(savedLeagues) do
		treeTab.tradeLeaguesList[k] = v
	end
	build.modFlag, treeTab.modFlag = savedModFlag, savedTreeModFlag
	if not ok then
		error(result, 0)
	end
	return result
end

-- "Search for Node" entries are labelled "<name>     <first stat line>".
local function timelessModName(entry)
	local label = T.Clean(entry.label or "")
	return (label:match("^(.-)%s%s%s") or label)
end

local function timelessMods(controls)
	local mods = { }
	for _, entry in ipairs(controls.nodeSelect.list) do
		if entry.id then
			t_insert(mods, { id = entry.id, name = timelessModName(entry), stats = cleanLines(entry.descriptions), total = entry.totalMod or nil })
		end
	end
	return mods
end

local function timelessSockets(controls)
	local sockets = { }
	for _, entry in ipairs(controls.socketSelect.list) do
		local label = T.Clean(entry.label)
		t_insert(sockets, {
			id = entry.id == -1 and "all" or entry.id,
			label = (label:gsub("^# ", "")),
			allocated = entry.id ~= -1 and label:sub(1, 2) == "# " or nil,
		})
	end
	return sockets
end

-- The protect checkboxes the finder shows for the chosen socket.
local function protectBoxes(controls)
	local boxes = { }
	local i = 1
	while controls["protectAllocatedBox" .. i] do
		t_insert(boxes, controls["protectAllocatedBox" .. i])
		i = i + 1
	end
	return boxes
end

local function findTimelessMod(controls, ref, jewelLabel)
	local list = controls.nodeSelect.list
	local wanted = T.Clean(tostring(ref)):lower()
	for _, entry in ipairs(list) do
		if entry.id and entry.id:lower() == wanted then
			return entry
		end
	end
	local exact, partial = { }, { }
	for _, entry in ipairs(list) do
		if entry.id then
			local name = timelessModName(entry):lower()
			if name == wanted then
				t_insert(exact, entry)
			elseif name:find(wanted, 1, true) or t_concat(entry.descriptions or { }, " "):lower():find(wanted, 1, true) then
				t_insert(partial, entry)
			end
		end
	end
	local hits = exact[1] and exact or partial
	if #hits == 1 then
		return hits[1]
	elseif #hits > 1 then
		local names = { }
		for i = 1, m_min(#hits, 15) do
			t_insert(names, hits[i].id .. " (" .. timelessModName(hits[i]) .. ")")
		end
		T.Fail("'%s' matches several %s modifiers: %s. Pass the id.", tostring(ref), jewelLabel, t_concat(names, "; "))
	end
	T.Fail("'%s' is not a %s modifier; list them with action 'options'.", tostring(ref), jewelLabel)
end

local function timelessOptions(controls, timelessData, args)
	local jewelType = timelessData.jewelType
	local options = {
		jewelTypes = { },
		jewelType = { id = jewelType.id, label = jewelType.label },
		conquerors = labels(controls.conquerorSelect.list),
		sockets = timelessSockets(controls),
		fallbackModes = { },
	}
	for _, entry in ipairs(controls.jewelSelect.list) do
		t_insert(options.jewelTypes, { id = entry.id, label = entry.label })
	end
	for _, entry in ipairs(controls.fallbackWeightsList.list) do
		t_insert(options.fallbackModes, { stat = entry.stat, label = entry.label })
	end
	if controls.devotionSelectLabel.shown then
		options.devotionModifiers = labels(controls.devotionSelect1.list)
	end
	if controls.abyssAscendancyLabel.shown then
		options.ascendancyOutcomes = { }
		for _, entry in ipairs(controls.abyssAscendancySelect.list) do
			if entry.id then
				t_insert(options.ascendancyOutcomes, { id = entry.id, label = entry.label })
			end
		end
	end
	if controls.protectAllocatedLabel.shown() then
		local names = { }
		for _, box in ipairs(protectBoxes(controls)) do
			t_insert(names, box.label)
		end
		options.protectableNodes = T.Array(names)
	end
	options.mods, options.modsPage = T.Page(timelessMods(controls), args, 100, 300)
	return options
end

local function timelessSearch(build, controls, captured, args)
	local timelessData = build.timelessData
	local jewelLabel = timelessData.jewelType.label
	-- Conqueror (default the first entry, "Any" where there is a choice).
	selectEntry(controls.conquerorSelect, args.conqueror and pickEntry(controls.conquerorSelect.list, args.conqueror, "conqueror") or 1)
	-- Devotion modifiers (Militant Faith).
	local devotion = args.devotion or { }
	if devotion[1] and not controls.devotionSelectLabel.shown then
		T.Fail("devotion applies to Militant Faith only.")
	end
	selectEntry(controls.devotionSelect1, devotion[1] and pickEntry(controls.devotionSelect1.list, devotion[1], "devotion modifier") or 1)
	selectEntry(controls.devotionSelect2, devotion[2] and pickEntry(controls.devotionSelect2.list, devotion[2], "devotion modifier") or 1)

	if not (args.desired and args.desired[1]) and not args.fallback and not args.ascendancy_outcome then
		T.Fail("Give desired nodes, a fallback mode or (for Reclaimed Malevolence) an ascendancy_outcome to search for.")
	end
	-- Desired nodes: lines of "id, weight, secondary weight, minimum weight".
	local lines = { }
	for _, want in ipairs(args.desired or { }) do
		local entry = findTimelessMod(controls, want.node, jewelLabel)
		local minimum = want.required and "required" or tostring(want.min_weight or 0)
		t_insert(lines, s_format("%s, %s, %s, %s", entry.id, tostring(want.weight or 1), tostring(want.weight2 or 1), minimum))
	end
	controls.searchList:SetText(t_concat(lines, "\n"), true)
	controls.searchListFallback:SetText("", true)
	if args.fallback then
		local index = pickEntry(controls.fallbackWeightsList.list, args.fallback, "fallback mode", { "stat", "label" })
		selectEntry(controls.fallbackWeightsList, index)
		controls.fallbackWeightsButton.onClick()
	end
	controls.totalMinimumWeight:SetText(args.total_minimum_weight and tostring(m_floor(args.total_minimum_weight)) or "", true)
	if args.ascendancy_outcome then
		if not controls.abyssAscendancyLabel.shown then
			T.Fail("ascendancy_outcome applies to Reclaimed Malevolence only.")
		end
		selectEntry(controls.abyssAscendancySelect, pickEntry(controls.abyssAscendancySelect.list, args.ascendancy_outcome, "ascendancy outcome", { "label", "id" }))
	end
	for _, name in ipairs(args.protect or { }) do
		if not controls.protectAllocatedLabel.shown() then
			T.Fail("protect needs filter_nodes, a single socket, and Militant Faith or Reclaimed Malevolence (as in Path of Building).")
		end
		local box = T.Find(protectBoxes(controls), name, function(candidate) return candidate.label end, "protectable node")
		box.state = true
		box.changeFunc(true)
	end

	-- Path of Building leaves earlier results when it finds nothing to search.
	wipeTable(timelessData.searchResults)
	wipeTable(timelessData.sharedResults)
	local started = os.clock()
	controls.searchButton.onClick()
	local seconds = os.clock() - started

	local results = timelessData.searchResults
	local shared = timelessData.sharedResults
	local desired = { }
	for legionId, node in pairs(shared.desiredNodes or { }) do
		t_insert(desired, { id = legionId, name = T.Clean(node.displayName), index = node.desiredIdx, weight = node.nodeWeight, weight2 = node.nodeWeight2 })
	end
	t_sort(desired, function(a, b) return a.index < b.index end)
	local rows = { }
	for rank, row in ipairs(results) do
		local gives = { }
		for _, wantedNode in ipairs(desired) do
			local hit = row[wantedNode.id]
			if hit then
				t_insert(gives, { id = wantedNode.id, name = wantedNode.name, nodes = hit.targetNodeNames })
			end
		end
		t_insert(rows, {
			rank = rank,
			seed = row.seed,
			total = T.Round(row.total, 3),
			socket = row.socketId or (shared.socket and shared.socket.id),
			socketLabel = row.socketLabel and T.Clean(row.socketLabel) or nil,
			gives = T.Array(gives),
		})
	end
	local page, paging = T.Page(rows, { limit = args.max_results, offset = args.offset }, 20, 500)
	for _, entry in ipairs(desired) do
		entry.index = nil
	end
	local result = {
		jewelType = jewelLabel,
		conqueror = T.Clean(timelessData.conquerorType.label or ""),
		socket = timelessData.jewelSocket.id == -1 and "all" or timelessData.jewelSocket.id,
		searchList = timelessData.searchList,
		desired = T.Array(desired),
		resultCount = #results,
		seconds = T.Round(seconds, 2),
		results = page,
		page = paging,
	}

	if args.trade and results[1] then
		local trade = args.trade
		-- Realm and league are set without their selFuncs, which would fetch league lists; the link reads both from the dropdowns.
		controls.realmSelection.selIndex = REALMS[trade.realm or "pc"]
		controls.searchTradeLeagueSelect.list = { T.Sanitise(trade.league) }
		controls.searchTradeLeagueSelect.selIndex = 1
		selectEntry(controls.tradeTypeSelection, TRADE_TYPES[trade.trade_type or "securable"])
		controls.searchMore.state = trade.search_more == true
		if trade.start_rank then
			controls.searchResults.selIndex = m_min(trade.start_rank, #results)
		end
		local links = { }
		for _ = 1, trade.pages or 1 do
			local before = #captured
			controls.searchTradeButton.onClick()
			if #captured == before then
				break
			end
			local first = controls.searchResults.selIndex
			local last = m_min(controls.searchResults.highlightIndex or first, #results)
			local seeds = { }
			for r = first, last do
				t_insert(seeds, results[r].seed)
			end
			t_insert(links, { url = captured[#captured], fromRank = first, toRank = last, seeds = seeds })
		end
		result.trade = { league = trade.league, realm = trade.realm or "pc", tradeType = trade.trade_type or "securable", links = links }
	end
	return result
end

T.Tool {
	name = "tree_timeless_jewel",
	title = "Find a timeless jewel",
	description = "Uses Path of Building's 'Find a Timeless Jewel' finder (Tree tab). Action 'options' lists the jewel types, the "
		.. "conquerors of a type, the jewel sockets (with whether each is allocated), the modifiers the type can give (ids and stats, "
		.. "to use as desired nodes), fallback weight modes, devotion modifiers (Militant Faith), ascendancy outcomes (Reclaimed "
		.. "Malevolence) and, for a socket with filter_nodes, the allocated notables that can be protected. Action 'search' scores "
		.. "every seed of the jewel type in one socket (or all sockets) by the desired modifiers' weights and returns the best seeds "
		.. "with which nodes give what; 'trade' adds pathofexile.com trade search links for them (returned only, never opened). The "
		.. "finder's saved settings and results in the build are left as they were. Searching can take a while, longest for all sockets.",
	readOnly = true,
	usesDialog = true,
	input = {
		action = { type = "string", enum = { "options", "search" }, description = "options: what can be chosen; search: find seeds." },
		jewel_type = { type = { "string", "integer" }, description = "Jewel type: name ('Glorious Vanity', 'Militant Faith', ...), its id (1-11) or internal name ('vaal'). Required for search." },
		conqueror = { type = "string", description = "Conqueror, for example 'Avarius' (default Any)." },
		socket = { type = { "integer", "string" }, description = "Jewel socket node id, or 'all' for every socket. Required for search." },
		desired = {
			type = "array", maxItems = 100,
			items = {
				type = "object",
				properties = {
					node = { type = "string", description = "Modifier id or name, from options." },
					weight = { type = "number", minimum = 0, description = "Weight of the first stat (default 1)." },
					weight2 = { type = "number", minimum = 0, description = "Weight of the second stat, for modifiers with two (default 1)." },
					min_weight = { type = "number", minimum = 0, description = "Seeds where this modifier scores less are left out (default 0)." },
					required = { type = "boolean", description = "Leave out seeds without this modifier." },
				},
				required = { "node" },
				additionalProperties = false,
			},
			description = "The modifiers to look for, with their weights.",
		},
		fallback = { type = "string", description = "Fill the fallback list with PoB's 'Generate' weights for this stat (key or label, for example 'FullDPS' or 'Life'); used for modifiers not in desired." },
		filter_nodes = { type = "boolean", description = "Only score nodes allocated on the tree (PoB's 'Filter Nodes')." },
		filter_distance = { type = "integer", minimum = 0, maximum = 10, description = "With filter_nodes: also score unallocated nodes this many points away." },
		devotion = { type = "array", items = { type = "string" }, maxItems = 2, description = "Militant Faith: up to two devotion modifiers the jewel must have." },
		total_minimum_weight = { type = "number", minimum = 0, description = "Leave out seeds whose total weight is lower." },
		protect = { type = "array", items = { type = "string" }, maxItems = 30, description = "Allocated notables that must not be replaced (Militant Faith or Reclaimed Malevolence, with filter_nodes)." },
		ascendancy_outcome = { type = "string", description = "Reclaimed Malevolence: the ascendancy notable the seed must give." },
		max_results = { type = "integer", minimum = 1, maximum = 500, description = "How many seeds to return (default 20)." },
		offset = { type = "integer", minimum = 0, description = "Skip this many seeds (search), or modifiers (options)." },
		limit = { type = "integer", minimum = 1, maximum = 300, description = "options: how many modifiers to list (default 100)." },
		trade = {
			type = "object",
			properties = {
				league = { type = "string", description = "Trade league, for example 'Standard'." },
				realm = { type = "string", enum = { "pc", "sony", "xbox" }, description = "Default pc." },
				trade_type = { type = "string", enum = { "securable", "available", "onlineleague", "online", "any" }, description = "Listing status filter (default securable: instant buyout)." },
				search_more = { type = "boolean", description = "Put up to 180 seeds in one link instead of a few (loses the ranking order)." },
				pages = { type = "integer", minimum = 1, maximum = 10, description = "How many links, each covering the next seeds (default 1)." },
				start_rank = { type = "integer", minimum = 1, description = "Rank of the first seed in the first link (default 1)." },
			},
			required = { "league" },
			additionalProperties = false,
			description = "Also return trade search links for the found seeds.",
		},
	},
	required = { "action" },
	run = function(args)
		local build = T.Build()
		build:ProcessBuildFlag()
		if args.action == "search" and (args.jewel_type == nil or args.socket == nil) then
			T.Fail("search needs jewel_type and socket (a socket id or 'all'); action 'options' lists them.")
		end
		return withTimelessStateRestored(build, function()
			return withTradeStubs(function(captured)
				return withDialog(function()
					build.treeTab:FindTimelessJewel()
				end, function(popup)
					local controls = popup.controls
					local timelessData = build.timelessData
					if args.jewel_type ~= nil then
						local index = pickEntry(controls.jewelSelect.list, args.jewel_type, "jewel type", { "label", "name" })
						selectEntry(controls.jewelSelect, index)
					end
					if args.socket ~= nil then
						local socket = args.socket
						local index
						if socket == "all" or socket == -1 then
							index = 1
						elseif tonumber(socket) then
							for i, entry in ipairs(controls.socketSelect.list) do
								if entry.id == tonumber(socket) then
									index = i
								end
							end
							if not index then
								T.Fail("%s is not a jewel socket the finder offers; action 'options' lists them.", tostring(socket))
							end
						else
							index = pickEntry(controls.socketSelect.list, socket, "jewel socket")
						end
						selectEntry(controls.socketSelect, index)
					end
					local filter = args.filter_nodes == true or (args.action == "options" and args.socket ~= nil)
					controls.socketFilter.state = filter
					controls.socketFilter.changeFunc(filter)
					if filter then
						local distance = args.filter_distance or 0
						controls.socketFilterAdditionalDistance:SetVal(distance / 10)
						timelessData.socketFilterDistance = distance
					end
					if args.action == "options" then
						return timelessOptions(controls, timelessData, args)
					end
					return timelessSearch(build, controls, captured, args)
				end)
			end)
		end)
	end,
}

------------------------------------------------------------------------------
-- Tattoos
------------------------------------------------------------------------------

-- The nodes a right click opens the tattoo dialog on (PassiveTreeView).
local function tattooable(node)
	if node.expansionSkill then
		return false
	end
	if node.isTattoo or node.type == "Keystone"
		or (node.type == "Normal" and (node.dn == "Strength" or node.dn == "Dexterity" or node.dn == "Intelligence"))
		or (node.type == "Notable" and #node.sd > 0 and (node.sd[1]:match("+30 to Dexterity") or node.sd[1]:match("+30 to Strength") or node.sd[1]:match("+30 to Intelligence"))) then
		return true
	end
	-- Runegrafts go on unallocated masteries through the same dialog.
	return node.type == "Mastery" and not node.alloc and node.masteryEffects ~= nil
end

local function currentTattoo(spec, node)
	local override = spec.hashOverrides[node.id]
	if override then
		return { name = override.dn, stats = cleanLines(override.sd) }
	end
end

-- Open PoB's tattoo dialog (TreeTab:ModifyNodePopup) on a node and use it.
-- The dialog remembers the last choice per node name (defaultTattoo) and the
-- legacy checkbox on the Tree tab; both are put back afterwards. It opens
-- without a remembered choice, since one from the longer legacy list can
-- point past the end of the normal list.
local function withTattooDialog(build, node, includeLegacy, use)
	local treeTab = build.treeTab
	local nodeName = build.spec.tree.nodes[node.id].dn
	local savedLegacy, savedDefault = treeTab.showLegacyTattoo, treeTab.defaultTattoo[nodeName]
	treeTab.showLegacyTattoo = false
	treeTab.defaultTattoo[nodeName] = nil
	local ok, result = pcall(withDialog, function()
		treeTab:ModifyNodePopup(node)
	end, function(popup)
		local controls = popup.controls
		if includeLegacy then
			controls.showLegacyTattoo.state = true
			controls.showLegacyTattoo.changeFunc(true)
		end
		return use(controls)
	end, "Path of Building offers no tattoo for this node%s")
	treeTab.showLegacyTattoo, treeTab.defaultTattoo[nodeName] = savedLegacy, savedDefault
	if not ok then
		error(result, 0)
	end
	return result
end

local function tattooOptions(build, controls)
	local tattooNodes = build.spec.tree.tattoo.nodes
	local options = { }
	for _, entry in ipairs(controls.modSelect.list) do
		local tattoo = tattooNodes[entry.id]
		t_insert(options, {
			id = entry.id,
			name = tattoo and tattoo.dn or timelessModName(entry),
			stats = cleanLines(entry.descriptions),
			legacy = tattoo and tattoo.legacy or nil,
		})
	end
	return options
end

T.Tool {
	name = "tree_tattoos",
	title = "Tattoos and runegrafts",
	description = "Uses the Tree tab's tattoo dialog (right click on a node): 'list' shows the tattoos Path of Building offers for a "
		.. "node, 'apply' replaces the node with one (its 'Add' button), 'reset' removes the tattoo from a node ('Reset Node'). "
		.. "Tattoos go on small attribute nodes, +30 attribute notables and keystones; runegrafts on unallocated masteries. Tattoos "
		.. "are given by id or name as listed; include_legacy also lists legacy tattoos. Results include PoB's tattoo count: the game "
		.. "allows at most 50 tattoos, which PoB counts but does not enforce. simulate cannot preview tattoos; after apply or reset, "
		.. "statChanges lists what changed. Changes are unsaved until build_save.",
	destructive = true,
	modifies = true,
	usesDialog = true,
	input = {
		action = { type = "string", enum = { "list", "apply", "reset" }, description = "What to do." },
		node = { type = { "integer", "string" }, description = "The node, by id or name (find it with tree_search)." },
		tattoo = { type = "string", description = "For apply: the tattoo's id or name from list." },
		include_legacy = { type = "boolean", description = "Include legacy tattoos." },
	},
	required = { "action", "node" },
	run = function(args, ctx)
		local build = T.Build()
		local spec = build.spec
		local node = T.FindNode(spec, args.node)
		if not tattooable(node) then
			T.Fail("%s (%s) cannot be tattooed: tattoos replace small attribute nodes, +30 attribute notables and keystones; runegrafts go on unallocated masteries.", node.dn, node.type)
		end
		local baseName = spec.tree.nodes[node.id].dn
		local result = { id = node.id, node = baseName, allocated = node.alloc and true or false, tattooLimit = 50 }
		if args.action == "list" then
			result.options = withTattooDialog(build, node, args.include_legacy, function(controls)
				return tattooOptions(build, controls)
			end)
			result.current = currentTattoo(spec, node)
		elseif args.action == "apply" then
			if not args.tattoo then
				T.Fail("Give the tattoo with 'tattoo'; action 'list' shows them.")
			end
			result.replaced = currentTattoo(spec, node)
			withTattooDialog(build, node, args.include_legacy, function(controls)
				local options = tattooOptions(build, controls)
				local index
				for i, option in ipairs(options) do
					option.index = i
					if option.id == args.tattoo then
						index = i
					end
				end
				if not index then
					index = T.Find(options, args.tattoo, function(option) return option.name end, "tattoo for " .. baseName).index
				end
				selectEntry(controls.modSelect, index)
				controls.save.onClick()
			end)
			result.applied = currentTattoo(spec, spec.nodes[node.id])
			ctx:Changed()
		else
			if not spec.hashOverrides[node.id] then
				T.Fail("%s (%d) has no tattoo.", baseName, node.id)
			end
			result.removed = currentTattoo(spec, node)
			withTattooDialog(build, node, true, function(controls)
				controls.reset.onClick()
			end)
			ctx:Changed()
		end
		result.tattooCount = tattooCount(spec)
		return result
	end,
}
