extends Node2D

#Create an island with noise by adding together blobs until sufficient volume or area is obtained
#Phase two is to generate a heightmap based on the same noise

var noise

var checkrad = 50
var desired_area = 1000
var desired_size = 200

var pol = []

var spacing = 25

var elevations = {}
var seedpoints=20

var font

var max_radius
var avg_radius

export(int) var start_seed = null

var circlepoints2 = [
Vector2(1,0)*checkrad,Vector2(.86,.5)*checkrad,Vector2(.707,.707)*checkrad,Vector2(.5,.86)*checkrad,
Vector2(0,1)*checkrad,Vector2(-.86,.5)*checkrad,Vector2(-.707,.707)*checkrad,Vector2(-.5,.86)*checkrad,
Vector2(-1,0)*checkrad,Vector2(-.86,-.5)*checkrad,Vector2(-.707,-.707)*checkrad,Vector2(-.5,-.86)*checkrad,
Vector2(0,-1)*checkrad,Vector2(.86,-.5)*checkrad,Vector2(.707,-.707)*checkrad,Vector2(.5,-.86)*checkrad]

var circlepoints = [
Vector2(1,0)*checkrad,Vector2(0,-1)*checkrad,Vector2(-1,0)*checkrad,Vector2(0,1)*checkrad
]

func setParameters(area,size):
	desired_area=area
	desired_size=size

func calculateStats(island_points):
	var center = centroid(island_points)
	var totalradius = 0
	var chosenpoint = null
	var chosenradius = 0
	for point in island_points:
		var radius = center.distance_to(point)
		totalradius += radius
		if radius > chosenradius:
			chosenradius = radius
			chosenpoint = point
	max_radius = chosenradius
	avg_radius = totalradius/island_points.size()

var SQUARE_OVERRIDE = 0

func _ready():
	spacing=desired_size
	seedpoints=desired_area
	font = load('res://new_dynamicfont.tres')
	font.size = 16
#	if start_seed:
#		seed(start_seed)
#	else:
	randomize()
	if SQUARE_OVERRIDE:
		var square = [Vector2(-1000,-1000),Vector2(1000,-1000),Vector2(1000,1000),Vector2(-1000,1000)]
		pol=square
#		$Polygon2D.polygon=pol
		$Collider.polygon=pol
		$Polygon2D.position = -centroid(pol)
		$Collider.position=$Polygon2D.position
#		calculateStats($Polygon2D.polygon)
		update()
		return
	noise = OpenSimplexNoise.new()
	pol = circlepoints
	if !pol:
		pol=circlepoints
	generatePoints()
	generateIslandPolygonFirstPass(pol)
	var results = smoothPolygon($Polygon2D.polygon)
	$Polygon2D.polygon=results
	results = roughenPolygon($Polygon2D.polygon)
	pol=Geometry.merge_polygons_2d(results,PoolVector2Array([]))
	pol=pol[0]
	$Polygon2D.polygon=pol
	$Collider.polygon=pol
	var offset = centroid(pol)
	$Polygon2D.position=-offset
	$Collider.position=-offset
	calculateStats($Polygon2D.polygon)
	update()
var debugpoints = []
func roughenPolygon(array,iterations=4):
	var p = array
	var final = []
	var itr = 0
	while itr < iterations:
		final.clear()
		for i in range(0,p.size(),1):#For each line segment including wraparound
			final.append(p[i])
#			print("added base ",p[i])
			var next = i+1
			if next == p.size():
				next=0
			var point = lerp(p[i],p[next],.5) #Get a point somewhere in the middle of the lines
			if p[i].distance_squared_to(point) > spacing*spacing:
				var normal = point.normalized()
				var adjust = Vector2(normal.y,normal.x) * (rand_range(-5,5)*6/(itr+1))
#			var adjust = Vector2(normal.y,normal.x) * 35
#			adjust=Vector2()
				point = point + adjust
#			print("added mid", point)
				
				final.append(point)
				debugpoints.append(point)
		p=final.duplicate()
		itr+=1
	return final

func centroid(ar):
	var total = Vector2()
	for point in ar:
		total+= point
	total = total/ar.size()
#	print("centroid: ",total)
	return total

func choosePoint(start):
	#Choose a random point on the edge of the search radius
	var angle = rand_range(-PI,PI)
	return start + Vector2(cos(angle),sin(angle))*(checkrad-4)

func resolvePolygon(points):
	var resolve = Geometry.convex_hull_2d(points)
	if resolve.size():
		return resolve

var debug_currentshape = null
var debug_previous = null
var totalpoly = null
var dt

func generatePoints():
	for i in range(-30,30):
		for j in range(-30,30):
			elevations[Vector2(i,j)*spacing] = 0
	var polygon = [self.global_position]
