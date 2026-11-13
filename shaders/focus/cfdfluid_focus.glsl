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
    'Spilled' (Single Pass CFD) by florian berger (flockaroo) - 2016
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported (CC BY-NC-SA 3.0)
    Source: https://www.shadertoy.com/view/MsGSRd
    Adapted as a fluid advection transition for Hyprland.
*/

// Multi-scale rotational curl swirl field
vec2 getCurlVelocity(vec2 p, float time) {
    vec2 v = vec2(0.0);
    float scale = 1.0;
    for (int l = 0; l < 6; l++) {
        float ang = time * (0.2 + float(l) * 0.1) + float(l) * 1.2566;
        mat2 rot_mat = mat2(cos(ang), sin(ang), -sin(ang), cos(ang));
        vec2 q = rot_mat * p * scale;

        vec2 curl_v = vec2(
            sin(q.y * 1.5 + cos(q.x * 1.2 + time * 0.5)),
            -cos(q.x * 1.5 + sin(q.y * 1.2 + time * 0.5))
        );

        v += curl_v / scale;
        scale *= 1.85;
    }

    // Central rotational motor current
    vec2 scr = p;
    v += (0.05 * scr.yx * vec2(1.0, -1.0)) / (dot(scr, scr) * 4.0 + 0.1);
    return v;
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
    float seed_local = seed * 10.0;
    vec2 res = max(surface_size, vec2(1.0));

    float time = p * 3.0 + seed_local;

    // Window-centered coordinates scaled by aspect ratio
    vec2 p_uv = (uv - 0.5) * 2.0;
    p_uv.x *= res.x / res.y;

    vec2 v = getCurlVelocity(p_uv, time);
    float fluid_intensity = length(v);

    // Advection displacement of window texture
    float distort_strength = (1.0 - p) * (1.0 - p) * 0.35;
    vec2 warped_uv = uv + v * distort_strength;

    // Reveal curve along fluid vortices
    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));
    float appear = (1.0 - dist * 0.85) + (fluid_intensity - 0.5) * 0.35;
    float reveal = smoothstep(appear + 0.35, appear - 0.35, (1.0 - p) * 1.6);

    vec4 screen = texture(tex, warped_uv);

    // Liquid surface shimmer and edge reflection
    vec3 fluid_tint = mix(vec3(0.9, 0.95, 1.05), vec3(1.1, 0.9, 0.75), sin(fluid_intensity * 4.0 + time) * 0.5 + 0.5);
    float edge = smoothstep(0.0, 0.6, reveal) * smoothstep(1.0, 0.3, reveal);
    vec3 final_rgb = mix(screen.rgb, screen.rgb * fluid_tint, edge * 0.7);

    float mask = screen.a * reveal;
    fragColor = vec4(final_rgb * mask, mask);

}
