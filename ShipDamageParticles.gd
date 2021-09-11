extends Node2D

func setup(magnitude):
	seed(OS.get_ticks_msec())
	$Particles2D.emitting=true
	$AnimationPlayer.play("explosion")
	$Particles2D.amount = rand_range(4,10)
	$Sprite.scale = rand_range(0.1,1) * Vector2(1,1)
	$Particles2D.scale = rand_range(0.1,.5) * Vector2(1,1)

func _process(delta):
	if !$AnimationPlayer.is_playing():
		$Sprite.visible=false
	if !$Particles2D.emitting and !$AnimationPlayer.playback_active:
		self.queue_free()
