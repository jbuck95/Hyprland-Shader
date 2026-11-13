#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;

/*
    'EmberCircles' - Simplex 3D Noise LED Dot Matrix
    Noise based on: https://www.shadertoy.com/view/XsX3zB (nikat / Stefan Gustavson)
    Palette modulation: Blue / Red / Dark cycle
    Adapted for Hyprland window transitions.
*/
#define BLUE vec3(0.447, 0.392, 0.650)
#define RED  vec3(0.918, 0.259, 0.329)
#define DARK vec3(0.122, 0.153, 0.196)
#define COUNT 32.0

vec3 random3(vec3 c) {
    float j = 4096.0 * sin(dot(c, vec3(17.0, 59.4, 15.0)));
    vec3 r;
    r.z = fract(512.0 * j); j *= 0.125;
    r.x = fract(512.0 * j); j *= 0.125;
    r.y = fract(512.0 * j);
    return r - 0.5;
}

const float F3 = 0.3333333;
const float G3 = 0.1666667;

float simplex3d(vec3 p) {
    vec3 s = floor(p + dot(p, vec3(F3)));
    vec3 x = p - s + dot(s, vec3(G3));
    vec3 e = step(vec3(0.0), x - x.yzx);
    vec3 i1 = e * (1.0 - e.zxy);
    vec3 i2 = 1.0 - e.zxy * (1.0 - e);
    vec3 x1 = x - i1 + G3;
    vec3 x2 = x - i2 + 2.0 * G3;
    vec3 x3 = x - 1.0 + 3.0 * G3;
    vec4 w, d;
    w.x = dot(x, x);
    w.y = dot(x1, x1);
    w.z = dot(x2, x2);
    w.w = dot(x3, x3);
    w = max(0.6 - w, 0.0);
    d.x = dot(random3(s), x);
    d.y = dot(random3(s + i1), x1);
    d.z = dot(random3(s + i2), x2);
    d.w = dot(random3(s + 1.0), x3);
    w *= w; w *= w; d *= w;
    return dot(d, vec4(52.0));
}

const mat3 rot1 = mat3(-0.37, 0.36, 0.85, -0.14, -0.93, 0.34, 0.92, 0.01, 0.4);
const mat3 rot2 = mat3(-0.55, -0.39, 0.74, 0.33, -0.91, -0.24, 0.77, 0.12, 0.63);

float noise3d(vec3 m) {
    return 0.5 + 0.5 * (0.5333333 * simplex3d(m * rot1) + 0.2666667 * simplex3d(2.0 * m * rot2));
}

vec3 prepalette(in float t) {
    t = mod(t, 1.0);
    float pt = smoothstep(0.0, 1.0, mod(t, 0.25) * 4.0);
    if (t < 0.25) return mix(DARK, BLUE, pt);
    if (t < 0.5)  return mix(BLUE, DARK, pt);
    if (t < 0.75) return mix(DARK, RED, pt);
    return mix(RED, DARK, pt);
}

void main() {
    float p = progress;
    vec2 uv = v_texcoord;
    float seed_local = seed * 10.0;
    vec2 res = max(surface_size, vec2(1.0));

    float time = p * 1.5 + seed_local;
    vec2 grid_uv = uv;
    grid_uv.x *= res.x / res.y;

    vec2 cell = floor(grid_uv * COUNT) / COUNT;
    float height = noise3d(vec3(cell * 1.5, time));
    height = floor(height * 20.0) / 20.0;

    vec3 dot_col = prepalette(height * 3.0 + time);

    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));

    float appear = (1.0 - dist * 0.9) + (1.0 - height) * 0.6;
    float reveal = smoothstep(appear + 0.3, appear - 0.3, (1.0 - p) * 1.6);

    vec2 frac_uv = mod(grid_uv * COUNT, 1.0) - 0.5;
    float dot_radius = clamp((1.0 - p) * 0.45, 0.0, 0.45);
    float in_dot = 1.0 - smoothstep(dot_radius - 0.05, dot_radius + 0.02, length(frac_uv));

    vec2 grid_count = COUNT * vec2(res.x / res.y, 1.0);
    vec2 quant_uv = (floor(uv * grid_count) + 0.5) / grid_count;
    vec2 sample_uv = mix(quant_uv, uv, smoothstep(0.3, 1.0, p));

    vec4 screen = texture(tex, sample_uv);

    float edge = smoothstep(0.0, 0.5, reveal) * smoothstep(1.0, 0.3, reveal);
    vec3 final_rgb = mix(screen.rgb, dot_col * in_dot + screen.rgb * 0.3, edge * 0.8);

    float mask = screen.a * reveal;
    fragColor = vec4(final_rgb * mask, mask);
}
