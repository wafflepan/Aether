extends Control

onready var diagram = $Control/MarginContainer/ViewportContainer/Viewport/ShipDiagram

func assignShip(sh):
	diagram.assignShip(sh)

func showPanel():
	self.visible=false

func hidePanel():
	self.visible=true

func _on_ShipPanel_resized():
	pass
#	if diagram and diagram.ship:
#		diagram.assignShip(diagram.ship)
