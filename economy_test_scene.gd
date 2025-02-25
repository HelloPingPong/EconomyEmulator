extends Control

var h_scale = 0
var v_scale = 0

var economy = EconomyEmulator.new()

var v_size = 200
var h_size = 400

var time_step = 0.3
var global_time = 0

var item_names = {
	APPLE = 'apple',
	BANANA = 'banana'
}

var prices = {
	item_names.APPLE : 2,
	item_names.BANANA : 3,
}

var prices_history = {
	
}

var max_price = 0
var min_price = 0

var time_boundary = 30

var economy_actor : EconomyActor

func _ready():
	
	randomize()

	_update_actors_ui()
	_update_modifiers_ui()
	_update_events_ui()
	
#	test_modifiers()
#	test_events()


func _on_Timer_timeout():
#	for i in 40:
	
	global_time += time_step
	economy.update_global_time(global_time)

	for act in economy.actors:
		
		prices_history[act] = {}

		for k in economy.items:
			prices_history[act][k] = []
			
			min_price = 0
			max_price = 0
			
			for i in range(-time_boundary, time_boundary, 1):
				var price = economy.get_price(k, global_time + i*time_step, act)
				if price > max_price:
					max_price = price
				if min_price > price:
					min_price = price
					
				prices_history[act][k].append(price)
	
	
	plot_lines()
	update_grid_prices()
	
func update_grid_prices():
	var grid = $HSplitContainer/TabContainer/GridContainer
	
	grid.clear()
	
	var columns = economy.actors.keys().size() + 1
	
	grid.push_table(columns)
	
	grid.push_cell()
	grid.add_text('*')
	grid.pop()
	
	for key in economy.actors: # Add table headers
		grid.push_cell()
		grid.add_text(key)
		grid.pop()
	
	for k in economy.items:
		grid.push_cell()
		grid.add_text(k)
		grid.pop()
		for act in economy.actors: # Add table values
			grid.push_cell()
			var price = economy.get_price(k, global_time, act)
			grid.add_text(String(price))
			grid.pop()
	grid.pop()
	
#
#	for act in economy.actors:
#		grid.add_item(act)
#		columns += 1
#		for k in economy.items:
#			var price = economy.get_price(k, global_time, act)
#			grid.add_item(String(price))
#	grid.max_columns = columns
			
	
func plot_lines():
	var chart = $HSplitContainer/TabContainer/lines
	for c in chart.get_children():
		c.queue_free()
	
	h_size = chart.get_global_rect().size.x
	v_size = chart.get_global_rect().size.y
	
	
	var price_range = (max_price - min_price) * 1.5
	if price_range == 0:
		return
	h_scale = h_size / (time_boundary * 2)
	v_scale = v_size / price_range
	
	var chart_pos = chart.rect_position.y
	
	for act in economy.actors:
		for k in economy.items:
			var line = Line2D.new()
			line.width = 2
			line.modulate = Color().from_hsv(randf(), 0.9, 0.8)
			
			var point_y = 0
			
			for i in time_boundary * 2:
				var point = Vector2()
				var price = prices_history[act][k][i]
				point.x = h_scale * i
				point.y = v_size  - price * v_scale
				point_y = point.y
				line.add_point(point)
			chart.add_child(line)
		
func _on_add_item_pressed():
	var item_name_input = $HSplitContainer/VBoxContainer/TabContainer/items/setup/item_name
	var item_price_input = $HSplitContainer/VBoxContainer/TabContainer/items/setup/item_price
	var group_select = $HSplitContainer/VBoxContainer/TabContainer/items/setup/group_select
	
	var group_name = group_select.get_item_text(group_select.get_selected_id())
	
	var item_name = item_name_input.text
	var item_price = float(item_price_input.text)
	
	economy.add_item(item_name, item_price)
	
	if !group_name.empty():
		economy.add_item_to_group(item_name, group_name)
	
	_update_items_ui()
	
	item_name_input.text = ''
	item_price_input.text = ''
	
