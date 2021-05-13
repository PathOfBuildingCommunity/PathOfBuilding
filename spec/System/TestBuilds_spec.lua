local function fetchBuilds(path, buildList)
    buildList = buildList or {}
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            local attr = lfs.attributes (f)
            assert(type(attr) == "table")
            if attr.mode == "directory" then
                fetchBuilds(f, buildList)
            else
                buildList[file] = LoadModule(f)
            end
        end
    end
    return buildList
end

describe("test all builds", function()

    local buildList = fetchBuilds("../spec/TestBuilds")
    for buildName, testBuild in pairs(buildList) do
        loadBuildFromXML(testBuild.xml)
        for key, value in pairs(testBuild.output) do
            it("on build: " .. buildName .. ", testing stat: " .. key, function()
                if type(value) == "number" then
                    assert.are.same(round(value, 4), round(build.calcsTab.mainOutput[key] or 0, 4))
                else
                    assert.are.same(value, build.calcsTab.mainOutput[key])
                end
            end)
        end
    end
end)
