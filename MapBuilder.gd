extends Node2D

# TODOS:
#
# - Keep track of total amount of each type, and weigh a type lower the closer it is to
#		'filling' (but never 0!)
#		- if a type is extremely low, chance to jump to higher entropy and build that type
# - Weigh higher the more neighbors match
# 		- Depending on types?
# - Some basic rules? i.e., shallows must border at least one sand, which must border at least one grass?
#		- gonna be pretty tricky. Should those rules just influence the weighting?
#		- lots of potential there for getting into an unsolvable state
# - Figure out how to not make the numbers I'm dealing with so freaking crazy high
#		- maybe limits on weights? So we can't get like 1x10^-30


export var size = 125
export var animate_render = true
export var render_speed = 100

var rng = RandomNumberGenerator.new()
var collapsible_tiles = {}
var type_totals = {}
var entropy_map = {}
var type_avg_fraction = {}
var num_built_since_last_yield = 0
var stop_build = false
var building = false
var prev_size = size

var ocean_at_edge = false
var ignore_tile_place = false

func get_render_speed():
	return 1.0 / (render_speed * 100)
	
func get_map_size():
	return floor(size / 2)

# Called when the node enters the scene tree for the first time.
func _ready():
	$"UI Layer/UI Root/PanelContainer/Map Panel/AnimateControls/GenSpeedSlider".value = render_speed
	$"UI Layer/UI Root/PanelContainer/Map Panel/AnimateControls/AnimateLabel".text = 'Animate Speed: ' + str(render_speed)
	$"UI Layer/UI Root/PanelContainer/Map Panel/SizeControls/SizeSlider".value = size
	$"UI Layer/UI Root/PanelContainer/Map Panel/SizeControls/SizeLabel".text = 'Size: ' + str(size)
	
	load_collapse_data()
	build_fake_maps()

func clear_map():
	$HexMap.clear()
	build_fake_maps()

func build_map():
	building = true
	# if we want to build oceans at the edge, do that now
	if ocean_at_edge:
		build_ocean_edges()
	
	# loop until all states have collapsed
	while not stop_build:
		# first, find the set of states with the lowest possible entropy level
		var next_tile_pos = find_next_tile()
		if next_tile_pos == null:
			stop_build = true
			break
		
		# choose a random state for that tile, and propgate that choice as much as we can
		collapse_propogate(next_tile_pos)
		if animate_render:
			if should_perform_animate_step():
				yield(get_tree().create_timer(get_render_speed()), "timeout")
	building = false
	
func collapse_propogate(tile_pos):
	if not tile_pos in collapsible_tiles:
		return
		
	var weights_by_type = get_weights_as_fraction_of_total()
		
	var starting_tile = collapsible_tiles[tile_pos]
	if starting_tile.collapsed:
		return
	
	starting_tile.collapse_full(weights_by_type)
	
	var tiles_to_check = []
	tiles_to_check.append_array(starting_tile.get_dirty_neighbors())
	
	while tiles_to_check.size() > 0:
		var next_tile = tiles_to_check.pop_front()
		if !next_tile.dirty:
			# sanity check
			continue
		
		next_tile.collapse(weights_by_type)
		if next_tile.collapsed:
			next_tile.collapse_full(weights_by_type)
		
		for neigh in next_tile.get_dirty_neighbors():
			if not neigh in tiles_to_check and not neigh.collapsed:
				tiles_to_check.append(neigh)
	
func build_fake_maps():
	for state in collapsible_tiles.values():
		state.clear()
			
	collapsible_tiles = {}
	entropy_map = {}
	for state in type_totals:
		type_totals[state] = 0
	var empty_tile = $HexMap.tile_set.find_tile_by_name('HexsetGridEmpty01')
	
	var actualSize = get_map_size()
	for x in range(-actualSize, actualSize):
		for y in range(-actualSize, actualSize):
			var key = Vector2(x, y)
			var new_tile = CollapsibleTile.new(key, rng)
			collapsible_tiles[key] = new_tile
			new_tile.connect('on_collapsed', self, '_on_collapse_single_tile')
			new_tile.connect('on_entropy_updated', self, '_on_entropy_updated')
			$HexMap.set_cellv(key, empty_tile)
	
	var weights_by_type = get_weights_as_fraction_of_total()
	for state in collapsible_tiles.values():
		state.set_neighbors(collapsible_tiles)
		state.calculate_entropy(weights_by_type)
		
	prev_size = size
		
		
