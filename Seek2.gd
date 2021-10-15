extends Area2D

func _ready():
	randomize()

	$Timer.wait_time=rand_range(5,10)
	fadein()
#	if randf()<0.5:
#		fadeout()
#	else:
#		fadein()

func fadeout():
	self.remove_from_group("seek")
	$Tween.interpolate_property(self,"modulate",self.modulate,Color(1,1,1,0.4),.3)
	$Tween.start()
	$Timer.start()
	yield($Timer,"timeout")
	fadein()

func fadein():
	self.add_to_group("seek")
	$Tween.interpolate_property(self,"modulate",self.modulate,Color(1,1,1,1),.3)
	$Tween.start()


func _on_Seek2_body_entered(body):
	if body.is_in_group("ships"):
		fadeout()
