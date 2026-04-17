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

-- Scan main.buildPath..subPath for .xml builds and sub-folders.
-- filterText is an optional substring filter applied to build filenames.
-- Returns a freshly allocated list of entries in the shape used by BuildListControl.
-- On cloud-read failure opens main:OpenCloudErrorPopup and returns whatever has been
-- collected so far (matching the prior in-module behavior in Modules/BuildList).
local function ScanFolder(subPath, filterText)
	subPath = subPath or ""
	filterText = filterText or ""
	local list = { }
	local handle
	if filterText ~= "" then
		handle = NewFileSearch(main.buildPath..subPath.."*"..filterText.."*.xml")
	else
		handle = NewFileSearch(main.buildPath..subPath.."*.xml")
	end
	while handle do
		local fileName = handle:GetFileName()
		local build = { }
		build.fileName = fileName
		build.subPath = subPath
		build.fullFileName = main.buildPath..subPath..fileName
		build.modified = handle:GetFileModifiedTime()
		build.buildName = fileName:gsub("%.xml$","")
		local fileHnd = io.open(build.fullFileName, "r")
		if fileHnd then
			local fileText = fileHnd:read("*a")
			fileHnd:close()
			if not fileText then
				main:OpenCloudErrorPopup(build.fullFileName)
				return list
			end
			fileText = fileText:match("(<Build.->)")
			if fileText then
				local xml = common.xml.ParseXML(fileText.."</Build>")
				if xml and xml[1] then
					build.level = tonumber(xml[1].attrib.level)
					build.className = xml[1].attrib.className
					build.ascendClassName = xml[1].attrib.ascendClassName
				end
			end
		end
		t_insert(list, build)
		if not handle:NextFile() then
			break
		end
	end
	handle = NewFileSearch(main.buildPath..subPath.."*", true)
	while handle do
		local folderName = handle:GetFileName()
		t_insert(list, {
			folderName = folderName,
			subPath = subPath,
			fullFileName = main.buildPath..subPath..folderName,
			modified = handle:GetFileModifiedTime()
		})
		if not handle:NextFile() then
			break
		end
	end
	return list
end

-- Sort the given list in place using the same rules as the startup build list.
-- sortMode: "NAME" (default), "CLASS", "EDITED", or "LEVEL".
local function SortList(list, sortMode)
	table.sort(list, function(a, b)
		local a_is_folder = a.folderName ~= nil
		local b_is_folder = b.folderName ~= nil

		if a_is_folder and not b_is_folder then return true end
		if not a_is_folder and b_is_folder then return false end

		if sortMode == "EDITED" then
			local modA = a.modified or 0
			local modB = b.modified or 0
			if modA ~= modB then
				return modA > modB
			end
			if a_is_folder then
				return naturalSortCompare(a.folderName, b.folderName)
			else
				return naturalSortCompare(a.fileName, b.fileName)
			end
		end

		if a_is_folder then
			return naturalSortCompare(a.folderName, b.folderName)
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
				return naturalSortCompare(a.fileName, b.fileName)
			elseif sortMode == "LEVEL" then
				if a.level and not b.level then return false
				elseif not a.level and b.level then return true
				elseif a.level and b.level then
					if a.level ~= b.level then return a.level < b.level end
				end
				return naturalSortCompare(a.fileName, b.fileName)
			else
				return naturalSortCompare(a.fileName, b.fileName)
			end
		end
	end)
end

return {
	buildSortDropList = buildSortDropList,
	ScanFolder = ScanFolder,
	SortList = SortList,
}
