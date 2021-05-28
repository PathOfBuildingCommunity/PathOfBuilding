local bit32 = require "bit32"

local ops = {}

local band = bit32.band
local bor = bit32.bor
local bxor = bit32.bxor

ops.uint32_lrot = bit32.lrotate
ops.byte_xor = bxor
ops.uint32_xor_3 = bxor
ops.uint32_xor_4 = bxor

function ops.uint32_ternary(a, b, c)
   -- c ~ (a & (b ~ c)) has less bitwise operations than (a & b) | (~a & c).
   return bxor(c, band(a, bxor(b, c)))
end

function ops.uint32_majority(a, b, c)
   -- (a & (b | c)) | (b & c) has less bitwise operations than (a & b) | (a & c) | (b & c).
   return bor(band(a, bor(b, c)), band(b, c))
end

return ops
