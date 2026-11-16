-- Path of Building
--
-- Module: MCP Tools
-- The tools, prompts and resources the local MCP server (Modules/McpServer)
-- offers. Tools are grouped by tab in Modules/McpTools/*.lua and work on the
-- same objects as the UI, so every number they report is Path of Building's.
--
-- Rules every tool follows:
--  * Nothing replaces the open build while it has unsaved changes, unless
--    the caller explicitly discards them.
--  * Nothing that changes the build, or opens one of PoB's own dialogs, runs
--    while the user has a dialog open.
--  * Changes mark the build as unsaved, so PoB asks before closing it; only
--    build_save writes files.
--  * Dialogs and selections a tool uses to do its work are put back as they were.
--
local McpProtocol = LoadModule("Modules/McpProtocol")

local t_insert = table.insert
local t_remove = table.remove
local t_concat = table.concat
local s_format = string.format
local m_min = math.min
local m_max = math.max

local M = { }
local defs = { }
local defsByName = { }
local pending = { }

-- Helpers shared by the tool files.
local T = { }

T.Object = McpProtocol.Object
T.Array = McpProtocol.Array

--- Stop the tool with a message for the client.
function T.Fail(message, ...)
	if select("#", ...) > 0 then
		message = s_format(message, ...)
	end
	error({ mcpFailure = message }, 0)
end

--- Remove PoB colour codes (^7, ^xRRGGBB) from display text.
function T.Clean(text)
	if type(text) ~= "string" then
		return text
	end
	return (text:gsub("%^x%x%x%x%x%x%x", ""):gsub("%^%d", ""))
end

--- Text that will be shown in PoB's UI. PoB's font only has ASCII glyphs
--- (unless a Unicode font is in use), so other characters are replaced the
--- way pasted text is (sanitiseText). Returns the text and whether it changed.
function T.Sanitise(text)
	if main.unicode or type(text) ~= "string" then
		return text, false
	end
	local clean = sanitiseText(text)
	return clean, clean ~= text
end

--- A number fit for JSON (dkjson refuses NaN and infinities).
function T.Number(value)
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return nil
	end
	return value
end

--- Round to a sensible precision for reporting.
function T.Round(value, digits)
	value = T.Number(value)
	if not value then
		return nil
	end
	return round(value, digits or 4)
end

--- The open build, or fail with a message saying what to do.
function T.Build()
	local build = main.modes["BUILD"]
	if main.mode ~= "BUILD" or not build.targetVersion or not build.spec then
		T.Fail("No build is open in Path of Building (it shows the build list). Open one with build_open first.")
	end
	return build
end

--- Recalculate the build now, as PoB would on the next frame.
function T.Recalculate(build)
	build.buildFlag = true
	build:ProcessBuildFlag()
end

--- Which parts of the build hold unsaved changes.
function T.UnsavedParts(build)
	local parts = { }
	local flags = {
		{ build.modFlag, "build" }, { build.notesTab.modFlag, "notes" }, { build.partyTab.modFlag, "party" },
		{ build.configTab.modFlag, "config" }, { build.treeTab.modFlag or build.spec.modFlag, "tree" },
		{ build.treeTab.searchFlag, "tree search" }, { build.skillsTab.modFlag, "skills" },
		{ build.itemsTab.modFlag, "items" }, { build.calcsTab.modFlag, "calcs" },
	}
	for _, flag in ipairs(flags) do
		if flag[1] then
			t_insert(parts, flag[2])
		end
	end
	return parts
end

--- Fail unless the open build may be replaced: no dialog open, and no
--- unsaved changes unless the caller discards them.
function T.CheckCanReplaceBuild(args)
	if main.popups[1] then
		T.Fail("A dialog is open in Path of Building; ask the user to finish or close it first.")
	end
	if main.mode == "BUILD" then
		local build = main.modes["BUILD"]
		if build.targetVersion and build.spec and build:HasUnsavedChanges() and not args.discard_unsaved then
			T.Fail("The build open in Path of Building (%s) has unsaved changes (%s). Save it with build_save, or ask the user; "
				.. "pass discard_unsaved: true only if the user agreed to lose them.", build.buildName or "?", t_concat(T.UnsavedParts(build), ", "))
		end
	end
end

--- Fail unless text is build XML Path of Building can load, before anything is replaced
--- (a load that fails shows PoB's full-screen error instead).
function T.CheckBuildXML(xml)
	local parsed = type(xml) == "string" and common.xml.ParseXML(xml)
	if not parsed or type(parsed[1]) ~= "table" or parsed[1].elem ~= "PathOfBuilding" then
		T.Fail("That is not a Path of Building build (no PathOfBuilding root element).")
	end
	for _, node in ipairs(parsed[1]) do
		if type(node) == "table" and node.elem == "Build" then
			return xml
		end
	end
	T.Fail("That is not a Path of Building build (no Build section).")
end

--- Switch PoB to a build now (main:SetMode, then the switch PoB would do on
--- the next frame), and check that it opened. Call it only after everything
--- the switch depends on was checked, including T.CheckCanReplaceBuild.
function T.SwitchToBuild(...)
	if main.mode == "BUILD" and main.modes["BUILD"].targetVersion then
		-- Dev Mode saves a closing build to its file; the caller already decided this one may be
		-- replaced, so do not write changes the user chose to discard. (Shutdown clears the flag.)
		main.modes["BUILD"].abortSave = true
	end
	main:SetMode("BUILD", ...)
	main:ProcessModeChange()
	local build = main.modes["BUILD"]
	if main.mode == "BUILD" and not build.targetVersion then
		-- PoB asks whether to convert a build made for an older game version (buildMode:OpenConversionPopup).
		if main.popups[1] and main.popups[1].title == "Game Version" then
			main:ClosePopup()
		end
		build:CloseBuild()
		main:ProcessModeChange()
		T.Fail("This build was made for an older version of Path of Exile and has to be converted; open it in Path of Building to choose.")
	end
	if main.mode ~= "BUILD" or not build.spec then
		main:ProcessModeChange()
		T.Fail("Path of Building could not open the build; check that it is a valid Path of Building build.")
	end
	return build
end

--- Find an entry by name: exact (case-insensitive) match first, then a
--- unique partial match. Fails with the closest names when nothing matches.
--- @param list table
--- @param query string
--- @param getName function(entry) -> string
--- @param what string Description for messages ("socket group")
function T.Find(list, query, getName, what)
	if type(query) ~= "string" then
		T.Fail("%s must be a name", what)
	end
	local wanted = query:lower()
	local partial = { }
	for _, entry in ipairs(list) do
		local name = getName(entry)
		if name then
			local lower = T.Clean(name):lower()
			if lower == wanted then
				return entry
			elseif lower:find(wanted, 1, true) then
				t_insert(partial, entry)
			end
		end
	end
	if #partial == 1 then
		return partial[1]
	end
	local names = { }
	for _, entry in ipairs(#partial > 1 and partial or list) do
		local name = getName(entry)
		if name and #names < 15 then
			t_insert(names, T.Clean(name))
		end
	end
	if #partial > 1 then
		T.Fail("%s '%s' matches several: %s", what, query, t_concat(names, "; "))
	end
	T.Fail("No %s named '%s'. Available: %s", what, query, #names > 0 and t_concat(names, "; ") or "none")
end

--- Page through a list. Returns the slice and paging details for the result.
function T.Page(list, args, defaultLimit, maxLimit)
	local limit = m_min(m_max(math.floor(args.limit or defaultLimit), 1), maxLimit or 200)
	local offset = m_max(math.floor(args.offset or 0), 0)
	local slice = { }
	for i = offset + 1, m_min(offset + limit, #list) do
		t_insert(slice, list[i])
	end
	local page = { total = #list, offset = offset, returned = #slice }
	if offset + limit < #list then
		page.next_offset = offset + limit
	end
	return T.Array(slice), page
end

--- Schema for the common paging arguments.
function T.PageArgs(defaultLimit, maxLimit)
	return {
		limit = { type = "integer", minimum = 1, maximum = maxLimit or 200, description = s_format("How many entries to return (default %d).", defaultLimit) },
		offset = { type = "integer", minimum = 0, description = "How many entries to skip, for the next page (use next_offset from the previous result)." },
	}
end

local function failureMessage(err)
	if type(err) == "table" and err.mcpFailure then
		return err.mcpFailure
	end
	return "Path of Building raised an error: " .. tostring(err)
end

local DIALOG_OPEN = "A dialog is open in Path of Building; ask the user to finish or close it first, then try again."

-- The dialogs open now, to close later only those a tool opened itself.
local function openPopups()
	local set = { }
	for _, popup in ipairs(main.popups) do
		set[popup] = true
	end
	return set
end

local function closePopupsOpenedSince(before)
	for i = #main.popups, 1, -1 do
		if not before[main.popups[i]] then
			t_remove(main.popups, i)
		end
	end
end

-- The resolve functions handed to deferred tools, with their pending call.
local resolverEntries = setmetatable({ }, { __mode = "k" })

--- A tool result that arrives later (a download PoB runs, for example).
--- starter(resolve) must eventually call resolve(result) or resolve(nil, message);
--- do the work in the callback through T.Settle.
function T.Defer(starter, timeoutSeconds)
	return { mcpDeferred = starter, timeout = timeoutSeconds or 60 }
end

--- Run fn(...) and pass its result, or its failure message, to a deferred
--- tool's resolve. Use it for work done in a callback PoB calls later (a
--- download finishing), where a T.Fail would otherwise escape into PoB.
--- Nothing runs once the call has already been answered (timed out), and a
--- tool that changes the build does not run while the user has a dialog open.
function T.Settle(resolve, fn, ...)
	local entry = resolverEntries[resolve]
	if entry and entry.done then
		return
	end
	if entry and (entry.def.modifies or entry.def.replacesBuild) and main.popups[1] then
		return resolve(nil, DIALOG_OPEN)
	end
	local before = openPopups()
	local ok, result = pcall(fn, ...)
	closePopupsOpenedSince(before)
	if ok then
		return resolve(result)
	end
	resolve(nil, failureMessage(result))
end

--- A PoB tooltip stand-in that records its lines, for PoB functions that
--- report through a tooltip (stat comparisons, for example).
function T.LineCollector()
	local collector = { lines = { } }
	function collector:AddLine(_, text)
		for line in tostring(text):gmatch("[^\n]+") do
			local clean = T.Clean(line):gsub("^%s+", ""):gsub("%s+$", "")
			if clean ~= "" then
				t_insert(self.lines, clean)
			end
		end
	end
	function collector:AddSeparator() end
	function collector:Clear()
		wipeTable(self.lines)
	end
	return collector
end

--- Register a tool.
--- def: name, title, description, input (properties), required (list),
---   readOnly, destructive, idempotent, openWorld (annotations),
---   needsBuild (default true), modifies (changes the open build),
---   replacesBuild, usesDialog (opens one of PoB's dialogs while it runs),
---   run(args, ctx) -> result table | nil, message | T.Defer(...)
function T.Tool(def)
	assert(not defsByName[def.name], "duplicate MCP tool " .. def.name)
	def.inputSchema = {
		type = "object",
		properties = T.Object(def.input or { }),
		additionalProperties = false,
	}
	if def.required and def.required[1] then
		def.inputSchema.required = def.required
	end
	def.annotations = T.Object({
		title = def.title,
		readOnlyHint = def.readOnly == true,
		destructiveHint = not def.readOnly and def.destructive == true,
		idempotentHint = def.idempotent == true,
		openWorldHint = def.openWorld == true,
	})
	t_insert(defs, def)
	defsByName[def.name] = def
	return def
end

T.discardUnsavedArg = {
	type = "boolean",
	description = "Replace the open build even though it has unsaved changes, losing them. Only pass true when the user has agreed.",
}

-- Run a tool with the shared guards, then report through finish.
local function callTool(def, args, finish)
	if def.needsBuild ~= false then
		local ok, err = pcall(T.Build)
		if not ok then
			return finish(nil, failureMessage(err))
		end
	end
	if (def.modifies or def.replacesBuild or def.usesDialog) and main.popups[1] then
		return finish(nil, DIALOG_OPEN)
	end
	local ctx = { changed = false }
	function ctx:Changed()
		self.changed = true
	end
	-- The output before a change, to report what the change did as the side bar would.
	local outputBefore = def.modifies and main.mode == "BUILD" and main.modes["BUILD"].calcsTab and main.modes["BUILD"].calcsTab.mainOutput

	local function complete(ok, result, message)
		if ctx.changed and main.mode == "BUILD" and main.modes["BUILD"].targetVersion then
			local build = main.modes["BUILD"]
			-- Edits made here bypass the controls that would set a tab's flag.
			build.modFlag = true
			build:ProcessBuildFlag()
			if not ok or result == nil then
				-- The change stays (and shows as unsaved), so say so.
				message = (ok and (message or "the tool returned no result") or failureMessage(result)) .. " (Some changes were already made before this error; they show in Path of Building as unsaved.)"
				return finish(nil, message)
			end
			if outputBefore and type(result) == "table" and result.statChanges == nil then
				local collector = T.LineCollector()
				build:AddStatComparesToTooltip(collector, outputBefore, build.calcsTab.mainOutput, "Changes:")
				local changes = { }
				for _, line in ipairs(collector.lines) do
					if line ~= "Changes:" then
						t_insert(changes, line)
					end
				end
				result.statChanges = T.Array(changes)
			end
		end
		if not ok then
			return finish(nil, failureMessage(result))
		elseif result == nil then
			return finish(nil, message or "the tool returned no result")
		end
		return finish(result)
	end

	local popupsBefore = openPopups()
	local ok, result, message = pcall(def.run, args, ctx)
	-- Close any dialog the tool opened and left behind (never one the user opened).
	closePopupsOpenedSince(popupsBefore)
	if ok and type(result) == "table" and result.mcpDeferred then
		local entry = { def = def, deadline = os.clock() + result.timeout, timeout = result.timeout }
		-- Answers exactly once, whatever happens while answering.
		entry.resolve = function(value, err)
			if entry.done then
				return
			end
			entry.done = true
			for i, other in ipairs(pending) do
				if other == entry then
					t_remove(pending, i)
					break
				end
			end
			local completed, completeErr = pcall(complete, true, value, err)
			if not completed then
				pcall(finish, nil, failureMessage(completeErr))
			end
		end
		local resolver = function(value, err)
			entry.resolve(value, err)
		end
		resolverEntries[resolver] = entry
		t_insert(pending, entry)
		local started, startErr = pcall(result.mcpDeferred, resolver)
		if not started then
			entry.resolve(nil, failureMessage(startErr))
		end
		return
	end
	return complete(ok, result, message)
end

--- Called every frame by the server: fails deferred calls that took too long.
function M.OnFrame()
	local now = os.clock()
	for i = #pending, 1, -1 do
		local entry = pending[i]
		if entry and now > entry.deadline then
			pcall(entry.resolve, nil, s_format("No answer within %d seconds; try again later.", entry.timeout))
		end
	end
end

function M.HasPending()
	return pending[1] ~= nil
end

M.tools = {
	list = function()
		return defs
	end,
	call = callTool,
}

------------------------------------------------------------------------------
-- Resources
------------------------------------------------------------------------------

local BUILD_XML_URI = "pob://build/current.xml"

M.resources = {
	list = function()
		local list = { }
		if main.mode == "BUILD" and main.modes["BUILD"].targetVersion then
			t_insert(list, {
				uri = BUILD_XML_URI,
				name = "current-build",
				title = "Open build (XML)",
				description = "The build open in Path of Building, as the XML it would save, including unsaved changes.",
				mimeType = "application/xml",
			})
		end
		return list
	end,
	read = function(uri)
		if uri ~= BUILD_XML_URI then
			return nil, "Resource not found: " .. tostring(uri)
		end
		local ok, build = pcall(T.Build)
		if not ok then
			return nil, failureMessage(build)
		end
		local xml = build:SaveDB("code")
		if not xml then
			return nil, "Path of Building could not compose the build XML"
		end
		return { { uri = BUILD_XML_URI, mimeType = "application/xml", text = xml } }
	end,
}

------------------------------------------------------------------------------
-- Prompts
------------------------------------------------------------------------------

local promptDefs = {
	{
		name = "analyze_build",
		title = "Analyze the open build",
		description = "Review the build open in Path of Building: offence, defence, warnings and the cheapest improvements.",
		arguments = { { name = "focus", description = "Optional focus, for example 'bossing', 'mapping' or 'defence'.", required = false } },
		text = function(args)
			return "Analyze the build that is open in Path of Building" .. (args.focus and args.focus ~= "" and (", focusing on " .. args.focus) or "") .. ".\n"
				.. "1. Read build_stats (with warnings) and config_get to know the enemy and buff assumptions.\n"
				.. "2. Read tree_get, items_get and skills_get.\n"
				.. "3. Report strengths, weaknesses and anything PoB warns about.\n"
				.. "4. Before recommending a change, measure it with simulate and quote the numbers it returns. Do not change the build unless asked."
		end,
	},
	{
		name = "compare_with_guide",
		title = "Compare with a guide build",
		description = "Load a guide build into the Compare tab and list what differs from the open build.",
		arguments = { { name = "guide", description = "Build link (pobb.in, pob.codes, poe.ninja, ...) or build code.", required = true } },
		text = function(args)
			return "Compare the build open in Path of Building with this guide build: " .. tostring(args.guide) .. "\n"
				.. "1. Add it with compare_builds (action add) and read the report (action report) for the stat, tree, item, skill and config differences.\n"
				.. "2. Summarise what the guide has that the open build lacks, ordered by impact.\n"
				.. "3. Measure the most important differences with simulate before recommending them, and do not change the build unless asked."
		end,
	},
	{
		name = "best_upgrade",
		title = "Find the best upgrade for a slot",
		description = "Search for and measure candidate items for one equipment slot.",
		arguments = {
			{ name = "slot", description = "Equipment slot, for example 'Helmet' or 'Ring 1'.", required = true },
			{ name = "goal", description = "What to improve, for example 'more damage' or 'more life and resistances'.", required = false },
		},
		text = function(args)
			return "Find the best upgrade for the " .. tostring(args.slot) .. " slot of the build open in Path of Building"
				.. (args.goal and args.goal ~= "" and (", aiming for " .. args.goal) or "") .. ".\n"
				.. "1. Read the current item with items_get and the build's needs with build_stats (resistances, attributes, warnings).\n"
				.. "2. Find candidates with items_db_search (uniques and PoB's rare templates) and, if useful, items_craft; trade_search finds listings on the trade site with their prices, already measured on the build (it needs PoB's Path of Exile login; otherwise trade_query gives a link the user can open).\n"
				.. "3. Measure every candidate with simulate in that slot and rank them by the measured change, mentioning unmet requirements and prices.\n"
				.. "4. Only equip one with items_equip if the user asks; nothing is bought."
		end,
	},
	{
		name = "timeless_jewel",
		title = "Find a timeless jewel",
		description = "Use Path of Building's timeless jewel finder for a goal.",
		arguments = { { name = "goal", description = "What the jewel should provide, for example 'Militant Faith with devotion near the Witch'.", required = true } },
		text = function(args)
			return "Use Path of Building's timeless jewel finder for this goal: " .. tostring(args.goal) .. "\n"
				.. "1. Call tree_timeless_jewel with action options to see the jewel types, sockets and node names it accepts.\n"
				.. "2. Search with the weights that match the goal and present the best seeds with what they give.\n"
				.. "3. Offer the trade search link it returns; nothing is bought or opened automatically."
		end,
	},
}

M.prompts = {
	list = function()
		return promptDefs
	end,
	get = function(name, args)
		for _, def in ipairs(promptDefs) do
			if def.name == name then
				for _, arg in ipairs(def.arguments) do
					if arg.required and (args[arg.name] == nil or args[arg.name] == "") then
						return nil, "Missing required argument: " .. arg.name
					end
				end
				return {
					description = def.description,
					messages = { { role = "user", content = { type = "text", text = def.text(args) } } },
				}
			end
		end
		return nil, "Unknown prompt: " .. tostring(name)
	end,
}

M.instructions = table.concat({
	"This server drives the Path of Building window open on the user's computer (Path of Exile 1).",
	"All numbers come from Path of Building's own calculations for the open build.",
	"Start with app_status. Read before you change: build_stats, tree_get, items_get, skills_get, config_get.",
	"Use simulate to measure a change (an item, passives, masteries, a flask) without touching the build.",
	"Changes made here show in the window and mark the build as unsaved; only build_save writes files.",
	"Never discard the user's unsaved work unless they agreed. Tools that need a dialog refuse while the user has one open.",
}, " ")

-- Tool files, one per area of the UI.
-- One failing file must not take the others down.
for _, name in ipairs({ "Build", "Tree", "Items", "Trade", "Skills", "Config", "Calcs", "Compare" }) do
	local ok, err = pcall(LoadModule, "Modules/McpTools/" .. name, T)
	if not ok then
		ConPrintf("MCP server: could not load the %s tools: %s", name, tostring(err))
	end
end

M.T = T
return M
