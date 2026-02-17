shader_type spatial;

// === GLOBAL INCLUDES ===
#include "res://fractal_globals.gdshaderinc"

// Use unshaded mode since we handle all lighting manually
render_mode unshaded, cull_disabled;

// Screen texture for reflections and background
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// === MENGER 4D PARAMETERS ===
group_uniforms Menger_4D_Main;
uniform float MengerScale : hint_range(1.0, 5.0) = 3.0;
uniform vec4 MengerOffset1 = vec4(1.0, 1.0, 1.0, 1.0);
uniform int Iterations : hint_range(1, 20) = 8;
uniform float RotationAngle : hint_range(0.0, 6.28) = 0.0;

group_uniforms Inversion_Settings;
uniform int InvType : hint_range(0, 8) = 0;
uniform float InvScale : hint_range(0.01, 5.0) = 1.0;
uniform float InvParamA : hint_range(-6.0, 6.0) = 0.5;
uniform vec4 InvCenter = vec4(0.0);

group_uniforms Rendering;
uniform float Detail : hint_range(-5.0, -1.0) = -2.5;
uniform int MaxSteps : hint_range(32, 512) = 256;

group_uniforms Fractal_Modes;
uniform bool JuliaMode = false;
uniform float JuliaMorph : hint_range(0.0, 1.0) = 0.0;
uniform vec4 JuliaSeed = vec4(0.0);

