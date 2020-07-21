-- Path of Building
--
-- Module: Combat Simulator
-- Simulates Real-Time Combat (rather than average based)
--

math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )

local targetVersion = "3_0"
local calcs = LoadModule("Modules/Calcs", targetVersion)

local cs = {}

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max

local TICK = 1 / data.misc.ServerTickRate

local function getPlayerWeaponInfo(env)
    local weapon1 = env.player.weaponData1
    return weapon1.AttackRate, weapon1.PhysicalMin, weapon1.PhysicalMax, weapon1.CritChance
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
            
        cs.player = { }

        cs.player.critChance = env.player.output.CritChance
        cs.player.critMultiplier = env.player.output.CritMultiplier
        cs.player.aps = env.player.output.Speed
        cs.player.attackInterval = env.player.output.Time
        cs.player.minDmg = env.player.output.MainHand.PhysicalMin
        cs.player.maxDmg = env.player.output.MainHand.PhysicalMax

        ConPrintf("\n\n=== COMBAT SIMULATOR ===\n")
        ConPrintf("PhysDmg Min: " .. cs.player.minDmg)
        ConPrintf("PhysDmg Max: " .. cs.player.maxDmg)
        ConPrintf("APS: " .. cs.player.aps)
        ConPrintf("Attack Internval: " .. cs.player.attackInterval)
        ConPrintf("Crit Chance: " .. cs.player.critChance)
        ConPrintf("Crit Multiplier: " .. cs.player.critMultiplier)
    end
end

local function getCriticalStrikeChance()
    local chance = cs.player.critChance 
    return chance
end

local function getCriticalStrikeMultiplier()
    local multiplier = cs.player.critMultiplier
    return multiplier
end

local function isCrit()
    local critChance = getCriticalStrikeChance() * 100
    local randValue = math.random(1, 10000)
    if randValue <= critChance then
        cs.simData.numCrits = cs.simData.numCrits + 1
        return true
    end
    return false
end

local function getDmg()
    cs.simData.numAttacks = cs.simData.numAttacks + 1
    local dmg = math.random(cs.player.minDmg, cs.player.maxDmg)
    if isCrit() then
        dmg = dmg * getCriticalStrikeMultiplier()
    end
    return dmg
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
    ConPrintf("Avg DPS: " .. avg_sim_dmg / numSims)
    ConPrintf("Avg Num of Attacks: " .. avg_sim_attacks / numSims)
    ConPrintf("Avg Num of Crits: " .. avg_sim_crits / numSims .. " --> (" .. avg_sim_crits * 100 / avg_sim_attacks .. "%%)")
end

return cs
