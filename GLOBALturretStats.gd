extends Node


#TODO: Load this from a file at runtime.


class turretStatEntry:
	var turret_name #Internal data name for the turret type
	var display_name #What it reads as
	
	var base_texture
	var turret_texture
	var projectile_texture
	
	var damage_per_shot
	var shots_per_reload
	var time_between_shots
	var reload_time
	
	var spread_angle
	var accuracy
	var projectile_speed
	var projectile_drag
	var projectile_lifetime
	
	func _init(tname,dname,base,turret,projectile,damagepershot,shotsperreload,timebetweenshots,reloadtime,spread,acc,projectilespeed,projectiledrag,lifetime):
		turret_name=tname
		display_name=dname
		base_texture=load(str("res://WeaponResources/Base/",base,".png"))
		turret_texture=load(str("res://WeaponResources/Turret/",turret,".png"))
		projectile_texture=load(str("res://WeaponResources/Projectile/",projectile,".png"))
		damage_per_shot=damagepershot
		shots_per_reload=shotsperreload
		time_between_shots=timebetweenshots
		reload_time=reloadtime
		spread_angle=spread
		accuracy=acc
		projectile_speed = projectilespeed
		projectile_drag = projectiledrag
		projectile_lifetime=lifetime

var turretdict = {}

func _ready():
	addTurret("basic","Basic Cannon","base_post","turret_1","bullet2",5,1,.4,2,10,.8,10,.1,5)
	addTurret("ballista","Superheated Ballista","base_gear","turret_ballista","bolt",15,1,.4,4,1,1,20,.1,7)
	addTurret("scatter","Repeating Scattergun","base_post","turret_1","pit",1,8,.15,5,19,.6,8,.9,2)

func addTurret(n,dis_n,base,turret,projectile,damage,clip,firingtime,reloadtime,spread,acc,sp,drag,lif):
	var newturret = turretStatEntry.new(n,dis_n,base,turret,projectile,damage,clip,firingtime,reloadtime,spread,acc,sp,drag,lif)
	turretdict[n]=newturret

func getTurretData(n):
	if turretdict.has(n):
		return turretdict[n]
