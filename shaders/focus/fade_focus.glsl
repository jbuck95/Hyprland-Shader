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

                vec2 center = vec2(0.5, 0.5);
                float scale = mix(0.95, 1.0, p);
                vec2 scaled_uv = (uv - center) / scale + center;

                vec2 tex_coords = scaled_uv;
                vec4 color = texture(tex, tex_coords.st);

                float alpha = smoothstep(0.0, 0.8, p);

                fragColor = color * alpha;
            
}
