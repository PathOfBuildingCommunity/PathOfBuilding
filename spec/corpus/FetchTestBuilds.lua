local json = require("dkjson")
local base64 = require("base64")
local sha256 = require("sha2").sha256
local zlib = require("zlib")
local corpusFile, inputs = assert(arg[1]), assert(arg[2])

local input = assert(io.open(corpusFile, "rb"))
assert(input:seek("end") <= 16 * 1024 * 1024, "Oversized corpus")
input:seek("set")
local corpus, _, err = json.decode(input:read("*a"))
input:close()
assert(corpus and not err and corpus.schemaVersion == 2 and type(corpus.snapshotId) == "string", "Invalid corpus")
assert(corpus.count == #corpus.builds and corpus.count > 0 and corpus.count <= 750, "Invalid corpus count")

local function write(path, content)
	local file = assert(io.open(path, "wb"))
	assert(file:write(content))
	assert(file:close())
end

local seen = {}
for _, entry in ipairs(corpus.builds) do
	local code, hash = entry.code, entry.sha256
	assert(#code <= 150 * 1024 and code:match("^[%w_+/=%-]+$"), "Invalid encoded build")
	assert(sha256(code) == hash and not seen[hash], "Incorrect or duplicate build SHA-256")
	seen[hash] = true
	local compressed = base64.decode(code:gsub("-", "+"):gsub("_", "/"))
	local inflate, chunks, size, eof = zlib.inflate(), {}, 0, false
	for offset = 1, #compressed, 1024 do
		assert(not eof, "Trailing compressed input")
		local chunk, finished, consumed = inflate(compressed:sub(offset, offset + 1023))
		size = size + #chunk
		assert(size <= 4 * 1024 * 1024 and (not finished or consumed == #compressed), "Invalid inflated build")
		chunks[#chunks + 1], eof = chunk, finished
	end
	assert(eof and size > 0, "Incomplete compressed build")
	write(inputs .. "/" .. hash .. ".xml", table.concat(chunks))
	local tags = entry.criteria or {}
	for _, tag in ipairs(tags) do assert(tag:match("^[a-z0-9%-]+$"), "Invalid criterion") end
	write(inputs .. "/" .. hash .. ".tags", table.concat(tags, ", "))
end
print(string.format("Corpus %s: %d verified API builds", corpus.snapshotId, corpus.count))
