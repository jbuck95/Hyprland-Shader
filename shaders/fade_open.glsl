#version 320 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;

            
void main() {

                float p = progress;
                vec2 uv = v_texcoord;

                vec2 center = vec2(0.5, 0.5);
                float scale = mix(0.95, 1.0, p);
                vec2 scaled_uv = (uv - center) / scale + center;

                vec2 tex_coords = scaled_uv;
                vec4 color = texture(tex, tex_coords.st);

                float alpha = smoothstep(0.0, 0.8, p);

                fragColor = color * alpha;
            }

