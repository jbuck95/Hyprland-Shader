#version 320 es
// @duration 0.45
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float time;
uniform float progress;
uniform float seed;
uniform vec2 surface_size;
uniform vec2 resolution;

precision highp float;



// Adapted procedural starfield (XorDev-style one-liner).
// Iteration count reduced (19 -> 12) for use as a per-frame transition.
vec3 starfieldEffect(vec2 fragCoord, vec2 res, float t0) {
    vec2 v = res;
    vec2 u = 0.2 * (fragCoord + fragCoord - v) / v.y;

    vec4 z = vec4(1.0, 2.0, 3.0, 0.0);
    vec4 o = z;

    float a = 0.5;
    float t = t0;
    for (float i = 0.0; i < 12.0; i += 1.0) {
        o += (1.0 + cos(z + t)) / length((1.0 + i * dot(v, v)) * sin(1.5 * u / (0.5 - dot(u, u)) - 9.0 * u.yx + t));
        v = cos(t + 1.0 - 7.0 * u * pow(a + 0.03 * i, i)) - 5.0 * u;
        t += 1.0;
        u += tanh(40.0 * dot(u *= mat2(cos(i + 0.02 * t - vec4(0.0, 11.0, 33.0, 0.0))), u) * cos(100.0 * u.yx + t)) / 200.0
           + 0.2 * a * u
           + cos(4.0 / exp(dot(o, o) / 100.0) + t) / 300.0;
    }

    o = 25.6 / (min(o, 13.0) + 164.0 / o) - dot(u, u) / 250.0;
    return o.rgb;
}


void main() {
    float _focus_p_raw = clamp(progress, 0.0, 1.0);
    float _focus_env = sin(_focus_p_raw * 3.14159265);

    if (_focus_env < 0.001) {
        fragColor = texture(tex, v_texcoord);
        return;
    }

    float _focus_progress = 1.0 - _focus_env * 0.85;


    float p = _focus_progress;
    vec2 uv = v_texcoord;
    float seed_local = seed * 100.0;
    vec2 res = max(surface_size, vec2(1.0));

    float t = p * 4.0 + seed_local;

    vec3 col = clamp(starfieldEffect(uv * res, res, t), 0.0, 4.0);
    float energy = clamp(dot(col, vec3(0.299, 0.587, 0.114)), 0.0, 1.0);

    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));

    float appear = (1.0 - dist * 1.2) + (1.0 - energy) * 0.7;
    float reveal = smoothstep(appear + 0.5, appear - 0.5, (1.0 - p) * 1.8);

    vec2 warp_r = clamp(vec2(dFdx(energy), dFdy(energy)) * 30.0 + 0.5, 0.0, 1.0);
    float distort_strength = (1.0 - p) * (1.0 - p) * 0.35;
    vec2 warped_uv = uv + (warp_r - 0.5) * distort_strength;

    vec4 screen = texture(tex, warped_uv);

    float edge = smoothstep(0.0, 0.6, reveal) * smoothstep(1.0, 0.4, reveal);
    vec3 final_rgb = mix(screen.rgb, col, edge * 0.9);

    fragColor = vec4(final_rgb, screen.a) * reveal;

}
