extends KinematicBody2D

var lifetime #Lifetime variance [low,high]

var accuracy #How many shots will 'miss' by passing over/under target.

var projectilespeed
var projectiledragco

var penetration = 100

export(int) var damage

var hits = []
var firedby = null

var lasthit = null

func _ready():
	lifetime = rand_range(lifetime[0],lifetime[1])
#	add_collision_exception_with(firedby)

func _physics_process(delta):
	var dist = Vector2(projectilespeed,0).rotated(self.rotation)
	while dist.length_squared()>0.001:
		var collide = move_and_collide(Vector2(projectilespeed,0).rotated(self.rotation))
		if lasthit:
			penetration = penetration - dist.length()
		if collide:
			if randf() > accuracy:
				#Miss!
				add_collision_exception_with(collide.collider) 
				dist=collide.remainder
			else:
				add_collision_exception_with(collide.collider)
				hitTarget(collide)
				dist = collide.remainder
		else:
			dist = Vector2()
	projectilespeed = max(0,projectilespeed-projectiledragco*projectilespeed*delta)
	lifetime -= delta
	if lifetime <= 0 or projectilespeed == 0:
		fadeout()

func setupProjectile(data):
	var projectile=self
	projectile.setTexture(data.projectile_texture)
	projectile.lifetime = [data.projectile_lifetime,data.projectile_lifetime+(0.1*data.projectile_lifetime)] #10% variance for now, probably relate directly to range instead
	projectile.accuracy = data.accuracy
	projectile.projectilespeed = data.projectile_speed
	projectile.projectiledragco = data.projectile_drag
	projectile.damage = data.damage_per_shot

func setTexture(t):
	$Sprite.texture=t

signal bullet_hit_target

func hitTarget(col):
	print("Bullet hit ",col.collider.name)
	if col.collider.has_method("takeDamage"):
		col.collider.takeDamage(damage,col)
		$AnimationPlayer.play("explosion")
		$CollisionShape2D.disabled=true
		$Sprite.visible=false
		projectilespeed=0
		$ExplosionSprite.visible=true
		yield($AnimationPlayer,"animation_finished")
		$ExplosionSprite.visible=false
	if penetration<=0:
		remove()

func fadeout():
	$AnimationPlayer.play("fadeout")
	remove()

func remove():
	if $CollisionShape2D.disabled==false:
		$Particles2D.emitting=false
		$CollisionShape2D.disabled=true
		set_physics_process(false)
		yield(get_tree().create_timer(0.5+$Particles2D.lifetime),"timeout")
		queue_free()
