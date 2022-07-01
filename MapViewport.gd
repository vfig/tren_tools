extends SubViewport

var has_mouse_focus:bool = false

var zoom_exponent:float = 0.0
const zoom_exponent_min:float = -5.0
const zoom_exponent_max:float = 5.0

var is_panning:bool = false
var pan_new_mouse_position:Vector2i
var pan_old_mouse_position:Vector2i

func _notification(notif):
	match notif:
		NOTIFICATION_VP_MOUSE_ENTER:
			has_mouse_focus = true
		NOTIFICATION_VP_MOUSE_EXIT:
			has_mouse_focus = false

func _input(event):
	if event is InputEventMouseButton \
	and has_mouse_focus \
	and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed \
				and not is_panning:
					zoom_exponent = clampf(zoom_exponent-0.1, zoom_exponent_min, zoom_exponent_max)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed \
				and not is_panning:
					zoom_exponent = clampf(zoom_exponent+0.1, zoom_exponent_min, zoom_exponent_max)
			MOUSE_BUTTON_MIDDLE:
				pan_old_mouse_position = event.position

	if event is InputEventMouseButton \
	and not event.pressed:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				is_panning = false

	if event is InputEventMouseMotion \
	and event.button_mask==MOUSE_BUTTON_MASK_MIDDLE:
		if not is_panning \
		and has_mouse_focus:
			is_panning = true
		if is_panning:
			pan_new_mouse_position = event.position
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func _process(dt):
	var t:float = (Time.get_ticks_msec()/1000.0)
	var camera:Camera3D = $Camera3D
	if is_panning:
		var delta := pan_new_mouse_position-pan_old_mouse_position
		pan_old_mouse_position = pan_new_mouse_position
		var pos_screen := size/2-delta
		var pos_world := camera.project_position(pos_screen, camera.position.z)
		camera.position = pos_world+Vector3(0.0,0.0,camera.position.z)
		#camera.global_transform.origin = Vector3(0.0,cos(t),10.0)
	camera.size = pow(2.0,zoom_exponent)
	update_grid_uniforms()

func update_grid_uniforms():
	var camera:Camera3D = $Camera3D
	var world_env:WorldEnvironment = $WorldEnvironment
	var mat:ShaderMaterial = world_env.environment.sky.sky_material as ShaderMaterial
	var camera_pos:Vector3 = camera.global_transform.origin
	var viewport_size_px:Vector2 = Vector2(size)
	var px_per_m:float = (camera.unproject_position(camera_pos+Vector3.DOWN)).y-0.5*viewport_size_px.y
	mat.set_shader_param("viewport_size_px", viewport_size_px)
	mat.set_shader_param("viewport_center_m", Vector2(camera_pos.x,camera_pos.y))
	mat.set_shader_param("px_per_m", px_per_m)
	mat.set_shader_param("grid_major_line_width_px", 1.5)
	mat.set_shader_param("grid_minor_line_width_px", 1.0)
	mat.set_shader_param("grid_major_spacing_m", 5.0)
	mat.set_shader_param("grid_minor_spacing_m", 1.0)
	mat.set_shader_param("background_color", Vector3(0.1,0.1,0.1))
	mat.set_shader_param("grid_major_color", Vector3(0.2,0.2,0.2))
	mat.set_shader_param("grid_minor_color", Vector3(0.15,0.15,0.15))
