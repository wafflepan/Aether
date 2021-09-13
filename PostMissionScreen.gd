extends Node2D
var scenedata
func getSceneData():
	scenedata = SceneSwitcher.takeStack() #Get stuff from previous scene about what actually happened

func _ready():
	getSceneData()
	parseSceneData()
	
	#Tabulated Detail Screens
	#DisplayOverview - mission success or fail, rewards, ship damage, summaries
	#DisplayMissionObjectives - each objective, success or fail
	#DisplayBattleParticipants
	#DisplayWeaponStatistics
	#DisplayPlayerShipLosses
	#Commendations, MVP, Achivements
	#DisplayRewards
	
	$ScreenTransition.fadeIn()

func parseSceneData():
	if !scenedata:
		return
	var missiondata = scenedata["mission_stats"]
	$CanvasLayer/Text/MissionTitle.bbcode_text = str("[center]Mission: ",missiondata["mission_name"],"[/center]")
	var timediff = getTimeDifference(missiondata["start_time"],missiondata["end_time"])
	$CanvasLayer/Text/ElapsedTime.bbcode_text = str("[center]Elapsed Time: ",timediff,"[/center]")

func getTimeDifference(start,end):
	var sec = int(ceil((end-start) / 1000.0))
	
	#seconds to minutes
	var sec_remainder = sec%60
	var minutes = int(floor(sec/60.0))
	#minutes to hours
	var min_remainder = minutes%60
	var hours = int(floor(minutes/60.0))
	
	return str(hours,":",min_remainder,":",sec_remainder)
	#Convert miliseconds to h/m/s format