func _on_add_group_pressed():
	var group_name_input = $HSplitContainer/VBoxContainer/TabContainer/groups/setup/group_name
	
	var group_name = group_name_input.text
	
	if !group_name.empty():
		economy.add_group(group_name)
		
	group_name_input.clear()
	
	_update_groups_ui()
	_update_items_ui()

func _on_add_actor_pressed():
	var actor_name_input = $HSplitContainer/VBoxContainer/TabContainer/actors/setup/LineEdit
	var parent_select = $HSplitContainer/VBoxContainer/TabContainer/actors/setup/parent
	var parent_bond_input = $HSplitContainer/VBoxContainer/TabContainer/actors/setup/parent_bond
	
	var parent_bond = parent_bond_input.text
	var actor_name = actor_name_input.text
	var actor_parent = parent_select.get_item_text(parent_select.get_selected_id())
	
	if parent_bond.empty():
		economy.add_actor(actor_name, actor_parent)
	else:
		economy.add_actor(actor_name, actor_parent, float(parent_bond))
	
	
	actor_name_input.clear()
	_update_actors_ui()
	
func _on_add_modifier_pressed():
	var mod_type_select = $HSplitContainer/VBoxContainer/TabContainer/modifiers/setup/mod_type
	var mod_stacking_select = $HSplitContainer/VBoxContainer/TabContainer/modifiers/setup/mod_stacking
	var mod_name_input = $HSplitContainer/VBoxContainer/TabContainer/modifiers/setup/mod_name
	var mod_value_input = $HSplitContainer/VBoxContainer/TabContainer/modifiers/setup/mod_value
	var item_name_select = $HSplitContainer/VBoxContainer/TabContainer/modifiers/setup/OptionButton
	
	var item_name = item_name_select.text
	var mod_name = mod_name_input.text
	var mod_value = float(mod_value_input.text)
	var mod_type = PriceModifier.Types[mod_type_select.get_item_text(mod_type_select.get_selected_id())]
	var mod_stacking = PriceModifier.StackingTypes[mod_stacking_select.get_item_text(mod_stacking_select.get_selected_id())]
	
	economy.add_modifier(mod_name, item_name, mod_value, mod_type, mod_stacking)
	
	_update_modifiers_list()
	mod_name_input.clear()
	mod_value_input.clear()
	
func _on_activate_modifier_pressed():
	var mod_list = $HSplitContainer/VBoxContainer/TabContainer/modifiers/mod_list
	var modifier_activation_actor = $HSplitContainer/VBoxContainer/TabContainer/modifiers/modifiers_control/actor
	var actor_name = modifier_activation_actor.get_item_text(modifier_activation_actor.get_selected_id())
	
	var selected_items = mod_list.get_selected_items()
	
	for i in selected_items:
		var mod_name = mod_list.get_item_text(i)
		economy.activate_modifier(mod_name, actor_name)
	
func _on_add_event_pressed():
	
	var interpolation_select = $HSplitContainer/VBoxContainer/TabContainer/events/setup/interpolation
	var event_name_input = $HSplitContainer/VBoxContainer/TabContainer/events/setup/event_name
	var mod_select = $HSplitContainer/VBoxContainer/TabContainer/events/setup/modifier
	
	var delay_input = $HSplitContainer/VBoxContainer/TabContainer/events/setup/delay
	var duration_input = $HSplitContainer/VBoxContainer/TabContainer/events/setup/duration
	
	var event_name = event_name_input.text
	var mod_name = mod_select.get_item_text(mod_select.get_selected_id())
	var interpolation = EconomyEvent.Types[interpolation_select.get_item_text(interpolation_select.get_selected_id())]
	var delay = float(delay_input.text)
	var duration = float(duration_input.text)
	
	economy.add_event(event_name, mod_name, 0, duration, interpolation)
#	economy.activate_event(event_name, delay)
	
	_update_events_ui()
	
