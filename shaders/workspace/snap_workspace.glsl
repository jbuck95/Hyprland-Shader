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
uniform vec2 velocity;
uniform vec2 peak_velocity;
uniform vec2 move_delta;
uniform float is_moving;
uniform float settle;

precision highp float;



            float hash(vec2 p) {
                return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
            }

            

void main() {
    float _ws_spd = length(velocity);
    float _ws_peak_spd = length(peak_velocity);

    float _ws_slide_energy = clamp(_ws_spd / 10000.0, 0.0, 1.0);
    float _ws_tail_energy = clamp(_ws_peak_spd / 10000.0, 0.0, 1.0) * (1.0 - settle) * (1.0 - settle);
    float _ws_energy = (settle > 0.001 || is_moving < 0.5) ? _ws_tail_energy : _ws_slide_energy;

    if (_ws_energy < 0.002) {
        fragColor = texture(tex, v_texcoord);
        return;
    }

    vec2 _ws_dir = _ws_spd > 1.0 ? normalize(velocity) : (length(move_delta) > 1.0 ? normalize(move_delta) : vec2(1.0, 0.0));
    float _ws_progress = 1.0 - _ws_energy * 0.75;



                float p = _ws_progress;
                vec2 uv = v_texcoord;
                float seed_local = seed * 100.0;
                float rp = 1.0 - p;

                float num_layers = 10.0;
                float pixel_layer = floor(hash(floor(uv * surface_size) + seed_local) * num_layers);

                vec4 result = vec4(0.0);
                vec2 target = vec2(1.0, 0.0);

                for (int i = 0; i < 10; i++) {
                    float layer = float(i);
                    float layer_delay = layer * 0.06;
                    float layer_p = clamp((rp - layer_delay) / (1.0 - layer_delay * 0.5), 0.0, 1.0);

                    float t = layer_p * layer_p;

                    float layer_alpha = 1.0 - smoothstep(0.3, 0.85, layer_p);

                    float lh = hash(vec2(layer + 0.5, seed_local));
                    vec2 layer_target = target + vec2(-0.08 + lh * 0.16, -0.04 + lh * 0.08);

                    float converge = t * 0.92;
                    vec2 sample_uv = (uv - layer_target * converge) / (1.0 - converge);

                    vec2 tex_coords = sample_uv;
                    vec4 color = texture(tex, tex_coords.st);

                    float belongs = step(abs(pixel_layer - layer), 0.5);
                    result += color * belongs * layer_alpha;
                }

                float initial_form = smoothstep(0.0, 0.05, rp);
                result.a *= mix(1.0, 0.0, initial_form);
                vec2 base_tex = uv;
                vec4 base_color = texture(tex, base_tex.st);
                float base_alpha = 1.0 - smoothstep(0.0, 0.1, rp);

                fragColor = base_color * base_alpha + result * (1.0 - base_alpha);
            
}
