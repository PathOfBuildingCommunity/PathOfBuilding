local lfs = require("lfs")
local sha1 = require("sha1")

describe("UpdateCheck", function()
	-- Use a temp dir outside the repo: the Docker test harness mounts the repo read-only
	local tmpDir = os.tmpname()
	os.remove(tmpDir)
	local originalRequire
	local originalMakeDir
	local originalGetScriptPath
	local originalGetRuntimePath

	local programContent = "-- new launch script\n"
	local runtimeContent = "\0new runtime binary"
	local soContent = "\0new shared object"

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

	local function newFakeCurl(responses)
		local curl = { OPT_ACCEPT_ENCODING = 0, OPT_IPRESOLVE = 1, OPT_PROXY = 2, OPT_SSL_VERIFYPEER = 3, OPT_SSL_VERIFYHOST = 4 }
		function curl.easy()
			local easy = { url = "" }
			function easy:escape(text)
				return text
			end
			function easy:setopt_url(url)
				self.url = url
			end
			function easy:setopt()
			end
			function easy:setopt_writefunction(sink)
				self.sink = sink
			end
			function easy:perform()
				local content = responses[self.url]
				if not content then
					return nil, { msg = function() return "404: "..self.url end }
				end
				if type(self.sink) == "function" then
					self.sink(content)
				else
					self.sink:write(content)
				end
				return true, nil
			end
			function easy:close()
			end
			return easy
		end
		return curl
	end

	-- Builds a local manifest on disk and returns the canned remote responses
	local function setUpManifests(platform)
		writeFile(tmpDir.."/manifest.xml", table.concat({
			'<?xml version="1.0" encoding="UTF-8"?>',
			'<PoBVersion>',
			'\t<Version number="1.0.0" platform="'..platform..'" branch="dev" />',
			'\t<Source part="default" url="http://fake/" />',
			'\t<File name="Launch.lua" part="program" sha1="0000000000000000000000000000000000000000" />',
			'\t<File name="Path{space}of{space}Building" part="runtime" platform="'..platform..'" sha1="1111111111111111111111111111111111111111" />',
			'\t<File name="SimpleGraphic.so" part="runtime" platform="'..platform..'" sha1="2222222222222222222222222222222222222222" />',
			'</PoBVersion>',
		}, "\n"))
		local remoteManifest = table.concat({
			'<?xml version="1.0" encoding="UTF-8"?>',
			'<PoBVersion>',
			'\t<Version number="1.0.1" />',
			'\t<Source part="default" url="http://fake/" />',
			'\t<Source part="program" url="http://fake/prog/" />',
			'\t<Source part="runtime" platform="'..platform..'" url="http://fake/rt/" />',
			'\t<File name="Launch.lua" part="program" sha1="'..sha1(programContent)..'" />',
			'\t<File name="Path{space}of{space}Building" part="runtime" platform="'..platform..'" sha1="'..sha1(runtimeContent)..'" />',
			'\t<File name="SimpleGraphic.so" part="runtime" platform="'..platform..'" sha1="'..sha1(soContent)..'" />',
			'</PoBVersion>',
		}, "\n")
		return {
			["http://fake/manifest.xml"] = remoteManifest,
			["http://fake/changelog.txt"] = "changelog",
			["http://fake/prog/Launch.lua"] = programContent,
			["http://fake/rt/Path{space}of{space}Building"] = runtimeContent,
			["http://fake/rt/SimpleGraphic.so"] = soContent,
		}
	end

	local function runUpdateCheck(platform)
		local responses = setUpManifests(platform)
		local fakeCurl = newFakeCurl(responses)
		_G.require = function(name)
			if name == "lcurl.safe" then
				return fakeCurl
			elseif name == "lzip" then
				return { }
			end
			return originalRequire(name)
		end
		return assert(loadfile("UpdateCheck.lua"))()
	end

	before_each(function()
		rmTree(tmpDir)
		lfs.mkdir(tmpDir)
		lfs.mkdir(tmpDir.."/runtime")
		originalRequire = _G.require
		originalMakeDir = _G.MakeDir
		originalGetScriptPath = _G.GetScriptPath
		originalGetRuntimePath = _G.GetRuntimePath
		_G.GetScriptPath = function()
			return tmpDir
		end
		_G.GetRuntimePath = function()
			return tmpDir.."/runtime"
		end
		_G.MakeDir = function(path)
			if path:sub(1, 1) ~= "/" then
				path = tmpDir.."/"..path
			end
			lfs.mkdir(path)
			return true
		end
	end)

	after_each(function()
		_G.require = originalRequire
		_G.MakeDir = originalMakeDir
		_G.GetScriptPath = originalGetScriptPath
		_G.GetRuntimePath = originalGetRuntimePath
		rmTree(tmpDir)
	end)

	it("stages runtime updates with chmod ops for extensionless files on linux64", function()
		local mode = runUpdateCheck("linux64")
		assert.are.equal("basic", mode)
		local opsRuntime = assert(readFile(tmpDir.."/Update/opFileRuntime.txt"))
		assert.is_truthy(opsRuntime:find('move "'..tmpDir..'/Update/Path{space}of{space}Building" "'..tmpDir..'/runtime/Path{space}of{space}Building"', 1, true))
		assert.is_truthy(opsRuntime:find('chmod "'..tmpDir..'/runtime/Path{space}of{space}Building"', 1, true))
		-- files with extensions never get chmod
		assert.is_falsy(opsRuntime:find('chmod "'..tmpDir..'/runtime/SimpleGraphic.so"', 1, true))
		assert.is_truthy(opsRuntime:find('start "'..tmpDir..'/runtime/Path of Building"', 1, true))
		local ops = assert(readFile(tmpDir.."/Update/opFile.txt"))
		assert.is_truthy(ops:find('move "'..tmpDir..'/Update/Launch.lua" "'..tmpDir..'/Launch.lua"', 1, true))
	end)

	it("emits no chmod ops on win32", function()
		local mode = runUpdateCheck("win32")
		assert.are.equal("basic", mode)
		local opsRuntime = assert(readFile(tmpDir.."/Update/opFileRuntime.txt"))
		assert.is_falsy(opsRuntime:find("chmod", 1, true))
	end)
end)
