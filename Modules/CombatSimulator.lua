-- Path of Building
--
-- Module: Combat Simulator
-- Simulates Real-Time Combat (rather than average based)
--

math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )

local targetVersion = "3_0"
local calcs = LoadModule("Modules/Calcs", targetVersion)

local cs = {}
cs.player = { }

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max

local TICK = 1 / data.misc.ServerTickRate

local function setPlayerWeaponInfo(env)
    cs.player.MH_Aps = env.player.output.MainHand.Speed
    cs.player.MH_PhysMinDmg = env.player.output.MainHand.PhysicalMin
    cs.player.MH_PhysMaxDmg = env.player.output.MainHand.PhysicalMax
    cs.player.MH_HitChance = env.player.output.MainHand.HitChance
    cs.player.MH_CritChance = env.player.output.MainHand.CritChance
    cs.player.MH_CritMultiplier = env.player.output.MainHand.CritMultiplier
    ConPrintf("PhysDmg MH Min: " .. cs.player.MH_PhysMinDmg)
    ConPrintf("PhysDmg MH Max: " .. cs.player.MH_PhysMaxDmg)
    ConPrintf("MH Crit Chance: " .. cs.player.MH_CritChance)
    ConPrintf("MH Crit Multiplier: " .. cs.player.MH_CritMultiplier)

    cs.player.isDualWield = env.player.modDB.conditions.DualWielding

    if cs.player.isDualWield then
        cs.player.OH_Aps = env.player.output.OffHand.Speed
        cs.player.OH_PhysMinDmg = env.player.output.OffHand.PhysicalMin
        cs.player.OH_PhysMaxDmg = env.player.output.OffHand.PhysicalMax
        cs.player.OH_HitChance = env.player.output.OffHand.HitChance
        cs.player.OH_CritChance = env.player.output.OffHand.CritChance
        cs.player.OH_CritMultiplier = env.player.output.OffHand.CritMultiplier
        ConPrintf("PhysDmg OH Min: " .. cs.player.OH_PhysMinDmg)
        ConPrintf("PhysDmg OH Max: " .. cs.player.OH_PhysMaxDmg)
        ConPrintf("OH Crit Chance: " .. cs.player.OH_CritChance)
        ConPrintf("OH Crit Multiplier: " .. cs.player.OH_CritMultiplier)

        cs.player.LastDmgFunc = nil
    end
end

local function getPlayerData(build)
    local env = calcs.initEnv(build, "CALCS")

    if env then
        -- Set settings to "UNBUFFED"
        env.mode_buffs = false
        env.mode_combat = false
        env.mode_effective = false

        -- Run pass on environment to get data
        calcs.perform(env)

        cs.player.aps = env.player.output.Speed
        cs.player.attackInterval = env.player.output.Time

        ConPrintf("\n\n=== COMBAT SIMULATOR ===\n")
        setPlayerWeaponInfo(env)

        ConPrintf("APS: " .. cs.player.aps)
        ConPrintf("Attack Internval: " .. cs.player.attackInterval)
    end
end

local function isCrit(critChance)
    local critChance = critChance * 100
    local randValue = math.random(1, 10000)
    if randValue <= critChance then
        cs.simData.numCrits = cs.simData.numCrits + 1
        return true
    end
    return false
end

local function getMainHandDmg()
    local dmg = math.random(cs.player.MH_PhysMinDmg, cs.player.MH_PhysMaxDmg)
    if isCrit(cs.player.MH_CritChance) then
        dmg = dmg * cs.player.MH_CritMultiplier
    end
    return dmg
end

local function getOffHandDmg()
    local dmg = math.random(cs.player.OH_PhysMinDmg, cs.player.OH_PhysMaxDmg)
    if isCrit(cs.player.OH_CritChance) then
        dmg = dmg * cs.player.OH_CritMultiplier
    end
    return dmg
end

local function getNextDmg()
    if cs.player.isDualWield and cs.player.LastDmgFunc == getMainHandDmg then
        cs.player.LastDmgFunc = getOffHandDmg
        return getOffHandDmg()
    end
    return getMainHandDmg()
end

local function getDmg()
    cs.simData.numAttacks = cs.simData.numAttacks + 1
    return getNextDmg()
end

local function runSingleSim(numSec, player)
    cs.simData = {
        numAttacks = 0,
        numCrits = 0,
        numMisses = 0,
    }
    local t = 0.0
    local t_tenth = 0.1
    local t_next_attack = cs.player.attackInterval
    local dmg_done = 0
    
    while t < numSec + 0.00001 do
        if t_next_attack <= t then
            local rand_dmg = getDmg()
            dmg_done = dmg_done + rand_dmg
            t_next_attack = t_next_attack + cs.player.attackInterval
            --ConPrintf("T: " .. t .. ", Dmg: " .. rand_dmg)
        end

        t = t + TICK
        if t_tenth - round(t,2) < 0.0001 then
            t = round(t - 3*TICK + 0.1, 1)
            t_tenth = t_tenth + 0.1
        end
        if t > t_tenth then
            t_tenth = t_tenth + 0.1
        end
    end

    return dmg_done / t
end

function cs.runSimulation(build)
    local numSims = 1000
    local numSecsPerSim = 100

    getPlayerData(build)

    local avg_sim_dmg = 0
    local avg_sim_attacks = 0
    local avg_sim_crits = 0
    for i = 1, numSims do
        local ret = runSingleSim(numSecsPerSim)
        --ConPrintf("Num Attacks: " .. cs.simData.numAttacks .. ", Num Crits: " .. cs.simData.numCrits)
        avg_sim_dmg = avg_sim_dmg + ret
        avg_sim_attacks = avg_sim_attacks + cs.simData.numAttacks
        avg_sim_crits = avg_sim_crits + cs.simData.numCrits
    end
    ConPrintf("\nAvg DPS: " .. avg_sim_dmg / numSims)
    ConPrintf("Avg Num of Attacks: " .. avg_sim_attacks / numSims)
    ConPrintf("Avg Num of Crits: " .. avg_sim_crits / numSims .. " --> (" .. avg_sim_crits * 100 / avg_sim_attacks .. "%%)")
end

return cs
