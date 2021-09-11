extends Node2D

#Signal manager for selection, destruction of ships, etc.

var playercontroller = null
onready var selector = $SelectionIndicator

func _ready():
	registerShips()
	playercontroller.gameworld.assignPlayerShip(playercontroller.ship)

func registerShips():
	for child in $Entities.get_children():
		if child is KinematicBody2D:
			print("Registered Ship: ",child.name)
			child.registerSignals(self)

func assignPlayerShip(sh):
	$UI.setPlayerShip(sh)

func shipRightClicked(sh):
	pass

func shipLeftClicked(sh):
	playercontroller.shipTargetingOrder(sh)

func shipHovered(sh):
	pass

func _unhandled_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == BUTTON_RIGHT:
			playercontroller.shipNavigationOrder(get_global_mouse_position())
	elif Input.is_action_just_pressed("speed_up"):
		playercontroller.shipIncreaseSpeed(10)
	elif Input.is_action_just_pressed("speed_down"):
		playercontroller.shipDecreaseSpeed(10)


#SHIP RETURN SIGNALS
func on_ship_clicked_left(sh):
	shipLeftClicked(sh)

func on_ship_clicked_right(sh):
	pass

func on_ship_hovered(sh):
	pass

func on_ship_unhovered(sh):
	pass
