shader_type canvas_item;
// Paints the whole battlefield ground in one pass: large coherent patches of
// grass, forest floor, dirt and stone with organic but well-defined edges.
//
// TEXTURE is the terrain field built by ground_view.gd: one smooth 0..1
// coverage value per channel, 0.5 lying on the boundary between cells.
//   R = dirt   G = forest floor   B = stone   A = Orichalcum-bearing stone
// The art textures repeat in world space, so no tile seams or tile repetition.

uniform sampler2D grass_texture : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D forest_texture : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D dirt_texture : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D stone_texture : source_color, repeat_enable, filter_linear_mipmap;
// R = boundary wobble, G = brightness drift, B = ore vein pattern.
uniform sampler2D variation_texture : repeat_enable, filter_linear;
uniform vec2 map_size_cells = vec2(40.0, 24.0);
// How many grid cells one repeat of an art texture covers.
uniform float cells_per_repeat = 4.0;

// Direction towards the light: the top-left of the screen, as in the sprites.
const vec2 TO_LIGHT = vec2(-0.7071, -0.7071);
const vec3 ORE_GLOW = vec3(1.0, 0.62, 0.18);

float wobble(sampler2D variation, vec2 cell) {
	float low = texture(variation, cell / 7.0).r - 0.5;
	float high = texture(variation, cell / 2.3 + vec2(0.37, 0.61)).r - 0.5;
	return low * 0.22 + high * 0.12;
}

float edge(float value, float softness) {
	return smoothstep(0.5 - softness, 0.5 + softness, value);
}

void fragment() {
	vec2 cell = UV * map_size_cells;
	vec2 art_uv = cell / cells_per_repeat;
	vec4 field = texture(TEXTURE, UV);
	float bend = wobble(variation_texture, cell);
	float drift = texture(variation_texture, cell / 17.0).g;

	// Grass everywhere, with slow brightness drift so big areas do not look flat.
	vec3 color = texture(grass_texture, art_uv).rgb * (0.93 + 0.14 * drift);

	// Forest floor: a wide, soft, irregular edge under the trees.
	float forest = smoothstep(0.30, 0.64, field.g + bend * 1.5);
	color = mix(color, texture(forest_texture, art_uv).rgb * (0.9 + 0.2 * drift), forest);

	// Dirt: a slightly sunken track with a darker lip just inside its edge.
	float dirt_value = field.r + bend;
	float dirt = edge(dirt_value, 0.045);
	vec3 dirt_color = texture(dirt_texture, art_uv).rgb * (0.9 + 0.2 * drift);
	float lip = 1.0 - smoothstep(0.52, 0.70, dirt_value);
	dirt_color *= 1.0 - 0.30 * lip;
	color = mix(color, dirt_color, dirt);

	// Stone: a raised slab. It casts a shadow to the bottom-right, and its rim
	// is lit on the side facing the light and dark on the far side.
	float stone_value = field.b + bend * 0.6;
	float stone = edge(stone_value, 0.03);
	vec2 shadow_cell = cell - vec2(0.17, 0.17);
	float shadow_value = texture(TEXTURE, shadow_cell / map_size_cells).b
			+ wobble(variation_texture, shadow_cell) * 0.6;
	color *= 1.0 - 0.42 * edge(shadow_value, 0.07) * (1.0 - stone);

	vec3 stone_color = texture(stone_texture, art_uv).rgb * (0.9 + 0.2 * drift);
	vec2 gradient = vec2(dFdx(stone_value), dFdy(stone_value));
	float slope = length(gradient);
	vec2 outward = slope > 0.00001 ? -gradient / slope : vec2(0.0);
	float rim = 1.0 - smoothstep(0.54, 0.80, stone_value);
	stone_color *= 1.0 + rim * dot(outward, TO_LIGHT) * 0.5;

	// Orichalcum: darker rock threaded with glowing amber veins.
	float ore = smoothstep(0.30, 0.70, field.a + bend * 0.5);
	float vein_a = 1.0 - smoothstep(0.0, 0.035, abs(texture(variation_texture, cell / 3.1).b - 0.5));
	float vein_b = 1.0 - smoothstep(0.0, 0.028, abs(texture(variation_texture, cell / 1.9 + vec2(0.5, 0.2)).b - 0.44));
	stone_color = mix(stone_color, stone_color * vec3(0.62, 0.60, 0.68), ore);
	stone_color += ORE_GLOW * (vein_a + vein_b * 0.7) * ore;

	color = mix(color, stone_color, stone);
	COLOR = vec4(color, 1.0);
}
