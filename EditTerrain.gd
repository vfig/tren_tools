extends Panel

var selection:HeightmapInstance = null:
	set=_set_selection

func _set_selection(inst:HeightmapInstance=null):
	print("select ",inst," (previously ",selection,")")
	selection = inst
	if inst!=null:
		%EditZMin.text = str(inst.z_range.x)
		%EditZMax.text = str(inst.z_range.y)
		%SelectionHandles.global_transform = inst.global_transform
		%SelectionHandles.visible = true
	else:
		%EditZMin.text = ""
		%EditZMax.text = ""
		%SelectionHandles.visible = false

func _on_open_file_pressed():
	var dialog:FileDialog = $OpenFileDialog
	dialog.connect("file_selected", _on_open_file_file_selected)
	dialog.popup_centered_ratio()

func _on_open_file_file_selected(path:String):
	var dialog:FileDialog = $OpenFileDialog
	dialog.disconnect("file_selected", _on_open_file_file_selected)
	print("Selected files: ", path)
	var result = file_read_bytes(path)
	if result.error:
		print("Error: ", result.error)
		return
	result = read_gsbg(result.data, path)
	if result.error:
		print("Error: ", result.error)
		return
	print("Result: ", result)
	var texture := ImageTexture.new()
	texture.create_from_image(result.image)
	var inst:HeightmapInstance = HeightmapInstance.new()
	inst.height_texture = texture
	inst.x_range = result.x_range
	inst.y_range = result.y_range
	inst.z_range = result.z_range
	%MapViewport.add_child(inst)
	selection = inst

func file_read_bytes(path:String) -> Dictionary:
	var make_result = func(error:int=FAILED, data=null) -> Dictionary:
		return {
			ok=(error==OK),
			error=error,
			data=data,
			}
	var file:File = File.new()
	var error:int = OK
	var data = null
	file.open(path, File.READ)
	error = file.get_error()
	if error==OK:
		data = file.get_buffer(file.get_length())
		error = file.get_error()
	file.close()
	return make_result.call(error, data)

func read_gsbg(data:PackedByteArray, path:String="(unknown path)") -> Dictionary:
	var make_result = func(error:int=FAILED, image:Image=null,
							x_min:float=0.0, x_max:float=1.0,
							y_min:float=0.0, y_max:float=1.0,
							z_min:float=0.0, z_max:float=1.0
							) -> Dictionary:
		return {
			ok=(error==OK),
			error=error,
			image=image,
			x_range=Vector2(x_min,x_max),
			y_range=Vector2(y_min,y_max),
			z_range=Vector2(z_min,z_max),
			}
	# GSBG Format:
	#
	# byte[4] magic = "DSBB"
	# int16   width, height
	# float64 x_min, x_max
	# float64 y_min, y_max
	# float64 z_min, z_max
	# float32[width][height] elevations
	#
	const DSBB:int = 0x42425344
	const header_size:int = 0x38
	const width_max:int = 16384
	const height_max:int = 16384

	if data.size()<header_size:
		push_error("File \"%s\" does not have GSBG header." % path)
		return make_result.call(ERR_PARSE_ERROR)
	var magic:int = data.decode_u32(0)
	if magic!=DSBB:
		push_error("File \"%s\" does not have GSBG identifier." % path)
		return make_result.call(ERR_PARSE_ERROR)
	var width:int = data.decode_s16(4)
	var height:int = data.decode_s16(6)
	var x_min:float = data.decode_double(8)
	var x_max:float = data.decode_double(16)
	var y_min:float = data.decode_double(24)
	var y_max:float = data.decode_double(32)
	var z_min:float = data.decode_double(40)
	var z_max:float = data.decode_double(48)
	if width<0 or width>width_max \
	or height<0 or height>height_max:
		push_error("File \"%s\" has unsupported size %sx%s." % [path,width,height])
		return make_result.call(ERR_PARSE_ERROR)
	var floats_start:int = header_size
	var floats_size:int = height*width*4
	var floats_end:int = floats_start+floats_size
	if data.size()<floats_end:
		push_error("File \"%s\" is too short." % path)
		return make_result.call(ERR_PARSE_ERROR)
	var image:Image = Image.new()
	image.data = {
		data=data.slice(floats_start,floats_end),
		format="RFloat",
		width=width,
		height=height,
		mipmaps=false,
		}
	return make_result.call(OK, image, x_min, x_max, y_min, y_max, z_min, z_max)

func _update_z_min_from_field(field:LineEdit, force_field_valid:bool=false):
	if selection==null:
		return
	var inst:HeightmapInstance = selection
	var z_range:Vector2 = inst.z_range
	var value:float = field.text.to_float()
	if not is_nan(value):
		z_range.x = value
		inst.z_range = z_range
		if force_field_valid:
			field.text = str(value)

func _update_z_max_from_field(field:LineEdit, force_field_valid:bool=false):
	if selection==null:
		return
	var inst:HeightmapInstance = selection
	var z_range:Vector2 = inst.z_range
	var value:float = field.text.to_float()
	if not is_nan(value):
		z_range.y = value
		inst.z_range = z_range
		if force_field_valid:
			field.text = str(value)

func _on_edit_z_min_text_changed(new_text):
	_update_z_min_from_field(%EditZMin)

func _on_edit_z_min_text_submitted(new_text):
	_update_z_min_from_field(%EditZMin, true)
	%EditZMin.release_focus()

func _on_edit_z_max_text_changed(new_text):
	_update_z_max_from_field(%EditZMax)

func _on_edit_z_max_text_submitted(new_text):
	_update_z_max_from_field(%EditZMax, true)
	%EditZMax.release_focus()
