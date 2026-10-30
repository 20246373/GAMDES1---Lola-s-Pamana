// Shows a canvas item only inside the UV beam, once its tell has been revealed.
shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec2 beam_pos = vec2(-9999.0, -9999.0);
uniform float beam_radius = 90.0;
uniform float beam_on = 0.0;
uniform float revealed = 0.0;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float d = distance(world_pos, beam_pos);
	float inside = 1.0 - smoothstep(beam_radius * 0.6, beam_radius, d);
	COLOR.a *= inside * beam_on * revealed;
}
