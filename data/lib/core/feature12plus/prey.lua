local config = {
	isThirdSlotFree = false
}

	local CONST = {
		DATA_STATE = {
			REROLL_NEW_GRID = 0,
			INACTIVE = 1,
			ACTIVE = 2,
			GRID_MONSTER_LIST = 3,
			SELECTION_CHANGE_MONSTER = 4,
			LIST_SELECTION = 5,
			WILD_CARD_SELECTION = 6
		},
		ACTION_MSG = {
			NEW_GRID = 0,
			BONUS_REROLL = 1,
			ACCEPT = 2,
			LIST_SELECTION = 3
		},
		SLOT = {
			FIRST = 0,
			SECOND = 1,
			THIRD = 2,

			SIZE = 3
		},
		OPTION = {
			NONE = 0,
			AUTOROLL = 1,
			LOCKED = 2
		},
		BONUS_TYPE = {
			DAMAGE = 0,
			DEFENSE = 1,
			EXP = 2,
			LOOT = 3
		},
		BONUS_STEP = {
			DAMAGE = 2,
			DEFENSE = 2,
			EXP = 3,
			LOOT = 3
		},
		BONUS_BASE = {
			DAMAGE = 5,
			DEFENSE = 10,
			EXP = 0,
			LOOT = 10
		},
		BONUS_VALUE = {
			START = 1,
			END = 10
		},
		MONSTER_DIFFICULT = {
			EASY = 0,
			MEDIUM = 1,
			HARD = 2,
			EXTREME = 3
		},
		MONSTER_GRID_TYPE = {},
		PREY_GRID_SIZE = 9,
		VALIDATION = {
			OK = 0,
			NOT_ENOUGH_MONSTERS_IN_GRIDS = 1,
			FAIL = 2
		},
		DURATION = 2 * 60 * 60,
		FREE_REROLL_TIME = 20 * 60 * 60,
		REROLL_WILDCARDS_COST = 1,
		SELECT_WILDCARDS_COST = 5
	}

	do
		CONST.MONSTER_GRID_TYPE[CONST.MONSTER_DIFFICULT.EASY] = {
			FROM = 0,
			TO = 99,
			GRID = {
				EASY = 3,
				MEDIUM = 3,
				HARD = 2,
				EXTREME = 1
			}
		}
		CONST.MONSTER_GRID_TYPE[CONST.MONSTER_DIFFICULT.MEDIUM] = {
			FROM = 100,
			TO = 299,
			GRID = {
				EASY = 1,
				MEDIUM = 3,
				HARD = 3,
				EXTREME = 2
			}
		}
		CONST.MONSTER_GRID_TYPE[CONST.MONSTER_DIFFICULT.HARD] = {
			FROM = 300,
			TO = 499,
			GRID = {
				EASY = 1,
				MEDIUM = 2,
				HARD = 3,
				EXTREME = 3
			}
		}
		CONST.MONSTER_GRID_TYPE[CONST.MONSTER_DIFFICULT.EXTREME] = {
			FROM = 500,
			-- 2642245 is max level reachable using TFS formula
			TO = 2642245,
			GRID = {
				EASY = 1,
				MEDIUM = 1,
				HARD = 3,
				EXTREME = 4
			}
		}
	end

	-- TODO: note: no exclusive monsters handled

local monsters = {
	[CONST.MONSTER_DIFFICULT.EASY] = {},
	[CONST.MONSTER_DIFFICULT.MEDIUM] = {},
	[CONST.MONSTER_DIFFICULT.HARD] = {},
	[CONST.MONSTER_DIFFICULT.EXTREME] = {},
	all = {}
}

local players = {}

local networkMsgMonsterList ={
	msg = nil,
	costPos = 0
}

-- PRIVATE API --

local function initMonstersArray()
	local playerMonsters = {}
	for i = 1, CONST.PREY_GRID_SIZE, 1 do
		table.insert(playerMonsters, i, 0)
	end

	return playerMonsters
end

