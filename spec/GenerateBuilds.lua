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
                if file:match("^.+(%..+)$") == ".xml" then
                    local fileHnd, errMsg = io.open(f, "r")
                    if not fileHnd then
                        return nil, errMsg
                    end
                    local fileText = fileHnd:read("*a")
                    fileHnd:close()
                    buildList[f] = fileText
                end
            end
        end
    end
    return buildList
end

function buildTable(tableName, values, string)
    string = string or ""
    string = string .. tableName .. " = {"
    for key, value in pairs(values) do
        if type(value) == "table" then
            buildTable(key, value, string)
        elseif type(value) == "boolean" then
            string = string .. "[\"" .. key .. "\"] = " .. (value and "true" or "false") .. ",\n"
        elseif type(value) == "string" then
            string = string .. "[\"" .. key .. "\"] = \"" .. value .. "\",\n"
        else
            string = string .. "[\"" .. key .. "\"] = " .. round(value, 4) .. ",\n"
        end
    end
    string = string .. "}\n"
    return string
end

local buildList = fetchBuilds("../spec/TestBuilds")
for filename, testBuild in pairs(buildList) do
    loadBuildFromXML(testBuild)
    local fileHnd, errMsg = io.open(filename:gsub("^(.+)%..+$", "%1.lua"), "w+")
    fileHnd:write("return {\n   xml = [[")
    fileHnd:write(testBuild)
    fileHnd:write("]],\n    ")
    fileHnd:write(buildTable("output", build.calcsTab.mainOutput) .. "\n}")
    fileHnd:close()
end