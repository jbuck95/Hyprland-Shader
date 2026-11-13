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
    'Warp Speed 2' by David Hoskins 2015 (adapted for Hyprland transition).
    CC BY-NC-SA 3.0 / Fork of https://www.shadertoy.com/view/Msl3WH
*/
vec3 warpSpeedEffect(vec2 uv, float animTime) {
    float s = 0.0;
    float v = 0.0;
    vec3 col = vec3(0.0);
    vec3 init = vec3(sin(animTime * 0.0032) * 0.3, 0.35 - cos(animTime * 0.005) * 0.3, animTime * 0.002);

    for (int r = 0; r < 60; r++) {
        vec3 p = init + s * vec3(uv, 0.05);
        p.z = fract(p.z);
        for (int i = 0; i < 10; i++) {
            p = abs(p * 2.04) / dot(p, p) - 0.9;
        }
        v += pow(dot(p, p), 0.7) * 0.06;
        col += vec3(v * 0.2 + 0.4, 12.0 - s * 2.0, 0.1 + v * 1.0) * v * 0.00003;
        s += 0.035;
    }
    return tanh(col);
}

void main() {
    float p = progress;
    vec2 uv = v_texcoord;
    float seed_local = seed * 100.0;
    vec2 res = surface_size.x > 1.0 ? surface_size : (resolution.x > 1.0 ? resolution : vec2(1920.0, 1080.0));

    float animTime = (p * 4.0 + seed_local) * 58.0;

    vec2 p_uv = (uv - 0.5) * 2.0;
    p_uv.x *= res.x / res.y;

    vec3 col = clamp(warpSpeedEffect(p_uv, animTime), 0.0, 4.0);
    float energy = clamp(dot(col, vec3(0.299, 0.587, 0.114)), 0.0, 1.0);

    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));

    float dissolve = (1.0 - dist) * 0.9 + energy * 0.4;
    float remain = smoothstep(dissolve + 0.3, dissolve - 0.3, p * 1.35);

    vec2 warp_r = clamp(vec2(dFdx(energy), dFdy(energy)) * 30.0 + 0.5, 0.0, 1.0);
    float distort_strength = p * p * 0.4;
    vec2 warped_uv = uv + (warp_r - 0.5) * distort_strength;

    vec4 screen = texture(tex, warped_uv);

    float edge = smoothstep(0.0, 0.6, remain) * smoothstep(1.0, 0.4, remain);
    vec3 final_rgb = mix(screen.rgb, col, edge * 0.9);

    float tail = smoothstep(1.0, 0.85, p);
    float mask = screen.a * remain * tail;
    fragColor = vec4(final_rgb * mask, mask);
}
