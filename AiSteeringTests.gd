extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	steerAI()
	angle=ship.rotation


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func getFlee():
	return get_tree().get_nodes_in_group("flee")

func getSeek():
	return get_tree().get_nodes_in_group("seek")

func fleeAI():
	var fleevectors = []
	for item in getFlee():
		var vector = ((ship.position-item.position)).normalized()/(ship.position.distance_to(item.position)/200)
		fleevectors.append(vector)
	debugfleestrengths=fleevectors
	return fleevectors

func seekAI():
	var seekvectors = []
	for item in getSeek():
		var vector = (item.position-ship.position).normalized()
		seekvectors.append(vector)
	debugseekstrengths=seekvectors
	return seekvectors

func steerAI():
	var seek=[]
	var flee=[]
	seek = seekAI()
	flee = fleeAI()
	var total = Vector2()
	for item in seek:
		total += item
	for item in flee:
		total += item
	var steervector = (total)
	debugsteering = steervector
	return steervector

var maxvel = 30

var steeringmax = 20 #Degrees per second
var speed = 60
var velocity = 30
var steering = 0
var debugsteering
var debugseekstrengths = []
var debugfleestrengths = []

var debugdesiredpoint = []
onready var ship = $Ship

#var pid_d = 1.5/(spin_change/spin_max)
var pid_d = 2
var pid_p = 1

var accel = 0
var angle = 0
var spin = 0
var spin_max = .5
var spin_change_max = .45

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

var lasterror = null
func _physics_process(delta):
	var steering = steerAI()
#	print(debugseekstrengths[0],"  ",debugfleestrengths[0],"  ",steering)
	ship.rotation = lerp_angle(ship.rotation,steering.angle(),0.5*delta)
	ship.position += Vector2(speed*delta,0).rotated(ship.rotation)
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
	update()

func _draw():
	if target:
		draw_circle(target,45,Color(1,1,1))
	for item in getFlee():
		draw_circle(item.position,200,Color(0.5,0,0,0.3))
	for item in getSeek():
		draw_circle(item.position,200,Color(0,0.5,0,0.3))
	for item in debugseekstrengths:
		draw_line(ship.position,ship.position+item*40,Color(0.2,1,0.2,0.8),6)
	for item in debugfleestrengths:
		draw_line(ship.position,ship.position+item*40,Color(1,0.2,0.2,0.8),6)
	if debugsteering:
		draw_line(ship.position,ship.position+debugsteering*40,Color(0.2,0.2,1,0.8),6)
#		draw_line(ship.position,ship.position+fleeAI()[0]+seekAI()[0],Color(0,0,0),6)
	
#	draw_line(ship.position,ship.position-seekAI()*10,Color(0,1,.5),5)
#	draw_line(ship.position,ship.position-fleeAI()*10,Color(1,0.5,0),5)
