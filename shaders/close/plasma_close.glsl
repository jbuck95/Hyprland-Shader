#version 320 es
// @duration 0.5
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;
uniform vec2 resolution;

vec3 hsv2rgb(float h, float s, float v) {
    return mix(vec3(1.0), clamp(abs(fract(h + vec3(3.0, 2.0, 1.0) / 3.0) * 6.0 - 3.0) - 1.0, 0.0, 1.0), s) * v;
}

// plasma field from "PLASMA SHIT V12", returns an RGB color for a given
// uv/time; luminance of the result is used elsewhere as a noise-like scalar.
vec3 plasma(vec2 uv, float t) {
    vec2 p = uv - 0.5;
    float fff = sin(length(p * 5.0) + t);

    vec2 vp = vec2(100.0, 100.0);
    vec2 p0 = p * vp;
    vec2 hvp = vp * 0.5;
    vec2 p1d = vec2(cos(t / 13.5), sin(t / 13.0)) * hvp - p0;
    vec2 p2d = vec2(sin(-t / 6.2), cos(-t / 6.0)) * hvp - p0;
    vec2 p3d = vec2(cos(-t / 3.7), cos(t / 3.5)) * hvp - p0;

    float sum = 0.5 + 0.5 * (
        cos(length(p1d) / 2.0) +
        cos(length(p2d) / 4.0) +
        sin(length(p3d) / 1.9) * sin(p3d.x / 1.2) * sin(p3d.y / 7.6));

    float ff = 0.5 + sin(t * 0.3 + fract(sum) * 6.28318) * 0.5;
    ff *= 0.15;

    return hsv2rgb(fff + ff + t * 0.3, 0.8, 0.8);
}

void main() {

    float p = progress;
    vec2 uv = v_texcoord;
    float seed_local = seed * 100.0;

    float t = p * 8.0 + seed_local;

    vec3 plasmaCol = plasma(uv * 1.3 + seed_local * 0.05, t);
    float energy = dot(plasmaCol, vec3(0.299, 0.587, 0.114));

    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));

    float dissolve = (1.0 - dist) * 0.9 + energy * 0.4;
    float remain = smoothstep(dissolve + 0.3, dissolve - 0.3, p * 1.35);

    vec2 warp_r = vec2(
        energy,
        dot(plasma(uv * 1.3 + seed_local * 0.05 + vec2(4.2, 1.7), t + 2.3), vec3(0.299, 0.587, 0.114))
    );

    float distort_strength = p * p * 0.5;
    vec2 warped_uv = uv + (warp_r - 0.5) * distort_strength;

    vec4 color = texture(tex, warped_uv);

    // plasma-colored glow right at the dissolve edge
    float edge = smoothstep(0.0, 0.6, remain) * smoothstep(1.0, 0.4, remain);
    vec3 final_rgb = mix(color.rgb, plasmaCol, edge * 0.9);

    float tail = smoothstep(1.0, 0.85, p);
    float mask = color.a * remain * tail;
    fragColor = vec4(final_rgb * mask, mask);
}