## DATA LOAD / MANIPULATE ##
func load_collapse_data():	
	var weights = HexCollapseData.binary_data['weights']
	var total_weight = 0
	for state in weights:
		type_totals[state] = 0
		total_weight += weights[state]
		
	for state in weights:
		type_avg_fraction[state] = weights[state] * 1.0 / total_weight
		
func get_total_placed():
	var total = 0
	for t in type_totals.values():
		total += t
	return total
	
func get_weights_as_fraction_of_total():
	var total = get_total_placed()
	
	if total == 0:
		return type_avg_fraction
	
	var curr_frac_by_type = {}
	for state in type_totals:
		curr_frac_by_type[state] = (1.0 * type_totals[state]) / total
	
	var weights_by_fraction_diff = {}
	for state in curr_frac_by_type:
		var weight_diff = curr_frac_by_type[state] - type_avg_fraction[state]
		var weight = 1.0 / pow(3, weight_diff * 100) + 0.0001
		weights_by_fraction_diff[state] = weight
		
	return weights_by_fraction_diff
	
	
## BUILDING HELPERS ##
func build_ocean_edges():
	ignore_tile_place = true
	var weights_by_type = get_weights_as_fraction_of_total()
	var actualSize = get_map_size()
	for y in [-actualSize, actualSize - 1]:
		for x in range(-actualSize, actualSize):
			collapsible_tiles[Vector2(x, y)].collapse_to_specific_type("deep_flat")
	for x in [-actualSize, actualSize - 1]:
		for y in range(-actualSize, actualSize):
			collapsible_tiles[Vector2(x, y)].collapse_to_specific_type("deep_flat")
			
	ignore_tile_place = false
	for state in collapsible_tiles.values():
		if not state.collapsed:
			state.calculate_entropy(weights_by_type)
			
func find_next_tile():
	if entropy_map.size() == 0:
		return null
	
	var entropies = entropy_map.keys()
	entropies.sort()
	return entropy_map[entropies[0]].keys()[0]
	
func should_perform_animate_step():
	var speed = get_render_speed()
	# each tick is ~0.01 seconds, so if speed = 0.01, that's 1 tile placed
	# Simulate multiple
	var do_yield = true
	if speed < 0.01:
		var num_diff = round(0.01 / speed)
		if num_built_since_last_yield < num_diff:
			num_built_since_last_yield += 1
			do_yield = false
		else:
			num_built_since_last_yield = 0
	return do_yield
	
func update_land_perc(type, new_val, ui_name, ui_display):
	var node = get_node("UI Layer/UI Root/PanelContainer/Map Panel/Perc Panel/" + str(ui_name) + "/" + str(ui_name) + "Label")
	node.text = ui_display + ' - ' + str(new_val)


## SIGNAL CONNECTIONS ##
func _on_collapse_single_tile(tile_pos, tile_type):
	if not ignore_tile_place:
		type_totals[tile_type] += 1
	var tiles_for_type = HexCollapseData.binary_data["tiles_for_types"][tile_type]
	var spec_type = rng.randf_range(0, tiles_for_type.size())
	var tile_id = $HexMap.tile_set.find_tile_by_name(tiles_for_type[spec_type])
	$HexMap.set_cellv(tile_pos, tile_id)
#	collapsible_tiles[tile_pos].clear()
#	collapsible_tiles.erase(tile_pos)
	
func _on_entropy_updated(tile_pos, og_entropy, new_entropy):
	if og_entropy == new_entropy:
		return
	if og_entropy in entropy_map:
		entropy_map[og_entropy].erase(tile_pos)
		if entropy_map[og_entropy].size() == 0:
			entropy_map.erase(og_entropy)
	if new_entropy == -1:
		return
	if not new_entropy in entropy_map:
		entropy_map[new_entropy] = {}
	entropy_map[new_entropy][tile_pos] = null

func _on_GenMapButton_pressed():
	stop_build = true
	if building:
		yield(get_tree().create_timer(0.5), "timeout")
	clear_map()
	stop_build = false
	build_map()


func _on_GenSpeedSlider_value_changed(value):
	render_speed = value
	$"UI Layer/UI Root/PanelContainer/Map Panel/AnimateControls/AnimateLabel".text = 'Animate Speed: ' + str(value)


func _on_SizeSlider_value_changed(value):
	size = value
	$"UI Layer/UI Root/PanelContainer/Map Panel/SizeControls/SizeLabel".text = 'Size: ' + str(value)
	stop_build = true


func _on_LandType_value_changed(value, type, ui_name, ui_display):
	update_land_perc(type, value, ui_name, ui_display)
