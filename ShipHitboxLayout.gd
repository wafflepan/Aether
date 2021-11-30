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
	func _init(num,rname,weight=1,loc=Vector2()):
		id = num
		room_name = rname
		room_weight = weight
		pos=loc
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
#	generateRoomPolygons(shiprooms)
	splitRoomPolygons(shiprooms)
	finalizePolygons(shiprooms)

func finalizePolygons(rooms:Array):
	pass
	

func generateRooms():
	var offset =Vector2(0,0)
	var engines = ShipRoom.new(0,"Engines",1.25,Vector2(-25,0)+offset)
	var bridge = ShipRoom.new(1,"Bridge",.9,Vector2(-10,0)+offset)
	var crew = ShipRoom.new(2,"Crew",.9,Vector2(10,-4)+offset)
	var munitions = ShipRoom.new(3,"Ammo",1,Vector2(4,3))
	var guns = ShipRoom.new(4,"Gunnery",1.1,Vector2(30,0))
	var mall = ShipRoom.new(5,"Mall",.51,Vector2(30,3))
	shiprooms = [engines,bridge,crew,munitions,guns,mall]
#	shiprooms = [engines,bridge,crew]

var debug_lines = {}
var midpointvectors = {}

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

func generateRoomPolygons(rooms:Array):
	var roompoints=[]
	var roomweights = []
	for r in rooms:
		roompoints.append(r.pos)
		roomweights.append(r.room_weight)
	var del = Geometry.triangulate_delaunay_2d(roompoints)
	print(del)
	var outside_edges = [] #List of edge pairs that have no corresponding pair (no shared triangles)
	var inside_edges = [] #List of edge pairs that have duplicates
	del_debug = del
	del_points = roompoints
	var triangles = []
	for i in range(0,del.size(),3):
		rooms[del[i]].addTLink(rooms[del[i+1]])
		rooms[del[i]].addTLink(rooms[del[i+2]])
		rooms[del[i+1]].addTLink(rooms[del[i+2]])
		rooms[del[i+1]].addTLink(rooms[del[i]])
		rooms[del[i+2]].addTLink(rooms[del[i]])
		rooms[del[i+2]].addTLink(rooms[del[i+1]])
		
		#Test whether the edge already exists in either list, if not then add it to outside edges.
		#Otherwise, add it to the inside_edges list and erase from outside edges
		
		for offset in range(0,3): #Iterate through all three points and check inside/outside
			var x = del[i+offset]
			var y = del[i+fposmod(offset+1,3)]
			var pair = Vector2(min(x,y),max(x,y))
			if pair in outside_edges or pair in inside_edges:
				outside_edges.erase(pair)
				if !pair in inside_edges:
					inside_edges.append(pair)
			else:
				outside_edges.append(pair)
		triangles.append(centroid([rooms[del[i]].pos,rooms[del[i+1]].pos,rooms[del[i+2]].pos],[rooms[del[i]].room_weight,rooms[del[i+1]].room_weight,rooms[del[i+2]].room_weight]))
		
	for i in triangles.size(): #For each triangle centroid:
		pass
		
	outside_debug=outside_edges
	
	centroids_debug = triangles
	update()

func _input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
		for r in shiprooms:
			r.polycolor = Color(.5,.5,.5,.4)
		printClosestRoomInfo(get_global_mouse_position())

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
#	print(rooms)
#	draw_polygon(rooms.back().poly,PoolColorArray([Color(randf(),randf(),randf(),0.4)]))
	for i in rooms.size():
#		print(room.poly)
		if rooms[i].poly:
			var color = Color(1 - float(i/rooms.size()),0 + float(i)/rooms.size(),0.5,0.5)
			draw_polygon(rooms[i].poly,PoolColorArray([color]))
var del_debug = []
var del_points = []
var centroids_debug = []
var outside_debug = []
var debug_font = null
func _draw():
#	font.font_data = load("res://Lobster-Regular.ttf")
#	font.size = 2
	drawRoomPolygons(shiprooms)
	for point in del_points:
		draw_circle(point,.8,Color(1,0,0))
#	for i in range(0,del_debug.size(),3):
#		draw_line(del_points[del_debug[i]],del_points[del_debug[i+1]],Color(0,1,1))
#		draw_line(del_points[del_debug[i+1]],del_points[del_debug[i+2]],Color(0,1,1))
#		draw_line(del_points[del_debug[i+2]],del_points[del_debug[i]],Color(0,1,1))
#	for i in range(centroids_debug.size()):
#		draw_circle(centroids_debug[i],1,Color(0,0,0))
#		draw_string(debug_font,centroids_debug[i],str(i))
#	for linepair in outside_debug:
#		draw_line(del_points[linepair.x],del_points[linepair.y],Color(0,.21,.41,.5),2)
#	for room in debug_lines:
#		for vec in debug_lines[room]:
#			draw_line(room.pos,room.pos+vec,Color(1,0.56,0.2,0.8),1)
#	for point in midpointvectors:
#		draw_line(point-midpointvectors[point]*5,point+midpointvectors[point]*5,Color(0,0,0.5),2)
