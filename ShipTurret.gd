extends Node2D

var projectile

export var turnspeed = 35#degrees per second

export var turret_type = "basic"

var desiredangle = 0



var currenttarget
var turret_owner = null
var turretdata=null
###TURRET ROTATION/DISTANCE STATS

var maxrange = 380
var minrange = 30
var angle = 40
var angle_offset = 0
var angle_limits

####WEAPON STATS

var shots_between_reload = 1 #Fire the entire clip no matter what, to ignore reload timing headaches.
var time_between_shots = 0.2
var reloadtime = 5
var spread = 10


##INTERNAL VARIABLES
var lastrot = 0
var reload = 0

var isFiring = false
#	var turret_name #Internal data name for the turret type
#	var display_name #What it reads as
#
#	var base_texture
#	var turret_texture
#	var projectile_texture
#
#	var damage_per_shot
#	var shots_per_reload
#	var time_between_shots
#	var reload_time
#
#	var spread_angle
#	var accuracy
#	var projectile_speed
#	var projectile_drag
#	var projectile_lifetime

func _ready():
	loadTurretData()
	turret_owner = get_parent().get_parent()
	angle_limits = [deg2rad(-angle/2),deg2rad(angle/2)]
	generateTargetingPolygon()

func loadTurretData(): #Load from file/database/etc the correct sprites and textures and particles for the chosen weapon. Access a global singleton with loaded stats.
	projectile=load("res://WeaponProjectile.tscn").instance()
	turretdata = GlobaLturretStats.getTurretData(self.turret_type)
	assert(turretdata)
#	setupProjectile(turretdata)
	setupSprites(turretdata)
	shots_between_reload=turretdata.shots_per_reload
	time_between_shots = turretdata.time_between_shots
	reloadtime = turretdata.reload_time
	spread=turretdata.spread_angle

#func setupProjectile(data):
#	projectile.setTexture(data.projectile_texture)
#	projectile.lifetime = [data.projectile_lifetime,data.projectile_lifetime+(0.1*data.projectile_lifetime)] #10% variance for now, probably relate directly to range instead
#	projectile.accuracy = data.accuracy
#	projectile.projectilespeed = data.projectile_speed
#	projectile.projectiledragco = data.projectile_drag
#	projectile.damage = data.damage_per_shot
func setupSprites(data):
	$Base.texture=data.base_texture
	$TurretNode/Turret.texture=data.turret_texture

func setTarget(tg):
	currenttarget=tg

func showArc():
	$DisplayPolygon.visible=true

func hideArc():
	$DisplayPolygon.visible=false

#For now, weapons are autotarget/fire

func _process(delta):
	if reload > 0:
		reload  -= delta
	if currenttarget==null:
		currenttarget = scanForTargets()
	else:
		var facing = (Vector2(1,0).rotated(self.global_rotation).angle_to(currenttarget.global_position-global_position))
		if abs($TurretNode.rotation-facing) < deg2rad(turnspeed)*delta:
			$TurretNode.rotation = facing
			desiredangle = null
		else:
			var midpoint = ($TurretNode.rotation + facing)/2
			var diff = (abs(angle_to_angle($TurretNode.rotation,midpoint)))
			if diff>0:
				$TurretNode.rotation = lerp_angle($TurretNode.rotation,midpoint,delta*deg2rad(turnspeed)/(diff))
		if abs(angle_to_angle($TurretNode.rotation,facing)) < 0.1 and !isFiring and reload <= 0 and currenttarget in $TargetArea.get_overlapping_bodies():
			fire()
#	print("Angle: ",$TurretNode.rotation,"  ",angle_limits)
	$TurretNode.rotation = clamp($TurretNode.rotation,angle_limits[0],angle_limits[1])
#	update()

static func angle_to_angle(from, to):
	return fposmod(to-from + PI, PI*2) - PI

func fire():
	if projectile == null:
		print("NO PROJECTILE ASSIGNED TO WEAPON")
	else:
		isFiring=true #Lockouts to prevent firing again while yields are active.
		for _i in range(shots_between_reload):
			$TurretNode/FiringParticles.emitting=true
			var newbullet = projectile.duplicate()
			newbullet.firedby = turret_owner
			newbullet.global_position=self.global_position
			newbullet.rotation=$TurretNode.global_rotation + deg2rad(rand_range(-spread/2,spread/2))
			newbullet.setupProjectile(turretdata)
			get_tree().get_root().add_child(newbullet)
			if shots_between_reload > 1:
				$FiringTimer.start(time_between_shots)
				yield($FiringTimer,"timeout")
		reload=reloadtime
		isFiring=false
		#Emit signal here to indicate finished firing a full shot/salvo.

func generateTargetingPolygon():
	var angle2 = angle_limits[0]
	var angle1 = angle_limits[1]
	var startcolor = Color(0.7,0.7,0.7,0.7)
	var endcolor = Color(0.9,0.9,0.9,0.1)
	targetpoly= []
	var colorpoly = []
#	targetpoly.resize(100) TODO optimization
#	anglelimits = [(angle1),(angle2)]
	var step = 0.03
	var i = angle1 #The positive (large) angle
	assert(angle1>angle2)
	targetpoly.append(Vector2(minrange,0).rotated(angle1))
	colorpoly.append(startcolor)
	while i >= angle2:
		targetpoly.push_back(Vector2(minrange,0).rotated(i))
		targetpoly.push_front(Vector2(maxrange,0).rotated(i))
		colorpoly.push_back(startcolor)
		colorpoly.push_front(endcolor)
		
		i-= step
	targetpoly.append(Vector2(maxrange,0).rotated(angle2))
	colorpoly.append(endcolor)
	targetpoly = PoolVector2Array(targetpoly)
	colorpoly = PoolColorArray(colorpoly)
	$TargetArea/Shape.polygon = targetpoly
	$DisplayPolygon.polygon=targetpoly
	$DisplayPolygon.vertex_colors = colorpoly

var targetpoly = []

func scanForTargets():
	#Implementation 1:
	#Get closest target and track
	var dist = INF
	var closest = null
	for target in turret_owner.getTargetList():
		if !target:
			turret_owner.removeTarget(target)
		else:
			var dist_to = self.global_position.distance_squared_to(target.global_position)
			if dist_to < dist:
				dist=dist_to
				closest=target
	return closest
