local chanceToBetterItem = 2 --more means less chance

function getItemAttack(uid) return ItemType(Item(uid):getId()):getAttack() end
function getItemDefense(uid) return ItemType(Item(uid):getId()):getDefense() end
function getItemArmor(uid) return ItemType(Item(uid):getId()):getArmor() end
function getItemWeaponType(uid) return ItemType(Item(uid):getId()):getWeaponType() end
function isArmor(uid) if (getItemArmor(uid) ~= 0 and getItemWeaponType(uid) == 0) then return true else return false end end
function isWeapon(uid) return (getItemWeaponType(uid) > 0 and getItemWeaponType(uid) ~= 4) end
function isShield(uid) return getItemWeaponType(uid) == 4 end
function isBow(uid) return (getItemWeaponType(uid) == 5 and (not ItemType(Item(uid):getId()):isStackable())) end

local function scanContainer(position)
	local corpse = Tile(position):getTopDownItem()
	if not corpse or not getContainerSize(corpse.uid) == 0 then
		return
	end
	if corpse and corpse:getType():isContainer()  then
		local corpSize = corpse:getSize()
		if not corpSize then
			return
		end
		if  corpSize <= 0 then
			return
		end
		for a = corpse:getSize() - 1, 0, -1 do
			local containerItem = corpse:getItem(a)
			if containerItem then
				local itemtype = ItemType(containerItem:getId())
				if itemtype:isStackable() == false and
						(isWeapon(containerItem.uid) or isArmor(containerItem.uid) or isBow(containerItem.uid) or isShield(containerItem.uid)) then

					if math.random(1, chanceToBetterItem) == 1 then
						containerItem:KOD_rollIAndSetItemAttributes()
						position:sendMagicEffect(171)
					end
				end
			end
		end
	end
end

local randomstats_loot = CreatureEvent("KOD_randomstats_loot")
function randomstats_loot.onKill(player, target)
	if not target:isMonster() then
		return true
	end

	addEvent(scanContainer, 100, target:getPosition())
	return true
end
randomstats_loot:register()

local randomstats_register = CreatureEvent("KOD_randomstats_login")
function randomstats_register.onLogin(player)
	player:registerEvent("KOD_randomstats_loot")
	return true
end
randomstats_register:register()
