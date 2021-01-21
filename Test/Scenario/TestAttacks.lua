TestAttack = {}

function TestAttack:setUp()
    newBuild()
end

function TestAttack:testCritChance()
    lu.assertEquals(build.calcsTab.mainOutput.CritChance, 0)
    build.itemsTab:CreateDisplayItemFromRaw("New Item\nMaraketh Bow\nCrafted: true\nPrefix: None\nPrefix: None\nPrefix: None\nSuffix: None\nSuffix: None\nSuffix: None\nQuality: 20\nSockets: G-G-G-G-G-G\nLevelReq: 71\nImplicits: 1\n{tags:speed}10% increased Movement Speed")
    build.itemsTab:AddDisplayItem()
    runCallback("OnFrame")
    lu.assertEquals(build.calcsTab.mainOutput.CritChance, 5.5 * build.calcsTab.mainOutput.HitChance / 100)
end

function TestAttack:testCritMulti()
    lu.assertEquals(build.calcsTab.mainOutput.CritChance, 0)
    build.itemsTab:CreateDisplayItemFromRaw("New Item\nAssassin Bow\nCrafted: true\nPrefix: None\nPrefix: None\nPrefix: None\nSuffix: None\nSuffix: None\nSuffix: None\nQuality: 20\nSockets: G-G-G-G-G-G\nLevelReq: 62\nImplicits: 1\n{tags:damage,critical}{range:0.5}+(15-25)% to Global Critical Strike Multiplier")
    build.itemsTab:AddDisplayItem()
    runCallback("OnFrame")
    lu.assertEquals(build.calcsTab.mainOutput.CritMultiplier, 1.5 + .2)
end

function TestAttack:tearDown()
    -- newBuild() takes care of resetting everything in setUp()
end