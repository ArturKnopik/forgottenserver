local config = {
	isThirdSlotFree = false
}

local CONST = {
    DATA_STATE = {
        LOCKED = 0,
        INACTIVE = 1,
        ACTIVE = 2,
        SELECTION = 3,
        SELECTION_CHANGE_MONSTER = 4,
        LIST_SELECTION = 5,
        WILD_CARD_SELECTION = 6
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
        NOT_ENAUGHT_MONSTERS_IN_GRIDS = 1,
        FAIL = 2
    }
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

-- in case of reload, on startup is doing nothing
do
	for _, mType in pairs(Game.getMonsterTypes()) do
		if mType:getBestiaryInfo().raceId then
			if mType:getBestiaryInfo().difficulty == 1 or mType:getBestiaryInfo().difficulty == 2 then
				table.insert(monsters[CONST.MONSTER_DIFFICULT.EASY], mType)
				table.insert(monsters.all, mType)
			elseif mType:getBestiaryInfo().difficulty == 3 then
				table.insert(monsters[CONST.MONSTER_DIFFICULT.MEDIUM], mType)
				table.insert(monsters.all, mType)
			elseif mType:getBestiaryInfo().difficulty == 4 then
				table.insert(monsters[CONST.MONSTER_DIFFICULT.HARD], mType)
				table.insert(monsters.all, mType)
			elseif mType:getBestiaryInfo().difficulty == 5 then
				table.insert(monsters[CONST.MONSTER_DIFFICULT.EXTREME], mType)
				table.insert(monsters.all, mType)
			end
		end
	end
end

local players = {}

-- PRIVATE API --

local function initMonstersArray()
    monsters = {}
    for i = 1, CONST.PREY_GRID_SIZE, 1 do
        table.insert(monsters, i, 0)
    end

    return monsters
end

local function initPlayerSlotTemplate()
    local template =  {
        raceId = 0,
        option = CONST.OPTION.NONE,
        bonusType = CONST.BONUS_TYPE.DAMAGE,
        bonusValue = 0,
        freeRerollTime = 0,
        dataState = CONST.DATA_STATE.INACTIVE,
        monsters = initMonstersArray()
    }

    return template
end

local function initPlayerTemplate(player)
    players[player:getGuid()] = {
        [CONST.SLOT.FIRST] = initPlayerSlotTemplate(),
        [CONST.SLOT.SECOND] = initPlayerSlotTemplate(),
        [CONST.SLOT.THIRD] = initPlayerSlotTemplate(),
    }
end

local function getPlayerData(player)
    return players[player:getGuid()]
end

local function getPlayerSlotData(player, slot)
    return players[player:getGuid()][slot]
end

local function isRelevantGrid(grid, level)
    if grid.FROM >= level and grid.TO <= level then
        return true
    end

    return false
end

local function getMonsterGridType(level)
    for _, grid in ipairs(CONST.MONSTER_GRID_TYPE) do
        if isRelevantGrid(grid, level) then
            return grid
        end
    end

    return nil
end

local function getMonstersByDifficults(difficult)
    return monsters[difficult]
end

local function getAllMonstersCount()
    local count = 0
    for _, monsters in pairs(monsters) do
        count = count + #monsters
    end

    return count
end

-- Validate if in each monster type diffficult array is enaught monsters
-- note: Grid size multipled by CONST.SLOT.SIZE, checks if there are enough monsters to fill all the slots
local function canAssignMonstersToAllGrids(grid)
    local isValidGrid = true
    if not grid.GRID.EASY * CONST.SLOT.SIZE <= #getMonstersByDifficults(CONST.MONSTER_DIFFICULT.EASY) then
        print("fail easy")
        isValidGrid = false
    end

    if not grid.GRID.MEDIUM * CONST.SLOT.SIZE <= #getMonstersByDifficults(CONST.MONSTER_DIFFICULT.MEDIUM) then
        print("fail medium")
        isValidGrid = false
    end

    if not grid.GRID.HARD * CONST.SLOT.SIZE <= #getMonstersByDifficults(CONST.MONSTER_DIFFICULT.HARD) then
        print("fail hard")
        isValidGrid = false
    end

    if not grid.GRID.EXTREME * CONST.SLOT.SIZE <= #getMonstersByDifficults(CONST.MONSTER_DIFFICULT.EXTREME) then
        print("fail extreme")
        isValidGrid = false
    end

    if isValidGrid == false then
        if getAllMonstersCount() < CONST.PREY_GRID_SIZE * CONST.SLOT.SIZE then
            return CONST.VALIDATION.FAIL
        end
        return CONST.VALIDATION.NOT_ENAUGHT_MONSTERS_IN_GRIDS
    end

    return CONST.VALIDATION.OK
end

local function loadPlayerSlotData(player, slot)
    local data = getPlayerSlotData(player, slot)

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
    data.option = math.max(0, player:getStorageValue(storageStart + 3) or 0)
    data.freeRerollTime = math.max(0, player:getStorageValue(storageStart + 4) or 0)
    for i = 1, CONST.PREY_GRID_SIZE, 1 do
        data.monsters[i] = math.max(0, player:getStorageValue(storageStart + 4 + i ) or 0)
    end
end

local function loadPlayerData(player)
    loadPlayerSlotData(player, CONST.SLOT.FIRST)
    loadPlayerSlotData(player, CONST.SLOT.SECOND)
    loadPlayerSlotData(player, CONST.SLOT.THIRD)
end

local function rollBonusValue(oldBonus)
    return math.random(math.max(1, oldBonus), CONST.BONUS_VALUE.END)
end

local function rollBonusType()
    return math.random(CONST.BONUS_TYPE.DAMAGE, CONST.BONUS_TYPE.LOOT)
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

local function isMonsterAlreadyRolled(monsterType, assigendMonstersArray)
    for _, mType in pairs(assigendMonstersArray) do
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
		if mType:getBestiaryInfo().raceId then
			if mType:getBestiaryInfo().difficulty == 1 or mType:getBestiaryInfo().difficulty == 2 then
				table.insert(monsters[CONST.MONSTER_DIFFICULT.EASY], mType)
			elseif mType:getBestiaryInfo().difficulty == 3 then
				table.insert(monsters[CONST.MONSTER_DIFFICULT.MEDIUM], mType)
			elseif mType:getBestiaryInfo().difficulty == 4 then
				table.insert(monsters[CONST.MONSTER_DIFFICULT.HARD], mType)
			elseif mType:getBestiaryInfo().difficulty == 5 then
				table.insert(monsters[CONST.MONSTER_DIFFICULT.EXTREME], mType)
			end
		end
	end
end

function Player.resetPreyMonstersSlot(self, slot)
    local data = getPlayerSlotData(self, slot)
    data.monsters = initMonstersArray()
end

function Player.resetPreyAllSlots(self)
    self:resetPreyMonstersSlot(CONST.SLOT.FIRST)
    self:resetPreyMonstersSlot(CONST.SLOT.SECOND)
    self:resetPreyMonstersSlot(CONST.SLOT.THIRD)
end

function Player.preparePreyMonsterSelectionGrid(self, slot, alreadyAssignedMonsters)
    if not isValidSlot(slot) then
        return false
    end

    local grid = getMonsterGridType(self:getLevel())
    if not grid then
        return false
    end

    local err = canAssignMonstersToAllGrids(grid)

    if err == CONST.VALIDATION.FAIL then
        return false
    end


    local playerSlotData = getPlayerSlotData(self, slot)

    for i = 1, CONST.PREY_GRID_SIZE, 1 do
        for _ = 1, grid.GRID.EASY, 1 do
            if err == CONST.VALIDATION.OK then
                local rollMonster
                repeat
                    rollMonster = getRandomByDifficultMonster(CONST.MONSTER_DIFFICULT.EASY)
                    if not rollMonster then
                        return false
                    end
                until isMonsterAlreadyRolled(rollMonster, alreadyAssignedMonsters) == false
                table.insert(alreadyAssignedMonsters, rollMonster)
                playerSlotData.monsters[i] = rollMonster:getBestiaryInfo().raceId
                i = i + 1
            else
                local rollMonster
                repeat
                    rollMonster = getRandomFromAllMonsters()
                    if not rollMonster then
                        return false
                    end
                until isMonsterAlreadyRolled(rollMonster, alreadyAssignedMonsters) == false
                table.insert(alreadyAssignedMonsters, rollMonster)
                i = i + 1
            end
        end

        for _ = 1, grid.GRID.MEDIUM, 1 do
            if err == CONST.VALIDATION.OK then
                local rollMonster
                repeat
                    rollMonster = getRandomByDifficultMonster(CONST.MONSTER_DIFFICULT.MEDIUM)
                    if not rollMonster then
                        return false
                    end
                until isMonsterAlreadyRolled(rollMonster, alreadyAssignedMonsters) == false
                table.insert(alreadyAssignedMonsters, rollMonster)
                i = i + 1
            else
                local rollMonster
                repeat
                    rollMonster = getRandomFromAllMonsters()
                    if not rollMonster then
                        return false
                    end
                until isMonsterAlreadyRolled(rollMonster, alreadyAssignedMonsters) == false
                table.insert(alreadyAssignedMonsters, rollMonster)
                i = i + 1
            end
        end

        for _ = 1, grid.GRID.HARD, 1 do
            if err == CONST.VALIDATION.OK then
                local rollMonster
                repeat
                    rollMonster = getRandomByDifficultMonster(CONST.MONSTER_DIFFICULT.HARD)
                    if not rollMonster then
                        return false
                    end
                until isMonsterAlreadyRolled(rollMonster, alreadyAssignedMonsters) == false
                table.insert(alreadyAssignedMonsters, rollMonster)
                i = i + 1
            else
                local rollMonster
                repeat
                    rollMonster = getRandomFromAllMonsters()
                    if not rollMonster then
                        return false
                    end
                until isMonsterAlreadyRolled(rollMonster, alreadyAssignedMonsters) == false
                table.insert(alreadyAssignedMonsters, rollMonster)
                i = i + 1
            end
        end

        for _ = 1, grid.GRID.EXTREME, 1 do
            if err == CONST.VALIDATION.OK then
                local rollMonster
                repeat
                    rollMonster = getRandomByDifficultMonster(CONST.MONSTER_DIFFICULT.EXTREME)
                    if not rollMonster then
                        return false
                    end
                until isMonsterAlreadyRolled(rollMonster, alreadyAssignedMonsters) == false
                table.insert(alreadyAssignedMonsters, rollMonster)
                i = i + 1
            else
                local rollMonster
                repeat
                    rollMonster = getRandomFromAllMonsters()
                    if not rollMonster then
                        return false
                    end
                until isMonsterAlreadyRolled(rollMonster, alreadyAssignedMonsters) == false
                table.insert(alreadyAssignedMonsters, rollMonster)
                i = i + 1
            end
        end
    end

    return true
end

function Player.prepareMonstersGrids(self)
    -- TODO: check if time is equal 0, if yes, player require data preparation
    self:resetPreyAllSlots()

    local assigendMonsters = {}
    if self:preparePreyMonsterSelectionGrid(CONST.SLOT.FIRST, assigendMonsters) == false then
        self:resetPreyAllSlots()
        return false
    end
    if self:preparePreyMonsterSelectionGrid(CONST.SLOT.SECOND, assigendMonsters) == false then
        self:resetPreyAllSlots()
        return false
    end
    if self:preparePreyMonsterSelectionGrid(CONST.SLOT.THIRD, assigendMonsters) == false then
        self:resetPreyAllSlots()
        return false
    end

    return true
end

function Player.sendPreyMonsterSelectionGrid(self, slot)
    if not isValidSlot(slot) then
        return false
    end

    local msg = NetworkMessage()
    msg:addByte(0xE8)
    msg:addByte(slot)
    msg:addByte(CONST.DATA_STATE.SELECTION)
    msg:addByte(CONST.PREY_GRID_SIZE)

    local slotData = getPlayerSlotData(self, slot)
    for i = 1, CONST.PREY_GRID_SIZE, 1 do
        local mType = slotData.monsters[i]
        msg:addString(mType:name())
        local outfit = mType:getOutfit()
        local looktype = outfit.lookType
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

    return true
end

function Player.sendPreyAllSlotsData(self, slot)

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
    msg:addByte(isPremium);
    msg:addU32(0)
    msg:addByte(CONST.OPTION.LOCKED)
    msg:sendToPlayer(self)
    msg:delete()
    return true
end

function Player.sendPreySelectedMonster(player, slot, monsterName, bonusType, bonusValue)
    if not isValidSlot(slot) then
        return false
    end

    local mType = MonsterType(monsterName)
    if not mType then
        return false
    end

    local msg = NetworkMessage()
    msg:addByte(0xE8)
    msg:addByte(slot)
    msg:addByte(CONST.DATA_STATE.ACTIVE)
    msg:addString(mType:name());
    local outfit = mType:getOutfit()
    local looktype = outfit.lookType
    msg:addU16(looktype)
    if looktype == 0 then
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

function Player.loadPreyData(self)
    if not getPlayerData(self) then
        initPlayerTemplate(self)
    end

    loadPlayerData(self)
end