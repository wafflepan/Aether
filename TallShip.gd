extends KinematicBody2D


class WeaponMount:
	var size = 1
	var location = Vector2()
	var angle = 0
	var weapon = null
	func _init(sz,loc,ang):
		size=sz
		location=loc
		angle=ang
	func assignWeapon(wp):
		weapon=wp
		weapon.position=location
		weapon.rotation_degrees=angle

class WeaponBattery: #Contains multiple turrets slaved to the same targeting/firing/cycling orders. Must be same weapon type?
	var total_arc
	var mounts = []
	var group_id = 0 #Per-ship
	
	func assignWeapon(wp):
		mounts.append(wp)
	func removeWeapon(wp):
		if wp in mounts:
			mounts.erase(wp)
	func setID(i):
		group_id = i
	

var mounts = []

var weapon_battery_list = []

onready var diagrampoly = $ShipOutline

var desired_targets = []

var current_velocity = Vector2()
var current_spin = 0.0

var waypoint = Vector2() #Waypoint to aim ship towards

var dragcoefficient = 0.1
var rudderforce=100 #Baseline rudder force of 100 should turn the ship reasonably fast while at average speed, benchmark for 10 degrees per second

var enginethrust
var maxspeed  = 40 #TODO make this a function of hull drag and engine thrust? Ships might have a 'design speed' and suffer penalties above it from turbulence, vortexes, etc.

var throttleslots = []
var currentthrottle = 0

export var isPlayer = false #Sloppy TODO for an entity-component input system for now
export var aiType = 0

var hullpointsmax = 30
var hullpoints = hullpointsmax
var unit_disabled=false

export(Script) var SHIP_CONTROLLER #Component for player or AI input to a ship


export(Curve2D) var navpoints
var navindex = 0
#AI TYPES:
# 0 - just sit there
# 1 - Patrol between patrol points
# 3 - Freely pursue enemy
#MAJOR TODO:

#Consider how weaponry is going to be controlled independent of ships. Will it be treasure planet lock-and-select-slot method? Maybe mechwarrior action groups?
#Some kind of 'repeat' or 'fire at will' to keep a stack of guns hammering a target as long as it's in range would be nice. 

#How are collisions handled?

var turn_rate = deg2rad(10)

func _ready():
	assignThrottleValues()
	current_velocity = 0
	if SHIP_CONTROLLER:
		SHIP_CONTROLLER = SHIP_CONTROLLER.new()
		SHIP_CONTROLLER.name=str(SHIP_CONTROLLER.type, " Ship Controller")
		self.add_child(SHIP_CONTROLLER)
	else:
		print("Loaded a tallship with no ship controller")
#	var engineparticles = $Engines.get_child(0)
	for child in $Engines.get_children():
		child.process_material=child.process_material.duplicate() #Make engine particles unique
	$HealthBar.max_value=hullpointsmax
	$HealthBar.value=hullpoints
	$Line2D.set_as_toplevel(true)
	$WaypointSprite.set_as_toplevel(true)
	$WaypointPath.set_as_toplevel(true)
	$TargetingSprite.set_as_toplevel(true)
	loadWeaponMounts()
	updateEngineParticles()


func assignThrottleValues():
	
#	throttleslots.append(0) #Most/all ships can hit zero throttle.
	for i in range(4):
		throttleslots.append(lerp(0,maxspeed,float(i)/3.0))
	print("Throttle Values: ",throttleslots)

func changeSpeed(newspeed):
	print("Changed Throttle Setting To ",currentthrottle,"  ,  ",current_velocity)
	self.current_velocity = newspeed
	displayNavigation()
	updateEngineParticles()

func throttleIncrease():
	currentthrottle += 1
	currentthrottle = clamp(currentthrottle,0,throttleslots.size()-1)
	changeSpeed(throttleslots[currentthrottle])

func throttleDecrease():
	currentthrottle -= 1
	currentthrottle = clamp(currentthrottle,0,throttleslots.size()-1)
	changeSpeed(throttleslots[currentthrottle])

func getThrottleSpeed():
	return throttleslots[currentthrottle]

