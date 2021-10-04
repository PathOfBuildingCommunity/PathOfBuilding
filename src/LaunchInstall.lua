#@ SimpleGraphic
-- Path of Building
--
-- Module: Launch Install
-- Installation bootstrap
--

local basicFiles = { "UpdateCheck.lua", "UpdateApply.lua", "Launch.lua" }

local xml = require("xml")
local curl = require("lcurl.safe")

ConClear()
ConPrintf("Preparing to complete installation...\n")

local localBranch, localSource
local localManXML = xml.LoadXMLFile("manifest.xml")
if localManXML and localManXML[1].elem == "PoBVersion" then
	for _, node in ipairs(localManXML[1]) do
		if type(node) == "table" then
			if node.elem == "Version" then
				localBranch = node.attrib.branch
			elseif node.elem == "Source" then
				if node.attrib.part == "program" then
					localSource = node.attrib.url
				end
			end
		end
	end
end
if not localBranch or not localSource then
	Exit("Install failed. (Missing or invalid manifest)")
	return
end
localSource = localSource:gsub("{branch}", localBranch)
for _, name in ipairs(basicFiles) do
	local text = ""
	local easy = curl.easy()
	easy:setopt_url(localSource..name)
	easy:setopt_writefunction(function(data)
		text = text..data 
		return true 
	end)
	easy:perform()
	local size = easy:getinfo(curl.INFO_SIZE_DOWNLOAD)
	easy:close()
	if size == 0 then
		Exit("Install failed. (Couldn't download program files)")
		return
	end
	local outFile = io.open(name, "wb")
	outFile:write(text)
	outFile:close()
end
Restart()