-- Path of Building
--
-- One-click build setup backed by ordinary, independently saved PoB config sets.
-- This module owns the setup row above the Configuration form, the inline scan
-- markers beside its options, the Details, scan, preference and Other settings
-- popups, and the lifecycle of generated config sets: creation, regeneration
-- when the build changes, and the override layer for values the player edits
-- in a generated set. Depends on
-- ConfigAutoScan, ConfigAutoInventory, ConfigAutoModel, ConfigAutoRulesBuild,
-- ConfigAutoRulesCombat and ConfigOptions; no other ConfigAuto module requires it.
--
-- Fields this module keeps on the ConfigTab (config):
--   autoSetupCache     weak-keyed: generated set -> { stamp, hash, baseline, summary, generated, failed }
--   autoSetupRevision  build.outputRevision the last Refresh saw
--   autoSettleTime     GetTime() of the last rebuild; both debounced jobs wait refreshDelay after it
--   autoSetupPending   { set, stamp } while the active generated set waits to regenerate
--   autoCheckPending   true while a marker check waits for the build to settle or runs
--   autoCheckScan      the unfinished automatic marker scan, resumed each frame
--   autoCheckViewTime  GetTime() since which the Configuration tab has shown the indicators
--   autoSetupError     true after a failed regeneration, until one succeeds
--   autoCheckMapping   weak-keyed: set -> whether the automatic check last recorded it as mapping
--   autoDetectMarkers  var -> marker control, filled by AddMarker
--   markerStatusFrame  per-draw-pass cache of marker statuses, set by ConfigTab:Draw
local t_insert = table.insert
local t_concat = table.concat
local m_min = math.min

local M = { }
local scanner = require("Modules.ConfigAutoScan")
local support = require("Modules.ConfigAutoInventory").Support
local model = require("Modules.ConfigAutoModel")
local preferences, plainText, policy = model.Preferences, model.Text, model.Policy
local optionsByName = model.optionsByName
local guided = require("Modules.ConfigAutoRulesBuild").Guided
local windows = require("Modules.ConfigAutoRulesCombat").Windows
local stuns = require("Modules.ConfigAutoRulesCombat").Stuns
local options = require("Modules.ConfigOptions")

local activities = {
	{ val = "boss", label = "Fighting one boss", name = "Boss fight", description = "A fight without extra enemies." },
	{ val = "maps", label = "Clearing maps", name = "Mapping", description = "Regularly killing enemies." },
}
-- Debounce: the active setup regenerates, and a stale marker record is checked
-- again, once the build has gone this many milliseconds without a rebuild, so a
-- run of edits causes one scan and one undo step rather than one per edit.
M.refreshDelay = 400
-- Milliseconds per frame the automatic marker check may spend scanning
M.scanBudget = 8
-- Marks a value the user cleared after the setup had set it
M.CLEARED = { }
local CLEARED = M.CLEARED

function M.IsActivity(value)
	return value == "boss" or value == "maps"
end

-- Reason shown for a set value whose requirements the build no longer meets
function M.InvalidSettingReason(config, varData)
	return scanner.GetInvalidSettingReason(config, varData)
end

-- ============================================================================
-- Text wrapping shared by markers, popups and Details
-- ============================================================================

-- Splits text into paragraphs on newlines and word-wraps each one to width.
-- An empty paragraph is kept as "" so callers can show a gap between paragraphs.
function M.WrapParagraphs(text, height, width)
	local lines = { }
	for paragraph in (text .. "\n"):gmatch("(.-)\n") do
		if paragraph == "" then
			t_insert(lines, "")
		else
			for _, line in ipairs(main:WrapString(paragraph, height, width)) do t_insert(lines, line) end
		end
	end
	return lines
end

-- Adds wrapped text to a tooltip, one line per wrapped line and a separator per blank paragraph
function M.AddWrappedTooltip(tooltip, text, height, width)
	for _, line in ipairs(M.WrapParagraphs(text, height, width)) do
		if line == "" then tooltip:AddSeparator(5) else tooltip:AddLine(height, "^7" .. line) end
	end
end

-- ============================================================================
-- Markers
-- ============================================================================

-- Adds the inline scan indicator beside a Configuration control: a green check for
-- a value the scan applied, a red cross for a known problem, or an orange question
-- mark (click for details) when the value needs the player's confirmation.
-- Options the scanner does not cover get no indicator. isNativeInvalid is the
-- ConfigTab check for a set value whose requirements the build no longer meets.
function M.AddMarker(config, control, varData, isNativeInvalid)
	if not varData.var or not support.GetAssessment(varData).supported then return end
	local var = varData.var
	local marker = new("TooltipLabelControl"):TooltipLabelControl({ "LEFT", control, "RIGHT" }, { 4, 0, 12, 12 }, "")
	-- The plain status is asked for several times while drawing one frame
	-- (shown, icon, click); ConfigTab:Draw provides markerStatusFrame so it is
	-- computed once per draw pass.
	marker.GetStatus = function(_, details)
		if details then return scanner.GetSettingCheck(config, var, isNativeInvalid(), true) end
		local frame = config.markerStatusFrame
		local cached = frame and frame[var]
		if not cached then
			cached = { scanner.GetSettingCheck(config, var, isNativeInvalid()) }
			if frame then frame[var] = cached end
		end
		return cached[1]
	end
	marker.iconFunc = function(x, y, width, height)
		local status = marker:GetStatus()
		if status == "passed" then
			SetDrawColor(0.42, 0.87, 0.50)
			main:DrawCheckMark(x + width / 2, y + height / 2, m_min(width, height) - 1)
		elseif status then
			SetDrawColor(1, 1, 1)
			-- "CENTER_X" centres on the given x; plain "CENTER" centres on the screen
			DrawString(x + width / 2, y, "CENTER_X", height, "VAR", status == "failed" and colorCodes.UNSUPPORTED .. "x" or colorCodes.WARNING .. "?")
		end
		SetDrawColor(1, 1, 1)
	end
	marker.tooltipFunc = function(tooltip)
		tooltip:Clear()
		local status, title, reason = marker:GetStatus(true)
		if not status then return end
		tooltip:AddLine(14, "^7" .. title)
		tooltip:AddSeparator(5)
		M.AddWrappedTooltip(tooltip, reason, 14, 520)
		if status == "review" then tooltip:AddLine(14, colorCodes.WARNING .. "Click to review") end
	end
	marker.canClick = function() return marker:GetStatus() == "review" end
	marker.onClick = function()
		local _, title, reason = marker:GetStatus(true)
		main:OpenMessagePopup(title, t_concat(M.WrapParagraphs(reason, 16, 450), "\n"))
	end
	-- Most options are unset and have no status, so that cheap check runs before
	-- the native control's visibility. IsShown skips the generic anchor check,
	-- which would evaluate the same control:IsShown() a second time per frame.
	marker.shown = function()
		return main.showAutoConfigureUI ~= false and marker:GetStatus() ~= nil and control:IsShown()
	end
	marker.IsShown = marker.shown
	config.autoDetectMarkers[var] = marker
	t_insert(config.controls, marker)
	return marker
end

-- ============================================================================
-- Generated config sets
-- ============================================================================

-- The manual set a generated set was made from, or nil for a manual set
local function baseFor(config, set)
	local base = set and config.configSets[set.autoBaseId]
	return base and not base.autoActivity and base or nil
end

-- The active config set when it is a generated one
function M.Active(config)
	local set = config.configSets[config.activeConfigSetId]
	return baseFor(config, set) and set or nil
end

