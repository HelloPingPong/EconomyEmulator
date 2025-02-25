class_name EconomyEvent

enum Types {
	IMMEDIATE,
	LINEAR_IN,
	LINEAR_OUT
	WAVE
}

var name : String
var start_time : float
var _end_time : float
var duration : float
var modifier : PriceModifier
var type : int

func _init(n = '', m = null, st = 0, d = 1, t = Types.IMMEDIATE):
	name = n
	modifier = m
	start_time = st
	duration = d
	type = t
	
	_end_time = start_time + duration
	
func get_price_modifier(time : float):
	var result_modifier : PriceModifier
	var percent : float = 1.0
	
	if time < start_time or time > _end_time:
		result_modifier = null
		return result_modifier
	
	result_modifier = modifier.duplicate()
	result_modifier.set_percent(_interpolate(time))
		
	return result_modifier
	
func get_price_modification(time : float):
	var result_modifier : PriceModifier = modifier
	var percent : float = 1.0
	var result : PriceModification 
	
	if time < start_time or time > _end_time:
		percent = 0
		return result_modifier.get_percent_modification(0)
	
#	if type == Types.IMMEDIATE:
#		result_modifier = modifier
		
	result = result_modifier.get_percent_modification(_interpolate(time))
		
	return result
	
func _interpolate(time : float):
	var value : float
	var time_percent = (time - start_time) / duration
	match type:
		Types.WAVE:
			value = sin(time_percent * PI)
		Types.LINEAR_IN:
			value = time_percent
		Types.LINEAR_OUT:
			value = 1 - time_percent
		Types.IMMEDIATE:
			value = 1
	return value

func duplicate():
	var clone = get_script().new()
	
	clone.name = name
	clone.start_time = start_time
	clone._end_time = _end_time
	clone.duration = duration
	clone.type = type
	clone.modifier = modifier
	
	return clone
	
func set_start_time(t : float):
	start_time = t
	_end_time = start_time + duration
