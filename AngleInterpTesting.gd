extends Node2D
var desiredpoint = Vector2()

func _input(event):
	if event is InputEventKey and event.is_pressed():
		if event.scancode == KEY_SPACE:
			startTest()
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
		desiredpoint = get_global_mouse_position()
		desiredangle = (get_global_mouse_position()-self.global_position).angle()
		print("Vector: ",get_global_mouse_position()-self.global_position)
#		print("Angle (Native): ",(rad2deg(fposmod(rotation-PI,PI*2)-PI)),"  Angle (Converted): ",rad2deg(normalizeangle(rotation)),"  Angle (Reverted): ",rad2deg(godot_angle(normalizeangle(rotation))))
#		print("DesiredAngle(converted): ",rad2deg(normalizeangle(desiredangle)),"  ",rad2deg(desiredangle))
#		print("Cone Extents: ",rad2deg(normalizeangle(anglelimits[0]))," , ",rad2deg(normalizeangle(anglelimits[1])))
var desiredangle=null
var turnspeed = deg2rad(90)
var anglelimits = []
func startTest():
	pass
	
	desiredangle = 270
	desiredangle = deg2rad(desiredangle)

var angleprogress = 0.0

func _ready():
	generateTargetingPolygon(100,200,210,180)
	
	#Angle Extents: First angle to second angle always sweeps clockwise (through/towards zero) to describe the bounds of valid space

func _process(delta):
	update()
	if desiredangle:
		
		var direction = self.global_position.direction_to(desiredpoint)
		var facing:float = atan2(direction.y, direction.x)
		var dir = -sign(direction.angle())
		rotation = rotate_const_speed(rotation,facing,delta*turnspeed*dir)
#		var diff = fposmod(facing-rotation + PI, PI*2) - PI
##		self.rotation -= min(turnspeed*delta,abs(diff))*sign(diff)
#		self.rotation = lerp_angle(self.rotation,facing,delta*turnspeed/abs(facing-rotation))
#		self.rotation = clamp(rotation,anglelimits[0],anglelimits[1])
#		var angle = normalizeangle(desiredangle)
#		print(rad2deg(angle))


func rotate_const_speed(a, b, d): #In radians
	if abs(a-b) >= PI: #only need to adjust for the long way round
		if a > b:
			b += 2 * PI
		else:
			a += 2 * PI
	return move_towards_float(a, b, d)

func move_towards_float (x, target, step): #Moves towards t without passing it
	if abs(target - x) < abs(step):
		return target
	else: return x + step

func _draw():
	
#	var point1 = Vector2(100,100)
#	var point2 = Vector2(100,-100)
#	var point3 = Vector2(-100,-100)
#	var point4 = Vector2(-100,100)
#	print(rad2deg(atan2(point1.y,point1.x)))
#	print(rad2deg(atan2(point2.y,point2.x)))
#	print(rad2deg(atan2(point3.y,point3.x)))
#	print(rad2deg(atan2(point4.y,point4.x)))
	print("Angle Limits: ",rad2deg(anglelimits[0]),"  ",rad2deg(anglelimits[1]),"  ",rad2deg(atan2(get_global_mouse_position().y,get_global_mouse_position().x)))
	
	draw_line(Vector2(),Vector2(100,0),Color(1,0,0),2)
	if desiredangle:
		draw_line(Vector2(),to_local(Vector2(100,0).rotated(desiredangle)),Color(1,0,0))
		draw_circle(to_local(desiredpoint),4,Color(0.3,2,0.7))
	if targetpoly:
		draw_set_transform(Vector2(),-rotation,scale)
		draw_polygon(targetpoly,PoolColorArray([Color(1,0.8,0.8,0.6)]))

func normalizeangle(angle):
	angle = (fposmod(angle + PI, PI*2) - PI)*-1
	if angle < 0:
		angle=angle+2*PI
	return angle

func godot_angle(angle):
	angle = (fposmod(angle - PI,PI*2)-PI)*-1
	
	return angle

func generateTargetingPolygon(minrange,maxrange,angle,offset):
	anglelimits = [deg2rad(-angle/2+offset),deg2rad(angle/2+offset)]
	targetpoly.append(Vector2(minrange,0).rotated(deg2rad(-angle/2+offset)))
	for i in range(-angle/2,angle/2,3):
		print("Point at angle ",i)
		targetpoly.append(Vector2(minrange,0).rotated(deg2rad(i+offset)))
	targetpoly.append(Vector2(minrange,0).rotated(deg2rad(angle/2+offset)))
	targetpoly.append(Vector2(maxrange,0).rotated(deg2rad(angle/2+offset)))
	for i in range(-angle/2,angle/2,3):
		print("Point at angle ",i)
		targetpoly.append(Vector2(maxrange,0).rotated(deg2rad(-i+offset)))
	targetpoly.append(Vector2(maxrange,0).rotated(deg2rad(-angle/2+offset)))

var targetpoly = []
