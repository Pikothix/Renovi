shader_type canvas_item;

uniform sampler2D terrain_map : filter_nearest, repeat_disable;

uniform vec2 logical_map_cells = vec2(16.0, 16.0);
uniform vec2 padded_map_cells = vec2(18.0, 18.0);
uniform float cell_size_px = 16.0;

uniform vec4 deep_water_color : source_color = vec4(0.18, 0.37, 0.65, 1.0);
uniform vec4 shallow_water_color : source_color = vec4(0.35, 0.60, 0.88, 1.0);
uniform vec4 sand_color : source_color = vec4(0.85, 0.76, 0.43, 1.0);
uniform vec4 dirt_color : source_color = vec4(0.55, 0.35, 0.24, 1.0);
uniform vec4 grass_color : source_color = vec4(0.37, 0.73, 0.38, 1.0);
uniform vec4 jungle_ground_color : source_color = vec4(0.19, 0.49, 0.25, 1.0);
uniform vec4 clay_color : source_color = vec4(0.66, 0.64, 0.60, 1.0);
uniform vec4 stone_color : source_color = vec4(0.31, 0.33, 0.36, 1.0);

uniform float land_noise_strength = 0.15;
uniform float shoreline_noise_strength = 0.08;
uniform float land_blend_strength = 0.12;
uniform float shoreline_blend_strength = 0.07;
uniform float shoreline_tint_strength = 0.08;
uniform float edge_noise_scale = 2.6;
uniform float pixel_variation = 0.06;


float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}


float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}


float decode_terrain(vec2 local_cell_coord) {
	vec2 uv = (local_cell_coord + vec2(1.5)) / padded_map_cells;
	float encoded = texture(terrain_map, uv).r;
	return floor(encoded * 7.0 + 0.5);
}


bool is_water(float terrain_id) {
	return terrain_id < 1.5;
}


vec3 terrain_color(float terrain_id) {
	if (terrain_id < 0.5) {
		return deep_water_color.rgb;
	}
	if (terrain_id < 1.5) {
		return shallow_water_color.rgb;
	}
	if (terrain_id < 2.5) {
		return sand_color.rgb;
	}
	if (terrain_id < 3.5) {
		return dirt_color.rgb;
	}
	if (terrain_id < 4.5) {
		return grass_color.rgb;
	}
	if (terrain_id < 5.5) {
		return jungle_ground_color.rgb;
	}
	if (terrain_id < 6.5) {
		return clay_color.rgb;
	}
	return stone_color.rgb;
}


float shoreline_presence(vec2 base_cell) {
	float current_terrain = decode_terrain(base_cell);
	float near_water = 0.0;

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			if (x == 0 && y == 0) {
				continue;
			}
			vec2 candidate = clamp(base_cell + vec2(float(x), float(y)), vec2(-1.0), logical_map_cells);
			float terrain_id = decode_terrain(candidate);
			if (is_water(terrain_id) != is_water(current_terrain)) {
				near_water += 1.0;
			}
		}
	}

	return clamp(near_water / 4.0, 0.0, 1.0);
}


float water_wave(vec2 pixel_pos) {
	float wave_a = sin(pixel_pos.x * 0.11 + pixel_pos.y * 0.03);
	float wave_b = sin(pixel_pos.y * 0.08 - pixel_pos.x * 0.02 + 1.3);
	return (wave_a + wave_b) * 0.5;
}


void fragment() {
	vec2 world_cells = UV * logical_map_cells;
	vec2 base_cell = floor(world_cells);
	float current_terrain = decode_terrain(clamp(base_cell, vec2(0.0), logical_map_cells - vec2(1.0)));
	bool current_is_water = is_water(current_terrain);
	vec3 color_accum = vec3(0.0);
	float total_weight = 0.0;

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 candidate = clamp(base_cell + vec2(float(x), float(y)), vec2(-1.0), logical_map_cells);
			float terrain_id = decode_terrain(candidate);
			bool shoreline_edge = is_water(terrain_id) != current_is_water;
			vec2 candidate_center = candidate + vec2(0.5);
			vec2 delta = abs(world_cells - candidate_center);
			float square_distance = max(delta.x, delta.y);

			float edge_noise = value_noise((world_cells + candidate * 1.618) * edge_noise_scale);
			float noise_strength = shoreline_edge ? shoreline_noise_strength : land_noise_strength;
			float blend_strength = shoreline_edge ? shoreline_blend_strength : land_blend_strength;
			float noisy_boundary = 0.5 + (edge_noise - 0.5) * noise_strength;
			float weight = 1.0 - smoothstep(noisy_boundary, noisy_boundary + blend_strength, square_distance);

			color_accum += terrain_color(terrain_id) * weight;
			total_weight += weight;
		}
	}

	if (total_weight < 0.001) {
		color_accum = terrain_color(current_terrain);
		total_weight = 1.0;
	}

	vec3 color = color_accum / total_weight;
	float shoreline_mix = shoreline_presence(base_cell);
	if (!current_is_water) {
		color = mix(color, sand_color.rgb, shoreline_mix * shoreline_tint_strength);
	} else {
		float wave = water_wave(UV * logical_map_cells * cell_size_px);
		color *= 1.0 + wave * 0.03;
	}

	float grain = hash12(floor(UV * logical_map_cells * cell_size_px));
	color *= 1.0 + (grain - 0.5) * pixel_variation;

	COLOR = vec4(color, 1.0);
}
