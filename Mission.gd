extends Node

#Contains information for what the mission is and how to complete it
#For now, a basic 'go to the thing' mission.

var mission_name = "Test Mission 1"
var phaseNames = ["Test Phase 1","Test Phase 2"]
var objectives = []


#ACTIVE OBJECTIVES FOR A GIVEN PHASE
var required_objectives = [] #Mandatory for completion of current phase
var optional_objectives = []

var missionmanager

var currentphase = -1 #Starts at -1 to become 0 at start

var missionphases = []

var extraction_type #How does the player ship leave at the end of the battle?
#Options include fleeing off the edge, fade to black
#Just fade to black for now

signal mission_complete
signal mission_failed
signal update_mission_objectives
signal phase_complete

class MissionObjective:
	signal objective_completed
	signal objective_failed
	signal objective_updated
	enum objective_types {AREA,ELIMINATE,ESCORT}
	#AREA: Enter the area(s), 
	var objective_type = objective_types.AREA
	var targets = []#The goal area(s) or unit(s) associated with this mission. TODO: how does this work for multi-target/multi-area
	var completed = [] #Which goal targets have already been met
	var failed = []
	
	
	var isClearedAtPhaseEnd=true #Used for optional objectives that can persist for entire missions
	var isOptional = false
	var isPointerObjective = true #Decide whether or not an arrow points at this objective at all times
	var isHiddenObjective = false #Whether or not to display the objective. Primarily used for obvious ones like 'player not dying'
	var isFailureObjective = false #Objective is not 'completed', can only be failed. Used for escorting stuff.
	var failuretext = "Replace Failure Text" #Displayed in post-mission stats as reason for mission failure
	var failThreshold = 0 #How many failures it takes before the objective is considered lost
	#TODO: Modify this so it can be stuff like search areas, or changing pointer strength/appearance time
	
	var objective_text = "Proceed to Location Alpha"
	
	func _init(desc=null):
		if desc:
			objective_text=desc
	
	func getText():
		return objective_text
	
	func onGoalComplete(target):
		if target in targets:
			if target in completed:
				print("tried to add a completed target to the list but it's already there! Duplicate signals?")
			completed.append(target)
			emit_signal("objective_updated",self)
			
			if completed.size() == targets.size():
				objectiveCompleted()
	
	func onGoalFailed(target):
		failed.append(target)
		if failed.size()>failThreshold:
			objectiveFailed()
	
	func objectiveCompleted():
		emit_signal("objective_completed",self)
		#Once an objective is completed, inform the mission manager
	
	func objectiveFailed():
		emit_signal("objective_failed",self)


func setupMission(mng): #Placeholder function to create mission parameters (this'll be done by the mission builder system later)
	missionmanager=mng
	playerDeathCondition()
#	objectives.append(createAreaObjective(Vector2(700,0))) #Basic Area Entry
	
	#Kill Patrol Ship Mission (handcoded)
	var newobj = MissionObjective.new()
	newobj.objective_type=newobj.objective_types.ELIMINATE
	newobj.objective_text="Eliminate All Enemy Vessels"
	for item in missionmanager.get_tree().get_nodes_in_group("ships"):
		if item.faction_id == 1:
			newobj.targets.append(item) #TODO: this is backwards, entity here should be passing spawn requests
	objectives.append(newobj)
#	newobj = MissionObjective.new()
#	newobj.objective_type=newobj.objective_types.ELIMINATE
#	newobj.objective_text="Eliminate Enemy Vessel Again"
#	newobj.target=missionmanager.get_parent().get_parent().get_node("Entities/PatrolShip2")
#	objectives.append(newobj)
#
#	newobj = MissionObjective.new()
#	newobj.objective_type=newobj.objective_types.ELIMINATE
#	newobj.objective_text="More Vessel, More Elimination."
#	newobj.target=missionmanager.get_parent().get_parent().get_node("Entities/PatrolShip3")
#	objectives.append(newobj)
#
#	newobj = MissionObjective.new()
#	newobj.objective_type=newobj.objective_types.ELIMINATE
#	newobj.objective_text="Spare This Vessel. KIDDING! ELIMINATE!"
#	newobj.target=missionmanager.get_parent().get_parent().get_node("Entities/PatrolShip4")
#	objectives.append(newobj)
	
	#PHASE TWO OF MISSION: 3 Areas Entered
	finalizePhase()
