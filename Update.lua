#@
-- Path of Building
--
-- Module: Update
-- Checks for and applies updates
--
local mode = ...

local xml = require("xml")
local sha1 = require("sha1")
local curl = require("lcurl")
local lzip = require("lzip")

local function downloadFile(url, outName)
	local outFile = io.open(outName, "wb")
	local easy = curl.easy()
	easy:setopt_url(url)
	easy:setopt_writefunction(outFile)
	easy:perform()
	local code = easy:getinfo(curl.INFO_RESPONSE_CODE)
	easy:close()
	outFile:close()
	if code ~= 200 then
		ConPrintf("Download failed (code %d)", code)
		os.remove(outName)
		return true
	end
end

if mode == "CHECK" then
	ConPrintf("Checking for update...")

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
		ConPrintf("Update failed: invalid local manifest")
		return true
	end

	-- Download and process remote manifest
	local remoteVer
	local remoteFiles = { }
	local remoteManText = ""
	local remoteSources = { }
	local easy = curl.easy()
	easy:setopt_url(localSource.."manifest.xml")
	easy:setopt_writefunction(function(data)
		remoteManText = remoteManText..data 
		return true 
	end)
	easy:perform()
	easy:close()
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
		ConPrintf("Update failed: invalid remote manifest")
		return true
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
				if data.sha1 ~= sha1(content) then
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
		ConPrintf("Update failed: nothing to update")
		return
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
				downloadFile(source, zipFileName)
				zipFiles[zipName] = lzip.open(zipFileName)
			end
			local zip = zipFiles[zipName]
			if zip then
				local zippedFile = zip:OpenFile(data.name)
				if zippedFile then
					local file = io.open(fileName, "wb")
					file:write(zippedFile:Read("*a"))
					file:close()
					zippedFile:close()
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
			if downloadFile(source..data.name, fileName) then
				failedFile = true
			end
		end
	end
	for name, zip in pairs(zipFiles) do
		zip:Close()
		os.remove(name)
	end
	if failedFile then
		ConPrintf("Update failed: failed to get all required files")
		return true
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
	local ops = { }
	for _, data in pairs(updateFiles) do
		table.insert(ops, 'copy "'..data.updateFileName..'" "'..data.name..'"')
		table.insert(ops, 'delete "'..data.updateFileName..'"')
	end
	for _, data in pairs(deleteFiles) do
		table.insert(ops, 'delete "'..data.name..'"')
	end
	table.insert(ops, 'copy "Update/manifest.xml" "manifest.xml"')
	table.insert(ops, 'delete "manifest.xml"')

	-- Write operations file
	local opFile = io.open("Update/opFile.txt", "w")
	opFile:write(table.concat(ops, "\n"))
	opFile:close()
end




