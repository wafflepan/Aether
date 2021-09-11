extends Area2D


func _on_Sprite_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.is_pressed():
		get_parent().selectTarget(self)
