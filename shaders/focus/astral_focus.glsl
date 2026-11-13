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



/*
    Star Nest by Pablo Roman Andrioli - adapted for a Hyprland transition.
    License: MIT
    Iteration counts reduced (iterations 17->10, volsteps 20->12) since this
    now runs as a per-frame transition instead of a static background.
*/
vec3 astralEffect(vec2 fragCoord, vec2 res, float t) {
    const int ITER = 10;
    const int VOLSTEPS = 12;
    const float formuparam = 0.53;
    const float stepsize = 0.1;
    const float zoom = 0.8;
    const float tile = 0.85;
    const float speed = 0.01;
    const float brightness = 0.0015;
    const float darkmatter = 0.3;
    const float distfading = 0.73;
    const float saturation = 0.85;

    vec2 uv = fragCoord / res - 0.5;
    uv.y *= res.y / res.x;
    vec3 dir = vec3(uv * zoom, 1.0);
    float animTime = t * speed + 0.25;

    float a1 = 0.5;
    float a2 = 0.8;
    mat2 rot1 = mat2(cos(a1), sin(a1), -sin(a1), cos(a1));
    mat2 rot2 = mat2(cos(a2), sin(a2), -sin(a2), cos(a2));
    dir.xz *= rot1;
    dir.xy *= rot2;

    vec3 from = vec3(1.0, 0.5, 0.5);
    from += vec3(animTime * 2.0, animTime, -2.0);
    from.xz *= rot1;
    from.xy *= rot2;

    float s = 0.1, fade = 1.0;
    vec3 v = vec3(0.0);

    for (int r = 0; r < VOLSTEPS; r++) {
        vec3 p = from + s * dir * 0.5;
        p = abs(vec3(tile) - mod(p, vec3(tile * 2.0)));
        float pa, a = pa = 0.0;

        for (int i = 0; i < ITER; i++) {
            p = abs(p) / dot(p, p) - formuparam;
            a += abs(length(p) - pa);
            pa = length(p);
        }

        float dm = max(0.0, darkmatter - a * a * 0.001);
        a *= a * a;

        if (r > 4) fade *= 1.0 - dm;

        v += fade;
        v += vec3(s, s * s, s * s * s * s) * a * brightness * fade;
        fade *= distfading;
        s += stepsize;
    }

    v = mix(vec3(length(v)), v, saturation);
    return v * 0.01;
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

    float t = p * 20.0 + seed_local;

    vec3 col = clamp(astralEffect(uv * res, res, t), 0.0, 4.0);
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
