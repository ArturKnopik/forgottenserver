function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '['..k..'] = ' .. dump(v) .. ',\n'
        end
        return s .. '} \n'
    else
        return tostring(o)
    end
end

if FEATURE.uniqueItems.enabled  == true then
	KOD_Attribute_config = {
		useDebugLogs = false,
		maxSlots = 6,
		allowSameAttribute = true,
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
	CST = {
		BASE_COMBAT_STATS = 1,
		BCS_SUBIT = { OFFENCE = 1,	DEFFENCE = 2},
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

	-- OTHER FUNCTIONS

	function printD(text)
		if KOD_Attribute_config.useDebugLogs then
			print(text)
		end
	end

	function rollRarity()
		printD("+rollRarity")
		local maxRollNumber = 1
		local rollChance = {}

		for i = 1, KOD_Attribute_config.maxSlots, 1 do
			printD("rollRarity: insert value " .. maxRollNumber .. ", on index " .. i)
			rollChance[i] = maxRollNumber
			maxRollNumber = maxRollNumber * 5
		end
		rollChance[#rollChance+1] = maxRollNumber * 5
		printD("rollRarity: insert value " .. maxRollNumber .. ", on index " .. #rollChance)

		local roll = math.random(1, maxRollNumber)
		printD("rolled value: " .. roll)
		for i = #rollChance, 1, -1 do
			if roll >= rollChance[i] then
				printD("rolled and returned :" .. #rollChance - i  .. ":" .. rollChance[i] )
				--return #rollChance - i
				return #rollChance - i
			end
		end
		printD("-rolled value: " .. 0)
		return 0
	end

	local function generateSlotName_Name(slot)
		printD("+generateSlotName_Name: " .. KOD_Attribute_config.stotNameBase .. tostring(slot))
		return KOD_Attribute_config.stotNameBase .. tostring(slot)
	end

	local function generateSlotName_Value(slot)
		printD("+generateSlotValue_Value: " .. KOD_Attribute_config.slotValueBase .. tostring(slot))
		return KOD_Attribute_config.slotValueBase .. tostring(slot)
	end

	local function getPrefixName(slot)
		printD("+getPrefixName")
		if not KOD_Attribute_config.itemRarityPrefix then
			printD(" getPrefixName: miss itemRarityPrefix")
			return KOD_Attribute_config.stotPrefixNameBase .. tostring(slot)
		elseif not KOD_Attribute_config.itemRarityPrefix[slot] then
			printD(" getPrefixName: miss itemRarityPrefix[slot]")
			return KOD_Attribute_config.stotPrefixNameBase .. tostring(slot)
		else
			printD(" getPrefixName: itemRarityPrefix[slot] exist")
			return KOD_Attribute_config.itemRarityPrefix[slot]
		end
		printD("-getPrefixName")
	end
	-- ITEM FUNCTIONS --

	-- slot count
	function Item.KOD_getNumberOfSlots(self)
		printD("+Item.KOD_getNumberOfSlots")

		local slots = self:getCustomAttribute(KOD_Attribute_config.slotCount)

		if slots then
			printD("Item.KOD_getNumberOfSlots: return slots " .. slots)
			return slots
		end
		printD("-Item.KOD_getNumberOfSlots: fail to get slots count")
		return false
	end

	function Item.KOD_setNumberOfSlots(self, slotCount)
		printD("+Item.KOD_setNumberOfSlots")
		if slotCount <= 0 and slotCount > KOD_Attribute_config.maxSlots then
			self:removeCustomAttribute(KOD_Attribute_config.slotCount)
			printD("Item.KOD_setNumberOfSlots: slot out of bound")
			return false
		end
		local prefixName = getPrefixName(slotCount)

		self:setAttribute(ITEM_ATTRIBUTE_ARTICLE, prefixName)
		self:setCustomAttribute(KOD_Attribute_config.slotCount, slotCount)
		printD("-Item.KOD_setNumberOfSlots: " .. prefixName .. ":" ..slotCount)
		return true
	end

	--slot name
	function Item.KOD_setAttributeSlotName(self, slotIndex, name)
		printD("+Item.KOD_setAttributeSlotName")
		self:setCustomAttribute(generateSlotName_Name(slotIndex), name)
		return true
	end

	function Item.KOD_getAttributeSlotName(self, slotIndex)
		printD("+Item.KOD_getAttributeSlotName")
		local slotname = self:getCustomAttribute(generateSlotName_Name(slotIndex))
		if not slotname then
			printD("Item.KOD_getAttributeSlotName: fail to get slot name")
			return false
		end
		printD("-Item.KOD_getAttributeSlotName")
		return slotname
	end

	--add/remove attribute if free slot
	function Item.KOD_addAttribute(self, name, value, slotIndex --[[optional]])
		printD("+Item.KOD_addAttribute")
		local slotCount = self:KOD_getNumberOfSlots()
		if not slotCount or slotCount <= 0 then
			printD("Item.KOD_addAttribute: lack of slots")
			return false
		end

		if slotIndex and slotIndex > 0 and slotIndex <= slotCount then
			printD("Item.KOD_addAttribute: slotIndex present, check attibute on index " .. slotIndex)
			if self:KOD_getAttributeSlotNameAndValue(slotIndex) then
				printD("Item.KOD_addAttribute: fail - attibute present on index " .. slotIndex)
				return false
			else
				printD("Item.KOD_addAttribute: add attribute to index " .. slotIndex)
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
		printD("-Item.KOD_addAttribute: no empty slot")
		return false
	end

	function Item.KOD_removeAttribute(self, slotIndex)
		printD("+Item.KOD_removeAttribute")
		self:removeCustomAttribute(generateSlotName_Name(slotIndex))
		self:removeCustomAttribute(generateSlotName_Value(slotIndex))
		return true
	end

	-- slot value
	function Item.KOD_setAttributeSlotValue(self, slotIndex, name)
		printD("+Item.KOD_setAttributeSlotValue")
		self:setCustomAttribute(generateSlotName_Value(slotIndex), name)
		return true
	end

	function Item.KOD_getAttributeSlotValue(self, slotIndex)
		printD("+Item.KOD_getAttributeSlotValue")
		local slotValue = self:getCustomAttribute(generateSlotName_Value(slotIndex))
		if not slotValue then
			printD("Item.KOD_getAttributeSlotValue: fail to get slot value, return false")
			return false
		end
		return slotValue
	end

	--name and value
	function Item.KOD_setAttributeSlotNameAndValue(self, slot, name, value)
		printD("+Item.KOD_setAttributeSlotNameAndValue")
		if KOD_Attribute_itemStats[name] then
			if KOD_Attribute_itemStats[name].base then
				printD("+Item.KOD_setAttributeSlotNameAndValue: base exist, set static attribute")
				self:setAttribute(KOD_Attribute_itemStats[name].base, self:getAttribute(KOD_Attribute_itemStats[name].base) + value)
			end
		end
		self:KOD_setAttributeSlotName(slot, name)
		self:KOD_setAttributeSlotValue(slot, value)
		return true
	end

	function Item.KOD_getAttributeSlotNameAndValue(self, slotIndex)
		printD("+Item.KOD_getAttributeSlotNameAndValue")
		local sn = self:KOD_getAttributeSlotName(slotIndex)
		local sv = self:KOD_getAttributeSlotValue(slotIndex)
		if not sn or not sv then
			printD("+Item.KOD_getAttributeSlotNameAndValue: fail to get slot name or value")
			return false
		end
		return {slotName = sn, slotValue = sv}
	end

	-- has attribute
	function Item.KOD_hasAttribute(self, attr, itemAttributeCount)
		printD("+Item.KOD_hasAttribute")
		for i = 1, itemAttributeCount, 1 do
			printD("Item.KOD_hasAttribute: checking data for attr " .. attr .. " on itemslot " .. i)
			if self:getCustomAttribute(generateSlotName_Name(i)) == attr then
				printD("+Item.KOD_hasAttribute: has atribute " .. attr .. " on slot " .. i)
				return true
			end
		end
		printD("+Item.KOD_hasAttribute: false")
		return false
	end

	function Item.KOD_hasAttributeNameAndValue(self, attr, itemAttributeCount)
		printD("+Item.KOD_getAttributeSlotNameAndValue")
		for i = 1, itemAttributeCount, 1 do
			if self:KOD_getCustomAttribute(generateSlotName_Name(i)) == attr then
				printD("Item.KOD_getAttributeSlotNameAndValue: found same attribute - " .. attr)
				return true
			end
		end
		printD("Item.KOD_hasAttributeNameAndValue: false")
		return false
	end

	function Item.KOD_removeAllAttribute(self)
		printD("+Item.KOD_removeAllAttribute")
		local slotCount = self:KOD_getNumberOfSlots()
		if not slotCount or slotCount == 0 then
			printD("Item.KOD_removeAllAttribute: lack of slot skip clearing")
			return false
		end
		for i = 1, slotCount, 1 do
			printD("Item.KOD_removeAllAttribute: remove attribute for slot " .. i)
			self:KOD_removeAttribute(i)
		end
		self:KOD_setNumberOfSlots(0)
		printD("-Item.KOD_removeAllAttribute")
		return true
	end

	function Item.KOD_resetToDefault(self)
		printD("+Item.KOD_resetToDefault")
		local it = self:getType()
		if not it then
			printD("Item.KOD_resetToDefault: fail to get itemType")
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
		printD("-Item.KOD_resetToDefault")
		return true
	end

	local function canAddRollThisAttributeToItem(rolledIndex, item, currentSlot)
		printD("+canAddRollThisAttributeToItem")
		if not rolledIndex or not item or not currentSlot then
			printD("canAddRollThisAttributeToItem: fail to get rolledValue or item or currentSlot, return false")
			return false
		end

		local rolledValue = KOD_Attribute_itemStats[rolledIndex]
		if item:KOD_hasAttribute(rolledIndex, currentSlot) == true and KOD_Attribute_config.allowSameAttribute == false then
			printD("canAddRollThisAttributeToItem: allowSameAttribute set to false and has same attribute, return false")
			return false
		end

		if not rolledValue.restricted then
			printD("canAddRollThisAttributeToItem: no restriction, return true")
			return true
		end


		local isIncluded = false
		local isExcluded = false

		printD("canAddRollThisAttributeToItem: restrictions exist, checking...")
		local include = rolledValue.restricted.include
		if not include then
			printD("canAddRollThisAttributeToItem: restrictions include missing, update isIncluded true")
			isIncluded = true
		else
			printD("canAddRollThisAttributeToItem: include...")
			if include.weaponType and item:getType():isWeapon() then
				printD("canAddRollThisAttributeToItem: include - weaponType checking...")
				local incWep = include.weaponType
				for i = 1, #incWep, 1 do
					if incWep[i] == item:getType():getWeaponType() then
						printD("canAddRollThisAttributeToItem: can include weapon, update isIncluded true")
						isIncluded = true
					end
				end
			end

			if include.slotType then
				printD("canAddRollThisAttributeToItem: include - slotType checking...")
				local incSl = include.slotType
				for i = 1, #incSl, 1 do
					if incSl[i] == slotBits[item:getType():getSlotPosition()] then
						printD("canAddRollThisAttributeToItem: can include slotType, update isIncluded true")
						isIncluded = true
					end
				end
			end
		end

		local exclude = rolledValue.restricted.exclude
		if not exclude then
			printD("canAddRollThisAttributeToItem: restrictions exclude missing, update isExcluded true")
		else
			printD("canAddRollThisAttributeToItem: exclude...")
			if exclude.weaponType and item:getType():isWeapon() then
				printD("canAddRollThisAttributeToItem: exclude - weaponType checking...")
				local incWep = exclude.weaponType
				for i = 1, #incWep, 1 do
					if incWep[i] == item:getType():getWeaponType() then
						printD("canAddRollThisAttributeToItem: can exclude weapon, update isExcluded false")
						isExcluded = true
					end
				end
			end

			if exclude.slotType then
				printD("canAddRollThisAttributeToItem: exclude - slotType checking...")
				local incSl = exclude.slotType
				for i = 1, #incSl, 1 do
					if incSl[i] == slotBits[item:getType():getSlotPosition()] then
						printD("canAddRollThisAttributeToItem: can exclude slotType, update isExcluded true")
						isExcluded = true
					end
				end
			end
		end

		if isIncluded == true and isExcluded == false then
			printD("canAddRollThisAttributeToItem: return true")
			return true
		else
			printD("canAddRollThisAttributeToItem: return true")
			return false
		end
		printD("-canAddRollThisAttributeToItem")
	end

	function Item.KOD_rollIAndSetItemAttributes(self)
		printD("+Item.KOD_rollIAndSetItemAttributes")
		self:KOD_resetToDefault()
		local rolledItemSlots = rollRarity()
		if rolledItemSlots <= 0 then
			printD("Item.KOD_rollIAndSetItemAttributes: slot count equal or less 0 - " .. rolledItemSlots)
			return false
		end
		self:KOD_setNumberOfSlots(rolledItemSlots)
		for i = 1, rolledItemSlots, 1 do
			printD("Item.KOD_rollIAndSetItemAttributes: set attribute for slot " .. i)
			local rolledIndex
			local rolledValue
			repeat
				rolledIndex = math.random(#KOD_Attribute_itemStats)
				rolledValue = KOD_Attribute_itemStats[rolledIndex]
				printD("Item.KOD_rollIAndSetItemAttributes: new index: " ..rolledIndex .. " for " .. i)
			until(canAddRollThisAttributeToItem(rolledIndex, self, i))

			self:KOD_setAttributeSlotNameAndValue(i, rolledIndex, math.random(rolledValue.attribute.value[1], rolledValue.attribute.value[2]))
		end
		printD("-Item.KOD_rollIAndSetItemAttributes")
		return true
	end

	-- restiction = true, (false + true)

	function KOD_Attribute_onLook(item)
		printD("+KOD_Attribute_onLook")
		local tempStr = ""

		if not item:isItem() then
			return tempStr
		end

		local slotCount = item:KOD_getNumberOfSlots()
		if not slotCount or slotCount <= 0 then
			printD("KOD_Attribute_onLook: return empty string")
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
		printD("-KOD_Attribute_onLook")
		return tempStr
	end

	local function calculateBaseStats(type, subType, slotData, playerStats, shouldAdd)
		printD("+calculateBaseStats")
		if not type or not subType or not slotData or not playerStats then
			printD("calculateBaseStats: fail to get type/subType/slotData/playerStats")
			return false
		end
		if shouldAdd and shouldAdd == true then
			printD("calculateBaseStats: adding value")
			if subType == CST.BCS_SUBIT.OFFENCE then
				if not playerStats.baseStats then
					printD("calculateBaseStats: creating base stat struct")
					playerStats.baseStats = {}
				end
				if not playerStats.baseStats.offence then
					printD("calculateBaseStats: creating base stat offence field and fill")
					playerStats.baseStats.offence = 0
					playerStats.baseStats.offence = playerStats.baseStats.offence + slotData.slotValue
				else
					printD("calculateBaseStats: fill")
					playerStats.baseStats.offence = playerStats.baseStats.offence + slotData.slotValue
				end
			elseif subType == CST.BCS_SUBIT.DEFFENCE then
				if not playerStats.baseStats then
					printD("calculateBaseStats: creating base stat struct")
					playerStats.baseStats = {}
				end
				if not playerStats.baseStats.deffence then
					printD("calculateBaseStats: creating base stat offence field and fill")
					playerStats.baseStats.deffence = 0
					playerStats.baseStats.deffence = playerStats.baseStats.deffence + slotData.slotValue
				else
					printD("calculateBaseStats: fill")
					playerStats.baseStats.deffence = playerStats.baseStats.deffence + slotData.slotValue
				end
			end
		else
			printD("calculateBaseStats: subtracting value")
			if subType == CST.BCS_SUBIT.OFFENCE then
				if not playerStats.baseStats then
					printD("calculateBaseStats: creating base stat struct")
					playerStats.baseStats = {}
				end
				if not playerStats.baseStats.offence then
					printD("calculateBaseStats: creating base stat offence field and fill")
					playerStats.baseStats.offence = 0
					playerStats.baseStats.offence = playerStats.baseStats.offence - slotData.slotValue
				else
					printD("calculateBaseStats: fill")
					playerStats.baseStats.offence = playerStats.baseStats.offence - slotData.slotValue
				end
			elseif subType == CST.BCS_SUBIT.DEFFENCE then
				if not playerStats.baseStats then
					printD("calculateBaseStats: creating base stat struct")
					playerStats.baseStats = {}
				end
				if not playerStats.baseStats.deffence then
					printD("calculateBaseStats: creating base stat offence field and fill")
					playerStats.baseStats.deffence = 0
					playerStats.baseStats.deffence = playerStats.baseStats.deffence - slotData.slotValue
				else
					printD("calculateBaseStats: fill")
					playerStats.baseStats.deffence = playerStats.baseStats.deffence - slotData.slotValue
				end
			end
		end
		printD("-calculateBaseStats:")
	end

	local function calculateElementDefence(type, subType, slotData, playerStats, shouldAdd)
		printD("+calculateElementDefence")
		if not type or not subType or not slotData or not playerStats then
			printD("calculateElementDefence: fail to get type/subType/slotData/playerStats")
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
		printD("-calculateElementDefence")
	end

	local function calculateElementOffence(type, subType, slotData, playerStats, shouldAdd)
		printD("+calculateElementOffence")
		if not type or not subType or not slotData or not playerStats then
			printD("calculateElementOffence: fail to get type/subType/slotData/playerStats")
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
		printD("-calculateElementOffence")
	end

	function KOD_Attribute_onEquipItem(player, item, slot)
		printD("+KOD_Attribute_onItemEquiped")
		if not player or not item or not slot then
			printD("KOD_Attribute_onItemEquiped: fail to get player or item or slot")
			return false
		end

		local playerStats = KOD_Attribute_PlayersItemStats[player:getGuid()]
		if not playerStats then
			printD("KOD_Attribute_onItemEquiped: fail to get player data, creating new table")
			KOD_Attribute_PlayersItemStats[player:getGuid()] = {}
			playerStats = KOD_Attribute_PlayersItemStats[player:getGuid()]
		end

		local slotCount = item:KOD_getNumberOfSlots()
		if not slotCount or slotCount <= 0 then
			printD("KOD_Attribute_onItemEquiped: lack of slots")
			return false
		end

		for i = 1, slotCount, 1 do
			printD("KOD_Attribute_onItemEquiped: operation for slot " .. i)
			local slotData = item:KOD_getAttributeSlotNameAndValue(i)
			if slotData and slotData.slotName and slotData.slotValue and KOD_Attribute_itemStats[slotData.slotName] then
				local attributeType
				local attributeSubType
				local condition = createConditionObject(CONDITION_ATTRIBUTES, slot)
				condition:setParameter(CONDITION_PARAM_TICKS, -1)
				if KOD_Attribute_itemStats[slotData.slotName].affection then
					printD("KOD_Attribute_onItemEquiped: read affection data from KOD_Attribute_itemStats for " .. slotData.slotName)
					attributeType = KOD_Attribute_itemStats[slotData.slotName].affection.type
					attributeSubType = KOD_Attribute_itemStats[slotData.slotName].affection.subType
				end
				if attributeType and attributeSubType then
					if attributeType == CST.COMBAT_SKILLS --[[ and attributeSubType >= CONDITION_PARAM_SKILL_MELEE and attributeSubType <= CONDITION_PARAM_CUSTOMSKILL_INCREADEMANARESTORING  - do i need this check??]] then
						printD("KOD_Attribute_onItemEquiped: add params to condition ")
						if KOD_Attribute_itemStats[slotData.slotName].percentage == true then
							printD("KOD_Attribute_onItemEquiped: add params to condition: add percentage value, add 100 to " .. slotData.slotValue)
							if KOD_Attribute_itemStats[slotData.slotName].allowedVocation then
								printD("KOD_Attribute_onItemEquiped: checkVocation")
								print(player:getAccountType() < ACCOUNT_TYPE_GOD)
								if table.contains(KOD_Attribute_itemStats[slotData.slotName].allowedVocation, player:getVocation():getId()) or
										player:getGroup():getAccess() then
									printD("KOD_Attribute_onItemEquiped: add skill for player vocation")
									condition:setParameter(attributeSubType, slotData.slotValue + 100)
									condition:setParameter(CONDITION_PARAM_SUBID, slotData.slotName + i * 1000)
									player:addCondition(condition)
								end
							else
								printD("KOD_Attribute_onItemEquiped: add skill for player")
								condition:setParameter(attributeSubType, slotData.slotValue + 100)
								condition:setParameter(CONDITION_PARAM_SUBID, slotData.slotName + i * 1000)
								player:addCondition(condition)
							end
						else
							printD("KOD_Attribute_onItemEquiped: add params to condition: add static " .. slotData.slotValue)
							if KOD_Attribute_itemStats[slotData.slotName].allowedVocation then
								printD("KOD_Attribute_onItemEquiped: checkVocation")
								print(player:getGroup():getAccess())
								if table.contains(KOD_Attribute_itemStats[slotData.slotName].allowedVocation, player:getVocation():getId()) or
										player:getGroup():getAccess() then
									printD("KOD_Attribute_onItemEquiped: add skill for player vocation")
									condition:setParameter(attributeSubType, slotData.slotValue)
									condition:setParameter(CONDITION_PARAM_SUBID, slotData.slotName + i * 1000)
									player:addCondition(condition)
								end
							else
								printD("KOD_Attribute_onItemEquiped: add skill for player")
								condition:setParameter(attributeSubType, slotData.slotValue)
								condition:setParameter(CONDITION_PARAM_SUBID, slotData.slotName + i * 1000)
								player:addCondition(condition)
							end
						end
					elseif attributeType == CST.BASE_COMBAT_STATS then
						printD("KOD_Attribute_onItemEquiped: BASE_COMBAT_STATS")
						calculateBaseStats(attributeType, attributeSubType, slotData, playerStats, true)
					elseif attributeType == CST.ELEMENT_DEFFENCE then
						printD("KOD_Attribute_onItemEquiped: ELEMENT_DEFFENCE")
						calculateElementDefence(attributeType, attributeSubType, slotData, playerStats, true)
					elseif attributeType == CST.ELEMENT_OFFENCE then
						printD("KOD_Attribute_onItemEquiped: ELEMENT_OFFENCE")
						calculateElementOffence(attributeType, attributeSubType, slotData, playerStats, true)
					end
				end
			end
		end
		printD("-KOD_Attribute_onItemEquiped")
	end

	function KOD_Attribute_onDeEquipItem(player, item, slot)
		printD("+KOD_Attribute_onItemEquiped")
		if not player or not item or not slot then
			printD("KOD_Attribute_onItemEquiped: fail to get player or item or slot")
			return false
		end

		local playerStats = KOD_Attribute_PlayersItemStats[player:getGuid()]
		if not playerStats then
			printD("KOD_Attribute_onItemEquiped: fail to get player data, creating new table")
			KOD_Attribute_PlayersItemStats[player:getGuid()] = {}
			playerStats = KOD_Attribute_PlayersItemStats[player:getGuid()]
		end

		local slotCount = item:KOD_getNumberOfSlots()
		if not slotCount or slotCount <= 0 then
			printD("KOD_Attribute_onItemEquiped: lack of slots")
			return false
		end

		for i = 1, slotCount, 1 do
			printD("KOD_Attribute_onItemEquiped: operation for slot " .. i)
			local slotData = item:KOD_getAttributeSlotNameAndValue(i)
			if slotData and slotData.slotName and slotData.slotValue and KOD_Attribute_itemStats[slotData.slotName] then
				local attributeType
				local attributeSubType
				if KOD_Attribute_itemStats[slotData.slotName].affection then
					printD("KOD_Attribute_onItemEquiped: read affection data from KOD_Attribute_itemStats for " .. slotData.slotName)
					attributeType = KOD_Attribute_itemStats[slotData.slotName].affection.type
					attributeSubType = KOD_Attribute_itemStats[slotData.slotName].affection.subType
				end
				if attributeType and attributeSubType then
					printD("KOD_Attribute_onItemEquiped: read affection data from KOD_Attribute_itemStats for " .. slotData.slotName)
					if attributeType == CST.COMBAT_SKILLS --[[ and attributeSubType >= CONDITION_PARAM_SKILL_MELEE and attributeSubType <= CONDITION_PARAM_SKILL_SHIELDPERCENT - do i need this check??]]then
						printD("KOD_Attribute_onDeEquipItemInternal: removeCondition")
						player:removeCondition(CONDITION_ATTRIBUTES, slot, slotData.slotName + i * 1000)
					elseif attributeType == CST.BASE_COMBAT_STATS then
						printD("KOD_Attribute_onDeEquipItemInternal: BASE_COMBAT_STATS")
						calculateBaseStats(attributeType, attributeSubType, slotData, playerStats, false)
					elseif attributeType == CST.ELEMENT_DEFFENCE then
						printD("KOD_Attribute_onDeEquipItemInternal: BASE_COMBAT_STATS")
						calculateElementDefence(attributeType, attributeSubType, slotData, playerStats, false)
					elseif attributeType == CST.ELEMENT_OFFENCE then
						printD("KOD_Attribute_onDeEquipItemInternal: BASE_COMBAT_STATS")
						calculateElementOffence(attributeType, attributeSubType, slotData, playerStats, false)
					end
				end
			end
		end
		printD("-KOD_Attribute_onItemEquiped")
	end

	--[[
	function KOD_Attribute_onItemMoved(item, player, fromPosition, toPosition)
		printD("+KOD_Attribute_onItemMoved")
		if not toPosition or not fromPosition or not player then
			printD("KOD_Attribute_onItemMoved")
			return
		end

		if fromPosition.x == 65535 or toPosition.x == 65535 then
			printD("KOD_Attribute_onItemMoved: playerSlot")
			if fromPosition.y <= 10  then
				printD("KOD_Attribute_onItemMoved: deequip")
				KOD_Attribute_onDeEquipItemInternal(player, item, toPosition.y, fromPosition.y)
			elseif toPosition.y <= 10 then
				printD("KOD_Attribute_onItemMoved: equip")
				KOD_Attribute_onEquipItemInternal(player, item, toPosition.y, fromPosition.y)
			end
		end
		printD("-KOD_Attribute_onItemMoved")
		print(dumpK(KOD_getPlayerStats(player)))
	end
	]]

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
						WEAPON_DISTANCE,
						WEAPON_WAND
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
			affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_SKILL_SWORD},
		},
		[17] = { -- Skill Axe
			attribute = {
				name = 'Axe Skill',
				value = {1, 12},
			},
			restricted = {
				exclude = {
					weaponType = {
						WEAPON_SWORD,
						WEAPON_CLUB,
						WEAPON_DISTANCE,
						WEAPON_WAND
					}
				}
			},
			affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_SKILL_AXE},
				},
		[18] = { -- Skill Club
			attribute = {
				name = 'Club Skill',
				value = {1, 12},
			},
			restricted = {
				exclude = {
					weaponType = {
						WEAPON_SWORD,
						WEAPON_AXE,
						WEAPON_DISTANCE,
						WEAPON_WAND
					}
				}
			},
			affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_SKILL_CLUB},
		},
		[19] = { -- Skill Melee
			attribute = {
				name = 'Melee Skills',
				value = {1, 12},
			},
			restricted = {
				exclude = {
					weaponType = {
						WEAPON_DISTANCE,
						WEAPON_WAND
					}
				}
			},
			affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_SKILL_MELEE},
		},
		[20] = { -- Skill Distance
			attribute = {
				name = 'Distance Skill',
				value = {1, 12},
			},
			restricted = {
				exclude = {
					weaponType = {
						WEAPON_SWORD,
						WEAPON_CLUB,
						WEAPON_AXE,
						WEAPON_WAND
					}
				}
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
			restricted = {
				exclude = {
					weaponType = {
						WEAPON_SWORD,
						WEAPON_CLUB,
						WEAPON_AXE,
						WEAPON_DISTANCE
					}
				}
			},
			affection = {type = CST.COMBAT_SKILLS, subType = CONDITION_PARAM_STAT_MAGICPOINTS},
			allowedVocation = {1, 2, 5, 6}
		},
		[23] = { -- Sword Skill %
			attribute = {
				name = 'Sword Skill',
				value = {1, 12},
			},
			restricted = {
				exclude = {
					weaponType = {
						WEAPON_CLUB,
						WEAPON_AXE,
						WEAPON_DISTANCE,
						WEAPON_WAND
					}
				}
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
			restricted = {
				exclude = {
					weaponType = {
						WEAPON_SWORD,
						WEAPON_CLUB,
						WEAPON_DISTANCE,
						WEAPON_WAND
					}
				}
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
			restricted = {
				exclude = {
					weaponType = {
						WEAPON_SWORD,
						WEAPON_AXE,
						WEAPON_DISTANCE,
						WEAPON_WAND
					}
				}
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
			restricted = {
				exclude = {
					weaponType = {
						WEAPON_DISTANCE,
						WEAPON_WAND
					}
				}
			},
			suffix = "%",
			percentage = true
		},
		[27] = { -- Skill Distance %
			attribute = {
				name = 'Distance Skill',
				value = {1, 12},
			},
			restricted = {
				exclude = {
					weaponType = {
						WEAPON_SWORD,
						WEAPON_CLUB,
						WEAPON_AXE,
						WEAPON_WAND
					}
				}
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
			restricted = {
				exclude = {
					weaponType = {
						WEAPON_SWORD,
						WEAPON_CLUB,
						WEAPON_AXE,
						WEAPON_DISTANCE
					}
				}
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
				value = {1200, 1800},
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

end