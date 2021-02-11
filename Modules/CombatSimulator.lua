-- Path of Building
--
-- Module: Combat Simulator
-- Simulates Real-Time Combat (rather than average based)
--

math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )

local targetVersion = "3_0"
local calcs = LoadModule("Modules/Calcs", targetVersion)

local cs = { }
cs.player = { }

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max

local TICK = 1 / data.misc.ServerTickRate

local DmgTypes = { "Physical", "Lightning", "Cold", "Fire", "Chaos" }

local function randomChance(var)
    return math.random(1, 10000) <= (var * 100)
end

local function isHit(hitChance)
    return randomChance(hitChance)
end

local function isCrit(critChance)
    return randomChance(critChance)
end

local function isTrigger(triggerChance)
    return randomChance(triggerChance)
end

local function gainEnduranceCharge(actor)
    actor.EnduranceCount = m_min(actor.EnduranceCount + 1, cs.player.EnduranceChargesMax)
    --ConPrintf("PLAYER GAINED A ENDURANCE CHARGE! Count: " .. actor.EnduranceCount)
end

local function gainFrenzyCharge(actor)
    actor.FrenzyCount = m_min(actor.FrenzyCount + 1, cs.player.FrenzyChargesMax)
    --ConPrintf("PLAYER GAINED A FRENZY CHARGE! Count: " .. actor.FrenzyCount)
end

local function gainPowerCharge(actor)
    actor.PowerCount = m_min(actor.PowerCount + 1, cs.player.PowerChargesMax)
    --ConPrintf("PLAYER GAINED A POWER CHARGE! Count: " .. actor.PowerCount)
end

local activeSkillListEffects = {
    Frenzy = function(actor) 
        t_insert(actor.onHit, gainFrenzyCharge)
    end
}

local function processPlayerSkillInfo(env)
    for _, activeSkill in ipairs(env.player.activeSkillList) do
        local socketGroupID = activeSkill.socketGroup
        local skillName = activeSkill.activeEffect.grantedEffect.name

        if activeSkillListEffects[skillName] then
            activeSkillListEffects[skillName](cs.player)
        end

        for _, supportSkill in ipairs(activeSkill.supportList) do
        end
    end
end

local function processPlayerWeaponInfo(env)
    cs.player.MH_Aps = env.player.output.MainHand.Speed
    cs.player.MH_AttackInterval = 1/cs.player.MH_Aps
    cs.player.MH_HitChance = env.player.output.MainHand.HitChance
    cs.player.MH_CritChance = env.player.output.MainHand.CritChance
    cs.player.MH_CritMultiplier = env.player.output.MainHand.CritMultiplier
    for _, damageType in ipairs(DmgTypes) do
        cs.player["MH_" .. damageType .. "MinDmg"] = env.player.output.MainHand[damageType .. "Min"] or 0
        cs.player["MH_" .. damageType .. "MaxDmg"] = env.player.output.MainHand[damageType .. "Max"] or 0
    end
    
    ConPrintf("MH Hit Chance: " .. cs.player.MH_HitChance)
    ConPrintf("MH APS: " .. cs.player.MH_Aps .. " --> Attack Every " .. cs.player.MH_AttackInterval .. " secs")
    ConPrintf("MH Crit Chance: " .. cs.player.MH_CritChance)
    ConPrintf("MH Crit Multiplier: " .. cs.player.MH_CritMultiplier)
    for _, damageType in ipairs(DmgTypes) do
        ConPrintf(damageType .. " Dmg MH Min: " .. cs.player["MH_" .. damageType .. "MinDmg"])
        ConPrintf(damageType .. " Dmg MH Max: " .. cs.player["MH_" .. damageType .. "MaxDmg"])
    end

    cs.player.isDualWield = env.player.modDB.conditions.DualWielding

    if cs.player.isDualWield then
        cs.player.OH_Aps = env.player.output.OffHand.Speed
        cs.player.OH_AttackInterval = 1/cs.player.OH_Aps
        cs.player.OH_HitChance = env.player.output.OffHand.HitChance
        cs.player.OH_CritChance = env.player.output.OffHand.CritChance
        cs.player.OH_CritMultiplier = env.player.output.OffHand.CritMultiplier
        for _, damageType in ipairs(DmgTypes) do
            cs.player["OH_" .. damageType .. "MinDmg"] = env.player.output.OffHand[damageType .. "Min"] or 0
            cs.player["OH_" .. damageType .. "MaxDmg"] = env.player.output.OffHand[damageType .. "Max"] or 0
        end

        ConPrintf("\nOH Hit Chance: " .. cs.player.OH_HitChance)
        ConPrintf("OH APS: " .. cs.player.OH_Aps .. " --> Attack Every " .. cs.player.OH_AttackInterval .. " secs")
        ConPrintf("OH Crit Chance: " .. cs.player.OH_CritChance)
        ConPrintf("OH Crit Multiplier: " .. cs.player.OH_CritMultiplier)
        for _, damageType in ipairs(DmgTypes) do
            ConPrintf(damageType .. " Dmg OH Min: " .. cs.player["OH_" .. damageType .. "MinDmg"])
            ConPrintf(damageType .. " Dmg OH Max: " .. cs.player["OH_" .. damageType .. "MaxDmg"])
        end

        cs.player.LastDmgFunc = nil
    end
