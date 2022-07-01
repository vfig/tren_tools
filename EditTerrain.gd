extends Panel

func _on_open_file_pressed():
	var dialog:FileDialog = $OpenFileDialog
	dialog.connect("file_selected", _on_open_file_file_selected)
	dialog.popup_centered_ratio()

func _on_open_file_file_selected(path:String):
	var dialog:FileDialog = $OpenFileDialog
	dialog.disconnect("file_selected", _on_open_file_file_selected)
	print("Selected files: ", path)
	var result = file_read_bytes(path)
	if result.ok:
		result = read_gsbg(result.data, path)
	if result.ok:
		print("Result: ", result)
		var texture := ImageTexture.new()
		texture.create_from_image(result.image)
		var rect:TextureRect = $TextureRect
		rect.texture = texture
		rect.material.set_shader_param("z_range", result.z_range)
		return
	print("Error: ", result.error)

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
