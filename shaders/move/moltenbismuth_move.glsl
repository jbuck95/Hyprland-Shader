#version 320 es
// @settle 0.4
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float time;
uniform float seed;
uniform vec2 surface_size;
uniform vec2 resolution;
uniform vec2 velocity;
uniform vec2 peak_velocity;
uniform float is_moving;
uniform float is_dragging;
uniform float settle;

precision highp float;



/*
    'molten bismuth' by florian berger (flockaroo) - 2019
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported (CC BY-NC-SA 3.0)
    Adapted as a procedural single-pass liquid metal transition for Hyprland.
*/

// Multi-scale rotational swirl flow (analytical CFD approximation)
vec2 fluidFlow(vec2 p, float t) {
    vec2 v = vec2(0.0);
    float scale = 1.0;
    for (int i = 0; i < 5; i++) {
        float a = t * (0.3 + float(i) * 0.15) + float(i) * 1.618;
        mat2 r = mat2(cos(a), sin(a), -sin(a), cos(a));
        vec2 q = r * p * scale;
        v += vec2(sin(q.y + cos(q.x * 0.8 + t)), cos(q.x - sin(q.y * 0.8 + t))) / scale;
        scale *= 1.75;
    }
    return v * 0.18;
}

// Bismuth iridescent oxidation palette
vec3 bismuthPalette(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (vec3(1.0, 1.0, 1.0) * t + vec3(0.0, 0.33, 0.67)));
}

// Procedural metallic environment reflection
vec3 proceduralEnv(vec3 dir) {
    float up = dir.y * 0.5 + 0.5;
    vec3 sky = mix(vec3(0.12, 0.16, 0.22), vec3(0.95, 0.90, 0.80), pow(up, 2.0));
    vec3 ground = vec3(0.06, 0.05, 0.04);
    vec3 col = mix(ground, sky, smoothstep(0.35, 0.65, up));
    col += vec3(0.4, 0.6, 0.9) * pow(max(0.0, sin(dir.x * 4.0 + dir.z * 3.0)), 6.0);
    return col;
}


void main() {
    float _move_spd = length(velocity);
    float _move_peak_spd = length(peak_velocity);

    float _move_energy_val = clamp(_move_spd / 8000.0, 0.0, 1.0);
    float _move_tail_energy = clamp(_move_peak_spd / 8000.0, 0.0, 1.0) * (1.0 - settle) * (1.0 - settle);
    float _move_energy = (settle > 0.001 || is_moving < 0.5) ? _move_tail_energy : _move_energy_val;

    if (is_dragging > 0.5) {
        _move_energy = max(_move_energy, clamp(_move_spd / 1500.0, 0.08, 0.8));
    }

    if (_move_energy < 0.002) {
        fragColor = texture(tex, v_texcoord);
        return;
    }

    vec2 _move_dir = _move_spd > 1.0 ? normalize(velocity) : (_move_peak_spd > 1.0 ? normalize(peak_velocity) : vec2(0.0, -1.0));
    float _move_progress = 1.0 - _move_energy * 0.75;


    float p = _move_progress;
    vec2 uv = v_texcoord;
    float seed_local = seed * 10.0;
    vec2 res = max(surface_size, vec2(1.0));

    float time = p * 2.5 + seed_local;

    // Window-centered aspect-scaled coordinates
    vec2 p_uv = (uv - 0.5) * 2.0;
    p_uv.x *= res.x / res.y;

    vec2 flow = fluidFlow(p_uv * 2.0, time);
    vec2 fluid_pos = p_uv * 2.0 + flow;

    // Liquid height field
    float h = sin(fluid_pos.x * 2.5 + sin(fluid_pos.y * 2.0 + time)) * cos(fluid_pos.y * 2.5 + cos(fluid_pos.x * 2.0 + time));
    h += 0.5 * sin(fluid_pos.x * 5.0 - time * 1.5) * cos(fluid_pos.y * 5.0 + time * 1.2);

    // Surface normal from screen-space derivatives
    vec3 n = normalize(vec3(-dFdx(h) * 12.0, -dFdy(h) * 12.0, 1.0));

    // Environmental reflection
    vec3 view_dir = normalize(vec3(p_uv, -1.0));
    vec3 R = reflect(view_dir, n);
    vec3 refl = proceduralEnv(R);

    // Bismuth iridescent thin-film color + reflection
    float bism_coord = length(flow) * 1.8 + h * 0.5 + time * 0.2;
    vec3 base_col = bismuthPalette(bism_coord);
    vec3 bismuth_metal = mix(base_col * refl * 1.8, refl, 0.4);

    // Window texture displacement along liquid vortices
    float distort_strength = (1.0 - p) * (1.0 - p) * 0.45;
    vec2 warped_uv = uv + flow * distort_strength;

    // Solidification / reveal curve
    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));
    float appear = (1.0 - dist * 0.9) + (h * 0.4);
    float reveal = smoothstep(appear + 0.35, appear - 0.35, (1.0 - p) * 1.6);

    vec4 screen = texture(tex, warped_uv);

    float edge = smoothstep(0.0, 0.5, reveal) * smoothstep(1.0, 0.3, reveal);
    vec3 final_rgb = mix(screen.rgb, bismuth_metal, edge * 0.88);

    float mask = screen.a * reveal;
    fragColor = vec4(final_rgb * mask, mask);

}
