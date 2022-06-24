extends Node2D

var binary_data = {
	"tiles_for_types": {},
	"weights": {},
	"neighbors": {},
	"back_map": {},
}

func _ready():
	build_binary_rep()
	
	
func build_binary_rep():
	for type in binary_map:
		var bin_val = binary_map[type]
		binary_data["tiles_for_types"][bin_val] = type_sets[type]
		binary_data["weights"][bin_val] = type_rules["weights"][type]
		var bin_neigh = 0
		for n_type in type_rules["neighbors"][type]:
			bin_neigh = bin_neigh | binary_map[n_type]
		binary_data["neighbors"][bin_val] = bin_neigh
		binary_data["back_map"][bin_val] = type
		
func get_biome(e, m):
	if e < 0.45:
		return "deep_flat"
	if e < 0.5:
		return "shallow_flat"
		
	var biome = ""
	var height = ""
		
	if e > 0.85:
		if m < 0.05: 
			return "stone_mont"
		if m < 0.2:
			return "desert_mont"
		if m < 0.3:
			return "warm_mont"
		if m < 0.5:
			return "boreal_mont"
		if m < 0.6:
			return "temperate_mont"
		return "snow_mont"
	
	if e > 0.7:
		if m < 0.15:
			return "desert_hill"
		if m < 0.35:
			return "warm_hill"
		if m < 0.7:
			return "boreal_hill"
		if m < 0.95:
			return "temperate_hill"
		return "swamp_hill"
		
	if m < 0.15:
		return "desert_flat"
	if m < 0.4:
		return "warm_flat"
	if m < 0.7:
		return "boreal_flat"
	if m < 0.93:
		return "temperate_flat"
	return "swamp_flat"
		
	

var type_sets = {
	"boreal_flat": [
		"HexsetGridBorealFlat01",
		"HexsetGridBorealFlat02",
		"HexsetGridBorealFlat03",
	],
	"boreal_hill": [
		"HexsetGridBorealHill01",
		"HexsetGridBorealHill02",
		"HexsetGridBorealHill03",
	],
	"boreal_mont": [
		"HexsetGridBorealMont01",
		"HexsetGridBorealMont02",
		"HexsetGridBorealMont03",
	],
	"shallow_flat": [
		"HexsetGridWshallowFlat01",
		"HexsetGridWshallowFlat02",
		"HexsetGridWshallowFlat03",
	],
	"deep_flat": [
		"HexsetGridWdeepFlat01",
		"HexsetGridWdeepFlat02",
		"HexsetGridWdeepFlat03",
	],
	"boreal_tree": [
		"HexsetGridBorealTree01",
	],
	"desert_flat": [
		"HexsetGridDesertFlat01",
		"HexsetGridDesertFlat02",
		"HexsetGridDesertFlat03",
	],
	"desert_hill": ["HexsetGridDesertHill01"],
	"desert_mont": ["HexsetGridDesertMont01"],
	"stone_mont": ["HexsetGridStoneMont01"],
	"warm_flat": ["HexsetGridWarmFlat01"],
	"warm_hill": ["HexsetGridWarmHill01"],
	"warm_mont": ["HexsetGridWarmMont01"],
	"temperate_flat": ["HexsetGridTemperateFlat01"],
	"temperate_hill": ["HexsetGridTemperateHill01"],
	"temperate_mont": ["HexsetGridTemperateMont01"],
	"snow_mont": ["HexsetGridSnowMont01"],
	"swamp_flat": ["HexsetGridSwampFlat01"],
	"swamp_hill": ["HexsetGridSwampHill01"],
#	"stone_flat": [
#		"HexsetGridStoneFlat01",
#	],
}

var type_rules = {
	"weights": {
		"boreal_flat": 35,
		"boreal_hill": 5,
		"boreal_mont": 3,
		"shallow_flat": 15,
		"boreal_tree": 12,
		"desert_flat": 5,
		"deep_flat": 25,
#		"stone_flat": 1,
	},
	"neighbors": {
		"boreal_flat": [
			"boreal_flat", 
			"boreal_hill", 
			"shallow_flat", 
			"boreal_tree",
			"desert_flat",
		],
		"boreal_hill": [
			"boreal_flat", 
			"boreal_hill", 
			"boreal_mont", 
			"boreal_tree",
		],
		"boreal_mont": [
			"boreal_hill", 
			"boreal_mont",
			"boreal_flat",
		],
		"shallow_flat": [
			"boreal_flat", 
			"shallow_flat",
			# "desert_flat",
			"deep_flat",
			"boreal_tree",
		],
		"boreal_tree": [
			"boreal_flat", 
			"boreal_tree",
			"boreal_hill",
			"shallow_flat",
		],
		"desert_flat": [
			"desert_flat",
			"boreal_flat",
		],
		"deep_flat": [
			"deep_flat",
			"shallow_flat",
		],
	},
}

var binary_map = {
	"boreal_flat": 1,
	"boreal_hill": 2,
	"boreal_mont": 4,
	"shallow_flat": 8,
	"boreal_tree": 16,
	"desert_flat": 32,
	"deep_flat": 64,
}
