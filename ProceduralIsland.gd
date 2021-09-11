extends Node2D

#Create an island with noise by adding together blobs until sufficient volume or area is obtained
#Phase two is to generate a heightmap based on the same noise

var noise

var checkrad = 50
var desired_area = 1000
var desired_size = 500

var pol = []

var spacing = 25

var elevations = {}
var seedpoints=40

var font

var circlepoints2 = [
Vector2(1,0)*checkrad,Vector2(.86,.5)*checkrad,Vector2(.707,.707)*checkrad,Vector2(.5,.86)*checkrad,
Vector2(0,1)*checkrad,Vector2(-.86,.5)*checkrad,Vector2(-.707,.707)*checkrad,Vector2(-.5,.86)*checkrad,
Vector2(-1,0)*checkrad,Vector2(-.86,-.5)*checkrad,Vector2(-.707,-.707)*checkrad,Vector2(-.5,-.86)*checkrad,
Vector2(0,-1)*checkrad,Vector2(.86,-.5)*checkrad,Vector2(.707,-.707)*checkrad,Vector2(.5,-.86)*checkrad]

var circlepoints = [
Vector2(1,0)*checkrad,Vector2(0,-1)*checkrad,Vector2(-1,0)*checkrad,Vector2(0,1)*checkrad
]

func _ready():
	font = load('res://new_dynamicfont.tres')
	font.size = 16
	randomize()
	noise = OpenSimplexNoise.new()
	generatePoints()
	generateIslandPolygonFirstPass(pol)
#	yield(get_tree().create_timer(1.2),"timeout")
	var results = smoothPolygon($Polygon2D.polygon)
#	results = smoothPolygon(results)
	print(results.size())
	pol=results
	$Polygon2D.polygon = results
	update()
#	yield(get_tree().create_timer(1.2),"timeout")
	results = roughenPolygon($Polygon2D.polygon)
	print(results.size())
	pol=results
#	if !Geometry.is_polygon_clockwise(pol):
#		var result = Geometry.convex_hull_2d(pol)
#		pol=result
	$Polygon2D.polygon=pol
	$Collider.polygon=pol
	update()

func roughenPolygon(array,iterations=5):
	var p = array
	var final = []
	var itr = 0
	while itr < iterations:
		final.clear()
		for i in range(0,p.size(),1):#For each line segment including wraparound
			final.append(p[i])
			var next = i+1
			if next == p.size():
				next=0
			if p[i].distance_squared_to(p[next]) > 15*15:
				
				var normal = (p[next]-p[i]).normalized()
				var point = lerp(p[i],p[next],rand_range(0.35,0.65)) #Get a point somewhere in the middle of the lines
				var adjust = Vector2(normal.y,normal.x) * rand_range(-6,6)
				point += adjust
				
				final.append(point)
		p=final.duplicate()
		itr+=1
	return final

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

func _draw():
	if debug_currentshape:
#		draw_polygon(totalpoly,PoolColorArray([Color(.2,.2,.2,.5)]))
		draw_polygon(debug_currentshape,PoolColorArray([Color(1,0,1)]))
		if debug_previous:
			draw_polygon(debug_previous,PoolColorArray([Color(.8,0,.8,0.5)]))
#	for point in pol:
#		draw_circle(point,checkrad,Color(0,0,1))
#	draw_polygon(pol,PoolColorArray([Color(1,0,0)]))
	for point in pol:
		var new = []
		for arcpoint in circlepoints:
			new.append(arcpoint+point)
#		draw_polygon(new,PoolColorArray([Color(1,0,1)]))
#	for x in $Polygon2D.polygon:
#		draw_circle(x,6,Color(.5,.5,1))
#	drawElevationGrid()
	if dt:
		drawDelEdges(pol,dt)
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

func drawDelEdges(points,tri):
	pass
	for i in range(0,tri.size(),3): #Every set of three points
		draw_circle(centroid(pol,[tri[i],tri[i+1],tri[i+2]]),5,Color(1,1,0))
	for x in points:
		draw_circle(x,4,Color(0.5,0.5,0.2))

func centroid(array,points):
	var total = Vector2()
	for point in points:
		total += array[point]
	return total/points.size()

func drawElevationGrid():
	for i in range(-30,30):
		for j in range(-30,30):
#			draw_circle(Vector2(i,j)*spacing,10,Color(0.2,0.2,0.2))
			if Vector2(i,j)*spacing in elevations:
#				print(str(elevations[Vector2(i,j)*spacing]))
				draw_string(font,Vector2(i,j)*spacing - Vector2(4,-5),str(elevations[Vector2(i,j)*spacing]),Color(lerp(0,1,elevations[Vector2(i,j)*spacing]/3.0),1,1))
