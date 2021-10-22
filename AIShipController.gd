extends Node2D

var ship
var gameworld
var pathinfo

var vision_range = 800

var type = "AI_Waypoint_Test"

var seekpoints = [] #List of global coordinate positions this entity is trying to path towards. Generally, scatter a bunch of them around the primary target.

var pathpoints = []

func populateSeekLocations():
	seekpoints = (get_tree().get_nodes_in_group("seek")) + ship.desired_targets

func _ready():
	ship = get_parent()
	setupRaycasts()
	setupVisionArea()
	ship.throttleIncrease()
	ship.throttleIncrease()
	ship.throttleIncrease()
	populateSeekLocations()
	call_deferred("mapPathfind",seekSteer())
	call_deferred("simplifyPathfind")
	update()

func getPathInfo():
	pathinfo = ship.get_parent().get_parent().get_node("MapGenerator")
	if pathinfo:
		pathinfo = pathinfo.getAstar()

#TODO: have raycast information for hazard avoidance add over several frames to reduce bobbing when rays are lost/gained

func placeWaypoint(loc):
	ship.setHeading(loc)
	ship.displayNavigation()

func targetCleared(target):
	pass #Notified that ship has been destroyed. Good time to reassess tactical space?

func seekSteer():
	#For each Seek point, multiply the seek point by the ratio of its contribution to the total distance
	#Then divide through by total distance
	var vectors = []
	var total = Vector2()
	var count = 0
	var distancetotal = 0
	for entry in seekpoints:
		var item = entry
		var dist = ship.position.distance_squared_to(item.position)
		distancetotal += 1.0/max(1,dist)
		total += item.position * (1.0/(max(1,dist))) #Closer locations contribute more to the total
		count+=1
	var weighted = total/distancetotal
	if count:
		return weighted
	else:
		return null

func mapPathfind(location):
	if !pathinfo:
		getPathInfo()
#	pathpoints = pathinfo
	var start = pathinfo.get_closest_point(ship.position)
	var end = pathinfo.get_closest_point(location)
	pathpoints = Array(pathinfo.get_point_path(start,end))
	#Return an array of points for navigating an Astar field
	#TODO: something in here could be removing certain redundant points

var debugpathfindsimplify_start = Vector2()
var debugpathfindsimplify_end = Vector2()

func simplifyPathfind():
	var path=pathpoints
	var final = [] #List of endpoints
	if !path.size():
		return
	#Starting at the end, raycast from start to end-i until clear shot is found. Repeat process from new starting point until end is reached.
	var space_state = get_world_2d().direct_space_state
	var start = path[0]
	var end_index = path.size()-1
	var end = path[end_index]
	while start != end:
		var result = space_state.intersect_ray(start,end,get_tree().get_nodes_in_group("ships"))
		if result:
#			print(result.collider.name)
			end_index -= 1 #Try again at lower index
			end = path[end_index]
		else:
			final.append(end)
			start=end
			end_index=path.size()-1
			end=path[end_index]
#		debugpathfindsimplify_end=end
#		debugpathfindsimplify_start=start
#		update()
#		yield(get_tree().create_timer(0.1),"timeout")
	pathpoints = final

func makeOrientationPath(location,angle):
	pass
	#Creates a circular path to put a ship at a desired location facing a desired direction. 
	#Returns an array of points for the ship to move through.

func _process(delta):
	pathpoints = []
	if pathpoints and ship.position.distance_squared_to(pathpoints[0])<(100*100):
		pathpoints.pop_front()
	if !pathpoints:
		populateSeekLocations()
		mapPathfind(seekSteer())
		simplifyPathfind()
	if pathpoints.size():
		ship.setHeading(pathpoints[0])
#	ship.setHeading(Vector2(0,0))
	var target = getClosestTarget()
	if target:
		ship.addTarget(target)
#	print(ship.desired_targets)
	update()
#	print("Ship Spin: ",rad2deg(ship.current_spin))

