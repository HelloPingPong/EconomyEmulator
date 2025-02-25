class_name PriceModifier

enum Types {
	ADD,
	MULTIPLY
}

enum StackingTypes {
	BASE,
	TOTAL
}

var item_name : String
var value : float
var type : int
var stacking : int
var percent : float

var result : PriceModification = PriceModification.new()

func _init(i = '', v = 1, t = Types.MULTIPLY, s = StackingTypes.TOTAL):
	item_name = i
	value = v
	type = t
	stacking = s
	result = _calculate_modifications()

func duplicate():
	var clone = get_script().new()
	
	clone.item_name = item_name
	clone.value = value
	clone.type = type
	clone.stacking = stacking
	
	return clone

func set_percent(p = 1.0):
	percent = p
	result = get_percent_modification(percent)
	
func get_percent_modification(percent : float):
	var res : PriceModification
	var alt_value : float = value
	if type == Types.ADD:
		alt_value *= percent
	
	if type == Types.MULTIPLY:
		alt_value = 1 + (alt_value - 1) * percent
		
	res = _calculate_modifications(alt_value)
	return res
		
func _calculate_modifications(alt_value = value):
	var res = PriceModification.new()
	
	if type == Types.ADD:
		if stacking == StackingTypes.BASE:
			res.base_addition = alt_value
			
		if stacking == StackingTypes.TOTAL:
			res.total_addition = alt_value
			
	if type == Types.MULTIPLY:
		if stacking == StackingTypes.BASE:
			res.base_multiplier = alt_value
			
		if stacking == StackingTypes.TOTAL:
			res.total_multiplier = alt_value
	
	return res
