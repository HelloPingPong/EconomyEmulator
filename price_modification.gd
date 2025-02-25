class_name PriceModification

var base_addition : float = 0
var base_multiplier : float = 1
var total_addition : float = 0
var total_multiplier : float = 1

func duplicate():
	var clone = get_script().new()
	
	clone.base_addition = base_addition
	clone.base_multiplier = base_multiplier
	clone.total_addition = total_addition
	clone.total_multiplier = total_multiplier
	return clone

func add(mod : PriceModification):
	if mod == null:
		return
	base_addition += mod.base_addition
	base_multiplier *= mod.base_multiplier
	total_addition += mod.total_addition
	total_multiplier *= mod.total_multiplier
	
func get_percent(p : float):
	var clone = duplicate()
	clone.base_addition = base_addition * p
	clone.base_multiplier = 1 + (base_multiplier - 1) * p
	clone.total_addition = total_addition * p
	clone.total_multiplier = 1 + (total_multiplier - 1) * p
	return clone
