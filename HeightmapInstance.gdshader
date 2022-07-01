shader_type spatial;
render_mode unshaded;

uniform sampler2D height_texture;
uniform vec2 z_range = vec2(0.0,1.0);

void fragment() {
	float z_raw = texture(height_texture, UV).r;
	float z = (z_raw-z_range.x)/(z_range.y-z_range.x);
	ALBEDO = vec3(z,z,z);
}
