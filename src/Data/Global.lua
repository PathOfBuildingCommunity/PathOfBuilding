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
---@param keywordFlags number The KeywordFlags to be compared to.
---@param modKeywordFlags number The KeywordFlags stored in the mod.
---@return boolean Whether the KeywordFlags in the mod are satisfied.
function MatchKeywordFlags(keywordFlags, modKeywordFlags)
	local matchAll = band(modKeywordFlags, KeywordFlag.MatchAll) ~= 0
	modKeywordFlags = band(modKeywordFlags, MatchAllMask)
	keywordFlags = band(keywordFlags, MatchAllMask)
	if matchAll then
		return band(keywordFlags, modKeywordFlags) == modKeywordFlags
	end
	return modKeywordFlags == 0 or band(keywordFlags, modKeywordFlags) ~= 0
end

-- Active skill types, used in ActiveSkills.dat and GrantedEffects.dat
-- Names taken from ActiveSkillType.dat as of PoE 3.17
SkillType = {
	Attack = 1,
	Spell = 2,
	Projectile = 3, -- Specifically skills which fire projectiles
	DualWieldOnly = 4, -- Attack requires dual wielding, only used on Dual Strike
	Buff = 5,
	Removed6 = 6, -- Now removed, was CanDualWield: Attack can be used while dual wielding
	MainHandOnly = 7, -- Attack only uses the main hand; removed in 3.5 but still needed for 2.6
	Removed8 = 8, -- Now removed, was only used on Cleave
	Minion = 9,
	Damage = 10, -- Skill hits (not used on attacks because all of them hit)
	Area = 11,
	Duration = 12,
	RequiresShield = 13,
	ProjectileSpeed = 14,
	HasReservation = 15,
	ReservationBecomesCost = 16,
	Trappable = 17, -- Skill can be turned into a trap
	Totemable = 18, -- Skill can be turned into a totem
	Mineable = 19, -- Skill can be turned into a mine
	ElementalStatus = 20, -- Causes elemental status effects, but doesn't hit (used on Herald of Ash to allow Elemental Proliferation to apply)
	MinionsCanExplode = 21,
	Removed22 = 22, -- Now removed, was AttackCanTotem
	Chains = 23,
	Melee = 24,
	MeleeSingleTarget = 25,
	Multicastable = 26, -- Spell can repeat via Spell Echo
	TotemCastsAlone = 27,
	Multistrikeable = 28, -- Attack can repeat via Multistrike
	CausesBurning = 29, -- Deals burning damage
	SummonsTotem = 30,
	TotemCastsWhenNotDetached = 31,
	Fire = 32,
	Cold = 33,
	Lightning = 34,
	Triggerable = 35,
	Trapped = 36,
	Movement = 37,
	Removed39 = 38, -- Now removed, was Cast
	DamageOverTime = 39,
	RemoteMined = 40,
	Triggered = 41,
	Vaal = 42,
	Aura = 43,
	Removed45 = 44, -- Now removed, was LightningSpell
	CanTargetUnusableCorpse = 45, -- Doesn't appear to be used at all
	Removed47 = 46, -- Now removed, was TriggeredAttack
	RangedAttack = 47,
	Removed49 = 48, -- Now removed, was MinionSpell
	Chaos = 49,
	FixedSpeedProjectile = 50, -- Not used by any skill
	Removed52 = 51,
	ThresholdJewelArea = 52, -- Allows Burning Arrow and Vigilant Strike to be supported by Inc AoE and Conc Effect
	ThresholdJewelProjectile = 53,
	ThresholdJewelDuration = 54, -- Allows Burning Arrow to be supported by Inc/Less Duration and Rapid Decay
	ThresholdJewelRangedAttack = 55,
	Removed57 = 56,
	Channel = 57,
	DegenOnlySpellDamage = 58, -- Allows Contagion, Blight and Scorching Ray to be supported by Controlled Destruction
	Removed60 = 59, -- Now removed, was ColdSpell
	InbuiltTrigger = 60, -- Skill granted by item that is automatically triggered, prevents trigger gems and trap/mine/totem from applying
	Golem = 61,
	Herald = 62,
	AuraAffectsEnemies = 63, -- Used by Death Aura, added by Blasphemy
	NoRuthless = 64,
	ThresholdJewelSpellDamage = 65,
	Cascadable = 66, -- Spell can cascade via Spell Cascade
	ProjectilesFromUser = 67, -- Skill can be supported by Volley
	MirageArcherCanUse = 68, -- Skill can be supported by Mirage Archer
	ProjectileSpiral = 69, -- Excludes Volley from Vaal Fireball and Vaal Spark
	SingleMainProjectile = 70, -- Excludes Volley from Spectral Shield Throw
	MinionsPersistWhenSkillRemoved = 71, -- Excludes Summon Phantasm on Kill from Manifest Dancing Dervish
	ProjectileNumber = 72, -- Allows LMP/GMP on Rain of Arrows and Toxic Rain
	Warcry = 73, -- Warcry
	Instant = 74, -- Instant cast skill
	Brand = 75,
	DestroysCorpse = 76, -- Consumes corpses on use
	NonHitChill = 77,
	ChillingArea = 78,
	AppliesCurse = 79,
	CanRapidFire = 80,
	AuraDuration = 81,
	AreaSpell = 82,
	OR = 83,
	AND = 84,
	NOT = 85,
	Physical = 86,
	AppliesMaim = 87,
	CreatesMinion = 88,
	Guard = 89,
	Travel = 90,
	Blink = 91,
	CanHaveBlessing = 92,
	ProjectilesNotFromUser = 93,
	AttackInPlaceIsDefault = 94,
	Nova = 95,
	InstantNoRepeatWhenHeld = 96,
	InstantShiftAttackForLeftMouse = 97,
	AuraNotOnCaster = 98,
	Banner = 99,
	Rain = 100,
	Cooldown = 101,
	ThresholdJewelChaining= 102,
	Slam = 103,
	Stance = 104,
	NonRepeatable = 105, -- Blood and Sand + Flesh and Stone
	OtherThingUsesSkill = 106,
	Steel = 107,
	Hex = 108,
	Mark = 109,
	Aegis = 110,
	Orb = 111,
	KillNoDamageModifiers = 112,
	RandomElement = 113, -- means elements cannot repeat
	LateConsumeCooldown = 114,
	Arcane = 115, -- means it is reliant on amount of mana spent
	FixedCastTime = 116,
	RequiresOffHandNotWeapon = 117,
	Link = 118,
	Blessing = 119,
	ZeroReservation = 120,
	DynamicCooldown = 121,
	Microtransaction = 122,
	OwnerCannotUse = 123,
	ProjectilesNotFired = 124,
	TotemsAreBallistae = 125,
	SkillGrantedBySupport = 126,
	PreventHexTransfer = 127,
	MinionsAreUndamageable = 128,
	InnateTrauma = 129,
	DualWieldRequiresDifferentTypes = 130,
	NoVolley = 131,
	SacredWispsCanUse = 132, -- Skill can be supported by Sacred Wisps
}

GlobalCache = { 
	cachedData = { MAIN = {}, CALCS = {}, CALCULATOR = {}, CACHE = {}, },
	deleteGroup = { },
	excludeFullDpsList = { },
	noCache = nil,
	useFullDPS = false,
	numActiveSkillInFullDPS = 0,
}

