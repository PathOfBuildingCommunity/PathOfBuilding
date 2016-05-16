#@ SimpleGraphic
-- Path of Building
--
-- Module: Launch Install
-- Installation bootstrap
--

local curl = require("lcurl")
local outFile = io.open("Launch.lua", "wb")
local easy = curl.easy()
easy:setopt_url("https://raw.githubusercontent.com/Openarl/PathOfBuilding/master/Launch.lua")
easy:setopt_writefunction(outFile)
easy:perform()
easy:close()
outFile:close()
Restart()