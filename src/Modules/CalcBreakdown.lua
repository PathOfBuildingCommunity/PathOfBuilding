-- Path of Building
--
-- Module: Calc Breakdown
-- Calculation breakdown generators
--
local modDB, output, actor = ...

local unpack = unpack
local ipairs = ipairs
local t_insert = table.insert
local m_floor = math.floor
local m_sqrt = math.sqrt
local s_format = string.format

local breakdown = { }

function breakdown.multiChain(out, chain)
	local base = (chain.base and chain.base[2]) or nil
	local multiplier = 1
	local lines = 0 -- lines is the total number of non 1 multipliers.
	if chain.label then
		t_insert(out, chain.label)
	end
	if base ~= nil then
		t_insert(out, s_format(unpack(chain.base)))
	end
	if base ~= 0 then
		for _, mult in ipairs(chain) do
			if mult[2] and mult[2] ~= 1 then
				multiplier = multiplier * mult[2]
				t_insert(out, "x "..s_format(unpack(mult)))
				lines = lines + 1
			end
		end
	end
	if chain.total then
		t_insert(out, chain.total)
	elseif (lines > 0 and base ~= nil) or (lines > 1 and base == nil) then
		t_insert(out, s_format("= %.2f", multiplier * (base or 1)))
	end
	return lines
end

function breakdown.simple(extraBase, cfg, total, ...)
	extraBase = extraBase or 0
	local base = modDB:Sum("BASE", cfg, (...))
	if (base + extraBase) ~= 0 then
		local inc = modDB:Sum("INC", cfg, ...)
		local more = modDB:More(cfg, ...)
		if inc ~= 0 or more ~= 1 or (base ~= 0 and extraBase ~= 0) then
			local out = { }
			if base ~= 0 and extraBase ~= 0 then
				out[1] = s_format("(%g + %g) ^8(base)", extraBase, base)
			else
				out[1] = s_format("%g ^8(base)", base + extraBase)
			end
			if inc ~= 0 then
				t_insert(out, s_format("x %.2f ^8(increased/reduced)", 1 + inc/100))
			end
			if more ~= 1 then
				t_insert(out, s_format("x %.2f ^8(more/less)", more))
			end
			t_insert(out, s_format("= %g", total))
			return out
		end
	end
end

function breakdown.mod(modList, cfg, ...)
	local inc = modList:Sum("INC", cfg, ...)
	local more = modList:More(cfg, ...)
	if inc ~= 0 and more ~= 1 then
		return { 
			s_format("%.2f ^8(increased/reduced)", 1 + inc/100),
			s_format("x %.2f ^8(more/less)", more),
			s_format("= %.2f", (1 + inc/100) * more),
		}
	end
end

function breakdown.slot(source, sourceName, cfg, base, total, ...)
	local inc = modDB:Sum("INC", cfg, ...)
	local more = modDB:More(cfg, ...)
	t_insert(breakdown[...].slots, {
		base = base,
		inc = (inc ~= 0) and s_format(" x %.2f", 1 + inc/100),
		more = (more ~= 1) and s_format(" x %.2f", more),
		total = s_format("%.2f", total or (base * (1 + inc / 100) * more)),
		source = source,
		sourceName = sourceName,
		item = actor.itemList[source],
	})
end

function breakdown.area(base, areaMod, total, incBreakpoint, moreBreakpoint, redBreakpoint, lessBreakpoint, label)
	local out = {}
	t_insert(out, label)
	if base ~= total then
		t_insert(out, s_format("%d ^8(base radius)", base))
		t_insert(out, s_format("x %.2f ^8(square root of area of effect modifier)", m_floor(100 * m_sqrt(areaMod)) / 100))
		t_insert(out, s_format("= %d", total))
	end
	if incBreakpoint and moreBreakpoint and redBreakpoint and lessBreakpoint then
		t_insert(out, s_format("^8Next breakpoint: %d%% increased AoE / a %d%% more AoE multiplier", incBreakpoint, moreBreakpoint))
		t_insert(out, s_format("^8Previous breakpoint: %d%% reduced AoE / a %d%% less AoE multiplier", redBreakpoint, lessBreakpoint))
	end
	out.radius = total
	return out
end

function breakdown.effMult(damageType, resist, pen, taken, mult, takenMore, sourceRes, useRes)
	local out = { }
	local resistForm = (damageType == "Physical") and "physical damage reduction" or "resistance"
	if sourceRes and sourceRes ~= damageType then
		t_insert(out, s_format("Enemy %s: %d%% ^8(%s)", resistForm, resist, sourceRes))
	elseif resist ~= 0 then
		t_insert(out, s_format("Enemy %s: %d%%", resistForm, resist))
	end
	if pen ~= 0 or not useRes then
		t_insert(out, "Effective resistance:")
		t_insert(out, s_format("%d%% ^8(resistance)", resist))
		if pen < 0 then
			t_insert(out, s_format("+ %d%% ^8(penetration)", -pen))
		elseif pen > 0 then
			t_insert(out, s_format("- %d%% ^8(penetration)", pen))
		end
		if not useRes then
			t_insert(out, s_format("x %d%% ^8(resistance ignored)", 0))
			t_insert(out, s_format("= %d%%", (0)))
		else 
			t_insert(out, s_format("= %d%%", (resist - pen)))
		end
	end
	if useRes then
		breakdown.multiChain(out, {
			label = "Effective DPS modifier:",
			{ "%.2f ^8(%s)", 1 - (resist - pen) / 100, resistForm },
			{ "%.2f ^8(increased/reduced damage taken)", 1 + taken / 100 },
			{ "%.2f ^8(more/less damage taken)", takenMore },
			total = s_format("= %.3f", mult),
		})
	else
		t_insert(out, "Effective DPS modifier:")
		t_insert(out, s_format("= %.3f ^8(increased/reduced damage taken)", mult))
	end
	return out
