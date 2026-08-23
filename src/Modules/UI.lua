-- Path of Building
--
-- Module: UI
-- Shared visual language for the base controls (buttons, drop downs, edits, check boxes, ...).
--
-- Everything here is purely cosmetic: it provides the colour tokens the controls draw with,
-- plus a handful of rounded rectangle primitives, since SimpleGraphic only knows how to draw
-- axis aligned quads.
--
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local ui = { }

-- Corner rounding used by the base controls
ui.radiusSmall = 3
ui.radius = 5
ui.radiusLarge = 8

-- Colour tokens. Each entry is { red, green, blue } in the 0-1 range that SetDrawColor expects.
ui.colors = {
	-- Outlines
	border = { 0.24, 0.24, 0.27 },
	borderHover = { 0.45, 0.45, 0.50 },
	borderActive = { 0.63, 0.63, 0.69 },
	borderDisabled = { 0.16, 0.16, 0.18 },

	-- Control bodies. Item names, "(Unused)" notes and other body text use the game's own
	-- palette, which is mixed for contrast against black, so anything holding text stays near
	-- black and leans on the border for definition. Only the hover and pressed states lift far
	-- enough to be felt.
	surface = { 0.055, 0.055, 0.065 },
	surfaceHover = { 0.115, 0.115, 0.135 },
	surfaceActive = { 0.17, 0.17, 0.20 },
	surfaceDisabled = { 0.035, 0.035, 0.04 },

	-- Containers that float above the rest of the interface
	popover = { 0.03, 0.03, 0.038 },
	panel = { 0.042, 0.042, 0.05 },

	-- Window chrome, i.e. the top bar and the side bar the tab buttons sit on. It reads as raised
	-- rather than recessed, so it is the one surface that sits above the controls it holds.
	chrome = { 0.13, 0.13, 0.15 },
	chromeBorder = { 0.30, 0.30, 0.34 },

	-- Text entry bodies, which sit a little deeper than a button
	input = { 0.022, 0.022, 0.028 },
	inputHover = { 0.045, 0.045, 0.055 },

	-- Row highlights inside lists and drop downs
	accent = { 0.17, 0.17, 0.20 },
	accentSubtle = { 0.095, 0.095, 0.11 },

	-- Filled emphasis, e.g. a ticked check box or a slider knob
	primary = { 0.88, 0.88, 0.91 },
	primaryHover = { 1, 1, 1 },
	onPrimary = { 0.05, 0.05, 0.06 },

	-- Text
	text = { 0.98, 0.98, 0.98 },
	textMuted = { 0.72, 0.72, 0.75 },
	textDisabled = { 0.42, 0.42, 0.45 },

	-- Focus ring drawn just outside a focused control
	ring = { 0.55, 0.55, 0.62 },

	-- Drag and drop feedback
	dropTarget = { 0.35, 0.75, 0.45 },
	dropTargetSurface = { 0.05, 0.09, 0.06 },
}

-- A white disc; each quadrant is used as a rounded corner, so a rounded rectangle is
-- four corner draws plus three plain quads.
local roundImage = NewImageHandle()
roundImage:Load("Assets/ui_round.png", "CLAMP", "MIPMAP")

-- Untextured geometry has no antialiasing, which a diagonal shape like a check mark shows badly,
-- so it comes from a sprite as well
local checkImage = NewImageHandle()
checkImage:Load("Assets/ui_check.png", "CLAMP", "MIPMAP")

---Set the current draw colour from a token
---@param color number[]
---@param alpha? number
function ui.SetColor(color, alpha)
	SetDrawColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

---Draw a filled rectangle with rounded corners, using the current draw colour
---@param radius? number defaults to ui.radius
function ui.DrawRect(x, y, width, height, radius)
	if width <= 0 or height <= 0 then
		return
	end
	radius = m_floor(m_min(radius or ui.radius, width / 2, height / 2))
	if radius < 1 then
		DrawImage(nil, x, y, width, height)
		return
	end
	local right = x + width - radius
	local bottom = y + height - radius
	DrawImage(roundImage, x, y, radius, radius, 0, 0, 0.5, 0.5)
	DrawImage(roundImage, right, y, radius, radius, 0.5, 0, 1, 0.5)
	DrawImage(roundImage, x, bottom, radius, radius, 0, 0.5, 0.5, 1)
	DrawImage(roundImage, right, bottom, radius, radius, 0.5, 0.5, 1, 1)
	DrawImage(nil, x + radius, y, width - radius * 2, radius)
	DrawImage(nil, x, y + radius, width, height - radius * 2)
	DrawImage(nil, x + radius, bottom, width - radius * 2, radius)
end

---Draw a filled circle of the given diameter, using the current draw colour
function ui.DrawCircle(x, y, diameter)
	DrawImage(roundImage, x, y, diameter, diameter)
end

---Draw a check mark centred on the given point, using the current draw colour
function ui.DrawCheckMark(x, y, size)
	DrawImage(checkImage, x - size / 2, y - size / 2, size, size)
end

---Draw an outlined, filled rounded rectangle
---@param border? number[] outline colour, or nil for no outline
---@param fill? number[] body colour, or nil to leave the body untouched
---@param thickness? number outline thickness, defaults to 1
function ui.DrawBox(x, y, width, height, radius, border, fill, thickness)
	radius = radius or ui.radius
	thickness = thickness or 1
	if border then
		ui.SetColor(border)
		ui.DrawRect(x, y, width, height, radius)
	elseif not fill then
		return
	end
	if fill then
		ui.SetColor(fill)
		local inset = border and thickness or 0
		ui.DrawRect(x + inset, y + inset, width - inset * 2, height - inset * 2, radius - inset)
	end
end

---Draw a focus ring around a control. Must be drawn before the control body, which covers its
---inner half.
function ui.DrawFocusRing(x, y, width, height, radius, color, spread)
	spread = spread or 2
	ui.SetColor(color or ui.colors.ring, 0.55)
	ui.DrawRect(x - spread, y - spread, width + spread * 2, height + spread * 2, (radius or ui.radius) + spread)
end

---Pick the outline and body colours for an interactive control
---@return number[] border
---@return number[] fill
function ui.SurfaceColors(enabled, hover, active)
	local colors = ui.colors
	if not enabled then
		return colors.borderDisabled, colors.surfaceDisabled
	elseif active then
		return colors.borderActive, colors.surfaceActive
	elseif hover then
		return colors.borderHover, colors.surfaceHover
	end
	return colors.border, colors.surface
end

---Clamp a corner radius so it never exceeds half of the smaller side
function ui.FitRadius(radius, width, height)
	return m_max(0, m_min(radius, m_floor(m_min(width, height) / 2)))
end

return ui
