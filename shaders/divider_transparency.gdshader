shader_type canvas_item;

uniform float threshold : hint_range(0.0, 1.0) = 0.85;
uniform vec4 target_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float tolerance : hint_range(0.0, 0.5) = 0.35;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Calculate distance from target color (white/cream)
    float dist = distance(tex_color.rgb, target_color.rgb);
    
    // If pixel is close to white (the background), make transparent
    if (dist < tolerance) {
        tex_color.a = 0.0;
    } else {
        // Blend edge pixels for smoother transition
        tex_color.a = smoothstep(0.0, tolerance, dist) * tex_color.a;
    }
    
    // Boost the gold colors slightly
    tex_color.rgb = mix(tex_color.rgb, tex_color.rgb * 1.2, 0.3);
    
    COLOR = tex_color;
}
