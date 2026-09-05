#version 320 es
// @duration 0.6
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;
uniform vec2 resolution;

/*
    'VCR Distortion' (CC BY-NC-SA 4.0)
    Adapted as an analog CRT / VHS transition shader for Hyprland.
*/

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float vhsNoise(vec2 p) {
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u * u * (3.0 - 2.0 * u);
    float res = mix(
        mix(hash21(ip), hash21(ip + vec2(1.0, 0.0)), u.x),
        mix(hash21(ip + vec2(0.0, 1.0)), hash21(ip + vec2(1.0, 1.0)), u.x),
        u.y
    );
    return res * res;
}

float onOff(float a, float b, float c, float t) {
    return step(c, sin(t + a * cos(t * b)));
}

float ramp(float y, float start, float end) {
    float inside = step(start, y) - step(end, y);
    float fact = (y - start) / max(end - start, 0.001) * inside;
    return (1.0 - fact) * inside;
}

float stripes(vec2 uv, float t) {
    float noi = vhsNoise(vec2(1.0, 2.0 * cos(t)) * t * 8.0 + uv * vec2(0.5, 1.0) * 8.0 + vec2(1.0, 3.0));
    return ramp(mod(uv.y * 4.0 + t * 0.5 + sin(t + sin(t * 0.63)), 1.0), 0.5, 0.6) * noi;
}

vec2 screenDistort(vec2 uv, float strength) {
    vec2 u = uv - 0.5;
    u = u * (1.0 + 2.0 * u.x * u.x * u.y * u.y * strength);
    return u + 0.5;
}

void main() {
    float p = progress;
    vec2 uv = v_texcoord;
    float seed_local = seed * 10.0;
    vec2 res = surface_size.x > 1.0 ? surface_size : (resolution.x > 1.0 ? resolution : vec2(1920.0, 1080.0));

    float time = p * 4.0 + seed_local;

    // Analog barrel distortion increases as window closes
    vec2 distorted_uv = screenDistort(uv, p * 1.2);

    // VCR jitter and tracking displacement
    vec2 look = distorted_uv;
    float track_win = 1.0 / (1.0 + 20.0 * pow(look.y - mod(time * 0.25, 1.0), 2.0));
    float h_jitter = (sin(look.y * 10.0 + time) / 50.0) * onOff(4.0, 4.0, 0.3, time) * (1.0 + cos(time * 80.0)) * track_win * p;
    float v_shift = 0.35 * onOff(2.0, 3.0, 0.9, time) * (sin(time) * sin(time * 20.0) + (0.5 + 0.1 * sin(time * 200.0) * cos(time))) * p;

    look.x += h_jitter;
    look.y = mod(look.y + v_shift, 1.0);

    // Chromatic aberration on tape tracking edge
    float chrom_shift = p * 0.02 * (1.0 + track_win * 2.5);
    vec4 screen;
    screen.r = texture(tex, clamp(look + vec2(chrom_shift, 0.0), 0.0, 1.0)).r;
    screen.g = texture(tex, clamp(look, 0.0, 1.0)).g;
    screen.b = texture(tex, clamp(look - vec2(chrom_shift, 0.0), 0.0, 1.0)).b;
    screen.a = texture(tex, clamp(look, 0.0, 1.0)).a;

    // Scanlines & tape noise
    float tape_stripes = stripes(look, time) * p;
    float tape_noise = vhsNoise(look * 16.0 + vec2(time * 15.0)) * 0.45 * p;
    float scanline = (12.0 + mod(look.y * res.y * 0.5 + time * 5.0, 1.0)) / 13.0;

    // Vignette
    float vigAmt = 2.5 * p;
    float vignette = clamp((1.0 - vigAmt * pow(look.y - 0.5, 2.0)) * (1.0 - vigAmt * pow(look.x - 0.5, 2.0)), 0.0, 1.0);

    vec3 final_rgb = (screen.rgb + vec3(tape_stripes) + vec3(tape_noise)) * scanline * vignette;

    // CRT power-off collapse curve
    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));
    float dissolve = (1.0 - dist * 0.85) + (1.0 - tape_stripes) * 0.3;
    float remain = smoothstep(dissolve + 0.3, dissolve - 0.3, p * 1.35);

    float tail = smoothstep(1.0, 0.85, p);
    float mask = screen.a * remain * tail;
    fragColor = vec4(final_rgb * mask, mask);
}
