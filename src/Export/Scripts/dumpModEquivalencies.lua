-- Dump ModEquivalencies rows to check if Foulborn (MutatedUnique) pairings exist
-- Run from the Export tool: loads dat files, prints matching rows

local found = 0
local total = 0

print("=== ModEquivalencies Dump ===")
print("")

-- First pass: dump ALL rows that involve MutatedUnique mods
print("--- Rows containing MutatedUnique mods ---")
for row in dat("ModEquivalencies"):Rows() do
	total = total + 1
	local id = row.Id or ""
	local m0 = row.ModsKey0 and row.ModsKey0.Id or "(nil)"
	local m1 = row.ModsKey1 and row.ModsKey1.Id or "(nil)"
	local m2 = row.ModsKey2 and row.ModsKey2.Id or "(nil)"

	if m0:match("MutatedUnique") or m1:match("MutatedUnique") or m2:match("MutatedUnique")
		or id:match("MutatedUnique") or id:match("Foulborn") or id:match("Mutated") then
		found = found + 1
		print(string.format("Row: Id=%s", id))
		print(string.format("  ModsKey0: %s", m0))
		print(string.format("  ModsKey1: %s", m1))
		print(string.format("  ModsKey2: %s", m2))
		print("")
	end
end

print(string.format("--- Found %d matching rows out of %d total ---", found, total))
print("")

-- Second pass: dump a sample of ALL rows (first 20) so we can see the general structure
print("--- Sample of first 20 rows (any type) ---")
local count = 0
for row in dat("ModEquivalencies"):Rows() do
	count = count + 1
	if count > 20 then break end
	local id = row.Id or ""
	local m0 = row.ModsKey0 and row.ModsKey0.Id or "(nil)"
	local m1 = row.ModsKey1 and row.ModsKey1.Id or "(nil)"
	local m2 = row.ModsKey2 and row.ModsKey2.Id or "(nil)"
	print(string.format("  [%d] Id=%s | M0=%s | M1=%s | M2=%s", count, id, m0, m1, m2))
end
print("")
print("Done.")
