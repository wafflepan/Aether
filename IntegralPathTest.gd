extends Node2D

export var start_velocity = 35.0
export var start_angle = deg2rad(0.0)
export var start_accel = 0.0
export var start_position = Vector2()
export var start_spin = deg2rad(0.0)
export var spin_change = deg2rad(8.0) #How fast spin can increase/decrease
export var spin_max = deg2rad(12.0)

#var pid_d = 1.5/(spin_change/spin_max)
var pid_d = 2
var pid_p = 1

var velocity = 0
var accel = 0
var angle = 0
var spin = 0

#var target = [Vector2(150,0),Vector2(200,-5),Vector2(200,50)]
#var target = [Vector2(50,0),Vector2(112,33)]
var target = [Vector2(50,-200)]

var setPath = false

func _ready():
	$Sprite.rotation = start_angle
	velocity = start_velocity
	angle = start_angle
	accel=start_accel
	spin=start_spin
	if target.size():
		predictPath()
	else:
		target.append(Vector2(rand_range(0,25*15),rand_range(0,25*10)))
		predictPath()
	update()

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
	predict_pid = clamp(predict_pid,-spin_change,spin_change)
	r_dot = clamp(r_dot+predict_pid*step,-spin_max,spin_max)
	v += accel*step
	r += r_dot*step
	p += Vector2(v,0).rotated(r)*step
	return [p,v,r,r_dot,error]

var debugpath1 = []
var debugpath2 = []
var circlealert =false

func predictMaxTurnRatePoint():
	pass #Return coordinate and rotation for point where the ship has achieved maximum spin from its starting vector
	#Run the integration forward until the returned spin equals the maximum spin
	debugpath1.clear()
	var p = $Sprite.position
	var v = velocity
	var r = angle
	var rdot = spin
	var error=lasterror
	for i in range(300):
		var results  = integrateMotion(1.0/60.0,error,target[0],p,v,r,rdot,accel)
		p=results[0]
		v=results[1]
		r=results[2]
		rdot=results[3]
		error=results[4]
		debugpath1.append(p)
#		print("Compare: ",abs(rdot-spin_max))
		if abs(rdot-spin_max) <= 0.1:
			print("Found Point on iteration ",i)
			break
#		else:
#			print("\t",abs(rdot-spin_max))
	return [p,r]

func checkTargetTurnRadius():
	circlealert=false
	pass
	#If the target is trapped inside the turn radius of the ship, add another point ahead of it to give time to turn around
	var rotation_time = 2*PI / spin_max
	
	#arclength of a full rotation = circumference
	#2PI  = velocity*rotation_time / r
	var rad = velocity*rotation_time/(2*PI)
	turnrad = rad
	#LOCAL COORDS
	var targetsign = sign(Vector2(1,0).rotated(angle).angle_to(target[0]-$Sprite.global_position))
	var center = Vector2(0,rad) * targetsign
	var center_to_target = $Sprite.to_local(target[0]) - center
	
	var turnpos = predictMaxTurnRatePoint()
	
	var turnradius_center = turnpos[0] + Vector2(0,rad*targetsign).rotated(turnpos[1])
	circlepos = turnradius_center
#	print(target[0].distance_to(turnradius_center)," vs radius of ",rad)
	if target[0].distance_to(turnradius_center) < rad-10:
		circlealert=true
		
		#Generate alternate route via steering opposite the contact point
#		var original = target.pop_front()
		var countersteer = $Sprite.global_position + Vector2(3,-3*targetsign)
#		target.push_front(original)
		target.push_front(countersteer)
#		checkTargetTurnRadius()
		lasterror=null
		predictPath()
