local bullseye = Condition(CONDITION_ATTRIBUTES)
bullseye:setParameter(CONDITION_PARAM_TICKS, 10 * 1000)
bullseye:setParameter(CONDITION_PARAM_SELLMODIFIER_ID, 19)
bullseye:setParameter(CONDITION_PARAM_SELLMODIFIER_LEVEL, 100)
bullseye:setParameter(CONDITION_PARAM_SELLMODIFIER_MAGICLEVEL, 100)
bullseye:setParameter(CONDITION_PARAM_SELLMODIFIER_MANACOST, 100)
bullseye:setParameter(CONDITION_PARAM_SELLMODIFIER_COOLDOWN, 1000)
bullseye:setParameter(CONDITION_PARAM_SELLMODIFIER_BOOSTDAMAGE, 100)
bullseye:setParameter(CONDITION_PARAM_BUFF_SPELL, true)

local fireBug = Action()

function fireBug.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	player:addCondition(bullseye)
	return true
end

fireBug:id(5468)
fireBug:register()
