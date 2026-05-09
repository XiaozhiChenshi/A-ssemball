shader_type canvas_item;

uniform float glitch_amount : hint_range(0.0, 1.0) = 0.0;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform float time_phase = 0.0;
uniform float slice_strength : hint_range(0.0, 1.0) = 0.0;
uniform float dropout_strength : hint_range(0.0, 1.0) = 0.0;
uniform float rgb_split : hint_range(0.0, 1.0) = 0.0;
uniform float scan_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 cyan_tint : source_color = vec4(0.30, 0.86, 1.0, 1.0);

float hash(float n) {
	return fract(sin(n) * 43758.5453123);
}

float band_offset(float y, float amount, float speed, float seed) {
	float band = floor(y * mix(10.0, 42.0, amount));
	float tick = floor(time_phase * speed);
	float noise = hash(band * 31.7 + tick * 11.3 + seed);
	float enabled = step(1.0 - amount * 0.84, noise);
	float direction = mix(-1.0, 1.0, step(0.5, hash(band + seed * 3.1)));
	return direction * enabled * amount * mix(0.006, 0.060, noise);
}

void fragment() {
	float amount = clamp(glitch_amount, 0.0, 1.0);
	float slice_amount = clamp(slice_strength + amount * 0.52, 0.0, 1.0);
	float dropout_amount = clamp(dropout_strength + amount * 0.42, 0.0, 1.0);
	float rgb_amount = clamp(rgb_split + amount * 0.34, 0.0, 1.0);
	float scan_amount = clamp(scan_strength + amount * 0.28, 0.0, 1.0);

	float slice_offset = band_offset(UV.y, slice_amount, 36.0, 17.0);
	slice_offset += band_offset(UV.y + 0.037, slice_amount * 0.55, 19.0, 71.0);
	float micro_wave = sin((UV.y * 96.0) + time_phase * 18.0) * slice_amount * 0.0025;

	vec2 shifted_uv = UV + vec2(slice_offset + micro_wave, 0.0);
	vec4 base_color = texture(TEXTURE, shifted_uv) * COLOR;

	float chroma = rgb_amount * 0.018;
	vec4 red_channel = texture(TEXTURE, shifted_uv + vec2(chroma, 0.0)) * COLOR;
	vec4 cyan_channel = texture(TEXTURE, shifted_uv - vec2(chroma * 1.35, 0.0)) * COLOR;

	vec3 rgb = base_color.rgb;
	rgb.r = mix(rgb.r, red_channel.r, rgb_amount * 0.72);
	rgb.gb = mix(rgb.gb, cyan_channel.gb, rgb_amount * 0.72);

	float scanline = 0.72 + 0.28 * smoothstep(0.12, 0.82, fract(UV.y * mix(36.0, 96.0, scan_amount) + time_phase * 0.85));
	float sweep = smoothstep(0.030, 0.0, abs(fract(UV.y - time_phase * 0.42) - 0.5));
	rgb += cyan_tint.rgb * sweep * scan_amount * 0.18 * base_color.a;

	float dropout_band = floor(UV.y * mix(18.0, 62.0, dropout_amount));
	float dropout_noise = hash(dropout_band * 19.0 + floor(time_phase * 44.0) * 23.0);
	float row_dropout = step(1.0 - dropout_amount * 0.50, dropout_noise);
	float thin_dropout = step(0.985 - dropout_amount * 0.25, hash(floor(UV.y * 140.0) + floor(time_phase * 58.0)));
	float alpha_cut = mix(1.0, 0.14, max(row_dropout, thin_dropout) * dropout_amount);

	float alpha = base_color.a * opacity * alpha_cut * mix(1.0, scanline, scan_amount * 0.42);
	COLOR = vec4(rgb, alpha);
}
