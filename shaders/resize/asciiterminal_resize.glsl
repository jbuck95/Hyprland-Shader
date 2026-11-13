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
uniform vec2 size_velocity;
uniform vec2 peak_size_velocity;
uniform float is_resizing;
uniform float is_dragging;
uniform float settle;

precision highp float;



/*
    'ascii terminal' by ryk (2015-03-14)
    Adapted as an ASCII terminal phosphor matrix transition for Hyprland.
*/

float termNoise(vec2 p, float t) {
    return sin(p.x * 10.0) * sin(p.y * (3.0 + sin(t / 11.0))) + 0.2;
}

mat2 rotate(float angle) {
    return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

float fbm(vec2 p, float t) {
    p *= 1.1;
    float f = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 3; i++) {
        mat2 modify = rotate((t / 50.0) * float(i * i));
        f += amp * termNoise(p, t);
        p = modify * p;
        p *= 2.0;
        amp /= 2.2;
    }
    return f;
}

float pattern(vec2 p, float t) {
    vec2 q = vec2(fbm(p + vec2(1.0), t), fbm(rotate(0.1 * t) * p + vec2(1.0), t));
    vec2 r = vec2(fbm(rotate(0.1) * q + vec2(0.0), t), fbm(q + vec2(0.0), t));
    return fbm(p + 1.0 * r, t);
}

float digit(vec2 p, float t) {
    vec2 grid = vec2(3.0, 1.0) * 18.0;
    vec2 s = floor(p * grid) / grid;
    p = p * grid;
    float intensity = pattern(s / 10.0, t) * 1.3 - 0.03;
    p = fract(p);
    p *= vec2(1.2, 1.2);
    float x = fract(p.x * 5.0);
    float y = fract((1.0 - p.y) * 5.0);
    int i = int(floor((1.0 - p.y) * 5.0));
    int j = int(floor(p.x * 5.0));
    int n = (i - 2) * (i - 2) + (j - 2) * (j - 2);
    float f = float(n) / 16.0;
    float isOn = (intensity - f > 0.1) ? 1.0 : 0.0;
    return (p.x <= 1.0 && p.y <= 1.0) ? isOn * (0.2 + y * 0.8) * (0.75 + x * 0.25) : 0.0;
}

float onOff(float a, float b, float c, float t) {
    return step(c, sin(t + a * cos(t * b)));
}

float displace(vec2 look, float t) {
    float y = (look.y - mod(t / 4.0, 1.0));
    float window = 1.0 / (1.0 + 50.0 * y * y);
    return (sin(look.y * 20.0 + t) / 80.0) * onOff(4.0, 2.0, 0.8, t) * (1.0 + cos(t * 60.0)) * window;
}

vec3 getTerminalGlow(vec2 p, float t) {
    float bar = mod(p.y + t * 6.0, 1.0) < 0.2 ? 1.4 : 1.0;
    p.x += displace(p, t);
    float middle = digit(p, t);
    float off = 0.003;
    float sum = 0.0;
    for (float i = -1.0; i < 2.0; i += 1.0) {
        for (float j = -1.0; j < 2.0; j += 1.0) {
            sum += digit(p + vec2(off * i, off * j), t);
        }
    }
    return vec3(0.85) * middle + (sum / 10.0) * vec3(0.1, 1.0, 0.2) * bar;
}


void main() {
    float _resize_spd = length(size_velocity);
    float _resize_peak_spd = length(peak_size_velocity);

    float _resize_energy_val = clamp(_resize_spd / 1200.0, 0.0, 1.0);
    float _resize_tail_energy = clamp(_resize_peak_spd / 1200.0, 0.0, 1.0) * (1.0 - settle) * (1.0 - settle);
    float _resize_energy = (settle > 0.001 || is_resizing < 0.5) ? _resize_tail_energy : _resize_energy_val;

    if (is_dragging > 0.5) {
        _resize_energy = max(_resize_energy, clamp(_resize_spd / 400.0, 0.08, 0.8));
    }

    if (_resize_energy < 0.002) {
        fragColor = texture(tex, v_texcoord);
        return;
    }

    vec2 _resize_dir = normalize(size_velocity);
    float _resize_progress = 1.0 - _resize_energy * 0.75;


    float p = _resize_progress;
    vec2 uv = v_texcoord;
    float seed_local = seed * 10.0;
    vec2 res = max(surface_size, vec2(1.0));

    float time = (p * 3.0 + seed_local);
    float inv_p = 1.0 - p;

    vec2 p_uv = uv;
    p_uv.x *= res.x / res.y;

    vec3 term_col = getTerminalGlow(p_uv, time);
    float term_energy = clamp(dot(term_col, vec3(0.299, 0.587, 0.114)), 0.0, 1.0);

    // Quantized ASCII pixel sampling transitioning to clean texture
    vec2 grid = vec2(3.0, 1.0) * 18.0 * vec2(res.x / res.y, 1.0);
    vec2 quant_uv = (floor(uv * grid) + 0.5) / grid;
    vec2 sample_uv = mix(quant_uv, uv, smoothstep(0.3, 1.0, p));

    vec4 screen = texture(tex, sample_uv);

    // Reveal calculation from window center
    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));
    float appear = (1.0 - dist * 0.85) + term_energy * 0.6;
    float reveal = smoothstep(appear + 0.35, appear - 0.35, inv_p * 1.6);

    float edge = smoothstep(0.0, 0.6, reveal) * smoothstep(1.0, 0.3, reveal);
    vec3 final_rgb = mix(screen.rgb, screen.rgb + term_col * 1.2, edge * 0.85);

    float mask = screen.a * reveal;
    fragColor = vec4(final_rgb * mask, mask);

}
