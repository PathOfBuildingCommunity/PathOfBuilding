-- Path of Building
--
-- Module: Global
-- Global constants
--

colorCodes = {
	NORMAL = "^xC8C8C8",
	MAGIC = "^x8888FF",
	RARE = "^xFFFF77",
	UNIQUE = "^xAF6025",
	RELIC = "^x60C060",
	GEM = "^x1AA29B",
	PROPHECY = "^xB54BFF",
	CURRENCY = "^xAA9E82",
	CRAFTED = "^xB8DAF1",
	CUSTOM = "^x5CF0BB",
	SOURCE = "^x88FFFF",
	UNSUPPORTED = "^xF05050",
	DISABLED = "^x7F7F7F",
	WARNING = "^xFF9922",
	TIP = "^x80A080",
	FIRE = "^xB97123",
	COLD = "^x3F6DB3",
	LIGHTNING = "^xADAA47",
	CHAOS = "^xD02090",
	POSITIVE = "^x33FF77",
	NEGATIVE = "^xDD0022",
	HIGHLIGHT ="^xFF0000",
	OFFENCE = "^xE07030",
	DEFENCE = "^x8080E0",
	SCION = "^xFFF0F0",
	MARAUDER = "^xE05030",
	RANGER = "^x70FF70",
	WITCH = "^x7070FF",
	DUELIST = "^xE0E070",
	TEMPLAR = "^xC040FF",
	SHADOW = "^x30C0D0",
	MAINHAND = "^x50FF50",
	MAINHANDBG = "^x071907",
	OFFHAND = "^xB7B7FF",
	OFFHANDBG = "^x070719",
	SHAPER = "^x55BBFF",
	ELDER = "^xAA77CC",
	FRACTURED = "^xA29160",
	MUTATED = "^xCD2285",
	ADJUDICATOR = "^xE9F831",
	BASILISK = "^x00CB3A",
	CRUSADER = "^x2946FC",
	EYRIE = "^xAAB7B8",
	CLEANSING = "^xF24141",
	TANGLE = "^x038C8C",
	CHILLBG = "^x151e26",
	FREEZEBG = "^x0c262b",
	SHOCKBG = "^x191732",
	SCORCHBG = "^x270b00",
	BRITTLEBG = "^x00122b",
	SAPBG = "^x261500",
	SCOURGE = "^xFF6E25",
	CRUCIBLE = "^xFFA500",
	SPLITPERSONALITY = "^xFFD62A",
	VESTIGIAL = "^xCBA5F1",
	INTANGIBILITY = "^x9BF4BD",
	MEMORY = "^xBFE2FA",
}
colorCodes.STRENGTH = colorCodes.MARAUDER
colorCodes.DEXTERITY = colorCodes.RANGER
colorCodes.INTELLIGENCE = colorCodes.WITCH

colorCodes.LIFE = colorCodes.MARAUDER
colorCodes.MANA = colorCodes.WITCH
colorCodes.ES = colorCodes.SOURCE
colorCodes.WARD = colorCodes.RARE
colorCodes.ARMOUR = colorCodes.NORMAL
colorCodes.EVASION = colorCodes.POSITIVE
colorCodes.RAGE = colorCodes.WARNING
colorCodes.PHYS = colorCodes.NORMAL

defaultColorCodes = copyTable(colorCodes)
function updateColorCode(code, color)
 	if colorCodes[code] then
		colorCodes[code] = color:gsub("^0", "^")
		if code == "HIGHLIGHT" then
			rgbColor = hexToRGB(color)
		end
	end
end

function hexToRGB(hex)
	hex = hex:gsub("0x", "") -- Remove "0x" prefix
	hex = hex:gsub("#","") -- Remove '#' if present
	if #hex ~= 6 then
		return nil
	end
	local r = (tonumber(hex:sub(1, 2), 16)) / 255
	local g = (tonumber(hex:sub(3, 4), 16)) / 255
	local b = (tonumber(hex:sub(5, 6), 16)) / 255
	return {r, g, b}
end

ModFlag = { }
-- Damage modes
ModFlag.Attack =	 0x00000001
ModFlag.Spell =		 0x00000002
ModFlag.Hit =		 0x00000004
ModFlag.Dot =		 0x00000008
ModFlag.Cast =		 0x00000010
-- Damage sources
ModFlag.Melee =		 0x00000100
ModFlag.Area =		 0x00000200
ModFlag.Projectile = 0x00000400
ModFlag.SourceMask = 0x00000600
ModFlag.Ailment =	 0x00000800
ModFlag.MeleeHit =	 0x00001000
ModFlag.Weapon =	 0x00002000
-- Weapon types
ModFlag.Axe =		 0x00010000
ModFlag.Bow =		 0x00020000
ModFlag.Claw =		 0x00040000
ModFlag.Dagger =	 0x00080000
ModFlag.Mace =		 0x00100000
ModFlag.Staff =		 0x00200000
ModFlag.Sword =		 0x00400000
ModFlag.Wand =		 0x00800000
ModFlag.Unarmed =	 0x01000000
ModFlag.Fishing =	 0x02000000
-- Weapon classes
ModFlag.WeaponMelee =0x04000000
ModFlag.WeaponRanged=0x08000000
ModFlag.Weapon1H =	 0x10000000
ModFlag.Weapon2H =	 0x20000000
ModFlag.WeaponMask = 0x2FFF0000

