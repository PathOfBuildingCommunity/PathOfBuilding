-- Path of Building
--
-- Module: Toast Notification
-- Manages toast notifications
--

local t_insert = table.insert
local t_remove = table.remove

local ToastNotification = {}

local toasts = {}
local dismissedIds = {}
local nextId = 1
local anchorMain = nil
local inputEvents = nil
local viewPort = nil
local screenH = 0

-- Animation durations (ms)
local SHOW_DURATION = 250
local HIDE_DURATION = 75

-- Generate a unique ID for a toast
local function generateId()
	local id = "toast_" .. nextId
	nextId = nextId + 1

	return id
end

-- Calculate toast height based on message content
local function calculateHeight(message)
	local lineCount = #message:gsub("[^\n]", "")

	return lineCount * 16 + 20 + 40
end

-- Initialize the toast system with required references
function ToastNotification:Init(anchor, events, vp, height)
	anchorMain = anchor
	inputEvents = events
	viewPort = vp
	screenH = height
end

-- Update references that change each frame
function ToastNotification:UpdateFrame(events, vp, height)
	inputEvents = events
	viewPort = vp
	screenH = height
end

-- Add a new toast notification
-- Returns the toast ID for later reference
function ToastNotification:Add(message)
	local id = generateId()
	local toast = {
		id = id,
		message = message,
		mode = nil, -- Will be set to "SHOWING" on first render
		start = nil,
		height = calculateHeight(message),
		currentHeight = 0,
		dismissButton = nil,
	}
	t_insert(toasts, toast)

	return id
end

-- Update an existing toast's message by ID
-- Returns true if toast was found and updated
function ToastNotification:Update(id, message)
	for _, toast in ipairs(toasts) do
		if toast.id == id then
			toast.message = message
			toast.height = calculateHeight(message)

			return true
		end
	end

	return false
end

-- Remove/dismiss a toast by ID
-- If immediate is true, removes instantly; otherwise triggers hide animation
function ToastNotification:Remove(id, immediate)
	for i, toast in ipairs(toasts) do
		if toast.id == id then
			if immediate then
				t_remove(toasts, i)
			else
				toast.mode = "HIDING"
				toast.start = GetTime()
			end

			return true
		end
	end

	return false
end

-- Check if a toast with the given ID exists
function ToastNotification:Exists(id)
	for _, toast in ipairs(toasts) do
		if toast.id == id then
			return true
		end
	end

	return false
end

-- Get a toast by ID
function ToastNotification:Get(id)
	for _, toast in ipairs(toasts) do
		if toast.id == id then
			return toast
		end
	end

	return nil
end

-- Clear all toasts
function ToastNotification:Clear(immediate)
	if immediate then
		toasts = {}
	else
		for _, toast in ipairs(toasts) do
			toast.mode = "HIDING"
			toast.start = GetTime()
		end
	end
end

-- Check if a toast ID was manually dismissed
function ToastNotification:WasDismissed(id)
	return dismissedIds[id] == true
end

-- Clear the dismissed state for a toast ID (or all if no id provided)
function ToastNotification:ClearDismissed(id)
	if id then
		dismissedIds[id] = nil
	else
		dismissedIds = {}
	end
end

-- Get total height of all visible toasts
function ToastNotification:GetTotalHeight()
	local total = 0
	for _, toast in ipairs(toasts) do
		total = total + (toast.currentHeight or 0)
	end

	return total
end

-- Process toast animations and render
-- Returns total toast height for mainBarHeight calculation
function ToastNotification:Render()
	local totalToastHeight = 0
	local toastsToRemove = {}

	for i, toast in ipairs(toasts) do
		if not toast.mode then
			toast.mode = "SHOWING"
			toast.start = GetTime()
			toast.dismissButton = new(
				"ButtonControl",
				{ "BOTTOMLEFT", anchorMain, "BOTTOMLEFT" },
				{ 4, 0, 80, 20 },
				"Dismiss",
				function()
					dismissedIds[toast.id] = true
					toast.mode = "HIDING"
					toast.start = GetTime()
				end
			)
		end

		local now = GetTime()
		if toast.mode == "SHOWING" then
			if now >= toast.start + SHOW_DURATION then
				toast.mode = "SHOWN"
				toast.currentHeight = toast.height
			else
				toast.currentHeight = toast.height * (now - toast.start) / SHOW_DURATION
			end
		elseif toast.mode == "SHOWN" then
			toast.currentHeight = toast.height
		elseif toast.mode == "HIDING" then
			if now >= toast.start + HIDE_DURATION then
				t_insert(toastsToRemove, i)
				toast.currentHeight = 0
			else
				toast.currentHeight = toast.height * (1 - (now - toast.start) / HIDE_DURATION)
			end
		end

		totalToastHeight = totalToastHeight + (toast.currentHeight or 0)
	end

	-- Remove finished toasts (in reverse order to preserve indices)
	for i = #toastsToRemove, 1, -1 do
		t_remove(toasts, toastsToRemove[i])
	end

	local yOffset = 58
	for _, toast in ipairs(toasts) do
		if toast.currentHeight and toast.currentHeight > 0 then
			local toastY = screenH - yOffset - toast.currentHeight

			-- Toast background
			SetDrawColor(0.85, 0.85, 0.85)
			DrawImage(nil, 0, toastY, 312, toast.currentHeight)
			SetDrawColor(0.1, 0.1, 0.1)
			DrawImage(nil, 0, toastY + 4, 308, toast.currentHeight - 4)

			-- Toast text
			SetDrawColor(1, 1, 1)
			DrawString(4, toastY + 8, "LEFT", 20, "VAR", toast.message:gsub("\n.*", ""))
			DrawString(4, toastY + 28, "LEFT", 16, "VAR", toast.message:gsub("^[^\n]*\n?", ""))

			-- Position and draw dismiss button for fully shown toasts
			if toast.mode == "SHOWN" and toast.dismissButton then
				-- y is relative to anchor (screenH - 4), negative goes up
				toast.dismissButton.y = -(yOffset + 4)

				-- Handle input for the button
				if inputEvents then
					for _, event in ipairs(inputEvents) do
						if toast.dismissButton:IsMouseOver() then
							if event.type == "KeyDown" then
								toast.dismissButton:OnKeyDown(event.key, event.doubleClick)
							elseif event.type == "KeyUp" then
								toast.dismissButton:OnKeyUp(event.key)
							end
						end
					end
				end
				toast.dismissButton:Draw(viewPort)
			end

			yOffset = yOffset + toast.currentHeight
		end
	end

	return totalToastHeight
end

return ToastNotification
