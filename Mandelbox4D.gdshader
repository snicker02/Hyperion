shader_type spatial;

#include "res://fractal_globals.gdshaderinc"
uniform float Time;
render_mode unshaded, cull_disabled;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

group_uniforms Mandelbox_Main;
uniform float Scale : hint_range(-5.0, 5.0) = 2.5;
uniform float BoxFoldLimit : hint_range(0.1, 5.0) = 1.0;
uniform int Iterations : hint_range(1, 50) = 17;
uniform float RotationAngle : hint_range(0.0, 6.28) = 0.0;

group_uniforms Inversion_Settings;
uniform int InvType : hint_range(0, 8) = 0;
uniform float InvScale : hint_range(0.01, 5.0) = 2.08;
uniform float InvParamA : hint_range(-6.0, 6.0) = 0.94;
uniform float InvParamB : hint_range(3.0, 20.0) = 4.0;
uniform vec4 InvCenter = vec4(0.0);

group_uniforms Rendering;
uniform float Detail : hint_range(-5.0, -1.0) = -2.5;
uniform int MaxSteps : hint_range(32, 512) = 256;

group_uniforms Fractal_Modes;
uniform bool JuliaMode = false;
uniform vec4 JuliaSeed = vec4(-0.5, 0.2, 0.0, 0.0);

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

vec4 rotate4D(vec4 p, float angle) {
	float s = sin(angle);
	float c = cos(angle);
	return vec4(p.x * c - p.w * s, p.y, p.z, p.x * s + p.w * c);
}

float getShape2CenterSqr(vec4 p, int type, float scale, float min_radius, float param_b) {
	float id2 = 1.0;
	float r2 = dot(p, p);
	
	if (type == 0) {
		// Standard sphere inversion
		id2 = scale * scale;
	}
	else if (type == 1) {
		// Box inversion
		float box_r = max(max(abs(p.x), abs(p.y)), max(abs(p.z), abs(p.w)));
		id2 = scale * scale / (box_r * box_r + 0.001);
	}
	else if (type == 2) {
		// Octahedral inversion
		float oct_r = abs(p.x) + abs(p.y) + abs(p.z) + abs(p.w);
		id2 = scale * scale / (oct_r * oct_r + 0.001);
	}
	else if (type == 3) {
		// Cylinder inversion (XY plane)
		float cyl_r2 = p.x * p.x + p.y * p.y;
		id2 = scale * scale / (cyl_r2 + 0.001);
	}
	else if (type == 4) {
		// Pyramid inversion
		float pyr_r = max(max(abs(p.x), abs(p.y)), abs(p.z) + abs(p.w));
		id2 = scale * scale / (pyr_r * pyr_r + 0.001);
	}
	// === TYPE 5: 4D POLYGON PRISM (Uses Polygon Sides Slider) ===
	else if (type == 5) {
		int sides = int(clamp(param_b, 3.0, 20.0));
		float angle = 6.283185 / float(sides);
		
		// Map position to polar coordinates in XY plane
		float theta = atan(p.y, p.x);
		
		// Use cosine folding to find distance to nearest polygon edge
		float edge_theta = floor(theta / angle + 0.5) * angle;
		float poly_r = length(p.xy) * cos(theta - edge_theta);
		
		// 4D radius including Z and W components
		float dist_r2 = poly_r * poly_r + p.z * p.z + p.w * p.w;
		id2 = (scale * scale) / max(dist_r2, 0.00001);
	}
	else if (type == 6) {
		// Cross inversion
		float cross_r = min(min(abs(p.x), abs(p.y)), min(abs(p.z), abs(p.w)));
		id2 = scale * scale / (cross_r * cross_r + 0.001);
	}
	// === TYPE 7: 4D TOROIDAL (Uses Inversion Param A for Major Radius) ===
	else if (type == 7) {
		float major_r = length(p.xy) - min_radius;
		float torus_r2 = major_r * major_r + p.z * p.z + p.w * p.w;
		id2 = scale * scale / (torus_r2 + 0.00001);
	}
	// === TYPE 8: AMAZING BOX (Uses Min Radius / Fixed Radius) ===
	else if (type == 8) {
		float min_r2 = min_radius * min_radius;
		float fixed_r2 = scale * scale;
		
		if (r2 < min_r2) {
			id2 = fixed_r2 / min_r2;
		}
		else if (r2 < fixed_r2) {
			id2 = fixed_r2 / r2;
		}
		else {
			id2 = 1.0;
		}
	}
	else {
		id2 = scale * scale;
	}
	
	return id2;
}

