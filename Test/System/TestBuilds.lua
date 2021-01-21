function TestBuilds:fetchBuilds(path, buildList)
    local buildList = buildList or {}
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            local attr = lfs.attributes (f)
            assert (type(attr) == "table")
            if attr.mode == "directory" then
                TestBuilds:fetchBuilds(f, buildList)
            else
                table.insert(buildList, LoadModule(f))
            end
        end
    end
    return buildList
end

describe("test all test builds", function()
    it("finds all test builds and compares their output", function()
        local buildList = TestBuilds:fetchBuilds("Test/TestBuilds")
        for _, testBuild in ipairs(buildList) do
            loadBuildFromXML(testBuild.xml)
            for key, value in pairs(testBuild.output) do
                assert.same(build.calcsTab.mainOutput[key], value)
            end
        end
    end)
end)