#		var altroute = Vector2(10,-10*targetsign)
#		var testp=$Sprite.global_position
#		var testv = velocity
#		var testr = angle
#		var testrdot = spin
#		var testerror = lasterror
#		var testpath = []
#		var testrotation = []
#		for i in range(20):
#			var countersteerresults = integrateMotion(1.0/60.0,testerror,$Sprite.global_position + altroute,testp,testv,testr,testrdot,accel)
#
#			testp=countersteerresults[0]
#			testv=countersteerresults[1]
#			testr=countersteerresults[2]
#			testrdot=countersteerresults[3]
#			testerror=countersteerresults[4]
#
#			testpath.append(countersteerresults[0])
#			testrotation.append(countersteerresults[3])
#			if testpath.back().distance_squared_to($Sprite.global_position+altroute) < 3*3:
#				break
#		print("Ship at ",$Sprite.global_position," Beginning Alternate Route Plan From: ",testp)
#		debugpath2 = testpath
#		var turnposalt = predictMaxTurnRatePoint()
#		target.push_front($Sprite.position + Vector2(rad,0).rotated($Sprite.rotation))

func _input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_RIGHT:
		target.push_front(get_global_mouse_position())
		lasterror=null
		checkTargetTurnRadius()
		predictPath()

var lasterror = null
var result = null

func _physics_process(delta):
#	print(rad2deg(spin))
#	print($Sprite.to_local(target[0]))
	if target.size():
		var angleerror = Vector2(1,0).rotated(angle).angle_to(target[0]-$Sprite.global_position)
		print(angleerror)
		var results = integrateMotion(delta,lasterror,target[0],$Sprite.global_position,velocity,angle,spin,accel)
		$Sprite.position =results[0]
		velocity=results[1]
		angle=results[2]
		spin=results[3]
		lasterror=results[4]
		
		$Sprite.rotation = angle
		if $Sprite.global_position.distance_squared_to(target[0]) < 10*10:
			target.pop_front()
			if target.size()<4:
				target.append(Vector2(rand_range(0,25*15),rand_range(0,25*10)))
			lasterror=null
			checkTargetTurnRadius()
			predictPath()
	update()

func _draw():
	drawGrid()
	if path:
		var colorarray = PoolColorArray()
		for i in range(0,path.size()):
			colorarray.append(Color(1,0,0,lerp(1,0,float(i)/(float(path.size())))))
		draw_polyline_colors(path,colorarray,2,false)
#			draw_circle(path[i],2,Color(1,0,0,lerp(1,0,float(i)/(float(path.size())))))
	if target:
		for point in target:
			draw_circle(point,5,Color(0,0,1,lerp(1,0.5,float(target.find(point))/float(target.size()))))
	var c_color = Color(1,1,1,0.3)
	if circlealert:
		c_color = Color(1,0.6,0.6,0.3)
	draw_circle(circlepos,turnrad,c_color)
	if debugpath1.size()>2:
		draw_polyline(debugpath1,Color(0.2,0.2,0.2),4)
	if debugpath2.size()>2:
		draw_polyline(debugpath2,Color(0,0.9,0.9,0.2),8)
	draw_set_transform($Sprite.position,$Sprite.rotation,$Sprite.scale)
	if result:
		draw_line(Vector2(),Vector2(-10,0).rotated(-result),Color(1,1,1,1),3)
	var rotation_time = 2*PI / spin_max
	
	#arclength of a full rotation = circumference
	#2PI  = velocity*rotation_time / r
	var rad = velocity*rotation_time/(2*PI)
	turnrad = rad
	#LOCAL COORDS
	var center = Vector2(0,rad) * sign($Sprite.to_local(target[0]).y)
	var center_to_target = $Sprite.to_local(target[0]) - center
	var linecolor = Color(1,1,1)
	if center_to_target.length() < rad:
		linecolor = Color(1,0.3,0.3)
	draw_circle(center,rad,Color(0.2,0.2,0.2,0.2))
	draw_line(center, center_to_target+center,linecolor,5)

func drawGrid():
	var step = 25
	for i in range(15):
		draw_line(Vector2(i,0)*step,Vector2(i,100)*step,Color(0,0,1,0.3))
	for i in range(15):
		draw_line(Vector2(0,i)*step,Vector2(100,i)*step,Color(0,0,1,0.3))


#integral(u dv) = uv - integral(v du)
var path = []
#var rotations = []
func predictPath():
	var prediction_lasterror = null
	var target_offset=0
	path.clear()
