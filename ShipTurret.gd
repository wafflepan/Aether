extends Node2D

export var projectile:PackedScene

export var traversalspeed = 15#degrees per second

var desiredangle = 0

var currenttarget

var turnrate = deg2rad(180)

var maxrange = 240
var minrange = 100
var angle = 190
var angle_offset = 180
var angle_limits

var reload= 0
var reloadtime = 1
var spread = 10

#var rotationtimestart = 0

#Negative-Positive: Break on left horizon
#Positive-Negative: Break on right horizon

var lastrot = 0
var midpoint = Vector2()
func _ready():
	angle_limits = [deg2rad(-angle/2+angle_offset),deg2rad(angle/2+angle_offset)]
	generateTargetingPolygon(minrange,maxrange,angle,angle_offset)

func setTarget(tg):
	lastrot = self.rotation
	currenttarget=tg

#For now, weapons are autotarget/fire

func _process(delta):
	if reload > 0:
		reload  -= delta
	if currenttarget==null:
		scanForTargets()
	else:
		var direction = self.global_position.direction_to(currenttarget)
		var facing:float = atan2(direction.y, direction.x)-get_parent().get_parent().rotation
		var rotationdiff = abs(angle_to_angle(rotation,facing))
		if rotationdiff <= turnrate * delta:
			rotation = facing
		else:
			rotation = lerp_angle(rotation, facing, turnrate * delta / rotationdiff)
		if rotationdiff < 0.1 and reload <= 0:
#			print("Time Between Fire: ",OS.get_ticks_msec()-rotationtimestart - reloadtime*1000)
			fire()
	#			rotationtimestart = OS.get_ticks_msec()
	
	#ANGLE RULES FOR TRAVERSAL:
	#if angle 2 is greater than angle 1, and both are positive, it's below the midline (starboard) and the turret must rotate through the midpoint between them (angle2-angle1)/2
	# 1 is negative, 2 is positive: Straddles midline, and turret must rotate through zero.
	#Both negative, 1 < 2, port side, rotate through midpoint
	#1 positive, > 2: straddles midline facing backwards, turret must rotate through 180
	
	if self.rotation > 2*PI:
		self.rotation -= 2*PI
	if self.rotation < -2*PI:
		self.rotation += 2*PI
	update()

static func angle_to_angle(from, to):
	return fposmod(to-from + PI, PI*2) - PI

func fire():
	if projectile == null:
		print("NO PROJECTILE ASSIGNED TO WEAPON")
	else:
		var newbullet = projectile.instance()
		newbullet.global_position=self.global_position
		newbullet.rotation=self.global_rotation + deg2rad(rand_range(-spread/2,spread/2))
		get_tree().get_root().add_child(newbullet)
		reload=reloadtime

func generateTargetingPolygon(minrange,maxrange,angle,offset):
	targetpoly.append(Vector2(minrange,0).rotated(angle_limits[0]))
	for i in range(-angle/2+offset,angle/2+offset,3):
#		print("Point at angle ",i)
		targetpoly.append(Vector2(minrange,0).rotated(deg2rad(i)))
	targetpoly.append(Vector2(minrange,0).rotated(angle_limits[1]))
	targetpoly.append(Vector2(maxrange,0).rotated(angle_limits[1]))
	for i in range(-angle/2,angle/2,3):
#		print("Point at angle ",i)
		targetpoly.append(Vector2(maxrange,0).rotated(deg2rad(-i+offset)))
	targetpoly.append(Vector2(maxrange,0).rotated(deg2rad(-angle/2+offset)))

var targetpoly = []

func scanForTargets():
	pass #Check the targeting area 

func _draw():
	if midpoint:
		draw_circle(to_local(self.global_position + Vector2(100,0).rotated((angle_limits[1]+angle_limits[0])/2)),5,Color(1,0,0))
		draw_circle(to_local(midpoint),7,Color(0,0,1))
	if currenttarget:
		draw_line(Vector2(),to_local(currenttarget),Color(0,1,1))
		draw_line(Vector2(),Vector2(100,0),Color(0,0.3,0.3))
	if targetpoly:
		draw_set_transform(Vector2(),-rotation,scale)
#		for point in targetpoly:
#			draw_circle(point,1,Color(0,1,1))
		draw_polygon(targetpoly,PoolColorArray([Color(0.8,0.8,0.8,0.6)]))