end

local function processPlayerInfo(env)
    cs.player.onHit = { }
    cs.player.onCrit = { }
    cs.player.onDamage = { }
    cs.player.EnduranceChargesMax = env.player.output.EnduranceChargesMax or 3
    cs.player.EnduranceChargesMin = env.player.output.EnduranceChargesMin or 0
    cs.player.FrenzyChargesMax = env.player.output.FrenzyChargesMax or 3
    cs.player.FrenzyChargesMin = env.player.output.FrenzyChargesMin or 0
    cs.player.PowerChargesMax = env.player.output.PowerChargesMax or 3
    cs.player.PowerChargesMin = env.player.output.PowerChargesMin or 0

    processPlayerSkillInfo(env)
    processPlayerWeaponInfo(env)
end

local function getPlayerData(build)
    local env = calcs.initEnv(build, "CALCS")

    -- Set settings to "UNBUFFED"
    env.mode_buffs = false
    env.mode_combat = false
    env.mode_effective = false

    -- Run pass on environment to get data
    calcs.perform(env)

    -- Get Player Information
    processPlayerInfo(env)
end

local function getMainHandDmg(dmgType)
    if isHit(cs.player.MH_HitChance) then
        cs.simData.numMHHits = cs.simData.numMHHits + 1
        local dmg = math.random(cs.player["MH_" .. dmgType .. "MinDmg"], cs.player["MH_" .. dmgType .. "MaxDmg"])
        if isCrit(cs.player.MH_CritChance) then
            cs.simData.numMHCrits = cs.simData.numMHCrits + 1
            dmg = dmg * cs.player.MH_CritMultiplier
        end
        return dmg
    end
    cs.simData.numMHMisses = cs.simData.numMHMisses + 1
    return nil
end

local function getOffHandDmg(dmgType)
    if isHit(cs.player.OH_HitChance) then
        cs.simData.numOHHits = cs.simData.numOHHits + 1
        local dmg = math.random(cs.player["OH_" .. dmgType .. "MinDmg"], cs.player["OH_" .. dmgType .. "MaxDmg"])
        if isCrit(cs.player.OH_CritChance) then
            cs.simData.numOHCrits = cs.simData.numOHCrits + 1
            dmg = dmg * cs.player.OH_CritMultiplier
        end
        return dmg
    end
    cs.simData.numOHMisses = cs.simData.numOHMisses + 1
    return nil
end

local function getNextDmg()
    if cs.player.isDualWield then
        if cs.player.LastDmgFunc == getMainHandDmg then
            cs.player.LastDmgFunc = getOffHandDmg
            return getOffHandDmg("Physical"), cs.player.MH_AttackInterval
        else
            cs.player.LastDmgFunc = getMainHandDmg
            return getMainHandDmg("Physical"), cs.player.OH_AttackInterval
        end
    end
    return getMainHandDmg("Fire"), cs.player.MH_AttackInterval
end

local function getDmg()
    cs.simData.numAttacks = cs.simData.numAttacks + 1
    local dmg, attack_interval = getNextDmg()
    if dmg ~= nil then
        -- Apply On Hit effects (even if damage is 0)
        if #cs.player.onHit > 0 then
            for _, func in ipairs(cs.player.onHit) do
                func(cs.player)
            end
        end

        if dmg > 0 then
            -- Apply on Damage effect (damage is greater than 0)
        end
    end
    return dmg or 0, attack_interval
end

