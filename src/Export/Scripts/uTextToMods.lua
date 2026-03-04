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

-- Source - https://stackoverflow.com/a/37956399
-- Posted by Egor Skriptunoff, modified by community. See post 'Timeline' for change history
-- Retrieved 2026-03-02, License - CC BY-SA 3.0

function io.linesbackward(filename)
	local file = assert(io.open(filename))
	local chunk_size = 4 * 1024
	local iterator = function() return "" end
	local tail = ""
	local chunk_index = math.ceil(file:seek "end" / chunk_size)
	return
		function()
			while true do
				local lineEOL, line = iterator()
				if lineEOL ~= "" then
					return line:reverse()
				end
				repeat
					chunk_index = chunk_index - 1
					if chunk_index < 0 then
						file:close()
						iterator = function()
							error('No more lines in file "' .. filename .. '"', 3)
						end
						return
					end
					file:seek("set", chunk_index * chunk_size)
					local chunk = file:read(chunk_size)
					local pattern = "^(.-" .. (chunk_index > 0 and "\n" or "") .. ")(.*)"
					local new_tail, lines = chunk:match(pattern)
					iterator = lines and (lines .. tail):reverse():gmatch "(\n?\r?([^\n]*))"
					tail = new_tail or chunk .. tail
				until iterator
			end
		end
end

local usedMods = {}
local itemUsedMods = {}
local modTextMap = LoadModule("Uniques/ModTextMap.lua")

for _, name in pairs(itemTypes) do
	-- Reading the file backward lets us see the most current variant lines first
	-- This way legacy mods can prefer existing mods and be more likely to match up automatically
	-- Note this ONLY works because conventionally we have the most current variant mod listed last
	-- if that ever changes due to modOrder, a lot of the `itemUsedMods` logic won't work (and might make things worse in some cases)
	local outTbl = {}
	for line in io.linesbackward("../Data/Uniques/"..name..".lua") do
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
						local multiplier = genericText:match("chance") and 1000 or genericText:match("per second") and 60 or 1
						min = tonumber(min) * multiplier
						max = tonumber(max) * multiplier
						outLine = outLine .. "[" .. min .. "," .. max .. "]"
					end
				end
				table.insert(outTbl, 1, outLine .. "\n")
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
