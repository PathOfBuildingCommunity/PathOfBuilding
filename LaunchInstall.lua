#@ SimpleGraphic
-- Path of Building
--
-- Module: Launch Install
-- Installation bootstrap
--

local basicFiles = { "Launch.lua", "UpdateCheck.lua", "UpdateApply.lua" }

local xml = require("xml")
local curl = require("lcurl")

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
for _, name in pairs(basicFiles) do
	local outFile = io.open(name, "wb")
	local easy = curl.easy()
	easy:setopt_url(localSource..name)
	easy:setopt_writefunction(outFile)
	easy:perform()
	local size = easy:getinfo(curl.INFO_SIZE_DOWNLOAD)
	easy:close()
	outFile:close()
	if size == 0 then
		Exit("Install failed. (Couldn't download program files)")
		return
	end
end
Restart()