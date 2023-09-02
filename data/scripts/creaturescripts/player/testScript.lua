local testItem = Action()

function testItem.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	Game.loadMap("data/world/forgotten.otbm")
end

testItem:id(2280)
testItem:register()
