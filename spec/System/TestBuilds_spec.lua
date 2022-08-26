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

expose("test all builds #builds", function()
    local buildList = fetchBuilds("../spec/TestBuilds")
    for buildName, testBuild in pairs(buildList) do
        loadBuildFromXML(testBuild.xml, buildName)
        testBuild.result = {}
        for key, value in pairs(testBuild.output) do
            -- Have to assign it to a temporary table here, as the tests will run later, when the 'build' isn't changing
            testBuild.result[key] = build.calcsTab.mainOutput[key]
            it("on build: " .. buildName .. ", key: " .. key, function()
                if type(value) == "number" and type(testBuild.result[key]) == "number" then
                    assert.are.same(round(value, 4), round(testBuild.result[key] or 0, 4))
                else
                    assert.are.same(value, testBuild.result[key])
                end
            end)
        end
    end
end)
