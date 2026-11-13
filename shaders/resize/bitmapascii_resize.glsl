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



/*
    'Bitmap to ASCII' by movAX13h (2013-2023)
    Adapted as a bitmapped ASCII transition for Hyprland.
*/

float character(int n, vec2 p) {
    p = floor(p * vec2(-4.0, 4.0) + 2.5);
    if (clamp(p.x, 0.0, 4.0) == p.x) {
        if (clamp(p.y, 0.0, 4.0) == p.y) {
            int a = int(round(p.x) + 5.0 * round(p.y));
            if (((n >> a) & 1) == 1) return 1.0;
        }
    }
    return 0.0;
}

int getCharMask(float gray) {
    int n = 4096;
    if (gray > 0.2) n = 65600;    // :
    if (gray > 0.3) n = 163153;   // *
    if (gray > 0.4) n = 15255086; // o
    if (gray > 0.5) n = 13121101; // &
    if (gray > 0.6) n = 15252014; // 8
    if (gray > 0.7) n = 13195790; // @
    if (gray > 0.8) n = 11512810; // #
    return n;
}


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
    vec2 res = max(surface_size, vec2(1.0));
    float inv_p = 1.0 - p;

    vec2 pix = uv * res;

    // Cell size transitions from 10px down to 1px
    float cell_size = mix(1.0, 10.0, inv_p);
    vec2 cell_uv = floor(pix / cell_size) * cell_size / res;

    vec4 quant_screen = texture(tex, cell_uv);
    vec4 raw_screen = texture(tex, uv);

    float gray = dot(quant_screen.rgb, vec3(0.299, 0.587, 0.114));
    int n = getCharMask(gray);

    vec2 char_p = mod(pix / (cell_size * 0.5), 2.0) - vec2(1.0);
    float char_val = character(n, char_p);

    vec3 ascii_col = quant_screen.rgb * (0.25 + 0.75 * char_val);
    float char_weight = smoothstep(0.75, 0.1, p);
    vec3 final_rgb = mix(raw_screen.rgb, ascii_col, char_weight);

    // Reveal calculation from window center
    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));
    float appear = (1.0 - dist * 0.85) + (gray * 0.35);
    float reveal = smoothstep(appear + 0.35, appear - 0.35, inv_p * 1.5);

    float mask = raw_screen.a * reveal;
    fragColor = vec4(final_rgb * mask, mask);

}
