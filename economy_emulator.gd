class_name EconomyEmulator
extends Node

var items : Dictionary = {}
var base_prices : Dictionary = {}

var groups : Dictionary = {}

var prices : Dictionary = {}

var actors : Dictionary = {}

var modifiers : Dictionary = {}
var events : Dictionary = {}

var active_modifiers : Dictionary = {}
var active_events : Dictionary = {}

var base_price_grow : float = 0.0
var base_price_drifts : Array = []

var price_phases_sync : bool = true
var price_phases : Dictionary = {}

var lazy_prices : bool = true

var money_precision : float = 0.01

var global_actor : EconomyActor = EconomyActor.new('global_actor')
var global_time : float = 0

func _init():
	actors['global_actor'] = global_actor

func add_actor(actor_name : String, parent_name = '', parent_bond = 1.0):
	
	if actors.has(actor_name):
		prints('duplicating actor: ', actor_name)
		return
		
	var parent = global_actor
		
	if actors.has(parent_name):
		parent = actors[parent_name]

	var actor = EconomyActor.new(actor_name, parent)
	
	actor.parent_bond = parent_bond
	
	actors[actor_name] = actor
	
	_propagate_items()
	_propagate_groups()
	_propagate_base_price_changes()
	
func remove_actor(actor_name : String):
	if !actors.has(actor_name):
		prints('no such actor: ', actor_name)
		return
		
	var actor : EconomyActor = actors[actor_name]
	var actor_parent : EconomyActor = actor.parent
	
	var act : EconomyActor
	for k in actors:
		act = actors[k]
		if act.aprent == actor:
			act.parent = actor_parent
			
	actors.erase(actor_name)
	
func add_group(group_name : String):
	groups[group_name] = []
	_propagate_groups()
	
func remove_group(group_name : String):
	groups.erase(group_name)
	_propagate_groups()
	
func add_item_to_group(item_name : String, group_name : String):
	if items.has(item_name) and groups.has(group_name):
		groups[group_name].append(item_name)
	_propagate_groups()
	
func remove_item_from_group(item_name : String, group_name : String):
	if items.has(item_name) and groups.has(group_name):
		groups[group_name].erase(item_name)
	_propagate_groups()
		
func _propagate_groups():
	var actor : EconomyActor
	for k in actors:
		actor = actors[k]
		actor.groups = groups.duplicate()

func add_item(name : String, base_price : float):
	items[name] = name
	base_prices[name] = base_price
	_propagate_items()
	
func remove_item(name : String):
	if base_prices.has(name):
		base_prices.erase(name)
		_propagate_items()
		
func _propagate_items():
	var actor : EconomyActor
	for k in actors:
		actor = actors[k]
		actor.base_prices = base_prices.duplicate()
	
func add_modifier(name : String, item_name : String, value : float, type = PriceModifier.Types.MULTIPLY, stacking = PriceModifier.StackingTypes.TOTAL):
	if modifiers.has(name):
		prints('duplicating modifier: ', name)
		return
		
	var mod = PriceModifier.new(item_name, value, type, stacking)
	modifiers[name] = mod
	
func remove_modifier(name : String):
	if modifiers.has(name):
		modifiers.erase(name)
	
func activate_modifier(name : String, actor_name = ''):
	if !modifiers.has(name):
		prints('no such modifier: ', name)
		return
		
	var actor = global_actor
		
	if actors.has(actor_name):
		actor = actors[actor_name]
		
	actor.modifiers.append(modifiers[name])
	
func deactivate_modifier(name, actor_name = ''):
	if !modifiers.has(name):
		prints('no such modifier: ', name)
		return
		
	var actor = global_actor
		
	if actors.has(actor_name):
		actor = actors[actor_name]
		
	actor.modifiers.erase(modifiers[name])
	
func add_event(name : String, modifier_name : String, start_time : float, duration : float, type = EconomyEvent.Types.WAVE):
	if events.has(name):
		prints('duplicating event: ', name)
		return
	
	if !modifiers.has(modifier_name):
		prints('no such modifier: ', modifier_name)
		return
		
	var modifier = modifiers[modifier_name]
	var event = EconomyEvent.new(name, modifier, start_time, duration, type)
	
	events[name] = event
	
func remove_event(name : String):
	if events.has(name):
		events.erase(name)
	
func activate_event(name : String, delay : float, actor_name = ''):
	if !events.has(name):
		prints('no such event: ', name)
		return
		
	var event : EconomyEvent = events[name].duplicate()
	var actor : EconomyActor = global_actor
	var start_time : float = global_time
		
	if actors.has(actor_name):
		actor = actors[actor_name]
	elif actor_name != '':
		prints('no such actor: ', name, 'event added to global actor')
		
	if delay > 0:
		start_time += delay
		
	event.set_start_time(start_time)
	
	actor.add_event(event)
	
func deactivate_event(name : String, actor_name = ''):
	if !events.has(name):
		prints('no such event: ', name)
		return
		
	var event : EconomyEvent = events[name]
	var actor : EconomyActor = global_actor
	
	if actors.has(actor_name):
		actor = actors[actor_name]
	elif actor_name != '':
		prints('no such actor: ', name, 'event removed from global actor')
		
	actor.remove_event(event)
	
func add_base_price_drift(percent : float, period : float):
	base_price_drifts.append({percent = percent, period = period})
	_propagate_base_price_changes()
	
func set_base_price_grow(amount : float):
	base_price_grow = amount
	_propagate_base_price_changes()
	
func set_money_precision(precision : float):
	money_precision = precision
	_propagate_base_price_changes()
	
func _propagate_base_price_changes():
	for k in actors:
		actors[k].base_price_grow = base_price_grow
		actors[k].money_precision = money_precision
		actors[k].base_price_drifts = base_price_drifts.duplicate()
	
func update_global_time(t : float):
	global_time = t
	if !lazy_prices:
		update_all_prices()
		
func update_all_prices():
	var actor : EconomyActor
	for k in actors:
		actor = actors[k]
		actor.update_global_time(global_time)
		actor.update_all_prices()
		
func get_price(item_name : String, time = global_time, actor_name = ''):
	if !items.has(item_name):
		prints('no such item', item_name)
	
	var actor : EconomyActor = global_actor
	
	if actors.has(actor_name):
		actor = actors[actor_name]
	elif actor_name != '':
		prints('no such actor: ', name)
		
	return actor.get_price(item_name, time)
