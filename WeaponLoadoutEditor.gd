extends Node


#Screen for altering the loadout of a ship by clicking and dragging equipment onto slots

#TODO

#Load ship and slots, and display in center: Dropdown list of available ships?
#Load all weapon types, display on side
#Display weapon info on right pane when clicked/hovered

onready var weaponlist = $ShipHardpointDisplay/ShipWeaponLoadout/WeaponList/MarginContainer/ScrollContainer/WeaponListContainer
onready var shipdisplay = $ShipHardpointDisplay/ShipWeaponLoadout/ShipDisplayBounds/MarginContainer/ShipDisplay

var chosenship
var scenedata

var selected_ship_slot = null
var selected_equipment = null

func _ready():
	scenedata = SceneSwitcher.readStack()
	if scenedata.has("chosen_ship"):
		chosenship=scenedata["chosen_ship"]
	if !chosenship:
		chosenship = load("res://TallShip.tscn").instance()
	chosenship.loadWeaponMounts()
	chosenship.assignThrottleValues()
	shipdisplay.assignShip(chosenship)
	loadWeaponButtons()

func clearWeaponButtons():
	for child in weaponlist.get_children():
		child.queue_free()

var helditem
onready var helditemsprite = $ShipHardpointDisplay/HeldItem

func _process(delta):
	if helditem:
		if !Input.is_mouse_button_pressed(BUTTON_LEFT):
			helditem=null
			helditemsprite.visible=false
		else:
			helditemsprite.rect_position=helditemsprite.get_global_mouse_position() - (helditemsprite.rect_size/4)

func buttonInput(inputevent,weapon):
	if inputevent is InputEventMouseButton:
		if inputevent.is_pressed() and inputevent.button_index == BUTTON_LEFT:
			pass
#	print(weapon,"  ",inputevent)
	pass
#	helditem = weapon
#	helditemsprite.texture = weapon.projectile_texture
#	helditemsprite.visible=true

func loadWeaponButtons():
	#Load an instance of each weapon button for now
	var weapons= GlobaLturretStats.getTurretList()
	
	for turret in weapons:
		var turretdata = weapons[turret]
#		var button = $ShipHardpointDisplay/WeaponList/MarginContainer/ScrollContainer/ButtonTemplate.duplicate()
		var button = load("res://WeaponEquipEntry.tscn").instance()
		button.assignWeapon(turretdata)
#		button.icon = turretdata.projectile_texture
		weaponlist.add_child(button)
		button.connect("mouse_entered",self,"buttonMouseEntered",[button])
		button.connect("mouse_exited",self,"buttonMouseExited",[button])
		button.connect("gui_input",self,"buttonInput",[turretdata])

var hovered = null

func buttonMouseEntered(b):
	if hovered != b:#New hover
		infoScreenClear()
	hovered=b
	infoScreenUpdateWeapon(hovered)
	
	#Send weapon type to the weapon info pane
func buttonMouseExited(b):
	if hovered == b:
		infoScreenClear()
		hovered=null
	else:
		print("Exited a non-hovered button, wtf. overlap?")

func infoScreenClear():
	pass
	$ShipHardpointDisplay/ShipWeaponLoadout/WeaponInfo/MarginContainer/WeaponName.bbcode_text=""

func infoScreenUpdateWeapon(wp):
	if wp:
		pass
		$ShipHardpointDisplay/ShipWeaponLoadout/WeaponInfo/MarginContainer/WeaponName.bbcode_text = wp.wp.display_name

func exportShipData(): #Convert the final ship loadout back into strings or JSON or some shit.
	var resultdict = {}
	#A list of mount IDs and the weapons filling them, as identifier strings. TODO: later this'll need to have mod slots or whatever.
	var shipmounts = []
	var m = shipdisplay.getShipMounts()
	for mount in m:
		var test = mount
		shipmounts.append({"size":mount.mount_data.size,"location":mount.mount_data.location,"rotation":mount.mount_data.angle})
		if mount.weapon_data:
			shipmounts.back()["weapon"]=mount.weapon_data["turret_type"]
		else:
			shipmounts.back()["weapon"]=null
	resultdict["ship_mounts"] = shipmounts
	resultdict["display_polygon"] = chosenship.get_node("ShipOutline").polygon
	resultdict["max_speed"] = chosenship.maxspeed
	resultdict["throttle_slots"] = chosenship.throttleslots
	resultdict["hullpoints_max"] = chosenship.hullpointsmax
	resultdict["max_turn_rate"] = chosenship.rotation_rate_max
	resultdict["max_turn_rate_change"] = chosenship.rotation_rate_change_max
	
	return resultdict


#	var mounts = shipstats["ship_mounts"]
#	for mount in mounts:
#		addMount(mount["size"],mount["location"],mount["rotation"])
#	diagrampoly = shipstats["display_polygon"]
#	maxspeed = shipstats["max_speed"]
#	throttleslots = shipstats["throttle_slots"]
#	hullpointsmax = shipstats["hullpoints_max"]
#	hullpoints = hullpointsmax
#	rotation_rate_max = shipstats["max_turn_rate"]
#	rotation_rate_change_max = shipstats["max_turn_rate_change"]
#
#	if shipstats.has["pid_settings"]:
#		pid_p = shipstats["pid_settings"][0]
#		pid_d = shipstats["pid_settings"][1]
#

func _on_ConfirmButton_pressed():
	var results = exportShipData()
	SceneSwitcher.addData("ship",results)
	SceneSwitcher.switchScenes("res://ShipCombat.tscn")
