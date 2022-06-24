extends Node2D


export var size = 125
export var pan_speed = 100
export var zoom_speed = 100

var elevation_noise = OpenSimplexNoise.new()
var moisture_noise = OpenSimplexNoise.new()
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
	
	var actualSize = get_map_size()
	
	var min_e = 100
	var max_e = 0
	
	for x in range(-actualSize, actualSize):
		for y in range(-actualSize, actualSize):
			var noisePos = Vector2(x, y)
			var elevation = (elevation_noise.get_noise_2dv(noisePos) * 1.5 + 1.0) / 2.0
			var moisture = (moisture_noise.get_noise_2dv(noisePos) * 1.5 + 1.0) / 2.0
			if elevation < min_e:
				min_e = elevation
			if elevation > max_e:
				max_e = elevation
			# var height = _get_height(noisePos, elevation_keys)
			# var tile_type = elevation_map[height]
			var tile_type = HexCollapseData.get_biome(elevation, moisture)
			$HexMap.set_cell(x, y, $HexMap.tile_set.find_tile_by_name(HexCollapseData.type_sets[tile_type][0]))
	print(min_e)
	print(max_e)
	is_building = false
	
#func _get_height(actualPos, elevation_keys):
#	var r_height = elevation_noise.get_noise_2dv(actualPos) * 100 * 1.5
#	var idx = elevation_keys.bsearch(r_height) - 1
#	return elevation_keys[idx] if idx >= 0 else elevation_keys[0]


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
