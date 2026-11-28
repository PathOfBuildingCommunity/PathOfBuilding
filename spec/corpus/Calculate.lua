local batch, cursorPath, outDir = assert(arg[1]), assert(arg[2]), assert(arg[3])
local startAt = assert(tonumber(arg[4]))
local zlib = require("zlib")
local appendStats = dofile("/harness/spec/corpus/BuildStats.lua")
dofile("HeadlessWrapper.lua")
assert(build and not launch.promptMsg, launch.promptMsg or "PoB failed to start")

-- SimpleGraphic supplies these functions in the desktop application. The
-- headless definitions are stubs, including the inflater used by Timeless jewels.
function Inflate(data)
	return (zlib.inflate(47)(data))
end
function Deflate(data)
	return (zlib.deflate()(data, "finish"))
end

local save = build.Save
function build:Save(xml)
	save(self, xml)
	local output = self.calcsTab.mainOutput
	appendStats(xml, output, "PlayerStat")
	if output.Minion then appendStats(xml, output.Minion, "MinionStat") end
end

local function write(path, value)
	local file = assert(io.open(path, "wb"))
	assert(file:write(value))
	assert(file:close())
end

local index = 0
for name in io.lines(batch) do
	index = index + 1
	if index >= startAt then
		write(cursorPath, tostring(index))
		write(cursorPath .. ".stage", "loading")
		local file = assert(io.open("/results/inputs/" .. name .. ".xml", "rb"))
		local xml = file:read("*a")
		file:close()
		io.stderr:write("Loading ", name, "\n")
		local start = os.clock()
		local document, err = common.xml.ParseXML(xml)
		assert(document and not err and document[1].elem == "PathOfBuilding", "Invalid PoB XML")
		loadBuildFromXML(xml, name)
		assert(not launch.promptMsg, launch.promptMsg)
		assert(not build.abortSave and type(build.calcsTab.mainOutput.Life) == "number", "No calculated player output")
		local elapsed = os.clock() - start
		write(cursorPath .. ".stage", "saving")
		io.stderr:write("Saving ", name, "\n")
		write(outDir .. "/" .. name .. ".build", assert(build:SaveDB("Cache")))
		write(outDir .. "/" .. name .. ".time", tostring(elapsed * 1000))
	end
end
