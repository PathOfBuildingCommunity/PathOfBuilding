require("HeadlessWrapper")
lu = require('luaunit')

LoadModule("Test/Scenario/TestAttacks")

os.exit( lu.LuaUnit.run() )