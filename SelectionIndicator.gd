extends Node2D

var location=Vector2()
var target = null
var size = Vector2(50,50)
onready var rec = $NinePatchRect
onready var tw = $NinePatchRect/Tween

func _ready():
	startTweens()

func chooseTarget(tg):
	visible=true
	target=tg
	if target.has_signal("disable_target"):
		target.connect("disable_target",self,"clearTarget")

func _process(delta):
	if target:
		self.position=target.position

func clearTarget():
	self.visible=false
	if target and target.has_signal("disable_target"):
		target.disconnect("disable_target",self,"clearTarget")
	target=null

func startTweens():
	tw.interpolate_property(rec,"rect_size",size,size + Vector2(15,15),0.6,Tween.TRANS_SINE,Tween.EASE_IN_OUT)
	tw.interpolate_property(rec,"rect_size",size + Vector2(15,15),size,0.6,Tween.TRANS_SINE,Tween.EASE_IN_OUT,0.6)
	tw.interpolate_property(rec,"rect_position",location,location - Vector2(15/2,15/2),0.6,Tween.TRANS_SINE,Tween.EASE_IN_OUT)
	tw.interpolate_property(rec,"rect_position",location - Vector2(15/2,15/2),location,0.6,Tween.TRANS_SINE,Tween.EASE_IN_OUT,0.6)
	tw.repeat = true
	tw.start()
