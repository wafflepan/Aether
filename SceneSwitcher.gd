extends Node

#Utility for passing parameters to and from a dictionary so scenes can load incoming data from previous scenes.

var dict = {}

func addData(id,input):
	dict[id]=input

func getData():
	return dict.duplicate(true)

func clearData():
	dict.clear()

func giveStack(d):
	#Pass whole stack to dict at once
	dict = d

func takeStack(): #Pop stack of inputs to clear for future scene switching use
	var results = getData()
	clearData()
	return results

func readStack(): #Read without popping, used for scenes that return back to a 'hub' scene like dock menus.
	return getData()

func switchScenes(newscenepath):
#	print(get_tree())
	assert(!get_tree().change_scene(newscenepath))
