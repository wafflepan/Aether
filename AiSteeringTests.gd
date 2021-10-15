extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
#func _ready():
#	steerAI()
#	angle=ship.rotation


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func getFlee():
	return get_tree().get_nodes_in_group("flee")

func getSeek():
	return get_tree().get_nodes_in_group("seek")

#func fleeAI():
#	var fleevectors = []
#	for item in getFlee():
#		var vector = ((ship.position-item.position)).normalized()/(ship.position.distance_to(item.position)/200)
#		fleevectors.append(vector)
#	debugfleestrengths=fleevectors
#	return fleevectors

func seekAI(shp):
	var seekvectors = []
	for item in getSeek():
		var vector = (item.position-shp.position)
		seekvectors.append(vector)
	debugseekstrengths=seekvectors
	update()
	return seekvectors

func getWeightedSeekPoint(shp):
	#For each Seek point, multiply the seek point by the ratio of its contribution to the total distance
	#Then divide through by total distance
	var vectors = []
	var total = Vector2()
	var count = 0
	var distancetotal = 0
	for item in getSeek():
		var dist = shp.position.distance_squared_to(item.position)
		distancetotal += 1.0/dist
		total += item.position * (1.0/(max(1,dist))) #Closer locations contribute more to the total
		count+=1
		debugsteering.append(item.position)
	var weighted = total/distancetotal
	return weighted

func steerAI(shp):
	var seek=[]
	var flee=[]
#	seek = seekAI(shp)
	seek = getWeightedSeekPoint(shp)
#	flee = fleeAI()
	var steervector = seek
	return steervector

var maxvel = 30

var steeringmax = 20 #Degrees per second
var speed = 60
var velocity = 30
var steering = 0
var debugsteering = []
var debugseekstrengths = []
var debugfleestrengths = []

var debugdesiredpoint = []
#onready var ship = $TallShip

#var pid_d = 1.5/(spin_change/spin_max)
var pid_d = 2
var pid_p = 1

var accel = 0
var angle = 0
var spin = 0
var spin_max = .4
var spin_change_max = .2

#var target = [Vector2(150,0),Vector2(200,-5),Vector2(200,50)]
#var target = [Vector2(50,0),Vector2(112,33)]
var target = null

var setPath = false

#func _ready():
#	$Sprite.rotation = start_angle
#	velocity = start_velocity
#	angle = start_angle
#	accel=start_accel
#	spin=start_spin
#	if target.size():
#		predictPath()
#	else:
#		target.append(Vector2(rand_range(0,25*15),rand_range(0,25*10)))
#		predictPath()
#	update()

var turnrad = 0
var circlepos = Vector2()

func wanderObject(obj):
	var speed = 170
	var bounds = 700
	var newpoint = Vector2(rand_range(0,bounds),rand_range(0,bounds))
	$Tween.interpolate_property(obj,"position",obj.position,newpoint,(obj.position-newpoint).length()/speed,Tween.TRANS_LINEAR)
	$Tween.start()

func integrateMotion(step,prev_error,target,start_p=Vector2(),start_v=0,start_r=0,start_spin=0,start_a=0):
	var p = start_p
	var v = start_v
	var r = start_r
	var r_dot = start_spin
	var a = start_a
	var error = Vector2(1,0).rotated(r).angle_to(target-p)
	if prev_error ==null:
		prev_error=error
	var predict_pid = error*pid_p + pid_d*(error-prev_error)/step
	predict_pid = clamp(predict_pid,-spin_change_max,spin_change_max)
	r_dot = clamp(r_dot+predict_pid*step,-spin_max,spin_max)
#	v += accel*step
	r += r_dot*step
	p += Vector2(v,0).rotated(r)*step
	return [p,v,r,r_dot,error]

var rudder = Vector2()
var lasterror = 0

func _process(delta):
	$TerrainTest.position=get_global_mouse_position()
#	update()
#func _physics_process(delta):
##	wanderObject($Seek2)
#	var steering = Vector2() #resultant vector for all steering forces
#	steering += steerAI()
##	steering = (Vector2(-100,-1)).normalized()
#	debugsteering=steering*40
#	var error = Vector2(1,0).rotated(ship.rotation).angle_to(steering)
#	print(error)
#	var predict_pid = error*pid_p + pid_d*(error-lasterror)/delta
#	predict_pid = clamp(predict_pid,-spin_change_max,spin_change_max)
##	steering = clamp(steering,-spin_change_max,spin_change_max) #Force it to stay between min/max rudder values
#	spin = clamp(spin+predict_pid*delta,-spin_max,spin_max)
##	spin = clamp(spin+steering.angle(),-spin_max,spin_max)
#	ship.rotation += spin * delta
#	ship.position += Vector2(speed*delta,0).rotated(ship.rotation)
#	lasterror=error
#	rudder = Vector2(1,0).rotated(predict_pid)
#	print(rad2deg(spin))
#	print($Sprite.to_local(target[0]))
#	if target:
#		var angleerror = Vector2(1,0).rotated(angle).angle_to(target-ship.global_position)
##		print(angleerror)
#		var results = integrateMotion(delta,lasterror,target,ship.global_position,velocity,angle,spin,accel)
#		ship.position =results[0]
#		velocity=results[1]
#		angle=results[2]
#		spin=results[3]
#		lasterror=results[4]
#
#		ship.rotation = angle
#		if $Sprite.global_position.distance_squared_to(target[0]) < 10*10:
#			target.pop_front()
#			if target.size()<4:
#				target.append(Vector2(rand_range(0,25*15),rand_range(0,25*10)))
#			lasterror=null
#			checkTargetTurnRadius()
#			predictPath()
#	update()

func _draw():
#	if target:
#		draw_circle(target,45,Color(1,1,1))
#	for item in getFlee():
#		draw_circle(item.position,200,Color(0.5,0,0,0.3))
#	for item in getSeek():
#		draw_circle(item.position,200,Color(0,0.5,0,0.3))
#	for item in debugseekstrengths:
#		draw_line(ship.position,ship.position+item,Color(0.2,1,0.2,0.8),6)
#	for item in debugfleestrengths:
#		draw_line(ship.position,ship.position+item,Color(1,0.2,0.2,0.8),6)
	if debugsteering:
		var total = Vector2()
		for line in debugsteering:
			draw_line($TallShip2.position,line,Color(0.2,0.2,0.2,0.8),10)
			total+=line
		total=total/debugsteering.size()
		draw_circle(total,60,Color(0.6,0.3,0.3))
#		draw_line(ship.position,ship.position+fleeAI()[0]+seekAI()[0],Color(0,0,0),6)
#	if rudder:
#		draw_line(ship.position,ship.position+rudder*20,Color(1,1,1),5)
#	draw_set_transform_matrix(ship.transform)
#	draw_line(ship.position,ship.position-seekAI()*10,Color(0,1,.5),5)
#	draw_line(ship.position,ship.position-fleeAI()*10,Color(1,0.5,0),5)
