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
    float p = progress;
    vec2 uv = v_texcoord;

    timeVal = (seed * 13.37 + p * 4.0) / 3.0;

    // Liquid melt and scanline shift on close
    vec2 warped_uv = uv + vec2(
        sin(uv.y * 25.0 + timeVal * 8.0) * 0.02 * p,
        p * p * 0.1 + cos(uv.x * 25.0 + timeVal * 8.0) * 0.01 * p
    );
    warped_uv = clamp(warped_uv, 0.0, 1.0);

    vec4 screen = texture(tex, warped_uv);
    float luminance = dot(screen.rgb, vec3(0.299, 0.587, 0.114));

    vec3 dosColor = ldos_getColor(uv, luminance);
    vec3 phosphorColor = dosColor + screen.rgb * dosColor * 1.5;

    // Melt into phosphor digits
    float dos_mix = smoothstep(0.1, 0.6, p);
    vec3 final_rgb = mix(screen.rgb, phosphorColor, dos_mix);

    // Fade out and dissolve downwards
    float tail = 1.0 - smoothstep(0.7, 1.0, p);
    float remain = smoothstep(1.0, 0.0, p + (1.0 - luminance) * 0.3 * p);

    float mask = screen.a * remain * tail;
    fragColor = vec4(final_rgb * mask, mask);
}
