#version 320 es
// @settle 0.35
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float time;
uniform float seed;
uniform vec2 surface_size;
uniform vec2 resolution;
uniform vec2 size_velocity;
uniform vec2 peak_size_velocity;
uniform float is_resizing;
uniform float is_dragging;
uniform float settle;

precision highp float;



            

void main() {
    float _resize_spd = length(size_velocity);
    float _resize_peak_spd = length(peak_size_velocity);

    float _resize_energy_val = clamp(_resize_spd / 1200.0, 0.0, 1.0);
    float _resize_tail_energy = clamp(_resize_peak_spd / 1200.0, 0.0, 1.0) * (1.0 - settle) * (1.0 - settle);
    float _resize_energy = (settle > 0.001 || is_resizing < 0.5) ? _resize_tail_energy : _resize_energy_val;

    if (is_dragging > 0.5) {
        _resize_energy = max(_resize_energy, clamp(_resize_spd / 400.0, 0.08, 0.8));
    }

    if (_resize_energy < 0.002) {
        fragColor = texture(tex, v_texcoord);
        return;
    }

    vec2 _resize_dir = normalize(size_velocity);
    float _resize_progress = 1.0 - _resize_energy * 0.75;



                float p = _resize_progress;
                vec2 uv = v_texcoord;

                float pixel_size = mix(0.06 + seed * 0.04, 0.0005, p * p);
                vec2 pixelated_uv = floor(uv / pixel_size) * pixel_size + pixel_size * 0.5;

                vec2 tex_coords = pixelated_uv;
                vec4 color = texture(tex, tex_coords.st);

                vec2 center = uv - 0.5;
                float dist = length(center);
                float reveal = smoothstep(0.0, 0.5, p) * smoothstep(dist * 0.8, dist * 0.8 - 0.3, (1.0 - p));

                float alpha = smoothstep(0.0, 0.3, p);
                fragColor = color * alpha;
            
}