local function initPlayerSlotTemplate()
	local template = {
		raceId = 0,
		option = CONST.OPTION.NONE,
		bonusType = CONST.BONUS_TYPE.DAMAGE,
		bonusValue = 1,
		freeRerollTime = 0,
		preyDuration = 0,
		dataState = CONST.DATA_STATE.INACTIVE,
		monsters = initMonstersArray()
	}

	return template
end

local function initPlayerTemplate(player)
	players[player:getGuid()] = {
		slots = {
			[CONST.SLOT.FIRST] = initPlayerSlotTemplate(),
			[CONST.SLOT.SECOND] = initPlayerSlotTemplate(),
			[CONST.SLOT.THIRD] = initPlayerSlotTemplate()
		},
		checksum = 0
	}
end

local function prepareMonsterListNetworkMessage()
	local msg = NetworkMessage()
	msg:addByte(0xE8)
	msg:addByte(0) -- slot, will be changed in future calls
	msg:addByte(CONST.DATA_STATE.LIST_SELECTION)
	msg:addU16(#monsters.all)

	for i = 1, #monsters.all, 1 do
		local mType = monsters.all[i]
		msg:addU16(mType:getBestiaryInfo().raceId)
	end

	networkMsgMonsterList.costPos = msg:tell()
	msg:addU32(0) -- cost, will be updated in future call
	msg:addByte(0) -- option, will be updated in future call

	networkMsgMonsterList.msg = msg

	print("prepare msg" .. networkMsgMonsterList.msg:len())
end

local function updateMonsterListMsg(slot, cost, option)
	if not networkMsgMonsterList.msg then
		return
	end

	networkMsgMonsterList.msg:seek(1)
	print(networkMsgMonsterList.msg:tell())
	networkMsgMonsterList.msg:addByte(slot)
	networkMsgMonsterList.msg:seek(networkMsgMonsterList.costPos)
	print(networkMsgMonsterList.costPos, networkMsgMonsterList.msg:tell())
	networkMsgMonsterList.msg:addU32(cost)
	networkMsgMonsterList.msg:addByte(option)
	print("update msg2", networkMsgMonsterList.msg:len())
end

function getPlayerData(player)
	return players[player:getGuid()]
end

local function getPlayerSlotData(player, slot)
	if not players[player:getGuid()] then
		return nil
	end

	if not players[player:getGuid()].slots then
		return nil
	end

	return players[player:getGuid()].slots[slot]
end

local function isRelevantGrid(grid, level)
	if grid.FROM <= level and grid.TO >= level then
		return true
	end

	return false
end

local function getMonsterByGridType(level)
	for _, grid in ipairs(CONST.MONSTER_GRID_TYPE) do
		if isRelevantGrid(grid, level) then
			return grid
		end
	end

	return nil
end

local function getMonstersByDifficult(difficult)
	return monsters[difficult]
end

local function getAllMonstersCount()
	local count = 0
	for _, monstersList in pairs(monsters) do
		count = count + #monstersList
	end

	return count
end

local function setPreySelectedMonsterRaceId(player, slot, raceId)
	local data = getPlayerSlotData(player, slot)
	if not data then
		print("setPreySelectedMonsterRaceId no data")
		return false
	end

	data.raceId = raceId
	data.preyDuration = CONST.DURATION

	print("setPreySelectedMonsterRaceId", data.raceId)
	print(data.preyDuration)
	return true
end

local function removePreyActivedMonsterRaceId(player, slot)
	local data = getPlayerSlotData(player, slot)
	if not data then
		return false
	end

	data.raceId = 0
	data.preyDuration = 0
	data.dataState = CONST.DATA_STATE.INACTIVE
	return true
end

-- Validate if in each monster type diffficult array is enaught monsters
-- note: Grid size multipled by CONST.SLOT.SIZE, checks if there are enough monsters to fill all the slots
local function canAssignMonstersToAllGrids(grid)
	local isValidGrid = true

	if not ((grid.GRID.EASY * CONST.SLOT.SIZE) <= #getMonstersByDifficult(CONST.MONSTER_DIFFICULT.EASY)) then
		isValidGrid = false
	end

	if not ((grid.GRID.MEDIUM * CONST.SLOT.SIZE) <= #getMonstersByDifficult(CONST.MONSTER_DIFFICULT.MEDIUM)) then
		isValidGrid = false
	end

	if not ((grid.GRID.HARD * CONST.SLOT.SIZE) <= #getMonstersByDifficult(CONST.MONSTER_DIFFICULT.HARD)) then
		isValidGrid = false
	end

	if not ((grid.GRID.EXTREME * CONST.SLOT.SIZE) <= #getMonstersByDifficult(CONST.MONSTER_DIFFICULT.EXTREME)) then
		isValidGrid = false
	end

	if isValidGrid == false then
		if getAllMonstersCount() < CONST.PREY_GRID_SIZE * CONST.SLOT.SIZE then
			return CONST.VALIDATION.FAIL
		end
		return CONST.VALIDATION.NOT_ENOUGH_MONSTERS_IN_GRIDS
	end

	return CONST.VALIDATION.OK
end

-- Cipsoft client specific, 3 slots
-- Returns freeRerollTime
local function loadPlayerSlotData(player, slot)
	local data = getPlayerSlotData(player, slot)
	if not data then
		return -1
	end

	local storageStart = 0
	if slot == CONST.SLOT.FIRST then
		storageStart = PlayerStorageKeys.preySlot1Monster
	elseif slot == CONST.SLOT.SECOND then
		storageStart = PlayerStorageKeys.preySlot2Monster
	elseif slot == CONST.SLOT.THIRD then
		storageStart = PlayerStorageKeys.preySlot3Monster
	end

	data.raceId = math.max(0, player:getStorageValue(storageStart) or 0)
	data.bonusType = math.max(0, player:getStorageValue(storageStart + 1) or 0)
	data.bonusValue = math.max(0, player:getStorageValue(storageStart + 2) or 0)
	data.dataState = math.max(0, player:getStorageValue(storageStart + 3) or 0)
	data.freeRerollTime = math.max(0, player:getStorageValue(storageStart + 4) or 0)
	data.preyDuration = math.max(0, player:getStorageValue(storageStart + 5) or 0)
	data.option = math.max(0, player:getStorageValue(storageStart + 6) or 0)
	for i = 1, CONST.PREY_GRID_SIZE, 1 do
		data.monsters[i] = math.max(0, player:getStorageValue(storageStart + 5 + i) or 0)
	end

	return data.freeRerollTime
end

-- simply checksum
local function generateChecksum(player)
	local data = getPlayerData(player)
	if not player then
		return -1
	end

	local sum = 0

	for _, slot in ipairs(data.slots) do
		for i = 1, CONST.SLOT.SIZE, 1 do
			sum = sum + slot.monsters[i]
		end
	end

	return sum
end

-- Cipsoft client specific, 3 slots
local function loadPlayerData(player)
	local data = getPlayerData(player)
	if data then
		if data.checksum == -1 or data.checksum == nil then
			return false
		elseif data.checksum == player:getStorageValue(PlayerStorageKeys.preyChecksum) then
			--return true
		end
	end

	-- used in case of first init
	local assignedMonsters = {}

	for i = 0, CONST.SLOT.SIZE -1, 1 do
		if loadPlayerSlotData(player, i) <= 0 then
			if getPlayerSlotData(player, i).freeRerollTime == 0 then
				player:preparePreyMonsterSelectionGrid(i, assignedMonsters)
			else
				return false
			end
		end
	end
	return true
end

-- Cipsoft client specific, 3 slots
local function savePlayerSlotData(player, slot)
	local data = getPlayerSlotData(player, slot)
	if not data then
		return false
	end

	local storageStart = 0
	if slot == CONST.SLOT.FIRST then
		storageStart = PlayerStorageKeys.preySlot1Monster
	elseif slot == CONST.SLOT.SECOND then
		storageStart = PlayerStorageKeys.preySlot2Monster
	elseif slot == CONST.SLOT.THIRD then
		storageStart = PlayerStorageKeys.preySlot3Monster
	end

	player:setStorageValue(storageStart, data.raceId)
	player:setStorageValue(storageStart + 1, data.bonusType)
	player:setStorageValue(storageStart + 2, data.bonusValue)
	player:setStorageValue(storageStart + 3, data.dataState)
	player:setStorageValue(storageStart + 4, data.freeRerollTime)
	player:setStorageValue(storageStart + 5, data.preyDuration)
	player:setStorageValue(storageStart + 6, data.option)
	for i = 1, CONST.PREY_GRID_SIZE, 1 do
		player:setStorageValue(storageStart + 5 + i, data.monsters[i])
	end

	return true
end

-- Cipsoft client specific, 3 slots
local function savePlayerData(player)
	local data = getPlayerData(player)
	if not data then
		return false
	end

	local checksum = generateChecksum(player)
	data.checksum = checksum
	player:setStorageValue(PlayerStorageKeys.preyChecksum, checksum)

	for i = 0, CONST.SLOT.SIZE -1, 1 do
		if not savePlayerSlotData(player, i) then
			return false
		end
	end
	return true
end

local function rollBonusValue(oldBonus)
	return math.random(math.max(1, oldBonus), CONST.BONUS_VALUE.END)
end

local function rollBonusType()
	return math.random(CONST.BONUS_TYPE.DAMAGE, CONST.BONUS_TYPE.LOOT)
end

local function getRerollPrice(level)
	return math.max(150, 150 * level)
end

local function isValidSlot(slot)
	if slot >= CONST.SLOT.FIRST and slot <= CONST.SLOT.THIRD then
		return true
	end

	return false
end

local function getRandomByDifficultMonster(difficult)
	local mTypes = monsters[difficult]
	if not mTypes then
		return nil
	end

	return mTypes[math.random(#mTypes)]
end

local function getRandomFromAllMonsters()
	return monsters.all[math.random(#monsters.all)]
end

local function isMonsterAlreadyRolled(monsterType, assignedMonstersArray)
	for _, mType in pairs(assignedMonstersArray) do
		if mType == monsterType then
			return true
		end
	end
	return false
end

-- PUBLIC API --
Prey = {}

Prey.getConfig = function()
	return config
end

Prey.getConst = function()
	return CONST
end

-- NOTE: Lack of monster with 4 and 5 stars on the TFS map
Prey.initMonsters = function()
	for _, mType in pairs(Game.getMonsterTypes()) do
		if mType:getBestiaryInfo().raceId > 0 and mType:getExperience() then
			if mType:getBestiaryInfo().difficulty == 0 or mType:getBestiaryInfo().difficulty == 1 then
				table.insert(monsters[CONST.MONSTER_DIFFICULT.EASY], mType)
				table.insert(monsters.all, mType)
			elseif mType:getBestiaryInfo().difficulty == 2 then
				table.insert(monsters[CONST.MONSTER_DIFFICULT.MEDIUM], mType)
				table.insert(monsters.all, mType)
			elseif mType:getBestiaryInfo().difficulty == 3 then
				table.insert(monsters[CONST.MONSTER_DIFFICULT.HARD], mType)
				table.insert(monsters.all, mType)
			elseif mType:getBestiaryInfo().difficulty == 4 then
				table.insert(monsters[CONST.MONSTER_DIFFICULT.EXTREME], mType)
				table.insert(monsters.all, mType)
			end
		end
	end
end

Prey.initNetworkMsg = function()
	prepareMonsterListNetworkMessage()
end

do
	Prey.initMonsters()
	Prey.initNetworkMsg()

end

function Player.setPreySelectedMonsterIndex(self, slot, index)
	local data = getPlayerSlotData(self, slot)
	if not data then
		return false
	end
	print("setPreySelectedMonsterIndex",data.monsters[index + 1])
	return setPreySelectedMonsterRaceId(self, slot, data.monsters[index + 1])
end

function Player.getPreyWildcards(self, slot)
	return math.max(0, self:getStorageValue(PlayerStorageKeys.preyWildcards) or 0)
end

function Player.isPreySlotUnlocked(self, slot)
	if slot == CONST.SLOT.FIRST then
		return true
	elseif slot == CONST.SLOT.SECOND and (self:isPremium() or math.max(0, self:getStorageValue(PlayerStorageKeys.preySecondSlotUnlocked) or 0) == 1) then
		return false
	elseif slot == CONST.SLOT.THIRD and math.max(0, self:getStorageValue(PlayerStorageKeys.preySecondSlotUnlocked) or 0) == 1 then
		return true
	end

	return false
end

function Player.resetPreyDurationTime(self, slot)
	local data = getPlayerSlotData(self, slot)
	if not data then
		return false
	end

	data.preyDuration = CONST.DURATION

	return true
end

function Player.removePreyDurationTime(self, slot, time)
	local data = getPlayerSlotData(self, slot)
	if not data then
		return false
	end

	data.preyDuration = data.preyDuration - time

	return true
end

function Player.getPreyDataState(self, slot)
	local data = getPlayerSlotData(self, slot)
	if not data then
		return CONST.DATA_STATE.INACTIVE
	end

	return data.dataState
end

function Player.setPreyDataState(self, slot, dataState)
	local data = getPlayerSlotData(self, slot)
	if not data then
		return false
	end

	data.dataState = dataState

	return true
end

function Player.isPreyDurationExpired(self, slot)
	local data = getPlayerSlotData(self, slot)
	if not data then
		return false
	end

	return data.preyDuration <= 0
end

function Player.resetPreyMonstersSlot(self, slot)
	local data = getPlayerSlotData(self, slot)
	if not data then
		return false
	end

	data.monsters = initMonstersArray()
	return true
end

function Player.resetPreyAllSlots(self)
	for i = 0, CONST.SLOT.SIZE - 1, 1 do
		self:resetPreyMonstersSlot(i)
	end
end

function Player.getPreyFreeRerollTimeout(self, slot)
	if not isValidSlot(slot) then
		return -1
	end

	local data = getPlayerSlotData(self, slot)
	if not data then
		return -1
	end

	return data.freeRerollTime
end

function Player.isPreySlotRerollExpired(self, slot)
	if not isValidSlot(slot) then
		return -1
	end

	local data = getPlayerSlotData(self, slot)
	if not data then
		return -1
	end

	return math.max(0, data.freeRerollTime - os.time()) == 0
end

function Player.preparePreyMonsterSelectionGrid(self, slot, alreadyAssignedMonsters)
	if not isValidSlot(slot) then
		return false
	end

	local grid = getMonsterByGridType(self:getLevel())
	if not grid then
		return false
	end

	local err = canAssignMonstersToAllGrids(grid)

	if err == CONST.VALIDATION.FAIL then
		return false
	end

	local playerSlotData = getPlayerSlotData(self, slot)
	if not playerSlotData then
		return false
	end

	local i = 1
	for _ = 1, grid.GRID.EASY, 1 do
		if err == CONST.VALIDATION.OK then
			local rollMonster
			repeat
				rollMonster = getRandomByDifficultMonster(CONST.MONSTER_DIFFICULT.EASY)
				if not rollMonster then
					return false
				end
			until not isMonsterAlreadyRolled(rollMonster, alreadyAssignedMonsters)
			table.insert(alreadyAssignedMonsters, rollMonster)
			playerSlotData.monsters[i] = rollMonster:getBestiaryInfo().raceId
		else
			local rollMonster
			repeat
				rollMonster = getRandomFromAllMonsters()
				if not rollMonster then
					return false
				end
			until not isMonsterAlreadyRolled(rollMonster, alreadyAssignedMonsters)
			table.insert(alreadyAssignedMonsters, rollMonster)
			playerSlotData.monsters[i] = rollMonster:getBestiaryInfo().raceId
		end
		i = i + 1
	end

	for _ = 1, grid.GRID.MEDIUM, 1 do
		if err == CONST.VALIDATION.OK then
			local rollMonster
			repeat
				rollMonster = getRandomByDifficultMonster(CONST.MONSTER_DIFFICULT.MEDIUM)
				if not rollMonster then
					return false
				end
			until not isMonsterAlreadyRolled(rollMonster, alreadyAssignedMonsters)
			table.insert(alreadyAssignedMonsters, rollMonster)
			playerSlotData.monsters[i] = rollMonster:getBestiaryInfo().raceId
		else
			local rollMonster
			repeat
				rollMonster = getRandomFromAllMonsters()
				if not rollMonster then
					return false
				end
			until not isMonsterAlreadyRolled(rollMonster, alreadyAssignedMonsters)
			table.insert(alreadyAssignedMonsters, rollMonster)
			playerSlotData.monsters[i] = rollMonster:getBestiaryInfo().raceId
		end
		i = i + 1
	end

	for _ = 1, grid.GRID.HARD, 1 do
		if err == CONST.VALIDATION.OK then
			local rollMonster
			repeat
				rollMonster = getRandomByDifficultMonster(CONST.MONSTER_DIFFICULT.HARD)
				if not rollMonster then
					return false
				end
			until not not isMonsterAlreadyRolled(rollMonster, alreadyAssignedMonsters)
			table.insert(alreadyAssignedMonsters, rollMonster)
			playerSlotData.monsters[i] = rollMonster:getBestiaryInfo().raceId
		else
			local rollMonster
			repeat
				rollMonster = getRandomFromAllMonsters()
				if not rollMonster then
					return false
				end
			until not isMonsterAlreadyRolled(rollMonster, alreadyAssignedMonsters)
			table.insert(alreadyAssignedMonsters, rollMonster)
			playerSlotData.monsters[i] = rollMonster:getBestiaryInfo().raceId
		end
		i = i + 1
	end

	for _ = 1, grid.GRID.EXTREME, 1 do
		if err == CONST.VALIDATION.OK then
			local rollMonster
			repeat
				rollMonster = getRandomByDifficultMonster(CONST.MONSTER_DIFFICULT.EXTREME)
				if not rollMonster then
					return false
				end
			until not isMonsterAlreadyRolled(rollMonster, alreadyAssignedMonsters)
			table.insert(alreadyAssignedMonsters, rollMonster)
			playerSlotData.monsters[i] = rollMonster:getBestiaryInfo().raceId
		else
			local rollMonster
			repeat
				rollMonster = getRandomFromAllMonsters()
				if not rollMonster then
					return false
				end
			until not isMonsterAlreadyRolled(rollMonster, alreadyAssignedMonsters)
			table.insert(alreadyAssignedMonsters, rollMonster)
			playerSlotData.monsters[i] = rollMonster:getBestiaryInfo().raceId
		end
		i = i + 1
	end

	playerSlotData.bonusType = rollBonusType()
	playerSlotData.bonusValue = rollBonusValue(1)

	playerSlotData.state = CONST.OPTION.SELECTION
	playerSlotData.freeRerollTime = os.time() + CONST.FREE_REROLL_TIME
	return true
end

function Player.prepareMonstersGrids(self)
	self:resetPreyAllSlots()

	local assignedMonsters = {}
	for i = 0, CONST.SLOT.SIZE -1, 1 do
		if self:preparePreyMonsterSelectionGrid(CONST.SLOT.FIRST, assignedMonsters) == false then
			self:resetPreyAllSlots()
			return false
		end
	end

	return true
end

function Player.sendRerollPrice(self)
	local msg = NetworkMessage()
	msg:addByte(0xE9)
	msg:addU32(getRerollPrice(self:getLevel()))
	msg:addByte(CONST.REROLL_WILDCARDS_COST)
	msg:addByte(CONST.SELECT_WILDCARDS_)
	-- hunting tasks
	msg:addU32(0) -- reroll price
	msg:addU32(0) -- reroll price?
	msg:addByte(0)
	msg:addByte(0)

	msg:sendToPlayer(self)
	msg:delete()
end

function Player.sendPreyMonsterSelectionGrid(self, slot)
	if not isValidSlot(slot) then
		return false
	end

	local msg = NetworkMessage()
	msg:addByte(0xE8)
	msg:addByte(slot)
	msg:addByte(CONST.DATA_STATE.GRID_MONSTER_LIST)
	msg:addByte(CONST.PREY_GRID_SIZE)

	local slotData = getPlayerSlotData(self, slot)
	if not slotData then
		msg:delete()
		return false
	end

	for i = 1, CONST.PREY_GRID_SIZE, 1 do
		local mType = MonsterType(slotData.monsters[i])
		if not mType then
			msg:delete()
			return false
		end
		msg:addString(mType:name())
		local outfit = mType:getOutfit()
		msg:addU16(outfit.lookType)
		if outfit.lookType == 0 then
			msg:addU16(mType.lookTypeEx);
		else
			msg:addByte(outfit.lookHead)
			msg:addByte(outfit.lookBody)
			msg:addByte(outfit.lookLegs)
			msg:addByte(outfit.lookFeet)
			msg:addByte(outfit.lookAddons)
		end
	end

	msg:addU32(math.max(0, slotData.freeRerollTime - os.time()))
    msg:addByte(1)
	msg:sendToPlayer(self)
	msg:delete()
	return true
end

-- NETWORK MESSAGE
function Player.sendPreyLockedSlot(self, slot, isPremium)
	if not isValidSlot(slot) then
		return false
	end

	local msg = NetworkMessage()
	msg:addByte(0xE8)
	msg:addByte(slot)
	msg:addByte(CONST.DATA_STATE.LOCKED)
	msg:addByte(isPremium)
	msg:addU32(0)
	msg:addByte(CONST.OPTION.LOCKED)
	msg:sendToPlayer(self)
	msg:delete()
	return true
end

function Player.sendPreySelectedMonster(player, slot, raceId, bonusType, bonusValue)
	if not isValidSlot(slot) then
		return false
	end

	local mType = MonsterType(raceId)
	if not mType then
		return false
	end

	local msg = NetworkMessage()
	msg:addByte(0xE8)
	msg:addByte(slot)
	msg:addByte(CONST.DATA_STATE.ACTIVE)
	msg:addString(mType:name());
	local outfit = mType:getOutfit()
	msg:addU16(outfit.lookType)
	if outfit.lookType == 0 then
		msg.addU16(mType.lookTypeEx)
	else
		msg:addByte(outfit.lookHead)
		msg:addByte(outfit.lookBody)
		msg:addByte(outfit.lookLegs)
		msg:addByte(outfit.lookFeet)
		msg:addByte(outfit.lookAddons)
		msg:addByte(bonusType)
		msg:addU16(25) -- percent
		msg:addByte(bonusValue); -- bonus rarity
		msg:addU16(7200) -- bonus time left in secounds

	end
	msg:addU32(7201) -- time to reroll
	msg:addByte(CONST.OPTION.LOCKED)
	msg:sendToPlayer(player)
	msg:delete()

	return true
end

function Player.sendPreyAllSlotsData(self)
	for slot = 0, CONST.SLOT.SIZE -1, 1 do
		if self:isPreySlotUnlocked(slot) then
			local data = getPlayerSlotData(self, slot)
			if not data then
				return
			end
			if data.dataState == CONST.DATA_STATE.ACTIVE then
				self:sendPreySelectedMonster(slot, data.raceId, data.bonusType, data.bonusValue)
			else
				self:sendPreyMonsterSelectionGrid(slot)

			end
		else
			self:sendPreyLockedSlot(slot, self:isPremium())
		end
	end
	self:sendResourceBalance(RESOURCE_PREY_WILDCARDS, self:getPreyWildcards())
end

function Player.sendPreyListSelection(self, slot)
	if not networkMsgMonsterList.msg then
		return
	end

	local slotData = getPlayerSlotData(self, slot)
	if not slotData then
		return
	end

	updateMonsterListMsg(slot, math.max(0, slotData.freeRerollTime - os.time()), slotData.option)

	--networkMsgMonsterList.msg:sendToPlayer(self)
end

function Player.loadPreyData(self)
	if not getPlayerData(self) then
		initPlayerTemplate(self)
	end

	--loadPlayerData(self)
end

function Player.savePreyData(self)
	if not getPlayerData(self) then
		initPlayerTemplate(self)
	end

	savePlayerData(self)
end
