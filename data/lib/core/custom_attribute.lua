-- Location
-- data\lib\core\custom_attribute.lua

-- data\lib\core\core.lua
-- put dofile('data/lib/core/custom_attribute.lua')

KOD_Attribute_config = {
	maxSlots = 6,
	allowSameAttribute = false,
	slotCount = "atr_slotCount",
	stotNameBase = "kod_slot_name_",
	slotValueBase = "kod_slot_value_",
	stotPrefixNameBase = "kod_slot_", -- if more slots then itemRarityPrefix items this will generate temp prefix
	rollRarityMultipler = 5,
	slotSubIdBase = 100,
	itemRarityPrefix = {
		[1] = "[Common]",
		[2] = "[Uncommon]",
		[3] = "[Rare]",
		[4] = "[Epic]",
		[5] = "[Legendary]",
		[6] = "[Mythic]",
	},
}
-- CONST
CST = { --- ConSTans
	BASE_COMBAT_STATS = 1,
	BCS_SUBIT = { OFFENCE = 1,	DEFFENCE = 2}, -- Base Combat Stats subid
	ELEMENT_DEFFENCE = 2,
	ELEMENT_OFFENCE = 3,
	COMBAT_SKILLS = 5
}

-- DATA STRUCTURES
KOD_Attribute_PlayersItemStats = {}

KOD_Attribute_slotSubId = {
	[CONST_SLOT_HEAD] = KOD_Attribute_config.slotSubIdBase + CONST_SLOT_HEAD,
	[CONST_SLOT_NECKLACE] = KOD_Attribute_config.slotSubIdBase + CONST_SLOT_NECKLACE,
	[CONST_SLOT_BACKPACK] = KOD_Attribute_config.slotSubIdBase + CONST_SLOT_BACKPACK,
	[CONST_SLOT_ARMOR] = KOD_Attribute_config.slotSubIdBase + CONST_SLOT_ARMOR,
	[CONST_SLOT_RIGHT] = KOD_Attribute_config.slotSubIdBase + CONST_SLOT_RIGHT,
	[CONST_SLOT_LEFT] = KOD_Attribute_config.slotSubIdBase + CONST_SLOT_LEFT,
	[CONST_SLOT_LEGS] = KOD_Attribute_config.slotSubIdBase + CONST_SLOT_LEGS,
	[CONST_SLOT_FEET] = KOD_Attribute_config.slotSubIdBase + CONST_SLOT_FEET,
	[CONST_SLOT_RING] = KOD_Attribute_config.slotSubIdBase + CONST_SLOT_RING,
	[CONST_SLOT_AMMO] = KOD_Attribute_config.slotSubIdBase + CONST_SLOT_AMMO
}

KOD_Attribute_slotTypeValue = {
	[1] = CONST_SLOT_HEAD, -- 1
	[2] = CONST_SLOT_NECKLACE, -- 2
	[3] = CONST_SLOT_BACKPACK, -- 3
	[4] = CONST_SLOT_ARMOR, -- 4
	[5] = CONST_SLOT_RIGHT, -- 5
	[6] = CONST_SLOT_LEFT, -- 6
	[7] = CONST_SLOT_LEGS, -- 7
	[8] = CONST_SLOT_FEET, -- 8
	[9] = CONST_SLOT_RING, -- 9
	[10] = CONST_SLOT_AMMO -- 10
}

local slotBits = {
	[SLOTP_HEAD] = CONST_SLOT_HEAD,
	[SLOTP_NECKLACE] = CONST_SLOT_NECKLACE,
	[SLOTP_BACKPACK] = CONST_SLOT_BACKPACK,
	[SLOTP_ARMOR] = CONST_SLOT_ARMOR,
	[SLOTP_RIGHT] = CONST_SLOT_RIGHT,
	[SLOTP_LEFT] = CONST_SLOT_LEFT,
	[SLOTP_LEGS] = CONST_SLOT_LEGS,
	[SLOTP_FEET] = CONST_SLOT_FEET,
	[SLOTP_RING] = CONST_SLOT_RING,
	[SLOTP_AMMO] = CONST_SLOT_AMMO
}

