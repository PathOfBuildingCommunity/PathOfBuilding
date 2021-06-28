local function fetchBuilds(path, buildList)
    buildList = buildList or {}
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            local attr = lfs.attributes (f)
            assert(type(attr) == "table")
            if attr.mode == "directory" then
                fetchBuilds(f, buildList)
            elseif file:match("^.+(%..+)$") == ".lua" then
                buildList[file] = LoadModule(f)
            end
        end
    end
    return buildList
end

expose("test all builds", function()

    package.cpath = package.cpath .. ';/mnt/c/Users/trevo/AppData/Roaming/JetBrains/PyCharmCE2021.1/plugins/EmmyLua/classes/debugger/emmy/linux/?.so'
local dbg = require('emmy_core')
dbg.tcpListen('localhost', 9965)
dbg.waitIDE()
    local buildList = fetchBuilds("../spec/TestBuilds")
    for buildName, testBuild in pairs(buildList) do
        loadBuildFromXML(testBuild.xml, buildName)
        for key, value in pairs(testBuild.output) do
            it("on build: " .. buildName .. ", pob build: " .. build.buildName .. ", testing stat: " .. key, function()
                if buildName ~= build.buildName then
                    ConPrintf("Builds don't match.  on build: " .. buildName .. ", pob build: " .. build.buildName)
                    break
                end
                if key == "LowestOfArmourAndEvasion" then
                    ConPrintf("on build: " .. buildName .. ", pob build: " .. build.buildName .. ", testing stat: " .. key .. ", result: " .. build.calcsTab.mainOutput[key])
                end
                if type(value) == "number" then
                    assert.are.same(round(value, 4), round(build.calcsTab.mainOutput[key] or 0, 4))
                else
                    assert.are.same(value, build.calcsTab.mainOutput[key])
                end
            end)
        end
    end
end)
