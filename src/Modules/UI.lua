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

-- TODO: remove this switch before merging upstream. It is here for the review only: not everyone
-- wants rounded corners, and some exiles have said they prefer the sharp edges, so setting this
-- to false squares everything off and makes the two looks easy to compare side by side.
-- Honoured by the primitives rather than the tokens, so it also catches the places that derive
-- their own radius, like the slider knob and the scroll bar thumb.
ui.rounded = true

-- Corner rounding used by the base controls
ui.radiusSmall = 3
ui.radius = 5
ui.radiusLarge = 8

-- Colour tokens. Each entry is { red, green, blue } in the 0-1 range that SetDrawColor expects.
-- Colour tokens, packed as 0xRRGGBB. They are plain numbers rather than {r, g, b} tables: the draw
-- path runs every frame for every control, so a colour that has to be built there, or a table that
-- has to be traced by the collector, adds up. Numbers are values in Lua, so passing one around or
-- deriving one at draw time allocates nothing.
ui.colors = {
	-- Outlines
	border = 0x3D3D45,
	borderHover = 0x737380,
	borderActive = 0xA1A1B0,
	borderDisabled = 0x29292E,

	-- Control bodies. Item names, "(Unused)" notes and other body text use the game's own
	-- palette, which is mixed for contrast against black, so anything holding text stays near
	-- black and leans on the border for definition. Only the hover and pressed states lift far
	-- enough to be felt.
	surface = 0x0E0E11,
	surfaceHover = 0x1D1D22,
	surfaceActive = 0x2B2B33,
	surfaceDisabled = 0x09090A,

	-- Containers that float above the rest of the interface
	popover = 0x08080A,
	panel = 0x0B0B0D,

	-- Window chrome, i.e. the top bar and the side bar the tab buttons sit on. It reads as raised
	-- rather than recessed, so it is the one surface that sits above the controls it holds.
	chrome = 0x212126,
	chromeBorder = 0x4C4C57,

	-- Text entry bodies, which sit a little deeper than a button
	input = 0x060607,
	inputHover = 0x0B0B0E,

	-- Row highlights inside lists and drop downs
	accent = 0x2B2B33,
	accentSubtle = 0x18181C,

	-- Filled emphasis, e.g. a ticked check box or a slider knob
	primary = 0xE0E0E8,
	primaryHover = 0xFFFFFF,
	onPrimary = 0x0D0D0F,

	-- Text
	text = 0xFAFAFA,
	textMuted = 0xB8B8BF,
	textDisabled = 0x6B6B73,

	-- Focus ring drawn just outside a focused control
	ring = 0x8C8C9E,

	-- Drag and drop feedback
	dropTarget = 0x59BF73,
	dropTargetSurface = 0x0D170F,
}

-- A white disc; each quadrant is used as a rounded corner, so a rounded rectangle is
-- four corner draws plus three plain quads.
local roundImage = NewImageHandle()
roundImage:Load("Assets/ui_round.png", "CLAMP", "MIPMAP")

-- Untextured geometry has no antialiasing, which a diagonal shape like a check mark shows badly,
-- so it comes from a sprite as well
local checkImage = NewImageHandle()
checkImage:Load("Assets/ui_check.png", "CLAMP", "MIPMAP")

---Set the current draw colour from a packed 0xRRGGBB token
---@param color integer
---@param alpha? number
function ui.SetColor(color, alpha)
	SetDrawColor(
		m_floor(color / 0x10000) / 255,
		m_floor(color / 0x100) % 0x100 / 255,
		color % 0x100 / 255,
		alpha or 1
	)
end

---Pack a colour that only exists at draw time, e.g. one a control's borderFunc returns, into the
---same form the tokens use. Returns a number, so it costs no allocation.
---@return integer
function ui.PackColor(r, g, b)
	return m_floor(r * 255 + 0.5) * 0x10000 + m_floor(g * 255 + 0.5) * 0x100 + m_floor(b * 255 + 0.5)
end

---Draw a filled rectangle with rounded corners, using the current draw colour
---@param radius? number defaults to ui.radius
function ui.DrawRect(x, y, width, height, radius)
	if width <= 0 or height <= 0 then
		return
	end
	radius = m_floor(m_min(radius or ui.radius, width / 2, height / 2))
	if not ui.rounded or radius < 1 then
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
	if not ui.rounded then
		DrawImage(nil, x, y, diameter, diameter)
		return
	end
	DrawImage(roundImage, x, y, diameter, diameter)
end

---Draw a check mark centred on the given point, using the current draw colour
function ui.DrawCheckMark(x, y, size)
	DrawImage(checkImage, x - size / 2, y - size / 2, size, size)
end

---Draw an outlined, filled rounded rectangle
---@param border? integer outline colour, or nil for no outline
---@param fill? integer body colour, or nil to leave the body untouched
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
---@return integer border
---@return integer fill
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
