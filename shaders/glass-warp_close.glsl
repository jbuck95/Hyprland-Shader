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

            float p = 1.0 - progress;
            vec2 uv = v_texcoord;

            float dist = length(uv - 0.5) * 2.0;
            float start_delay = dist * 0.6;
            float t = clamp((p - start_delay) / (1.0 - start_delay), 0.0, 1.0);
            float strong_t = pow(t, 2.5);

            if (p < start_delay) { fragColor = vec4(0.0); return; }

            vec2 center = vec2(0.5);
            vec2 from_center = uv - center;
            vec2 spawn = center + from_center * 0.1;
            vec2 render_pos = mix(spawn, uv, strong_t);

            vec2 tex_coords = render_pos;
            vec4 color = texture(tex, tex_coords.st);

            bool is_window_area = uv.x >= -0.075 && uv.x <= 1.075 &&
                                  uv.y >= -0.075 && uv.y <= 1.075;

            float alpha = mix(1.0, t, pow(dist, 0.5));
            if (!is_window_area) {
                float ring_fade = 1.0 - smoothstep(0.99, 0.999, p);
                alpha *= ring_fade;
            }
            fragColor = color * alpha;

}
