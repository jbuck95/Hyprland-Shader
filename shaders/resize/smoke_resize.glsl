#version 320 es
// @settle 0.35
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float time;
uniform float seed;
uniform vec2 surface_size;
uniform vec2 size_velocity;
uniform vec2 peak_size_velocity;
uniform float is_resizing;
uniform float is_dragging;
uniform float settle;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 4; i++) {
        v += amp * noise(p);
        p *= 2.0;
        amp *= 0.5;
    }
    return v;
}

vec2 warp_r;
float warpedFbm(vec2 p, float t) {
    vec2 q = vec2(fbm(p + vec2(0.0, 0.0)),
                  fbm(p + vec2(5.2, 1.3)));

    warp_r = vec2(fbm(p + 6.0 * q + vec2(1.7, 9.2) + 0.25 * t),
                  fbm(p + 6.0 * q + vec2(8.3, 2.8) + 0.22 * t));

    return fbm(p + 5.0 * warp_r);
}

void main() {
    float spd = length(size_velocity);
    float peak_spd = length(peak_size_velocity);

    float resize_energy = clamp(spd / 1200.0, 0.0, 1.0);
    float tail_energy = clamp(peak_spd / 1200.0, 0.0, 1.0) * (1.0 - settle) * (1.0 - settle);
    float energy = (settle > 0.001 || is_resizing < 0.5) ? tail_energy : resize_energy;

    if (is_dragging > 0.5) {
        energy = max(energy, clamp(spd / 400.0, 0.08, 0.8));
    }

    if (energy < 0.002) {
        fragColor = texture(tex, v_texcoord);
        return;
    }

    vec2 uv = v_texcoord;
    vec2 rel = uv - 0.5;
    float dist_from_center = length(rel);

    float t = time * 3.0 + seed * 43.0;
    float fluid = warpedFbm(uv * 2.5, t);

    // Billowing smoke wave expanding / contracting from center
    vec2 dir = normalize(size_velocity);
    vec2 offset = (warp_r - 0.5) * (energy * 0.06 * (dist_from_center + 0.2)) + dir * (energy * 0.025 * (fluid - 0.5));
    vec2 sampled_uv = clamp(uv + offset, 0.0, 1.0);

    vec4 color = texture(tex, sampled_uv);
    float smoke_tint = 1.0 - (fluid * energy * 0.1);
    color.rgb *= smoke_tint;

    fragColor = color;
}
