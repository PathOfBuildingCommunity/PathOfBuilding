-- Path of Building
--
-- Module: Calc Breakdown
-- Calculation breakdown generators
--
local modDB, output, actor = ...

local unpack = unpack
local ipairs = ipairs
local t_insert = table.insert
local s_format = string.format

local breakdown = { }

function breakdown.multiChain(out, chain)
	local base = chain.base
	local lines = 0
	for _, mult in ipairs(chain) do
		if mult[2] and mult[2] ~= 1 then
			if lines == 0 then
				if base then
					if chain.label then
						t_insert(out, chain.label)
					end
					t_insert(out, base)
					t_insert(out, "x "..s_format(unpack(mult)))
					lines = 2
				else
					base = s_format(unpack(mult))
				end
			else
				t_insert(out, "x "..s_format(unpack(mult)))
				lines = lines + 1
			end
		end
	end
	if lines > 0 then
		t_insert(out, chain.total)
	end
	return lines
end

function breakdown.simple(extraBase, cfg, total, ...)
	extraBase = extraBase or 0
	local base = modDB:Sum("BASE", cfg, (...))
	if (base + extraBase) ~= 0 then
		local inc = modDB:Sum("INC", cfg, ...)
		local more = modDB:Sum("MORE", cfg, ...)
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

function breakdown.mod(cfg, ...)
	local inc = modDB:Sum("INC", cfg, ...)
	local more = modDB:Sum("MORE", cfg, ...)
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
	local more = modDB:Sum("MORE", cfg, ...)
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

function breakdown.effMult(damageType, resist, pen, taken, mult)
	local out = { }
	local resistForm = (damageType == "Physical") and "physical damage reduction" or "resistance"
	if resist ~= 0 then
		t_insert(out, s_format("Enemy %s: %d%%", resistForm, resist))
	end
	if pen ~= 0 then
		t_insert(out, "Effective resistance:")
		t_insert(out, s_format("%d%% ^8(resistance)", resist))
		t_insert(out, s_format("- %d%% ^8(penetration)", pen))
		t_insert(out, s_format("= %d%%", resist - pen))
	end
	if (resist - pen) ~= 0 and taken ~= 0 then
		t_insert(out, "Effective DPS modifier:")
		t_insert(out, s_format("%.2f ^8(%s)", 1 - (resist - pen) / 100, resistForm))
		t_insert(out, s_format("x %.2f ^8(increased/reduced damage taken)", 1 + taken / 100))
		t_insert(out, s_format("= %.3f", mult))
	end
	return out
end

function breakdown.dot(out, baseVal, inc, more, rate, effMult, total)
	breakdown.multiChain(out, {
		base = s_format("%.1f ^8(base damage per second)", baseVal), 
		{ "%.2f ^8(increased/reduced)", 1 + inc/100 },
		{ "%.2f ^8(more/less)", more },
		{ "%.2f ^8(rate modifier)", rate },
		{ "%.3f ^8(effective DPS modifier)", effMult },
		total = s_format("= %.1f ^8per second", total),
	})
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