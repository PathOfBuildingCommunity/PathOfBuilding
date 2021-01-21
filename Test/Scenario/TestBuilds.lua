TestBuilds = {}

function TestBuilds:testBuilds()
    local testBuild = LoadModule("Test/TestBuilds/3.13/OccVortex")
    loadBuildFromXML(testBuild.xml)
    for key, value in pairs(testBuild.output) do
        lu.assertEquals(build.calcsTab.mainOutput[key], value)
    end
end