func loadWeaponMounts():
	pass #TODO load this from a file for each ship hull or something.
	var bow_sweep = WeaponMount.new(1,Vector2(45,0),0)
	var sidegun1 = WeaponMount.new(1,Vector2(25,-7),-80)
	var sidegun2 = WeaponMount.new(1,Vector2(25,7),80)
	mounts=[bow_sweep,sidegun1,sidegun2]
	var turrets = ["basic","ballista","scatter"]
	for mount in mounts:
		var newgun = load("res://ShipTurret.tscn").instance()
		newgun.turret_type=turrets[mounts.find(mount)]
		mount.assignWeapon(newgun)
		$Hardpoints.add_child(newgun)

func addTarget(tg):
	desired_targets.append(tg)
func removeTarget(tg):
	desired_targets.erase(tg)
	SHIP_CONTROLLER.targetCleared(tg) #Notify the controller that this is no longer a valid target
func clearTargets():
	desired_targets=[]
func getTargetList():
	return desired_targets

onready var damageparticles = preload("res://ShipDamageParticles.tscn")

func takeDamage(amt,collision):
	hullpoints -= amt
	$HealthBar.value=hullpoints
	if hullpoints <= 0:
		self.die()
	var newpart = damageparticles.instance()
	newpart.setup(amt/hullpointsmax)
#	var inwardvector = self.global_position - collision.position
#	var inwarddist = inwardvector.length()
#	newpart.global_position=inwardvector.normalized() * inwarddist*0.8
	newpart.global_position = to_local(collision.position)
	newpart.rotation = collision.normal.angle()
	self.add_child(newpart)
	

func updateEngineParticles():
	for emitter in $Engines.get_children():
		emitter.process_material.initial_velocity=10+ lerp(0,150,current_velocity/maxspeed)


signal disable_target
signal unit_destroyed
func die():
	unit_disabled=true
	self.z_index-=1
	emit_signal("unit_destroyed",self) #For tracking elimination mission goals
	emit_signal("disable_target",self)
	var randspin = deg2rad(rand_range(-30,30))
	var randduration = rand_range(5,7)
	$Tween.interpolate_property($ShipSprite,"modulate",self.modulate,Color(0.5,0.5,0.5),randduration,Tween.TRANS_LINEAR,Tween.EASE_IN)
	$Tween.interpolate_property(self,"scale",self.scale,Vector2(0.8,0.8),randduration,Tween.TRANS_LINEAR,Tween.EASE_IN)
	$Tween.interpolate_property(self,"rotation",self.rotation,self.rotation+randspin,randduration,Tween.TRANS_LINEAR,Tween.EASE_IN)
#	$Tween.interpolate_property(self,"modulate",self.modulate,Color(0.8,0.8,0.8),randduration,Tween.TRANS_LINEAR,Tween.EASE_IN)
	$Tween.start()
	set_process(false)
	$CollisionShape2D.disabled=true
	yield($Tween,"tween_all_completed")
	$Tween.interpolate_property(self,"modulate",self.modulate,Color(0.1,0.1,0.1,0),0.4,Tween.TRANS_LINEAR,Tween.EASE_IN)
	$Tween.start()
	yield($Tween,"tween_all_completed")
	self.queue_free()

func steeringPID(step,currentval,error,lasterror,steermax):
	if lasterror==null:
		lasterror=error
	var predict_pid = error*pid_p + pid_d*(error-lasterror)/step
	return clamp(predict_pid,-rotation_rate_change_max,rotation_rate_change_max)

var rotation_rate = 0.0
var rotation_rate_max = deg2rad(12.0) #Degrees per second
var rotation_rate_change_max = deg2rad(8.0) #Degrees per second

var pid_p = 1
var pid_d = 2

var ship_previous_error

func integrateShipMotion(step,p,v,r,rdot,lasterror,targetposition,targetvelocity):
	var error = Vector2(1,0).rotated(r).angle_to(targetposition-p) #How far off target the ship's current heading is
	var steer = steeringPID(step,rotation_rate,error,lasterror,rotation_rate_change_max)
	rdot = clamp(rdot+steer*step,-rotation_rate_max,rotation_rate_max)
#	print(rdot)
	#TODO: Acceleration to desired throttle
	#velocity += acceleration*step
	#clamp to throttle to prevent overshoot
	
	r += rdot*step
	p += Vector2(current_velocity,0).rotated(r)*step
#	ship_previous_error=error
	return [p,v,r,rdot,error]
