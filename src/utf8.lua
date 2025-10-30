-- Minimal utf8 stub for headless usage; not full Unicode support.
-- Provides only functions used by non-UI PoB paths. Do NOT use for UI text.
local M = {}

M.gsub = string.gsub
M.find = string.find
M.sub = string.sub
M.reverse = string.reverse
M.match = string.match

-- Very naive next-codepoint boundary: moves one byte forward/backward.
function M.next(s, i, dir)
  if type(s) ~= 'string' then return nil end
  i = tonumber(i) or 1
  dir = tonumber(dir) or 1
  if dir >= 0 then
    local j = i + 1
    if j > #s + 1 then return #s + 1 end
    return j
  else
    local j = i - 1
    if j < 0 then return 0 end
    return j
  end
end

return M

