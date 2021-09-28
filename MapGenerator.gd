extends Node2D

#Create a map full of nodes and locations that the mission system can hook into

var islands = {}

export var size = Vector2(5800,5000)

export var island_density = 0.001 #Number of islands per 50000 units

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

#func _process(delta):
#	for item in testquadrant.get_overlapping_bodies():
#		item.modulate = Color(1,0,0)

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
	var query = Physics2DShapeQueryParameters.new()
	var q = quadrants.keys()[0]
	query.set_transform(Transform2D(0,q.position/2))
	var queryshape=RectangleShape2D.new()
	queryshape.extents = q.size/2
	query.set_shape(queryshape)
	testquadrant.position = q.position/2
	testquadrantshape.shape = queryshape
	var results =get_world_2d().get_direct_space_state().collide_shape(query,528)
	print(results)
#	for entry in results:
#		entry["collider"].modulate=Color(1,1,0)
#		print(entry["collider"].name)
#			island.modulate=Color(0,0,0)
			
		#First get list of islands that are centered in that quadrant 

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
