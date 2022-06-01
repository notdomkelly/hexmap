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
	

var type_sets = {
	"boreal_flat": [
		"HexsetGridBorealFlat01"
	],
	"boreal_hill": [
		"HexsetGridBorealHill01"
	],
	"boreal_mont": [
		"HexsetGridBorealMont01"
	],
	"shallow_flat": [
		"HexsetGridWshallowFlat01"
	],
	"deep_flat": [
		"HexsetGridWdeepFlat01",
	],
	"boreal_tree": [
		"HexsetGridBorealTree01"
	],
	"desert_flat": [
		"HexsetGridDesertFlat01"
	],
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
			# "shallow_flat",
		],
		"deep_flat": [
			"deep_flat",
			"shallow_flat",
		],
#		"stone_flat": [
#			"stone_flat",
#			"boreal_flat",
#		],
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