#func shipNavigationOrder(pos):
#	ship.setHeading(pos)
#	ship.displayNavigation()
#
#func shipTargetingOrder(tg):
#
#	if Input.is_action_pressed("input_additive_order"):
#		ship.addTarget(tg)
#	else:
#		ship.clearTargets()
#		ship.addTarget(tg)
#		gameworld.selector.chooseTarget(tg)

func shipIncreaseSpeed(amt):
	ship.throttleIncrease()

func shipDecreaseSpeed(amt):
	ship.throttleDecrease()

var raycast_sum = Vector2()

func setupRaycasts():
	var castholder = Node2D.new()
	castholder.name = "Raycasts"
	self.add_child(castholder)
	for angle in range(-180,180,5):
		var newray = RayCast2D.new()
		newray.cast_to = Vector2(200-abs(angle),0).rotated(deg2rad(angle))
		raycast_sum+=newray.cast_to
		newray.enabled=true
		newray.add_exception(ship)
		$Raycasts.add_child(newray)

func setupVisionArea():
	var vision = Node2D.new()
	vision.name="Vision"
	self.add_child(vision)
	var newarea = Area2D.new()
	var circle = CollisionShape2D.new()
	circle.shape = CircleShape2D.new()
	circle.shape.radius = vision_range
	$Vision.add_child(newarea)
	newarea.add_child(circle)

func getTargetsInVision():
	var results = $Vision.get_child(0).get_overlapping_bodies()
	return results

func getClosestTarget():
	var closest=null
	var closestdist=INF
	var targets = []
	var list = getTargetsInVision()
	for target in list:
		if target.is_in_group("ships") and target.getFaction() != ship.getFaction():
			targets.append(target)
			if ship.position.distance_squared_to(target.position) < closestdist:
				closest=target
				closestdist = ship.position.distance_squared_to(target.position)
	return closest

func getSteeringAdjust():
#	return Vector2()
	return addRaycastEmptyVectors()

func getPathPoints():
	return pathpoints

func addRaycastEmptyVectors():
	var total = Vector2(0,0)
	var count = 0
	for item in $Raycasts.get_children(): #Get raycasts
		total += item.cast_to.normalized()
		if !item.is_colliding():
			pass
#			count+=1
#			total+=item.cast_to
		else:
			var point = to_local(item.get_collision_point())
#			total +=(ship.global_position - (item.cast_to- Vector2(item.get_collision_point().x,-item.get_collision_point().y))).normalized()
#			total -= Vector2(point.y,point.x).normalized() * (item.cast_to.length()/point.length())
			total -= (item.cast_to - point)
			count +=1
#		else:
#			print(item.get_collider().name)
#	print(total/count)
	if count:
		var average_vector = total/count
		var weight = total.length()/raycast_sum.length()
#		print(total.length(),"   ",raycast_sum.length(),"   ",weight)
		return [average_vector,weight]
	else:
		return [Vector2(),0]
func _draw():
	draw_line(ship.to_local(debugpathfindsimplify_start),ship.to_local(debugpathfindsimplify_end),Color(1,1,0.6,0.8),100)
#	draw_set_transform_matrix(ship.get_parent().get_transform().affine_inverse())
	if pathpoints:
		for point in pathpoints:
			draw_circle(ship.to_local(point),45,Color(0,0,1,0.7))
#		draw_polyline(pathpoints,Color(0,1,1),10,true)
#	for item in $Raycasts.get_children():
#		if item.is_colliding():
##			print(item.get_collider().name)
#			draw_line(Vector2(),item.cast_to,Color(1,0,0,0.5),5)
#			draw_circle(to_local(item.get_collision_point()),7,Color(1,0,0))
#	draw_line(Vector2(),addRaycastEmptyVectors()[0]*100*addRaycastEmptyVectors()[1],Color(0,1,1,0.6),8)
##	draw_line(Vector2(),addRaycastEmptyVectors()*40,Color(1,1,1),10)
#	for raycast in $Raycasts.get_children():
#		draw_line(Vector2(),raycast.cast_to,Color(1,1,1,0.5),6)
