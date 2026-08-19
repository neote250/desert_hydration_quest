// Sloshing water fill for the Drink button.
//
// Drives a ColorRect. `fill` is 0..1; the waterline sits at that height and is
// perturbed by two out-of-phase sine waves so the surface never looks periodic.
// `tilt` pivots the surface around the centre — feed it the accelerometer and
// the water leans when the player tilts the phone.
//
// `mask` is the canteen silhouette: water is multiplied by its alpha, so any
// skin shape works without touching this shader. Leave it unset for a plain
// square (the default white texture is fully opaque).
shader_type canvas_item;

uniform float fill : hint_range(0.0, 1.0) = 1.0;

uniform vec4 water_deep : source_color = vec4(0.117, 0.419, 0.490, 1.0);
uniform vec4 water_shallow : source_color = vec4(0.219, 0.647, 0.749, 1.0);
uniform vec4 empty_color : source_color = vec4(0.043, 0.098, 0.117, 0.35);
uniform vec4 foam_color : source_color = vec4(0.878, 0.964, 1.0, 1.0);

uniform float wave_amplitude : hint_range(0.0, 0.15) = 0.022;
uniform float wave_frequency : hint_range(1.0, 24.0) = 7.0;
uniform float wave_speed : hint_range(0.0, 6.0) = 1.6;
uniform float foam_thickness : hint_range(0.0, 0.08) = 0.014;

// -1..1. Positive leans the water to the right.
uniform float tilt : hint_range(-1.0, 1.0) = 0.0;
uniform float tilt_strength : hint_range(0.0, 1.0) = 0.22;

uniform sampler2D mask : hint_default_white;

void fragment() {
	float m = texture(mask, UV).a;

	// Waves flatten out as the container reaches full or empty, so the surface
	// never clips through the top or bottom edge.
	float damp = smoothstep(0.0, 0.12, fill) * smoothstep(0.0, 0.12, 1.0 - fill);

	float t = TIME * wave_speed;
	float w1 = sin(UV.x * wave_frequency + t) * wave_amplitude;
	float w2 = sin(UV.x * wave_frequency * 0.63 - t * 1.31) * wave_amplitude * 0.6;
	float lean = (UV.x - 0.5) * tilt * tilt_strength;

	float surface = (1.0 - fill) + (w1 + w2 + lean) * damp;

	// UV.y grows downward, so water is everything below the waterline.
	float is_water = smoothstep(surface - 0.004, surface + 0.004, UV.y);

	float depth = smoothstep(surface, 1.0, UV.y);
	vec4 water = mix(water_shallow, water_deep, depth);

	float foam = smoothstep(foam_thickness, 0.0, abs(UV.y - surface));
	water = mix(water, foam_color, foam * 0.55 * damp);

	COLOR = mix(empty_color, water, is_water);
	COLOR.a *= m;
}
