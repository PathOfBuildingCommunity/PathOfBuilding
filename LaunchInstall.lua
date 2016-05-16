#@ SimpleGraphic
-- Path of Building
--
-- Module: Launch Install
-- Installation bootstrap
--

local basicFiles = {
	["Launch.lua"] = "https://raw.githubusercontent.com/Openarl/PathOfBuilding/master/Launch.lua",
	["Update.lua"] = "https://raw.githubusercontent.com/Openarl/PathOfBuilding/master/Update.lua",
}
local curl = require("lcurl")
for name, url in pairs(basicFiles) do
	local outFile = io.open(name, "wb")
	local easy = curl.easy()
	easy:setopt_url(url)
	easy:setopt_writefunction(outFile)
	easy:perform()
	easy:close()
	outFile:close()
end
Restart()