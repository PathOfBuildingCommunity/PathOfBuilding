local band = bit.band
local bor = bit.bor
local rshift = bit.rshift
local lshift = bit.lshift
local tohex = bit.tohex
local bswap4 = bit.bswap
local push = table.insert
local schar = string.char
local sbyte = string.byte

local function wnum(n, c)
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
    -- dat64 value(8 uint)
    local dataOffset = 4 + (8*size)
    out:write(wnum(size,4))

    local row = 0
    local stringIndex = 8
    for v, s in ipairs(enumTable) do
        out:write(wnum(stringIndex,8))
        local utf16 = convertUTF8to16(s)
        stringIndex = stringIndex + utf16:len() + 2
        row = row + 1
    end
    for i = 1, 8 do
        out:write(schar(0xBB))
    end
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