// === VERTEX SHADER ===
void vertex() {
	// Fullscreen quad - covers entire viewport
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

// === 4D ROTATION FUNCTION ===
vec4 rotate4D(vec4 p, float angle) {
	float s = sin(angle);
	float c = cos(angle);
	// Rotate in the XW plane for 4D depth
	return vec4(p.x * c - p.w * s, p.y, p.z, p.x * s + p.w * c);
}

// === 4D INVERSION HELPER ===
// Calculates the squared radius for shape-based inversions
float getShape2CenterSqr(vec4 p, int type, float scale, float min_radius) {
	float id2 = 1.0;
	
	if (type == 0) {
		// Standard sphere inversion
		id2 = scale * scale;
	}
	else if (type == 8) {
		// Amazing Box inversion (variable radius based on distance)
		float min_r2 = min_radius * min_radius;
		float fixed_r2 = scale * scale;
		float r2 = dot(p, p);
		
		if (r2 < min_r2) {
			id2 = fixed_r2 / min_r2;
		}
		else if (r2 < fixed_r2) {
			id2 = fixed_r2 / r2;
		}
		else {
			id2 = 1.0; // No inversion beyond fixed radius
		}
	}
	else {
		// Types 1-7: Reserved for future inversion types
		// Currently treated as standard sphere inversion
		id2 = scale * scale;
	}
	
	return id2;
}

// === SHAPE FOLD (SPHERE/BOX INVERSION) ===
void shapeFold4D(inout vec4 p, inout float der) {
	float s2InvCenterSqr = getShape2CenterSqr(p - InvCenter, InvType, InvScale, InvParamA);
	float p2InvCenterSqr = dot(p - InvCenter, p - InvCenter);
	
	if (p2InvCenterSqr < s2InvCenterSqr) {
		float ratio = s2InvCenterSqr / p2InvCenterSqr;
		p *= ratio;
		der *= ratio;
	}
}

// === MENGER SPONGE 4D DISTANCE ESTIMATOR ===
float map(vec3 p3d, out vec4 orbit) {
	// Start with 4D point
	vec4 p4d = vec4(p3d, OffsetW);
	orbit = vec4(1e20);
	
	// Calculate combined offset (Menger or Julia based on morph)
	vec4 combined_offset = mix(MengerOffset1, JuliaSeed, JuliaMorph);
	
	// Apply 4D rotation if enabled
	if (abs(RotationAngle) > 0.01) {
		p4d = rotate4D(p4d, RotationAngle);
	}
	
	// Extract 3D position (now includes W influence from rotation)
	vec3 z = p4d.xyz;
	
	// W-axis influence: Modulate the 3D position based on W component
	float w_influence = p4d.w + combined_offset.w;
	z += vec3(sin(w_influence), cos(w_influence), sin(w_influence * 0.7)) * 0.2;
	
	// Apply symmetry folding from globals
	apply_symmetry(z);
	
	// Apply offset translation
	z -= combined_offset.xyz * 0.1;
	
	// Core Menger Sponge algorithm
	float d = length(max(abs(z) - 1.5, 0.0));
	float s = 1.0;
	
	for (int i = 0; i < Iterations; i++) {
		vec3 a = mod(z * s, 2.0) - 1.0;
		s *= MengerScale;
		vec3 r = abs(1.0 - MengerScale * abs(a));
		
		float da = max(r.x, r.y);
		float db = max(r.y, r.z);
		float dc = max(r.z, r.x);
		float c = (min(da, min(db, dc)) - 1.0) / s;
		
		d = max(d, c);
		
		// Update orbit trap for coloring
		orbit = min(orbit, vec4(abs(a), length(a)));
	}
	
	// Apply shape inversion if enabled
	if (InvType > 0) {
		float inv_radius = InvScale;
		float r = length(z);
		if (r < inv_radius) {
			d *= inv_radius / r;
		}
	}
	
	return d * 0.8;
}

// === NORMAL CALCULATION ===
vec3 get_normal(vec3 p) {
	float e = 0.001; // Epsilon for gradient
	vec4 dummy;
	return normalize(vec3(
		map(p + vec3(e, 0, 0), dummy) - map(p - vec3(e, 0, 0), dummy),
		map(p + vec3(0, e, 0), dummy) - map(p - vec3(0, e, 0), dummy),
		map(p + vec3(0, 0, e), dummy) - map(p - vec3(0, 0, e), dummy)
	));
}



// === FRAGMENT SHADER ===
void fragment() {
	// === RAY SETUP ===
	vec3 ro = CAMERA_POSITION_WORLD;
	
	// Convert screen UV to normalized device coordinates
	vec2 p_ndc = SCREEN_UV * 2.0 - 1.0;
	p_ndc.x *= VIEWPORT_SIZE.x / VIEWPORT_SIZE.y; // Aspect ratio correction
	
	// Calculate ray direction
	vec3 rd = normalize((INV_VIEW_MATRIX * vec4(p_ndc, -1.0, 0.0)).xyz);
	
	// === RAY MARCHING ===
	float t = 0.5; // Start farther from camera to avoid being inside
	bool hit = false;
	vec4 orbit = vec4(0.0);
	int steps_taken = 0;
	
	for (int i = 0; i < MaxSteps; i++) {
		float d = map(ro + rd * t, orbit);
		steps_taken = i;
		
		// Hit detection
		if (d < pow(10.0, Detail)) {
			hit = true;
			break;
		}
		
		// Step forward
		t += d * 0.9;
		
		// Max distance check - search farther
		if (t > 100.0) break;
	}
	
	// === RENDERING ===
	if (hit) {
		vec3 p = ro + rd * t;
		vec3 normal = get_normal(p);
		
		// === COLOR FROM ORBIT TRAP ===
		vec3 fractal_col = palette(length(orbit.xyz) * ColorCycle);
		
		// === STRONG LIGHTING ===
		vec3 light_dir = normalize(vec3(1.0, 2.0, 3.0));
		float diffuse = max(dot(normal, light_dir), 0.0);
		float lighting = diffuse * 0.8 + 0.3; // 80% diffuse, 30% ambient
		
		fractal_col *= lighting;
		
		// Ensure minimum brightness
		fractal_col = max(fractal_col, vec3(0.05));
		
		// === SPECULAR HIGHLIGHTS ===
		vec3 view_dir = normalize(ro - p);
		vec3 half_dir = normalize(light_dir + view_dir);
		float spec = pow(max(dot(normal, half_dir), 0.0), 32.0);
		fractal_col += vec3(spec * 0.3);
		
		// === REFLECTIVITY (Environment Mapping) ===
		if (Reflectivity > 0.0) {
			vec3 ref_dir = reflect(rd, normal);
			vec2 ref_uv = SCREEN_UV + ref_dir.xy * 0.05;
			ref_uv = clamp(ref_uv, 0.0, 1.0);
			
			vec3 reflection = texture(SCREEN_TEXTURE, ref_uv).rgb;
			fractal_col = mix(fractal_col, reflection, Reflectivity);
		}
		
		// === FOG ===
		if (FogDensity > 0.0) {
			float fog = 1.0 - exp(-t * FogDensity);
			vec3 fog_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
			fractal_col = mix(fractal_col, fog_color, fog);
		}
		
		ALBEDO = apply_art_controls(fractal_col); 
	}
	else {
		// Keep your background gradient logic - it looks better than pure black
		vec3 bg = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
		
		if (length(bg) < 0.01) {
			float gradient = p_ndc.y * 0.5 + 0.5;
			bg = mix(vec3(0.05, 0.05, 0.1), vec3(0.1, 0.15, 0.2), gradient);
		}
		
		ALBEDO = bg;
	}
}
