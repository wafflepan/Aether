extends CenterContainer

func _ready():
	$Particles2D.position = $TextureRect.rect_position

func victory():
	pass #Eventually these will pull from mission info to change the flavor text
	fadein()

func defeat():
	pass #Swap to defeat text, then fadein
	$TextureRect.texture = load("res://defeat_1.png")
	fadein()

func fadein():
	$Particles2D.emitting=true
	$Tween.interpolate_property($TextureRect,"modulate",Color(1,1,1,0),Color(1,1,1,1),1)
	$Tween.start()
