shader_type canvas_item;
render_mode unshaded;

uniform vec2 z_range = vec2(0.0,1.0);

void fragment() {
	float z_raw = texture(TEXTURE, UV).r;
	float z = (z_raw-z_range.x)/(z_range.y-z_range.x);
	COLOR = vec4(z,z,z,1.0);
}
