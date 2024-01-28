local band = bit.band
local rshift = bit.rshift
local push = table.insert
local schar = string.char

local function writeNum(n, c)
    local bytes = {}
    for i = 1, c do
        push(bytes, schar(band(n, 0xFF)))
        n = rshift(n, 8)
    end
    return table.concat(bytes)
end

function len(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

local function writeEnum(filename, enumTable)
    local filenameAbs = "./ggpk/data/" .. filename
    local out = io.open(filenameAbs, "wb")
    local size = len(enumTable)

    out:write(writeNum(size,4))

    -- Write fields
    local stringIndex = 8
    for v, s in ipairs(enumTable) do
        out:write(writeNum(stringIndex,8))
        local utf16 = convertUTF8to16(s)
        stringIndex = stringIndex + utf16:len() + 2
    end

    -- data offset mark
    for i = 1, 8 do
        out:write(schar(0xBB))
    end

    -- strings in utf16
    for _, s in ipairs(enumTable) do
        out:write(convertUTF8to16(s) .. "\0\0")
    end
    
    out:close()
    print("Wrote " .. size .. " enum types to " .. filename)
end


-- influenced types
local influenceTypes = {
    "Shaper",
    "Elder",
    "Crusader",
    "Eyrie",
    "Basilisk",
    "Adjudicator",
    "None"
}

writeEnum("influenceTypes.dat64", influenceTypes)

-- passive Skills types
local passiveSkillTypes  = {
    "Passive Tree",
    "Atlas Tree"
}
writeEnum("passiveSkillTypes.dat64", passiveSkillTypes)
