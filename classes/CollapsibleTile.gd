extends Reference

class_name CollapsibleTile

signal on_collapsed(tile_pos, tile_type)
signal on_entropy_updated(tile_pos, old_entropy, new_entropy)

const DIRECTIONS = {
	EVEN = {
		E = Vector2(1, 0),
		NE = Vector2(0, -1),
		NW = Vector2(-1, -1),
		W = Vector2(-1, 0),
		SW = Vector2(-1, 1),
		SE = Vector2(0, 1),
	},
	ODD = {
		E = Vector2(1, 0),
		NE = Vector2(1, -1),
		NW = Vector2(0, -1),
		W = Vector2(-1, 0),
		SW = Vector2(0, 1),
		SE = Vector2(1, 1),
	},
}

var key: Vector2
var possible_states = 0 setget _possible_states_set
var allowed_neighbor_states = 0
var collapsed setget , collapsed_get
func collapsed_get():
	return possible_states && !(possible_states & (possible_states-1))
	
var map_repr = null
var neighbors = {}
var collapsed_neighbor_types = []
var dirty = false
var rng = null
var entropy = 100


func _init(_key, _rng):
	self.key = _key
	self.rng = _rng
	var new_state_bin = 0
	for state in HexCollapseData.binary_data["tiles_for_types"].keys():
		new_state_bin |= state
	self._possible_states_set(new_state_bin)
	
func clear():
	self.neighbors.clear()
			
func mark_dirty():
	self.dirty = true if not self.collapsed else false
	
func calculate_entropy(weights_by_type):
	var og_entropy = self.entropy
	if self.collapsed:
		self.entropy = -1
	else:
		var weight_sum = 0
		var weight_sum_log = 0
		var weights = self._get_weights()
		for state in weights:
			if state & self.possible_states == state:
				var w = weights[state] * weights_by_type[state]
				weight_sum += w
				weight_sum_log += (w * log(w))
		self.entropy = log(weight_sum) - (weight_sum_log / weight_sum)
		for neighbor in self.neighbors.values():
			if neighbor.collapsed:
				self.entropy = self.entropy / 10
		
	if og_entropy != self.entropy:
		emit_signal("on_entropy_updated", self.key, og_entropy, self.entropy)

func set_neighbors(tile_map):
	var parity = int(self.key.y) % 2
	var dir_set = DIRECTIONS.EVEN if parity == 0 else DIRECTIONS.ODD
	for dir in dir_set:
		var neighbor_key = self.key + dir_set[dir]
		if tile_map.has(neighbor_key):
			self.neighbors[dir] = tile_map[neighbor_key]
	
func get_dirty_neighbors():
	var ret = []
	for neighbor in self.neighbors.values():
		if neighbor.dirty and not neighbor.collapsed:
			ret.push_back(neighbor)
	
	return ret
	
func collapse(weights_by_type):
	var new_possible_states = self._get_possible_states_from_neighbors()
	self._possible_states_set(new_possible_states)
	self.calculate_entropy(weights_by_type)
	
	# and mark myself updated
	self.dirty = false
	
func collapse_full(weights_by_type):
	var type = 0
	if not self.collapsed:
		# choose one of a set of possible states to collapse down to
		var pos_by_weight = {}
		var curr_weight = 0.0
		var weights = self._get_weights()
		for state in weights.keys():
			if state & possible_states == state:
				var w = min(weights[state] * weights_by_type[state] * 1.0, 999999999)
				curr_weight += max(1, w)
				pos_by_weight[curr_weight] = state 
			
		self.rng.randomize()
		var rand_weight = self.rng.randf_range(0, curr_weight)
		for weight in pos_by_weight.keys():
			if rand_weight < weight:
				type = pos_by_weight[weight]
				break
	else:
		type = self.possible_states
	self._collapse_final(type)
	
func collapse_to_specific_type(type):
	self._collapse_final(type)


## HELPER METHODS ##
func _collapse_final(type):
	self._possible_states_set(type)
	for neighbor in self.neighbors.values():
		neighbor.collapsed_neighbor_types.append(type)
	var og_entropy = self.entropy
	self.entropy = -1
	emit_signal("on_collapsed", self.key, type)
	emit_signal("on_entropy_updated", self.key, og_entropy, self.entropy)
		
func _possible_states_set(new_states):
			
	if new_states == self.possible_states:
		self.dirty = false
		return
	
	possible_states = new_states
	
	
	var allowed_types = -1
	var neighbor_rules = HexCollapseData.binary_data['neighbors']
	for bit in neighbor_rules.keys():
		if bit & new_states == bit:
			if allowed_types == -1:
				allowed_types = neighbor_rules[bit]
			else:
				allowed_types |= neighbor_rules[bit]
				
	
	# if there is, tell the neighbors they need to re-evaluate
	if allowed_types != self.allowed_neighbor_states:
		self.allowed_neighbor_states = allowed_types
		for neighbor in self.neighbors.values():
			neighbor.mark_dirty()

func _get_weights():
	var weights = HexCollapseData.binary_data['weights']
	var collapsed_neighbors = self._get_weights__from_neighbor(weights)
	return self._get_weights__updated(weights, collapsed_neighbors)
	
func _get_weights__from_neighbor(weights):
	var collapsed_neighbors = {}
	for weight in weights:
		collapsed_neighbors[weight] = 0
	
	for neighbor in self.collapsed_neighbor_types:
		collapsed_neighbors[neighbor] += 1
	return collapsed_neighbors
	
func _get_weights__updated(weights, collapsed_neighbors):
	var updated_weights = {}
	for state in weights:
		updated_weights[state] = weights[state] * (collapsed_neighbors[state] * 40 + 1)
	return updated_weights
	
	
			
func _get_possible_states_from_neighbors():
	# determine the set of states allowed by each neighbor
	var joined_states = -1
	for n_key in self.neighbors:
		if joined_states == -1:
			joined_states = self.neighbors[n_key].allowed_neighbor_states
		else:
			joined_states &= self.neighbors[n_key].allowed_neighbor_states
	return joined_states
	
func _strip_possible_states(new_possible_states, allowed_types):
	var updated_state = {}
	for state in new_possible_states:
		if state in allowed_types:
			updated_state[state] = null
	return updated_state
	
