extends TileMap


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

signal tile_clicked(tile_pos)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			var new_pos = get_viewport().canvas_transform.affine_inverse().xform(event.position)
			var map_pos = self.world_to_map(new_pos)
			emit_signal("tile_clicked", map_pos)
