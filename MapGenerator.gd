extends Node2D

#Create a map full of nodes and locations that the mission system can hook into

var islands = {}

export var size = Vector2(5800,5000)

export var island_density = 0.05 #Number of islands per 50000 units

var bounds = Rect2(Vector2(-size.x/2,-size.y/2),size)
#T0 Implementation:

var quadrants = {}

#Randomly sprinkle islands around a defined area
#Determine most central island, and islands closest to the 4 quadrants
#Determine major routes that cross between the edges for escort/blockade missions
#Determine islands that major routes pass by

#FOr each Quadrant:
#Centermost Island
#Largest Island
#Smallest Island
#Cornermost Island
#Middle-Of-Quadrant-most Island

func _ready():
	randomize()
	var number = round((size.x*size.y * island_density)/50000)
	for i in number:
		var newis = makeIsland(1)
		newis.name = "Island "+str(i)
	calculateQuadrants()
	call_deferred("populateQuadrants")
	update()


var ex = []
var allresults = []
#func _process(delta):
#	var query = Physics2DShapeQueryParameters.new()
#	query.set_transform(Transform2D(0,quadrants.keys()[0].position/2))
#	var queryshape=RectangleShape2D.new()
#	queryshape.extents = quadrants.keys()[0].size/2
#	query.set_exclude(ex)
#	query.set_shape(queryshape)
#	var results =get_world_2d().get_direct_space_state().get_rest_info(query)
#	if results:
#		print(results["collider_id"],"  ",results["rid"].get_id())
#		allresults.append((results["collider_id"]))
#		if !results["rid"] in ex:
#			pass
#			ex.append(results["rid"])
#		else:
#			print("dupe")
#	print(allresults)
#	populateQuadrants()
#	set_process(false)

var debug_center

func calculateQuadrants():
	#For each of the rect's four corners, draw a rect from there to the center
	var centerpoint = Vector2()
	var corners = [Vector2(-size.x/2,-size.y/2),Vector2(size.x/2,-size.y/2),Vector2(size.x/2,size.y/2),Vector2(-size.x/2,size.y/2)]
	for corner in corners:
		quadrants[Rect2(corner,centerpoint-corner)]=[]
onready var testquadrant=$QuadrantTester
onready var testquadrantshape = $QuadrantTester/CollisionShape2D

func populateQuadrants():
	for q in quadrants:
		var query = Physics2DShapeQueryParameters.new()
#		var q = quadrants.keys()[0]
		query.set_transform(Transform2D(0,q.position/2))
		var queryshape=RectangleShape2D.new()
		queryshape.extents = q.size/2
		query.set_shape(queryshape)
		testquadrant.position = q.position/2
		testquadrantshape.shape = queryshape
		var results =get_world_2d().get_direct_space_state().get_rest_info(query)
		var islandlist = []
		while results:
			islandlist.append(instance_from_id(results["collider_id"]))
	#		print(query.exclude, results["collider_id"])
	#		var exclusion = query.get_exclude()
	#		exclusion.append(results["collider_id"])
			query.set_exclude(islandlist)
#			print(query.exclude)
			results = get_world_2d().get_direct_space_state().get_rest_info(query)
	#	print(results)
		print(islandlist.size()," Islands in Q",quadrants.keys().find(q)+1,":")
		for x in islandlist:
			pass
			print("\t",(x).name)
		quadrants[q] = islandlist
	for q in quadrants:
		var islands = quadrants[q]
		highlightCenterIsland(getQuadrantCenter(q),islands)
#	for entry in results:
#		entry["collider"].modulate=Color(1,1,0)
#		print(entry["collider"].name)
#			island.modulate=Color(0,0,0)
			
		#First get list of islands that are centered in that quadrant 

func getQuadrantCenter(q):
	return q.position/2

func makeIsland(_sz):
	var island = load("res://ProceduralIsland.tscn").instance()
	island.setParameters(rand_range(100,200),rand_range(20,200))
	island.position = (Vector2(rand_range(-size.x/2,size.x/2),rand_range(-size.y/2,size.y/2)))
	var i = 0
	while islandTooClose(island,islands,1000) and i < 20:
#		print("Too Close!")
		island.position = (Vector2(rand_range(-size.x/2,size.x/2),rand_range(-size.y/2,size.y/2)))
		i+=1
	if i < 20:
		islands[island.position]=island
		self.add_child(island)
#	update()
	return island

func islandTooClose(isl,arr,r):
	for entry in arr:
#		print(isl.position.distance_squared_to(entry))
		if isl.position.distance_squared_to(entry) < r*r:
			return true
	return false

func _draw():
	draw_rect(bounds,Color(1,1,1),false,15)
	draw_circle(Vector2(),40,Color(1,1,1))
	for q in quadrants:
#		print(q)
		draw_rect(q,Color(1,0,0,0.5),false,8)

var sort_distance_point = Vector2()
func sortIslandDistance(center,islands):
	var ary = islands.duplicate()
	sort_distance_point=center
	ary.sort_custom(self,"distanceSort")
	return ary

func highlightCenterIsland(center,islands):
	var island = sortIslandDistance(center,islands)[0]
	island.modulate=Color(1,1,0)

func distanceSort(a,b):
	return a.position.distance_squared_to(sort_distance_point) < b.position.distance_squared_to(sort_distance_point)

func getCenterIsland():
	var mapcenter = Vector2()
	#Get the one in the middle
	var closest = null
	var closestdist = INF
	for island in islands:
		if island.position.distance_squared_to(mapcenter)<closestdist:
			closestdist = island.position.distance_squared_to(mapcenter)
			closest=island
	return closest
