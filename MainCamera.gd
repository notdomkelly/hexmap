extends Camera2D


export var pan_speed = 240
export var zoom_speed = 100
export var max_zoom = 10
export var min_zoom = 0.1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	handle_pan(delta)
	
func _input(event):
	handle_zoom(event)
	
func handle_pan(delta):
	var change = Vector2(0, 0)
	
	if Input.is_action_pressed("camera_up"):
		change.y -= pan_speed
	if Input.is_action_pressed("camera_down"):
		change.y += pan_speed
	if Input.is_action_pressed("camera_left"):
		change.x -= pan_speed
	if Input.is_action_pressed("camera_right"):
		change.x += pan_speed
		
	change = change * delta * self.zoom
		
	self.position += change

func handle_zoom(event):
	var zoom_change = Vector2(1, 1)
	var zoom_speed_actual = 1 + (zoom_speed / 1000.0)
	
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			zoom_change /= zoom_speed_actual
		if event.button_index == BUTTON_WHEEL_DOWN:
			zoom_change *= zoom_speed_actual
		
	self.zoom *= zoom_change
