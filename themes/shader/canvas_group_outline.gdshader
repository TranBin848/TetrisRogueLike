shader_type canvas_item;
render_mode unshaded;

uniform vec3 line_colour: source_color = vec3(1.0);
uniform int line_thickness: hint_range(0, 10) = 1;
uniform int shadow_offset = 0;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec2 size = SCREEN_PIXEL_SIZE * float(line_thickness);
	float line_alpha = 0.0;

	for (float i = -size.x; i <= size.x; i += SCREEN_PIXEL_SIZE.x) {
		for (float j = -size.y; j <= size.y; j += SCREEN_PIXEL_SIZE.y) {
			line_alpha += texture(screen_texture, SCREEN_UV + vec2(i, j)).a;
		}
	}

	// Calculate shadow
	vec2 shadow_pos = SCREEN_UV + SCREEN_PIXEL_SIZE * float(shadow_offset);
	float shadow_alpha = 0.0;
	
	for (float i = -size.x; i <= size.x; i += SCREEN_PIXEL_SIZE.x) {
		for (float j = -size.y; j <= size.y; j += SCREEN_PIXEL_SIZE.y) {
			shadow_alpha += texture(screen_texture, shadow_pos + vec2(i, j)).a;
		}
	}

	vec4 colour = texture(screen_texture, SCREEN_UV);
	
	// Get the maximum alpha in the area to respect modulate
	float content_alpha = colour.a;
	
	// Only show outline/shadow where there's content nearby
	float outline_strength = min(line_alpha, 1.0) - content_alpha;
	float shadow_strength = min(shadow_alpha, 1.0) - content_alpha;
	
	vec4 outline = vec4(line_colour, max(outline_strength, 0.0));
	vec4 shadow = vec4(line_colour, max(shadow_strength, 0.0));
	
	// Blend shadow, then outline, then color
	COLOR = mix(shadow, outline, outline.a);
	COLOR = mix(COLOR, colour, colour.a);
}