end

function breakdown.dot(out, baseVal, inc, more, mult, rate, aura, effMult, total)
	breakdown.multiChain(out, {
		base = { "%.1f ^8(base damage per second)", baseVal }, 
		{ "%.2f ^8(increased/reduced)", 1 + inc/100 },
		{ "%.2f ^8(more/less)", more },
		{ "%.2f ^8(multiplier)", 1 + (mult or 0)/100 },
		{ "%.2f ^8(rate modifier)", rate },
		{ "%.3f ^8(aura effect modifier)", aura },
		{ "%.3f ^8(effective DPS modifier)", effMult },
		total = s_format("= %.1f ^8per second", total),
	})
end

function breakdown.critDot(dotMulti, critMulti, dotChance, critChance)
	local combined = (dotMulti * dotChance) + (critMulti * critChance)
	local out = { }
	if dotChance > 0 then
		t_insert(out, s_format("Contribution from Non-crits:"))
		t_insert(out, s_format("%.2f ^8(dot multiplier for non-crits)", dotMulti))
		t_insert(out, s_format("x %.4f ^8(portion of instances created by non-crits)", dotChance))
		t_insert(out, s_format("= %.2f", dotMulti * dotChance))
	end
	if critChance > 0 then
		t_insert(out, s_format("Contribution from Crits:"))
		t_insert(out, s_format("%.2f ^8(dot multiplier for crits)", critMulti))
		t_insert(out, s_format("x %.4f ^8(portion of instances created by crits)", critChance))
		t_insert(out, s_format("= %.2f", critMulti * critChance))
	end
	if (dotChance > 0 and critChance > 0) and (dotMulti ~= critMulti)then
		t_insert(out, s_format("Effective DoT Multiplier:"))
		t_insert(out, s_format("%.2f + %.2f", dotMulti * dotChance, critMulti * critChance))
		t_insert(out, s_format("= %.2f", combined))
	end
	return out
end		
		
function breakdown.leech(instant, instantRate, instances, pool, rate, max, dur)
	local out = { }
	if actor.mainSkill.skillData.showAverage then
		if instant > 0 then
			t_insert(out, s_format("Instant Leech: %.1f", instant))
		end
		if instances > 0 then
			t_insert(out, "Total leeched per instance:")
			t_insert(out, s_format("%d ^8(size of leech destination pool)", pool))
			t_insert(out, "x 0.02 ^8(base leech rate is 2% per second)")
			local rateMod = calcLib.mod(modDB, skillCfg, rate)
			if rateMod ~= 1 then
				t_insert(out, s_format("x %.2f ^8(leech rate modifier)", rateMod))
			end
			t_insert(out, s_format("x %.2fs ^8(instance duration)", dur))
			t_insert(out, s_format("= %.1f", pool * 0.02 * rateMod * dur))
		end
	else
		if instantRate > 0 then
			t_insert(out, s_format("Instant Leech per hit: %.1f", instant))
			t_insert(out, s_format("Instant Leech per second: %.1f", instantRate))
		end
		if instances > 0 then
			t_insert(out, "Rate per instance:")
			t_insert(out, s_format("%d ^8(size of leech destination pool)", pool))
			t_insert(out, "x 0.02 ^8(base leech rate is 2% per second)")
			local rateMod = calcLib.mod(modDB, skillCfg, rate)
			if rateMod ~= 1 then
				t_insert(out, s_format("x %.2f ^8(leech rate modifier)", rateMod))
			end
			t_insert(out, s_format("= %.1f ^8per second", pool * 0.02 * rateMod))
			t_insert(out, "Maximum leech rate against one target:")
			t_insert(out, s_format("%.1f", pool * 0.02 * rateMod))
			t_insert(out, s_format("x %.1f ^8(average instances)", instances))
			local total = pool * 0.02 * rateMod * instances
			t_insert(out, s_format("= %.1f ^8per second", total))
			if total <= max then
				t_insert(out, s_format("Time to reach max: %.1fs", dur))
			end
			t_insert(out, s_format("Leech rate cap: %.1f", max))
			if total > max then
				t_insert(out, s_format("Time to reach cap: %.1fs", dur / total * max))
			end
		end
	end
	return out
end

return breakdown
