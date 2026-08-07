local lfs = require("lfs")

describe("Asset references", function()
	-- Collect actual files under a directory with their exact on-disk casing
	local function collectFiles(dir, prefix, out)
		out = out or { }
		for entry in lfs.dir(dir) do
			if entry ~= "." and entry ~= ".." then
				local full = dir.."/"..entry
				local rel = prefix..entry
				if lfs.attributes(full, "mode") == "directory" then
					collectFiles(full, rel.."/", out)
				else
					out[rel] = true
				end
			end
		end
		return out
	end

	-- Collect Lua sources, skipping data/export dirs that don't reference assets
	local function collectLuaFiles(dir, out)
		out = out or { }
		for entry in lfs.dir(dir) do
			if entry ~= "." and entry ~= ".." then
				local full = dir.."/"..entry
				local mode = lfs.attributes(full, "mode")
				if mode == "directory" then
					if entry ~= "Data" and entry ~= "TreeData" and entry ~= "Export" and entry ~= "Builds" then
						collectLuaFiles(full, out)
					end
				elseif entry:match("%.lua$") then
					table.insert(out, full)
				end
			end
		end
		return out
	end

	it("match on-disk filenames exactly (case-sensitive)", function()
		local actual = collectFiles("Assets", "Assets/")
		local lowerToActual = { }
		for name in pairs(actual) do
			lowerToActual[name:lower()] = name
		end
		local mismatches = { }
		for _, luaFile in ipairs(collectLuaFiles(".")) do
			local file = assert(io.open(luaFile, "rb"))
			local content = file:read("*a")
			file:close()
			for ref in content:gmatch('"(Assets/[%w_%-%./]+)"') do
				if not actual[ref] then
					local hint = lowerToActual[ref:lower()]
					table.insert(mismatches, string.format("%s references %q%s",
						luaFile, ref, hint and (" (on disk: %q)"):format(hint) or " (no such file)"))
				end
			end
		end
		assert.are.equal(0, #mismatches, "\n"..table.concat(mismatches, "\n"))
	end)
end)
