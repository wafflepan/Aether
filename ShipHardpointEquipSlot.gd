extends Control

var mount_data = null
var weapon_data = null

func setupMount(mount): #Adjust where the mount is positioned and stuff
	mount_data=mount
	self.rect_position = (mount_data.location) - self.rect_min_size/2
	if mount_data.weapon:
		assignMount({"turret_icon":GlobaLturretStats.getTurretIconFromType(mount_data.weapon.turret_type),"turret_type":mount_data.weapon.turret_type})
	#TODO: Stuff here about the size/type/etc changing the displayed slot shape.

func assignMount(turret):
	weapon_data = turret
	$TurretIcon.texture = weapon_data["turret_icon"]

func clearMount():
	weapon_data=null
	$TurretIcon.texture=null

func can_drop_data(position, data):
#	print("Can slot accept ",data,"?")
	return true

func drop_data(position, data):
	pass
#	print("Acquired data: ",data)
	assignMount(data)

func get_drag_data(position):
	pass
#	print("DragData")


func _on_ShipHardpointEquipSlot_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT and event.is_pressed():
			clearMount()