func _on_activate_event_pressed():
	var event_list = $HSplitContainer/VBoxContainer/TabContainer/events/events_list
	var delay_input = $HSplitContainer/VBoxContainer/TabContainer/events/event_control/event_delay
	var event_activation_actor = $HSplitContainer/VBoxContainer/TabContainer/events/event_control/actor
	var actor_name = event_activation_actor.get_item_text(event_activation_actor.get_selected_id())
	
	var selected_items = event_list.get_selected_items()
	var delay = 0
	
	if !delay_input.text.empty():
		delay = float(delay_input.text)
	
	for i in selected_items:
		var event_name = event_list.get_item_text(i)
		economy.activate_event(event_name, delay, actor_name)
	
	
func _update_events_ui():
	var interpolation_select = $HSplitContainer/VBoxContainer/TabContainer/events/setup/interpolation
	var event_list = $HSplitContainer/VBoxContainer/TabContainer/events/events_list
	
	interpolation_select.clear()
	event_list.clear()
	
	for k in EconomyEvent.Types:
		interpolation_select.add_item(k)
	
	for k in economy.events:
		event_list.add_item(k)
	
func _update_actors_ui():
	var actor_parent_opt = $HSplitContainer/VBoxContainer/TabContainer/actors/setup/parent
	var event_activation_actor = $HSplitContainer/VBoxContainer/TabContainer/events/event_control/actor
	var modifier_activation_actor = $HSplitContainer/VBoxContainer/TabContainer/modifiers/modifiers_control/actor
	var actors_list = $HSplitContainer/VBoxContainer/TabContainer/actors/actors_list
	var parent_bond_input = $HSplitContainer/VBoxContainer/TabContainer/actors/setup/parent_bond
	
	actor_parent_opt.clear()
	event_activation_actor.clear()
	modifier_activation_actor.clear()
	actors_list.clear()
	parent_bond_input.clear()
	
	for k in economy.actors:
		actor_parent_opt.add_item(k)
		event_activation_actor.add_item(k)
		modifier_activation_actor.add_item(k)
		var parent = economy.actors[k].parent
		var parent_name = '_'
		if parent != null:
			parent_name = parent.name
		actors_list.add_item(k + ' (' + parent_name + ')')
		
	actors_list.minimum_size_changed()
	
func _update_groups_ui():
	var group_list = $HSplitContainer/VBoxContainer/TabContainer/groups/group_list
	var group_select = $HSplitContainer/VBoxContainer/TabContainer/items/setup/group_select
	
	
		
	group_list.clear()
	group_select.clear()
	
	group_select.add_item('')
	
	for k in economy.groups:
		group_list.add_item(k)
		group_select.add_item(k)
			
func _update_items_ui():
	var opt_btn = $HSplitContainer/VBoxContainer/TabContainer/modifiers/setup/OptionButton
	var item_list = $HSplitContainer/VBoxContainer/TabContainer/items/items_list
	
	opt_btn.clear()
	item_list.clear()
	
	opt_btn.add_item('')
	
	for k in economy.items:
		opt_btn.add_item(k)
		item_list.add_item(k + ' ' + String(economy.base_prices[k]))
		
	opt_btn.add_separator()
		
	for k in economy.groups:
		opt_btn.add_item(k)
		
func _update_modifiers_ui():
	var mod_type_select = $HSplitContainer/VBoxContainer/TabContainer/modifiers/setup/mod_type
	var mod_stacking_select = $HSplitContainer/VBoxContainer/TabContainer/modifiers/setup/mod_stacking

	mod_type_select.clear()
	mod_stacking_select.clear()

	for k in PriceModifier.Types:
		mod_type_select.add_item(k)
		
	for k in PriceModifier.StackingTypes:
		mod_stacking_select.add_item(k)

