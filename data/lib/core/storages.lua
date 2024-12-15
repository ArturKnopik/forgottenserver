--[[
Reserved player storage ranges:
- 300000 to 301000+ reserved for achievements
- 20000 to 21000+ reserved for achievement progress
- 10000000 to 20000000 reserved for outfits and mounts on source
]]--

AccountStorageKeys = {
}

GlobalStorageKeys = {
	cobraBastionFlask = 30000,
}

PlayerStorageKeys = {
	-- Misc:
	annihilatorReward = 30015,
	goldenOutfit = 30016,
	-- empty: 30017
	promotion = 30018,
	delayLargeSeaShell = 30019,
	firstRod = 30020,
	delayWallMirror = 30021,
	-- empty: 30022
	madSheepSummon = 30023,
	crateUsable = 30024,
	-- empty: 30025
	afflictedOutfit = 30026,
	afflictedPlagueMask = 30027,
	afflictedPlagueBell = 30028,
	-- empty: 30029
	-- empty: 30030
	nailCaseUseCount = 30031,
	swampDigging = 30032,
	insectoidCell = 30033,
	-- empty: 30034
	mutatedPumpkin = 30035,

	-- Achievements:
	achievementsTotal = 19999,
	achievementsCounter = 20000,
	achievementsBase = 300000,

	-- Bestiary:
	bestiaryKillsBase = 400000,

	-- Charms: 410000 to 410201
	charmPoints = 410000,
	charmsMonster = 410001,
    charmsUnlocked = 410101,

	-- Bosstiary: 430000 to 450006
	bosstiaryKillsBase = 430000,
	bosstiaryCooldownsBase = 440000,
	bosstiaryPoints = 450000,
	bosstiarySlot1 = 450001,
	bosstiarySlot2 = 450002,
	bosstiaryDay = 450004,
	bosstiaryTodayRemoveDate = 450005,
	bosstiaryTodayRemoveCount = 450006,

	-- Prey: 460000 to 460050
	--[[ Storage structure per slot:
		preySlotXMonster = {NUMBER}
		preySlot1BonusType = preySlotXMonster + 1
		preySlot1BonusValue = preySlotXMonster + 2
		preySlotXDataState = preySlotXMonster + 3
		preySlotXFreeRerollTime = preySlotXMonster + 4
		preySlotXStatus = preySlotXMonster + 5
		preySlotXRolledMonstersStart = preySlotXMonster + 5
		preySlotXRolledMonstersStart = preySlotXRolledMonstersStart + 9(monsters grid size/CONST.PREY_GRID_SIZE)
	]]
	preyWildcards = 460000,
	preyChecksum = 460001,
	preySecondSlotUnlocked = 460002,
	preyThirdSlotUnlocked = 460003,

	preySlot1Monster = 460010,
	preySlot1BonusType = 4600011,
	preySlot1BonusValue = 460012,
	preySlot1DataState = 460013,
	preySlot1FreeRerollTime = 460014,
	preySlot1ActiveRemainingTime = 460015,
	preySlot1Status = 460016,
	preySlot1RolledMonstersStart = 460017,
	preySlot1RolledMonstersEnd = 460026,

	preySlot2Monster = 460030,
	preySlot2BonusType = 460031,
	preySlot2BonusValue = 460032,
	preySlot2DataState = 460033,
	preySlot2FreeRerollTime = 460034,
	preySlot2ActiveRemainingTime = 460035,
	preySlot2Options = 460036,
	preySlot2RolledMonstersStart = 460037,
	preySlot2RolledMonstersEnd = 460046,

	preySlot3Monster = 460050,
	preySlot3BonusType = 460051,
	preySlot3BonusValue = 460052,
	preySlot3DataState = 460053,
	preySlot3FreeRerollTime = 460054,
	preySlot3ActiveRemainingTime = 460055,
	preySlot3Status = 460056,
	preySlot3RolledMonstersStart = 460057,
	preySlot3RolledMonstersEnd = 460066,
}
