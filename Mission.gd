extends Node

#Contains information for what the mission is and how to complete it
#For now, a basic 'go to the thing' mission.

var mission_name = "Test Mission 1"
var phaseNames = ["Test Phase 1","Test Phase 2"]
var objectives = []

var required_objectives = [] #Mandatory for completion of current phase
var optional_objectives = []

var missionmanager

var currentphase = -1 #Starts at -1 to become 0 at start

var missionphases = []

var extraction_type #How does the player ship leave at the end of the battle?
#Options include fleeing off the edge, fade to black
#Just fade to black for now

signal mission_complete
signal update_mission_objectives

class MissionObjective:
	signal objective_completed
	enum objective_types {AREA,ELIMINATE,ESCORT}
	var objective_type = objective_types.AREA
	var target #The goal area or ship associated with this mission
	
	var isClearedAtPhaseEnd=true #Used for optional objectives that can persist for entire missions
	var isOptional = false
	var isPointerObjective = true #Decide whether or not an arrow points at this objective at all times
	#TODO: Modify this so it can be stuff like search areas, or changing pointer strength/appearance time
	
	var objective_text = "Proceed to Location Alpha"
	
	func _init(desc=null):
		if desc:
			objective_text=desc
	
	func getText():
		return objective_text
	
	func onGoalComplete(_target):
		pass
		#TODO
		#for now, only have partial/single goal objectives
		objectiveCompleted()
	
	func objectiveCompleted():
		emit_signal("objective_completed",self)
		#Once an objective is completed, inform the mission manager

func getMissionName():
	return mission_name
func getPhaseName():
	if phaseNames.size()>currentphase: #If the phase name actually exists
		return phaseNames[currentphase]
	return null
func getObjectives():
	if missionphases.size()>currentphase:
		return missionphases[currentphase]
	else:
		return []

func onObjectiveComplete(obj):
	if obj in required_objectives:
		required_objectives.erase(obj)
	else:
		optional_objectives.erase(obj)
	if required_objectives.size()==0:
		activateNextPhase()

func createAreaObjective(where,desc=null): #Quick hacky utility for making player-usable oneshot areas.
	var newobj=MissionObjective.new(desc)
	newobj.objective_type=newobj.objective_types.AREA
	var newarea = load("res://MissionGoalArea.tscn").instance()
	newarea.position = where
	newobj.target=newarea
	newarea.mission=self
	newarea.addValidGroup("player")
	return newobj

func setupMission(mng):
	missionmanager=mng
#	objectives.append(createAreaObjective(Vector2(700,0)))
	
	var newobj = MissionObjective.new()
	newobj.objective_type=newobj.objective_types.ELIMINATE
	newobj.objective_text="Eliminate Enemy Vessel"
	newobj.target=missionmanager.get_parent().get_parent().get_node("Entities/PatrolShip")
	objectives.append(newobj)
	
	finalizePhase()
	objectives.append(createAreaObjective(Vector2(1000,0),"Rally at Bravo"))
	objectives.append(createAreaObjective(Vector2(1000,500),"Rally at Delta"))
	objectives.append(createAreaObjective(Vector2(1000,-500),"Rally at Charlie"))
	finalizePhase()

func finalizePhase():
	missionphases.append(objectives)
	objectives=[]

func activateNextPhase():
	if required_objectives.size():
		print("MOVING TO NEXT PHASE WITHOUT COMPLETION OF ALL OBJECTIVES")
	for x in optional_objectives:
		if x.isClearedAtPhaseEnd:
			optional_objectives.erase(x)
	currentphase+=1
	if currentphase == missionphases.size():
		print("Mission Phases Resolved: Mission Complete! TODO")
		#emit mission completed signal?
		emit_signal("mission_complete",self)
	else:
		objectives=missionphases[currentphase]
		for obj in objectives:
			connectObjectiveSignals(obj)
			if obj.isOptional == false:
				required_objectives.append(obj)
			else:
				optional_objectives.append(obj)
	emit_signal("update_mission_objectives")

func connectObjectiveSignals(obj):
	pass
	#Link up the goal_completed signal to the Mission Info manager, either from elimination targets or Goal Areas
#	self.connect()
	obj.connect("objective_completed",self,"onObjectiveComplete")
	match obj.objective_type:
		0:
			print("Objective Type: AREA")
			obj.target.connect("goal_completed",obj,"onGoalComplete")
		1:
			print("Objective Type: ELIMINATE")
			obj.target.connect("unit_destroyed",obj,"onGoalComplete")