#
#func integrateMotion(step,prev_error,target,start_p=Vector2(),start_v=0,start_r=0,start_spin=0,start_a=0):
#	var p = start_p
#	var v = start_v
#	var r = start_r
#	var r_dot = start_spin
#	var a = start_a
#	var error = Vector2(1,0).rotated(r).angle_to(target-p)
#	if prev_error ==null:
#		prev_error=error
#	var predict_pid = error*pid_p + pid_d*(error-prev_error)/step
#	predict_pid = clamp(predict_pid,-spin_change,spin_change)
#	r_dot = clamp(r_dot+predict_pid*step,-spin_max,spin_max)
#	v += accel*step
#	r += r_dot*step
#	p += Vector2(v,0).rotated(r)*step
#	return [p,v,r,r_dot,error]


func _physics_process(delta):
#	print(getThrottleSpeed())
	if getThrottleSpeed():
		var results = integrateShipMotion(delta,self.position,current_velocity,self.rotation,current_spin,ship_previous_error,waypoint,getThrottleSpeed())
#		self.position=results[0]
		var _collision = move_and_collide(results[0]-self.global_position)
		current_velocity=results[1]
		self.rotation=results[2]
		current_spin = results[3]
		ship_previous_error=results[4]
#	applyDrag()
#	applyThrust()
#	applyRudderForces()
#	self.position = self.position + Vector2(current_velocity,0).rotated(self.rotation)*delta
##	var desiredrotation = self.position.angle_to_point(waypoint)
#	if $WaypointSprite.visible and to_local(waypoint).length() and current_velocity>0:
#		var dir = get_angle_to(waypoint)
#		if abs(dir) < 0.3*delta:
#			rotation += dir
#		else:
#			if dir>0: rotation += turn_rate*delta #clockwise
#			if dir<0: rotation -= turn_rate*delta #anti - clockwise
	if current_velocity > 0:
#		$Line2D.add_point($ShipSprite/EnginePosition.global_position)
		if $Line2D.points.size() > 190:
			$Line2D.remove_point(0)
#	print(self.position.distance_to($WaypointSprite.position))
	if $WaypointPath.points and $WaypointSprite.visible and self.position.distance_to($WaypointPath.points[0])<1:
		$WaypointPath.remove_point(0)
	if self.position.distance_to($WaypointSprite.position)<1:
		$WaypointSprite.visible=false
		$WaypointPath.clear_points()
	update()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.is_pressed() and isPlayer: #Player Inputs
		if event.button_index == BUTTON_RIGHT:
			setHeading(get_global_mouse_position())
#		elif event.button_index == BUTTON_LEFT:
#			for hardpoint in $Hardpoints.get_children():
#				pass
#				hardpoint.setTarget(get_global_mouse_position())
#				$TargetingSprite.position=get_global_mouse_position()
#				$TargetingSprite.visible=true
	

func applyDrag():
	pass

func applyThrust():
	pass

func getSpeed():
	return current_velocity
func getMaxSpeed():
	return maxspeed

func applyRudderForces():
	pass

func setHeading(loc):
	waypoint = loc
	$WaypointSprite.position = waypoint
	$WaypointSprite.visible=true
	displayNavigation()

signal ship_clicked_left
signal ship_clicked_right
#signal ship_hovered

func registerSignals(to):
	assert(!connect("ship_clicked_left",to,"on_ship_clicked_left"))
	assert(!connect("ship_clicked_left",to,"on_ship_clicked_right"))
#	assert(connect("ship_hovered",to,"on_ship_hovered"))
	#Register signals for clicking/hovering/etc into the main combat manager

func displayNavigation():
	predictPath()
	update()

func predictPath():
#	print("Predicting Path, throttle = ",getThrottleSpeed())
	var path = []
	var p = self.position
	var v = current_velocity
	var r = self.rotation
	var rdot = current_spin
	var predict_lasterror = null
	for _i in range(1000):
		var results = integrateShipMotion(1.0/60.0,p,v,r,rdot,predict_lasterror,waypoint,getThrottleSpeed())
		p=results[0]
		v=results[1]
		r=results[2]
		rdot=results[3]
		predict_lasterror=results[4]
		path.append(p)
		if p.distance_squared_to(waypoint) < 10*10:
			break
	$WaypointPath.points=path

func _on_TallShip_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_pressed() and !event.is_echo():
		if event.button_index == BUTTON_LEFT:
			print("Ship Clicked: ",name)
			emit_signal("ship_clicked_left",self)
#			if !self.is_in_group("player"):
#				get_parent().get_node("SelectionIndicator").chooseTarget(self)
		elif event.button_index == BUTTON_RIGHT:
			emit_signal("ship_clicked_right",self)
