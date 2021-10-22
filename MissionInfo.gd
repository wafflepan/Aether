extends Control

#Points to objectives, onscreen and off
#Also tracks and updates the current objectives and their progress

var mission

var active_objectives = [] #Everything currently displayed
var pointer_targets = [] #Things to point at

#onready var camera = get_parent().get_parent().getPlayerCamera()
var camera
onready var objectivelist = $MissionObjectives/MarginContainer/ScrollContainer/Objectives
onready var missiontitle = $MissionObjectives/CenterContainer/MissionName

func _ready():
	#For now, hardcoded add a mission
	var newmission = load("res://Mission.gd").new() #TODO: replace with query to mission generator
	newmission.setupMission(self)
	
	mission=newmission
	loadMission()
	nextMissionPhase() #Load in 'next' phase of mission (the first)

func nextMissionPhase():
#	var phase_objectives = mission.getObjectives()
#	for objective in phase_objectives: #For each objective in the current phase:
#		mission.connectObjectiveSignals(objective) #Connect the signals of the objective
	mission.activateNextPhase() #Signal the mission to proceed as normal

func loadMissionObjectives():
	updateMissionPhase() #Update title and labels
	clearMissionObjectiveList() #TODO make this a fadeout on absent objectives or something
	for objective in mission.getObjectives():
#		if !objective in active_objectives: #Only do for objectives that aren't still in the list from last phase!
		objective.connect("objective_completed",self,"onObjectiveComplete")
		active_objectives.append(objective)
		for t in objective.targets:
			if objective.objective_type == objective.objective_types.AREA and !(t.get_parent()):
				get_parent().get_parent().get_node("MissionData").add_child(t)
			if objective.isPointerObjective:
				addPointerObjective(t)
		if !objective.isHiddenObjective:
			var lab = RichTextLabel.new()
			lab.bbcode_enabled=true
			lab.fit_content_height=true
			lab.bbcode_text = objective.getText()
			objectivelist.add_child(lab)
			updateObjective(objective)
	#		else:
#			print(objective," still in list from last time! Ignoring.")

var r_offset=0
func _process(delta):
	if camera:
		for t in pointer_targets:
	#		var list = $Pointers.get_children()
	#		var t = obj.target
			var zoomscalar = camera.zoom.x #Zoom on player cam is symmetric
			var p = $Pointers.get_child(pointer_targets.find(t)) #+1 offset to ignore template
			var pos = (t.get_global_transform_with_canvas().origin-Vector2(p.rect_size.x/2,p.rect_size.y) + Vector2(0,-50)/(zoomscalar*2))
			var screensize = get_viewport_rect().size
			var clampx = clamp(pos.x,0+screensize.x*.15,screensize.x*.82)
			var clampy = clamp(pos.y,0+screensize.y*.15,screensize.y*.85)
			p.set_global_position(Vector2(clampx,clampy))
			p.rect_rotation = rad2deg(p.rect_position.angle_to_point(t.get_global_transform_with_canvas().origin-p.rect_size/2)+PI)
			var distance_to = (t.get_global_transform_with_canvas().origin-p.rect_position).length()
			var transparency = lerp(1,0.2,min(1,max(0.2,distance_to/800)))
			p.modulate = Color(1,1,1,transparency) #TODO: have color changes on pointers for attack/defend/occupy (red blue green)
			p.get_node("Label").text=t.name

func addPointerObjective(target):
	var newp = $PointerTemplate.duplicate()
	$Pointers.add_child(newp)
#	$Pointers.move_child(newp,0)
	newp.visible=true
	newp.name=str("Pointer To ",target.name)
	pointer_targets.append(target)
	newp.rect_pivot_offset = newp.rect_size/2

func removePointerObjective(target):
	if target in pointer_targets:
		var p = $Pointers.get_child(pointer_targets.find(target))
		p.queue_free()
		pointer_targets.erase(target)

func loadMission(): #Connect all mission signals
	mission.connect("update_mission_objectives",self,"loadMissionObjectives")
	mission.connect("phase_complete",self,"nextMissionPhase")
	mission.connect("mission_complete",self,"onMissionComplete")
	mission.connect("mission_failed",self,"onMissionFailed")
	get_parent().get_parent().get_node("MissionStatsRecorder").setMissionInfo(mission)
#	self.add_child(mission)
#	updateMissionPhase()

func updateMissionPhase(): #Update name of mission and current phase.
	var n = mission.getMissionName()
	var phase = mission.getPhaseName()
	if phase:
		missiontitle.bbcode_text=str("[center]",n,(" : "),phase,"[/center]")
	else:
		missiontitle.bbcode_text=str("[center]",n,"[/center]")

func clearMissionObjectiveList():
	active_objectives.clear()
	pointer_targets.clear()
	for child in objectivelist.get_children():
		child.queue_free()
	for child in $Pointers.get_children():
		child.queue_free()

func updateObjective(obj):
	#For a given objective, update its entry. This is used for changing mission parameters mid-fight, or updating partial completion.
	if obj in active_objectives and !obj.isHiddenObjective:
		for t in obj.completed:
			if t in pointer_targets:
				removePointerObjective(t)
		var entry = objectivelist.get_child(active_objectives.find(obj))
		entry.bbcode_text = str(obj.getText(),"\t",obj.completed.size(),"/",obj.targets.size())
#		print(entry.bbcode_text)

func onObjectiveComplete(obj): #TODO disconnect signals
	if obj in active_objectives:
		var label = objectivelist.get_child(active_objectives.find(obj)) #Should always grab correct index? I hope???
		if obj.isPointerObjective:
			for t in obj.targets:
				removePointerObjective(t)
		label.bbcode_text = "[s][color=#66FF99]%s[/color][/s]" % label.bbcode_text
#		active_objectives.erase(obj)

func onMissionComplete(mis): #TODO: add some delay in here, yeah?
	$MissionEndTitle.victory()
	yield($MissionEndTitle/Tween,"tween_all_completed")
	get_parent().get_parent().switchToPostCombatScreen(mission)

func onObjectiveFailed():
	onMissionFailed()

func onMissionFailed():
	$MissionEndTitle.defeat()
	get_parent().get_parent().switchToPostCombatScreen(mission)

func onGoalComplete():
	print("GOAL FINISHED")

func onGoalFailed():
	print("GOAL FAILED")
