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
}
colorCodes.STRENGTH = colorCodes.MARAUDER
colorCodes.DEXTERITY = colorCodes.RANGER
colorCodes.INTELLIGENCE = colorCodes.WITCH

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
-- Weapon classes
ModFlag.WeaponMelee =0x02000000
ModFlag.WeaponRanged=0x04000000
ModFlag.Weapon1H =	 0x08000000
ModFlag.Weapon2H =	 0x10000000
ModFlag.WeaponMask = 0x1FFF0000

KeywordFlag = { }
-- Skill keywords
KeywordFlag.Aura =		0x00000001
KeywordFlag.Curse =		0x00000002
KeywordFlag.Warcry =	0x00000004
KeywordFlag.Movement =	0x00000008
KeywordFlag.Fire =		0x00000010
KeywordFlag.Cold =		0x00000020
KeywordFlag.Lightning =	0x00000040
KeywordFlag.Chaos =		0x00000080
KeywordFlag.Vaal =		0x00000100
KeywordFlag.Bow =		0x00000200
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
---@return boolean Whether the KeywordFlags in the mod are satified.
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
-- Had to reverse engineer this, not sure what all of the values mean
SkillType = {
	Attack = 1,
	Spell = 2,
	Projectile = 3, -- Specifically skills which fire projectiles
	DualWield = 4, -- Attack requires dual wielding, only used on Dual Strike
	Buff = 5,
	Removed6 = 6, -- Now removed, was CanDualWield: Attack can be used while dual wielding
	MainHandOnly = 7, -- Attack only uses the main hand; removed in 3.5 but still needed for 2.6
	Removed8 = 8, -- Now removed, was only used on Cleave
	Minion = 9,
	Hit = 10, -- Skill hits (not used on attacks because all of them hit)
	Area = 11,
	Duration = 12,
	Shield = 13, -- Skill requires a shield
	ProjectileDamage = 14, -- Skill deals projectile damage but doesn't fire projectiles
	ManaCostReserved = 15, -- The skill's mana cost is a reservation
	ManaCostPercent = 16, -- The skill's mana cost is a percentage
	SkillCanTrap = 17, -- Skill can be turned into a trap
	SkillCanTotem = 18, -- Skill can be turned into a totem
	SkillCanMine = 19, -- Skill can be turned into a mine
	CauseElementalStatus = 20, -- Causes elemental status effects, but doesn't hit (used on Herald of Ash to allow Elemental Proliferation to apply)
	CreateMinion = 21, -- Creates or summons minions
	Removed22 = 22, -- Now removed, was AttackCanTotem
	Chaining = 23,
	Melee = 24,
	MeleeSingleTarget = 25,
	SpellCanRepeat = 26, -- Spell can repeat via Spell Echo
	Type27 = 27, -- No idea, used on auras and certain damage skills
	AttackCanRepeat = 28, -- Attack can repeat via Multistrike
	CausesBurning = 29, -- Deals burning damage
	Totem = 30,
	DamageCannotBeReflected = 31,
	--Curse = 32,
	FireSkill = 32,
	ColdSkill = 33,
	LightningSkill = 34,
	Triggerable = 35,
	Trap = 36,
	MovementSkill = 37,
	Removed39 = 38, -- Now removed, was Cast
	DamageOverTime = 39,
	Mine = 40,
	Triggered = 41,
	Vaal = 42,
	Aura = 43,
	Removed45 = 44, -- Now removed, was LightningSpell
	Type46 = 45, -- Doesn't appear to be used at all
	Removed47 = 46, -- Now removed, was TriggeredAttack
	ProjectileAttack = 47,
	Removed49 = 48, -- Now removed, was MinionSpell
	ChaosSkill = 49,
	Type51 = 50, -- Not used by any skill
	Removed52 = 51,
	Type53 = 52, -- Allows Burning Arrow and Vigilant Strike to be supported by Inc AoE and Conc Effect
	MinionProjectile = 53,
	Type55 = 54, -- Allows Burning Arrow to be supported by Inc/Less Duration and Rapid Decay
	AnimateWeapon = 55,
	Removed57 = 56,
	Channelled = 57,
	Type59 = 58, -- Allows Contagion, Blight and Scorching Ray to be supported by Controlled Destruction
	Removed60 = 59, -- Now removed, was ColdSpell
	TriggeredGrantedSkill = 60, -- Skill granted by item that is automatically triggered, prevents trigger gems and trap/mine/totem from applying
	Golem = 61,
	Herald = 62,
	AuraDebuff = 63, -- Used by Death Aura, added by Blasphemy
	Type65 = 64, -- Excludes Ruthless from Cyclone
	Type66 = 65, -- Allows Iron Will
	SpellCanCascade = 66, -- Spell can cascade via Spell Cascade
	SkillCanVolley = 67, -- Skill can be supported by Volley
	SkillCanMirageArcher = 68, -- Skill can be supported by Mirage Archer
	LaunchesSeriesOfProjectiles = 69, -- Excludes Volley from Vaal Fireball and Vaal Spark
	Type71 = 70, -- Excludes Volley from Spectral Shield Throw
	Type72 = 71, -- Excludes Summon Phantasm on Kill from Manifest Dancing Dervish
	Type73 = 72, -- Allows LMP/GMP on Rain of Arrows and Toxic Rain
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
	PhysicalSkill = 86,
	Maims = 87,
	CreatesMinion = 88,
	GuardSkill = 89,
	TravelSkill = 90,
	BlinkSkill = 91,
	CanHaveBlessing = 92,
	FiresProjectilesFromSecondaryLocation = 93,
	Ballista = 94,
	NovaSpell = 95,
	Type91 = 96,
	Type92 = 97,
	CanDetonate = 98,
	Banner = 99,
	FiresArrowsAtTargetLocation = 100,
	SecondWindSupport = 101,
	Type97= 102,
	CantUseFistOfWar = 103,
	SlamSkill = 104,
	StanceSkill = 105, -- Bload and Sand + Flesh and Stone
	CreatesMirageWarrior = 106,
	UsesSupportedTriggerSkill = 107,
	SteelSkill = 108,
	Hex = 109,
	Mark = 110,
	Aegis = 111,
	Orb = 112,
}

GlobalCache = { 
	--cachedData = { MAIN = {}, CALCS = {}, CALCULATOR = {}, },
	cachedData = { },
	minionSkills = { },
	excludeFullDpsList = { },
	dontUseCache = nil,
}