KeywordFlag = { }
-- Skill keywords
KeywordFlag.Aura =		0x00000001
KeywordFlag.Curse =		0x00000002
KeywordFlag.Warcry =	0x00000004
KeywordFlag.Movement =	0x00000008
KeywordFlag.Physical =	0x00000010
KeywordFlag.Fire =		0x00000020
KeywordFlag.Cold =		0x00000040
KeywordFlag.Lightning =	0x00000080
KeywordFlag.Chaos =		0x00000100
KeywordFlag.Vaal =		0x00000200
KeywordFlag.Bow =		0x00000400
KeywordFlag.Arrow =		0x00000800
-- Skill types
KeywordFlag.Trap =		0x00001000
KeywordFlag.Mine =		0x00002000
KeywordFlag.Totem =		0x00004000
KeywordFlag.Minion =	0x00008000
KeywordFlag.Attack =	0x00010000
KeywordFlag.Spell =		0x00020000
KeywordFlag.Hit =		0x00040000
KeywordFlag.Ailment =	0x00080000
KeywordFlag.Brand =		0x00100000
-- Other effects
KeywordFlag.Poison =	0x00200000
KeywordFlag.Bleed =		0x00400000
KeywordFlag.Ignite =	0x00800000
-- Damage over Time types
KeywordFlag.PhysicalDot=0x01000000
KeywordFlag.LightningDot=0x02000000
KeywordFlag.ColdDot =	0x04000000
KeywordFlag.FireDot =	0x08000000
KeywordFlag.ChaosDot =	0x10000000
---The default behavior for KeywordFlags is to match *any* of the specified flags.
---Including the "MatchAll" flag when creating a mod will cause *all* flags to be matched rather than any.
KeywordFlag.MatchAll =	0x40000000

-- Helper function to compare KeywordFlags
local band = bit.band
local MatchAllMask = bit.bnot(KeywordFlag.MatchAll)

-- Two-level numeric-key cache to avoid building string keys or allocating tables per call.
local matchKeywordFlagsCache = {}
function ClearMatchKeywordFlagsCache()
	-- cheap full reset without reallocating the outer table
	for k in pairs(matchKeywordFlagsCache) do
		matchKeywordFlagsCache[k] = nil
	end
end

---@param keywordFlags number The KeywordFlags to be compared to.
---@param modKeywordFlags number The KeywordFlags stored in the mod.
---@return boolean Whether the KeywordFlags in the mod are satisfied.
function MatchKeywordFlags(keywordFlags, modKeywordFlags)
	-- Cache lookup
	local row = matchKeywordFlagsCache[keywordFlags]
	if row then
		local cached = row[modKeywordFlags]
		if cached ~= nil then
			return cached
		end
	else
		row = {}
		matchKeywordFlagsCache[keywordFlags] = row
	end
	-- Not in cache, compute normally
	local matchAll = band(modKeywordFlags, KeywordFlag.MatchAll) ~= 0
	local modMasked = band(modKeywordFlags, MatchAllMask)
	local keywordMasked = band(keywordFlags, MatchAllMask)

	local matches
	if matchAll then
		matches = band(keywordMasked, modMasked) == modMasked
	else
		matches = (modMasked == 0) or (band(keywordMasked, modMasked) ~= 0)
	end
	row[modKeywordFlags] = matches -- Add to cache
	return matches
end