-- Deterministic text form of plain data, so two build states compare by string
local function serialize(value, out)
	local kind = type(value)
	if kind == "table" then
		local keys = { }
		for key in pairs(value) do t_insert(keys, key) end
		table.sort(keys, function(a, b)
			if type(a) ~= type(b) then return type(a) < type(b) end
			return a < b
		end)
		t_insert(out, "{")
		for _, key in ipairs(keys) do
			t_insert(out, tostring(key) .. "=")
			serialize(value[key], out)
			t_insert(out, ",")
		end
		t_insert(out, "}")
	elseif kind == "string" then
		t_insert(out, "s" .. #value .. ":" .. value)
	else
		t_insert(out, kind:sub(1, 1) .. tostring(value))
	end
end

local function textOf(value)
	local out = { }
	serialize(value, out)
	return t_concat(out)
end

-- Everything a generated setup is derived from, as one string. Building it is far
-- cheaper than a scan, so it decides whether the active setup needs one at all.
-- Its SHA-1 is saved with the set so a loaded set knows whether it is current.
local function sourceStamp(config, base)
	local build = config.build
	local items = { }
	for name, slot in pairs(build.itemsTab.slots) do
		local item = slot.selItemId and build.itemsTab.items[slot.selItemId]
		items[name] = { slot.selItemId or 0, slot.active == true, item and item.raw or "" }
	end
	local groups = { }
	for _, group in ipairs(build.skillsTab.socketGroupList) do
		local raw = { enabled = group.enabled ~= false, slot = group.slot, count = group.groupCount or 1,
			main = group.mainActiveSkill or 1, part = group.skillPart, include = group.includeInFullDPS == true, gems = { } }
		for _, gem in ipairs(group.gemList) do
			t_insert(raw.gems, { name = gem.nameSpec, id = gem.gemId, skill = gem.skillId, level = gem.level, quality = gem.quality,
				enabled = gem.enabled ~= false, count = gem.count or 1, global1 = gem.enableGlobal1 ~= false, global2 = gem.enableGlobal2 ~= false })
		end
		t_insert(groups, raw)
	end
	local spec = build.spec
	local nodes = { }
	if spec then
		for id in pairs(spec.allocNodes) do t_insert(nodes, id) end
		table.sort(nodes)
	end
	local party = { }
	local partyControls = build.partyTab and build.partyTab.controls
	if partyControls then
		for _, name in ipairs({ "editPartyMemberStats", "editAuras", "editCurses", "editWarcries", "editLinks" }) do
			party[name] = partyControls[name] and partyControls[name].buf or ""
		end
	end
	local settings = preferences.Get(main)
	settings.showDetails = false
	return textOf({
		base.id, base.input, base.placeholder, base.customModsList or { },
		items, build.itemsTab.activeItemSetId or 0,
		groups, build.skillsTab.activeSkillSetId or 0, build.mainSocketGroup or 0,
		nodes, spec and spec.masterySelections or { },
		spec and { spec.treeVersion, spec.curClassId, spec.curAscendClassId, spec.curSecondaryAscendClassId } or { },
		party, build.spectreList or { }, build.autoConfigureQuestEvidence or { }, build.characterLevel or 0,
		preferences.Key(settings),
	})
end

-- Saved with a generated set so a loaded one knows whether it is still current
function M.SourceHash(config, set)
	local base = baseFor(config, set)
	return base and common.sha1(sourceStamp(config, base)) or nil
end

-- Values the user changed in a generated set since it was last generated. They
-- are re-applied after every regeneration until the set is explicitly refreshed.
function M.CaptureOverrides(config, set)
	local overrides = set.autoOverrides or { }
	local state = config.autoSetupCache[set]
	local baseline = state and state.baseline
	if baseline then
		overrides = copyTable(baseline.overrides or { }, true)
		local vars = { }
		for var in pairs(set.input) do vars[var] = true end
		for var in pairs(baseline.input) do vars[var] = true end
		for var in pairs(vars) do
			local value = set.input[var]
			if value ~= baseline.input[var] then
				overrides[var] = value == nil and CLEARED or value
			end
		end
	end
	set.autoOverrides = next(overrides) and overrides or nil
	return overrides
end

local function applyOverrides(input, overrides)
	for var, value in pairs(overrides) do
		if value == CLEARED then
			input[var] = nil
		else
			input[var] = value
		end
	end
end

local function savedBaseline(set)
	return { input = copyTable(set.input), overrides = copyTable(set.autoOverrides or { }, true) }
end

-- Config sets read from a file keep their saved values; nothing is regenerated
-- until the build actually changes.
function M.Loaded(config)
	for _, set in pairs(config.configSets) do
		if baseFor(config, set) then
			-- Older generated sets wrote false for native default-on checkboxes; restore
			-- the default unless the player recorded that value as an override.
			local overrides = set.autoOverrides or { }
			for var, value in pairs(set.input) do
				if value == false and config.defaultState[var] == true and overrides[var] == nil then
					set.input[var] = true
				end
			end
			config.autoSetupCache[set] = { hash = set.autoSourceHash, baseline = savedBaseline(set) }
		end
	end
end

-- Scans the build for the setup and writes it into set (created when nil).
-- Returns the set and whether its values changed.
local function regenerate(config, base, set, activity, stamp, reset)
	local cache = config.autoSetupCache
	local settings = preferences.Get(main)
	local ok, draft, summary, report, applied = pcall(scanner.BuildSetup, config.build, base, activity == "maps", settings)
	if not ok then
		config.autoSetupError = true
		ConPrintf("Auto-configure could not set up this build: %s", tostring(draft))
		-- Remembered per source, so the same failure is not retried every rebuild
		if set then cache[set] = { stamp = stamp, failed = true, baseline = cache[set] and cache[set].baseline } end
		return
	end
	config.autoSetupError = nil
	local created = not set
	if created then
		local name = activity == "maps" and activities[2].name or activities[1].name
		local baseName = (base.title or ""):gsub("%{[%w,]+%}", ""):match("^%s*(.-)%s*$")
		if baseName ~= "" and baseName ~= "Default" then name = name .. " (" .. baseName .. ")" end
		set = config:NewConfigSet(nil, name)
		set.autoActivity, set.autoBaseId = activity, base.id
		t_insert(config.configSetOrderList, set.id)
	end
	local baseline = { input = copyTable(draft.input) }
	local overrides = reset and { } or M.CaptureOverrides(config, set)
	if reset then set.autoOverrides = nil end
	applyOverrides(draft.input, overrides)
	-- Custom modifiers edited in the generated set are kept
	if not reset and not created and textOf(set.customModsList or { }) ~= textOf(base.customModsList or { }) then
		draft.customModsList = set.customModsList
	end
	local changed = created or not scanner.SameSetupValues(set, draft)
	if changed then
		set.input, set.placeholder, set.customModsList = draft.input, draft.placeholder, draft.customModsList
	end
	scanner.RecordSettingChecks(config, set, report, applied, settings)
	cache[set] = { stamp = stamp, summary = summary, baseline = baseline }
	return set, changed
end

-- Regenerates only when the cached set was not made from the current sources.
-- force always regenerates; reset also discards the player's overrides.
local function generate(config, base, set, activity, force, reset)
	local stamp = sourceStamp(config, base)
	local state = set and config.autoSetupCache[set]
	if reset and set then
		state = nil
		config.autoSetupCache[set] = nil
	end
	if state and not force then
		if not state.stamp and state.hash == common.sha1(stamp) then
			-- Loaded from a file saved with the same sources it was generated from
			state.stamp = stamp
		end
		if state.stamp == stamp then
			if state.failed then return end
			return set, false
		end
	end
	return regenerate(config, base, set, activity, stamp, reset)
end

-- The generated set for the active set's base and the activity, if it exists
local function findSetup(config, activity)
	local current = config.configSets[config.activeConfigSetId]
	local base = baseFor(config, current) or current
	for _, id in ipairs(config.configSetOrderList) do
		local set = config.configSets[id]
		if set.autoBaseId == base.id and set.autoActivity == activity then return set, base, current end
	end
	return nil, base, current
end

-- Switches to the generated set for the activity, creating or regenerating it as
-- needed, with one undo step. Returns true when a set was selected.
function M.Select(config, activity, reset)
	if not M.IsActivity(activity) then return end
	local target, base, current = findSetup(config, activity)
	local chosen, changed = generate(config, base, target, activity, current == base, reset)
	if not chosen then return end
	config.autoSetupPending = nil
	if chosen ~= current or changed then
		config:SetActiveConfigSet(chosen.id)
		config:AddUndoState()
	end
	return true
end

-- A changed build marks the active generated setup stale; it regenerates once the
-- build has settled, and never on load. Returns true when its values changed.
local function refreshGenerated(config, rebuilt, settled)
	local set = M.Active(config)
	if not set then
		config.autoSetupPending = nil
		return
	end
	local base = baseFor(config, set)
	local state = config.autoSetupCache[set]
	local pending = config.autoSetupPending
	if pending and pending.set ~= set then pending = nil end
	if rebuilt or not state then
		local stamp = sourceStamp(config, base)
		if not state or not state.stamp then
			-- First sight of this setup (loaded from file): its saved values stand
			state = state or { baseline = savedBaseline(set) }
			state.stamp = stamp
			config.autoSetupCache[set] = state
			pending = nil
		elseif stamp ~= state.stamp then
			pending = { set = set, stamp = stamp }
		else
			pending = nil
		end
	end
	config.autoSetupPending = pending
	if pending and settled then
		config.autoSetupPending = nil
		local _, changed = regenerate(config, base, set, set.autoActivity, pending.stamp)
		if changed then
			config.input, config.placeholder = set.input, set.placeholder
			config:UpdateControls()
			config:BuildModList()
			config:AddUndoState()
			return true
		end
	end
end

-- Markers need a scan record for the active set even when the player never ran a
-- scan. This read-only pass records one for a set without a record, or with a stale
-- one, once the build has settled and the Configuration tab has shown the indicators
-- for the same delay, so loading a build or passing through the tab never scans.
-- Detect runs isolated from the real tab, so nothing here changes inputs,
-- placeholders or the undo history. The scan is spread over frames (scanBudget
-- milliseconds each); the markers keep the previous record until it finishes, and
-- it is dropped unrecorded when the build, set, activity or view changes first.
local function checkActive(config, settled)
	local build = config.build
	local scan = config.autoCheckScan
	config.autoCheckScan = nil
	if main.showAutoConfigureUI == false or build.viewMode ~= "CONFIG" then
		config.autoCheckViewTime = nil
		return
	end
	config.autoCheckViewTime = config.autoCheckViewTime or GetTime()
	local set = config.configSets[config.activeConfigSetId]
	local generated = M.Active(config)
	-- A generated setup about to regenerate records its own checks
	if generated and config.autoSetupPending then return end
	local mapping = generated and generated.autoActivity == "maps"
		or not generated and config.controls.setupActivity:GetSelValueByKey("val") == "maps"
	local current = scanner.SettingChecksState(config, set)
	local checked = config.autoCheckMapping[set]
	if current and (checked == nil or checked == mapping) then
		config.autoCheckPending = nil
		return
	end
	config.autoCheckPending = true
	if not settled or build.buildFlag or GetTime() - config.autoCheckViewTime < M.refreshDelay then return end
	if scan and (scan.set ~= set or scan.mapping ~= mapping or scan.revision ~= build.outputRevision) then scan = nil end
	if not scan then
		local settings = preferences.Get(main)
		scan = { set = set, mapping = mapping, revision = build.outputRevision, settings = settings,
			source = scanner.SetupSource(build, set.id, settings), detect = scanner.StartDetect(build, mapping, nil, nil, settings) }
	end
	local done, ok, suggestions, report = scanner.ResumeDetect(scan.detect, M.scanBudget)
	if not done then
		config.autoCheckScan = scan
		return
	end
	-- Anything else the scan was based on, such as the scan settings, starts it over
	if not scanner.SameSetupSource(scan.source, scanner.SetupSource(build, set.id, preferences.Get(main))) then return end
	config.autoCheckPending = nil
	local settings = scan.settings
	if not ok then
		ConPrintf("Auto-configure could not check this configuration: %s", tostring(suggestions))
		-- An empty record keeps the markers at "scan again" until the build changes
		report = { }
	end
	scanner.RecordSettingChecks(config, set, report, nil, settings)
	config.autoCheckMapping[set] = mapping
end

-- Called every frame by the build. Returns true when the active generated setup
-- changed and the build must recalculate.
function M.Refresh(config)
	local rebuilt = config.autoSetupRevision ~= config.build.outputRevision
	if rebuilt then
		config.autoSetupRevision = config.build.outputRevision
		config.autoSettleTime = GetTime()
	end
	local settled = not rebuilt and GetTime() - config.autoSettleTime >= M.refreshDelay
	local changed = refreshGenerated(config, rebuilt, settled)
	checkActive(config, settled)
	return changed
end

-- ============================================================================
-- Setup row above the Configuration form
-- ============================================================================

-- Narrow tabs stack Details and the summary on a second row
local function compact(config)
	return not M.Active(config) and config.width > 0 and config.width < 414
end

-- Height the setup block takes above the native form, including its gap
function M.BlockHeight(config)
	return compact(config) and 52 or 28
end

function M.AddControls(config, anchor)
	local controls = config.controls
	config.autoSetupCache = setmetatable({ }, { __mode = "k" })
	config.autoCheckMapping = setmetatable({ }, { __mode = "k" })
	config.autoDetectMarkers = { }
	config.autoSettleTime = -math.huge
	local function active() return M.Active(config) end
	local function stacked() return compact(config) end
	controls.setupActivity = new("DropDownControl"):DropDownControl(anchor, { 10, 0, 150, 20 }, copyTable(activities), function(_, entry)
		if active() then
			if not M.Select(config, entry.val) then controls.setupActivity:SelByValue(active().autoActivity, "val") end
		elseif findSetup(config, entry.val) then
			-- From the manual set, an existing setup is selected directly; a new
			-- one is only created by "Set up my build".
			M.Select(config, entry.val)
		end
	end)
	controls.setupActivity.tooltipText = "Choose what your build is doing."
	controls.autoConfigure = new("ButtonControl"):ButtonControl({ "LEFT", controls.setupActivity, "RIGHT" }, { 8, 0, 120, 20 }, "Set up my build", function()
		M.Select(config, controls.setupActivity:GetSelValueByKey("val"))
	end)
	controls.autoConfigure.shown = function() return not active() end
	controls.setupDetails = new("ButtonControl"):ButtonControl(anchor, { 0, 0, 70, 20 }, "Details...", function() M.OpenDetails(config) end)
	controls.setupDetails.x = function() return active() and 168 or stacked() and 10 or 296 end
	controls.setupDetails.y = function() return stacked() and 24 or 0 end
	-- One row: the summary and the activity's assumption follow the buttons
	controls.setupSummary = new("LabelControl"):LabelControl({ "LEFT", controls.setupDetails, "RIGHT" }, { 8, 0, 0, 14 }, function()
		if config.autoSetupError then return colorCodes.WARNING .. "Could not update. Open Details." end
		if active() then
			if config.autoSetupPending then return "^7Updating setup for your changes..." end
			local state = config.autoSetupCache[active()]
			if state and state.outdated then return colorCodes.WARNING .. "Setup is out of date. Open Details to refresh it." end
			local env = config.build.calcsTab.mainEnv
			local name = env and env.player.mainSkill.activeEffect.grantedEffect.name
			-- A set loaded from a file is only checked against a fresh scan in Details
			return (state and state.summary and "^7Setup applied" or "^7Saved setup") .. (name and (" for " .. name) or "")
		end
		return "^7Use your gear, skills and tree."
	end)
	controls.setupAssumption = new("LabelControl"):LabelControl({ "LEFT", controls.setupSummary, "RIGHT" }, { 8, 0, 0, 14 }, function()
		return "^8" .. controls.setupActivity:GetSelValueByKey("description")
	end)
	controls.setupAssumption.shown = function() return active() ~= nil end
end

-- Keeps the activity dropdown in step with the active set
function M.SyncControls(config)
	local set = M.Active(config)
	if set then config.controls.setupActivity:SelByValue(set.autoActivity, "val") end
end

-- ============================================================================
-- Details popup
-- ============================================================================

-- A set loaded from a file has no summary. Details rebuilds it read-only from the
-- current sources and records whether a fresh setup would change the saved values.
local function inspectSaved(config, set)
	local state = config.autoSetupCache[set]
	if state and state.summary then return state end
	local base = baseFor(config, set)
	local ok, draft, summary = pcall(scanner.BuildSetup, config.build, base, set.autoActivity == "maps", preferences.Get(main))
	if not ok then
		ConPrintf("Auto-configure could not check this setup: %s", tostring(draft))
		return state
	end
	state = state or { baseline = savedBaseline(set) }
	applyOverrides(draft.input, M.CaptureOverrides(config, set))
	if textOf(set.customModsList or { }) ~= textOf(base.customModsList or { }) then
		draft.customModsList = set.customModsList
	end
	state.summary, state.outdated = summary, not scanner.SameSetupValues(set, draft)
	config.autoSetupCache[set] = state
	return state
end

function M.OpenDetails(config)
	local anchor, controls = { "TOPLEFT", nil, "TOPLEFT" }, { }
	local set = M.Active(config)
	local state = set and inspectSaved(config, set)
	local rows = state and state.summary and copyTable(state.summary) or { }
	local overrides = set and set.autoOverrides or { }
	for _, row in ipairs(rows) do
		local value = scanner.SetupValueLabel(row.var, set.input, set.placeholder)
		if value ~= row.value and overrides[row.var] == nil and state.outdated then
			row.reason = "Saved as " .. value .. ". A fresh scan suggests " .. row.value .. ".\n" .. row.reason
			row.value, row.status = value, "Outdated"
		elseif value ~= row.value then
			row.value, row.status = value, "Edited"
			row.reason = "You changed this after the setup."
		end
	end
	local footerY = #rows > 0 and 260 or 44
	controls.intro = new("LabelControl"):LabelControl(anchor, { 12, 14, 0, 16 }, not set and "Set up your build to see why."
		or state and state.outdated and colorCodes.WARNING .. "A fresh scan would change this setup. Refresh setup to update it."
		or #rows > 0 and "Hover a setting to see why."
		or not (state and state.summary) and "Refresh the setup to see why."
		or "PoB used the standard settings.")
	controls.list = new("ListControl"):ListControl(anchor, { 12, 42, 576, 206 }, 22, "VERTICAL", false, rows)
	controls.list.colList = { { width = 342, label = "Setting" }, { width = 120, label = "Value" }, { width = 94, label = "Basis" } }
	controls.list.colLabels = true
	controls.list.showRowSeparators = true
	function controls.list:GetRowValue(column, _, row)
		if column == 1 then return row.label end
		if column == 2 then return row.value end
		return row.status == "Estimated" and colorCodes.WARNING .. row.status or row.status == "Left out" and "^8" .. row.status
			or row.status == "Outdated" and colorCodes.NEGATIVE .. row.status or colorCodes.SHAPER .. row.status
	end
	function controls.list:AddValueTooltip(tooltip, _, row)
		tooltip:Clear()
		M.AddWrappedTooltip(tooltip, row.reason, 14, 480)
	end
	controls.list.shown = #rows > 0
	controls.advanced = new("ButtonControl"):ButtonControl(anchor, { 12, footerY, 130, 22 }, "Advanced scan...", function()
		main:ClosePopup()
		M.OpenPopup(config)
	end)
	controls.markers = new("CheckBoxControl"):CheckBoxControl(anchor, { 310, footerY + 2, 16 }, "Show scan indicators", function(state)
		main.showAutoConfigureUI = state
		main:SaveSettings()
	end, "Show scan markers beside settings.", main.showAutoConfigureUI ~= false)
	controls.markers.labelRight = true
	controls.manual = new("ButtonControl"):ButtonControl(anchor, { 12, footerY + 32, 144, 22 }, "Use manual setup", function()
		config:SetActiveConfigSet(set.autoBaseId)
		config:AddUndoState()
		main:ClosePopup()
	end)
	controls.manual.shown = set ~= nil
	controls.retry = new("ButtonControl"):ButtonControl(anchor, { 166, footerY + 32, 130, 22 }, "Refresh setup", function()
		if M.Select(config, config.controls.setupActivity:GetSelValueByKey("val"), true) then main:ClosePopup() end
	end)
	controls.retry.tooltipText = "Rebuild; drops your manual edits."
	controls.retry.shown = set ~= nil or config.autoSetupError == true
	controls.close = new("ButtonControl"):ButtonControl(anchor, { 488, footerY + 32, 100, 22 }, "Done", function() main:ClosePopup() end)
	main:OpenPopup(600, footerY + 68, "Setup details", controls, nil, nil, "close")
end

-- ============================================================================
-- Scan popups: Auto-configure, Full configuration scan and the choice dialog
-- ============================================================================

function M.OpenChoice(suggestions, entry)
	if entry.numeric then
		local state = scanner.ScanState(suggestions)
		if not state then return end
		return M.EditGuided(suggestions, entry, state.build.configTab, function() scanner.Preview(suggestions) end)
	end
	local controls, anchor = { }, { "TOPLEFT", nil, "TOPLEFT" }
	controls.intro = new("LabelControl"):LabelControl(anchor, { 12, 16, 0, 16 }, "^7Choose the window or value to model:")
	controls.value = new("DropDownControl"):DropDownControl(anchor, { 12, 46, 476, 20 }, entry.choices)
	if entry.choiceConfirmed then controls.value:SelByValue(entry.value, "val") end
	controls.value.tooltipText = plainText.Reason(entry, entry.assessment or support.GetAssessment(entry.var), optionsByName[entry.var],
		entry.settings or preferences.Get(main))
	controls.save = new("ButtonControl"):ButtonControl(anchor, { 268, 94, 100, 22 }, "Use choice", function()
		scanner.Choose(suggestions, entry, controls.value.list[controls.value.selIndex].val)
		main:ClosePopup()
	end)
	controls.skip = new("ButtonControl"):ButtonControl(anchor, { 12, 94, 100, 22 }, "Skip setting", function()
		if entry.selected then scanner.Toggle(suggestions, entry) end
		main:ClosePopup()
	end)
	controls.close = new("ButtonControl"):ButtonControl(anchor, { 388, 94, 100, 22 }, "Cancel", function() main:ClosePopup() end)
	main:OpenPopup(500, 132, StripEscapes(optionsByName[entry.var].label), controls, nil, nil, "close")
end

local function addReasonTooltip(self, tooltip, index, value)
	tooltip:Clear()
	local option = optionsByName[value.var]
	if option then
		tooltip:AddLine(14, "^7" .. (value.section or "Configuration") .. ": " .. StripEscapes(option.label))
		tooltip:AddSeparator(6)
	end
	local text = value.var and plainText.Reason(value, value.assessment or support.GetAssessment(value.var), option, value.settings or preferences.Get(main))
		or value.reason
	if value.assumption then tooltip:AddLine(14, colorCodes.SHAPER .. "Estimated for your chosen fight.") end
	for line in (text .. "\n"):gmatch("(.-)\n") do
		if line == "" then tooltip:AddSeparator(5) else for _, wrapped in ipairs(main:WrapString(line, 14, 660)) do tooltip:AddLine(14, "^7" .. wrapped) end end
	end
end

function M.OpenReport(report)
	local controls = { }
	local anchor = { "TOPLEFT", nil, "TOPLEFT" }
	local counts = { }
	for _, entry in ipairs(report) do counts[entry.section] = (counts[entry.section] or 0) + 1 end
	local sections = { { label = "All sections (" .. #report .. ")" } }
	for _, option in ipairs(options) do
		if option.section and counts[option.section] then
			t_insert(sections, { label = option.section .. " (" .. counts[option.section] .. ")", section = option.section })
		end
	end
	local function filter()
		local section = sections[controls.section.selIndex].section
		controls.list.list = { }
		controls.list.selIndex, controls.list.selValue = nil, nil
		controls.list.controls.scrollBarV:SetOffset(0)
		for _, entry in ipairs(report) do
			if not section or entry.section == section then t_insert(controls.list.list, entry) end
		end
		controls.list:SelectIndex(1)
	end
	controls.intro = new("LabelControl"):LabelControl(anchor, { 12, 16, 0, 16 },
		"^7Settings, sources and assumptions.")
	controls.sectionLabel = new("LabelControl"):LabelControl(anchor, { 12, 46, 0, 16 }, "^7Section:")
	controls.section = new("DropDownControl"):DropDownControl(anchor, { 90, 44, 420, 20 }, sections, filter)
	controls.list = new("ListControl"):ListControl(anchor, { 12, 80, 736, 398 }, 22, "VERTICAL", false, { })
	controls.list.showRowSeparators = true
	controls.list.GetRowValue = function(self, column, index, value)
		local status = value.numeric and not value.choiceConfirmed and colorCodes.WARNING .. "[Needs value] "
			or value.unresolved and ("^8[" .. value.status .. "] ")
			or value.review and colorCodes.WARNING .. "[Ask first] "
			or value.assumption and colorCodes.SHAPER .. "[Assumed] "
			or "^2[Detected] "
		local section = controls.section.selIndex == 1 and (value.section .. ": ") or ""
		return status .. "^7" .. section .. value.label
	end
	controls.list.AddValueTooltip = addReasonTooltip
	controls.help = new("LabelControl"):LabelControl(anchor, { 12, 490, 0, 14 },
		"^7Hover a row for the reason.")
	controls.close = new("ButtonControl"):ButtonControl(anchor, { 648, 520, 100, 22 }, "Back", function() main:ClosePopup() end)
	filter()
	main:OpenPopup(760, 560, "Full configuration scan", controls, nil, nil, "close")
end

function M.OpenPopup(configTab)
	local controls = { }
	local manualDirty = false
	local anchor = { "TOPLEFT", nil, "TOPLEFT" }
	local suggestions
	local report
	local pages, page = { ready = { }, review = { } }, "ready"
	local columns = { ready = { { width = 500 }, { width = 216 } }, review = { { } } }
	local samples, sampleInputs = { }, { }
	local function scanSettings()
		local settings = preferences.Get(main)
		for key, value in pairs(samples) do settings[key] = value end
		return settings
	end
	local function changesSetting(entry)
		if configTab.input[entry.var] ~= entry.value then return true end
		local opposite = entry.value == true and windows.exclusive[entry.var]
		if opposite and (configTab.input[opposite] ~= false or configTab.placeholder[opposite] ~= nil) then return true end
		local placeholder = configTab.placeholder[entry.var]
		if entry.restorePlaceholder ~= nil then return placeholder ~= entry.restorePlaceholder end
		return placeholder ~= nil and (entry.value == 0 or entry.useDefault or entry.clearPlaceholder)
	end
	local function pendingCount()
		local count = 0
		for _, suggestion in ipairs(suggestions) do
			if suggestion.selected and not suggestion.unresolved and changesSetting(suggestion) then count = count + 1 end
		end
		return count
	end
	local function showPage(nextPage, keepSelection)
		local list = controls.list
		local selected = keepSelection and list.selValue
		page = nextPage
		list.list = pages[page]
		list.colList = columns[page]
		list.selIndex, list.selValue = nil, nil
		list.controls.scrollBarV:SetOffset(0)
		if selected then
			for index, entry in ipairs(list.list) do
				if entry == selected then list:SelectIndex(index); return end
			end
		end
		list:SelectIndex(1)
	end
	local function populate(initial)
		pages.ready, pages.review = { }, { }
		sampleInputs = { }
		local mainSkill = configTab.build.calcsTab.mainEnv.player.mainSkill
		local melee = stuns.CanSample(mainSkill)
		for _, entry in ipairs(report) do
			if melee and (entry.var == "conditionStunnedEnemyRecently" or entry.var == "conditionEnemyStunned") then
				sampleInputs.stunSampleThreshold = true
			elseif entry.var == "hoaOverkill" and controls.scenario.selIndex == 2 then
				sampleInputs.overkillHitDamage, sampleInputs.overkillLifeBeforeHit = true, true
			end
		end
		for _, suggestion in ipairs(suggestions) do
			if suggestion.review then
				t_insert(pages.review, suggestion)
			elseif changesSetting(suggestion) then
				t_insert(pages.ready, suggestion)
			end
		end
		if initial and #pages.ready == 0 and #pages.review > 0 then page = "review" end
		showPage(page, not initial)
	end
	local firstScan = true
	local function refresh()
		suggestions, report = scanner.Detect(configTab.build, controls.scenario.selIndex == 2, controls.duration.buf, nil, scanSettings())
		local set = configTab.configSets[configTab.activeConfigSetId]
		local state = scanner.ScanState(suggestions)
		if not set.autoActivity then scanner.RecordSettingChecks(configTab, set, report, nil, state.settings) end
		manualDirty = false
		controls.duration.scanned = controls.duration.buf
		-- Keep the callback alive with the popup, not with the global scan cache.
		-- Otherwise it closes over suggestions and defeats the cache's weak key.
		controls.list.onScanChange = function(updated) report = updated; populate() end
		local callback = setmetatable({ controls.list.onScanChange }, { __mode = "v" })
		state.onChange = function(updated) local update = callback[1]; if update then update(updated) end end
		populate(firstScan)
		firstScan = false
	end
	controls.showMarkers = new("CheckBoxControl"):CheckBoxControl(anchor, { 432, 45, 16 }, "Show scan indicators", function(state)
		main.showAutoConfigureUI = state
		main:SaveSettings()
	end, "Show markers; saved for all builds.", main.showAutoConfigureUI ~= false)
	controls.showMarkers.labelRight = true
	controls.sensitivity = new("ButtonControl"):ButtonControl(anchor, { 608, 42, 140, 22 }, "Sensitivity...", function()
		M.OpenSensitivity(main, refresh)
	end)
	controls.sensitivity.tooltipText = "Your own thresholds and combat pace."
	controls.scenarioLabel = new("LabelControl"):LabelControl(anchor, { 12, 16, 0, 16 }, "^7Combat:")
	controls.scenario = new("DropDownControl"):DropDownControl(anchor, { 90, 14, 250, 20 }, { "Boss fight (no kills)", "Mapping (regular kills)" }, refresh)
	if configTab.configSets[configTab.activeConfigSetId].autoActivity == "maps" then controls.scenario.selIndex = 2 end
	controls.scenario.tooltipText = "Which on-kill effects to detect."
	controls.durationLabel = new("LabelControl"):LabelControl(anchor, { 358, 16, 0, 16 }, "^7Fight time:")
	controls.duration = new("EditControl"):EditControl(anchor, { 442, 14, 72, 20 }, "4", nil, "%D", 3)
	controls.duration.tooltipText = "Fight time for stacks (1-300 s)."
	controls.durationUnits = new("LabelControl"):LabelControl(anchor, { 522, 16, 0, 16 }, "^7seconds")
	controls.scan = new("ButtonControl"):ButtonControl(anchor, { 648, 14, 100, 20 }, "Scan again", refresh)
	controls.scan.enabled = function() local value = tonumber(controls.duration.buf) return value and value >= 1 and value <= 300 end
	controls.ready = new("ButtonControl"):ButtonControl(anchor, { 12, 42, 120, 22 }, function() return "Ready (" .. #pages.ready .. ")" end, function()
		showPage("ready")
	end)
	controls.ready.locked = function() return page == "ready" end
	controls.ready.tooltipText = "Suggested changes to apply."
	controls.review = new("ButtonControl"):ButtonControl(anchor, { 140, 42, 120, 22 }, function() return "Review (" .. #pages.review .. ")" end, function()
		showPage("review")
	end)
	controls.review.locked = function() return page == "review" end
	controls.review.tooltipText = "Answers and values the scan needs."
	controls.list = new("ListControl"):ListControl(anchor, { 12, 72, 736, 292 }, 22, "VERTICAL", false, { })
	controls.list.showRowSeparators = true
	controls.list.GetRowValue = function(self, column, index, value)
		local option = optionsByName[value.var]
		if column == 2 then
			local current = configTab.input[value.var]
			if current == nil or current == 0 and option.type == "count" and not option.allowZero then
				current = configTab.placeholder[value.var]
				if current == nil then current = configTab.defaultState[value.var] end
			end
			if current == nil and option.type == "check" then current = false end
			local before = plainText.ValueLabel(value.var, option, current)
			local after = plainText.ValueLabel(value.var, option, value.value)
			return "^8" .. before .. "  >  ^7" .. after
		end
		local status = value.unresolved and "^8[Unavailable] "
			or value.numeric and not value.choiceConfirmed and colorCodes.WARNING .. "[Needs value] "
			or value.choices and not value.choiceConfirmed and colorCodes.WARNING .. "[Choose] "
			or value.selected and "^2[x] " or "^7[ ] "
		if page == "ready" and value.assumption then status = status .. colorCodes.SHAPER .. "[Assumed] " end
		local label = page == "ready" and option and StripEscapes(option.label):gsub(":$", "") or value.label
		return status .. "^7" .. label
	end
	controls.list.AddValueTooltip = addReasonTooltip
	controls.list.OnSelClick = function(self, index, value)
		if value.choices or value.numeric then M.OpenChoice(suggestions, value) else scanner.Toggle(suggestions, value) end
	end
	controls.list.OnSelKeyDown = function(self, index, value, key)
		if key == "SPACE" then self:OnSelClick(index, value) end
	end
	controls.empty = new("LabelControl"):LabelControl(anchor, { 24, 84, 0, 14 }, function()
		return page == "ready" and "^7No automatic changes for this build." or "^7No settings need your input."
	end)
	controls.empty.shown = function() return #controls.list.list == 0 end
	controls.list.shown = function() return #controls.list.list > 0 end
	controls.help = new("LabelControl"):LabelControl(anchor, { 12, 376, 0, 14 }, function()
		if manualDirty then return colorCodes.WARNING .. "Settings changed. Scan again." end
		local state = scanner.ScanState(suggestions)
		if state and state.previewError then return "^1Preview failed: " .. state.previewError:match("^[^\n]*") .. " Click Scan again." end
		if not scanner.ScanIsCurrent(state) then return colorCodes.WARNING .. "Your build changed. Scan again." end
		local problem = scanner.SelectionError(configTab, suggestions)
		return problem and (colorCodes.WARNING .. problem)
			or controls.duration.buf ~= controls.duration.scanned and colorCodes.WARNING .. "Fight time changed. Scan again."
			or "^7Click to select, hover for details."
	end)
	controls.save = new("ButtonControl"):ButtonControl(anchor, { 468, 408, 168, 22 }, function()
		return "Apply " .. pendingCount() .. " settings"
	end, function()
		scanner.Apply(configTab, suggestions)
		main:ClosePopup()
	end)
	controls.save.enabled = function()
		local state = scanner.ScanState(suggestions)
		return not manualDirty and pendingCount() > 0 and controls.duration.buf == controls.duration.scanned
		and not state.previewError and scanner.ScanIsCurrent(state)
		and preferences.Key(state.settings) == preferences.Key(scanSettings()) and not scanner.SelectionError(configTab, suggestions) end
	controls.details = new("ButtonControl"):ButtonControl(anchor, { 12, 408, 136, 22 }, "Full scan...", function() M.OpenReport(report) end)
	controls.other = new("ButtonControl"):ButtonControl(anchor, { 156, 408, 160, 22 }, "Other settings...", function()
		M.OpenGuided(configTab, support.GetInventory(), scanner.Apply, function() manualDirty = true end)
	end)
	controls.samples = new("ButtonControl"):ButtonControl(anchor, { 324, 408, 136, 22 }, "Hit samples...", function()
		M.OpenHitSamples(samples, sampleInputs, function(values)
			samples, page = values, "review"
			refresh()
		end)
	end)
	controls.samples.shown = function() return next(sampleInputs) ~= nil end
	controls.samples.tooltipText = "Known numbers for Stun or overkill."
	controls.close = new("ButtonControl"):ButtonControl(anchor, { 648, 408, 100, 22 }, "Cancel", function() main:ClosePopup() end)
	refresh()
	main:OpenPopup(760, 446, "Auto-configure", controls, nil, nil, "close")
end

-- ============================================================================
-- Preference popups (sensitivity, combat model, hit samples) and the Other
-- settings popup for Guided choices. The logic modules own their data.
-- ============================================================================

-- Shared "validate, persist on the owner, close, notify" save button.
local function saveButton(controls, anchor, rect, label, read, owner, onSaved)
	controls.save = new("ButtonControl"):ButtonControl(anchor, rect, label, function()
		local values = read()
		if not values then return end
		owner.autoConfigureSettings = values
		if owner.SaveSettings then owner:SaveSettings() end
		main:ClosePopup()
		if onSaved then onSaved(values) end
	end)
	controls.save.enabled = function() return read() ~= nil end
end
function M.OpenSensitivity(owner, onSaved)
	owner = owner or main
	local settings, controls, anchor = preferences.Get(owner), { }, { "TOPLEFT", nil, "TOPLEFT" }
	local page, fieldPages = "confidence", { }
	local function confidenceShown() return page == "confidence" end
	controls.confidence = new("ButtonControl"):ButtonControl(anchor, { 12, 14, 124, 22 }, "Confidence", function() page = "confidence" end)
	controls.confidence.locked = confidenceShown
	controls.pace = new("ButtonControl"):ButtonControl(anchor, { 144, 14, 136, 22 }, "Combat pace", function() page = "pace" end)
	controls.pace.locked = function() return page == "pace" end
	controls.presetLabel = new("LabelControl"):LabelControl(anchor, { 12, 54, 0, 16 }, "Preset:")
	controls.presetLabel.shown = confidenceShown
	local presetList = { preferences.presets[1].label, preferences.presets[2].label, preferences.presets[3].label, "Custom" }
	local function updatePreset()
		controls.preset.selIndex = 4
		for index, preset in ipairs(preferences.presets) do
			local matches = true
			for key, value in pairs(preset.values) do if not controls[key] or tonumber(controls[key].buf) ~= value then matches = false end end
			if matches then controls.preset.selIndex = index end
		end
	end
	controls.preset = new("DropDownControl"):DropDownControl(anchor, { 295, 52, 160, 20 }, presetList, function(index)
		if not controls.blockThreshold or not preferences.presets[index] then return end
		for key, value in pairs(preferences.presets[index].values) do controls[key]:SetText(tostring(value)) end
		updatePreset()
	end)
	controls.preset.shown = confidenceShown
	controls.preset.tooltipText = "Changes thresholds only."
	local nextY = { confidence = 84, pace = 52 }
	for _, field in ipairs(preferences.fields) do
		local group = field.group or "confidence"
		fieldPages[field.key] = group
		local function shown() return page == group end
		local y = nextY[group]
		nextY[group] = y + 27
		controls[field.key .. "Label"] = new("LabelControl"):LabelControl(anchor, { 12, y + 2, 0, 14 }, field.label)
		controls[field.key] = new("EditControl"):EditControl(anchor, { 295, y, 72, 20 }, tostring(settings[field.key]), nil, "^%d%.%-", 7, updatePreset)
		controls[field.key].tooltipText = field.help .. "\nAllowed range: " .. field.min .. " to " .. field.max .. "."
		controls[field.key].borderFunc = function()
			local value = tonumber(controls[field.key].buf)
			if not value or value < field.min or value > field.max then return 1, 0.4, 0.2 end
			return 0.5, 0.5, 0.5
		end
		controls[field.key .. "Unit"] = new("LabelControl"):LabelControl(anchor, { 377, y + 2, 0, 14 }, field.unit)
		controls[field.key .. "Label"].shown = shown
		controls[field.key].shown = shown
		controls[field.key .. "Unit"].shown = shown
	end
	updatePreset()
	controls.askAllAssumptions = new("CheckBoxControl"):CheckBoxControl(anchor, { 12, 226, 16 }, "Ask before using combat assumptions", nil,
		"Leaves estimates unchecked for you.", settings.askAllAssumptions)
	controls.askAllAssumptions.labelRight = true
	controls.askAllAssumptions.shown = confidenceShown
	controls.showDetails = new("CheckBoxControl"):CheckBoxControl(anchor, { 12, 252, 16 }, "Show calculation details", nil,
		"Show calculation rules in tooltips.", settings.showDetails)
	controls.showDetails.labelRight = true
	controls.showDetails.shown = confidenceShown
	local function read()
		local values = preferences.Get(owner)
		values.askAllAssumptions, values.showDetails = controls.askAllAssumptions.state, controls.showDetails.state
		for _, field in ipairs(preferences.fields) do values[field.key] = controls[field.key].buf end
		return preferences.Validate(values)
	end
	controls.help = new("LabelControl"):LabelControl(anchor, { 12, 282, 0, 14 }, function()
		local _, err, invalidField = read()
		if err then
			local tab = fieldPages[invalidField] == "pace" and "Combat pace" or "Confidence"
			return colorCodes.WARNING .. "Check the highlighted fields in " .. tab .. "."
		end
		return "^7These settings apply to all builds."
	end)
	saveButton(controls, anchor, { 203, 312, 140, 22 }, "Save settings", read, owner, onSaved)
	controls.close = new("ButtonControl"):ButtonControl(anchor, { 355, 312, 100, 22 }, "Cancel", function() main:ClosePopup() end)
	controls.model = new("ButtonControl"):ButtonControl(anchor, { 12, 312, 172, 22 }, "Combat model...", function() M.OpenCombatModel(owner, onSaved) end)
	main:OpenPopup(470, 350, "Auto-configure sensitivity", controls, nil, nil, "close")
end
function M.OpenCombatModel(owner, onSaved)
	owner = owner or main
	local settings, controls, anchor = preferences.Get(owner), { }, { "TOPLEFT", nil, "TOPLEFT" }
	controls.intro = new("LabelControl"):LabelControl(anchor, { 12, 16, 0, 14 }, "^7Modelling choices for the scan.")
	for index, field in ipairs(preferences.modelChoices) do
		local y = 52 + (index - 1) * 38
		controls[field.key .. "Label"] = new("LabelControl"):LabelControl(anchor, { 12, y + 2, 0, 14 }, field.label)
		controls[field.key] = new("DropDownControl"):DropDownControl(anchor, { 220, y, 288, 20 }, field.list)
		controls[field.key]:SelByValue(settings[field.key], "val")
	end
	for index, field in ipairs(preferences.modelFields) do
		local y = 178 + (index - 1) * 38
		controls[field.key .. "Label"] = new("LabelControl"):LabelControl(anchor, { 12, y + 2, 0, 14 }, field.label)
		controls[field.key] = new("EditControl"):EditControl(anchor, { 320, y, 72, 20 }, tostring(settings[field.key]), nil, "^%d%.%-", 8)
		controls[field.key .. "Unit"] = new("LabelControl"):LabelControl(anchor, { 404, y + 2, 0, 14 }, field.unit)
		controls[field.key].tooltipText = "Tenths of a metre to model."
	end
	controls.solo = new("CheckBoxControl"):CheckBoxControl(anchor, { 12, 264, 16 }, "Solo fight: no other players removing your Hallowing Flames",
		nil, nil, settings.assumeSolo)
	controls.solo.labelRight = true
	local function read()
		local values = preferences.Get(owner)
		values.assumeSolo = controls.solo.state
		for _, field in ipairs(preferences.modelChoices) do values[field.key] = controls[field.key].list[controls[field.key].selIndex].val end
		for _, field in ipairs(preferences.modelFields) do
			values[field.key] = controls[field.key].buf
			local number = tonumber(values[field.key])
			if not number or math.abs(number * 10 - math.floor(number * 10 + 0.5)) > 1e-7 then return nil end
		end
		return preferences.Validate(values)
	end
	controls.help = new("LabelControl"):LabelControl(anchor, { 12, 302, 0, 14 }, function() return read()
		and "^7Quest choices are never guessed." or colorCodes.WARNING .. "Enter a valid distance (0.1 m steps)." end)
	saveButton(controls, anchor, { 244, 342, 140, 22 }, "Save model", read, owner, onSaved)
	controls.close = new("ButtonControl"):ButtonControl(anchor, { 408, 342, 100, 22 }, "Cancel", function() main:ClosePopup() end)
	main:OpenPopup(520, 380, "Auto-configure combat model", controls, nil, nil, "close")
end

function M.OpenHitSamples(current, relevant, onConfirm)
	local controls, anchor = { }, { "TOPLEFT", nil, "TOPLEFT" }
	local rowY = 44
	controls.intro = new("LabelControl"):LabelControl(anchor, { 12, 16, 0, 14 }, "^7Optional numbers; blank if unknown.")
	for _, field in ipairs(preferences.sampleFields) do
		if relevant[field.key] then
			local value = current[field.key] or 0
			controls[field.key .. "Label"] = new("LabelControl"):LabelControl(anchor, { 12, rowY + 2, 0, 14 }, field.label)
			controls[field.key] = new("EditControl"):EditControl(anchor, { 306, rowY, 172, 20 }, value > 0 and tostring(value) or "", nil, "%D", 13)
			controls[field.key].tooltipText = field.help
			rowY = rowY + 28
		end
	end
	local function read()
		local values = copyTable(current)
		for _, field in ipairs(preferences.sampleFields) do
			local input = controls[field.key]
			if input then
				local value = input.buf == "" and 0 or tonumber(input.buf)
				if not value or value ~= value or value < 0 or value > field.max then return nil, "Enter a number from 0 to "
					.. string.format("%.0f", field.max) .. "." end
				values[field.key] = value
			end
		end
		local hit, life = values.overkillHitDamage or 0, values.overkillLifeBeforeHit or 0
		if hit > 0 or life > 0 then
			if hit <= 0 or life <= 0 then return nil, "Enter both numbers from the same kill." end
			if hit < life then return nil, "Hit must be at least the Life left." end
		end
		return values
	end
	controls.help = new("LabelControl"):LabelControl(anchor, { 12, rowY + 8, 0, 14 }, function()
		local _, err = read()
		return err and colorCodes.WARNING .. err or "^7You can review the estimates first."
	end)
	controls.save = new("ButtonControl"):ButtonControl(anchor, { 224, rowY + 36, 140, 22 }, "Rescan", function()
		local values = read()
		if values then
			main:ClosePopup()
			onConfirm(values)
		end
	end)
	controls.save.enabled = function() return read() ~= nil end
	controls.close = new("ButtonControl"):ButtonControl(anchor, { 378, rowY + 36, 100, 22 }, "Cancel", function() main:ClosePopup() end)
	main:OpenPopup(490, rowY + 72, "Hit samples", controls, nil, nil, "close")
end
function M.EditGuided(entries, entry, configTab, onConfirmed)
	if not entry.available then return end
	local controls, anchor = { }, { "TOPLEFT", nil, "TOPLEFT" }
	local lines = { }
	for paragraph in (entry.reason .. "\n"):gmatch("(.-)\n") do
		if paragraph == "" then t_insert(lines, "")
		else for _, line in ipairs(main:WrapString(paragraph, 14, 476)) do t_insert(lines, line) end end
	end
	for index, line in ipairs(lines) do
		controls["explain" .. index] = new("LabelControl"):LabelControl(anchor, { 12, 12 + (index - 1) * 18, 0, 14 }, "^7" .. line)
	end
	local y = 28 + #lines * 18
	if entry.choices then
		controls.value = new("DropDownControl"):DropDownControl(anchor, { 12, y, 476, 20 }, entry.choices)
		local current = entry.current; if entry.choiceConfirmed then current = entry.value end
		if current ~= nil then controls.value:SelByValue(current, "val") end
	else
		local _, _, scale = guided.Bounds(entry, entry.valueBuild or configTab.build)
		local current = entry.current; if entry.choiceConfirmed then current = entry.value end
		if current == nil then
			if entry.useDefault then current = entry.restorePlaceholder else current = configTab.placeholder[entry.var] end
		end
		controls.value = new("EditControl"):EditControl(anchor, { 12, y, 160, 20 }, current ~= nil and tostring(current / scale) or "", nil, "^%d%.%-", 14)
		controls.range = new("LabelControl"):LabelControl(anchor, { 184, y + 2, 0, 14 }, scale == 10 and "metres (1 metre = 10 PoB units)"
			or "Enter the amount you actually use")
	end
	controls.help = new("LabelControl"):LabelControl(anchor, { 12, y + 34, 0, 14 }, function()
		if entry.choices then return "^7Only your confirmed value is staged." end
		local _, err = guided.Number(entry, entry.valueBuild or configTab.build, controls.value.buf)
		return err and (colorCodes.WARNING .. err) or "^7Unchecked until you confirm it."
	end)
	controls.save = new("ButtonControl"):ButtonControl(anchor, { 268, y + 70, 100, 22 }, "Use value", function()
		local value = controls.value.buf
		if entry.choices then value = controls.value.list[controls.value.selIndex].val end
		if guided.Set(entry, value, configTab) then main:ClosePopup(); if onConfirmed then onConfirmed() end end
	end)
	controls.save.enabled = function() return entry.choices ~= nil or guided.Number(entry, entry.valueBuild or configTab.build, controls.value.buf) ~= nil end
	controls.default = new("ButtonControl"):ButtonControl(anchor, { 12, y + 70, 172, 22 }, "Use PoB default", function()
		guided.Default(entry, configTab)
		main:ClosePopup()
	end)
	controls.default.shown = not entry.numeric
	controls.close = new("ButtonControl"):ButtonControl(anchor, { 388, y + 70, 100, 22 }, "Cancel", function() main:ClosePopup() end)
	main:OpenPopup(500, y + 108, entry.baseLabel, controls, nil, nil, "close")
end
function M.OpenGuided(configTab, inventory, apply, onApplied)
	local entries, retired = guided.Entries(configTab, inventory)
	local controls, anchor = { }, { "TOPLEFT", nil, "TOPLEFT" }
	local function filter()
		controls.list.list = { }
		for _, entry in ipairs(entries) do if entry.available or controls.showAll.state then t_insert(controls.list.list, entry) end end
		controls.list:SelectIndex(1)
	end
	controls.intro = new("LabelControl"):LabelControl(anchor, { 12, 16, 0, 14 },
		"^7These answers start unchecked.")
	controls.showAll = new("CheckBoxControl"):CheckBoxControl(anchor, { 12, 48, 16 }, "Also show settings not used by this build", filter, nil, false)
	controls.showAll.labelRight = true
	controls.list = new("ListControl"):ListControl(anchor, { 12, 80, 736, 330 }, 22, "VERTICAL", false, { })
	controls.list.showRowSeparators = true
	controls.list.GetRowValue = function(_, _, _, entry)
		return (not entry.available and "^8[Not used] " or entry.selected and "^2[Chosen] " or colorCodes.WARNING .. "[Choose] ") .. "^7" .. entry.section .. ": "
			.. entry.label
	end
	controls.list.OnSelClick = function(_, _, entry)
		if entry.selected then entry.selected = false else M.EditGuided(entries, entry, configTab) end
	end
	controls.list.OnSelKeyDown = function(self, index, entry, key)
		if key == "SPACE" then self:OnSelClick(index, entry) end
	end
	controls.list.AddValueTooltip = function(_, tooltip, _, entry)
		tooltip:Clear()
		for _, line in ipairs(main:WrapString(entry.reason, 14, 600)) do tooltip:AddLine(14, "^7" .. line) end
		if not entry.available then tooltip:AddLine(14, "^8Not used by this build; left alone.") end
	end
	controls.help = new("LabelControl"):LabelControl(anchor, { 12, 430, 0, 14 }, "^7No maximums are filled in for you.")
	controls.legacy = new("LabelControl"):LabelControl(anchor, { 12, 452, 0, 14 }, "^7" .. retired
		.. " old settings are left alone.")
	local function pending()
		local count = 0
		for _, entry in ipairs(entries) do
			if entry.selected and (entry.current ~= entry.value or entry.useDefault or entry.clearPlaceholder and configTab.placeholder[entry.var] ~= nil) then
				count = count + 1
			end
		end
		return count
	end
	controls.save = new("ButtonControl"):ButtonControl(anchor, { 468, 492, 168, 22 }, function() return "Apply " .. pending() .. " settings" end, function()
		if apply(configTab, entries) then main:ClosePopup(); if onApplied then onApplied() end end
	end)
	controls.save.enabled = function() return pending() > 0 end
	controls.close = new("ButtonControl"):ButtonControl(anchor, { 648, 492, 100, 22 }, "Cancel", function() main:ClosePopup() end)
	filter()
	main:OpenPopup(760, 532, "Other settings: your choices", controls, nil, nil, "close")
	return entries
end

return M
