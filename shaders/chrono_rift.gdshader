shader_type canvas_item;

// Шейдер квантового разлома времени и хроматической аберрации
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform vec2 rift_center = vec2(0.5, 0.5);
uniform float rift_progress : hint_range(0.0, 1.0) = 0.0;
uniform float distortion_strength : hint_range(0.0, 0.15) = 0.05;
uniform float chromatic_aberration : hint_range(0.0, 0.08) = 0.025;
uniform vec4 rift_tint : source_color = vec4(0.85, 0.45, 1.0, 0.6);

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 dir = uv - rift_center;
    float dist = length(dir);
    
    // Волна искажения, расходящаяся от центра разлома
    float wave_dist = rift_progress * 0.75;
    float wave = exp(-pow((dist - wave_dist) * 16.0, 2.0));
    
    // Эффект гравитационной линзы / сингулярности в центре
    float center_pull = exp(-dist * 14.0) * (1.0 - rift_progress);
    
    float total_distort = (wave * distortion_strength + center_pull * 0.04) * (1.0 - rift_progress * 0.4);
    vec2 offset = normalize(dir + vec2(0.0001)) * total_distort;
    
    // Хроматическая аберрация (разделение спектра RGB при преломлении времени)
    float ca = chromatic_aberration * wave * (1.0 - rift_progress * 0.5);
    float r = texture(SCREEN_TEXTURE, uv - offset - normalize(dir) * ca).r;
    float g = texture(SCREEN_TEXTURE, uv - offset).g;
    float b = texture(SCREEN_TEXTURE, uv - offset + normalize(dir) * ca).b;
    
    vec4 scene_color = vec4(r, g, b, 1.0);
    
    // Квантовое сияние на гребне волны
    vec4 glow = rift_tint * wave * (1.0 - rift_progress);
    
    COLOR = scene_color + glow;
}
