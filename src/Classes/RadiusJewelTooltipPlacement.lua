-- Path of Building
--
-- Module: Radius Jewel Tooltip Placement
-- Keeps Radius Jewel Finder tooltips inside the viewport and clear of previews.
--

local ipairs = ipairs
local t_insert = table.insert
local m_max = math.max
local m_min = math.min

local M = { }

local function clampPosition(viewPort, x, y, width, height)
	x = m_max(viewPort.x, m_min(x, viewPort.x + viewPort.width - width))
	y = m_max(viewPort.y, m_min(y, viewPort.y + viewPort.height - height))
	return x, y
end

local function rectanglesOverlap(aX, aY, aW, aH, bX, bY, bW, bH)
	return aX < bX + bW and aX + aW > bX and aY < bY + bH and aY + aH > bY
end

function M.placeTooltip(viewPort, ttW, ttH, cursorX, cursorY, blockedRectangles, preferPrimaryBlockedRect)
	local candidates = {
		{ x = cursorX + 20, y = cursorY + 20 },
		{ x = cursorX - ttW - 20, y = cursorY + 20 },
		{ x = cursorX + 20, y = cursorY - ttH - 20 },
		{ x = cursorX - ttW - 20, y = cursorY - ttH - 20 },
	}
	local primaryBlockedRect = preferPrimaryBlockedRect and blockedRectangles and blockedRectangles[1] or nil
	if primaryBlockedRect then
		t_insert(candidates, 1, { x = primaryBlockedRect.x - ttW - 12, y = cursorY + 20 })
		t_insert(candidates, 2, { x = primaryBlockedRect.x + primaryBlockedRect.width + 12, y = cursorY + 20 })
		t_insert(candidates, 3, { x = primaryBlockedRect.x, y = primaryBlockedRect.y - ttH - 12 })
		t_insert(candidates, 4, { x = primaryBlockedRect.x, y = primaryBlockedRect.y + primaryBlockedRect.height + 12 })
	end
	for _, candidate in ipairs(candidates) do
		local ttX, ttY = clampPosition(viewPort, candidate.x, candidate.y, ttW, ttH)
		local overlapsBlockedRect = false
		for _, blockedRect in ipairs(blockedRectangles or { }) do
			if rectanglesOverlap(ttX, ttY, ttW, ttH, blockedRect.x, blockedRect.y, blockedRect.width, blockedRect.height) then
				overlapsBlockedRect = true
				break
			end
		end
		if not overlapsBlockedRect then
			return ttX, ttY
		end
	end
	return clampPosition(viewPort, cursorX + 20, cursorY + 20, ttW, ttH)
end

return M
