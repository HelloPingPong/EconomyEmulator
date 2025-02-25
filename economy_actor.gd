class_name EconomyActor

var base_prices : Dictionary
var groups : Dictionary

var name : String

var modifiers : Array = []
var events : Array = []

var actual_prices : Dictionary = {}

var parent : EconomyActor

var global_time setget update_global_time

var time_distance : float = 0
var parent_bond : float = 0.8

var base_price_grow : float = 0.0
var base_price_drifts : Array = []
var money_precision : float = 0.01

func _init(n : String, p = null):
	name = n
	parent = p
	
func _get_base_price(item_name: String, time : float) -> float:
	
	if !base_prices.has(item_name):
		prints('price not found', item_name)
		return -1.0
	
	var base_price : float = base_prices[item_name]
	var final_price : float = base_price
	
	if base_price_grow > 0:
		final_price += time * base_price_grow
		
	if base_price_drifts.size() > 0:
		for drift in base_price_drifts:
			var phase = fmod(time, drift.period) / drift.period
			var price_change = base_price * drift.percent * sin(phase * TAU)
			final_price += price_change
			
	return final_price
	
func update_global_time(t):
	global_time = t
	cleanup_outdated_events()
	return global_time
	
func cleanup_outdated_events():
	var events_amount = events.size()
	var event : EconomyEvent
	
	for i in events_amount:
		event = events[events_amount - i - 1]
		if event._end_time < global_time:
			events.erase(event)
	
func add_items(items_dict : Dictionary):
	for key in items_dict.keys():
		add_item(key, items_dict[key])

func add_item(name : String, price : float):
	base_prices[name] = price
	
func remove_item(name : String):
	base_prices.erase(name)
	
func add_modifier(m : PriceModifier):
	modifiers.append(m)

func remove_modifier(m : PriceModifier):
	modifiers.erase(m)
	
func add_event(e : EconomyEvent):
	events.append(e)
	
func remove_event(e : EconomyEvent):
	var events_amount : int = events.size()
	var event : EconomyEvent
	for i in events_amount:
		event = events[events_amount - i - 1]
		if event.name == e.name:
			events.erase(event)

func get_base_price(name : String):
	if base_prices.has(name):
		return base_prices[name]
	else: 
		return null

func get_price(item_name : String, time = global_time):
	
	if !base_prices.has(item_name):
		return null
		
	var parent_modifications = _get_parents_modifications_recursive(item_name, time)
	
	var own_modifications = get_modifications(item_name, time)
	
	var base_price = _get_base_price(item_name, time)
	
	var total_modification : PriceModification = PriceModification.new()
	
	total_modification.add(parent_modifications)
	total_modification.add(own_modifications)
			
	var result_price = (base_price * total_modification.base_multiplier + total_modification.base_addition) * total_modification.total_multiplier + total_modification.total_addition
			
	return stepify(result_price, money_precision)

func update_all_prices():
	for k in base_prices:
		actual_prices[k] = get_price(k, global_time)
		
func get_modifications(item_name : String, time : float):
	var total_modifications = PriceModification.new()
	
	for m in modifiers:
		if m.item_name == item_name or m.item_name.empty():
			total_modifications.add(m.get_percent_modification(1))
		elif groups.has(m.item_name) and groups[m.item_name].has(item_name):
			total_modifications.add(m.get_percent_modification(1))
			
	for e in events:
		if e.modifier.item_name == item_name or e.modifier.item_name.empty():
			total_modifications.add(e.get_price_modification(time))
		elif groups.has(e.modifier.item_name) and groups[e.modifier.item_name].has(item_name):
			total_modifications.add(e.get_price_modification(time))
			
	return total_modifications

func _get_parents_modifications_recursive(item_name : String, time : float):
	var p : EconomyActor = parent
	var p_bond : float = parent_bond
	
	var total_modifications : PriceModification = PriceModification.new()
	
	var max_depth = 100
	
	while p != null and max_depth > 0:
		
		max_depth -= 1
		
		total_modifications.add(p.get_modifications(item_name, time).get_percent(p_bond))
		
		p_bond *= p.parent_bond
		p = p.parent
			
	return total_modifications


