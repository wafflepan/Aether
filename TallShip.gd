extends KinematicBody2D


class WeaponMount:
	var id = 0 #Unique numeric ID for each mount on a ship.
	var size = 1
	var location = Vector2()
	var angle = 0
	var weapon = null
	var weapontype = GlobaLturretStats.type.TURRET
	
	var isDisabled = false #Damaged or disarmed
	var isDestroyed = false
	
	func _init(sz,loc,ang):
		size=sz
		location=loc
		angle=ang
	func assignWeapon(wp):
		if wp:
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
var waypoint = null #Waypoint to aim ship towards

#var dragcoefficient = 0.1
#var rudderforce=100 #Baseline rudder force of 100 should turn the ship reasonably fast while at average speed, benchmark for 10 degrees per second

#var enginethrust
var maxspeed  = 40 #TODO make this a function of hull drag and engine thrust? Ships might have a 'design speed' and suffer penalties above it from turbulence, vortexes, etc.

var throttleslots = []
var currentthrottle = 0
var target_velocity = 0

var accel = 25
var deccel = 15

var rotation_rate = 0.0

####
var rotation_rate_max = deg2rad(12.0) #Degrees per second
var rotation_rate_change_max = deg2rad(22.0) #Degrees per second
####

var pid_p = 1
var pid_d = 2

export var isPlayer = false #Sloppy TODO for an entity-component input system for now
export var aiType = 0
export var faction_id = 0 #0 is environmental/neutral, 1 is enemy, 2 is player, 3 is allied

export var hullpointsmax = 30
var hullpoints
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

var shipstats=null #Imported dictionary that tells a ship what it is

func _ready():
	hullpoints=hullpointsmax
	if shipstats:
		loadShipStats()
	else:
		loadWeaponMounts() #Hardcoded mount-loading
	$HealthBar.max_value=hullpointsmax
	$HealthBar.value=hullpoints
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
	$Line2D.set_as_toplevel(true)
	$WaypointSprite.set_as_toplevel(true)
	$WaypointPath.set_as_toplevel(true)
	$TargetingSprite.set_as_toplevel(true)
	updateEngineParticles()

func setShipStats(st):
	shipstats=st
	loadShipStats()

func clearTurrets():
	pass
	for mount in $Hardpoints.get_children():
		mount.free()
		mounts.clear()

func loadShipStats():
	clearTurrets()
	#Assign various stat values from a dictionary
	var mountsdata = shipstats["ship_mounts"]
	for mount in mountsdata:
		var test1 = mount
		var newmount = addMount(mount["size"],mount["location"],mount["rotation"])
		if mount.has("weapon") and mount["weapon"]!=null:
			var newgun = load("res://ShipTurret.tscn").instance()
			newgun.turret_type=mount["weapon"]
			newmount.assignWeapon(newgun)
			$Hardpoints.add_child(newgun)
	diagrampoly = shipstats["display_polygon"]
	maxspeed = shipstats["max_speed"]
	throttleslots = shipstats["throttle_slots"]
	hullpointsmax = shipstats["hullpoints_max"]
	hullpoints = hullpointsmax
	rotation_rate_max = shipstats["max_turn_rate"]
	rotation_rate_change_max = shipstats["max_turn_rate_change"]
	
	if shipstats.has("pid_settings"):
		pid_p = shipstats["pid_settings"][0]
		pid_d = shipstats["pid_settings"][1]
	

func assignThrottleValues():
	
#	throttleslots.append(0) #Most/all ships can hit zero throttle.
	for i in range(4):
		throttleslots.append(lerp(0,maxspeed,float(i)/3.0))
#	print("Throttle Values: ",throttleslots)

func changeSpeed(newspeed):
#	print("Changed Throttle Setting To ",currentthrottle,"  ,  ",current_velocity)
	target_velocity=newspeed
#	displayNavigation()
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
	return target_velocity

func addMount(size,loc,rot):
	var newmount = WeaponMount.new(size,loc,rot)
	newmount.id = mounts.size()
	mounts.append(newmount)
	return newmount

func loadWeaponMounts():
	#TODO load this from a file for each ship hull or something.
	assert(addMount(1,Vector2(45,0),0))
	assert(addMount(1,Vector2(25,-7),-80))
	assert(addMount(1,Vector2(25,7),80))
	assert(addMount(1,Vector2(-40,0),180))
	var turrets = ["basic","scatter","scatter",null]
	for mount in mounts:
		if turrets[mounts.find(mount)]:
			var newgun = load("res://ShipTurret.tscn").instance()
			newgun.turret_type=turrets[mounts.find(mount)]
			mount.assignWeapon(newgun) #Can be assigned as null
			$Hardpoints.add_child(newgun)

