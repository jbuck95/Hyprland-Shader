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
    float p = progress;
    vec2 uv = v_texcoord;
    vec2 res = surface_size.x > 1.0 ? surface_size : (resolution.x > 1.0 ? resolution : vec2(1920.0, 1080.0));

    vec2 pix = uv * res;

    // Cell size transitions from 1px up to 10px
    float cell_size = mix(1.0, 10.0, p);
    vec2 cell_uv = floor(pix / cell_size) * cell_size / res;

    vec4 quant_screen = texture(tex, cell_uv);
    vec4 raw_screen = texture(tex, uv);

    float gray = dot(quant_screen.rgb, vec3(0.299, 0.587, 0.114));
    int n = getCharMask(gray);

    vec2 char_p = mod(pix / (cell_size * 0.5), 2.0) - vec2(1.0);
    float char_val = character(n, char_p);

    vec3 ascii_col = quant_screen.rgb * (0.25 + 0.75 * char_val);
    float char_weight = smoothstep(0.1, 0.75, p);
    vec3 final_rgb = mix(raw_screen.rgb, ascii_col, char_weight);

    // Dissolve calculation
    vec2 center = uv - 0.5;
    float dist = length(center * vec2(1.0, 0.7));
    float dissolve = (1.0 - dist * 0.85) + (gray * 0.35);
    float remain = smoothstep(dissolve + 0.3, dissolve - 0.3, p * 1.35);

    float tail = smoothstep(1.0, 0.85, p);
    float mask = raw_screen.a * remain * tail;
    fragColor = vec4(final_rgb * mask, mask);
}
