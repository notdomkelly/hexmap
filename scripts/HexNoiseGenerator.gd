extends Node2D


export var size = 125
var actual_size
var edge_buffer = 10
export var pan_speed = 100
export var zoom_speed = 100

var elevation_noise = OpenSimplexNoise.new()
var moisture_noise = OpenSimplexNoise.new()
var offset = Vector2(0, 0)
var is_building = false

var falloff_types = ['None', 'Circle', 'Rectangle']
var curr_falloff_type = 0

var rng = RandomNumberGenerator.new()
class CustomElevationSorter:
	static func sort_descending(a, b):
		return a > b

	
func get_map_size():
	return floor(size / 2)

# Called when the node enters the scene tree for the first time.
func _ready():
	for x in falloff_types:
		$"UI Layer/UI Root/PanelContainer/Map Panel/FalloffControl/FalloffType".add_item(x)
	$"UI Layer/UI Root/PanelContainer/Map Panel/FalloffControl/FalloffType".select(curr_falloff_type)
	actual_size = get_map_size()
	# Configure
	elevation_noise.seed = randi()
	elevation_noise.period = 20.0
	elevation_noise.persistence = 0.8
	$"UI Layer/UI Root/PanelContainer/Map Panel/SeedControl/SeedSpinBox".value = elevation_noise.seed
	$"UI Layer/UI Root/PanelContainer/Map Panel/FrequencyControl/FrequencySlider".value = elevation_noise.period
	$"UI Layer/UI Root/PanelContainer/Map Panel/ScaleControl/ScaleSlider".value = elevation_noise.persistence
	moisture_noise.seed = randi()
	moisture_noise.period = 20.0
	moisture_noise.persistence = 0.8
	# elevation_noise.octaves = 4
	# elevation_noise.persistence = 0.8
	build_map() # Replace with function body.

func build_map(random_m = true):
	is_building = true
	if random_m:
		moisture_noise.seed = randi()
	
	for x in range(-actual_size, actual_size):
		for y in range(-actual_size, actual_size):
			var noisePos = Vector2(x, y)
			
			var elevation = (elevation_noise.get_noise_2dv(noisePos) * 1.5 + 1.0) / 2.0
			var moisture = (moisture_noise.get_noise_2dv(noisePos) * 1.5 + 1.0) / 2.0
			
			elevation = get_falloff_elevation(elevation, noisePos)
			
			var tile_type = HexCollapseData.get_biome(elevation, moisture)
			$HexMap.set_cell(x, y, $HexMap.tile_set.find_tile_by_name(HexCollapseData.type_sets[tile_type][0]))
	is_building = false
	
	
func get_falloff_elevation(elevation, pos):
	if curr_falloff_type == 1:
		var dist_from_edge = actual_size - pos.distance_to(Vector2(0, 0))
		if dist_from_edge < edge_buffer:
			elevation = elevation * (elevation + dist_from_edge / 100)
	elif curr_falloff_type == 2:
		if actual_size - abs(pos.x) < edge_buffer:
			var dist_from_edge = actual_size - abs(pos.x)
			elevation = elevation * (elevation + dist_from_edge / 100)
		elif actual_size - abs(pos.y) < edge_buffer:
			var dist_from_edge = actual_size - abs(pos.y)
			elevation = elevation * (elevation + dist_from_edge / 100)
			
	return elevation


func _on_BackButton_pressed():
	get_tree().change_scene("res://scenes/Main.tscn")


func _on_GenMapButton_pressed():
	elevation_noise.seed = randi()
	$"UI Layer/UI Root/PanelContainer/Map Panel/SeedControl/SeedSpinBox".value = elevation_noise.seed
	# $"UI Layer/UI Root/PanelContainer/Map Panel/SeedControl/SeedLabel".text = 'Seed: ' + str(elevation_noise.seed)
	build_map()


func _on_SeedSpinBox_value_changed(value):
	elevation_noise.seed = value
	if not is_building:
		build_map()


func _on_FrequencySlider_value_changed(value):
	elevation_noise.period = value
	moisture_noise.period = value
	if not is_building:
		build_map(false)


func _on_ScaleSlider_value_changed(value):
	elevation_noise.persistence = value
	moisture_noise.persistence = value
	if not is_building:
		build_map(false)


func _on_FalloffType_item_selected(index):
	curr_falloff_type = index
	if not is_building:
		build_map(false)