func addTarget(tg):
	if !tg in desired_targets:
		desired_targets.append(tg)
func removeTarget(tg):
	desired_targets.erase(tg)
	SHIP_CONTROLLER.targetCleared(tg) #Notify the controller that this is no longer a valid target
func clearTargets():
	desired_targets=[]
func getTargetList():
	return desired_targets

onready var damageparticles = preload("res://ShipDamageParticles.tscn")

func takeDamage(amt,collision): #Particle emission for impacts. #TODO: read information from a bitmask to determine material type emitting
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
	deccel=deccel*2 #More drag as it sinks
	target_velocity = target_velocity * (0.2+rand_range(-0.2,0.2))
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
	if unit_disabled:
		return 0
	if lasterror==null:
		lasterror=error
	var predict_pid = error*pid_p + pid_d*(error-lasterror)/step
	return predict_pid

var ship_previous_error

func integrateShipMotion(step,p,v,r,rdot,lasterror,targetposition,targetvelocity):
	var error = 0.0
	if SHIP_CONTROLLER:
		var navigation_error = 0
		if waypoint != null:
			navigation_error = Vector2(1,0).rotated(r).angle_to(targetposition-p)
		var avoidance_info = SHIP_CONTROLLER.getSteeringAdjust()
		var avoidance_error = (Vector2(1,0).angle_to(avoidance_info[0]))
		
		error = (navigation_error*1 + avoidance_error*avoidance_info[1]*3) / (1+avoidance_info[1]*3) #Weighted average
		steervector = Vector2(1,0).rotated(error)
		navvector = Vector2(1,0).rotated(navigation_error)
	var steer = clamp(steeringPID(step,rotation_rate,error,lasterror,rotation_rate_change_max),-rotation_rate_change_max,rotation_rate_change_max) #Waypoint Steering
	rdot = clamp(rdot+steer*step,-rotation_rate_max,rotation_rate_max)
	r += rdot*step
	
	if v < targetvelocity:
		if targetvelocity-v < accel*step:
			v=targetvelocity
		else:
			v+=accel*step
	elif v > targetvelocity:
		if v-targetvelocity < deccel*step:
			v=targetvelocity
		else:
			v-=deccel*step
	p += Vector2(v,0).rotated(r)*step
#	ship_previous_error=error
	return [p,v,r,rdot,error]


func _physics_process(delta):
	if getThrottleSpeed():
		var results = integrateShipMotion(delta,self.position,current_velocity,self.rotation,current_spin,ship_previous_error,waypoint,getThrottleSpeed())
#		print("Moving by ",results[0],"  ",results[0]-self.global_position)
		var _collision = move_and_collide(results[0]-self.global_position)
		current_velocity=results[1]
		self.rotation=results[2]
		current_spin = results[3]
		ship_previous_error=results[4]
	if current_velocity > 0:
		if $Line2D.points.size() > 190:
			$Line2D.remove_point(0)
	if $WaypointPath.points and $WaypointSprite.visible and self.position.distance_to($WaypointPath.points[0])<1:
		$WaypointPath.remove_point(0)
	if self.position.distance_to($WaypointSprite.position)<1:
		$WaypointSprite.visible=false
		$WaypointPath.clear_points()
	update()
var steervector = Vector2()
var navvector = Vector2()
func _draw():
	if steervector:
		draw_line(Vector2(),navvector*100,Color(1,1,0),10)
		draw_line(Vector2(),steervector*100,Color(0,0,1),10)
	draw_line(Vector2(-50,0),Vector2(-50,0)-Vector2(40,0).rotated(-current_spin),Color(1,1,1),10)
	for target in desired_targets:
		draw_line(Vector2(),to_local(target.position),Color(0.8,0.4,0.4,0.7),5)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.is_pressed() and isPlayer: #Player Inputs
		if event.button_index == BUTTON_RIGHT:
			setHeading(get_global_mouse_position())

func getFaction():
	return faction_id

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
	if loc != null:
		waypoint = loc
		$WaypointSprite.global_position = waypoint
		$WaypointSprite.visible=true

signal ship_clicked_left
signal ship_clicked_right
#signal ship_hovered

func registerSignals(to):
	assert(!connect("ship_clicked_left",to,"on_ship_clicked_left"))
	assert(!connect("ship_clicked_left",to,"on_ship_clicked_right"))
#	assert(connect("ship_hovered",to,"on_ship_hovered"))
	#Register signals for clicking/hovering/etc into the main combat manager

func displayNavigation():
#	return
	predictPath()
	update()

func predictPath(): #TODO: for the love of god make this threaded
	if waypoint==null:
		return
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
		elif event.button_index == BUTTON_RIGHT:
			emit_signal("ship_clicked_right",self)
