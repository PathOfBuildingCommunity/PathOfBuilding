-- Store the API corpus alongside the calculated base cache, outside Git.
package.path = "runtime/lua/?.lua;" .. package.path
local json = require("dkjson")
local base64 = require("base64")
local zlib = require("zlib")
local cache = assert(arg[1])
local input = assert(io.open(cache .. "/corpus.json", "r"))
local corpus = assert(json.decode(input:read("*a")))
input:close()
assert(corpus.schemaVersion == 2 and #corpus.builds > 0 and #corpus.builds == corpus.count, "Invalid build corpus")
local list = assert(io.open(cache .. "/builds.txt", "w"))
for _, entry in ipairs(corpus.builds) do
    assert(#entry.sha256 == 64 and entry.sha256:match("^%x+$"), "Invalid build filename")
    local xml = zlib.inflate()(base64.decode(entry.code:gsub("-", "+"):gsub("_", "/")))
    local output = assert(io.open(cache .. "/" .. entry.sha256 .. ".xml", "w"))
    output:write(xml)
    output:close()
    list:write(entry.sha256, "\n")
end
list:close()
print("[+] Downloaded " .. corpus.count .. " builds from corpus " .. corpus.snapshotId)
