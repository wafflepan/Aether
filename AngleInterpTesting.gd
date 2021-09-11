extends Node2D
var desiredpoint = Vector2()

var desiredangle=null
var turnspeed = deg2rad(190)
var anglelimits = []

var angleprogress = 0.0

func _ready():
	generateTargetingPolygon(100,200,240)
#	anglelimits = [deg2rad(-135),deg2rad(135)]
	
	#Angle Extents: First angle to second angle always sweeps clockwise (through/towards zero) to describe the bounds of valid space
	
	#CASES AS FOLLOWS:
	
	#START ANGLE BELOW 180 (top hemisphere)

func _process(delta):
#	update()
	print(rad2deg(Vector2(1,0).rotated(self.global_rotation).angle_to(get_global_mouse_position()-global_position)))
	if desiredangle:
		
		var facing = (Vector2(1,0).rotated(self.global_rotation).angle_to(desiredpoint-global_position))
		if abs($TurretNode.rotation-facing) < turnspeed*delta:
			$TurretNode.rotation = facing
			desiredangle = null
		else:
			var midpoint = ($TurretNode.rotation + facing)/2
			$TurretNode.rotation = lerp_angle($TurretNode.rotation,midpoint,delta*turnspeed/(abs(angle_to_angle($TurretNode.rotation,midpoint))))

static func angle_to_angle(from, to):
	return fposmod(to-from + PI, PI*2) - PI

func _draw(): #TODO replace this with an actual polygon attached to the turret base
	if targetpoly:
		draw_polygon(targetpoly,PoolColorArray([Color(1,0.8,0.8,0.6)]))

func generateTargetingPolygon(minrange,maxrange,angle):
	var angle2 = (deg2rad(-angle/2))
	var angle1 = (deg2rad(angle/2))
	targetpoly= []
#	targetpoly.resize(100) TODO optimization
	anglelimits = [(angle1),(angle2)]
	var step = 0.03
	var i = angle1 #The positive (large) angle
	assert(angle1>angle2)
	targetpoly.append(Vector2(minrange,0).rotated(angle1))
	while i >= angle2:
		targetpoly.push_back(Vector2(minrange,0).rotated(i))
		targetpoly.push_front(Vector2(maxrange,0).rotated(i))
		
		i-= step
	targetpoly.append(Vector2(maxrange,0).rotated(angle2))
	update()

var targetpoly = []