#	polygon.append(choosePoint(polygon.back()))
	var x = 1#Iterate for now
	while x < seedpoints:
		x+=1
		var newpoint = choosePoint(polygon.back())
		polygon.append(newpoint)
	for point in polygon:
		var rounded = closestElevation(point)
		if rounded in elevations:
			elevations[rounded]+=1
	pol = polygon
#	dt = Geometry.triangulate_delaunay_2d(pol)
#	print(Geometry.triangulate_delaunay_2d(PoolVector2Array(polygon)))
#	pol = resolvePolygon(polygon)

func generateIslandPolygonFirstPass(points):
	var poly = PoolVector2Array()
	for point in points:
		var shape = PoolVector2Array([
Vector2(1,0)*checkrad+point,Vector2(0,-1)*checkrad+point,Vector2(-1,0)*checkrad+point,Vector2(0,1)*checkrad+point])
		if !poly.size():
			poly.append_array(shape)
		else:
			var clipped = Geometry.merge_polygons_2d(poly,shape)
			if clipped:
				poly=clipped[0]
		debug_previous=debug_currentshape
		debug_currentshape=shape
		totalpoly = poly
#		print(point)
#		update()
#		yield(get_tree().create_timer(.1),"timeout")
	debug_currentshape=null
	debug_previous=null
	update()
	$Polygon2D.polygon=poly

func closestElevation(point):
	pass
	return Vector2(stepify(point.x,spacing),stepify(point.y,spacing))

#func _draw():
#	draw_circle(Vector2(),max_radius,Color(1,0,0,0.4))
#	draw_circle(Vector2(),avg_radius,Color(0,1,0,0.2))
#	for point in $Polygon2D.polygon:
#		draw_circle(point,5,Color(1,1,1,lerp(1,0.01,float(Array($Polygon2D.polygon).find(point))/$Polygon2D.polygon.size())))
#	for point in debugpoints:
#		draw_circle(point,3,Color(1,0,0))
#	draw_circle(Vector2(),8,Color(0,0,1))
#	draw_circle(centroid($Polygon2D.polygon),8,Color(0,1,0))
#	if debug_currentshape:
##		draw_polygon(totalpoly,PoolColorArray([Color(.2,.2,.2,.5)]))
#		draw_polygon(debug_currentshape,PoolColorArray([Color(1,0,1)]))
#		if debug_previous:
#			draw_polygon(debug_previous,PoolColorArray([Color(.8,0,.8,0.5)]))
##	for point in pol:
##		draw_circle(point,checkrad,Color(0,0,1))
##	draw_polygon(pol,PoolColorArray([Color(1,0,0)]))
#	for point in pol:
#		var new = []
#		for arcpoint in circlepoints:
#			new.append(arcpoint+point)
##		draw_polygon(new,PoolColorArray([Color(1,0,1)]))
##	for x in $Polygon2D.polygon:
##		draw_circle(x,6,Color(.5,.5,1))
##	drawElevationGrid()
#	if dt:
#		drawDelEdges(pol,dt)
#	for i in range(pol.size()):
#		pass
#		var next = i+1
#		if next==pol.size():
#			next=0
#		draw_line(pol[i],pol[next],Color(randi()),rand_range(1,10),true)
#	if debugpoint:
#		draw_circle(debugpoint,8,Color(1,0,0))

var debugpoint = null

func smoothPolygon(p): #Connect every other point on the polygon to smooth and deform it
	var new = []
	for i in range(0,p.size(),2):
		new.append(p[i])
#		debugpoint = p[i]
#		update()
#		yield(get_tree().create_timer(.3),"timeout")
	return new

#func drawDelEdges(points,tri):
#	pass
#	for i in range(0,tri.size(),3): #Every set of three points
#		draw_circle(centroid(pol,[tri[i],tri[i+1],tri[i+2]]),5,Color(1,1,0))
#	for x in points:
#		draw_circle(x,4,Color(0.5,0.5,0.2))
#
#func centroid(array,points):
#	var total = Vector2()
#	for point in points:
#		total += array[point]
#	return total/points.size()

func drawElevationGrid():
	for i in range(-30,30):
		for j in range(-30,30):
#			draw_circle(Vector2(i,j)*spacing,10,Color(0.2,0.2,0.2))
			if Vector2(i,j)*spacing in elevations:
#				print(str(elevations[Vector2(i,j)*spacing]))
				draw_string(font,Vector2(i,j)*spacing - Vector2(4,-5),str(elevations[Vector2(i,j)*spacing]),Color(lerp(0,1,elevations[Vector2(i,j)*spacing]/3.0),1,1))


func _on_ProceduralIsland_input_event(viewport, event, shape_idx):
#	print("test")
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == BUTTON_LEFT:
			print("ISLAND STATS: ",max_radius,"  ",avg_radius)


func _on_ProceduralIsland_mouse_entered():
#	print("test")
	pass # Replace with function body.
