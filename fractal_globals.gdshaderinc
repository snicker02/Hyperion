// fractal_globals.gdshaderinc
// Global shader utilities and parameters shared across all fractal shaders
// Note: SCREEN_TEXTURE must be declared in each individual shader, not here

// === RENDERING PARAMETERS ===
group_uniforms Global_Rendering;
uniform float Reflectivity : hint_range(0.0, 1.0) = 0.0;
uniform float FogDensity : hint_range(0.0, 0.2) = 0.0;
uniform int PaletteType : hint_range(0, 3) = 0;
uniform float ColorCycle : hint_range(0.0, 10.0) = 0.15;
uniform float ColorOffset : hint_range(0.0, 1.0) = 0.0;
uniform float OffsetW : hint_range(-5.0, 5.0) = 0.0;

// === SYMMETRY FOLDING ===
group_uniforms Symmetry_Folding;
// Absolute value folds (mirror across origin)
uniform bool F_absX = false;
uniform bool F_absY = false;
uniform bool F_absZ = false;

// Plane symmetry swaps
uniform bool F_X = false;
uniform bool F_Y = false;
uniform bool F_Z = false;

// Symmetry strength (0.5 = full symmetry, 0.0 = no effect)
uniform vec3 SymmetryStrength = vec3(0.5);

// Offset applied before/after folding
uniform vec3 F_offset = vec3(0.0);

// Custom Gradient Colors
uniform vec3 Color1 : source_color = vec3(1.0, 0.0, 0.0);
uniform vec3 Color2 : source_color = vec3(0.0, 1.0, 0.0);
uniform vec3 Color3 : source_color = vec3(0.0, 0.0, 1.0);

uniform float Saturation : hint_range(0.0, 2.0) = 1.0;
uniform float Contrast : hint_range(0.0, 2.0) = 1.0;
uniform float Brightness : hint_range(0.0, 2.0) = 1.0;

// === GLOBAL COLORING ===
group_uniforms Global_Coloring;




vec3 palette(float t) {
    if (PaletteType == 4) { // This MUST match the Index in your PaletteSelector
        float factor = fract(t + ColorOffset);
        if (factor < 0.5) return mix(Color1, Color2, factor * 2.0);
        return mix(Color2, Color3, (factor - 0.5) * 2.0);
    }
    
    // Existing palettes (0, 1, 2, 3)
    vec3 a, b, c, d;
    if (PaletteType == 0) { a = vec3(0.5); b = vec3(0.5); c = vec3(1.0); d = vec3(0.0, 0.33, 0.67); }
    else if (PaletteType == 1) { a = vec3(0.5); b = vec3(0.5); c = vec3(0.5); d = vec3(0.5, 0.2, 0.25); }
    else if (PaletteType == 2) { a = vec3(0.5); b = vec3(0.5); c = vec3(0.8, 0.5, 0.4); d = vec3(0.2, 0.4, 0.2); }
    else if (PaletteType == 3) { a = vec3(0.8, 0.5, 0.4); b = vec3(0.2, 0.4, 0.2); c = vec3(2.0, 1.0, 1.0); d = vec3(0.0, 0.25, 0.25); }
    
    return a + b * cos(6.28318 * (c * t + d + ColorOffset));
}


// === SYMMETRY FOLDING FUNCTION ===
// Applies various geometric symmetries to create complex fractal patterns
// This function modifies the input point 'p' in place
void apply_symmetry(inout vec3 p) {
	// Step 1: Absolute Value Folds (mirror across coordinate planes)
	if (F_absX) p.x = abs(p.x);
	if (F_absY) p.y = abs(p.y);
	if (F_absZ) p.z = abs(p.z);
	
	// Step 2: Plane Symmetry Folding
	// This creates kaleidoscopic effects by conditionally swapping coordinates
	// The formula: t = SymmetryStrength * (diff - abs(diff)) creates a conditional fold
	// When diff > 0: no change, when diff < 0: fold occurs
	
	float t = 0.0;
	p -= F_offset;
	
	if (F_X) {
		t = p.x - p.z;
		t = SymmetryStrength.x * (t - abs(t));
		p.x = p.x - t;
		p.z = p.z + t;
	}
	
	if (F_Y) {
		t = p.x - p.y;
		t = SymmetryStrength.y * (t - abs(t));
		p.x = p.x - t;
		p.y = p.y + t;
	}
	
	if (F_Z) {
		t = p.y - p.z;
		t = SymmetryStrength.z * (t - abs(t));
		p.y = p.y - t;
		p.z = p.z + t;
	}
	
	p += F_offset;
}

// === UTILITY FUNCTIONS ===

// Smooth minimum function for distance field blending
float smin(float a, float b, float k) {
	float h = max(k - abs(a - b), 0.0) / k;
	return min(a, b) - h * h * k * 0.25;
}

// Rotation matrix helper (2D rotation)
mat2 rot2D(float angle) {
	float s = sin(angle);
	float c = cos(angle);
	return mat2(vec2(c, -s), vec2(s, c));
}

// Hash function for procedural variation
float hash(vec3 p) {
	p = fract(p * vec3(443.897, 441.423, 437.195));
	p += dot(p, p.yzx + 19.19);
	return fract((p.x + p.y) * p.z);
}
vec3 apply_art_controls(vec3 color) {
    // Apply Brightness
    color *= Brightness;
    
    // Apply Contrast (centered at 0.5)
    color = (color - 0.5) * Contrast + 0.5;
    
    // Apply Saturation using standard luminance weights
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(luma), color, Saturation);
    
    return clamp(color, 0.0, 1.0);
}