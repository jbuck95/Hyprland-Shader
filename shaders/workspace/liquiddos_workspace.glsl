#version 320 es
// @settle 0.35
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float time;
uniform float seed;
uniform vec2 surface_size;
uniform vec2 resolution;
uniform vec2 velocity;
uniform vec2 peak_velocity;
uniform vec2 move_delta;
uniform float is_moving;
uniform float settle;

precision highp float;



/*
    'Liquid DOS' by studiobloom (2023-10-12)
    https://www.shadertoy.com/view/dtffRN
    Adapted as an analog liquid CRT/DOS matrix transition for Hyprland.
*/

const vec2 gridScale = vec2(3.0, 5.0);
const float patternMultiplier = 1.3;
const float threshold = 0.3;
const vec3 brightness = vec3(0.9);

float timeVal;

float ldos_noise(vec2 p) {
    return sin(p.x * 10.0) * sin(p.y * (3.0 + sin(timeVal / 11.0))) + 0.2; 
}

mat2 ldos_rotate(float angle) {
    return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

float ldos_fbm(vec2 p, float luminance) {
    p *= 1.0 + luminance;
    float f = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 3; i++) {
        mat2 modify = ldos_rotate((timeVal + luminance * 10.0) / 50.0 * float(i * i));
        f += amp * ldos_noise(p);
        p = modify * p;
        p *= 2.0;
        amp /= 2.2;
    }
    return f;
}

float ldos_pattern(vec2 p, out vec2 q, out vec2 r, float luminance) {
    q = vec2(ldos_fbm(p + vec2(1.0), luminance), ldos_fbm(ldos_rotate(0.1 * timeVal) * p + vec2(1.0), luminance));
    r = vec2(ldos_fbm(ldos_rotate(0.1) * q + vec2(0.0), luminance), ldos_fbm(q + vec2(0.0), luminance));
    return ldos_fbm(p + 1.0 * r, luminance);
}

float ldos_digit(vec2 p, float luminance) {
    vec2 grid = gridScale * 15.0;
    vec2 s = floor(p * grid) / grid;
    p = p * grid;
    vec2 q, r;
    float intensity = ldos_pattern(s / 10.0, q, r, luminance) * patternMultiplier - 0.03;
    p = fract(p);
    p *= vec2(1.2, 1.2);
    float x = fract(p.x * 5.0);
    float y = fract((1.0 - p.y) * 5.0);
    int i = int(floor((1.0 - p.y) * 5.0));
    int j = int(floor(p.x * 5.0));
    int n = (i - 2) * (i - 2) + (j - 2) * (j - 2);
    float f = float(n) / 16.0;
    float isOn = (intensity - f > threshold) ? 1.0 : 0.0;
    return (p.x <= 1.0 && p.y <= 1.0) ? isOn * (0.2 + y * 4.0 / 5.0) * (0.75 + x / 4.0) : 0.0;
}

vec3 ldos_getColor(vec2 p, float luminance) {
    float bar = mod(p.y + timeVal * 20.0, 1.0) < 0.2 ? 1.4 : 1.0;
    float middle = ldos_digit(p, luminance);
    float off = 0.002;
    float sum = 0.0;
    for (float i = -1.0; i <= 1.0; i += 1.0) {
        for (float j = -1.0; j <= 1.0; j += 1.0) {
            sum += ldos_digit(p + vec2(off * i, off * j), luminance);
        }
    }
    return brightness * middle + (sum / 10.0) * vec3(0.0, 1.0, 0.0) * bar;
}


void main() {
    float _ws_spd = length(velocity);
    float _ws_peak_spd = length(peak_velocity);

    float _ws_slide_energy = clamp(_ws_spd / 10000.0, 0.0, 1.0);
    float _ws_tail_energy = clamp(_ws_peak_spd / 10000.0, 0.0, 1.0) * (1.0 - settle) * (1.0 - settle);
    float _ws_energy = (settle > 0.001 || is_moving < 0.5) ? _ws_tail_energy : _ws_slide_energy;

    if (_ws_energy < 0.002) {
        fragColor = texture(tex, v_texcoord);
        return;
    }

    vec2 _ws_dir = _ws_spd > 1.0 ? normalize(velocity) : (length(move_delta) > 1.0 ? normalize(move_delta) : vec2(1.0, 0.0));
    float _ws_progress = 1.0 - _ws_energy * 0.75;


    float p = _ws_progress;
    vec2 uv = v_texcoord;
    float inv_p = 1.0 - p;

    timeVal = (seed * 13.37 + p * 4.0) / 3.0;

    // Slight CRT liquid warp on opening
    vec2 warped_uv = uv + vec2(
        sin(uv.y * 20.0 + timeVal * 5.0) * 0.005 * inv_p,
        cos(uv.x * 20.0 + timeVal * 5.0) * 0.005 * inv_p
    );
    warped_uv = clamp(warped_uv, 0.0, 1.0);

    vec4 screen = texture(tex, warped_uv);
    float luminance = dot(screen.rgb, vec3(0.299, 0.587, 0.114));

    vec3 dosColor = ldos_getColor(uv, luminance);
    vec3 phosphorColor = dosColor + screen.rgb * dosColor * 1.5;

    // Transition from DOS CRT matrix green into the full window color
    float dos_mix = smoothstep(0.7, 0.05, p);
    vec3 final_rgb = mix(screen.rgb, phosphorColor, dos_mix);

    // Boot wipe / scanline reveal
    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.75));
    float reveal = smoothstep(1.2 * inv_p + 0.15, 1.2 * inv_p - 0.15, (1.0 - dist) + luminance * 0.25);

    float mask = screen.a * reveal;
    fragColor = vec4(final_rgb * mask, mask);

}