function rollRarity()
	local maxRollNumber = 1
	local rollChance = {}
	for i = 1, KOD_Attribute_config.maxSlots, 1 do
		rollChance[i] = maxRollNumber
		maxRollNumber = maxRollNumber * 5
	end
	rollChance[#rollChance+1] = maxRollNumber * 5

	local roll = math.random(1, maxRollNumber)
	for i = #rollChance, 1, -1 do
		if roll >= rollChance[i] then
			return #rollChance - i
		end
	end
	return 0
end

local function generateSlotName_Name(slot)
	return KOD_Attribute_config.stotNameBase .. tostring(slot)
end

local function generateSlotName_Value(slot)
	return KOD_Attribute_config.slotValueBase .. tostring(slot)
end

local function getPrefixName(slot)
	if not KOD_Attribute_config.itemRarityPrefix then
		return KOD_Attribute_config.stotPrefixNameBase .. tostring(slot)
	elseif not KOD_Attribute_config.itemRarityPrefix[slot] then
		return KOD_Attribute_config.stotPrefixNameBase .. tostring(slot)
	else
		return KOD_Attribute_config.itemRarityPrefix[slot]
	end
end
-- ITEM FUNCTIONS --

-- slot count
function Item.KOD_getNumberOfSlots(self)

	local slots = self:getCustomAttribute(KOD_Attribute_config.slotCount)

	if slots then
		return slots
	end
	return false
end

function Item.KOD_setNumberOfSlots(self, slotCount)
	if slotCount <= 0 and slotCount > KOD_Attribute_config.maxSlots then
		self:removeCustomAttribute(KOD_Attribute_config.slotCount)
		return false
	end
	local prefixName = getPrefixName(slotCount)

	self:setAttribute(ITEM_ATTRIBUTE_ARTICLE, prefixName)
	self:setCustomAttribute(KOD_Attribute_config.slotCount, slotCount)
	return true
end

--slot name
function Item.KOD_setAttributeSlotName(self, slotIndex, name)
	self:setCustomAttribute(generateSlotName_Name(slotIndex), name)
	return true
end

function Item.KOD_getAttributeSlotName(self, slotIndex)
	local slotname = self:getCustomAttribute(generateSlotName_Name(slotIndex))
	if not slotname then
		return false
	end
	return slotname
end

--add/remove attribute if free slot
function Item.KOD_addAttribute(self, name, value, slotIndex --[[optional]])
	local slotCount = self:KOD_getNumberOfSlots()
	if not slotCount or slotCount <= 0 then
		return false
	end

	if slotIndex and slotIndex > 0 and slotIndex <= slotCount then
		if self:KOD_getAttributeSlotNameAndValue(slotIndex) then
			return false
		else
			self:KOD_setAttributeSlotNameAndValue(slotIndex, name, value)
			return true
		end
	end

	for i = 1, slotCount, 1 do
		local slotData = self:KOD_getAttributeSlotNameAndValue(i)
		if not slotData or not slotData.slotName or not slotData.slotValue then
			self:KOD_setAttributeSlotNameAndValue(i, name, value)
			return true
		end
	end
	return false
end

function Item.KOD_removeAttribute(self, slotIndex)
	self:removeCustomAttribute(generateSlotName_Name(slotIndex))
	self:removeCustomAttribute(generateSlotName_Value(slotIndex))
	return true
end

-- slot value
function Item.KOD_setAttributeSlotValue(self, slotIndex, name)
	self:setCustomAttribute(generateSlotName_Value(slotIndex), name)
	return true
end

function Item.KOD_getAttributeSlotValue(self, slotIndex)
	local slotValue = self:getCustomAttribute(generateSlotName_Value(slotIndex))
	if not slotValue then
		return false
	end
	return slotValue
end

--name and value
function Item.KOD_setAttributeSlotNameAndValue(self, slot, name, value)
	if KOD_Attribute_itemStats[name] then
		if KOD_Attribute_itemStats[name].base then
			self:setAttribute(KOD_Attribute_itemStats[name].base, self:getAttribute(KOD_Attribute_itemStats[name].base) + value)
		end
	end
	self:KOD_setAttributeSlotName(slot, name)
	self:KOD_setAttributeSlotValue(slot, value)
	return true
end

function Item.KOD_getAttributeSlotNameAndValue(self, slotIndex)
	local sn = self:KOD_getAttributeSlotName(slotIndex)
	local sv = self:KOD_getAttributeSlotValue(slotIndex)
	if not sn or not sv then
		return false
	end
	return {slotName = sn, slotValue = sv}
end

-- has attribute
function Item.KOD_hasAttribute(self, attr, itemAttributeCount)
	for i = 1, itemAttributeCount, 1 do
		if self:getCustomAttribute(generateSlotName_Name(i)) == attr then
			return true
		end
	end
	return false
end

function Item.KOD_hasAttributeNameAndValue(self, attr, itemAttributeCount)
	for i = 1, itemAttributeCount, 1 do
		if self:KOD_getCustomAttribute(generateSlotName_Name(i)) == attr then
			return true
		end
	end
	return false
end

function Item.KOD_removeAllAttribute(self)
	local slotCount = self:KOD_getNumberOfSlots()
	if not slotCount or slotCount == 0 then
		return false
	end
	for i = 1, slotCount, 1 do
		self:KOD_removeAttribute(i)
	end
	self:KOD_setNumberOfSlots(0)
	return true
end

function Item.KOD_resetToDefault(self)
	local it = self:getType()
	if not it then
		return false
	end

	self:KOD_removeAllAttribute()
	self:setAttribute(ITEM_ATTRIBUTE_ARTICLE, it:getArticle())
	self:setAttribute(ITEM_ATTRIBUTE_ATTACK, it:getAttack())
	self:setAttribute(ITEM_ATTRIBUTE_DEFENSE, it:getDefense())
	self:setAttribute(ITEM_ATTRIBUTE_EXTRADEFENSE, it:getExtraDefense())
	self:setAttribute(ITEM_ATTRIBUTE_ARMOR, it:getArmor())
	if it:getAttackSpeed() ~= 0 then
		self:setAttribute(ITEM_ATTRIBUTE_ATTACK_SPEED, it:getAttackSpeed())
	else
		self:removeAttribute(ITEM_ATTRIBUTE_ATTACK_SPEED)
	end
	return true
end

local function canAddRollThisAttributeToItem(rolledIndex, item, currentSlot)
	if not rolledIndex or not item or not currentSlot then
		return false
	end

	local rolledValue = KOD_Attribute_itemStats[rolledIndex]
	if item:KOD_hasAttribute(rolledIndex, currentSlot) == true and KOD_Attribute_config.allowSameAttribute == false then
		return false
	end

	if not rolledValue.restricted then
		return true
	end


	local isIncluded = false
	local isExcluded = false

	local include = rolledValue.restricted.include
	if not include then
		isIncluded = true
	else
		if include.weaponType and item:getType():isWeapon() then
			local incWep = include.weaponType
			for i = 1, #incWep, 1 do
				if incWep[i] == item:getType():getWeaponType() then
					isIncluded = true
				end
			end
		end

		if include.slotType then
			local incSl = include.slotType
			for i = 1, #incSl, 1 do
				if incSl[i] == slotBits[item:getType():getSlotPosition()] then
					isIncluded = true
				end
			end
		end
	end

	local exclude = rolledValue.restricted.exclude
	if not exclude then
	else
		if exclude.weaponType and item:getType():isWeapon() then
			local incWep = exclude.weaponType
			for i = 1, #incWep, 1 do
				if incWep[i] == item:getType():getWeaponType() then
					isExcluded = true
				end
			end
		end

		if exclude.slotType then
			local incSl = exclude.slotType
			for i = 1, #incSl, 1 do
				if incSl[i] == slotBits[item:getType():getSlotPosition()] then
					isExcluded = true
				end
			end
		end
	end

	if isIncluded == true and isExcluded == false then
		return true
	else
		return false
	end
end

function Item.KOD_rollIAndSetItemAttributes(self)
	self:KOD_resetToDefault()
	local rolledItemSlots = rollRarity()
	if rolledItemSlots <= 0 then
		return false
	end

	self:KOD_setNumberOfSlots(rolledItemSlots)
	for i = 1, rolledItemSlots, 1 do
		local rolledIndex
		local rolledValue
		repeat
			rolledIndex = math.random(#KOD_Attribute_itemStats)
			rolledValue = KOD_Attribute_itemStats[rolledIndex]
		until(canAddRollThisAttributeToItem(rolledIndex, self, i))

		self:KOD_setAttributeSlotNameAndValue(i, rolledIndex, math.random(rolledValue.attribute.value[1], rolledValue.attribute.value[2]))
	end
	return true
end

-- restiction = true, (false + true)

function KOD_Attribute_onLook(item)
	local tempStr = ""

	if not item:isItem() then
		return tempStr
	end

	local slotCount = item:KOD_getNumberOfSlots()
	if not slotCount or slotCount <= 0 then
		return tempStr
	end

	tempStr = "\nUnique Attribute:"
	for i = 1, slotCount, 1 do
		local slotData = item:KOD_getAttributeSlotNameAndValue(i)
		if not slotData or not slotData.slotName or not slotData.slotValue then
			tempStr = tempStr .. "\n- Empty Slot -"
		else
			if not KOD_Attribute_itemStats[slotData.slotName] then
				tempStr = tempStr .. "\n" .. "- Attribute Disabled -"
			else
				tempStr = tempStr .. "\n" .. KOD_Attribute_itemStats[slotData.slotName].attribute.name
				tempStr = tempStr .. " +" .. slotData.slotValue
				local suffix = KOD_Attribute_itemStats[slotData.slotName].suffix
				if suffix then
					tempStr = tempStr .. suffix
				end
			end
		end
	end
	return tempStr
end

local function calculateBaseStats(type, subType, slotData, playerStats, shouldAdd)
	if not type or not subType or not slotData or not playerStats then
		return false
	end
	if shouldAdd and shouldAdd == true then
		if subType == CST.BCS_SUBIT.OFFENCE then
			if not playerStats.baseStats then
				playerStats.baseStats = {}
			end
			if not playerStats.baseStats.offence then
				playerStats.baseStats.offence = 0
				playerStats.baseStats.offence = playerStats.baseStats.offence + slotData.slotValue
			else
				playerStats.baseStats.offence = playerStats.baseStats.offence + slotData.slotValue
			end
		elseif subType == CST.BCS_SUBIT.DEFFENCE then
			if not playerStats.baseStats then
				playerStats.baseStats = {}
			end
			if not playerStats.baseStats.deffence then
				playerStats.baseStats.deffence = 0
				playerStats.baseStats.deffence = playerStats.baseStats.deffence + slotData.slotValue
			else
				playerStats.baseStats.deffence = playerStats.baseStats.deffence + slotData.slotValue
			end
		end
	else
		if subType == CST.BCS_SUBIT.OFFENCE then
			if not playerStats.baseStats then
				playerStats.baseStats = {}
			end
			if not playerStats.baseStats.offence then
				playerStats.baseStats.offence = 0
				playerStats.baseStats.offence = playerStats.baseStats.offence - slotData.slotValue
			else
				playerStats.baseStats.offence = playerStats.baseStats.offence - slotData.slotValue
			end
		elseif subType == CST.BCS_SUBIT.DEFFENCE then
			if not playerStats.baseStats then
				playerStats.baseStats = {}
			end
			if not playerStats.baseStats.deffence then
				playerStats.baseStats.deffence = 0
				playerStats.baseStats.deffence = playerStats.baseStats.deffence - slotData.slotValue
			else
				playerStats.baseStats.deffence = playerStats.baseStats.deffence - slotData.slotValue
			end
		end
	end
end

local function calculateElementDefence(type, subType, slotData, playerStats, shouldAdd)
	if not type or not subType or not slotData or not playerStats then
		return false
	end
	if shouldAdd and shouldAdd == true then
		if not playerStats.elementDeffence then
			playerStats.elementDeffence = {}
			if not playerStats.elementDeffence[subType] then
				playerStats.elementDeffence[subType] = 0
				playerStats.elementDeffence[subType] = playerStats.elementDeffence[subType] + slotData.slotValue
			else
				playerStats.elementDeffence[subType] = playerStats.elementDeffence[subType] + slotData.slotValue
			end
		else
			if not playerStats.elementDeffence[subType] then
				playerStats.elementDeffence[subType] = 0
				playerStats.elementDeffence[subType] = playerStats.elementDeffence[subType] + slotData.slotValue
			else
				playerStats.elementDeffence[subType] = playerStats.elementDeffence[subType] + slotData.slotValue
			end
		end
	else
		if not playerStats.elementDeffence then
			playerStats.elementDeffence = {}
			if not playerStats.elementDeffence[subType] then
				playerStats.elementDeffence[subType] = 0
				playerStats.elementDeffence[subType] = playerStats.elementDeffence[subType] - slotData.slotValue
			else
				playerStats.elementDeffence[subType] = playerStats.elementDeffence[subType] - slotData.slotValue
			end
		else
			if not playerStats.elementDeffence[subType] then
				playerStats.elementDeffence[subType] = 0
				playerStats.elementDeffence[subType] = playerStats.elementDeffence[subType] - slotData.slotValue
			else
				playerStats.elementDeffence[subType] = playerStats.elementDeffence[subType] - slotData.slotValue
			end
		end
	end
end

local function calculateElementOffence(type, subType, slotData, playerStats, shouldAdd)
	if not type or not subType or not slotData or not playerStats then
		return false
	end
	if shouldAdd and shouldAdd == true then
		if not playerStats.elementOffence then
			playerStats.elementOffence = {}
			if not playerStats.elementOffence[subType] then
				playerStats.elementOffence[subType] = 0
				playerStats.elementOffence[subType] = playerStats.elementOffence[subType] + slotData.slotValue
			else
				playerStats.elementOffence[subType] = playerStats.elementOffence[subType] + slotData.slotValue
			end
		else
			if not playerStats.elementOffence[subType] then
				playerStats.elementOffence[subType] = 0
				playerStats.elementOffence[subType] = playerStats.elementOffence[subType] + slotData.slotValue
			else
				playerStats.elementOffence[subType] = playerStats.elementOffence[subType] + slotData.slotValue
			end
		end
	else
		if not playerStats.elementOffence then
			playerStats.elementOffence = {}
			if not playerStats.elementOffence[subType] then
				playerStats.elementOffence[subType] = 0
				playerStats.elementOffence[subType] = playerStats.elementOffence[subType] - slotData.slotValue
			else
				playerStats.elementOffence[subType] = playerStats.elementOffence[subType] - slotData.slotValue
			end
		else
			if not playerStats.elementOffence[subType] then
				playerStats.elementOffence[subType] = 0
				playerStats.elementOffence[subType] = playerStats.elementOffence[subType] - slotData.slotValue
			else
				playerStats.elementOffence[subType] = playerStats.elementOffence[subType] - slotData.slotValue
			end
		end
	end
end

function KOD_Attribute_onEquipItemInternal(player, item, slot, fromPosition)
	if not player or not item or not slot then
		return false
	end

	local playerStats = KOD_Attribute_PlayersItemStats[player:getGuid()]
	if not playerStats then
		KOD_Attribute_PlayersItemStats[player:getGuid()] = {}
		playerStats = KOD_Attribute_PlayersItemStats[player:getGuid()]
	end

	local slotCount = item:KOD_getNumberOfSlots()
	if not slotCount or slotCount <= 0 then
		return false
	end

	for i = 1, slotCount, 1 do
		local slotData = item:KOD_getAttributeSlotNameAndValue(i)
		if slotData and slotData.slotName and slotData.slotValue and KOD_Attribute_itemStats[slotData.slotName] then
			local attributeType
			local attributeSubType
			local condition = createConditionObject(CONDITION_ATTRIBUTES, slot)
			condition:setParameter(CONDITION_PARAM_TICKS, -1)
			if KOD_Attribute_itemStats[slotData.slotName].affection then
				attributeType = KOD_Attribute_itemStats[slotData.slotName].affection.type
				attributeSubType = KOD_Attribute_itemStats[slotData.slotName].affection.subType
			end
			if attributeType and attributeSubType then
				if attributeType == CST.COMBAT_SKILLS then
					if KOD_Attribute_itemStats[slotData.slotName].percentage == true then
						if KOD_Attribute_itemStats[slotData.slotName].allowedVocation then
							if table.contains(KOD_Attribute_itemStats[slotData.slotName].allowedVocation, player:getVocation()) or
									player:getGroup():getAccess() then
								condition:setParameter(attributeSubType, slotData.slotValue + 100)
								condition:setParameter(CONDITION_PARAM_SUBID, slotData.slotName)
								player:addCondition(condition)
							end
						else
							condition:setParameter(attributeSubType, slotData.slotValue + 100)
							condition:setParameter(CONDITION_PARAM_SUBID, slotData.slotName)
							player:addCondition(condition)
						end
					else
						if KOD_Attribute_itemStats[slotData.slotName].allowedVocation then
							if table.contains(KOD_Attribute_itemStats[slotData.slotName].allowedVocation, player:getVocation()) or
									player:getGroup():getAccess() then
								condition:setParameter(attributeSubType, slotData.slotValue)
								condition:setParameter(CONDITION_PARAM_SUBID, slotData.slotName)
								player:addCondition(condition)
							end
						else
							condition:setParameter(attributeSubType, slotData.slotValue)
							condition:setParameter(CONDITION_PARAM_SUBID, slotData.slotName)
							player:addCondition(condition)
						end
					end
				elseif attributeType == CST.BASE_COMBAT_STATS then
					calculateBaseStats(attributeType, attributeSubType, slotData, playerStats, true)
				elseif attributeType == CST.ELEMENT_DEFFENCE then
					calculateElementDefence(attributeType, attributeSubType, slotData, playerStats, true)
				elseif attributeType == CST.ELEMENT_OFFENCE then
					calculateElementOffence(attributeType, attributeSubType, slotData, playerStats, true)
				end
			end
		end
	end
end

function KOD_Attribute_onDeEquipItemInternal(player, item, toPosition, slot)
	if not player or not item or not slot then
		return false
	end

	local playerStats = KOD_Attribute_PlayersItemStats[player:getGuid()]
	if not playerStats then
		KOD_Attribute_PlayersItemStats[player:getGuid()] = {}
		playerStats = KOD_Attribute_PlayersItemStats[player:getGuid()]
	end

	local slotCount = item:KOD_getNumberOfSlots()
	if not slotCount or slotCount <= 0 then
		return false
	end

	for i = 1, slotCount, 1 do
		local slotData = item:KOD_getAttributeSlotNameAndValue(i)
		if slotData and slotData.slotName and slotData.slotValue and KOD_Attribute_itemStats[slotData.slotName] then
			local attributeType
			local attributeSubType
			if KOD_Attribute_itemStats[slotData.slotName].affection then
				attributeType = KOD_Attribute_itemStats[slotData.slotName].affection.type
				attributeSubType = KOD_Attribute_itemStats[slotData.slotName].affection.subType
			end
			if attributeType and attributeSubType then
				if attributeType == CST.COMBAT_SKILLS then
					player:removeCondition(CONDITION_ATTRIBUTES, slot, slotData.slotName)
				elseif attributeType == CST.BASE_COMBAT_STATS then
					calculateBaseStats(attributeType, attributeSubType, slotData, playerStats, false)
				elseif attributeType == CST.ELEMENT_DEFFENCE then
					calculateElementDefence(attributeType, attributeSubType, slotData, playerStats, false)
				elseif attributeType == CST.ELEMENT_OFFENCE then
					calculateElementOffence(attributeType, attributeSubType, slotData, playerStats, false)
				end
			end
		end
	end
end

function KOD_Attribute_onItemMoved(item, player, fromPosition, toPosition)
	if not toPosition or not fromPosition or not player then
		return
	end

	if fromPosition.x == 65535 or toPosition.x == 65535 then
        if fromPosition.y <= 10  then
			KOD_Attribute_onDeEquipItemInternal(player, item, toPosition.y, fromPosition.y)
		elseif toPosition.y <= 10 then
			KOD_Attribute_onEquipItemInternal(player, item, toPosition.y, fromPosition.y)
		end
	end
end

function KOD_getPlayerStats(player)
	return KOD_Attribute_PlayersItemStats[player:getGuid()]
end

KOD_Attribute_itemStats = {
	[1] = { -- Attack
		attribute = {
			name = 'Attack',
			value = {1, 10},
		},
		restricted = {
			include = {
				weaponType = {
					WEAPON_SWORD,
					WEAPON_CLUB,
					WEAPON_AXE,
					WEAPON_DISTANCE
				}
			}
		},
		base = ITEM_ATTRIBUTE_ATTACK
	},
	[2] = { -- Defense
		attribute = {
			name = 'Defense',
			value = {1, 10},
		},
		restricted = {
			include = {
				weaponType = {
					WEAPON_SHIELD
				}
			},
		},
		base = ITEM_ATTRIBUTE_DEFENSE
	},
	[3] = { -- Extra Defense
		attribute = {
			name = 'Extra Defense',
			value = {1, 10},
		},
		restricted = {
			include = {
				weaponType = {
					WEAPON_SWORD,
					WEAPON_CLUB,
					WEAPON_AXE
				}
			}
		},
		base = ITEM_ATTRIBUTE_EXTRADEFENSE
	},
	[4] = { -- Armor
		attribute = {
			name = 'Armor',
			value = {1, 10},
		},
		restricted = {
			include = {
				slotType = {
					CONST_SLOT_HEAD,
					CONST_SLOT_NECKLACE,
					CONST_SLOT_ARMOR,
					CONST_SLOT_LEGS,
					CONST_SLOT_FEET
				}
			}
		},
		base = ITEM_ATTRIBUTE_ARMOR
	},
	[5] = { -- All Resistance %
		attribute = {
			name = 'All Resistance',
			value = {1, 10},
		},
		restricted = {
			exclude = {
				weaponType = {
					WEAPON_SWORD,
					WEAPON_CLUB,
					WEAPON_AXE,
					WEAPON_DISTANCE,
					WEAPON_WAND
				}
			}
		},
		affection = {type = CST.BASE_COMBAT_STATS, subType = CST.BCS_SUBIT.DEFFENCE},
		suffix = "%",
	},
	[6] = { -- Lifedrain Resistance %
		attribute = {
			name = 'Lifedrain Resistance',
			value = {1, 10},
		},
		restricted = {
			exclude = {
				weaponType = {
					WEAPON_SWORD,
					WEAPON_CLUB,
					WEAPON_AXE,
					WEAPON_DISTANCE,
					WEAPON_WAND
				}
			}
		},
		affection = {type = CST.ELEMENT_DEFFENCE, subType = COMBAT_LIFEDRAIN},
		suffix = "%",
	},
	[7] = { -- Manadrain Resistance %
		attribute = {
			name = 'Manadrain Resistance',
			value = {1, 10},
		},
		restricted = {
			exclude = {
				weaponType = {
					WEAPON_SWORD,
					WEAPON_CLUB,
					WEAPON_AXE,
					WEAPON_DISTANCE,
					WEAPON_WAND
				}
			}
		},
		affection = {type = CST.ELEMENT_DEFFENCE, subType = COMBAT_MANADRAIN},
		suffix = "%",
	},
	[8] = { -- Holy Resistance %
		attribute = {
			name = 'Holy Resistance',
			value = {1, 10},
		},
		restricted = {
			exclude = {
				weaponType = {
					WEAPON_SWORD,
					WEAPON_CLUB,
					WEAPON_AXE,
					WEAPON_DISTANCE,
					WEAPON_WAND
				}
			}
		},
		affection = {type = CST.ELEMENT_DEFFENCE, subType = COMBAT_HOLYDAMAGE},
		suffix = "%",
	},

	[9] = { -- Fire Resistance %
		attribute = {
			name = 'Fire Resistance',
			value = {1, 10},
		},
		restricted = {
			exclude = {
				weaponType = {
					WEAPON_SWORD,
					WEAPON_CLUB,
					WEAPON_AXE,
					WEAPON_DISTANCE,
					WEAPON_WAND
				}
			}
		},
		affection = {type = CST.ELEMENT_DEFFENCE, subType = COMBAT_FIREDAMAGE},
		suffix = "%",
	},
	[10] = { -- Ice Resistance %
		attribute = {
			name = 'Ice Resistance',
			value = {1, 10},
		},
		restricted = {
			exclude = {
				weaponType = {
					WEAPON_SWORD,
					WEAPON_CLUB,
					WEAPON_AXE,
					WEAPON_DISTANCE,
					WEAPON_WAND
				}
			}
		},
		affection = {type = CST.ELEMENT_DEFFENCE, subType = COMBAT_ICEDAMAGE},
		suffix = "%",
	},
	[11] = { -- Energy Resistance %
		attribute = {
			name = 'Energy Resistance',
			value = {1, 10},
		},
		restricted = {
			exclude = {
				weaponType = {
					WEAPON_SWORD,
					WEAPON_CLUB,
					WEAPON_AXE,
					WEAPON_DISTANCE,
					WEAPON_WAND
				}
			}
		},
		affection = {type = CST.ELEMENT_DEFFENCE, subType = COMBAT_ENERGYDAMAGE},
		suffix = "%",
	},
	[12] = { -- Earth Resistance %
		attribute = {
			name = 'Earth Resistance',
			value = {1, 10},
		},
		restricted = {
			exclude = {
				weaponType = {
					WEAPON_SWORD,
					WEAPON_CLUB,
					WEAPON_AXE,
					WEAPON_DISTANCE,
					WEAPON_WAND
				}
			}
		},
		affection = {type = CST.ELEMENT_DEFFENCE, subType = COMBAT_EARTHDAMAGE},
		suffix = "%",
	},
	[13] = { -- Physical Resistance %
		attribute = {
			name = 'Physical Resistance',
			value = {1, 10},
		},
		restricted = {
			exclude = {
				weaponType = {
					WEAPON_SWORD,
					WEAPON_CLUB,
					WEAPON_AXE,
					WEAPON_DISTANCE,
					WEAPON_WAND
				}
			}
		},
		affection = {type = CST.ELEMENT_DEFFENCE, subType = COMBAT_PHYSICALDAMAGE},
		suffix = "%",
	},
	[14] = { -- Death Resistance %
		attribute = {
			name = 'Death Resistance',
			value = {1, 10},
		},
		restricted = {
			exclude = {
				weaponType = {
					WEAPON_SWORD,
					WEAPON_CLUB,
					WEAPON_AXE,
					WEAPON_DISTANCE,
					WEAPON_WAND
				}
			}
		},
		affection = {type = CST.ELEMENT_DEFFENCE, subType = COMBAT_DEATHDAMAGE},
		suffix = "%",
	},
	[15] = { -- All Damage %
		attribute = {
			name = 'All Damage',
			value = {1, 10},
		},
		affection = {type = CST.BASE_COMBAT_STATS, subType = CST.BCS_SUBIT.OFFENCE},
		suffix = "%",
	},
	[16] = { -- Sword Skill
		attribute = {
			name = 'Sword Skill',
			value = {1, 12},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_SKILL_SWORD},
	},
	[17] = { -- Skill Axe
		attribute = {
			name = 'Axe Skill',
			value = {1, 12},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_SKILL_AXE},
			},
	[18] = { -- Skill Club
		attribute = {
			name = 'Club Skill',
			value = {1, 12},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_SKILL_CLUB},
	},
	[19] = { -- Skill Melee
		attribute = {
			name = 'Melee Skills',
			value = {1, 12},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_SKILL_MELEE},
	},
	[20] = { -- Skill Distance
		attribute = {
			name = 'Distance Skill',
			value = {1, 12},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_SKILL_DISTANCE},
	},
	[21] = { -- Skill Shielding
		attribute = {
			name = 'Shield Skill',
			value = {1, 12},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_SKILL_SHIELD},
	},
	[22] = { -- Magic Level
		attribute = {
			name = 'Magic Level',
			value = {1, 12},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_STAT_MAGICPOINTS},
		allowedVocation = {1, 2, 5, 6}
	},
	[23] = { -- Sword Skill %
		attribute = {
			name = 'Sword Skill',
			value = {1, 12},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_SKILL_SWORDPERCENT},
		suffix = "%",
		percentage = true
	},
	[24] = { -- Skill Axe %
		attribute = {
			name = 'Axe Skill',
			value = {1, 12},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_SKILL_AXEPERCENT},
		suffix = "%",
		percentage = true
	},
	[25] = { -- Skill Club %
		attribute = {
			name = 'Club Skill',
			value = {1, 12},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_SKILL_CLUBPERCENT},
		suffix = "%",
		percentage = true
	},
	[26] = { -- Skill Melee %
		attribute = {
			name = 'Melee Skills',
			value = {1, 12},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_SKILL_MELEEPERCENT},
		suffix = "%",
		percentage = true
	},
	[27] = { -- Skill Distance %
		attribute = {
			name = 'Distance Skill',
			value = {1, 12},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_SKILL_DISTANCEPERCENT},
		suffix = "%",
		percentage = true
	},
	[28] = { -- Skill Shielding %
		attribute = {
			name = 'Shield Skill',
			value = {1, 12},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_SKILL_SHIELDPERCENT},
		suffix = "%",
		percentage = true
	},
	[29] = { -- Magic Level %
		attribute = {
			name = 'Magic Level',
			value = {1, 12},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_STAT_MAGICPOINTSPERCENT},
		suffix = "%",
		percentage = true
	},
	[30] = { -- Lifedrain Damage %
		attribute = {
			name = 'Lifedrain Damage',
			value = {1, 10},
		},
		affection = {type = CST.ELEMENT_OFFENCE, subType = COMBAT_LIFEDRAIN},
		suffix = "%",
	},
	[31] = { -- Manadrain Damage %
		attribute = {
			name = 'Manadrain Damage',
			value = {1, 10},
		},
		affection = {type = CST.ELEMENT_OFFENCE, subType = COMBAT_MANADRAIN},
		suffix = "%",
	},
	[32] = { -- Holy Damage %
		attribute = {
			name = 'Holy Damage',
			value = {1, 10},
		},
		affection = {type = CST.ELEMENT_OFFENCE, subType = COMBAT_HOLYDAMAGE},
		suffix = "%",
	},
	[33] = { -- Fire Damage %
		attribute = {
			name = 'Fire Damage',
			value = {1, 10},
		},
		affection = {type = CST.ELEMENT_OFFENCE, subType = COMBAT_FIREDAMAGE},
		suffix = "%",
	},
	[34] = { -- Ice Damage %
		attribute = {
			name = 'Ice Damage',
			value = {1, 10},
		},
		affection = {type = CST.ELEMENT_OFFENCE, subType = COMBAT_ICEDAMAGE},
		suffix = "%",
	},
	[35] = { -- Energy Damage %
		attribute = {
			name = 'Energy Damage',
			value = {1, 10},
		},
		affection = {type = CST.ELEMENT_OFFENCE, subType = COMBAT_ENERGYDAMAGE},
		suffix = "%",
	},
	[36] = { -- Earth Damage %
		attribute = {
			name = 'Earth Damage',
			value = {1, 10},
		},
		affection = {type = CST.ELEMENT_OFFENCE, subType = COMBAT_EARTHDAMAGE},
		suffix = "%",
	},
	[37] = { -- Physical Damage %
		attribute = {
			name = 'Physical Damage',
			value = {1, 10},
		},
		affection = {type = CST.ELEMENT_OFFENCE, subType = COMBAT_PHYSICALDAMAGE},
		suffix = "%",
	},
	[38] = { -- Death Damage %
		attribute = {
			name = 'Death Damage',
			value = {1, 10},
		},
		affection = {type = CST.ELEMENT_OFFENCE, subType = COMBAT_DEATHDAMAGE},
		suffix = "%",
	},
	[39] = { -- Max Health
		attribute = {
			name = 'Max Health',
			value = {50, 500},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_STAT_MAXHITPOINTS},
	},
	[40] = { -- Max Mana
		attribute = {
			name = 'Max Mana',
			value = {50, 500},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_STAT_MAXMANAPOINTS},
	},
	[41] = { -- Max Health %
		attribute = {
			name = 'Max Health',
			value = {1, 10},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_STAT_MAXHITPOINTSPERCENT},
		suffix = "%",
		percentage = true
	},
	[42] = { -- Max Mana %
		attribute = {
			name = 'Max Mana',
			value = {1, 10},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_STAT_MAXMANAPOINTSPERCENT},
		suffix = "%",
		percentage = true
	},
	--[[
	[43] = { -- attack speed (+1300)
		attribute = {
			name = 'Attack Speed',
			value = {1000, 1800},
		},
		restricted = {
			include = {
				weaponType = {
					WEAPON_SWORD,
					WEAPON_CLUB,
					WEAPON_AXE,
					WEAPON_DISTANCE
				}
			}
		},
		base = ITEM_ATTRIBUTE_ATTACK_SPEED,
	},
	[44] = { -- Cooldown Reduction %
		attribute = {
			name = 'Cooldown Reduction',
			value = {1, 8},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_CUSTOMSKILL_COOLDOWNREDUCTION},
		suffix = "%",
	},
	[45] = { -- Increased Healing %
		attribute = {
			name = 'Increase Healing',
			value = {1, 15},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_CUSTOMSKILL_INCREASEHEALING},
		suffix = "%",
	},
	[46] = { -- Increased Mana Restoring %
		attribute = {
			name = 'Increase Mana Restoring',
			value = {1, 10},
		},
		affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_CUSTOMSKILL_INCREADEMANARESTORING},
		suffix = "%",
	},
	]]
}