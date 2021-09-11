extends Control


onready var button = $TextureButton
var turret


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func assignTurret(t):
	turret=t
	$ReloadBar.max_value=turret.reloadtime*100

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if turret:
		$ReloadBar.value = turret.reloadtime*100 - turret.reload*100


func _on_ShipDiagramHardpoint_mouse_entered():
	turret.showArc()


func _on_ShipDiagramHardpoint_mouse_exited():
	turret.hideArc()
