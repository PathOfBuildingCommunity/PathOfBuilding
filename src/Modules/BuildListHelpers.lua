-- Path of Building
--
-- Module: Build List Helpers
-- Shared helpers for scanning and sorting the builds folder.
-- Used by both the startup build list (Modules/BuildList) and the
-- "Import from Folder" popup in the Compare tab.
--
local t_insert = table.insert

local buildSortDropList = {
	{ label = "Sort by Name", sortMode = "NAME" },
	{ label = "Sort by Class", sortMode = "CLASS" },
	{ label = "Sort by Last Edited", sortMode = "EDITED"},
	{ label = "Sort by Level", sortMode = "LEVEL"},
}

local function ReadBuildHeader(fullFileName)
	local fileHnd = io.open(fullFileName, "r")
	if not fileHnd then return { } end
	local headerText = fileHnd:read(2048)
	fileHnd:close()
	if not headerText then
		main:OpenCloudErrorPopup(fullFileName)
		return
	end

	local buildTag = headerText:match("<Build%s+[^>]->")
	if not buildTag then return { } end

	return {
		level = tonumber(buildTag:match('level="([^"]+)"')),
		className = buildTag:match('className="([^"]+)"'),
		ascendClassName = buildTag:match('ascendClassName="([^"]+)"'),
	}
end

local function MatchEntry(entry, terms)
	for _, term in ipairs(terms) do
		local termLower = term:lower()
		local val = termLower:match("^class:(.*)$")
		if val then
			if val ~= "" then
				local match = (entry.className and entry.className:lower():find(val, 1, true)) or
				              (entry.ascendClassName and entry.ascendClassName:lower():find(val, 1, true)) or
				              (entry.folderName and entry.folderName:lower():find(val, 1, true))
				if not match then return false end
			end
		else
			local match = (entry.buildName and entry.buildName:lower():find(termLower, 1, true)) or
			              (entry.folderName and entry.folderName:lower():find(termLower, 1, true)) or
			              (entry.className and entry.className:lower():find(termLower, 1, true)) or
			              (entry.ascendClassName and entry.ascendClassName:lower():find(termLower, 1, true)) or
			              (entry.subPath and entry.subPath:lower():find(termLower, 1, true))
			if not match then return false end
		end
	end
	return true
end

-- Recursively index builds and folders below main.buildPath..subPath.
local function ScanFolder(subPath)
	subPath = subPath or ""
	local list = { }

	local function scanDir(currentSubPath)
		local handle = NewFileSearch(main.buildPath..currentSubPath.."*.xml")
		while handle do
			local fileName = handle:GetFileName()
			local fullFileName = main.buildPath..currentSubPath..fileName
			local header = ReadBuildHeader(fullFileName)
			if header then
				t_insert(list, {
					fileName = fileName,
					subPath = currentSubPath,
					fullFileName = fullFileName,
					modified = handle:GetFileModifiedTime(),
					buildName = fileName:gsub("%.xml$",""),
					level = header.level,
					className = header.className,
					ascendClassName = header.ascendClassName,
				})
			end

			if not handle:NextFile() then break end
		end

		handle = NewFileSearch(main.buildPath..currentSubPath.."*", true)
		local subFolders = { }
		while handle do
			local folderName = handle:GetFileName()
			local modified = handle:GetFileModifiedTime()
			t_insert(subFolders, { name = folderName, modified = modified })
			if not handle:NextFile() then break end
		end

		for _, folder in ipairs(subFolders) do
			local folderName = folder.name
			local nextSubPath = currentSubPath .. folderName .. "/"
			t_insert(list, {
				folderName = folderName,
				subPath = currentSubPath,
				fullFileName = main.buildPath..currentSubPath..folderName,
				modified = folder.modified
			})
			scanDir(nextSubPath)
		end
	end

	scanDir(subPath)
	return list
end

-- Filtering the cached index avoids filesystem work on every keystroke.
local function FilterList(index, subPath, filterText)
	local terms = { }
	for term in (filterText or ""):gmatch("%S+") do
		t_insert(terms, term)
	end

	local list = { }
	for _, entry in ipairs(index or { }) do
		if (#terms == 0 and entry.subPath == subPath) or (#terms > 0 and MatchEntry(entry, terms)) then
			t_insert(list, entry)
		end
	end
	return list
end

local function CanMoveToSubPath(build, targetSubPath)
	if build.subPath == targetSubPath then return false end
	if build.folderName then
		-- MoveFolder and CopyFolder recurse, so their destination cannot be inside the source.
		local sourceSubPath = build.subPath .. build.folderName .. "/"
		if targetSubPath:sub(1, #sourceSubPath) == sourceSubPath then return false end
	end
	return true
end

-- Sort the given list in place using the same rules as the startup build list.
-- sortMode: "NAME" (default), "CLASS", "EDITED", or "LEVEL".
local function SortList(list, sortMode)
	table.sort(list, function(a, b)
		local a_is_folder = a.folderName ~= nil
		local b_is_folder = b.folderName ~= nil

		if a_is_folder and not b_is_folder then return true end
		if not a_is_folder and b_is_folder then return false end

		local aPathName = (a.subPath or "") .. (a.folderName or a.fileName or "")
		local bPathName = (b.subPath or "") .. (b.folderName or b.fileName or "")

		if sortMode == "EDITED" then
			local modA = a.modified or 0
			local modB = b.modified or 0
			if modA ~= modB then
				return modA > modB
			end
			return naturalSortCompare(aPathName, bPathName)
		end

		if a_is_folder then
			return naturalSortCompare(aPathName, bPathName)
		else
			if sortMode == "CLASS" then
				local a_has_class = a.className ~= nil
				local b_has_class = b.className ~= nil
				if not a_has_class and b_has_class then return true
				elseif a_has_class and not b_has_class then return false
				elseif a_has_class and b_has_class and a.className ~= b.className then
					return a.className < b.className
				end

				local a_has_asc = a.ascendClassName ~= nil
				local b_has_asc = b.ascendClassName ~= nil
				if not a_has_asc and b_has_asc then return true
				elseif a_has_asc and not b_has_asc then return false
				elseif a_has_asc and b_has_asc and a.ascendClassName ~= b.ascendClassName then
					return a.ascendClassName < b.ascendClassName
				end
				return naturalSortCompare(aPathName, bPathName)
			elseif sortMode == "LEVEL" then
				if a.level and not b.level then return false
				elseif not a.level and b.level then return true
				elseif a.level and b.level then
					if a.level ~= b.level then return a.level < b.level end
				end
				return naturalSortCompare(aPathName, bPathName)
			else
				return naturalSortCompare(aPathName, bPathName)
			end
		end
	end)
end

return {
	buildSortDropList = buildSortDropList,
	CanMoveToSubPath = CanMoveToSubPath,
	FilterList = FilterList,
	ScanFolder = ScanFolder,
	SortList = SortList,
}
