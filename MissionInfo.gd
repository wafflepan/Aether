extends Control

#Points to objectives, onscreen and off
#Also tracks and updates the current objectives and their progress

var mission

var active_objectives = [] #Everything to point at

onready var objectivelist = $MissionObjectives/MarginContainer/ScrollContainer/Objectives
onready var missiontitle = $MissionObjectives/CenterContainer/MissionName

func _ready():
	pass
	#For now, hardcoded add a mission
	var newmission = load("res://Mission.gd").new()
	newmission.setupMission(self)
#	self.add_child(newmission)
	mission=newmission
	mission.connect("update_mission_objectives",self,"loadMissionObjectives")
	loadMission()
	nextMissionPhase()

func nextMissionPhase():
	var phase = mission.getObjectives()
	for objective in phase:
		mission.connectObjectiveSignals(objective)
	mission.activateNextPhase()
	updateMissionPhase()

func loadMissionObjectives():
	clearMissionObjectiveList() #TODO make this a fadeout on absent objectives or something
	for objective in mission.getObjectives():
		objective.connect("objective_completed",self,"onObjectiveComplete")
		var lab = RichTextLabel.new()
		lab.bbcode_enabled=true
		lab.fit_content_height=true
		lab.bbcode_text = objective.getText()
		objectivelist.add_child(lab)
		active_objectives.append(objective)
		if objective.objective_type == objective.objective_types.AREA and !(objective.target.get_parent()):
			get_parent().get_parent().get_node("MissionData").add_child(objective.target)

func loadMission():
	mission.connect("mission_complete",self,"onMissionComplete")
	self.add_child(mission)
	updateMissionPhase()

func updateMissionPhase():
	var n = mission.getMissionName()
	var phase = mission.getPhaseName()
	if phase:
		missiontitle.bbcode_text=str("[center]",n,(" : "),phase,"[/center]")
	else:
		missiontitle.bbcode_text=str("[center]",n,"[/center]")

func clearMissionObjectiveList():
	active_objectives.clear()
	for child in objectivelist.get_children():
		child.queue_free()

func onObjectiveComplete(obj):
	if obj in active_objectives:
		var label = objectivelist.get_child(active_objectives.find(obj)) #Should always grab correct index? I hope???
#		var text = label.bbcode_text
		label.bbcode_text = "[s][color=#66FF99]%s[/color][/s]" % label.bbcode_text

func onMissionComplete(mis):
	get_parent().get_parent().get_node("ScreenTransition/AnimationPlayer").play("fade_black") #TODO Transition to post-mission screen

func onObjectiveFailed():
	pass

func onGoalComplete():
	print("GOAL FINISHED")

func onGoalFailed():
	print("GOAL FAILED")
