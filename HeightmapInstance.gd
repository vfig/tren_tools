extends MeshInstance3D
class_name HeightmapInstance

@export var height_texture:Texture2D
@export var x_range:Vector2 = Vector2(0.0, 1.0)
@export var y_range:Vector2 = Vector2(0.0, 1.0)
@export var z_range:Vector2 = Vector2(0.0, 1.0)

func _init():
	mesh = QuadMesh.new()
	material_override = preload("res://matHeightmapInstance.tres")

func _process(_dt):
	var mat := (material_override as ShaderMaterial)
	mat.set_shader_param("height_texture", height_texture)
	mat.set_shader_param("z_range", z_range)
