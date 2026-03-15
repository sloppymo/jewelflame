shader_type canvas_item;

// Province Highlight Shader
// This shader highlights a specific province by brightening its pixels
// based on the data map color

uniform vec4 target_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float highlight_intensity : hint_range(0.0, 2.0) = 1.3;
uniform float border_thickness : hint_range(0.0, 5.0) = 2.0;
uniform vec4 border_color : source_color = vec4(1.0, 0.843, 0.0, 1.0); // Gold
uniform bool show_border = true;

// Color tolerance for matching (adjust based on your data map precision)
uniform float color_tolerance : hint_range(0.0, 0.1) = 0.02;

varying vec2 v_uv;

void vertex() {
    v_uv = UV;
}

// Check if two colors match within tolerance
bool colors_match(vec4 a, vec4 b) {
    vec3 diff = abs(a.rgb - b.rgb);
    return diff.r < color_tolerance && diff.g < color_tolerance && diff.b < color_tolerance;
}

// Check if this pixel is at the edge of the target province
bool is_border(sampler2D tex, vec2 uv, vec2 pixel_size) {
    if (!show_border) return false;
    
    vec4 center = texture(tex, uv);
    
    // Sample neighboring pixels
    vec4 left = texture(tex, uv + vec2(-pixel_size.x * border_thickness, 0.0));
    vec4 right = texture(tex, uv + vec2(pixel_size.x * border_thickness, 0.0));
    vec4 up = texture(tex, uv + vec2(0.0, -pixel_size.y * border_thickness));
    vec4 down = texture(tex, uv + vec2(0.0, pixel_size.y * border_thickness));
    
    // This pixel is a border if it's target color but neighbor is not
    bool is_target = colors_match(center, target_color);
    bool neighbor_not_target = !colors_match(left, target_color) || 
                               !colors_match(right, target_color) || 
                               !colors_match(up, target_color) || 
                               !colors_match(down, target_color);
    
    return is_target && neighbor_not_target;
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Check if this pixel matches our target province color
    if (colors_match(tex_color, target_color)) {
        // Apply highlight effect
        vec3 highlighted = tex_color.rgb * highlight_intensity;
        
        // Check for border
        if (is_border(TEXTURE, UV, TEXTURE_PIXEL_SIZE)) {
            COLOR = border_color;
        } else {
            COLOR = vec4(highlighted, tex_color.a);
        }
    } else {
        // Dim non-selected provinces slightly for contrast
        COLOR = vec4(tex_color.rgb * 0.7, tex_color.a);
    }
}
