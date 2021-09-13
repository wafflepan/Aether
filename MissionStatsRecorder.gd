extends Node

var start_time = null

var missiondict = {}

#Records all the important events of a mission!

#Events Like:

#(all events timestamped relative to mission start)

#Each weapon firing event, owner
#Each weapon hit event, owner

#Each ship destroyed, and by who

#Each objective completed

#Elapsed Time

func getMissionDict():
	return missiondict

func setMissionInfo(mis):
	pass
	#Mission info like name, objectives
	missiondict["mission_name"]=mis.getMissionName()
	missiondict["mission_data_full"]=mis

func startMissionRecording():
	start_time = OS.get_ticks_msec()
	missiondict["start_time"]=start_time

func recordWeaponFire(weapon,shooter):
	pass
	var entry = {"weapon":weapon,"owner":shooter,"time":getMissionTime()}

func getMissionTime():
	return OS.get_ticks_msec()-start_time #Does this fuck up if you cross a dateline/midnight? ticks/msec instead?

func finishMissionRecording():
	missiondict["end_time"] = OS.get_ticks_msec()
