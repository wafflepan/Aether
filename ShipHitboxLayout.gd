extends Node2D

#Manages info and methods for a ship's internal layout and hitboxes

#For now, this is just represented by including smaller hitboxes inside and raycasting through the ship to determine what's hit.

#When a ship is hit, check angle and armor stuff, determine if the shot would bounce off, then
#Cast a straight ray through the ship and for each room hit, damage the room then decrease the shot penetration accordingly
#Proceed until shot runs out of penetration, or no more rooms are found (shot fully penetrates ship)

class ShipRoom:
	var id = null
	var room_volume = null #Can be overridden manually, but should be calculated at runtime
	var poly = null
	var room_name = null
	var room_weight = null
	var pos = null
	var polycolor = Color(.2,.2,.2,.4)
	var poly_size_offset = 0
	func _init(num,rname,weight=1,loc=Vector2(),polybuffer=0):
		id = num
		room_name = rname
		room_weight = weight
		pos=loc
		poly_size_offset=-polybuffer
	func addTLink(r):
		if !triangle_links.has(r):
			triangle_links.append(r)
	var triangle_links = [] #List of other room IDs that are adjacent via delauney. Used for midpoints.

var shiprooms = []

#Procedure:
#Take each position of the room and its weighting
#Determine voronoi polygon for all room points
#Union/snip with outline shape
#Smooth/tweak rooms, squish down really long ones into more squareish

func _ready():
	var pol = [Vector2(-50,-50),Vector2(50,-50),Vector2(50,50),Vector2(-50,50)]
#	$ShipOutline.polygon=pol
	var font = DynamicFont.new()
	var f_data = DynamicFontData.new()
	f_data.font_path = "res://Lobster-Regular.ttf"
	font.font_data = f_data
	debug_font = font
	generateRooms()
	splitRoomPolygons(shiprooms)
	finalizePolygons(shiprooms)
	makeHitboxes(shiprooms)

func makeHitboxes(rooms):
#	var full = CollisionPolygon2D.new()
#	full.polygon = $ShipOutline.polygon
#	$Hitboxes.add_child(full)
	for room in rooms:
		var box = KinematicBody2D.new()
		var newcollider = CollisionPolygon2D.new()
		newcollider.polygon=room.poly
		newcollider.name = room.room_name
		box.name = room.room_name
		$Hitboxes.add_child(box)
		box.add_child(newcollider)

func finalizePolygons(rooms:Array):
	for room in rooms:
		var results = Geometry.offset_polygon_2d(room.poly,-1.5+room.poly_size_offset)
		if results:
			room.poly = results[0]
	

func generateRooms():
	var offset =Vector2(0,0)
	var engines = ShipRoom.new(0,"Engines",1.25,Vector2(-25,0)+offset)
	var bridge = ShipRoom.new(1,"Bridge",.9,Vector2(-10,0)+offset,1)
	var crew = ShipRoom.new(2,"Crew",.9,Vector2(10,-4)+offset)
	var munitions = ShipRoom.new(3,"Ammo",1,Vector2(4,3))
	var guns = ShipRoom.new(4,"Gunnery",1.1,Vector2(30,0))
	var mall = ShipRoom.new(5,"Mall",.51,Vector2(30,3))
	shiprooms = [engines,crew,munitions,bridge,guns,mall]
#	shiprooms = [engines,bridge,crew]
#	shiprooms = [engines]

var debug_lines = {}
var debug_raycast = Vector2()
var midpointvectors = {}
var debug_raycast_results = []

var room_dict = {}

func splitRoomPolygons(rooms:Array):
	var startpoly = $ShipOutline.polygon
	var del_dict = {}
	var roompoints = []
	for r in rooms:
		roompoints.append(r.pos)
		r.poly=startpoly
	var del = Geometry.triangulate_delaunay_2d(roompoints)
#	print(del)
	for i in range(0,del.size(),3):
		for j in range(0,3): #For each of the three triangle indices:
			var room_id = del[i+j]
			var current_room = rooms[del[i+j]]
			#For each index in the triangle, associate the other two as neighbors.
			if !del_dict.has(room_id):
				del_dict[room_id] = [] #Add the room to the dict
			for k in range(1,3):
				var index = fposmod(j+k,3)
				if !del_dict[room_id].has(del[i+index]):
					del_dict[room_id].append(del[i+index]) #Add the neighbor ID to the room entry
					var neighbor_room = rooms[del[i+index]]
					var midpoint = (neighbor_room.pos + rooms[room_id].pos)/2
					var vec = (neighbor_room.pos - current_room.pos)
					vec = Vector2(-vec.y,vec.x)
					var cutline = Geometry.offset_polyline_2d([midpoint+vec*100,midpoint-vec*100],0.001)[0]
					var roompoly = current_room.poly
					var snipped = Geometry.clip_polygons_2d(roompoly,cutline)
					for result_poly in snipped:
						if Geometry.is_point_in_polygon(current_room.pos,result_poly):
							current_room.poly = result_poly
							break

