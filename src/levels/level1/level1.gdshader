shader_type canvas_item;

uniform sampler2D noise_texture : repeat_enable;
uniform vec4 fog_color : source_color = vec4(1.0);
uniform float density : hint_range(0.0, 1.0) = 0.5;
uniform float speed : hint_range(0.0, 0.2) = 0.02;

void fragment() {
    // Scroll coordinates over time
    vec2 uv1 = UV + TIME * speed;
    vec2 uv2 = UV - TIME * speed * 0.5;
    
    // Sample noise and combine layers
    float noise1 = texture(noise_texture, uv1).r;
    float noise2 = texture(noise_texture, uv2).r;
    float fog_value = (noise1 + noise2) * 0.5;
    
    // Apply density
    float alpha = clamp(fog_value * density, 0.0, 1.0);
    
    COLOR = vec4(fog_color.rgb, alpha);
}