#	objectives.append(createAreaObjective(Vector2(1000,0),"Rally at Bravo"))
#	objectives.append(createAreaObjective(Vector2(1000,500),"Rally at Delta"))
#	objectives.append(createAreaObjective(Vector2(1000,-500),"Rally at Charlie"))
#	finalizePhase()

func getPlayerShip():
	for item in missionmanager.get_tree().get_nodes_in_group("ships"):
		if item.faction_id==2:
			return item

func playerDeathCondition():
	#Create an invisible 'escort mission' that tracks the player's ship as a failure condition. TODO: eventually this should be player's entire fleet, yeah?
	var newobj =MissionObjective.new()
	newobj.objective_type = newobj.objective_types.ESCORT
	newobj.targets.append(getPlayerShip())
	newobj.isFailureObjective=true
	newobj.isHiddenObjective=false #change for final
	newobj.isClearedAtPhaseEnd=false
	newobj.objective_text = "Your Flagship Must Survive!"
	newobj.failuretext="Your ship was destroyed!"
	objectives.append(newobj)

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
	objectives.erase(obj)
	if obj in required_objectives:
		required_objectives.erase(obj)
	else:
		optional_objectives.erase(obj)
	
	
	if checkObjectivesComplete():
		emit_signal("phase_complete")

func checkObjectivesComplete(): #TODO: check the objectives, ignore the ones that are ESCORT or other non-completable (fail-only) types, exclude from checking.
	for objective in required_objectives:
		if !(objective.isFailureObjective or objective.objective_type == objective.objective_types.ESCORT): #Look for remaining objectives to complete
			return false#objectives remain
	return true#Otherwise, cleared for next phase!

func onObjectiveFailed(obj):
	emit_signal("mission_failed")

func createAreaObjective(where,desc=null): #Quick hacky utility for making player-usable oneshot areas.
	var newobj=MissionObjective.new(desc)
	newobj.objective_type=newobj.objective_types.AREA
	var newarea = load("res://MissionGoalArea.tscn").instance()
	newarea.position = where
	newobj.target=newarea
	newarea.mission=self
	newarea.addValidGroup("player")
	return newobj

func finalizePhase():
	if !objectives.size():
		print("ERROR: Mission tried to finalize a phase with no objectives")
		return -1
	missionphases.append(objectives)
	objectives=[]

func activateNextPhase():
#	if required_objectives.size(): #This should never happen unless the mission has a fail phase!
#		print("MOVING TO NEXT PHASE WITHOUT COMPLETION OF ALL OBJECTIVES")
	for x in optional_objectives: #Erase the non-persistent optional objectives
		if x.isClearedAtPhaseEnd: #TODO: stuff here to disconnect signals cleanly, some kind of removeObjective call to the MissionInfo
			optional_objectives.erase(x)
	currentphase+=1 #Increment phase
	if currentphase == missionphases.size(): #If no more phases, mission ends! Should maybe have a 'conclusion phase' that includes retreat, etc.
		print("Mission Phases Resolved: Mission Complete! TODO")
		#emit mission completed signal?
		emit_signal("mission_complete",self) #For now, causes fadeout. TODO: postgame menu?
	else: #Load next phase of objectives, pass to MissionInfo, etc.
		objectives=objectives + missionphases[currentphase] #TODO make this a standard 'loadMissionPhase' call
		for obj in objectives:
			connectObjectiveSignals(obj)#Connect each object
			if obj.isOptional == false:
				required_objectives.append(obj)
			else:
				optional_objectives.append(obj)
		emit_signal("update_mission_objectives")

func connectObjectiveSignals(obj):
	#Link up the goal_completed signal to the Mission Info manager, either from elimination targets or Goal Areas
	obj.connect("objective_completed",self,"onObjectiveComplete")
	obj.connect("objective_failed",self,"onObjectiveFailed")
	obj.connect("objective_updated",missionmanager,"updateObjective")
	for target in obj.targets:
		match obj.objective_type:
			obj.objective_types.AREA:
#				print("Objective Type: AREA")
				target.connect("goal_completed",obj,"onGoalComplete")
			obj.objective_types.ELIMINATE:
#				print("Objective Type: ELIMINATE")
				target.connect("unit_destroyed",obj,"onGoalComplete")
			obj.objective_types.ESCORT:
#				print("Objective Type: ESCORT")
				target.connect("unit_destroyed",obj,"onGoalFailed")
