extends Control

var wp = null #TurretData object loaded in from GLOBAL stats singleton

func assignWeapon(w):
	wp = w
	$MarginContainer/Label.bbcode_text=wp.display_name

func get_drag_data(position):
	var tex=TextureRect.new()
	tex.rect_min_size=Vector2(50,50)
	tex.texture=wp.icon
	tex.rect_position=Vector2(100,0)
	set_drag_preview(tex)
	return {"turret_type":wp.turret_name,"turret_icon":GlobaLturretStats.getTurretIconFromType(wp.turret_name)}

func can_drop_data(_pos,data):
#	print("Check data drop")
	return true

func drop_data(_pos,data):
#	print("Drop data")
	pass
