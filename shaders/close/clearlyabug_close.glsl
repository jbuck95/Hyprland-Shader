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
    'Clearly a bug - A Happy Accident' Raymarch Shader
    Inspired by @XorDev, @byt3_m3chanic, @FabriceNeyrat2, @iq, @shane
    Adapted for Hyprland window transition.
*/
vec3 bugEffect(vec2 fragCoord, vec2 res, float animTime) {
    float d = 0.0;
    float z = fract(dot(fragCoord, sin(fragCoord))) - 0.5;
    vec4 o = vec4(0.0);
    vec4 p = vec4(0.0);
    vec4 O = vec4(0.0);

    for (float i = 0.0; i < 50.0; i += 1.0) {
        p = vec4(z * normalize(vec3(fragCoord - 0.5 * res, res.y)), 0.1 * animTime);
        p.z += animTime;
        O = p;

        p.xy *= mat2(cos(2.0 + O.z + vec4(0.0, 11.0, 33.0, 0.0)));
        p.xy *= mat2(cos(O + vec4(0.0, 11.0, 33.0, 0.0)));

        O = (1.0 + sin(0.5 * O.z + length(p - O) + vec4(0.0, 4.0, 3.0, 6.0)))
            / (0.5 + 2.0 * dot(O.xy, O.xy));

        p = abs(fract(p) - 0.5);
        d = abs(min(length(p.xy) - 0.125, min(p.x, p.y) + 1e-3)) + 1e-3;

        o += (O.w / d) * O;
        z += 0.7 * d;
    }

    return tanh(o.rgb / 20000.0);
}

void main() {
    float p = progress;
    vec2 uv = v_texcoord;
    float seed_local = seed * 100.0;
    vec2 res = surface_size.x > 1.0 ? surface_size : (resolution.x > 1.0 ? resolution : vec2(1920.0, 1080.0));

    float animTime = (p * 3.0 + seed_local);

    vec3 col = clamp(bugEffect(uv * res, res, animTime), 0.0, 4.0);
    float energy = clamp(dot(col, vec3(0.299, 0.587, 0.114)), 0.0, 1.0);

    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));

    float dissolve = (1.0 - dist) * 0.9 + energy * 0.4;
    float remain = smoothstep(dissolve + 0.3, dissolve - 0.3, p * 1.35);

    vec2 warp_r = clamp(vec2(dFdx(energy), dFdy(energy)) * 25.0 + 0.5, 0.0, 1.0);
    float distort_strength = p * p * 0.4;
    vec2 warped_uv = uv + (warp_r - 0.5) * distort_strength;

    vec4 screen = texture(tex, warped_uv);

    float edge = smoothstep(0.0, 0.6, remain) * smoothstep(1.0, 0.4, remain);
    vec3 final_rgb = mix(screen.rgb, col, edge * 0.9);

    float tail = smoothstep(1.0, 0.85, p);
    float mask = screen.a * remain * tail;
    fragColor = vec4(final_rgb * mask, mask);
}
