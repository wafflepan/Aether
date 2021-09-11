extends Node2D

var ship = null
var polygonscale = Vector2(1,1)

func _ready():
	pass
#	var test2 = load("res://TallShip.tscn")
#	var test = load("res://TallShip.tscn").instance()
#	assignShip(test)

func assignShip(sh):
	ship=sh
	#Assign the ship that's going to be displayed, then update the model
	loadPoly()
	placeTurrets()
	print("Finished Loading Ship")

func placeTurrets():
#	var test1 = ship.get_node("Hardpoints").get_children()
	for turret in ship.get_node("Hardpoints").get_children():
#		print("Added Turret")
		var t=load("res://ShipDiagramHardpoint.tscn").instance()
		t.rect_size = t.rect_size * polygonscale
#		print(t.rect_size)
		t.rect_position = (turret.position*$ShipOutline.scale).rotated(-PI/2) - t.rect_min_size/2
#		print($ShipOutline.scale)
		t.assignTurret(turret)
		add_child(t)
		t.button.connect("pressed",self,"hardpoint_button")

func hardpoint_button():
	print("Clicked hardpoint")

func loadPoly():
	var poly = ship.get_node("ShipOutline")
	$ShipOutline.polygon = poly.polygon
	var sprite = ship.get_node("ShipSprite")
	var image = sprite.texture.get_data()
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image)
	polygonscale = get_viewport().size / bitmap.get_size()
	polygonscale = min(polygonscale.x,polygonscale.y)
	$ShipOutline.scale=polygonscale*Vector2(1,1)*3

func createPoly():
	var sprite = ship.get_node("ShipSprite")
	var image = sprite.texture.get_data()

	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image)
	
#	var polygons = bitmap.opaque_to_polygons(Rect2(Vector2(bitmap.get_size().x/2,0), bitmap.get_size()),1) #RECT can be used to specify which section of the sprite to sample
	var polygons = bitmap.opaque_to_polygons(Rect2(Vector2(0,0), bitmap.get_size()),.1) #RECT can be used to specify which section of the sprite to sample
#	debug1=polygons[0]
	var polycopy = polygons
#	for point in polygons[0]:
#		polycopy.append(Vector2(-point.x,point.y)) #Mirroring
	var final = Geometry.merge_polygons_2d(polygons[0],polycopy)
	final = Geometry.offset_polygon_2d(final[0],17)
	final = Geometry.offset_polygon_2d(final[0],-19) #Cheap hacky rounding-off-corners method. Use UNION of this and the original polygon to snip pointy bits while preserving corners.
	final = Geometry.intersect_polygons_2d(final[0],polygons[0])
	final[0].append(final[0][0])
	var pscale = get_viewport().size / bitmap.get_size()
	pscale = min(polygonscale.x,polygonscale.y)
	$ShipDiagram.points=final[0]
	$ShipDiagram.scale = Vector2(1,1)*pscale
	$ShipOutline.width = $ShipOutline.width / pscale
	$ShipOutline.position = -bitmap.get_size()/2*pscale
	
	offset = -bitmap.get_size()/2*polygonscale
	pscale = polygonscale
	update()
#var debug1 = []
var offset= []
#var pscale

func _draw():
	draw_set_transform(Vector2(),-PI/2,$ShipOutline.scale)
	pass
	draw_circle(Vector2(),2,Color(0,1,1))
	if ship:
		for t in ship.get_node("Hardpoints").get_children():
			
			draw_circle(t.position,2,Color(1,0,0))
#	draw_set_transform(offset,0,Vector2(1,1)*pscale)
#	draw_polyline(debug1,Color(1,0,0))
