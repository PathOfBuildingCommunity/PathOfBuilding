#@
-- Path of Building
--
-- Module: Update Check
-- Checks for updates
--

local xml = require("xml")
local sha1 = require("sha1")
local curl = require("lcurl.safe")
local lzip = require("lzip")

local globalRetryLimit = 10
local function downloadFileText(url)
	for i = 1, 5 do
		if i > 1 then
			ConPrintf("Retrying... (%d of 5)", i)
		end
		local text = ""
		local easy = curl.easy()
		easy:setopt_url(url)
		easy:setopt_writefunction(function(data)
			text = text..data 
			return true
		end)
		local _, error = easy:perform()
		easy:close()
		if not error then
			return text
		end
		ConPrintf("Download failed (%s)", error:msg())
		if globalRetryLimit == 0 then
			break
		end
		globalRetryLimit = globalRetryLimit - 1
	end
end
local function downloadFile(url, outName)
	local text = downloadFileText(url)
	if text then
		local outFile = io.open(outName, "wb")
		outFile:write(text)
		outFile:close()
	else
		return true
	end
end

ConPrintf("Checking for update...")

local scriptPath = GetScriptPath()
local runtimePath = GetRuntimePath()

-- Load and process local manifest
local localVer
local localPlatform, localBranch
local localFiles = { }
local localManXML = xml.LoadXMLFile(scriptPath.."/manifest.xml")
local localSource
local runtimeExecutable
if localManXML and localManXML[1].elem == "PoBVersion" then
	for _, node in ipairs(localManXML[1]) do
		if type(node) == "table" then
			if node.elem == "Version" then
				localVer = node.attrib.number
				localPlatform = node.attrib.platform
				localBranch = node.attrib.branch
			elseif node.elem == "Source" then
				if node.attrib.part == "program" then
					localSource = node.attrib.url
				end
			elseif node.elem == "File" then
				local fullPath
				if node.attrib.part == "runtime" then
					fullPath = runtimePath .. "/" .. node.attrib.name
				else
					fullPath = scriptPath .. "/" .. node.attrib.name
				end
				localFiles[node.attrib.name] = { sha1 = node.attrib.sha1, part = node.attrib.part, platform = node.attrib.platform, fullPath = fullPath }
				if node.attrib.part == "runtime" and node.attrib.name:match("Path of Building") then
					runtimeExecutable = fullPath
				end
			end
		end
	end
end
if not localVer or not localSource or not localBranch or not next(localFiles) then
	ConPrintf("Update check failed: invalid local manifest")
	return
end
localSource = localSource:gsub("{branch}", localBranch)

-- Download and process remote manifest
local remoteVer
local remoteFiles = { }
local remoteSources = { }
local remoteManText = downloadFileText(localSource.."manifest.xml")
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
					local fullPath
					if node.attrib.part == "runtime" then
						fullPath = runtimePath .. "/" .. node.attrib.name
					else
						fullPath = scriptPath .. "/" .. node.attrib.name
					end
					remoteFiles[node.attrib.name] = { sha1 = node.attrib.sha1, part = node.attrib.part, platform = node.attrib.platform, fullPath = fullPath }
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
		local file = io.open(localFiles[name].fullPath, "rb")
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

-- Download changelog
downloadFile(localSource.."changelog.txt", scriptPath.."/changelog.txt")

-- Download files that need updating
local failedFile = false
local zipFiles = { }
for index, data in ipairs(updateFiles) do
	if UpdateProgress then
		UpdateProgress("Downloading %d/%d", index, #updateFiles)
	end
	local partSources = remoteSources[data.part]
	local source = partSources[localPlatform] or partSources["any"]
	source = source:gsub("{branch}", localBranch)
	local fileName = scriptPath.."/Update/"..data.name:gsub("[\\/]","{slash}")
	data.updateFileName = fileName
	local content
	local zipName = source:match("/([^/]+%.zip)$")
	if zipName then
		if not zipFiles[zipName] then
			ConPrintf("Downloading %s...", zipName)
			local zipFileName = scriptPath.."/Update/"..zipName
			downloadFile(source, zipFileName)
			zipFiles[zipName] = lzip.open(zipFileName)
		end
		local zip = zipFiles[zipName]
		if zip then
			local zippedFile = zip:OpenFile(data.name)
			if zippedFile then
				content = zippedFile:Read("*a")
				zippedFile:Close()
			else
				ConPrintf("Couldn't extract '%s' from '%s' (extract failed)", data.name, zipName)
			end
		else
			ConPrintf("Couldn't extract '%s' from '%s' (zip open failed)", data.name, zipName)
		end
	else
		ConPrintf("Downloading %s... (%d of %d)", data.name, index, #updateFiles)
		content = downloadFileText(source..data.name)
	end
	if content then
		if data.sha1 ~= sha1(content) and data.sha1 ~= sha1(content:gsub("\n","\r\n")) then
			ConPrintf("Hash mismatch on '%s'", data.name)
			failedFile = true
		else
			local file = io.open(fileName, "w+b")
			file:write(content)
			file:close()
		end
	else
		failedFile = true
	end
end
for name, zip in pairs(zipFiles) do
	zip:Close()
	os.remove(scriptPath.."/Update/"..name)
end
if failedFile then
	ConPrintf("Update failed: one or more files couldn't be downloaded")
	return
end

-- Create new manifest
localManXML = { elem = "PoBVersion" }
table.insert(localManXML, { elem = "Version", attrib = { number = remoteVer, platform = localPlatform, branch = localBranch } })
for part, platforms in pairs(remoteSources) do
	for platform, url in pairs(platforms) do
		table.insert(localManXML, { elem = "Source", attrib = { part = part, platform = platform ~= "any" and platform, url = url } })
	end
end
for name, data in pairs(remoteFiles) do
	table.insert(localManXML, { elem = "File", attrib = { name = data.name, sha1 = data.sha1, part = data.part, platform = data.platform } })
end 
xml.SaveXMLFile(localManXML, scriptPath.."/Update/manifest.xml")

-- Build list of operations to apply the update
local updateMode = "normal"
local ops = { }
local opsRuntime = { }
for _, data in pairs(updateFiles) do
	-- Ensure that the destination path of this file exists
	local dirStr = ""
	for dir in data.fullPath:gmatch("([^/]+/)") do
		dirStr = dirStr .. dir
		MakeDir(dirStr)
	end
	if data.part == "runtime" then
		-- Core runtime file, will need to update from the basic environment
		-- These files will be updated on the second pass of the update script, with the first pass being run within the normal environment
		updateMode = "basic"
		table.insert(opsRuntime, 'move "'..data.updateFileName..'" "'..data.fullPath..'"')
	else
		table.insert(ops, 'move "'..data.updateFileName..'" "'..data.fullPath..'"')
	end
end
for _, data in pairs(deleteFiles) do
	table.insert(ops, 'delete "'..data.fullPath..'"')
end
table.insert(ops, 'move "'..scriptPath..'/Update/manifest.xml" "'..scriptPath..'/manifest.xml"')
if updateMode == "basic" then
	-- Update script will need to relaunch the normal environment after updating
	table.insert(opsRuntime, 'start "'..runtimeExecutable..'"')
	local opRuntimeFile = io.open(scriptPath.."/Update/opFileRuntime.txt", "w+")
	opRuntimeFile:write(table.concat(opsRuntime, "\n"))
	opRuntimeFile:close()
end

-- Write operations file
local opFile = io.open(scriptPath.."/Update/opFile.txt", "w+")
opFile:write(table.concat(ops, "\n"))
opFile:close()

ConPrintf("Update is ready.")
return updateMode
