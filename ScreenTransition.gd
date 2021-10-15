extends CanvasLayer

signal finished

func _ready():
	fadeIn()

func fadeIn():
	$AnimationPlayer.play("unfade_black")
	yield($AnimationPlayer,"animation_finished")
	emit_signal("finished")

func fadeOut():
	$AnimationPlayer.play("fade_black")
	yield($AnimationPlayer,"animation_finished")
	emit_signal("finished")
