extends Control

#Points to objectives, onscreen and off
#Also tracks and updates the current objectives and their progress

var mission

var active_objectives = [] #Everything currently displayed
var pointer_targets = [] #Things to point at

#onready var camera = get_parent().get_parent().getPlayerCamera()
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
		if objective.isPointerObjective:
			addPointerObjective(objective.target)

var r_offset=0
func _process(delta):
	for obj in active_objectives:
#		var list = $Pointers.get_children()
		var t = obj.target
		var p = $Pointers.get_child(active_objectives.find(obj.target)+1) #+1 offset to ignore template
#		p.rect_position = t.global_position + Vector2(0,-15)
#		p.set_global_position( t.get_global_transform_with_canvas().origin )
		var pos = (t.get_global_transform_with_canvas().origin-Vector2(p.rect_size.x/2,p.rect_size.y) + Vector2(0,-50))
		var screensize = OS.get_screen_size()
		var clampx = clamp(pos.x,0+screensize.x*.25,screensize.x*.75)
		var clampy = clamp(pos.y,0+screensize.y*.15,screensize.y*.85)
		p.set_global_position(Vector2(clampx,clampy))
		r_offset+=25*delta
#		p.rect_position = p.rect_position + Vector2(0,-100)
		p.rect_rotation = rad2deg(p.rect_position.angle_to_point(t.get_global_transform_with_canvas().origin-p.rect_size/2)+PI)
		var distance_to = (t.get_global_transform_with_canvas().origin-p.rect_position).length()
		var transparency = lerp(1,0.05,distance_to/800)
		p.modulate = Color(1,1,1,transparency)
#		p.rect_rotation += r_offset*delta
#		p.modulate=Color(randi())

func addPointerObjective(target):
	var newp = $PointerTemplate.duplicate()
	$Pointers.add_child(newp)
	newp.visible=true
	newp.name=str("Pointer To ",target.name)
	pointer_targets.append(target)
	newp.rect_pivot_offset = newp.rect_size/2

func removePointerObjective(target):
	if target in pointer_targets:
		var p = $Pointers.get_child(pointer_targets.find(target))
		$Pointers.remove_child(p)
		pointer_targets.erase(target)

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
		if obj.isPointerObjective and obj.target in pointer_targets:
			pass
			removePointerObjective(obj.target)
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