#	rotations.clear()
	var step = 1.0/60.0 #every x seconds draw a prediction dot
	var v = velocity
	var p = $Sprite.global_position
	var r = angle
	var r_dot = spin
	for i in 1000:
#		var target_angle = (target-p).angle()
#		var error = Vector2(1,0).rotated(r).angle_to(target[target_offset]-p)
#		if prediction_lasterror ==null:
#			prediction_lasterror=error
#		var predict_pid = error*pid_p + pid_d*(error-prediction_lasterror)/step
#		predict_pid = clamp(predict_pid,-spin_change,spin_change)
		var results = integrateMotion(step,prediction_lasterror,target[target_offset],p,v,r,r_dot,accel)
#		r_dot = clamp(r_dot+predict_pid*step,-spin_max,spin_max)
#		prediction_lasterror=error
#		v += accel*step
#		r += r_dot*step
#		p += Vector2(v,0).rotated(r)*step
		p=results[0]
		v=results[1]
		r=results[2]
		r_dot=results[3]
		prediction_lasterror=results[4]
		path.append(p)
#		print([p,v,r,prediction_lasterror]," vs ",results)
		if p.distance_squared_to(target[target_offset]) < 10*10:
			target_offset+=1
			if target_offset > target.size()-1:
				break
#		rotations.append(r)
#	print(path.size())

#extends Spatial
#
#var launchedOnThisInput := false
#var launching := false
#
#func _physics_process(delta):
#	var turn = 0.0
#	if Input.is_key_pressed(KEY_LEFT): turn -= 1.0
#	if Input.is_key_pressed(KEY_RIGHT): turn += 1.0
#	$LaunchPoint.rotate(Vector3.DOWN, turn * delta)
#	UpdatePrediction()
#	if Input.is_key_pressed(KEY_SPACE):
#		if launchedOnThisInput == false:
#			if launching == false:
#				Launch()
#				launchedOnThisInput = true
#			else: Reset()
#	else: launchedOnThisInput = false
#	if launching: LaunchProcess(delta)
#
#export var steps :=  200
#export var startSpeed := 30.0
#export var dt := 0.02	# project settings -> physics fps needs to be set to 50 too
#export var gravStrength := 500.0
#
#var path = []
#func UpdatePrediction():
#	path.clear()
#	# p position, v velocity
#	var p = $LaunchPoint.global_transform.origin
#	var v = startSpeed * -$LaunchPoint.global_transform.basis.z
#	for n in steps:
#		var state = AdvanceState(p, v, dt)
#		p = state[0]
#		v = state[1]
#		path.append(p)
#
## process just for drawing the prediciton path
#func _process(delta):
#	var pre = Vector3.ZERO
#	for n in steps:
#		DebugDraw.draw_line_3d(pre, path[n], Color.white)
#		pre = path[n]
#
#var projectileVelocity := Vector3.ZERO
#func Launch():
#	launching = true
#	projectileVelocity = startSpeed * -$LaunchPoint.global_transform.basis.z
#
#func LaunchProcess(delta):
#	var state = AdvanceState($Projectile.global_transform.origin, projectileVelocity, delta)
#	$Projectile.global_transform.origin = state[0]
#	projectileVelocity = state[1]
#
#func Reset():
#	launching = false
#	projectileVelocity = Vector3.ZERO
#	$Projectile.global_transform.origin = Vector3.ZERO
#
#func AdvanceState(var p, var v, var delta ):
#	var g = GetGravityAtPoint(p)
#	v += g * delta
#	p += v * delta
#	return[p,v]
#
#
#func GetGravityAtPoint(var p : Vector3) -> Vector3:
#	return GetGravityOfPlanetAtPoint($Planet, p) + GetGravityOfPlanetAtPoint($Planet2, p)
#
#func GetGravityOfPlanetAtPoint(var planet, var point) -> Vector3:
#	var p = planet.global_transform.origin
#	return gravStrength / p.distance_to(point) * -p.direction_to(point)
