extends Node2D


export var size = 125
export var pan_speed = 100
export var zoom_speed = 100

var noise = OpenSimplexNoise.new()
var offset = Vector2(0, 0)
var is_building = false

var rng = RandomNumberGenerator.new()
class CustomElevationSorter:
	static func sort_descending(a, b):
		return a > b

	
func get_map_size():
	return floor(size / 2)

# Called when the node enters the scene tree for the first time.
func _ready():
	# Configure
	noise.seed = randi()
	noise.period = 20.0
	noise.persistence = 0.8
	$"UI Layer/UI Root/PanelContainer/Map Panel/SeedControl/SeedSpinBox".value = noise.seed
	$"UI Layer/UI Root/PanelContainer/Map Panel/FrequencyControl/FrequencySlider".value = noise.period
	$"UI Layer/UI Root/PanelContainer/Map Panel/ScaleControl/ScaleSlider".value = noise.persistence
	# noise.octaves = 4
	# noise.persistence = 0.8
	build_map() # Replace with function body.

func build_map():
	is_building = true
	
	var actualSize = get_map_size()
	var elevation_map = HexCollapseData.type_rules["elevations"]
	var elevation_keys = elevation_map.keys()
	
	for x in range(-actualSize, actualSize):
		for y in range(-actualSize, actualSize):
			var noisePos = Vector2(x, y)
			var height = _get_height(noisePos, elevation_keys)
			var tile_type = elevation_map[height]
			$HexMap.set_cell(x, y, $HexMap.tile_set.find_tile_by_name(HexCollapseData.type_sets[tile_type][0]))
	is_building = false
	
func _get_height(actualPos, elevation_keys):
	var r_height = noise.get_noise_2dv(actualPos) * 100 * 1.5
	var idx = elevation_keys.bsearch(r_height) - 1
	return elevation_keys[idx] if idx >= 0 else elevation_keys[0]


func _on_BackButton_pressed():
	get_tree().change_scene("res://scenes/Main.tscn")


func _on_GenMapButton_pressed():
	noise.seed = randi()
	$"UI Layer/UI Root/PanelContainer/Map Panel/SeedControl/SeedSpinBox".value = noise.seed
	# $"UI Layer/UI Root/PanelContainer/Map Panel/SeedControl/SeedLabel".text = 'Seed: ' + str(noise.seed)
	build_map()


func _on_SeedSpinBox_value_changed(value):
	noise.seed = value
	if not is_building:
		build_map()


func _on_FrequencySlider_value_changed(value):
	noise.period = value
	if not is_building:
		build_map()


func _on_ScaleSlider_value_changed(value):
	noise.persistence = value
	if not is_building:
		build_map()
