extends Node2D

var lifetime = [5,5.5] #Lifetime variance [low,high]

var accuracy = .9 #How many shots will 'miss' by passing over/under target.

var projectilespeed = 10
var projectiledragco = 0.1

func _ready():
	lifetime = rand_range(lifetime[0],lifetime[1])

func _process(delta):
	self.position += Vector2(projectilespeed,0).rotated(self.rotation)
	projectilespeed-= projectiledragco*projectilespeed*delta
	lifetime -= delta
	if lifetime <= 0:
		self.queue_free()