var firing_point = Vector2()

func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == BUTTON_LEFT:
			for r in shiprooms:
				r.polycolor = Color(.5,.5,.5,.4)
			printClosestRoomInfo(get_global_mouse_position())
		elif event.button_index == BUTTON_MIDDLE:
			firing_point = get_global_mouse_position()
			debug_raycast = [firing_point , firing_point + Vector2(0,100)]
			projectileRoomRaycast(firing_point,firing_point+Vector2(0,100),100)
			update()
		elif event.button_index == BUTTON_RIGHT:
			pass
			debug_raycast = [firing_point , get_global_mouse_position()]
			projectileRoomRaycast(firing_point,get_global_mouse_position(),100)
			var bullet = load("res://WeaponProjectile.tscn").instance()
			bullet.position = firing_point
			bullet.firedby = self
			bullet.accuracy = 100
			bullet.rotation = (get_global_mouse_position()-firing_point).angle()
			var turretdata = GlobaLturretStats.getTurretData("basic")
			bullet.setupProjectile(turretdata)
			self.add_child(bullet)
			update()

var debugdistpoints = []
var distSortOrigin = Vector2()
func distSort(a,b):
	if distSortOrigin.distance_squared_to(a) < distSortOrigin.distance_squared_to(b):
		return true
	return false

func projectileRoomRaycast(start,vec,pen):
	return
	distSortOrigin = start
	debug_raycast_results=[]
	var room_point_list = []
#	print("Raycast Test starting at ",start," to ",vec)
	var result_list = {}
	var line = PoolVector2Array([start,vec])
	var ship_total = Geometry.intersect_polyline_with_polygon_2d([start,vec],$ShipOutline.polygon)
	var impact_start
	if !ship_total:
		return
	else:
		impact_start = ship_total[0]
		room_point_list = [ship_total[0][0]]
		for room in shiprooms:
			var pol = room.poly
			var results = Geometry.intersect_polyline_with_polygon_2d(line,pol)
			if results:
				room_point_list.append_array(results[0])
				debug_raycast_results.append(results[0])
				result_list[room] = results[0]
		room_point_list.append(ship_total[0][1])
		print(room_point_list)
		room_point_list.sort_custom(self,"distSort")
		print(room_point_list)
		debugdistpoints = room_point_list
		for point in room_point_list:
			print(start.distance_squared_to(point))
#		print("Raycast Results:")
#		for room in result_list:
#			if result_list[room].size():
#				print("Room: ",room.room_name,"  Segment Length: ",result_list[room][0].distance_to(result_list[room][1]))

func printClosestRoomInfo(pos):
	var c = null
	var dist = INF
	for room in shiprooms:
		if pos.distance_squared_to(room.pos) < dist:
			c=room
			dist=pos.distance_squared_to(room.pos)
	c.polycolor = Color(1,0,1,1)
	print("Room: ",c.room_name,"  ID: ",c.id)
	update()

func closestPointOnPolygon(point:Vector2,poly:PoolVector2Array):
	var closest = null
	var dist = INF
	for i in range(0,poly.size()):
		var segment1 = poly[i]
		var segment2 = poly[fposmod(i+1,poly.size())]
		var new = Geometry.get_closest_point_to_segment_2d(point,segment1,segment2)
		var newdist = new.distance_squared_to(point)
		if newdist < dist:
			closest=new
			dist=newdist
	return closest

func centroid(points:Array,weights:Array):
	var sum = Vector2()
	var weightsum = 0.0
	for i in points.size():
		sum += points[i] * (1.0 / weights[i])
		weightsum += 1.0/(weights[i])
	sum = sum/weightsum
	return sum

func drawRoomPolygons(rooms):
	for i in rooms.size():
		if rooms[i].poly:
			var color = Color(1 - float(i/rooms.size()),0 + float(i)/rooms.size(),0.5,0.5)
			draw_polygon(rooms[i].poly,PoolColorArray([color]))
var del_debug = []
var del_points = []
var centroids_debug = []
var outside_debug = []
var debug_font = null

func _draw():
#	drawRoomPolygons(shiprooms)
	for point in del_points:
		draw_circle(point,.8,Color(1,0,0))
	draw_circle(firing_point,10,Color(0,0,0))
#	if debug_raycast:
#		draw_line(debug_raycast[0],debug_raycast[1],Color(0,1,1),1)
#		for linepair in debug_raycast_results:
#			draw_circle(linepair[0],2,Color(1,0,0))
#			draw_circle(linepair[1],2,Color(0,1,1))
	for i in debugdistpoints.size():
		draw_circle(debugdistpoints[i],1.5,Color(0.1+i/10.0,0.1+i/10.0,0.1+i/10.0,.8))
