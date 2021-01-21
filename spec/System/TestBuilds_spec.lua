local function fetchBuilds(path, buildList)
    local buildList = buildList or {}
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            local attr = lfs.attributes (f)
            assert (type(attr) == "table")
            if attr.mode == "directory" then
                fetchBuilds(f, buildList)
            else
                table.insert(buildList, LoadModule(f))
            end
        end
    end
    return buildList
end

describe("test all test builds", function()

    local buildList = fetchBuilds("spec/TestBuilds")
    for _, testBuild in ipairs(buildList) do
        loadBuildFromXML(testBuild.xml)
        for key, value in pairs(testBuild.output) do
            it("test key: " .. key, function()
                if type(value) == 'number' then
                    value = round(value, 4)
                    build.calcsTab.mainOutput[key] = round(build.calcsTab.mainOutput[key], 4)
                end
                assert.are.equals(build.calcsTab.mainOutput[key], value)
            end)
        end
    end
end)