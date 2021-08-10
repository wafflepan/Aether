extends KinematicBody2D


var current_velocity = Vector2()

var waypoint = Vector2() #Waypoint to aim ship towards

var dragcoefficient = 0.1
var rudderforce=100 #Baseline rudder force of 100 should turn the ship reasonably fast while at average speed, benchmark for 10 degrees per second

var enginethrust
var maxspeed  = 40 #TODO make this a function of hull drag and engine thrust? Ships might have a 'design speed' and suffer penalties above it from turbulence, vortexes, etc.

#MAJOR TODO:

#Explore switching to derived position for the predicted path, in order to simulate things like drag, rudder rate of turn, etc. More flexible and useful overall. Does this cause shaky/flickery behavior?
#Consider how weaponry is going to be controlled independent of ships. Will it be treasure planet lock-and-select-slot method? Maybe mechwarrior action groups?
#Some kind of 'repeat' or 'fire at will' to keep a stack of guns hammering a target as long as it's in range would be nice. 

#How are collisions handled?
#Throttle Settings: Continuous or discrete steps?

var turn_rate = 0.3

func _ready():
	$Line2D.set_as_toplevel(true)
	$WaypointSprite.set_as_toplevel(true)
	$WaypointPath.set_as_toplevel(true)
	$TargetingSprite.set_as_toplevel(true)

func _process(delta):
	applyDrag()
	applyThrust()
	applyRudderForces()
	self.position = self.position + current_velocity.rotated(self.rotation)*delta
	var desiredrotation = self.position.angle_to_point(waypoint)
	if $WaypointSprite.visible and waypoint:
		var dir = get_angle_to(waypoint)
		if abs(dir) < 0.3*delta:
			rotation += dir
		else:
			if dir>0: rotation += turn_rate*delta #clockwise
			if dir<0: rotation -= turn_rate*delta #anti - clockwise
		$Line2D.add_point($ShipSprite/EnginePosition.global_position)
		if $Line2D.points.size() > 190:
			pass
			$Line2D.remove_point(0)
#	print(self.position.distance_to($WaypointSprite.position))
	if $WaypointSprite.visible and self.position.distance_to($WaypointPath.points[0])<1:
		$WaypointPath.remove_point(0)
	if self.position.distance_to($WaypointSprite.position)<1:
		$WaypointSprite.visible=false
		$WaypointPath.clear_points()

func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == BUTTON_RIGHT:
			setHeading(get_global_mouse_position())
		elif event.button_index == BUTTON_LEFT:
			for hardpoint in $Hardpoints.get_children():
				pass
				hardpoint.setTarget(get_global_mouse_position())
				$TargetingSprite.position=get_global_mouse_position()
				$TargetingSprite.visible=true
	

func applyDrag():
	pass

func applyThrust():
	pass

func applyRudderForces():
	pass

func setHeading(loc):
	waypoint = loc
	current_velocity = Vector2(maxspeed,0)
	$WaypointSprite.position = waypoint
	$WaypointSprite.visible=true
	update()

func drawShipPath():
	
	#TODO: Calculus here to determine the actual path the boat is taking?
	#First, draw the entire turning radius circle
	$WaypointPath.clear_points()
	var loc = to_local(waypoint)
	if loc.y==0:
		loc.y=0.01 #TODO
	var polarity = loc.y/abs(loc.y)
	var radius = current_velocity.length() / (turn_rate)
	var circlecenter =  self.position + Vector2(radius,0).rotated(self.rotation+PI/2*polarity)
	
	if waypoint.distance_to(circlecenter) < radius:
		waypoint = circlecenter + circlecenter.direction_to(waypoint) * radius * 1.01
		$WaypointSprite.position = waypoint
		$WaypointSprite.visible=true
	
	var dist = circlecenter.distance_to(waypoint)
	var angle_ship_to_center = (self.position-circlecenter).angle_to(Vector2(1,0))
	if angle_ship_to_center<0:
		angle_ship_to_center+=2*PI
	var angle_phi = acos(radius/dist)*-polarity
	var angle_hypo = ((waypoint-circlecenter).angle_to(Vector2(1,0)))
	var horizon_to_tangent = angle_hypo-angle_phi
	if horizon_to_tangent < 0:
		horizon_to_tangent+=2*PI
	var Q = circlecenter + Vector2(cos(horizon_to_tangent),-sin(horizon_to_tangent))*radius
#	print("angle_phi: ",rad2deg(angle_phi),"  angle_hypo: ", rad2deg(angle_hypo))

	var startangle = angle_ship_to_center
	var endangle = horizon_to_tangent
	var t = startangle
	var step = 0.05
	if polarity<1:
		if startangle > endangle:
			while t <= 2*PI:
				$WaypointPath.add_point(Vector2(cos(t),-sin(t))*radius + circlecenter)
				t+= step
			t=0
			while t <= endangle:
				$WaypointPath.add_point(Vector2(cos(t),-sin(t))*radius + circlecenter)
				t+= step
		else:
			while t <= endangle:
				$WaypointPath.add_point(Vector2(cos(t),-sin(t))*radius + circlecenter)
				t+= step
	else:
		if startangle < endangle:
			while t >= 0:
				$WaypointPath.add_point(Vector2(cos(t),-sin(t))*radius + circlecenter)
				t-= step
			t=2*PI
			while t >= endangle:
				$WaypointPath.add_point(Vector2(cos(t),-sin(t))*radius + circlecenter)
				t-= step
		else:
			while t >= endangle:
				$WaypointPath.add_point(Vector2(cos(t),-sin(t))*radius + circlecenter)
				t-= step
	$WaypointPath.add_point(Q)
	var QWdist = Q.distance_to(waypoint)
	var r = QWdist/10
	for i in range(r):
		var newpoint = (Q+Q.direction_to(waypoint)*lerp(0,QWdist,i/r))
		$WaypointPath.add_point(newpoint)
	$WaypointPath.add_point(waypoint)
	
	#Get angle between start and Q to determine angle constraints for curve
	
	draw_line(to_local(circlecenter),to_local(Vector2(cos(startangle),-sin(startangle))*radius+circlecenter),Color(1,0,0))
	draw_line(to_local(circlecenter),to_local(Vector2(cos(0),-sin(0))*radius+circlecenter),Color(1,0,0))
	draw_line(to_local(circlecenter),to_local(waypoint),Color(1,0,0.5),4)
	draw_line(to_local(circlecenter),to_local(Q),Color(0.8,0.5,0),4)
	draw_circle(to_local(circlecenter),4,Color(1,0,1))
	draw_circle(to_local(Q),4,Color(1,0,1))



func _draw():
	draw_line(Vector2(),Vector2(100,0),Color(1,1,1),2,true)
	if waypoint:
		drawShipPath()
