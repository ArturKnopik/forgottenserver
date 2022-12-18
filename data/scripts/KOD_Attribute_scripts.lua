if FEATURE.uniqueItems.enabled  == true then
    local maxDamageReduction = 20 -- min damage taken
    
    local KOD_Attribute_onHealthChange = CreatureEvent("KOD_Attribute_onHealthChange")
    function KOD_Attribute_onHealthChange.onHealthChange(target, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
        if primaryType == COMBAT_HEALING or (primaryType == COMBAT_MANADRAIN and primaryDamage > 0) then
            return primaryDamage, primaryType, secondaryDamage, secondaryType
        end
        local attackMultipler = 100
        local attackerStats = nil
        if attacker and attacker:isPlayer() then
            attackerStats = KOD_Attribute_PlayersItemStats[attacker:getGuid()]
        end

        if attackerStats then
            local attackerStatsBase = attackerStats.baseStats
            if attackerStatsBase then
                if attackerStatsBase.offence then
                    attackMultipler = attackMultipler + attackerStatsBase.offence
                end
            end
            local attackerElementOffence = attackerStats.elementOffence
            if attackerElementOffence then
                if attackerElementOffence[primaryType] then
                    attackMultipler = attackMultipler + attackerElementOffence[primaryType]
                end
            end
        end

        local targetStats = nil
        if target:isPlayer() then
            targetStats = KOD_Attribute_PlayersItemStats[target:getGuid()]
        end
        if targetStats then
            local targetStatsBase = targetStats.baseStats
            if targetStatsBase then
                if targetStatsBase.deffence then
                    attackMultipler = attackMultipler - targetStatsBase.deffence
                end
            end
            local targetElementOffence = targetStats.elementDeffence
            if targetElementOffence then
                if targetElementOffence[primaryType] then
                    attackMultipler = attackMultipler - targetElementOffence[primaryType]
                end
            end
        end
        if attackMultipler < maxDamageReduction then
            attackMultipler = maxDamageReduction
        end
        return primaryDamage * (attackMultipler/100), primaryType, secondaryDamage, secondaryType
    end
    KOD_Attribute_onHealthChange:register()

    local KOD_Attribute_onManaChange = CreatureEvent("KOD_Attribute_onManaChange")
    function KOD_Attribute_onManaChange.onManaChange(target, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
        if primaryType == COMBAT_HEALING or (primaryType == COMBAT_MANADRAIN and primaryDamage > 0) then
            return primaryDamage, primaryType, secondaryDamage, secondaryType
        end
        local attackMultipler = 100
        local attackerStats = nil
        if attacker and attacker:isPlayer() then
            attackerStats = KOD_Attribute_PlayersItemStats[attacker:getGuid()]
        end

        if attackerStats then
            local attackerStatsBase = attackerStats.baseStats
            if attackerStatsBase then
                if attackerStatsBase.offence then
                    attackMultipler = attackMultipler + attackerStatsBase.offence
                end
            end
            local attackerElementOffence = attackerStats.elementOffence
            if attackerElementOffence then
                if attackerElementOffence[primaryType] then
                    attackMultipler = attackMultipler + attackerElementOffence[primaryType]
                end
            end
        end

        local targetStats = nil
        if target:isPlayer() then
            targetStats = KOD_Attribute_PlayersItemStats[target:getGuid()]
        end
        if targetStats then
            local targetStatsBase = targetStats.baseStats
            if targetStatsBase then
                if targetStatsBase.deffence then
                    attackMultipler = attackMultipler - targetStatsBase.deffence
                end
            end
            local targetElementOffence = targetStats.elementDeffence
            if targetElementOffence then
                if targetElementOffence[primaryType] then
                    attackMultipler = attackMultipler - targetElementOffence[primaryType]
                end
            end
        end
        if attackMultipler < maxDamageReduction then
            attackMultipler = maxDamageReduction
        end
        return primaryDamage * (attackMultipler/100), primaryType, secondaryDamage, secondaryType
    end
    KOD_Attribute_onManaChange:register()

    local KOD_Attribute_onLogin = CreatureEvent("KOD_Attribute_onLogin")
    function KOD_Attribute_onLogin.onLogin(player)
        player:registerEvent("KOD_Attribute_onHealthChange")
        player:registerEvent("KOD_Attribute_onManaChange")

        KOD_Attribute_PlayersItemStats[player:getGuid()] = {}

        local query = db.storeQuery("SELECT `health`,`mana` FROM players where `id`="..player:getGuid())
        for i = CONST_SLOT_HEAD, CONST_SLOT_AMMO do
            local fromPosition = {x = 65535, y = 65535}
            local toPosition = {x = 65535, y = i}
            local item = player:getSlotItem(i)
            KOD_Attribute_onEquipItem(player, item, i)
        end

        if query then
            local health = tonumber(result.getDataString(query, 'health'))
            local mana = tonumber(result.getDataString(query, 'mana'))
            local playerHealth = player:getHealth()
            local playerMana = player:getMana()
            if playerHealth < health then
                player:addHealth(health - playerHealth)
            end
            if playerMana < mana then
                player:addMana(mana - playerMana)
            end
            result.free(query)
        end
        return true
    end
    KOD_Attribute_onLogin:register()

    local KOD_Attribute_onLogout = CreatureEvent("KOD_Attribute_onLogout")
    function KOD_Attribute_onLogout.onLogout(player)
        KOD_Attribute_PlayersItemStats[player:getGuid()] = nil
        return true
    end
    KOD_Attribute_onLogout:register()
end