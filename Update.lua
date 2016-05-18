#@
-- Path of Building
--
-- Module: Update
-- Checks for and applies updates
--
local mode = ...

local function downloadFile(curl, url, outName)
	local outFile = io.open(outName, "wb")
	local easy = curl.easy()
	easy:setopt_url(url)
	easy:setopt_writefunction(outFile)
	easy:perform()
	local size = easy:getinfo(curl.INFO_SIZE_DOWNLOAD)
	easy:close()
	outFile:close()
	if size == 0 then
		ConPrintf("Download failed")
		os.remove(outName)
		return true
	end
end

local function downloadFileText(curl, url)
	local text = ""
	local easy = curl.easy()
	easy:setopt_url(url)
	easy:setopt_writefunction(function(data)
		text = text..data 
		return true 
	end)
	easy:perform()
	local size = easy:getinfo(curl.INFO_SIZE_DOWNLOAD)
	easy:close()
	if size == 0 then
		ConPrintf("Download failed")
		return nil
	end
	return text
end

if mode == "CHECK" then
	ConPrintf("Checking for update...")

	local xml = require("xml")
	local sha1 = require("sha1")
	local curl = require("lcurl")
	local lzip = require("lzip")

	-- Load and process local manifest
	local localVer
	local localPlatform
	local localFiles = { }
	local localManXML = xml.LoadXMLFile("manifest.xml")
	local localSource
	if localManXML and localManXML[1].elem == "PoBVersion" then
		for _, node in ipairs(localManXML[1]) do
			if type(node) == "table" then
				if node.elem == "Version" then
					localVer = node.attrib.number
					localPlatform = node.attrib.platform
				elseif node.elem == "Source" then
					if node.attrib.part == "program" then
						localSource = node.attrib.url
					end
				elseif node.elem == "File" then
					localFiles[node.attrib.name] = { sha1 = node.attrib.sha1, part = node.attrib.part, platform = node.attrib.platform }
				end
			end
		end
	end
	if not localVer or not localSource or not next(localFiles) then
		ConPrintf("Update check failed: invalid local manifest")
		return
	end

	-- Download and process remote manifest
	local remoteVer
	local remoteFiles = { }
	local remoteSources = { }
	local remoteManText = downloadFileText(curl, localSource.."manifest.xml")
	if not remoteManText then
		ConPrintf("Update check failed: couldn't download version manifest")
		return
	end
	local remoteManXML = xml.ParseXML(remoteManText)
	if remoteManXML and remoteManXML[1].elem == "PoBVersion" then
		for _, node in ipairs(remoteManXML[1]) do
			if type(node) == "table" then
				if node.elem == "Version" then
					remoteVer = node.attrib.number
				elseif node.elem == "Source" then
					if not remoteSources[node.attrib.part] then
						remoteSources[node.attrib.part] = { }
					end
					remoteSources[node.attrib.part][node.attrib.platform or "any"] = node.attrib.url
				elseif node.elem == "File" then
					if not node.attrib.platform or node.attrib.platform == localPlatform then
						remoteFiles[node.attrib.name] = { sha1 = node.attrib.sha1, part = node.attrib.part, platform = node.attrib.platform }
					end
				end
			end
		end
	end
	if not remoteVer or not next(remoteSources) or not next(remoteFiles) then
		ConPrintf("Update check failed: invalid remote manifest")
		return
	end

	-- Build lists of files to be updated or deleted
	local updateFiles = { }
	for name, data in pairs(remoteFiles) do
		data.name = name
		if not localFiles[name] or localFiles[name].sha1 ~= data.sha1 then
			table.insert(updateFiles, data)
		elseif localFiles[name] then
			local file = io.open(name, "rb")
			if not file then
				ConPrintf("Warning: '%s' doesn't exist, it will be re-downloaded", data.name)
				table.insert(updateFiles, data)
			else
				local content = file:read("*a")
				file:close()
				if data.sha1 ~= sha1(content) and data.sha1 ~= sha1(content:gsub("\n","\r\n")) then
					ConPrintf("Warning: Integrity check on '%s' failed, it will be replaced", data.name)
					table.insert(updateFiles, data)
				end
			end
		end
	end
	local deleteFiles = { }
	for name, data in pairs(localFiles) do
		data.name = name
		if not remoteFiles[name] then
			table.insert(deleteFiles, data)
		end
	end
	
	if #updateFiles == 0 and #deleteFiles == 0 then
		ConPrintf("No update available.")
		return "none"
	end

	MakeDir("Update")
	ConPrintf("Downloading update...")

	-- Download files that need updating
	local failedFile = false
	local zipFiles = { }
	for _, data in ipairs(updateFiles) do
		local partSources = remoteSources[data.part]
		local source = partSources[localPlatform] or partSources["any"]
		local fileName = "Update/"..data.name:gsub("[\\/]","{slash}")
		data.updateFileName = fileName
		local zipName = source:match("/([^/]+%.zip)$")
		if zipName then
			if not zipFiles[zipName] then
				ConPrintf("Downloading %s...", zipName)
				local zipFileName = "Update/"..zipName
				downloadFile(curl, source, zipFileName)
				zipFiles[zipName] = lzip.open(zipFileName)
			end
			local zip = zipFiles[zipName]
			if zip then
				local zippedFile = zip:OpenFile(data.name)
				if zippedFile then
					local file = io.open(fileName, "wb")
					file:write(zippedFile:Read("*a"))
					file:close()
					zippedFile:Close()
				else
					ConPrintf("Couldn't extract '%s' from '%s' (extract failed)", data.name, zipName)
					failedFile = true
				end
			else
				ConPrintf("Couldn't extract '%s' from '%s' (zip open failed)", data.name, zipName)
				failedFile = true
			end
		elseif source == "" then
			ConPrintf("File '%s' has no source", data.name)
			failedFile = true
		else
			ConPrintf("Downloading %s...", data.name)
			if downloadFile(curl, source..data.name, fileName) then
				failedFile = true
			end
		end
	end
	for name, zip in pairs(zipFiles) do
		zip:Close()
		os.remove("Update/"..name)
	end
	if failedFile then
		ConPrintf("Update failed: one or more files couldn't be downloaded")
		return
	end

	-- Create new manifest
	localManXML = { elem = "PoBVersion" }
	table.insert(localManXML, { elem = "Version", attrib = { number = remoteVer, platform = localPlatform } })
	for part, platforms in pairs(remoteSources) do
		for platform, url in pairs(platforms) do
			table.insert(localManXML, { elem = "Source", attrib = { part = part, platform = platform ~= "any" and platform, url = url } })
		end
	end
	for name, data in pairs(remoteFiles) do
		table.insert(localManXML, { elem = "File", attrib = { name = data.name, sha1 = data.sha1, part = data.part, platform = data.platform } })
	end 
	xml.SaveXMLFile(localManXML, "Update/manifest.xml")

	-- Build list of operations to apply the update
	local updateMode = "normal"
	local ops = { }
	for _, data in pairs(updateFiles) do
		-- Ensure that the destination path of this file exists
		local dirStr = ""
		for dir in data.name:gmatch("([^/]+/)") do
			dirStr = dirStr .. dir
			MakeDir(dirStr)
		end
		if data.platform then
			-- Core platform file, will need to update from the basic environment
			updateMode = "basic"
			-- Tell update code to pause until this file is writable
			table.insert(ops, 'wait "'..data.name..'"')
		end
		table.insert(ops, 'copy "'..data.updateFileName..'" "'..data.name..'"')
		table.insert(ops, 'delete "'..data.updateFileName..'"')
	end
	for _, data in pairs(deleteFiles) do
		table.insert(ops, 'delete "'..data.name..'"')
	end
	table.insert(ops, 'copy "Update/manifest.xml" "manifest.xml"')
	table.insert(ops, 'delete "Update/manifest.xml"')
	if updateMode == "basic" then
		-- Update script will need to relaunch the normal environment after updating
		table.insert(ops, 'launch')
	end

	-- Write operations file
	local opFile = io.open("Update/opFile.txt", "w")
	opFile:write(table.concat(ops, "\n"))
	opFile:close()

	ConPrintf("Update is ready.")
	return updateMode
end

print("Applying update...")
local opFile = io.open("Update/opFile.txt", "r")
if not opFile then
	return
end
local launch = false
for line in opFile:lines() do
	local op, args = line:match("(%a+) ?(.*)")
	if op == "wait" then
		local name = args:match('"(.*)"')
		local file
		while not file do
			file = io.open(name, "r+")
		end
		file:close()
	elseif op == "copy" then
		local src, dst = args:match('"(.*)" "(.*)"')
		local srcFile = io.open(src, "rb")
		if srcFile then
			local dstFile = io.open(dst, "wb")
			if dstFile then
				dstFile:write(srcFile:read("*a"))
				dstFile:close()
			end
			srcFile:close()
		end
	elseif op == "delete" then
		local file = args:match('"(.*)"')
		os.remove(file)
	elseif op == "launch" then
		launch = true
	end
end
opFile:close()
os.remove("Update/opFile.txt")
if launch then
	os.execute("start PathOfBuilding")
end
