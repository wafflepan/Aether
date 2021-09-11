extends Area2D

#Detects when an entity flagged by the Mission Coordinator as having to reach this location occurs.

#Depending on the goal area type, might require the ship to remain inside for a set duration.

enum goal_types {ON_ENTRY_ANY, ON_ENTRY_NUMBER, TIME_OCCUPY, TIME_OCCUPY_ADDITIVE}
var type = goal_types.ON_ENTRY_ANY
#On Entry Any: One tagged ship reaches the goal instantly completes the objective.
#On Entry Number: A certain number of tagged entities
#Time Occupy: tagged entity must remain inside for the duration
#Time Occupy Additive: Tagged entity must remain inside for the duration, but leaving and reentering does not reset progress.

var mission #Mission object that this goal area is associated with

var active=true #Whether or not this mission object shows up and has an associated waypoint

var time_total
var time

var validgroups = [] #Groups of entities that count
var validobjects = [] #Individual entities that count

var registered = [] #Ships that have already used this mission zone successfully

#signal goal_conditions_updated #Time ticking down, another ship enters, etc etc.
signal goal_completed #Area is finished and can delete itself after sending this signal

func _ready():
	$Collider.polygon=$Polygon.polygon

func groupsCheck(bod):
	for group in validgroups:
		if bod.is_in_group(group):
			return true
	return false

func addValidGroup(g):
	validgroups.append(g)

func addValidObject(o):
	validobjects.append(o)

func _on_MissionGoalArea_body_entered(body):
	
	if body in validobjects or groupsCheck(body): #Make sure it's a valid entity
		if type == goal_types.ON_ENTRY_ANY:
			print(body.name)
			emit_signal("goal_completed",self)
			queue_free()
