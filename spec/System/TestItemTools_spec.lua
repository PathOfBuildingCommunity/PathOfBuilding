local applyRangeTests = {
    -- Number without range
    [{ "+10 to maximum Life", 1.0, 1.0 }] = "+10 to maximum Life",
    [{ "+10 to maximum Life", 1.0, 1.5 }] = "+15 to maximum Life",
    [{ "+10 to maximum Life", 0.5, 1.0 }] = "+10 to maximum Life",
    [{ "+10 to maximum Life", 0.5, 1.5 }] = "+15 to maximum Life",
    -- One range
    [{ "+(10-20) to maximum Life", 1.0, 1.0 }] = "+20 to maximum Life",
    [{ "+(10-20) to maximum Life", 1.0, 1.5 }] = "+30 to maximum Life",
    [{ "+(10-20) to maximum Life", 0.5, 1.0 }] = "+15 to maximum Life",
    [{ "+(10-20) to maximum Life", 0.5, 1.5 }] = "+22 to maximum Life",
    -- Two ranges
    [{ "Adds (60-80) to (270-300) Physical Damage", 1.0, 1.0 }] = "Adds 80 to 300 Physical Damage",
    [{ "Adds (60-80) to (270-300) Physical Damage", 1.0, 1.5 }] = "Adds 120 to 450 Physical Damage",
    [{ "Adds (60-80) to (270-300) Physical Damage", 0.5, 1.0 }] = "Adds 70 to 285 Physical Damage",
    [{ "Adds (60-80) to (270-300) Physical Damage", 0.5, 1.5 }] = "Adds 105 to 427 Physical Damage",
    -- Range with increased/reduced
    [{ "(10--10)% increased Charges per use", 1.0, 1.0 }] = "10% reduced Charges per use",
    [{ "(10--10)% increased Charges per use", 1.0, 1.5 }] = "15% reduced Charges per use",
    [{ "(10--10)% increased Charges per use", 0.5, 1.0 }] = "0% increased Charges per use",
    [{ "(10--10)% increased Charges per use", 0.5, 1.5 }] = "0% increased Charges per use",
    [{ "(10--10)% increased Charges per use", 0.0, 1.0 }] = "10% increased Charges per use",
    [{ "(10--10)% increased Charges per use", 0.0, 1.5 }] = "15% increased Charges per use",
    -- Range with constant numbers after
    [{ "(15-20)% increased Cold Damage per 1% Cold Resistance above 75%", 1.0, 1.0 }] = "20% increased Cold Damage per 1% Cold Resistance above 75%",
    [{ "(15-20)% increased Cold Damage per 1% Cold Resistance above 75%", 1.0, 1.5 }] = "30% increased Cold Damage per 1% Cold Resistance above 75%",
    [{ "(15-20)% increased Cold Damage per 1% Cold Resistance above 75%", 0.5, 1.0 }] = "18% increased Cold Damage per 1% Cold Resistance above 75%",
    [{ "(15-20)% increased Cold Damage per 1% Cold Resistance above 75%", 0.5, 1.5 }] = "27% increased Cold Damage per 1% Cold Resistance above 75%",
    -- High precision range
    [{ "Regenerate (66.7-75) Life per second", 1.0, 1.0 }] = "Regenerate 75 Life per second",
    [{ "Regenerate (66.7-75) Life per second", 1.0, 1.5 }] = "Regenerate 112.5 Life per second",
    [{ "Regenerate (66.7-75) Life per second", 0.5, 1.0 }] = "Regenerate 70.9 Life per second",
    [{ "Regenerate (66.7-75) Life per second", 0.5, 1.5 }] = "Regenerate 106.3 Life per second",
    -- Range with plus sign that is removed when negative
    [{ "+(-25-50)% to Fire Resistance", 1.0, 1.0 }] = "+50% to Fire Resistance",
    [{ "+(-25-50)% to Fire Resistance", 1.0, 1.5 }] = "+75% to Fire Resistance",
    [{ "+(-25-50)% to Fire Resistance", 0.0, 1.0 }] = "-25% to Fire Resistance",
    [{ "+(-25-50)% to Fire Resistance", 0.0, 1.5 }] = "-37% to Fire Resistance",
}

describe("TestItemTools", function()
    for args, expected in pairs(applyRangeTests) do
        it(string.format("tests applyRange('%s', %.2f, %.2f)", unpack(args)), function()
            local result = itemLib.applyRange(unpack(args))
            assert.are.equals(expected, result)
        end)
    end
end)