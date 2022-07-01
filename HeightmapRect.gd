extends TextureRect
class_name HeightmapRect

@export var x_range:Vector2 = Vector2(0.0, 1.0)
@export var y_range:Vector2 = Vector2(0.0, 1.0)
@export var z_range:Vector2 = Vector2(0.0, 1.0)

func _ready():
	ignore_texture_size = true
	material = preload("res://matHeightmapScaled.tres")

func _process(_dt):
	var mat := (material as ShaderMaterial)
	mat.set_shader_param("z_range", z_range)