-- Active skill types, used in ActiveSkills.dat and GrantedEffects.dat
-- Names taken from ActiveSkillType.dat as of PoE 3.17
SkillType = {
	Attack = 1,
	Spell = 2,
	Projectile = 3, -- Specifically skills which fire projectiles
	DualWieldOnly = 4, -- Attack requires dual wielding, only used on Dual Strike
	Buff = 5,
	Minion = 6,
	Damage = 7, -- Skill hits (not used on attacks because all of them hit)
	Area = 8,
	Duration = 9,
	RequiresShield = 10,
	ProjectileSpeed = 11,
	HasReservation = 12,
	ReservationBecomesCost = 13,
	Trappable = 14, -- Skill can be turned into a trap
	Totemable = 15, -- Skill can be turned into a totem
	Mineable = 16, -- Skill can be turned into a mine
	ElementalStatus = 17, -- Causes elemental status effects, but doesn't hit (used on Herald of Ash to allow Elemental Proliferation to apply)
	MinionsCanExplode = 18,
	Chains = 19,
	Melee = 20,
	MeleeSingleTarget = 21,
	Multicastable = 22, -- Spell can repeat via Spell Echo
	TotemCastsAlone = 23,
	Multistrikeable = 24, -- Attack can repeat via Multistrike
	CausesBurning = 25, -- Deals burning damage
	SummonsTotem = 26,
	TotemCastsWhenNotDetached = 27,
	Physical = 28,
	Fire = 29,
	Cold = 30,
	Lightning = 31,
	Triggerable = 32,
	Trapped = 33,
	Movement = 34,
	DamageOverTime = 35,
	RemoteMined = 36,
	Triggered = 37,
	Vaal = 38,
	Aura = 39,
	CanTargetUnusableCorpse = 40, -- Doesn't appear to be used at all
	RangedAttack = 41,
	Chaos = 42,
	FixedSpeedProjectile = 43, -- Not used by any skill
	ThresholdJewelArea = 44, -- Allows Burning Arrow and Vigilant Strike to be supported by Inc AoE and Conc Effect
	ThresholdJewelProjectile = 45,
	ThresholdJewelDuration = 46, -- Allows Burning Arrow to be supported by Inc/Less Duration and Rapid Decay
	ThresholdJewelRangedAttack = 47,
	Channel = 48,
	DegenOnlySpellDamage = 49, -- Allows Contagion, Blight and Scorching Ray to be supported by Controlled Destruction
	InbuiltTrigger = 50, -- Skill granted by item that is automatically triggered, prevents trigger gems and trap/mine/totem from applying
	Golem = 51,
	Herald = 52,
	AuraAffectsEnemies = 53, -- Used by Death Aura, added by Blasphemy
	NoRuthless = 54,
	ThresholdJewelSpellDamage = 55,
	Cascadable = 56, -- Spell can cascade via Spell Cascade
	ProjectilesFromUser = 57, -- Skill can be supported by Volley
	MirageArcherCanUse = 58, -- Skill can be supported by Mirage Archer
	ProjectileSpiral = 59, -- Excludes Volley from Vaal Fireball and Vaal Spark
	SingleMainProjectile = 60, -- Excludes Volley from Spectral Shield Throw
	MinionsPersistWhenSkillRemoved = 61, -- Excludes Summon Phantasm on Kill from Manifest Dancing Dervish
	ProjectileNumber = 62, -- Allows LMP/GMP on Rain of Arrows and Toxic Rain
	Warcry = 63, -- Warcry
	Instant = 64, -- Instant cast skill
	Brand = 65,
	DestroysCorpse = 66, -- Consumes corpses on use
	NonHitChill = 67,
	ChillingArea = 68,
	AppliesCurse = 69,
	CanRapidFire = 70,
	AuraDuration = 71,
	AreaSpell = 72,
	OR = 73,
	AND = 74,
	NOT = 75,
	AppliesMaim = 76,
	CreatesMinion = 77,
	Guard = 78,
	Travel = 79,
	Blink = 80,
	CanHaveBlessing = 81,
	ProjectilesNotFromUser = 82,
	AttackInPlaceIsDefault = 83,
	Nova = 84,
	InstantNoRepeatWhenHeld = 85,
	InstantShiftAttackForLeftMouse = 86,
	AuraNotOnCaster = 87,
	Banner = 88,
	Rain = 89,
	Cooldown = 90,
	ThresholdJewelChaining= 91,
	Slam = 92,
	Stance = 93,
	NonRepeatable = 94, -- Blood and Sand + Flesh and Stone
	OtherThingUsesSkill = 95,
	Steel = 96,
	Hex = 97,
	Mark = 98,
	Aegis = 99,
	Orb = 100,
	KillNoDamageModifiers = 101,
	RandomElement = 102, -- means elements cannot repeat
	LateConsumeCooldown = 103,
	Arcane = 104, -- means it is reliant on amount of mana spent
	FixedCastTime = 105,
	RequiresOffHandNotWeapon = 106,
	Link = 107,
	Blessing = 108,
	ZeroReservation = 109,
	DynamicCooldown = 110,
	Microtransaction = 111,
	OwnerCannotUse = 112,
	ProjectilesNumberModifiersNotApplied = 113,
	TotemsAreBallistae = 114,
	SkillGrantedBySupport = 115,
	PreventHexTransfer = 116,
	MinionsAreUndamagable = 117,
	InnateTrauma = 118,
	DualWieldRequiresDifferentTypes = 119,
	NoVolley = 120,
	Retaliation = 121,
	NeverExertable = 122,
	DisallowTriggerSupports = 123,
	ProjectileCannotReturn = 124,
	Offering = 125,
	SupportedByBane = 126,
	WandAttack = 127,
	GainsIntensity = 128,
	CreatesSentinelMinion = 129,
	SupportedByAutoExertion = 130,
	SupportedByCrabTotem = 131,
	SupportedBySpellTotem = 132,
	CreatesCorpse = 133,
	RequiresStaff = 134,
	Pact = 135,
}

GlobalCache = {
	cachedData = { MAIN = {}, CALCS = {}, CALCULATOR = {} },
}

