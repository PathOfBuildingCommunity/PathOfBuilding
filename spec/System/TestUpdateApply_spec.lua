local lfs = require("lfs")

describe("UpdateApply", function()
	-- Use a temp dir outside the repo: the Docker test harness mounts the repo read-only
	local tmpDir = os.tmpname()
	os.remove(tmpDir)
	local originalSpawnProcess
	local originalExecute
	local spawned
	local executed

	local function writeFile(path, content)
		local file = assert(io.open(path, "wb"))
		file:write(content)
		file:close()
	end

	local function readFile(path)
		local file = io.open(path, "rb")
		if not file then
			return nil
		end
		local content = file:read("*a")
		file:close()
		return content
	end

	local function rmTree(path)
		if lfs.attributes(path, "mode") ~= "directory" then
			os.remove(path)
			return
		end
		for entry in lfs.dir(path) do
			if entry ~= "." and entry ~= ".." then
				rmTree(path.."/"..entry)
			end
		end
		lfs.rmdir(path)
	end

	local function runApply(ops)
		writeFile(tmpDir.."/opFile.txt", table.concat(ops, "\n"))
		return pcall(assert(loadfile("UpdateApply.lua")), tmpDir.."/opFile.txt")
	end

	before_each(function()
		rmTree(tmpDir)
		lfs.mkdir(tmpDir)
		spawned = { }
		executed = { }
		originalSpawnProcess = _G.SpawnProcess
		originalExecute = os.execute
		_G.SpawnProcess = function(target)
			table.insert(spawned, target)
		end
		os.execute = function(command)
			table.insert(executed, command)
			return 0
		end
	end)

	after_each(function()
		_G.SpawnProcess = originalSpawnProcess
		os.execute = originalExecute
		rmTree(tmpDir)
	end)

	it("moves files and desanitises {space} in the destination", function()
		writeFile(tmpDir.."/staged", "new content")
		local ok, err = runApply({ 'move "'..tmpDir..'/staged" "'..tmpDir..'/Path{space}of{space}Building"' })
		assert.is_true(ok, err)
		assert.are.equal("new content", readFile(tmpDir.."/Path of Building"))
		assert.is_nil(readFile(tmpDir.."/staged"))
	end)

	it("deletes files", function()
		writeFile(tmpDir.."/stale.lua", "old")
		local ok, err = runApply({ 'delete "'..tmpDir..'/stale.lua"' })
		assert.is_true(ok, err)
		assert.is_nil(readFile(tmpDir.."/stale.lua"))
	end)

	it("marks chmod targets executable, desanitising {space}", function()
		local ok, err = runApply({ 'chmod "'..tmpDir..'/Path{space}of{space}Building"' })
		assert.is_true(ok, err)
		assert.are.equal(1, #executed)
		assert.are.equal('chmod +x "'..tmpDir..'/Path of Building"', executed[1])
	end)

	it("starts processes", function()
		local ok, err = runApply({ 'start "'..tmpDir..'/Path of Building"' })
		assert.is_true(ok, err)
		assert.are.same({ tmpDir.."/Path of Building" }, spawned)
	end)

	it("raises a clear error instead of looping forever when the destination is unwritable", function()
		writeFile(tmpDir.."/staged", "new content")
		local ok, err = runApply({ 'move "'..tmpDir..'/staged" "'..tmpDir..'/no-such-dir/target"' })
		assert.is_false(ok)
		assert.matches("couldn't write", tostring(err))
	end)
end)
