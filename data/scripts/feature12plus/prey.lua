local startup = GlobalEvent("prey_onStartup")
function startup.onStartup()
	print("Prey.initMonsters()")
	Prey.initMonsters()
	return true
end
startup:register()


local login = CreatureEvent("prey_onLogin")
function login.onLogin(player)
	local c = Prey.getConfig()
	local const = Prey.getConst()

	player:sendPreySelectedMonster(0, "Demon", const.BONUS_TYPE.DEFENSE, const.BONUS_BASE.DEFENSE)

	if player:isPremium() then
		player:sendPreyLockedSlot(const.SLOT.SECOND, true)
	else
		player:sendPreyLockedSlot(const.SLOT.SECOND, true)
	end

	if c.isThirdSlotFree == false then
		player:sendPreyLockedSlot(const.SLOT.THIRD, false)
	else

	end

    return true
end
login:register()