void shapeFold(inout vec4 p, inout float der) {
	float s2InvCenterSqr = getShape2CenterSqr(p - InvCenter, InvType, InvScale, InvParamA, InvParamB);
	float p2InvCenterSqr = dot(p - InvCenter, p - InvCenter);
	
	if (p2InvCenterSqr < s2InvCenterSqr) {
		float ratio = s2InvCenterSqr / p2InvCenterSqr;
		p *= ratio;
		der *= ratio;
	}
}

void boxFold(inout vec4 p) {
	p = clamp(p, -BoxFoldLimit, BoxFoldLimit) * 2.0 - p;
}

float map(vec3 p3d, out vec4 orbit) {
	float dr = 1.0;
	orbit = vec4(1e20);
	
	vec4 p4d = vec4(p3d, OffsetW);
	vec4 offset = JuliaMode ? JuliaSeed : p4d;
	
	for (int i = 0; i < Iterations; i++) {
		p4d = rotate4D(p4d, RotationAngle);
		apply_symmetry(p4d.xyz);
		boxFold(p4d);
		shapeFold(p4d, dr);
		p4d = (p4d * Scale) + offset;
		dr = (dr * abs(Scale)) + 1.0;
		orbit = min(orbit, abs(p4d));
		if (dot(p4d, p4d) > 1000.0) break;
	}
	
	float box_size = abs(Scale - 1.0);
	vec4 q = abs(p4d) - box_size;
	return (length(max(q, 0.0)) + min(max(q.x, max(q.y, max(q.z, q.w))), 0.0)) / abs(dr);
}

vec3 get_normal(vec3 p) {
	float e = 0.001;
	vec4 dummy;
	return normalize(vec3(
		map(p + vec3(e, 0, 0), dummy) - map(p - vec3(e, 0, 0), dummy),
		map(p + vec3(0, e, 0), dummy) - map(p - vec3(0, e, 0), dummy),
		map(p + vec3(0, 0, e), dummy) - map(p - vec3(0, 0, e), dummy)
	));
}



void fragment() {
    vec3 ro = CAMERA_POSITION_WORLD;
    vec2 p_ndc = SCREEN_UV * 2.0 - 1.0;
    p_ndc.x *= VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
    vec3 rd = normalize((INV_VIEW_MATRIX * vec4(p_ndc, -1.0, 0.0)).xyz);
    
    float t = 0.05;
    bool hit = false;
    vec4 orbit;
    
    for (int i = 0; i < MaxSteps; i++) {
        float d = map(ro + rd * t, orbit);
        if (d < pow(10.0, Detail)) {
            hit = true;
            break;
        }
        t += d;
        if (t > 40.0) break;
    }

    if (hit) {
        vec3 p = ro + rd * t;
        vec3 n = get_normal(p);
        vec3 col = palette(length(orbit.xyz) * ColorCycle);
        
        vec3 light_dir = normalize(vec3(1.0, 1.0, -1.0));
        float diff = max(dot(n, light_dir), 0.0) * 0.7 + 0.3;
        col *= diff;
        
        vec3 view_dir = normalize(ro - p);
        vec3 half_dir = normalize(light_dir + view_dir);
        float spec = pow(max(dot(n, half_dir), 0.0), 32.0);
        col += vec3(spec * 0.3);
        
        if (FogDensity > 0.0) {
            float fog = 1.0 - exp(-t * FogDensity);
            vec3 sky = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
            col = mix(col, sky, fog);
        }
        
        if (Reflectivity > 0.0) {
            vec3 ref_dir = reflect(rd, n);
            vec2 ref_uv = clamp(SCREEN_UV + ref_dir.xy * 0.05, 0.0, 1.0);
            vec3 reflection = texture(SCREEN_TEXTURE, ref_uv).rgb;
            col = mix(col, reflection, Reflectivity);
        }
        
        ALBEDO = apply_art_controls(col);
        ALPHA = 1.0; // Solid fractal
    }
    else {
        ALPHA = 0.0; // Transparent space for BG image
        ALBEDO = vec3(0.0);
    }
}
