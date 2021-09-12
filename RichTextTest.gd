#tool
#extends RichTextEffect
#class_name RichTextPulse
#
## Syntax: [pulse color=#00FFAA height=0.0 freq=2.0][/pulse]
#
## Define the tag name.
#var bbcode = "strike"

#func _process_custom_fx(char_fx):
#	# Get parameters, or use the provided default value if missing.
#	var speed = char_fx.env.get("speed", 1.0) #Time to complete full strikethrough wipe
#	var color = char_fx.env.get("color", char_fx.color)
#	var height = char_fx.env.get("height", 0.0)
#	var freq = char_fx.env.get("freq", 2.0)
#
#	var test1 = char_fx.relative_index
#
#	var sined_time = (sin(char_fx.elapsed_time * freq) + 1.0) / 2.0
#	if test1 > sined_time:
#		pass
#	var y_off = sined_time * height
#	color.a = 1.0
#	char_fx.color = char_fx.color.linear_interpolate(color, sined_time)
#	char_fx.offset = Vector2(0, -1) * y_off
#	return true

tool
extends RichTextEffect
class_name HideTextFX

var bbcode := "hide"

func _process_custom_fx(char_fx : CharFXTransform):
#	var hide_char : String = char_fx.env.get("char", "")
	char_fx.color.a = sin(char_fx.elapsed_time)*10
	if char_fx.relative_index < sin(char_fx.elapsed_time)*10.0:
		char_fx.visible=false
	else:
		char_fx.visible=true
	
#	if char_fx.elapsed_time > 2.0:
#		char_fx.elapsed_time=0
	
	return true
