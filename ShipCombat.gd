extends Node2D

###GLOBAL TODO

#Load Ship Data From File
#Create Ship Variants
#Spellcasting Mounts
#Manual-Fire Mounts
#Internal Ship Rooms
#Internal Room Damage
#Localized Armor Bitmask
#Mission Builder
#Island Graphics
#Island Mountain Colliders
#Collision Damage/Run Aground/Bump Ships
#Weapon Groups
#Weapon Group Editing



#Signal manager for selection, destruction of ships, etc.

var playercontroller = null
onready var camera = $Camera
onready var selector = $SelectionIndicator

var scene_data = null

func _ready():
	scene_data = SceneSwitcher.takeStack()
	registerShips()
	if scene_data:
		$Entities/TallShip.setShipStats(scene_data["ship"])
	if playercontroller:
		assignPlayerShip(playercontroller.ship)
	$ScreenTransition.fadeIn()
	$MissionStatsRecorder.startMissionRecording()

func switchToPostCombatScreen(mis):
	$MissionStatsRecorder.finishMissionRecording()
	$ScreenTransition.fadeOut()
	yield($ScreenTransition,"finished")
	SceneSwitcher.giveStack({"mission_stats":$MissionStatsRecorder.getMissionDict()})
	SceneSwitcher.switchScenes("res://PostMissionScreen.tscn")

func registerShips():
	for child in $Entities.get_children():
		if child is KinematicBody2D:
			print("Registered Ship: ",child.name)
			child.registerSignals(self)

func assignPlayerShip(sh):
	if "ship" in scene_data:
		sh.setShipStats(scene_data["ship"])
	$UI/MissionInfo.camera=camera
	$UI.setPlayerShip(sh)
	remove_child(camera)
	sh.add_child(camera)

func getPlayerCamera():
	return playercontroller.ship.get_node("Camera")

func shipRightClicked(sh):
	pass

func shipLeftClicked(sh):
	playercontroller.shipTargetingOrder(sh)

func shipHovered(sh):
	pass

func _unhandled_input(event):
	if playercontroller:
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
