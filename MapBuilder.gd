extends Node2D


export var size = 125
export var animate_render = true
export var render_speed = 100

var rng = RandomNumberGenerator.new()
var collapsible_tiles = {}
var type_totals = {}
var entropy_map = {}
var dirty_entropy_tiles = {}
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
	# build_fake_maps()

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
		dirty_entropy_tiles[next_tile.key] = next_tile
		
		for neigh in next_tile.get_dirty_neighbors():
			if not neigh in tiles_to_check and not neigh.collapsed:
				tiles_to_check.append(neigh)
	
func build_fake_maps():
	for state in collapsible_tiles.values():
		state.clear()
			
	collapsible_tiles = {}
	dirty_entropy_tiles = {}
	entropy_map = {}
	entropy_map[100] = {}
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
			entropy_map[100][key] = null
			if $HexMap.get_cellv(key) != empty_tile:
				$HexMap.set_cellv(key, empty_tile)
	
	# Randomly select a tile as the start for more interesting generation
	var keys = collapsible_tiles.keys()
	var random_key = keys[rng.randf_range(0, keys.size())]
	collapsible_tiles[random_key].calculate_entropy(null, 99)
	
	for state in collapsible_tiles.values():
		state.set_neighbors(collapsible_tiles)
		
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
		
	var weights_by_type = get_weights_as_fraction_of_total()
	for tile in dirty_entropy_tiles.values():
		tile.calculate_entropy(weights_by_type)
	dirty_entropy_tiles = {}
	
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


## SIGNAL CONNECTIONS ##
func _on_collapse_single_tile(tile_pos, tile_type):
	if not ignore_tile_place:
		type_totals[tile_type] += 1
	var tiles_for_type = HexCollapseData.binary_data["tiles_for_types"][tile_type]
	var spec_type = rng.randf_range(0, tiles_for_type.size())
	var tile_id = $HexMap.tile_set.find_tile_by_name(tiles_for_type[spec_type])
	$HexMap.set_cellv(tile_pos, tile_id)
	
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
