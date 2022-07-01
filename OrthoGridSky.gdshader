shader_type sky;

uniform vec2 viewport_size_px;
uniform vec2 viewport_center_m;
uniform float px_per_m;
uniform float grid_major_line_width_px;
uniform float grid_minor_line_width_px;
uniform float grid_major_spacing_m;
uniform float grid_minor_spacing_m;
uniform vec3 background_color;
uniform vec3 grid_major_color;
uniform vec3 grid_minor_color;

float grid(vec2 uv, float spacing, float line_width) {
	vec2 p = uv-vec2(0.5);
	vec2 size = vec2(line_width-0.5);
	vec2 a1 = mod(p-size,spacing);
	vec2 a2 = mod(p+size,spacing);
	vec2 a = a2-a1;
	float g = min(a.x,a.y);
	return clamp(g, 0.0, 1.0);
}

void sky() {
	vec2 screen_px = vec2(SCREEN_UV.x-0.5,0.5-SCREEN_UV.y)*viewport_size_px;
	screen_px += viewport_center_m*px_per_m;
	float grid_major = grid(screen_px, grid_major_spacing_m*px_per_m, grid_major_line_width_px);
	float grid_minor = grid(screen_px, grid_minor_spacing_m*px_per_m, grid_minor_line_width_px);
	COLOR = mix(grid_major_color, mix(grid_minor_color, background_color, grid_minor), grid_major);
}
