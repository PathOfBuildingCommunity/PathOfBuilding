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

	-- Control bodies
	surface = { 0.10, 0.10, 0.12 },
	surfaceHover = { 0.16, 0.16, 0.19 },
	surfaceActive = { 0.22, 0.22, 0.25 },
	surfaceDisabled = { 0.08, 0.08, 0.09 },

	-- Containers that float above the rest of the interface
	popover = { 0.06, 0.06, 0.07 },
	panel = { 0.09, 0.09, 0.10 },

	-- Text entry bodies, which sit a little deeper than a button
	input = { 0.05, 0.05, 0.06 },
	inputHover = { 0.08, 0.08, 0.09 },

	-- Row highlights inside lists and drop downs
	accent = { 0.20, 0.20, 0.23 },
	accentSubtle = { 0.14, 0.14, 0.16 },

	-- Filled emphasis, e.g. a ticked check box or a slider knob
	primary = { 0.88, 0.88, 0.91 },
	primaryHover = { 1, 1, 1 },
	onPrimary = { 0.05, 0.05, 0.06 },

	-- Text
	text = { 0.98, 0.98, 0.98 },
	textMuted = { 0.64, 0.64, 0.68 },
	textDisabled = { 0.38, 0.38, 0.41 },

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
