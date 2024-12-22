local startup = GlobalEvent("prey_onStartup")
function startup.onStartup()
	Prey.initMonsters()
	Prey.initNetworkMsg()
	return true
end
startup:register()


local login = CreatureEvent("prey_onLogin")
function login.onLogin(player)
	--player:loadPreyData()
	--player:sendPreyAllSlotsData()
    return true
end
login:register()

local login = CreatureEvent("prey_onLogout")
function login.onLogout(player)
	player:savePreyData()
    return true
end
login:register()

local handlerBuy = PacketHandler(0xEB)
function handlerBuy.onReceive(player, msg)
    local slot = msg:getByte()
    local actionMsg = msg:getByte()
	print("action", slot, actionMsg)
	
	--[[
		jeśli wybrany monster to
		action:
			0 - get new grid
			1 - reroll bonus
			3 - select from list
			4 - accept list
	]]

	-- done:
	--[[
		inactive
		grid selection
		list selection
		selected monsters
	]]

	if actionMsg == Prey.getConst().ACTION_MSG.NEW_GRID then
		print("NEW_GRID")
		player:setPreyDataState(slot, Prey.getConst().DATA_STATE.SELECTED_MONSTER)
	elseif actionMsg == Prey.getConst().ACTION_MSG.BONUS_REROLL then
		print("BONUS_REROLL")
	elseif actionMsg == Prey.getConst().ACTION_MSG.GRID_ACCEPT then
		print("MONSTER ACCEPT")
		local gridSlot = msg:getByte()
		player:setPreySelectedMonsterIndex(slot, gridSlot)
		player:setPreyDataState(slot, Prey.getConst().DATA_STATE.ACTIVE)
	elseif actionMsg == Prey.getConst().ACTION_MSG.LIST_SELECTION then
		print("LIST_SELECTION")
	elseif actionMsg == Prey.getConst().ACTION_MSG.LIST_ACCEPT then
		print("LIST_ACCEPT")
		local raceId = msg:getU16()
		player:setPreyListSelectedMonsterRaceId(slot, race)

		--player:sendPreyListSelection(slot)
	end


	player:sendPreyAllSlotsData()
	--dump_p(getPlayerData(player))
end
handlerBuy:register()