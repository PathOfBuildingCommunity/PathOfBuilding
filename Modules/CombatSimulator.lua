-- Combat Simulator

math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )

local cs = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max

LoadModule("Common")
LoadModule("Data")

TICK = 1 / data.misc.ServerTickRate

local heroProfile = {
    minDmg = 10,
    maxDmg = 40,
    aps = 14.67
}

local function GetAttackInterval(aps)
    return 1.0/aps
end

local function runSingleSim(numSec, heroProfile)
    local t = 0.0
    local t_tenth = 0.1
    local t_next_attack = 0.0
    local dmg_done = 0
    
    while t < numSec + 0.00001 do
        if t_next_attack < t then
            local rand_dmg = math.random(heroProfile.minDmg, heroProfile.maxDmg)
            dmg_done = dmg_done + rand_dmg
            t_next_attack = t_next_attack + GetAttackInterval(heroProfile.aps)
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

function runSimulation(numSims, numSecsPerSim)
    local avg_sim_dmg = 0
    for i = 1, numSims do
        local ret = runSingleSim(numSecsPerSim)
        avg_sim_dmg = avg_sim_dmg + ret
    end
    ConPrintf("Avg DPS: " .. avg_sim_dmg/numSims)
end

runSimulation(1000, 2.0)