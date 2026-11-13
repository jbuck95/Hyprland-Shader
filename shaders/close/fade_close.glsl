#version 320 es
// @duration 0.5
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

uniform float progress;
uniform float seed;
uniform vec2 surface_size;
uniform vec2 resolution;

            
void main() {

                float p = progress;
                vec2 uv = v_texcoord;

                vec2 center = vec2(0.5, 0.5);
                float scale = mix(1.0, 0.95, p);
                vec2 scaled_uv = (uv - center) / scale + center;

                vec2 tex_coords = scaled_uv;
                vec4 color = texture(tex, tex_coords.st);

                float alpha = smoothstep(1.0, 0.2, p);

                fragColor = color * alpha;
            }

