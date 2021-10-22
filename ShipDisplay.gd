extends Control

var ship = null
var polygonscale = Vector2(1,1)

onready var displaycenter = self.rect_size/2


func _ready():
	pass
#	var test2 = load("res://TallShip.tscn")
#	var test = load("res://TallShip.tscn").instance()
#	assignShip(test)

func clearMount(mount):
	pass
	mount.clearMount()

func swapMountEquip(mount,new):
	mount.assignMount(new)

func assignShip(sh):
	ship=sh
	#Assign the ship that's going to be displayed, then update the model
	loadPoly()
	placeMounts()
#	print("Finished Loading Ship")

func getShipMounts():
	var list = []
	for child in $ShipOutline.get_children():
		list.append(child)
	return list

func placeMounts(): #Place weapon mounts, then assign each mount and ID its corresponding weapon where applicable.
	#Since mounts here are just for display purposes (for now, todo: DPS calculations and stuff), just a dict of name and display texture
#	var test1 = ship.get_node("Hardpoints").get_children()
	for mount in ship.mounts:
		var t = load("res://ShipHardpointEquipSlot.tscn").instance()
		t.setupMount(mount)
		t.connect("gui_input",self,"hardpointInput")
		$ShipOutline.add_child(t)

func hardpointInput(input):
	if input is InputEventMouseButton:
		if input.button_index == BUTTON_LEFT:
			if !input.is_pressed():
				print("Button Released")
			else:
				pass

func hardpoint_button():
	print("Clicked hardpoint")

func loadPoly():
	var poly = ship.get_node("ShipOutline")
	$ShipOutline.polygon = poly.polygon
	var sprite = ship.get_node("ShipSprite")
	var image = sprite.texture.get_data()
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image)
	polygonscale = self.rect_size / bitmap.get_size()
	polygonscale = min(polygonscale.x,polygonscale.y)
	$ShipOutline.scale=polygonscale*Vector2(1,1)
	$ShipOutline.position = displaycenter

#var debug1 = []
var offset= []
#var pscale

#func _draw():
##	draw_set_transform(Vector2(),-PI/2,$ShipOutline.scale)
#	pass
#	draw_circle(Vector2(),2,Color(0,1,1))
#	if ship:
#		for t in ship.get_node("Hardpoints").get_children():
#
#			draw_circle(t.position,2,Color(1,0,0))
##	draw_set_transform(offset,0,Vector2(1,1)*pscale)
##	draw_polyline(debug1,Color(1,0,0))
#	draw_circle(Vector2(),40,Color(1,0,0,0.3))
