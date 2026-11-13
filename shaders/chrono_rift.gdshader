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
    float aspect = SCREEN_PIXEL_SIZE.y / max(SCREEN_PIXEL_SIZE.x, 0.0001);
    vec2 aspect_dir = vec2(dir.x * aspect, dir.y);
    float dist = length(aspect_dir);

    // Плавная огибающая появления и затухания без резких скачков на границах 0 и 1
    float envelope = smoothstep(0.0, 0.06, rift_progress) * (1.0 - smoothstep(0.55, 1.0, rift_progress));

    // Волна искажения, расходящаяся от центра разлома (в экранных пропорциях — идеальный круг)
    float wave_dist = rift_progress * 0.78;
    float wave = exp(-pow((dist - wave_dist) * 15.0, 2.0));
    float inner_wave = exp(-pow((dist - wave_dist * 0.62) * 22.0, 2.0));

    // Эффект гравитационной линзы / сингулярности в центре
    float center_pull = exp(-dist * 14.0) * (1.0 - smoothstep(0.0, 0.65, rift_progress));

    float total_distort = (wave * distortion_strength + center_pull * 0.04) * envelope;
    vec2 safe_dir = dist > 0.0001 ? (aspect_dir / dist) : vec2(0.0);
    vec2 uv_dir = vec2(safe_dir.x / aspect, safe_dir.y);
    vec2 offset = uv_dir * total_distort;

    // Хроматическая аберрация (разделение спектра RGB при преломлении времени)
    float ca = chromatic_aberration * wave * envelope;
    vec2 uv_r = clamp(uv - offset - uv_dir * ca, vec2(0.001), vec2(0.999));
    vec2 uv_g = clamp(uv - offset, vec2(0.001), vec2(0.999));
    vec2 uv_b = clamp(uv - offset + uv_dir * ca, vec2(0.001), vec2(0.999));

    float r = texture(SCREEN_TEXTURE, uv_r).r;
    float g = texture(SCREEN_TEXTURE, uv_g).g;
    float b = texture(SCREEN_TEXTURE, uv_b).b;

    vec4 scene_color = vec4(r, g, b, 1.0);

    // Квантовое сияние на гребне основной и вторичной волны
    vec4 glow = rift_tint * wave * rift_tint.a * envelope;
    vec4 inner_glow = vec4(0.35, 0.92, 1.0, 0.35) * inner_wave * envelope;

    COLOR = scene_color + glow + inner_glow;
}