local function runSingleSim(numSec, player)
    local t = 0.0
    local t_tenth = 0.1
    local t_next_attack = cs.player.MH_AttackInterval
    local dmg_done = 0
    
    while t < numSec + 0.00001 do
        if t_next_attack <= t then
            local rand_dmg, attack_interval = getDmg()
            dmg_done = dmg_done + rand_dmg
            t_next_attack = t_next_attack + attack_interval
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

local function initPlayerData(player)
    player.EnduranceCount = player.EnduranceChargesMin
    player.FrenzyCount = player.FrenzyChargesMin
    player.PowerCount = player.PowerChargesMin
end

function cs.runSimulation(build)
    cs.simData = { }
    cs.player = { }
    ConPrintf("\n\n=== COMBAT SIMULATOR ===")
    local numSims = 10000
    local numSecsPerSim = 100
    ConPrintf("Num Simulations: " .. numSims)
    ConPrintf("Simulated " .. numSecsPerSim .. " seconds per Simulation\n")

    getPlayerData(build)

    local avg_sim_dmg = 0
    local max_sim_dmg = 0
    local min_sim_dmg = 1000000000000
    local avg_sim_attacks = 0
    local avg_sim_mh_hits = 0
    local avg_sim_oh_hits = 0
    local avg_sim_mh_misses = 0
    local avg_sim_mh_crits = 0
    local avg_sim_oh_misses = 0
    local avg_sim_oh_crits = 0
    for i = 1, numSims do
        -- prepare per run simulation data variables
        cs.simData.numAttacks = 0
        cs.simData.numMHHits = 0
        cs.simData.numOHHits = 0
        cs.simData.numMHCrits = 0
        cs.simData.numMHMisses = 0
        cs.simData.numOHCrits = 0
        cs.simData.numOHMisses = 0

        -- initialize per run environment
        initPlayerData(cs.player)

        -- run single simulation
        local ret = runSingleSim(numSecsPerSim)

        -- Updated per-run averages
        avg_sim_dmg = avg_sim_dmg + ret
        if ret > max_sim_dmg then max_sim_dmg = ret end
        if ret < min_sim_dmg then min_sim_dmg = ret end
        avg_sim_attacks = avg_sim_attacks + cs.simData.numAttacks
        avg_sim_mh_hits = avg_sim_mh_hits + cs.simData.numMHHits
        avg_sim_oh_hits = avg_sim_oh_hits + cs.simData.numOHHits
        avg_sim_mh_misses = avg_sim_mh_misses + cs.simData.numMHMisses
        avg_sim_mh_crits = avg_sim_mh_crits + cs.simData.numMHCrits
        avg_sim_oh_misses = avg_sim_oh_misses + cs.simData.numOHMisses
        avg_sim_oh_crits = avg_sim_oh_crits + cs.simData.numOHCrits
    end
    ConPrintf("========================")
    ConPrintf("\nMax DPS across all simulations: " .. max_sim_dmg)
    ConPrintf("Min DPS across all simulations: " .. min_sim_dmg)
    ConPrintf("\nAvg DPS: " .. avg_sim_dmg / numSims)
    ConPrintf("Avg Num of Attacks: " .. avg_sim_attacks / numSims)
    if cs.player.isDualWield then
        ConPrintf("Avg Num of MH Misses: " .. avg_sim_mh_misses / numSims .. " --> (" .. avg_sim_mh_misses * 100 / (avg_sim_mh_hits + avg_sim_mh_misses) .. "%%)")
        ConPrintf("Avg Num of MH Crits: " .. avg_sim_mh_crits / numSims .. " --> (" .. avg_sim_mh_crits * 100 / (avg_sim_mh_hits + avg_sim_mh_misses) .. "%%)")
        ConPrintf("Avg Num of OH Misses: " .. avg_sim_oh_misses / numSims .. " --> (" .. avg_sim_oh_misses * 100 / (avg_sim_oh_hits + avg_sim_oh_misses) .. "%%)")
        ConPrintf("Avg Num of OH Crits: " .. avg_sim_oh_crits / numSims .. " --> (" .. avg_sim_oh_crits * 100 / (avg_sim_oh_hits + avg_sim_oh_misses) .. "%%)")
    else
        ConPrintf("Avg Num of Misses: " .. avg_sim_mh_misses / numSims .. " --> (" .. avg_sim_mh_misses * 100 / avg_sim_attacks .. "%%)")
        ConPrintf("Avg Num of Crits: " .. avg_sim_mh_crits / numSims .. " --> (" .. avg_sim_mh_crits * 100 / avg_sim_attacks .. "%%)")
    end
    ConPrintf("\n========================")
end

return cs
