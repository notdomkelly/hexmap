
	
#func update_representation():
#	if !map_repr:
#		return
#
#	self.map_repr.clear()
#
#	if self.collapsed_get():
#		return
#
#	var idx = 0
#	for state in self.possible_states:
#		self.map_repr.set_cell(idx, 0, self.map_repr.tile_set.find_tile_by_name(self.type_sets[state][0]))
#		idx += 1



#func create_representation(tile_set=null, position=null):
#	self.possible_states_set(self.type_sets.keys())
#	return false
#	if !self.map_repr:
#		self.map_repr = TileMap.new()
#		self.map_repr.tile_set = tile_set
#		self.map_repr.centered_textures = true
#		self.map_repr.cell_size = Vector2(5, 15)
#		self.map_repr.cell_y_sort = true
#		self.map_repr.scale = Vector2(0.4, 0.4)
#		self.map_repr.position = position
#		self.possible_states_set(self.type_sets.keys())
#		return true
#	self.possible_states_set(self.type_sets.keys())
#	return false


	
#func reset():
#	self.dirty = false
#	self.is_full_collapsing = false
#	self.possible_states_set(self.type_sets.keys())
#	self.entropy = 100



#
#func _on_HexMap_tile_clicked(tile_pos):
#	return
#	if $HexMap.get_cellv(tile_pos) == -1:
#		self.collapse_propogate(tile_pos)