func _update_modifiers_list():
	var mod_select = $HSplitContainer/VBoxContainer/TabContainer/events/setup/modifier
	var mod_list = $HSplitContainer/VBoxContainer/TabContainer/modifiers/mod_list
	
	mod_select.clear()
	mod_list.clear()
	
	for k in economy.modifiers:
		mod_select.add_item(k)
		mod_list.add_item(k)

func test_modifiers():
	economy.add_actor('city')
	economy.add_actor('merchant', 'city')
	
	economy.add_item('apple', 20)
	economy.add_item('banana', 30)
	
	economy.add_group('food')
	
	economy.add_item_to_group('apple', 'food')
	economy.add_item_to_group('banana', 'food')
	
	economy.add_modifier('mod_apple', 'apple', 3, PriceModifier.Types.ADD, PriceModifier.StackingTypes.BASE)
	economy.add_modifier('mod_food', 'food', 2, PriceModifier.Types.MULTIPLY, PriceModifier.StackingTypes.BASE)
	economy.add_modifier('greedy_merchant', 'banana', 2, PriceModifier.Types.MULTIPLY, PriceModifier.StackingTypes.BASE)
	
	economy.activate_modifier('mod_apple')
	economy.activate_modifier('mod_food', 'city')
	economy.activate_modifier('greedy_merchant', 'merchant')
	
	prints(economy.get_price('apple', 0))
	prints(economy.get_price('apple', 0, 'city'))
	prints(economy.get_price('apple', 0, 'merchant'))
	
	prints(economy.get_price('banana', 0))
	prints(economy.get_price('banana', 0, 'city'))
	prints(economy.get_price('banana', 0, 'merchant'))

func test_events():
	economy.add_actor('city_one')
	economy.add_actor('city_two')
	economy.add_actor('merchant_one', 'city_one')
	economy.add_actor('merchant_two', 'city_two')
	
	economy.add_item('apple', 20)
	economy.add_item('banana', 30)
	economy.add_item('sword', 50)
	
	economy.add_group('food')
	
	economy.add_item_to_group('apple', 'food')
	economy.add_item_to_group('banana', 'food')
	
	economy.add_modifier('drought_modifier', 'food', 3, PriceModifier.Types.MULTIPLY, PriceModifier.StackingTypes.BASE)
	
	economy.add_event('drought_event', 'drought_modifier', 0, 10, EconomyEvent.Types.WAVE)
	
	economy.activate_event('drought_event', 0, 'city_one')
	
	prints(economy.get_price('apple', 0, 'merchant_one'))
	prints(economy.get_price('apple', 2, 'merchant_one'))
	prints(economy.get_price('apple', 5, 'merchant_one'))
	prints(economy.get_price('apple', 8, 'merchant_one'))
	prints(economy.get_price('apple', 10, 'merchant_one'))
	
	prints(economy.get_price('sword', 0, 'merchant_one'))
	prints(economy.get_price('sword', 5, 'merchant_one'))
	prints(economy.get_price('sword', 10, 'merchant_one'))
	
	prints(economy.get_price('apple', 0, 'merchant_two'))
	prints(economy.get_price('apple', 2, 'merchant_two'))
	prints(economy.get_price('apple', 5, 'merchant_two'))
	prints(economy.get_price('apple', 8, 'merchant_two'))
	prints(economy.get_price('apple', 10, 'merchant_two'))
	

func _on_set_price_grow_pressed():
	var price_grow_input = $HSplitContainer/VBoxContainer/TabContainer/globals/price_grow/grow_amount
	
	if price_grow_input.text.empty():
		return
		
	economy.set_base_price_grow(float(price_grow_input.text))
		

func _on_add_price_drift_pressed():
	var drift_percent_input = $HSplitContainer/VBoxContainer/TabContainer/globals/price_drifts/percent
	var drift_period_input = $HSplitContainer/VBoxContainer/TabContainer/globals/price_drifts/period
	
	if drift_percent_input.text.empty() or drift_period_input.text.empty():
		return
		
	economy.add_base_price_drift(float(drift_percent_input.text), float(drift_period_input.text))

