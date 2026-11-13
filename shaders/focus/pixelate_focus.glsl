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
