-- Simple stdio JSON-RPC loop exposing a tiny PoB API

-- Debug logging control
local DEBUG = os.getenv('POB_API_DEBUG') == '1'
local function debug_log(msg)
  if DEBUG then io.stderr:write('[Server] ' .. msg .. '\n') end
end

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

debug_log('About to require API.Handlers')
local ok, API = pcall(require, 'API.Handlers')
if not ok then
  debug_log('Failed to require API.Handlers: ' .. tostring(API))
  error('Failed to load API.Handlers: ' .. tostring(API))
end
debug_log('Successfully loaded API.Handlers')
local handlers = API.handlers
local function get_version_meta()
  return API.version_meta()
end

handlers.quit = function(params)
  return { ok = true, quit = true }
end

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
