-- Summarize the existing stat report without changing which differences count.
local function summarize(lines, compared, baseRef, headRef)
	local builds, stats, build = {}, {}, nil
	local changedBuilds, changedValues = 0, 0
	for line in lines do
		build = line:match("^## Output Diff for (.+)%.build$") or build
		local stat, actor = line:match("^(.-) Mismatch in (%a+) outputs:")
		if stat then
			assert(build, "Stat difference has no build name")
			local head = assert(lines():match("^%s*head Output: (.*)$"), "Missing head value")
			local base = assert(lines():match("^%s*dev Output: (.*)$"), "Missing base value")
			if not builds[build] then
				builds[build] = true
				changedBuilds = changedBuilds + 1
			end
			local key = actor .. "." .. stat
			local entry = stats[key] or { key = key, count = 0, build = build, base = base, head = head }
			entry.count = entry.count + 1
			stats[key] = entry
			changedValues = changedValues + 1
		end
	end
	local function escape(value)
		return tostring(value):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("|", "&#124;"):gsub("`", "&#96;")
	end
	local rows = {}
	for _, entry in pairs(stats) do rows[#rows + 1] = entry end
	-- Put common player results first; this affects presentation only.
	local priority = { ["player.Life"] = 1, ["player.Mana"] = 2, ["player.EnergyShield"] = 3,
		["player.TotalDPS"] = 4, ["player.CombinedDPS"] = 5, ["player.FullDPS"] = 6 }
	table.sort(rows, function(a, b)
		local ap, bp = priority[a.key] or 7, priority[b.key] or 7
		if ap ~= bp then return ap < bp end
		if a.count ~= b.count then return a.count > b.count end
		return a.key < b.key
	end)
	local output = {
		"## Build comparison summary", "",
		changedBuilds > 0 and "**Changes found: review required.**" or "**No calculated-stat differences found.**", "",
		string.format("Compared **%d builds**. **%d builds** have calculated-stat differences (**%d changed values**).", compared, changedBuilds, changedValues), "",
		"Base: `" .. escape(baseRef) .. "`. Candidate: `" .. escape(headRef) .. "`.", "",
	}
	if #rows > 0 then
		output[#output + 1] = string.format("Showing %d of %d changed stats, with one example for each. Common player results appear first; other stats are ordered by affected build count.", math.min(25, #rows), #rows)
		output[#output + 1] = ""
		output[#output + 1] = "| Stat | Affected builds | Example build | Before | After |"
		output[#output + 1] = "| --- | ---: | --- | ---: | ---: |"
		for index = 1, math.min(25, #rows) do
			local entry = rows[index]
			local name = entry.build
			if #name == 64 and name:match("^%x+$") then name = name:sub(1, 12) end
			output[#output + 1] = string.format("| %s | %d | %s | %s | %s |", escape(entry.key), entry.count, escape(name), escape(entry.base), escape(entry.head))
		end
		output[#output + 1] = ""
	end
	output[#output + 1] = "Strict mode fails on calculated-stat differences. Saved XML and timing differences are informational."
	output[#output + 1] = ""
	output[#output + 1] = "Full differences are in the **build-diff-output** artifact. API build identifiers above are shortened to 12 characters for searching the full report."
	return table.concat(output, "\n"), changedBuilds
end

if arg and arg[0]:match("BuildSummary%.lua$") then
	local output = summarize(io.lines(assert(arg[1])), assert(tonumber(arg[2])), assert(arg[3]), assert(arg[4]))
	print(output)
end
return summarize
