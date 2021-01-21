require("HeadlessWrapper")
lu = require('luaunit')

LoadModule("Test/Scenario/TestAttacks")
LoadModule("Test/Scenario/TestBuilds")

os.exit( lu.LuaUnit.run() )