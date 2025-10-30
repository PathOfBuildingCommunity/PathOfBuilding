-- API/Server.lua
-- Simple stdio JSON-RPC loop exposing a tiny PoB API

-- json loader with robust fallback to runtime path
local ok, json = pcall(require, 'dkjson')
if not ok then
  local base = rawget(_G, 'POB_SCRIPT_DIR') or '.'
  local candidates = {
    base .. '/runtime/lua/dkjson.lua',
    base .. '/../runtime/lua/dkjson.lua',
    'runtime/lua/dkjson.lua',
    '../runtime/lua/dkjson.lua',
  }
  for _, p in ipairs(candidates) do
    local ok2, mod = pcall(dofile, p)
    if ok2 and type(mod) == 'table' then json = mod; ok = true; break end
  end
  if not ok then error('dkjson not found; ensure PoB runtime or dkjson is available') end
end

local function j_encode(tbl)
  return json.encode(tbl, { indent = false })
end
local function j_decode(txt)
  return json.decode(txt)
end

local function write_line(tbl)
  io.write(j_encode(tbl), "\n")
  io.flush()
end

local function read_line()
  return io.read("*l")
end

-- Load common handlers via require for path robustness
io.stderr:write('[Server] About to require API.Handlers\n')
local ok, API = pcall(require, 'API.Handlers')
if not ok then
  io.stderr:write('[Server] Failed to require API.Handlers: ' .. tostring(API) .. '\n')
  error('Failed to load API.Handlers: ' .. tostring(API))
end
io.stderr:write('[Server] Successfully loaded API.Handlers\n')
local handlers = API.handlers
local function get_version_meta()
  return API.version_meta()
end

-- Commands
handlers.quit = function(params)
  return { ok = true, quit = true }
end

-- Main loop
write_line({ ok = true, ready = true, version = get_version_meta() })
while true do
  local line = read_line()
  if not line then break end
  if #line == 0 then goto continue end
  local msg = j_decode(line)
  if not msg or type(msg) ~= 'table' then
    write_line({ ok = false, error = 'invalid json' })
    goto continue
  end
  local action = msg.action
  local params = msg.params or {}
  local handler = handlers[action]
  if not handler then
    write_line({ ok = false, error = 'unknown action: '..tostring(action) })
    goto continue
  end
  local ok2, res = pcall(handler, params)
  if not ok2 then
    write_line({ ok = false, error = 'exception: '..tostring(res) })
  else
    write_line(res)
    if action == 'quit' then break end
  end
  ::continue::
end
