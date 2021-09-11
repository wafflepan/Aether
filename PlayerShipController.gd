extends Node

#Mediates player input into ship orders

#THINGS A PLAYER CAN DO:
# - Designate Targets (Shift for multiple)
# - Designate Navigation Waypoints (Shift for multiple)

var ship
var gameworld

var type = "Player"

func _ready():
	ship = get_parent()
	gameworld = ship.get_parent().get_parent()
	gameworld.playercontroller=self

func shipNavigationOrder(pos):
	ship.setHeading(pos)
	ship.displayNavigation()

func shipTargetingOrder(tg):
	
	if Input.is_action_pressed("input_additive_order"):
		ship.addTarget(tg)
	else:
		ship.clearTargets()
		ship.addTarget(tg)
		gameworld.selector.chooseTarget(tg)

func targetCleared(tg):
	gameworld.selector.clearTarget()

func shipIncreaseSpeed(amt):
	ship.throttleIncrease()

func shipDecreaseSpeed(amt):
	ship.throttleDecrease()
