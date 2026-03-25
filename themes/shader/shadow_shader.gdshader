shader_type canvas_item;

uniform vec3 shadow_color: source_color = vec3(0.0, 0.0, 0.0);


void fragment() {
    COLOR.rgb = shadow_color;
}
