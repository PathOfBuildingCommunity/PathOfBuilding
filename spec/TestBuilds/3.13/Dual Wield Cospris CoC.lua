return {
   xml = [[<?xml version="1.0" encoding="UTF-8"?>
<PathOfBuilding>
	<Build level="100" targetVersion="3_0" pantheonMajorGod="None" bandit="None" className="Ranger" ascendClassName="Raider" mainSocketGroup="5" viewMode="TREE" pantheonMinorGod="None">
		<PlayerStat stat="AverageHit" value="371187.5112"/>
		<PlayerStat stat="AverageDamage" value="371187.5112"/>
		<PlayerStat stat="Speed" value="3.5814285714286"/>
		<PlayerStat stat="Speed" value="3.5814285714286"/>
		<PlayerStat stat="Speed" value="3.5814285714286"/>
		<PlayerStat stat="PreEffectiveCritChance" value="100"/>
		<PlayerStat stat="CritChance" value="100"/>
		<PlayerStat stat="CritMultiplier" value="6.08"/>
		<PlayerStat stat="HitChance" value="100"/>
		<PlayerStat stat="TotalDPS" value="14623197.137661"/>
		<PlayerStat stat="TotalDot" value="0"/>
		<PlayerStat stat="WithBleedDPS" value="14623197.137661"/>
		<PlayerStat stat="WithIgniteDPS" value="14623197.137661"/>
		<PlayerStat stat="WithPoisonDPS" value="14623197.137661"/>
		<PlayerStat stat="TotalDotDPS" value="0"/>
		<PlayerStat stat="CombinedDPS" value="16247996.819623"/>
		<PlayerStat stat="CombinedAvg" value="14623197.137661"/>
		<PlayerStat stat="Cooldown" value="0.13333333333333"/>
		<PlayerStat stat="ManaCost" value="45"/>
		<PlayerStat stat="Str" value="116"/>
		<PlayerStat stat="ReqStr" value="114"/>
		<PlayerStat stat="Dex" value="247"/>
		<PlayerStat stat="ReqDex" value="212"/>
		<PlayerStat stat="Int" value="381"/>
		<PlayerStat stat="ReqInt" value="257"/>
		<PlayerStat stat="Devotion" value="0"/>
		<PlayerStat stat="Life" value="1348"/>
		<PlayerStat stat="Spec:LifeInc" value="0"/>
		<PlayerStat stat="LifeUnreserved" value="256"/>
		<PlayerStat stat="LifeUnreservedPercent" value="18.991097922849"/>
		<PlayerStat stat="LifeRegen" value="1.348"/>
		<PlayerStat stat="LifeLeechGainRate" value="269.6"/>
		<PlayerStat stat="Mana" value="946"/>
		<PlayerStat stat="Spec:ManaInc" value="8"/>
		<PlayerStat stat="ManaUnreserved" value="66"/>
		<PlayerStat stat="ManaUnreservedPercent" value="6.9767441860465"/>
		<PlayerStat stat="ManaRegen" value="39.6"/>
		<PlayerStat stat="ManaLeechGainRate" value="0"/>
		<PlayerStat stat="EnergyShield" value="5731"/>
		<PlayerStat stat="Spec:EnergyShieldInc" value="125"/>
		<PlayerStat stat="EnergyShieldRegen" value="0"/>
		<PlayerStat stat="EnergyShieldLeechGainRate" value="286.55"/>
		<PlayerStat stat="Evasion" value="1048"/>
		<PlayerStat stat="Spec:EvasionInc" value="148"/>
		<PlayerStat stat="MeleeEvadeChance" value="1.35"/>
		<PlayerStat stat="MeleeEvadeChance" value="1.35"/>
		<PlayerStat stat="ProjectileEvadeChance" value="1.35"/>
		<PlayerStat stat="Armour" value="164"/>
		<PlayerStat stat="Spec:ArmourInc" value="0"/>
		<PlayerStat stat="PhysicalDamageReduction" value="1"/>
		<PlayerStat stat="EffectiveMovementSpeedMod" value="3.9131"/>
		<PlayerStat stat="BlockChance" value="15"/>
		<PlayerStat stat="SpellBlockChance" value="0"/>
		<PlayerStat stat="AttackDodgeChance" value="25"/>
		<PlayerStat stat="SpellDodgeChance" value="25"/>
		<PlayerStat stat="FireResist" value="75"/>
		<PlayerStat stat="FireResistOverCap" value="70"/>
		<PlayerStat stat="ColdResist" value="75"/>
		<PlayerStat stat="ColdResistOverCap" value="17"/>
		<PlayerStat stat="LightningResist" value="76"/>
		<PlayerStat stat="LightningResistOverCap" value="22"/>
		<PlayerStat stat="ChaosResist" value="-25"/>
		<PlayerStat stat="ChaosResistOverCap" value="0"/>
		<PlayerStat stat="PowerCharges" value="6"/>
		<PlayerStat stat="PowerChargesMax" value="6"/>
		<PlayerStat stat="FrenzyCharges" value="6"/>
		<PlayerStat stat="FrenzyChargesMax" value="6"/>
		<PlayerStat stat="EnduranceCharges" value="0"/>
		<PlayerStat stat="EnduranceChargesMax" value="3"/>
	</Build>
	<Import lastAccountHash="dc7b95d5105da6507bc56287f0ff95348a3c2c5b" lastRealm="PC" lastCharacterHash="fa9c9747161fdbf2a53b12efee46effa591681f6"/>
	<Calcs>
		<Input name="showMinion" boolean="true"/>
		<Input name="skill_number" number="5"/>
		<Input name="misc_buffMode" string="EFFECTIVE"/>
		<Section collapsed="false" id="SkillSelect"/>
		<Section collapsed="false" id="HitDamage"/>
		<Section collapsed="false" id="Warcries"/>
		<Section collapsed="false" id="Dot"/>
		<Section collapsed="false" id="Speed"/>
		<Section collapsed="false" id="Crit"/>
		<Section collapsed="false" id="Impale"/>
		<Section collapsed="false" id="SkillTypeStats"/>
		<Section collapsed="false" id="HitChance"/>
		<Section collapsed="false" id="Bleed"/>
		<Section collapsed="false" id="Poison"/>
		<Section collapsed="false" id="Ignite"/>
		<Section collapsed="false" id="Decay"/>
		<Section collapsed="false" id="LeechGain"/>
		<Section collapsed="false" id="EleAilments"/>
		<Section collapsed="false" id="MiscEffects"/>
		<Section collapsed="false" id="Attributes"/>
		<Section collapsed="false" id="Life"/>
		<Section collapsed="false" id="Mana"/>
		<Section collapsed="false" id="EnergyShield"/>
		<Section collapsed="false" id="Armour"/>
		<Section collapsed="false" id="Evasion"/>
		<Section collapsed="false" id="Resist"/>
		<Section collapsed="false" id="Block"/>
		<Section collapsed="false" id="MiscDefences"/>
		<Section collapsed="false" id="DamageTaken"/>
	</Calcs>
	<Skills sortGemsByDPSField="CombinedDPS" sortGemsByDPS="true" defaultGemQuality="20" defaultGemLevel="20" showSupportGemTypes="ALL" showAltQualityGems="true">
		<Skill mainActiveSkillCalcs="1" label="" enabled="true" slot="Boots" mainActiveSkill="3">
			<Gem enableGlobal2="false" level="21" gemId="Metadata/Items/Gems/SkillGemHatred" skillId="Hatred" enableGlobal1="true" qualityId="Default" quality="0" enabled="true" nameSpec="Hatred"/>
			<Gem enableGlobal2="false" level="21" gemId="Metadata/Items/Gems/SkillGemHeraldOfIce" skillId="HeraldOfIce" enableGlobal1="true" qualityId="Default" quality="23" enabled="true" nameSpec="Herald of Ice" skillMinion="SummonedPhantasm"/>
			<Gem enableGlobal2="false" level="21" gemId="Metadata/Items/Gems/SkillGemSpellDamageAura" skillId="SpellDamageAura" enableGlobal1="true" qualityId="Alternate1" quality="20" enabled="true" nameSpec="Zealotry"/>
			<Gem enableGlobal2="false" level="4" gemId="Metadata/Items/Gems/SupportGemAdditionalXP" skillId="SupportAdditionalXP" enableGlobal1="true" qualityId="Default" quality="10" enabled="true" nameSpec="Enlighten"/>
		</Skill>
		<Skill mainActiveSkillCalcs="1" label="" enabled="true" slot="Helmet" mainActiveSkill="1">
			<Gem enableGlobal2="false" level="20" gemId="Metadata/Items/Gems/SkillGemDash" skillId="QuickDodge" enableGlobal1="true" qualityId="Alternate1" quality="20" enabled="true" nameSpec="Dash"/>
			<Gem enableGlobal2="false" level="20" gemId="Metadata/Items/Gems/SupportGemSecondWind" skillId="SupportAdditionalCooldown" enableGlobal1="true" qualityId="Alternate1" quality="20" enabled="true" nameSpec="Second Wind"/>
			<Gem enableGlobal2="false" level="6" gemId="Metadata/Items/Gems/SupportGemArcaneSurge" skillId="SupportArcaneSurge" enableGlobal1="true" qualityId="Alternate2" quality="20" enabled="true" nameSpec="Arcane Surge"/>
		</Skill>
		<Skill mainActiveSkillCalcs="1" label="" enabled="true" slot="Helmet" mainActiveSkill="1">
			<Gem enableGlobal2="false" skillMinionSkillCalcs="2" skillMinionCalcs="SummonedIceGolem" level="21" gemId="Metadata/Items/Gems/SkillGemSummonIceGolem" skillId="SummonIceGolem" skillMinionSkill="3" enableGlobal1="true" qualityId="Alternate1" quality="20" enabled="true" nameSpec="Summon Ice Golem" skillMinion="SummonedIceGolem"/>
		</Skill>
		<Skill mainActiveSkillCalcs="2" label="" enabled="true" slot="Weapon 1" mainActiveSkill="2">
			<Gem enableGlobal2="false" level="19" gemId="Metadata/Items/Gems/SkillGemFrostBomb" skillId="FrostBomb" enableGlobal1="true" qualityId="Alternate2" quality="20" enabled="true" nameSpec="Frost Bomb" skillMinion="SummonedPhantasm"/>
			<Gem enableGlobal2="false" level="21" gemId="Metadata/Items/Gems/SkillGemIceSpear" skillId="IceSpear" skillPart="4" enableGlobal1="true" qualityId="Default" quality="23" skillPartCalcs="4" enabled="true" nameSpec="Ice Spear" skillMinion="SummonedPhantasm"/>
			<Gem enableGlobal2="false" level="21" gemId="Metadata/Items/Gems/SkillGemFrostbite" skillId="Frostbite" enableGlobal1="true" qualityId="Default" quality="23" enabled="true" nameSpec="Frostbite"/>
		</Skill>
		<Skill mainActiveSkillCalcs="3" label="" enabled="true" slot="Body Armour" mainActiveSkill="3">
			<Gem enableGlobal2="false" skillStageCountCalcs="7" skillStageCount="7" level="21" gemId="Metadata/Items/Gems/SkillGemCyclone" skillId="Cyclone" skillPart="1" enableGlobal1="true" qualityId="Alternate2" quality="20" enabled="true" nameSpec="Cyclone" skillMinion="SummonedPhantasm"/>
			<Gem enableGlobal2="false" level="6" gemId="Metadata/Items/Gems/SupportGemCastOnCritPlus" skillId="SupportCastOnCritPlus" enableGlobal1="true" qualityId="Default" quality="20" enabled="true" nameSpec="Awakened Cast On Critical Strike"/>
			<Gem enableGlobal2="false" level="5" gemId="Metadata/Items/Gems/SupportGemGreaterMultipleProjectilesPlus" skillId="SupportGreaterMultipleProjectilesPlus" enableGlobal1="true" qualityId="Default" quality="20" enabled="true" nameSpec="Awakened Greater Multiple Projectiles"/>
			<Gem enableGlobal2="false" level="21" gemId="Metadata/Items/Gems/SkillGemFreezingPulse" skillId="FreezingPulse" enableGlobal1="true" qualityId="Default" quality="20" enabled="true" nameSpec="Freezing Pulse" skillMinion="SummonedPhantasm"/>
			<Gem enableGlobal2="false" level="21" gemId="Metadata/Items/Gems/SupportGemPowerChargeOnCrit" skillId="SupportPowerChargeOnCrit" skillPart="1" enableGlobal1="true" qualityId="Alternate2" quality="20" enabled="true" nameSpec="Power Charge On Critical" skillMinion="SkitterbotCold"/>
			<Gem enableGlobal2="false" level="21" gemId="Metadata/Items/Gems/SkillGemIceSpear" skillId="IceSpear" skillPart="4" enableGlobal1="true" qualityId="Default" quality="23" skillPartCalcs="4" enabled="true" nameSpec="Ice Spear" skillMinion="SummonedPhantasm"/>
		</Skill>
		<Skill mainActiveSkillCalcs="1" label="" enabled="true" slot="Weapon 2" mainActiveSkill="1">
			<Gem enableGlobal2="false" level="21" gemId="Metadata/Items/Gems/SkillGemIceSpear" skillId="IceSpear" skillPart="4" enableGlobal1="true" qualityId="Default" quality="23" skillPartCalcs="4" enabled="true" nameSpec="Ice Spear" skillMinion="SummonedPhantasm"/>
			<Gem enableGlobal2="false" level="5" gemId="Metadata/Items/Gems/SupportGemGreaterMultipleProjectilesPlus" skillId="SupportGreaterMultipleProjectilesPlus" enableGlobal1="true" qualityId="Default" quality="20" enabled="true" nameSpec="Awakened Greater Multiple Projectiles"/>
			<Gem enableGlobal2="false" level="6" gemId="Metadata/Items/Gems/SupportGemControlledDestructionPlus" skillId="SupportControlledDestructionPlus" skillPart="1" enableGlobal1="true" qualityId="Default" quality="20" enabled="true" nameSpec="Awakened Controlled Destruction" skillMinion="SkitterbotCold"/>
		</Skill>
		<Skill mainActiveSkillCalcs="1" label="" enabled="true" slot="Gloves" mainActiveSkill="4">
			<Gem enableGlobal2="false" level="21" gemId="Metadata/Items/Gems/SkillGemVaalRighteousFire" skillId="VaalRighteousFire" enableGlobal1="true" qualityId="Default" quality="0" enabled="true" nameSpec="Vaal Righteous Fire"/>
			<Gem enableGlobal2="false" level="20" gemId="Metadata/Items/Gems/SkillGemPrecision" skillId="AccuracyAndCritsAura" enableGlobal1="true" qualityId="Alternate1" quality="20" enabled="true" nameSpec="Precision"/>
			<Gem enableGlobal2="false" level="21" gemId="Metadata/Items/Gems/SupportGemBloodMagic" skillId="SupportBloodMagic" enableGlobal1="true" qualityId="Default" quality="8" enabled="true" nameSpec="Blood Magic"/>
			<Gem enableGlobal2="true" level="21" gemId="Metadata/Items/Gems/SkillGemVaalDiscipline" skillId="VaalDiscipline" enableGlobal1="true" qualityId="Default" quality="0" enabled="true" nameSpec="Vaal Discipline"/>
		</Skill>
		<Skill source="Item:26:Agony Touch, Fingerless Silk Gloves" mainActiveSkillCalcs="1" label="" enabled="true" slot="Gloves" mainActiveSkill="1">
			<Gem enableGlobal2="false" level="1" skillId="EnchantmentOfFrostOnKill4" enableGlobal1="true" qualityId="Default" quality="0" enabled="true" nameSpec="Commandment of Frost"/>
		</Skill>
		<Skill source="Item:14:Dread Knuckle, Moonstone Ring" mainActiveSkillCalcs="1" label="" enabled="true" slot="Ring 1" mainActiveSkill="1">
			<Gem enableGlobal2="false" level="12" gemId="Metadata/Items/Gems/SkillGemCriticalWeakness" skillId="AssassinsMark" enableGlobal1="true" qualityId="Default" quality="0" enabled="true" nameSpec="Assassin&apos;s Mark"/>
		</Skill>
	</Skills>
	<Tree activeSpec="1">
		<Spec ascendClassId="1" nodes="39841,64583,3537,20987,5926,12613,41635,63447,58244,42795,31703,35851,22618,61320,33989,12143,11597,61419,41263,65574,8001,35894,56158,16954,51923,2311,55247,29712,32710,65893,65575,12783,3452,22535,65552,59370,66576,20528,28754,13170,4849,65568,25411,7112,65894,24050,15117,60592,49651,4367,37671,28859,65561,52502,9408,53421,8833,50338,5823,6250,12888,65872,8135,49605,28012,7960,9797,4036,19501,20546,16848,65888,45035,65570,35283,65578,58427,47484,65555,18865,50459,66579,46092,21033,44184,53213,66585,27929,5296,47306,42649,39861,23690,23659,27536,61834,32176,65874,13885,15228,48778,9355,55571,11018,23950,65882,14674,63795,50029,36678,31364,38995,63799,65890,33864,4011,12146,60440,38662,10763,9261,65898,49978,21301,21984,6538,60090,8012,33310,55114" treeVersion="3_13" classId="2">
			<EditedNodes>
				<EditedNode editorSeed="3094" icon="Art/2DArt/SkillIcons/passives/VaalNotableDefensive.dds" nodeName="Ritual of Flesh" nodeId="11420">
					8% increased maximum Life
					Regenerate 1% of Life per second
				</EditedNode>
				<EditedNode editorSeed="3094" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Life" nodeId="60398">
					3% increased maximum Life
				</EditedNode>
				<EditedNode editorSeed="160000" icon="Art/2DArt/SkillIcons/passives/EternalEmpireOffensiveNotable.dds" nodeName="Eternal Resilience" nodeId="11420">
					Gain 1 Endurance Charge every second if you&apos;ve been Hit Recently
				</EditedNode>
				<EditedNode editorSeed="10468" nodeId="48438">
					24% increased Evasion Rating and Armour
					8% increased maximum Life
					10% chance to Intimidate Enemies for 4 seconds on Hit
				</EditedNode>
				<EditedNode editorSeed="5841" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Cast Speed" nodeId="7388">
					2% increased Cast Speed
				</EditedNode>
				<EditedNode editorSeed="5841" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Mana" nodeId="36542">
					4% increased maximum Mana
				</EditedNode>
				<EditedNode editorSeed="5841" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Skill Duration" nodeId="57264">
					4% increased Skill Effect Duration
				</EditedNode>
				<EditedNode editorSeed="5841" icon="Art/2DArt/SkillIcons/passives/VaalNotableDefensive.dds" nodeName="Cult of Fire" nodeId="11420">
					+1% to maximum Fire Resistance
					+20% to Fire Resistance
				</EditedNode>
				<EditedNode editorSeed="5841" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Energy Shield" nodeId="37569">
					3% increased maximum Energy Shield
				</EditedNode>
				<EditedNode editorSeed="5841" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Cold Resistance" nodeId="4397">
					+10% to Cold Resistance
				</EditedNode>
				<EditedNode editorSeed="5841" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Area of Effect" nodeId="60398">
					5% increased Area of Effect
				</EditedNode>
				<EditedNode editorSeed="5841" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Life" nodeId="31875">
					2% increased maximum Life
				</EditedNode>
				<EditedNode editorSeed="118400" icon="Art/2DArt/SkillIcons/passives/EternalEmpireOffensiveNotable.dds" nodeName="Slum Lord" nodeId="36949">
					Minions deal 80% increased Damage
				</EditedNode>
				<EditedNode editorSeed="118400" icon="Art/2DArt/SkillIcons/passives/EternalEmpireDefensiveNotable.dds" nodeName="Superiority" nodeId="19103">
					15% increased effect of Non-Curse Auras from your Skills
				</EditedNode>
				<EditedNode editorSeed="6289" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Fire Damage" nodeId="7388">
					12% increased Fire Damage
				</EditedNode>
				<EditedNode editorSeed="6289" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Spell Block" nodeId="36542">
					1% Chance to Block Spell Damage
				</EditedNode>
				<EditedNode editorSeed="6289" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Energy Shield" nodeId="37569">
					5% increased maximum Energy Shield
				</EditedNode>
				<EditedNode editorSeed="6289" icon="Art/2DArt/SkillIcons/passives/VaalNotableDefensive.dds" nodeName="Ritual of Flesh" nodeId="11420">
					10% increased maximum Life
					Regenerate 1.1% of Life per second
				</EditedNode>
				<EditedNode editorSeed="6289" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Fire Resistance" nodeId="47251">
					+11% to Fire Resistance
				</EditedNode>
				<EditedNode editorSeed="6289" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Aura Effect" nodeId="57264">
					3% increased effect of Non-Curse Auras from your Skills
				</EditedNode>
				<EditedNode editorSeed="6289" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Curse Effect" nodeId="4397">
					3% increased Effect of your Curses
				</EditedNode>
				<EditedNode editorSeed="6289" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Evasion" nodeId="60398">
					9% increased Evasion Rating
				</EditedNode>
				<EditedNode editorSeed="6289" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Skill Duration" nodeId="31875">
					5% increased Skill Effect Duration
				</EditedNode>
				<EditedNode editorSeed="6562" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Area Damage" nodeId="7388">
					10% increased Area Damage
				</EditedNode>
				<EditedNode editorSeed="6562" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Mana Regeneration" nodeId="4184">
					12% increased Mana Regeneration Rate
				</EditedNode>
				<EditedNode editorSeed="6562" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Attack Damage" nodeId="17579">
					10% increased Attack Damage
				</EditedNode>
				<EditedNode editorSeed="6562" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Chaos Resistance" nodeId="21934">
					+8% to Chaos Resistance
				</EditedNode>
				<EditedNode editorSeed="6562" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Critical Strike Multiplier" nodeId="18866">
					+9% to Critical Strike Multiplier
				</EditedNode>
				<EditedNode editorSeed="6562" icon="Art/2DArt/SkillIcons/passives/VaalNotableOffensive.dds" nodeName="Ritual of Might" nodeId="11420">
					2% chance to deal Double Damage
					25% increased Physical Damage
				</EditedNode>
				<EditedNode editorSeed="6562" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Life" nodeId="739">
					3% increased maximum Life
				</EditedNode>
				<EditedNode editorSeed="6562" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Movement Speed" nodeId="33783">
					3% increased Movement Speed
				</EditedNode>
				<EditedNode editorSeed="6562" icon="Art/2DArt/SkillIcons/passives/VaalNotableOffensive.dds" nodeName="Might of the Vaal" nodeId="34661">
					3% increased Cast Speed
					11% increased Projectile Damage
					5% chance to Shock
					6% chance to Ignite
				</EditedNode>
				<EditedNode editorSeed="6562" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Spell Damage" nodeId="1957">
					12% increased Spell Damage
				</EditedNode>
				<EditedNode editorSeed="6562" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Attack Dodge" nodeId="37569">
					1% chance to Dodge Attack Hits
				</EditedNode>
				<EditedNode editorSeed="6562" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Projectile Speed" nodeId="31875">
					7% increased Projectile Speed
				</EditedNode>
				<EditedNode editorSeed="6562" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Attack Speed" nodeId="57264">
					3% increased Attack Speed
				</EditedNode>
				<EditedNode editorSeed="6562" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Curse Effect" nodeId="36542">
					5% increased Effect of your Curses
				</EditedNode>
				<EditedNode editorSeed="6562" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Physical Damage" nodeId="33296">
					7% increased Physical Damage
				</EditedNode>
				<EditedNode editorSeed="6562" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Armour" nodeId="4397">
					7% increased Armour
				</EditedNode>
				<EditedNode editorSeed="6562" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Lightning Resistance" nodeId="60398">
					+12% to Lightning Resistance
				</EditedNode>
				<EditedNode editorSeed="6562" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Life" nodeId="36774">
					2% increased maximum Life
				</EditedNode>
				<EditedNode editorSeed="3041" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Fire Damage" nodeId="60398">
					10% increased Fire Damage
				</EditedNode>
				<EditedNode editorSeed="927" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Area Damage" nodeId="7388">
					11% increased Area Damage
				</EditedNode>
				<EditedNode editorSeed="927" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Fire Resistance" nodeId="36542">
					+10% to Fire Resistance
				</EditedNode>
				<EditedNode editorSeed="927" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Area Damage" nodeId="57264">
					7% increased Area Damage
				</EditedNode>
				<EditedNode editorSeed="927" icon="Art/2DArt/SkillIcons/passives/VaalNotableOffensive.dds" nodeName="Might of the Vaal" nodeId="11420">
					7% increased Fire Damage
					6% increased maximum Mana
					+11% to Lightning Resistance
				</EditedNode>
				<EditedNode editorSeed="927" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Critical Strike Multiplier" nodeId="37569">
					+8% to Critical Strike Multiplier
				</EditedNode>
				<EditedNode editorSeed="927" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Critical Strike Chance" nodeId="4397">
					10% increased Critical Strike Chance
				</EditedNode>
				<EditedNode editorSeed="927" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Life" nodeId="60398">
					3% increased maximum Life
				</EditedNode>
				<EditedNode editorSeed="927" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Spell Damage" nodeId="31875">
					7% increased Spell Damage
				</EditedNode>
				<EditedNode editorSeed="408" icon="Art/2DArt/SkillIcons/passives/VaalNotableDefensive.dds" nodeName="Commanding Presence" nodeId="23690">
					20% increased Area of Effect of Aura Skills
					15% increased effect of Non-Curse Auras from your Skills
				</EditedNode>
				<EditedNode editorSeed="408" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Aura Effect" nodeId="48778">
					4% increased effect of Non-Curse Auras from your Skills
				</EditedNode>
				<EditedNode editorSeed="1457" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Critical Strike Multiplier" nodeId="39821">
					+9% to Critical Strike Multiplier
				</EditedNode>
				<EditedNode editorSeed="1457" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Spell Dodge" nodeId="4011">
					1% chance to Dodge Spell Hits
				</EditedNode>
				<EditedNode editorSeed="1457" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Fire Resistance" nodeId="39861">
					+10% to Fire Resistance
				</EditedNode>
				<EditedNode editorSeed="1457" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Critical Strike Multiplier" nodeId="9355">
					+8% to Critical Strike Multiplier
				</EditedNode>
				<EditedNode editorSeed="1457" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Armour" nodeId="49978">
					8% increased Armour
				</EditedNode>
				<EditedNode editorSeed="1457" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Energy Shield" nodeId="38662">
					5% increased maximum Energy Shield
				</EditedNode>
				<EditedNode editorSeed="1457" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Life" nodeId="6538">
					3% increased maximum Life
				</EditedNode>
				<EditedNode editorSeed="1457" icon="Art/2DArt/SkillIcons/passives/VaalNotableOffensive.dds" nodeName="Flesh to Frost" nodeId="50338">
					28% increased Cold Damage
					10% of Physical Damage Converted to Cold Damage
				</EditedNode>
				<EditedNode editorSeed="597" icon="Art/2DArt/SkillIcons/passives/VaalNotableDefensive.dds" nodeName="Flesh Worship" nodeId="11420">
					7% increased maximum Life
					0.4% of Attack Damage Leeched as Life
				</EditedNode>
				<EditedNode editorSeed="597" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Area Damage" nodeId="36542">
					12% increased Area Damage
				</EditedNode>
				<EditedNode editorSeed="597" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Spell Damage" nodeId="57264">
					7% increased Spell Damage
				</EditedNode>
				<EditedNode editorSeed="597" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Critical Strike Multiplier" nodeId="31875">
					+8% to Critical Strike Multiplier
				</EditedNode>
				<EditedNode editorSeed="597" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Fire Resistance" nodeId="37569">
					+14% to Fire Resistance
				</EditedNode>
				<EditedNode editorSeed="597" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Chaos Damage" nodeId="4397">
					8% increased Chaos Damage
				</EditedNode>
				<EditedNode editorSeed="597" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Physical Damage" nodeId="60398">
					12% increased Physical Damage
				</EditedNode>
				<EditedNode editorSeed="597" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Lightning Damage" nodeId="7388">
					10% increased Lightning Damage
				</EditedNode>
				<EditedNode editorSeed="4104" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Life" nodeId="15405">
					3% increased maximum Life
				</EditedNode>
				<EditedNode editorSeed="4104" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Area of Effect" nodeId="65034">
					5% increased Area of Effect
				</EditedNode>
				<EditedNode editorSeed="4104" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Area of Effect" nodeId="50862">
					6% increased Area of Effect
				</EditedNode>
				<EditedNode editorSeed="147440" icon="Art/2DArt/SkillIcons/passives/EternalEmpireOffensiveNotable.dds" nodeName="Eternal Fervour" nodeId="23690">
					10% chance to gain a Frenzy Charge on Hit
				</EditedNode>
				<EditedNode editorSeed="7003" icon="Art/2DArt/SkillIcons/passives/VaalNotableDefensive.dds" nodeName="Ritual of Flesh" nodeId="11420">
					8% increased maximum Life
					Regenerate 0.7% of Life per second
				</EditedNode>
				<EditedNode editorSeed="7003" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Evasion" nodeId="57264">
					9% increased Evasion Rating
				</EditedNode>
				<EditedNode editorSeed="7003" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Fire Resistance" nodeId="7388">
					+13% to Fire Resistance
				</EditedNode>
				<EditedNode editorSeed="7003" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Fire Resistance" nodeId="37569">
					+11% to Fire Resistance
				</EditedNode>
				<EditedNode editorSeed="7003" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Fire Damage" nodeId="4397">
					11% increased Fire Damage
				</EditedNode>
				<EditedNode editorSeed="7003" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Projectile Speed" nodeId="60398">
					10% increased Projectile Speed
				</EditedNode>
				<EditedNode editorSeed="7003" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Projectile Damage" nodeId="31875">
					7% increased Projectile Damage
				</EditedNode>
				<EditedNode editorSeed="4050" icon="Art/2DArt/SkillIcons/passives/VaalNotableDefensive.dds" nodeName="Commanding Presence" nodeId="23690">
					20% increased Area of Effect of Aura Skills
					15% increased effect of Non-Curse Auras from your Skills
				</EditedNode>
				<EditedNode editorSeed="4050" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Aura Effect" nodeId="48778">
					4% increased effect of Non-Curse Auras from your Skills
				</EditedNode>
				<EditedNode editorSeed="5322" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Aura Effect" nodeId="27659">
					4% increased effect of Non-Curse Auras from your Skills
				</EditedNode>
				<EditedNode editorSeed="5322" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Movement Speed" nodeId="48778">
					3% increased Movement Speed
				</EditedNode>
				<EditedNode editorSeed="5322" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Minion Damage" nodeId="8948">
					Minions deal 12% increased Damage
				</EditedNode>
				<EditedNode editorSeed="5322" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Life" nodeId="21678">
					2% increased maximum Life
				</EditedNode>
				<EditedNode editorSeed="5322" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Lightning Resistance" nodeId="37671">
					+13% to Lightning Resistance
				</EditedNode>
				<EditedNode editorSeed="5322" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Chaos Resistance" nodeId="32210">
					+6% to Chaos Resistance
				</EditedNode>
				<EditedNode editorSeed="5894" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Lightning Resistance" nodeId="21301">
					+12% to Lightning Resistance
				</EditedNode>
				<EditedNode editorSeed="5894" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Fire Resistance" nodeId="45272">
					+12% to Fire Resistance
				</EditedNode>
				<EditedNode editorSeed="5894" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Cold Resistance" nodeId="37671">
					+12% to Cold Resistance
				</EditedNode>
				<EditedNode editorSeed="5894" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Damage Over Time" nodeId="16970">
					10% increased Damage over Time
				</EditedNode>
				<EditedNode editorSeed="5894" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Chaos Damage" nodeId="37175">
					10% increased Chaos Damage
				</EditedNode>
				<EditedNode editorSeed="5894" icon="Art/2DArt/SkillIcons/passives/VaalNotableOffensive.dds" nodeName="Ritual of Shadows" nodeId="25439">
					30% increased Chaos Damage
					25% chance to inflict Withered for 2 seconds on Hit
				</EditedNode>
				<EditedNode editorSeed="3162" icon="Art/2DArt/SkillIcons/passives/VaalNotableOffensive.dds" nodeName="Thaumaturgical Aptitude" nodeId="11420">
					27% increased Spell Damage
					43% increased Critical Strike Chance for Spells
				</EditedNode>
				<EditedNode editorSeed="3162" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Critical Strike Multiplier" nodeId="36542">
					+9% to Critical Strike Multiplier
				</EditedNode>
				<EditedNode editorSeed="3162" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Aura Effect" nodeId="57264">
					3% increased effect of Non-Curse Auras from your Skills
				</EditedNode>
				<EditedNode editorSeed="3162" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Chaos Damage" nodeId="31875">
					12% increased Chaos Damage
				</EditedNode>
				<EditedNode editorSeed="3162" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Movement Speed" nodeId="37569">
					3% increased Movement Speed
				</EditedNode>
				<EditedNode editorSeed="3162" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Movement Speed" nodeId="60398">
					3% increased Movement Speed
				</EditedNode>
				<EditedNode editorSeed="3162" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Spell Block" nodeId="4397">
					1% Chance to Block Spell Damage
				</EditedNode>
				<EditedNode editorSeed="3162" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Spell Damage" nodeId="7388">
					7% increased Spell Damage
				</EditedNode>
				<EditedNode editorSeed="3853" icon="Art/2DArt/SkillIcons/passives/VaalNotableOffensive.dds" nodeName="Ritual of Immolation" nodeId="11420">
					33% increased Fire Damage
					Damage Penetrates 2% Fire Resistance
				</EditedNode>
				<EditedNode editorSeed="3853" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Chaos Damage" nodeId="36542">
					9% increased Chaos Damage
				</EditedNode>
				<EditedNode editorSeed="3853" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Fire Damage" nodeId="57264">
					9% increased Fire Damage
				</EditedNode>
				<EditedNode editorSeed="3853" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Freeze Chance" nodeId="7388">
					4% chance to Freeze
				</EditedNode>
				<EditedNode editorSeed="3853" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Spell Block" nodeId="37569">
					1% Chance to Block Spell Damage
				</EditedNode>
				<EditedNode editorSeed="3853" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Critical Strike Multiplier" nodeId="60398">
					+9% to Critical Strike Multiplier
				</EditedNode>
				<EditedNode editorSeed="3853" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Energy Shield" nodeId="4397">
					5% increased maximum Energy Shield
				</EditedNode>
				<EditedNode editorSeed="3853" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Spell Dodge" nodeId="31875">
					1% chance to Dodge Spell Hits
				</EditedNode>
				<EditedNode editorSeed="7884" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Chaos Resistance" nodeId="46578">
					+7% to Chaos Resistance
				</EditedNode>
				<EditedNode editorSeed="7884" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Life" nodeId="30691">
					2% increased maximum Life
				</EditedNode>
				<EditedNode editorSeed="7884" icon="Art/2DArt/SkillIcons/passives/VaalNotableDefensive.dds" nodeName="Cult of Chaos" nodeId="7440">
					+1% to maximum Chaos Resistance
					+17% to Chaos Resistance
				</EditedNode>
				<EditedNode editorSeed="7884" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Life" nodeId="13714">
					2% increased maximum Life
				</EditedNode>
				<EditedNode editorSeed="7884" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Chaos Resistance" nodeId="476">
					+8% to Chaos Resistance
				</EditedNode>
				<EditedNode editorSeed="1444" icon="Art/2DArt/SkillIcons/passives/VaalNotableOffensive.dds" nodeName="Ritual of Immolation" nodeId="11420">
					34% increased Fire Damage
					Damage Penetrates 3% Fire Resistance
				</EditedNode>
				<EditedNode editorSeed="1444" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Fire Resistance" nodeId="36542">
					+12% to Fire Resistance
				</EditedNode>
				<EditedNode editorSeed="1444" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Cold Resistance" nodeId="57264">
					+12% to Cold Resistance
				</EditedNode>
				<EditedNode editorSeed="1444" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Attack Damage" nodeId="31875">
					8% increased Attack Damage
				</EditedNode>
				<EditedNode editorSeed="1444" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Life" nodeId="37569">
					4% increased maximum Life
				</EditedNode>
				<EditedNode editorSeed="1444" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Mana" nodeId="4397">
					4% increased maximum Mana
				</EditedNode>
				<EditedNode editorSeed="1444" icon="Art/2DArt/SkillIcons/passives/VaalOffensive.dds" nodeName="Chaos Damage" nodeId="60398">
					12% increased Chaos Damage
				</EditedNode>
				<EditedNode editorSeed="1444" icon="Art/2DArt/SkillIcons/passives/VaalDefensive.dds" nodeName="Evasion" nodeId="7388">
					12% increased Evasion Rating
				</EditedNode>
			</EditedNodes>
			<URL>
				https://www.pathofexile.com/passive-skill-tree/AAAABAIBAJuh_EcN0VH7FyYxRaKj99fjhKcre9eMC1ha74iExS9vLU3v66EvH0GMNtteQjrK0wkH1890EH_GMe8NfFgH5-pQMHBSM3IS8WNDG8hd8jsN7LDB8xEPkydwu80WJMDQrSKBxKIWvxhqMlgfx8HFbWwfGCZFD8RMLVBCQdCv64nTuXxJsbQMUimsmM_dbRkUsLjKppmbtVyKXGtrkPGKfbA2PTt8vooki9kTKwpdjjlS-TPDbY9GeoSYU_k3hEgPqy9y7BiXBioLJC3DOlM1VeAZiuq6H0yCHtdK
			</URL>
			<Sockets>
				<Socket nodeId="16218" itemId="0"/>
				<Socket nodeId="11150" itemId="0"/>
				<Socket nodeId="61834" itemId="3"/>
				<Socket nodeId="64583" itemId="9"/>
				<Socket nodeId="22994" itemId="0"/>
				<Socket nodeId="48679" itemId="0"/>
				<Socket nodeId="2311" itemId="11"/>
				<Socket nodeId="9408" itemId="7"/>
				<Socket nodeId="36634" itemId="0"/>
				<Socket nodeId="61305" itemId="0"/>
				<Socket nodeId="21984" itemId="2"/>
				<Socket nodeId="2491" itemId="0"/>
				<Socket nodeId="54127" itemId="0"/>
				<Socket nodeId="6230" itemId="0"/>
				<Socket nodeId="29712" itemId="12"/>
				<Socket nodeId="55190" itemId="0"/>
				<Socket nodeId="14993" itemId="0"/>
				<Socket nodeId="24970" itemId="0"/>
				<Socket nodeId="12613" itemId="10"/>
				<Socket nodeId="18436" itemId="0"/>
				<Socket nodeId="46519" itemId="0"/>
				<Socket nodeId="40400" itemId="0"/>
				<Socket nodeId="33631" itemId="0"/>
				<Socket nodeId="3109" itemId="0"/>
				<Socket nodeId="60735" itemId="0"/>
				<Socket nodeId="46393" itemId="0"/>
				<Socket nodeId="23756" itemId="0"/>
				<Socket nodeId="59585" itemId="0"/>
				<Socket nodeId="32763" itemId="0"/>
				<Socket nodeId="41876" itemId="0"/>
				<Socket nodeId="13170" itemId="13"/>
				<Socket nodeId="28475" itemId="0"/>
				<Socket nodeId="26196" itemId="0"/>
				<Socket nodeId="49080" itemId="0"/>
				<Socket nodeId="61288" itemId="0"/>
				<Socket nodeId="34483" itemId="0"/>
				<Socket nodeId="33989" itemId="1"/>
				<Socket nodeId="46882" itemId="0"/>
				<Socket nodeId="17219" itemId="0"/>
				<Socket nodeId="23984" itemId="0"/>
				<Socket nodeId="22748" itemId="0"/>
				<Socket nodeId="44169" itemId="0"/>
				<Socket nodeId="61666" itemId="0"/>
				<Socket nodeId="31683" itemId="0"/>
				<Socket nodeId="41263" itemId="4"/>
				<Socket nodeId="61419" itemId="6"/>
				<Socket nodeId="33753" itemId="0"/>
				<Socket nodeId="49684" itemId="0"/>
				<Socket nodeId="48768" itemId="0"/>
				<Socket nodeId="12161" itemId="0"/>
				<Socket nodeId="51198" itemId="0"/>
				<Socket nodeId="26725" itemId="0"/>
				<Socket nodeId="10532" itemId="0"/>
				<Socket nodeId="7960" itemId="8"/>
				<Socket nodeId="36931" itemId="0"/>
				<Socket nodeId="6910" itemId="0"/>
				<Socket nodeId="9797" itemId="5"/>
			</Sockets>
		</Spec>
	</Tree>
	<Notes>

	</Notes>
	<TreeView searchStr="" zoomY="-160.90625996259" showHeatMap="false" zoomLevel="1" showStatDifferences="true" zoomX="-37.70021510869"/>
	<Items activeItemSet="1" useSecondWeaponSet="false">
		<Item id="1">
			Rarity: UNIQUE
Watcher&apos;s Eye
Prismatic Jewel
Unique ID: 40f9711d5bd7ad2bcbddaf71c705607aef0eecd3dcadaafec6c0192f79b82863
Item Level: 86
Limited to: 1
Implicits: 0
5% increased maximum Energy Shield
4% increased maximum Life
4% increased maximum Mana
+1.71% to Critical Strike Chance while affected by Hatred
Effects of Consecrated Ground you create while affected by Zealotry Linger for 2 seconds
Damage Penetrates 15% Cold Resistance while affected by Hatred
		</Item>
		<Item id="2">
			Rarity: RARE
Dusk Glimmer
Large Cluster Jewel
Unique ID: 2d3cbcc8d8386a5eb230ea8596ae126ec82707dd70839f76f8cf275157a657e1
Item Level: 82
LevelReq: 54
Implicits: 3
{crafted}Adds 8 Passive Skills
{crafted}2 Added Passive Skills are Jewel Sockets
{crafted}Added Small Passive Skills grant: 12% increased Cold Damage
Added Small Passive Skills also grant: 5% increased Mana Regeneration Rate
1 Added Passive Skill is Blanketed Snow
1 Added Passive Skill is Prismatic Heart
1 Added Passive Skill is Widespread Destruction
		</Item>
		<Item id="3">
			Rarity: RARE
Kraken Joy
Cobalt Jewel
Unique ID: fd16398b69819790167994dc77e3b69f977be69130d8026b3b02c7239b4a4446
Item Level: 83
Implicits: 1
5% increased Elemental Damage
+11% to Global Critical Strike Multiplier
+14% to Critical Strike Multiplier for Spells
+17% to Critical Strike Multiplier with Cold Skills
8% increased maximum Energy Shield
		</Item>
		<Item id="4">
			Rarity: UNIQUE
Energy From Within
Cobalt Jewel
Unique ID: 70e1ed44f66615911c6fe0dd1e7c13ef9af4cb1057416a9f2c97e06af979d564
Item Level: 84
LevelReq: 26
Radius: Large
Implicits: 1
Corrupted Blood cannot be inflicted on you
6% increased maximum Energy Shield
Increases and Reductions to Life in Radius are Transformed to apply to Energy Shield
Corrupted
		</Item>
		<Item id="5">
			Rarity: RARE
Chimeric Breath
Cobalt Jewel
Unique ID: 674c7bf1100affed697857e93f5d0b79ac6d1aabeb0ecc9181ae76f25a2ea58e
Item Level: 85
Implicits: 0
+11% to Global Critical Strike Multiplier
+13% to Critical Strike Multiplier for Spells
+18% to Critical Strike Multiplier with Cold Skills
8% increased maximum Energy Shield
		</Item>
		<Item id="6">
			Rarity: UNIQUE
Thread of Hope
Crimson Jewel
Unique ID: 4a1fe5b365677ccfdefe80eeaae4d200458f9f71f1ed528cd3f8d9ebdcf151f8
Item Level: 86
Radius: Variable
Implicits: 1
Damage Penetrates 1% Elemental Resistances
Only affects Passives in Large Ring
Passives in Radius can be Allocated without being connected to your tree
-11% to all Elemental Resistances
Corrupted
		</Item>
		<Item id="7">
			Rarity: RARE
Hypnotic Glisten
Medium Cluster Jewel
Unique ID: 18ddae58580b5458b52a8e07b972f43592bfd4e9bf5b10c928dd50c67bbfd06f
Item Level: 83
LevelReq: 54
Implicits: 3
{crafted}Adds 4 Passive Skills
{crafted}1 Added Passive Skill is a Jewel Socket
{crafted}Added Small Passive Skills grant: 15% increased Critical Strike Chance
Added Small Passive Skills also grant: +3% to Lightning Resistance
Added Small Passive Skills also grant: +5 to Strength
1 Added Passive Skill is Pressure Points
1 Added Passive Skill is Quick Getaway
		</Item>
		<Item id="8">
			Rarity: RARE
Chimeric Spark
Large Cluster Jewel
Unique ID: db1f34511e33c0f8a512380923f2f10bfc2b0a590d83755525c2bbcc7af88bf6
Item Level: 83
LevelReq: 54
Implicits: 4
{crafted}Adds 8 Passive Skills
{crafted}2 Added Passive Skills are Jewel Sockets
{crafted}Added Small Passive Skills grant: 12% increased Cold Damage
3% increased Area of Effect of Aura Skills
Added Small Passive Skills also grant: +3 to Dexterity
1 Added Passive Skill is Blanketed Snow
1 Added Passive Skill is Prismatic Heart
1 Added Passive Skill is Widespread Destruction
		</Item>
		<Item id="9">
			Rarity: RARE
Eagle Hope
Medium Cluster Jewel
Unique ID: 44b55f1694ba9a9bb7c6719105c00f47cc1af341df11e0f936188e2c0969d182
Item Level: 81
LevelReq: 54
Implicits: 3
{crafted}Adds 5 Passive Skills
{crafted}1 Added Passive Skill is a Jewel Socket
{crafted}Added Small Passive Skills grant: 15% increased Critical Strike Chance
Added Small Passive Skills also grant: +5% to Cold Resistance
Added Small Passive Skills also grant: +5 to Intelligence
1 Added Passive Skill is Pressure Points
1 Added Passive Skill is Quick Getaway
		</Item>
		<Item id="10">
			Rarity: RARE
Oblivion Sliver
Cobalt Jewel
Unique ID: 64a1323507e4508e9f9009a31cd5edd6f6ea9bd445309f2d28f2efeb7b7bba0f
Item Level: 83
Implicits: 0
{fractured}8% increased maximum Energy Shield
+12% to Global Critical Strike Multiplier
+13% to Critical Strike Multiplier for Spells
+18% to Critical Strike Multiplier with Cold Skills
		</Item>
		<Item id="11">
			Rarity: RARE
Brood Ornament
Cobalt Jewel
Unique ID: 562947158c410aa04616602d94434f3162856e8e125c61ceacc5794d81662ae3
Item Level: 78
Implicits: 0
+12% to Global Critical Strike Multiplier
+15% to Critical Strike Multiplier for Spells
+18% to Critical Strike Multiplier with Cold Skills
8% increased maximum Energy Shield
		</Item>
		<Item id="12">
			Rarity: RARE
Dusk Cut
Medium Cluster Jewel
Unique ID: e8b79cf8b11b6cab2c9a44d1d57cab5175b61d7d01f5a5556d6f09e6df1f1723
Item Level: 81
LevelReq: 54
Implicits: 3
{crafted}Adds 4 Passive Skills
{crafted}1 Added Passive Skill is a Jewel Socket
{crafted}Added Small Passive Skills grant: 3% increased Effect of your Curses
Added Small Passive Skills also grant: +5% to Cold Resistance
Added Small Passive Skills also grant: Regenerate 0.1% of Life per Second
1 Added Passive Skill is Evil Eye
1 Added Passive Skill is Wish for Death
		</Item>
		<Item id="13">
			Rarity: RARE
Eagle Hope
Cobalt Jewel
Unique ID: 0409c46e4c9b270990ec666b8b75e985d3983093e7c296ef40a9e7bf9688cf9b
Item Level: 72
Implicits: 0
{fractured}+12% to Global Critical Strike Multiplier
+13% to Critical Strike Multiplier for Spells
+18% to Critical Strike Multiplier with Cold Skills
8% increased maximum Energy Shield
		</Item>
		<Item id="14">
			Rarity: RARE
Dread Knuckle
Moonstone Ring
Unique ID: 346d82b5f01400d23caf59978fbb87a3f3e2adff0e20e32c86409f065bcef5b2
Shaper Item
Elder Item
Item Level: 83
LevelReq: 64
Implicits: 1
+30 to maximum Energy Shield
Trigger Level 12 Assassin&apos;s Mark when you Hit a Rare or Unique Enemy
Adds 20 to 41 Cold Damage to Spells and Attacks
+19% to Global Critical Strike Multiplier
+56 to maximum Energy Shield
6% chance to Freeze
Adds 12 to 30 Cold Damage against Chilled or Frozen Enemies
{crafted}16% increased Cold Damage
		</Item>
		<Item id="15">
			Rarity: RARE
Behemoth Spur
Two-Toned Boots (Armour/Energy Shield)
Unique ID: 8037cba8056b90a2bd2c9982010207a08e4a236ada4bbb7ec19da5a085687098
Hunter Item
Redeemer Item
Item Level: 86
Quality: 30
Sockets: G-G-B-B
LevelReq: 70
Implicits: 2
{crafted}80% chance to Avoid being Stunned if you&apos;ve Killed Recently
+12% to Fire and Lightning Resistances
+42 to Strength
9% increased Strength
35% increased Movement Speed
19% chance to gain Elusive on Critical Strike
9% increased Elusive Effect
18% increased Effect of Tailwind on you
You have Tailwind if you have dealt a Critical Strike Recently
{crafted}+34 to maximum Energy Shield
		</Item>
		<Item id="16">
			Rarity: RARE
Honour Veil
Hubris Circlet
Unique ID: 93f4283be9c8db994476a3a5bfd9ef60fdf32fcc255f191c622cc1b21a2a666e
Warlord Item
Redeemer Item
Item Level: 86
Quality: 30
Sockets: G-G-B G
LevelReq: 69
Implicits: 1
{crafted}Zealotry has 15% reduced Mana Reservation
+20% to Global Critical Strike Multiplier
96% increased Energy Shield
22% increased Elemental Damage
7% reduced Mana Reserved
Damage Penetrates 3% of Enemy Elemental Resistances
Nearby Enemies have -9% to Cold Resistance
{crafted}+45 to maximum Energy Shield
		</Item>
		<Item id="17">
			Rarity: UNIQUE
Cospri&apos;s Malice
Jewelled Foil
Unique ID: 0a331d6968381dd99594f5cd6132943b1b1e5e39020397605501603949191678
Item Level: 75
Quality: 20
Sockets: B-B-B
LevelReq: 68
Implicits: 3
{crafted}Quality does not increase Physical Damage
{crafted}Grants 1% increased Elemental Damage per 2% Quality
Skills fire an additional Projectile
Trigger a Socketed Cold Spell on Melee Critical Strike
+257 Intelligence Requirement
No Physical Damage
Adds 94 to 167 Cold Damage
Adds 57 to 101 Cold Damage to Spells
9% increased Attack Speed
60% increased Critical Strike Chance against Chilled Enemies
Corrupted
		</Item>
		<Item id="18">
			Rarity: RARE
Kraken Shackle
Crystal Belt
Unique ID: 1fdf3bc5ec92991c311859456844a857333f206c599831e057caee7d05bf2ac0
Shaper Item
Crusader Item
Item Level: 86
LevelReq: 79
Implicits: 1
+96 to maximum Energy Shield
+61 to maximum Energy Shield
16% increased maximum Energy Shield
+48% to Fire Resistance
+43% to Lightning Resistance
36% increased Energy Shield from Body Armour
28% increased Spell Damage during any Flask Effect
20% increased Cooldown Recovery
		</Item>
		<Item id="19">
			Rarity: RARE
Mind Spiral
Topaz Ring
Unique ID: b6dd3b4d9bcb60886aa7c2c1faf5e3da9fa1b5f4f18ad40ecd673c529ccfeab0
Crusader Item
Item Level: 85
LevelReq: 67
Implicits: 1
+36% to Lightning Resistance
25% increased Spell Damage
+45 to maximum Energy Shield
13% increased maximum Energy Shield
+19% to all Elemental Resistances
+57% to Fire Resistance
+56% to Cold Resistance
		</Item>
		<Item id="20">
			Rarity: MAGIC
Alchemist&apos;s Quicksilver Flask of Adrenaline
Unique ID: df4a300d384a39f893e08838bbb21f77d2e0308232f32a2be7056171752ecbda
Item Level: 42
Quality: 20
LevelReq: 16
Implicits: 0
30% increased Movement Speed during Flask effect
25% increased effect
33% reduced Duration
		</Item>
		<Item id="21">
			Rarity: UNIQUE
Atziri&apos;s Promise
Amethyst Flask
Unique ID: 82a02cd5ae91c45af9d472f20355e22c148033f4156a9db34d04524441df9cbd
Item Level: 85
Quality: 0
LevelReq: 68
Implicits: 0
2% of Chaos Damage Leeched as Life during Flask effect
Gain 20% of Physical Damage as Extra Chaos Damage during effect
Gain 15% of Elemental Damage as Extra Chaos Damage during effect
		</Item>
		<Item id="22">
			Rarity: MAGIC
Enduring Eternal Mana Flask of Heat
Unique ID: c8691aa616346249cdae9722f0b78f2a70c8c1b1441be40c73b0780ef713b484
Item Level: 72
Quality: 26
LevelReq: 65
Implicits: 0
30% reduced Amount Recovered
Immunity to Freeze and Chill during Flask effect
Removes Freeze and Chill on use
30% reduced Duration
Flask Effect is not removed at Full Mana
Flask Effect does not Queue
		</Item>
		<Item id="23">
			Rarity: UNIQUE
Dying Sun
Ruby Flask
Unique ID: 2c27fad04da58e0c7faf96884765635ab45ec396bf6ac92ff8b8f94bfeb2b9b8
Item Level: 80
Quality: 0
LevelReq: 68
Implicits: 0
8% reduced Charges used
Skills fire 2 additional Projectiles during Flask Effect
25% increased Area of Effect during Flask Effect
		</Item>
		<Item id="24">
			Rarity: UNIQUE
Shavronne&apos;s Wrappings
Occultist&apos;s Vestment
Unique ID: c5663fe63ec58fca7c88c5988623dd3bdceb89c9e8ac624d8227fc9f47d39f67
Item Level: 70
Quality: 20
Sockets: G-G-G-B-B-B
LevelReq: 62
Implicits: 2
+1 to Level of Socketed Gems
+2 to Level of Socketed Projectile Gems
134% increased Energy Shield
10% faster start of Energy Shield Recharge
+36% to Lightning Resistance
Reflects 1 to 250 Lightning Damage to Melee Attackers
Chaos Damage does not bypass Energy Shield
Corrupted
		</Item>
		<Item id="25">
			Rarity: UNIQUE
Cospri&apos;s Malice
Jewelled Foil
Unique ID: e022814fd14bf965ffb1abf8305e539c1ab40ab59c4add1ae8927f3a83af8480
Item Level: 83
Quality: 0
Sockets: B-G-B
LevelReq: 68
Implicits: 1
Skills fire an additional Projectile
Trigger a Socketed Cold Spell on Melee Critical Strike
+257 Intelligence Requirement
No Physical Damage
Adds 91 to 161 Cold Damage
Adds 55 to 106 Cold Damage to Spells
14% increased Attack Speed
60% increased Critical Strike Chance against Chilled Enemies
Corrupted
		</Item>
		<Item id="26">
			Rarity: RARE
Agony Touch
Fingerless Silk Gloves
Unique ID: 38caeb692e3b3996b6162db7fc10810a0bf205ad18ce3c413eaabffa986c2440
Hunter Item
Item Level: 85
Quality: 28
Sockets: W-W-W-B
LevelReq: 70
Implicits: 2
{crafted}Trigger Commandment of Frost on Kill
16% increased Spell Damage
+588 to Accuracy Rating
+47 to maximum Energy Shield
96% increased Energy Shield
+48% to Cold Resistance
Unnerve Enemies for 4 seconds on Hit
50% increased Damage with Hits against Chilled Enemies
{crafted}12% increased Attack Speed
		</Item>
		<Item id="27">
			Rarity: UNIQUE
Bottled Faith
Sulphur Flask
Unique ID: 8a2882da1154eaefb6594f530acd5234a62b9093ba09702355432766c2f2e045
Item Level: 85
Quality: 20
LevelReq: 35
Implicits: 1
Creates Consecrated Ground on Use
45% increased Duration
Consecrated Ground created by this Flask has Tripled Radius
+2% to Critical Strike Chance against Enemies on Consecrated Ground during Effect
Consecrated Ground created during Effect applies 10% increased Damage taken to Enemies
		</Item>
		<Item id="28">
			Rarity: UNIQUE
Badge of the Brotherhood
Turquoise Amulet
Unique ID: e6b2caa3bf151e3cbbaffce1c93329c2252d608bb683c24b70cb3be8e7d0e887
Item Level: 85
LevelReq: 60
Implicits: 2
{crafted}Allocates Overcharge
+24 to Dexterity and Intelligence
Your Maximum Frenzy Charges is equal to your Maximum Power Charges
9% increased Cooldown Recovery Rate of Travel Skills per Frenzy Charge
10% increased Effect of Elusive on you per Power Charge
25% chance to lose a Frenzy Charge when you use a Travel Skill
22% chance to lose a Power Charge when you gain Elusive
		</Item>
		<Slot name="Weapon 1" itemId="17"/>
		<Slot active="true" name="Flask 3" itemId="21"/>
		<Slot name="Gloves" itemId="26"/>
		<Slot name="Belt" itemId="18"/>
		<Slot active="true" name="Flask 5" itemId="20"/>
		<Slot name="Helmet" itemId="16"/>
		<Slot active="true" name="Flask 1" itemId="22"/>
		<Slot active="true" name="Flask 4" itemId="27"/>
		<Slot active="true" name="Flask 2" itemId="23"/>
		<Slot name="Weapon 2" itemId="25"/>
		<Slot name="Ring 2" itemId="19"/>
		<Slot name="Body Armour" itemId="24"/>
		<Slot name="Ring 1" itemId="14"/>
		<Slot name="Boots" itemId="15"/>
		<Slot name="Amulet" itemId="28"/>
		<ItemSet useSecondWeaponSet="false" id="1">
			<Slot name="Weapon 1Swap Abyssal Socket 5" itemId="0"/>
			<Slot name="Weapon 1 Abyssal Socket 2" itemId="0"/>
			<Slot name="Weapon 1" itemId="17"/>
			<Slot name="Boots Abyssal Socket 5" itemId="0"/>
			<Slot name="Weapon 1Swap Abyssal Socket 2" itemId="0"/>
			<Slot name="Belt Abyssal Socket 2" itemId="0"/>
			<Slot active="true" name="Flask 3" itemId="21"/>
			<Slot name="Weapon 2Swap Abyssal Socket 3" itemId="0"/>
			<Slot name="Weapon 1 Abyssal Socket 5" itemId="0"/>
			<Slot name="Weapon 2 Abyssal Socket 5" itemId="0"/>
			<Slot name="Weapon 2 Abyssal Socket 4" itemId="0"/>
			<Slot name="Weapon 1 Abyssal Socket 6" itemId="0"/>
			<Slot name="Weapon 2 Abyssal Socket 6" itemId="0"/>
			<Slot name="Weapon 2Swap Abyssal Socket 1" itemId="0"/>
			<Slot name="Boots Abyssal Socket 3" itemId="0"/>
			<Slot name="Helmet Abyssal Socket 1" itemId="0"/>
			<Slot name="Belt Abyssal Socket 6" itemId="0"/>
			<Slot name="Helmet Abyssal Socket 2" itemId="0"/>
			<Slot name="Gloves" itemId="26"/>
			<Slot name="Helmet Abyssal Socket 3" itemId="0"/>
			<Slot name="Weapon 1Swap Abyssal Socket 1" itemId="0"/>
			<Slot name="Helmet Abyssal Socket 4" itemId="0"/>
			<Slot name="Weapon 2 Abyssal Socket 1" itemId="0"/>
			<Slot name="Weapon 1 Abyssal Socket 4" itemId="0"/>
			<Slot name="Belt" itemId="18"/>
			<Slot name="Gloves Abyssal Socket 4" itemId="0"/>
			<Slot name="Boots Abyssal Socket 4" itemId="0"/>
			<Slot name="Weapon 2 Abyssal Socket 2" itemId="0"/>
			<Slot active="true" name="Flask 5" itemId="20"/>
			<Slot name="Boots Abyssal Socket 2" itemId="0"/>
			<Slot name="Belt Abyssal Socket 3" itemId="0"/>
			<Slot name="Body Armour Abyssal Socket 1" itemId="0"/>
			<Slot name="Gloves Abyssal Socket 1" itemId="0"/>
			<Slot name="Helmet Abyssal Socket 5" itemId="0"/>
			<Slot name="Helmet Abyssal Socket 6" itemId="0"/>
			<Slot name="Helmet" itemId="16"/>
			<Slot active="true" name="Flask 1" itemId="22"/>
			<Slot name="Gloves Abyssal Socket 5" itemId="0"/>
			<Slot name="Body Armour Abyssal Socket 2" itemId="0"/>
			<Slot name="Boots Abyssal Socket 6" itemId="0"/>
			<Slot name="Weapon 1 Abyssal Socket 3" itemId="0"/>
			<Slot name="Weapon 2 Abyssal Socket 3" itemId="0"/>
			<Slot name="Belt Abyssal Socket 4" itemId="0"/>
			<Slot name="Weapon 2Swap Abyssal Socket 2" itemId="0"/>
			<Slot name="Belt Abyssal Socket 1" itemId="0"/>
			<Slot name="Body Armour Abyssal Socket 3" itemId="0"/>
			<Slot active="true" name="Flask 4" itemId="27"/>
			<Slot active="true" name="Flask 2" itemId="23"/>
			<Slot name="Belt Abyssal Socket 5" itemId="0"/>
			<Slot name="Weapon 1Swap Abyssal Socket 3" itemId="0"/>
			<Slot name="Weapon 2" itemId="25"/>
			<Slot name="Weapon 2Swap Abyssal Socket 6" itemId="0"/>
			<Slot name="Boots Abyssal Socket 1" itemId="0"/>
			<Slot name="Body Armour Abyssal Socket 4" itemId="0"/>
			<Slot name="Weapon 2Swap Abyssal Socket 4" itemId="0"/>
			<Slot name="Weapon 2 Swap" itemId="0"/>
			<Slot name="Weapon 1 Swap" itemId="0"/>
			<Slot name="Weapon 1Swap Abyssal Socket 6" itemId="0"/>
			<Slot name="Ring 2" itemId="19"/>
			<Slot name="Gloves Abyssal Socket 2" itemId="0"/>
			<Slot name="Body Armour Abyssal Socket 6" itemId="0"/>
			<Slot name="Weapon 1 Abyssal Socket 1" itemId="0"/>
			<Slot name="Body Armour" itemId="24"/>
			<Slot name="Gloves Abyssal Socket 3" itemId="0"/>
			<Slot name="Ring 1" itemId="14"/>
			<Slot name="Weapon 1Swap Abyssal Socket 4" itemId="0"/>
			<Slot name="Body Armour Abyssal Socket 5" itemId="0"/>
			<Slot name="Gloves Abyssal Socket 6" itemId="0"/>
			<Slot name="Boots" itemId="15"/>
			<Slot name="Weapon 2Swap Abyssal Socket 5" itemId="0"/>
			<Slot name="Amulet" itemId="28"/>
		</ItemSet>
	</Items>
	<Config>
		<Input name="buffTailwind" boolean="true"/>
		<Input name="useFrenzyCharges" boolean="true"/>
		<Input name="conditionEnemyChilled" boolean="true"/>
		<Input name="enemyIsBoss" string="Sirus"/>
		<Input name="igniteMode" string="CRIT"/>
		<Input name="conditionEnemyOnConsecratedGround" boolean="true"/>
		<Input name="conditionCritRecently" boolean="true"/>
		<Input name="usePowerCharges" boolean="true"/>
		<Input name="conditionEnemyUnnerved" boolean="true"/>
		<Input name="buffElusive" boolean="true"/>
		<Input name="conditionKilledRecently" boolean="true"/>
		<Input name="conditionLeeching" boolean="true"/>
	</Config>
</PathOfBuilding>]],
    output = {["SpellSuppressionChanceOverCap"] = 0,
["FrenzyChargesMin"] = 0,
["EnergyShieldOnGloves"] = 202,
["HitChance"] = 100,
["LightningDotEHP"] = 24929.1667,
["CrabBarriersMax"] = 0,
["BlockEffect"] = 100,
["AvoidColdDamageChance"] = 25,
["PierceCount"] = 0,
["AnyTakenReflect"] = 0,
["InspirationCharges"] = 5,
["AbsorptionChargesMax"] = 0,
["LifePercentCost"] = 0,
["ReqInt"] = 257,
["ProjectileNotHitChance"] = 0,
["LifeCost"] = 0,
["ManaPercentCost"] = 0,
["ColdMinBase"] = 669.2,
["MaxManaLeechRate"] = 189.2,
["PhysicalTakenReflectMult"] = 0.97,
["LightningLightningBaseTakenHitMult"] = 0.24,
["SelfShockDuration"] = 100,
["ManaOnHit"] = 0,
["AfflictionChargesMax"] = 0,
["PhysicalProjectileDamageChance"] = 36.25,
["ManaCost"] = 45,
["DoubleDamageChance"] = 10,
["SpellSuppressionEffect"] = 50,
["BloodChargesMax"] = 5,
["FireMeleeDamageChance"] = 36.25,
["PhysicalGuardEffectiveLife"] = 69,
["ActiveTrapLimit"] = 15,
["PhysicalAegis"] = 0,
["EnergyShieldRegen"] = 0,
["LightningAegis"] = 0,
["SiphoningCharges"] = 0,
["RuthlessBlowEffect"] = 1,
["Cooldown"] = 0.132,
["PhysicalTakenHitMult"] = 0.97,
["ChaosDotEHP"] = 4786.4,
["ReqStr"] = 114,
["LightningGuardAbsorbRate"] = 0,
["MissingLightningResist"] = 0,
["MaxManaLeechInstance"] = 94.6,
["LightningGuardEffectivePool"] = 0,
["EnergyShieldOnBody Armour"] = 330,
["MaxEnergyShieldLeechRate"] = 295.7,
["EnergyShieldLeechInstanceRate"] = 118.28,
["PhysicalNumberOfHits"] = 8.6486,
["ChaosTakenHit"] = 1,
["FireFireBaseTakenHitMult"] = 0.2,
["CurrentShock"] = 0,
["PhysicalResist"] = 0,
["ColdSpellProjectileDamageChance"] = 25,
["FireResistOver75"] = 0,
["ColdResist"] = 75,
["Spec:EnergyShieldInc"] = 125,
["ScorchChanceOnHit"] = 0,
["PhysicalMinBase"] = 0,
["SpellProjectileBlockChance"] = 0,
["ColdTakenReflectMult"] = 0.25,
["Dex"] = 247,
["Spec:EvasionInc"] = 148,
["Spec:ArmourInc"] = 0,
["Spec:ManaInc"] = 8,
["Spec:LifeInc"] = 0,
["ExtraPoints"] = 2,
["KnockbackChanceOnHit"] = 0,
["TheoreticalOffensiveWarcryEffect"] = 1,
["IgniteChanceOnHit"] = 0,
["FullDPS"] = 0,
["PowerChargesMax"] = 6,
["EnergyShieldLeechInstantRate"] = 0,
["CullingDPS"] = 2819202.2946,
["ElusiveEffectMod"] = 169,
["TotalDotDPS"] = 0,
["SelfBleedDuration"] = 100,
["MaxOffensiveWarcryEffect"] = 1,
["WithIgniteDPS"] = 25372820.6514,
["PhysicalDamageReduction"] = 3,
["SelfChillEffect"] = 100,
["Str"] = 116,
["SpellDodgeChanceOverCap"] = 0,
["WithPoisonDPS"] = 25372820.6514,
["FireProjectileDamageChance"] = 36.25,
["LightningSpellProjectileDamageChance"] = 25,
["AttackDodgeChanceOverCap"] = 0,
["CombinedAvg"] = 25372820.6514,
["CombinedDPS"] = 28192022.946,
["TotalDot"] = 0,
["FireCritAverage"] = 0,
["AnyGuard"] = false,
["PhysicalTakenReflect"] = 1,
["MaximumScorch"] = 50,
["ShieldBlockChance"] = 0,
["EnemyStunDuration"] = 0.35,
["EnergyShieldLeechGainRate"] = 295.7,
["EnemyStunThresholdMod"] = 1,
["KnockbackChance"] = 0,
["SpellBlockChance"] = 0,
["PhysicalMindOverMatter"] = 0,
["FreezeDurationMod"] = 1.08,
["FreezeChance"] = 100,
["LightningManaEffectiveLife"] = 69,
["TriggerTime"] = 0.1325,
["LightningResistOver75"] = 1,
["ColdTakenReflect"] = 1,
["SpellBlockChanceMax"] = 75,
["ChaosEnergyShieldBypass"] = 0,
["EnergyShieldOnBoots"] = 75,
["impaleStoredHitAvg"] = 0,
["ChillEffectModDisplay"] = 0,
["ManaOnHitRate"] = 0,
["DamageTakenOnBlock"] = 0,
["ChillEffectMod"] = 1,
["EnergyShieldRechargeDelay"] = 1.8182,
["EnergyShieldRegenPercent"] = 0,
["ShockChance"] = 100,
["IgniteChance"] = 100,
["BlockChanceOverCap"] = 0,
["ChallengerCharges"] = 0,
["Int"] = 381,
["ColdEnergyShieldBypass"] = 0,
["CritIgniteDotMulti"] = 1.5,
["FireResistTotal"] = 145,
["FreezeAvoidChance"] = 100,
["IgniteDotMulti"] = 1,
["ChaosTakenHitMult"] = 1.25,
["LifeLeechRate"] = 269.6,
["BleedChanceOnHit"] = 0,
["IgniteFireMin"] = 0,
["AttackDodgeChance"] = 0,
["ImpaleChance"] = 0,
["EnergyShieldLeechDuration"] = 5,
["BrittleChanceOnHit"] = 0,
["ChillChanceOnHit"] = 0,
["FreezeChanceOnHit"] = 0,
["ReqDex"] = 212,
["ColdTakenHit"] = 1,
["ShockChanceOnHit"] = 0,
["LightningProjectileDamageChance"] = 36.25,
["PhysicalHitAverage"] = 0,
["ChillChance"] = 100,
["DoubleDamageChanceOnCrit"] = 10,
["BrutalChargesMin"] = 0,
["ChaosMindOverMatter"] = 0,
["PoisonChanceOnHit"] = 0,
["Armour"] = 164,
["KnockbackChanceOnCrit"] = 0,
["SapChanceOnCrit"] = 0,
["PoisonAvoidChance"] = 0,
["LightningResistTotal"] = 98,
["FireMinBase"] = 0,
["LightningMinBase"] = 0,
["FireDotEHP"] = 29915,
["CritChance"] = 100,
["ChillChanceOnCrit"] = 100,
["InterruptStunAvoidChance"] = 25,
["RuthlessBlowMaxCount"] = 0,
["ScaledDamageEffect"] = 1.1,
["AverageDamage"] = 305512.5906,
["ColdTakenHitMult"] = 0.25,
["PowerChargesMin"] = 1,
["Devotion"] = 0,
["MissingColdResist"] = 0,
["ChaosGuardAbsorbRate"] = 0,
["ShockChanceOnCrit"] = 100,
["IgniteChanceOnCrit"] = 100,
["PhysicalTakenHit"] = 1,
["ActionTriggerRate"] = 7.5758,
["PoisonChanceOnCrit"] = 0,
["BleedChanceOnCrit"] = 0,
["ManaLeechGainRate"] = 0,
["ColdGuardAbsorbRate"] = 0,
["LifeLeechInstances"] = 415.25,
["LifeUnreserved"] = 69,
["IgniteFireMax"] = 0,
["FireResist"] = 75,
["RemovableFrenzyCharges"] = 6,
["ManaLeechRate"] = 0,
["ChaosAegis"] = 0,
["ManaLeechInstanceRate"] = 18.92,
["EnergyShieldLeechPerHit"] = 591.4,
["EnergyShieldLeechRate"] = 295.7,
["PhysicalTotalPool"] = 5983,
["FreezeChanceOnCrit"] = 100,
["BlockDuration"] = 0.35,
["ManaLeechPerHit"] = 0,
["FrenzyChargesMax"] = 6,
["MissingChaosResist"] = 100,
["TotalDPS"] = 25372820.6514,
["AverageHit"] = 305512.5906,
["FireTakenHit"] = 0.8,
["EnergyShieldOnHitRate"] = 0,
["BleedAvoidChance"] = 0,
["AverageNotHitChance"] = 0,
["LifeOnHitRate"] = 0,
["EnergyShieldOnBlock"] = 0,
["EnergyShieldOnHit"] = 0,
["StunAvoidChance"] = 90,
["LifeOnHit"] = 0,
["ColdResistOverCap"] = 17,
["Life"] = 1348,
["DurationMod"] = 1,
["ManaLeechInstantRate"] = 0,
["EnduranceCharges"] = 0,
["ChainRemaining"] = 0,
["ShockAvoidChance"] = 0,
["ColdTakenDotMult"] = 0.25,
["ChaosAverageDamageChance"] = 30.625,
["ManaLeechInstances"] = 0,
["ChaosMaximumHitTaken"] = 4786.4,
["SapChanceOnHit"] = 0,
["PhysicalTotalEHP"] = 10660.2808,
["ESCost"] = 0,
["ManaUnreservedPercent"] = 9.9366,
["ColdMindOverMatter"] = 0,
["PhysicalGuardEffectivePool"] = 0,
["LifeLeechInstantRate"] = 0,
["MaximumShock"] = 50,
["LifeLeechDuration"] = 5,
["EnergyShieldLeechInstant"] = 0,
["SpellProjectileNotHitChance"] = 0,
["LifeRegenPercent"] = 0.1,
["LightningResist"] = 76,
["PhysicalSpellProjectileDamageChance"] = 25,
["LifeLeechGainRate"] = 269.6,
["SpellNotHitChance"] = 0,
["LifeReservedPercent"] = 94.8813,
["PhysicalMaximumHitTaken"] = 6168.0412,
["TotalMax"] = 61273.3825,
["WarcryPower"] = 20,
["ProjectileEvadeChance"] = 0,
["AbsorptionCharges"] = 0,
["FireMaxBase"] = 0,
["LightningCritAverage"] = 0,
["FireEnergyShieldBypass"] = 0,
["MaxEnergyShieldLeechInstance"] = 591.4,
["HexDoomLimit"] = 30,
["PhysicalSpellDamageChance"] = 25,
["EnergyShieldLeechInstances"] = 415.25,
["AvoidPhysicalDamageChance"] = 25,
["FireHitAverage"] = 0,
["ProjectileCount"] = 11,
["CullMultiplier"] = 1.1111,
["ColdHitAverage"] = 46444.8188,
["ChaosResistTotal"] = -25,
["CrabBarriers"] = 0,
["LightningResistOverCap"] = 22,
["FireNumberOfHits"] = 36.036,
["ChaosCritAverage"] = 22199.1963,
["EnergyShieldOnHelmet"] = 273,
["TotalDotInstance"] = 0,
["ManaReservedPercent"] = 90.0634,
["FireResistOverCap"] = 70,
["PhysicalCritAverage"] = 0,
["LightningTakenReflectMult"] = 0.24,
["AvoidChaosDamageChance"] = 25,
["allMult"] = 1.1,
["PhysicalTakenDotMult"] = 1,
["ManaLeech"] = 0,
["GhostShrouds"] = 0,
["LifeLeechInstant"] = 0,
["LowestOfMaximumLifeAndMaximumMana"] = 946,
["ColdDotEHP"] = 23932,
["LifeLeech"] = 134.8,
["SelfPoisonDuration"] = 100,
["ChaosMaxBase"] = 0,
["ColdResistTotal"] = 92,
["BrutalCharges"] = 0,
["ColdMaxBase"] = 1054.2,
["LightningMaxBase"] = 0,
["PhysicalMaxBase"] = 0,
["PhysicalGuardAbsorbRate"] = 0,
["InspirationChargesMax"] = 5,
["ChaosResist"] = -25,
["DoubleDamageEffect"] = 1.1,
["TripleDamageEffect"] = 1,
["PreEffectiveCritChance"] = 100,
["ManaUnreserved"] = 94,
["FireTakenReflect"] = 0.8,
["Accuracy"] = 4112.55,
["TripleDamageChanceOnCrit"] = 0,
["LifeLeechPerHit"] = 134.8,
["BonusCritDotMultiplier"] = 0,
["CritEffect"] = 6.1,
["WardRechargeDelay"] = 5,
["FireTakenReflectMult"] = 0.2,
["MaxLifeLeechInstance"] = 134.8,
["SpellSuppressionEffectiveChance"] = 0,
["EnduranceChargesMin"] = 0,
["ActiveGolemLimit"] = 1,
["FireManaEffectiveLife"] = 69,
["TripleDamageChance"] = 0,
["LifeUnreservedPercent"] = 5.1187,
["ScorchChanceOnCrit"] = 0,
["ShowBlockEffect"] = true,
["FistOfWarCooldown"] = 0,
["RuthlessBlowMultiplier"] = 1,
["FistOfWarAilmentEffect"] = 1,
["ServerTriggerRate"] = 7.55,
["BlockChanceMax"] = 75,
["RuthlessBlowChance"] = 0,
["LightRadiusMod"] = 1,
["FistOfWarHitEffect"] = 1,
["ExertedAttackUptimeRatio"] = 0,
["ManaRegen"] = 35.6,
["ChaosChaosBaseTakenHitMult"] = 1.25,
["AilmentWarcryEffect"] = 1,
["RallyingHitEffect"] = 1,
["SourceTriggerRate"] = 7.55,
["SeismicHitEffect"] = 1,
["TheoreticalMaxOffensiveWarcryEffect"] = 1,
["WithBleedDPS"] = 25372820.6514,
["OffensiveWarcryEffect"] = 1,
["AvoidLightningDamageChance"] = 25,
["Speed"] = 7.55,
["ColdColdBaseTakenHitMult"] = 0.25,
["SelfIgniteDuration"] = 100,
["AvoidFireDamageChance"] = 25,
["ChaosSpellProjectileDamageChance"] = 25,
["Time"] = 0.1325,
["FrenzyCharges"] = 6,
["TotalCharges"] = 12,
["ChaosTakenReflectMult"] = 1.25,
["RageCost"] = 0,
["LifeReserved"] = 1279,
["SpellSuppressionChance"] = 0,
["ProjectileSpeedMod"] = 1.86,
["FireSpellProjectileDamageChance"] = 25,
["PiercedCount"] = 0,
["PierceCountString"] = 0,
["ForkCountString"] = "0",
["Chain"] = 0,
["EnemyCurseLimit"] = 2,
["ChainMaxString"] = 0,
["LightningEnergyShieldBypass"] = 0,
["ChainMax"] = 0,
["ActiveMineLimit"] = 15,
["ColdTotalPool"] = 5983,
["LightningMindOverMatter"] = 0,
["ChaosTotalEHP"] = 7106.8539,
["ChaosNumberOfHits"] = 5.7658,
["FireSpellDamageChance"] = 25,
["LightningHitAverage"] = 0,
["ColdTotalEHP"] = 35534.2694,
["ColdNumberOfHits"] = 28.8288,
["CritExtraDamageReduction"] = 0,
["PhysicalResistWhenHit"] = 0,
["Gear:Ward"] = 0,
["BloodCharges"] = 5,
["ColdMaximumHitTaken"] = 23932,
["BlitzChargesMax"] = 0,
["LightningMaximumHitTaken"] = 24929.1667,
["LightningAverageDamageChance"] = 30.625,
["BrittleChanceOnCrit"] = 0,
["SelfFreezeDuration"] = 100,
["PhysicalDotEHP"] = 5983,
["ChaosGuardEffectiveLife"] = 69,
["ChaosSpellDamageChance"] = 25,
["MovementSpeedMod"] = 3.59,
["FireTotalPool"] = 5983,
["ColdProjectileDamageChance"] = 36.25,
["ChillAvoidChance"] = 100,
["ChaosMeleeDamageChance"] = 36.25,
["LowestAttribute"] = 116,
["EnduranceChargesMax"] = 3,
["ActionSpeedMod"] = 1.09,
["SpellBlockChanceOverCap"] = 0,
["MeleeEvadeChance"] = 0,
["FireAverageDamageChance"] = 30.625,
["ProjectileBlockChance"] = 15,
["FireTotalEHP"] = 44417.8368,
["RemovableEnduranceCharges"] = 0,
["ColdAverageDamageChance"] = 30.625,
["ColdAegis"] = 0,
["ChaosGuardEffectivePool"] = 0,
["ColdMeleeDamageChance"] = 36.25,
["LightningSpellDamageChance"] = 25,
["LightningMeleeDamageChance"] = 36.25,
["PhysicalAverageDamageChance"] = 30.625,
["Gear:EnergyShield"] = 880,
["EnergyShield"] = 5914,
["SelfShockEffect"] = 100,
["dontSplitEvade"] = true,
["ColdCritAverage"] = 283313.3944,
["ChallengerChargesMax"] = 0,
["LightningTakenHitMult"] = 0.24,
["StunDuration"] = 0.35,
["PhysicalMeleeDamageChance"] = 36.25,
["AverageBlockChance"] = 7.5,
["AnyMindOverMatter"] = false,
["ManaRegenInc"] = 115,
["SpellDodgeChance"] = 0,
["AfflictionChargesMin"] = 0,
["ChaosResistOver75"] = 0,
["LightningTakenReflect"] = 1,
["FireTakenHitMult"] = 0.2,
["LowestOfArmourAndEvasion"] = 45,
["EnergyShieldLeech"] = 591.4,
["ChaosMinBase"] = 0,
["FireMindOverMatter"] = 0,
["AnyAegis"] = false,
["ChaosHitAverage"] = 3639.2125,
["ArmourOnBoots"] = 164,
["AbsorptionChargesMin"] = 0,
["EvadeChance"] = 0,
["DamageReductionMax"] = 90,
["LifeLeechInstanceRate"] = 26.96,
["ColdResistOver75"] = 0,
["EnergyShieldRechargeAppliesToEnergyShield"] = true,
["ManaOnBlock"] = 0,
["MissingFireResist"] = 0,
["IgniteAvoidChance"] = 0,
["SiphoningChargesMax"] = 0,
["EnergyShieldRecharge"] = 3454,
["Gear:Armour"] = 164,
["BrutalChargesMax"] = 0,
["LightningTotalEHP"] = 37310.9829,
["ChaosProjectileDamageChance"] = 36.25,
["ManaLeechDuration"] = 0,
["SelfBlindDuration"] = 100,
["EffectiveMovementSpeedMod"] = 3.9131,
["MaxLifeLeechRate"] = 269.6,
["CurrentScorch"] = 0,
["SelfChillDuration"] = 100,
["BlockChance"] = 15,
["FireGuardAbsorbRate"] = 0,
["ChaosPoisonChance"] = 0,
["ChaosManaEffectiveLife"] = 69,
["PowerCharges"] = 6,
["AfflictionCharges"] = 0,
["TotalAttr"] = 744,
["FireAegis"] = 0,
["LifeOnBlock"] = 0,
["Evasion"] = 45,
["Gear:Evasion"] = 0,
["Mana"] = 946,
["EnergyShieldOnSpellBlock"] = 0,
["AvoidProjectilesChance"] = 0,
["ColdGuardEffectiveLife"] = 69,
["ColdSpellDamageChance"] = 25,
["FireGuardEffectivePool"] = 0,
["PhysicalEnergyShieldBypass"] = 0,
["LightningTakenDotMult"] = 0.24,
["TotalMin"] = 38894.68,
["ChaosTakenReflect"] = 1,
["CullPercent"] = 10,
["ColdGuardEffectivePool"] = 0,
["BlitzCharges"] = 0,
["PhysicalPhysicalBaseTakenHitMult"] = 0.97,
["LightningGuardEffectiveLife"] = 69,
["ChaosResistOverCap"] = 0,
["BlindAvoidChance"] = 0,
["FireMaximumHitTaken"] = 29915,
["Ward"] = 0,
["ManaRecoveryRateMod"] = 1,
["RemovablePowerCharges"] = 5,
["FireGuardEffectiveLife"] = 69,
["LifeRecoveryRateMod"] = 1,
["LightningNumberOfHits"] = 30.2703,
["CritMultiplier"] = 6.1,
["ManaReserved"] = 852,
["ChillDurationMod"] = 1,
["LifeRegen"] = 1.348,
["LightningTotalPool"] = 5983,
["ColdManaEffectiveLife"] = 69,
["AnyBypass"] = true,
["ChaosTotalPool"] = 5983,
["EnergyShieldRecoveryRateMod"] = 1,
["MeleeNotHitChance"] = 0,
["ManaLeechInstant"] = 0,
["PhysicalManaEffectiveLife"] = 69,
["ChaosTakenDotMult"] = 1.25,
["FireTakenDotMult"] = 0.2,
["LightningTakenHit"] = 1,
}

}