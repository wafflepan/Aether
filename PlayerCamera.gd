extends Camera2D

func _process(delta):
#	var viewport = get_viewport().size/2
	var mouse_offset = (get_parent().get_local_mouse_position() - get_viewport().size / 2)
	mouse_offset = get_local_mouse_position()
	self.position = lerp(Vector2(), mouse_offset.normalized() * 500, mouse_offset.length()/ 1000)
	self.zoom = lerp(zoom,desiredzoom,zoomspeed)
#	print(mouse_offset,"  ",self.position)

var zoomspeed = .1
var desiredzoom=self.zoom

func _input(event):
	if Input.is_action_just_pressed("camera_zoom_in"):
		desiredzoom -= Vector2(0.1,0.1)
		desiredzoom.x = clamp(desiredzoom.x,0.5,3)
		desiredzoom.y = clamp(desiredzoom.y,0.5,3)
	elif Input.is_action_just_pressed("camera_zoom_out"):
		desiredzoom += Vector2(0.1,0.1)
		desiredzoom.x = clamp(desiredzoom.x,0.5,3)
		desiredzoom.y = clamp(desiredzoom.y,0.5,3)
