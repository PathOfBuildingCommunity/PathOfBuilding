-- Path of Building
--
-- Module: Combat Simulator
-- Simulates Real-Time Combat (rather than average based)
--

math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )

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

local function getPlayerData()
    cs.player = { }
    if global_env then
        cs.player.aps, cs.player.minDmg, cs.player.maxDmg, cs.player.critChance = getPlayerWeaponInfo(global_env)
        ConPrintf("PhysDmg Min: " .. cs.player.minDmg)
        ConPrintf("PhysDmg Max: " .. cs.player.maxDmg)
        ConPrintf("APS: " .. cs.player.aps)
        ConPrintf("Crit Chance: " .. cs.player.critChance)
        cs.player.attackInterval = 1/cs.player.aps
    end
end

local function getDmg()
    local flat_dmg = math.random(cs.player.minDmg, cs.player.maxDmg)
    return flat_dmg
end

local function runSingleSim(numSec, player)
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

function cs.runSimulation()
    local numSims = 1000
    local numSecsPerSim = 100

    getPlayerData()

    local avg_sim_dmg = 0
    for i = 1, numSims do
        local ret = runSingleSim(numSecsPerSim)
        --ConPrintf("DPS [" .. i .. "]: " .. ret)
        avg_sim_dmg = avg_sim_dmg + ret
    end
    ConPrintf("Avg DPS: " .. avg_sim_dmg/numSims)
end

return cs
