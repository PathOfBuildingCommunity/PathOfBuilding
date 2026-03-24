if not table.containsId then
	dofile("Scripts/mods.lua")
end

-- Note that these will be normally commented out to prevent accidental legacy mod wording loss on export
-- (before legacy mods have been added to the uniques in src/Data)
local itemTypes = {
	-- "axe",
	-- "bow",
	-- "claw",
	-- "dagger",
	-- "fishing",
	-- "mace",
	-- "staff",
	-- "sword",
	-- "wand",
	-- "helmet",
	-- "body",
	-- "gloves",
	-- "boots",
	-- "shield",
	-- "quiver",
	-- "amulet",
	-- "ring",
	-- "belt",
	-- "jewel",
	-- "flask",
	-- "tincture",
}

-- TODO: Remove this once we are exporting all item types
local itemTypesTemp = {
	"axe",
	"bow",
	"claw",
	"dagger",
	"fishing",
	"mace",
	"staff",
	"sword",
	"wand",
	"helmet",
	"body",
	"gloves",
	"boots",
	"shield",
	"quiver",
	"amulet",
	"ring",
	"belt",
	"jewel",
	"flask",
	"tincture",
}

function io.linesBackward(filename)
	local file = assert(io.open(filename, "rb"))
	local content = file:read("*a")
	file:close()
	content = content:gsub("\r\n", "\n"):gsub("\r", "\n")
	local lines = {}
	for line in content:gmatch("([^\n]*)\n?") do
		lines[#lines + 1] = line
	end
	-- Trailing empty entry from final newline
	if lines[#lines] == "" then
		lines[#lines] = nil
	end
	local i = #lines + 1
	return function()
		i = i - 1
		if i > 0 then
			return lines[i]
		end
	end
end

local usedMods = {}
local itemUsedMods = {}
local modTextMap = LoadModule("Uniques/ModTextMap.lua")
local uniqueMods = LoadModule("../Data/ModItemExclusive.lua")

for _, name in pairs(itemTypes) do
	-- Reading the file backward lets us see the most current variant lines first
	-- This way legacy mods can prefer existing mods and be more likely to match up automatically
	-- Note this ONLY works because conventionally we have the most current variant mod listed last
	-- if that ever changes due to modOrder, a lot of the `itemUsedMods` logic won't work (and might make things worse in some cases)
	local outTbl = {}
	for line in io.linesBackward("../Data/Uniques/"..name..".lua") do
		if line == "]],[[" then
			itemUsedMods = {} -- Reset mod list for trying to keep variants using the same mod
		end
		local specName, specVal = line:match("^([%a ]+): (.+)$")
		if not specName and line ~= "]],[[" then
			local variants = line:match("{[vV]ariant:([%d,.]+)}")
			local fractured = line:match("({fractured})") or ""
			local modText = line:gsub("{.-}", ""):gsub("\xe2\x80\x93", "-") -- Clean tag prefixes and EM dash
			local possibleMods = modTextMap[modText:lower()] or {}
			local genericText
			local genericValues = {}
			if variants then
				-- Replace numbers with placeholder.  Covers 5, -5--10, -5.5-10.5, etc.  Ranges are handled later when printing
				local genericMatchText = modText:gsub('(%-*%d*%.*%d+%-*%-*%d*%.*%d*)', '#')
				local genericMatchMods = modTextMap[genericMatchText:lower()] or {}
				local newPossibleMods = {}
				for _, mod in ipairs(genericMatchMods) do
					if itemUsedMods[mod] then
						-- Found previously used mod that matches the generic version, so it's likely just a variant of the other
						-- Don't use the found possibleMod, as it might match exactly, but for a different item
						table.insert(newPossibleMods, mod)
					end
				end
				if newPossibleMods[1] or #possibleMods == 0 then
					genericText = genericMatchText
					for val in modText:gmatch('(%-*%d*%.*%d+%-*%-*%d*%.*%d*)') do
						table.insert(genericValues, val)
					end
					possibleMods = #newPossibleMods == 0 and genericMatchMods or newPossibleMods
				end
			end
			local gggMod
			if possibleMods[1] then
				table.sort(possibleMods, function(a, b)
					-- Strongly prefer already used mods for variant purposes
					if itemUsedMods[a] == itemUsedMods[b] then
						-- Used or not, prefer the mod with the item type
						-- This doesn't really work for energy shield mods on shields, but it's a start
						if a:lower():match(name) == b:lower():match(name) then
							-- Sort types that aren't this one lower
							for _, itemType in ipairs(itemTypesTemp) do
								if a:lower():match(itemType) and not b:lower():match(itemType) then
									return false
								end
							end
							-- No item types in the names, or they had identical item types
							-- Implicits preferred
							if (a:match("Implicit") and a:lower():match(name)) and not (b:match("Implicit") and b:lower():match(name)) then
								return true
							elseif (b:match("Implicit") and b:lower():match(name)) and not (a:match("Implicit") and a:lower():match(name)) then
								return false
							end
							-- No implicits, so prefer unused
							if usedMods[a] == usedMods[b] then
								return a:lower() < b:lower()
							else
								return not usedMods[a]
							end
						else
							return a:lower():match(name) ~= nil
						end
					else
						return itemUsedMods[a] ~= nil
					end
				end)

				-- Sorted already, so just pick the top one
				gggMod = possibleMods[1]
				usedMods[gggMod] = true
				itemUsedMods[gggMod] = true
				local outLine = fractured
				if variants then
					outLine = outLine .. "{variant:" .. variants:gsub("%.", ",") .. "}"
				end
				outLine = outLine .. gggMod
				if genericText then
					-- Figure out where to put [,]
					for _, val in ipairs(genericValues) do
						local min, max = val:match("(%-*%d*%.*%d+)-*(%-*%d*%.*%d*)")
						if not max or max == "" then max = min end
						-- Decimals mean it's not an exact value
						-- There are more that should be multiplied, but they're near-impossible to detect this way
						local multiplier = genericText:match("critical strike chance") and 1000 or genericText:match("per second") and 60 or 1
						min = tonumber(min) * multiplier
						max = tonumber(max) * multiplier
						outLine = outLine .. "[" .. min .. "," .. max .. "]"
					end
				end
				table.insert(outTbl, 1, outLine .. "\n")
				-- Multi-line mods: remove stale continuation lines from outTbl.
				-- Since we read backward, continuation lines (2nd, 3rd, etc.) were
				-- processed before the first line and are already in outTbl as raw
				-- text. The mod ID we just inserted resolves to ALL lines, so the
				-- raw continuation entries are duplicates.
				-- Also collect continuations from sibling mods that share the same
				-- first line (e.g. Dream/Nightmare jewels have 4 mods with identical
				-- first lines but different continuations).
				local modData = uniqueMods[gggMod]
				if modData and #modData > 1 then
					local continuations = {}
					-- Find all mods sharing this first line
					local firstLine = modData[1]:lower()
					local siblingMods = modTextMap[firstLine] or { gggMod }
					for _, siblingId in ipairs(siblingMods) do
						local siblingData = uniqueMods[siblingId]
						if siblingData then
							for i = 2, #siblingData do
								continuations[siblingData[i]:lower()] = true
							end
						end
					end
					-- Find boundary of current item (stop at ]],[[ separator)
					local boundary = #outTbl
					for j = 2, #outTbl do
						local stripped = outTbl[j]:gsub("\n$", "")
						if stripped == "]],[[" or stripped == "]]," then
							boundary = j - 1
							break
						end
					end
					-- Scan backward within current item, remove matching entries
					for j = boundary, 2, -1 do
						local cleanLine = outTbl[j]:gsub("{.-}", ""):gsub("%s+$", ""):gsub("\n$", "")
						if continuations[cleanLine:lower()] then
							table.remove(outTbl, j)
						end
					end
				end
			else
				ConPrintf("Warning: No mod found for line '%s' in %s", modText, name)
				table.insert(outTbl, 1, line .."\n")
			end
		else
			table.insert(outTbl, 1, line .. "\n")
		end
	end
	local out = io.open("Uniques/"..name..".lua", "w")
	for _, line in ipairs(outTbl) do
		out:write(line)
	end
	out:close()
end

print("Unique mods exported.")
