#!/usr/bin/env python3
import os
import glob
import re
import subprocess
from pathlib import Path

BASE_DIR = Path("/home/jan/own/shader/shaders")
OPEN_DIR = BASE_DIR / "open"
CLOSE_DIR = BASE_DIR / "close"
MOVE_DIR = BASE_DIR / "move"
RESIZE_DIR = BASE_DIR / "resize"
FOCUS_DIR = BASE_DIR / "focus"
WS_DIR = BASE_DIR / "workspace"

for d in [MOVE_DIR, RESIZE_DIR, FOCUS_DIR, WS_DIR]:
    d.mkdir(parents=True, exist_ok=True)

open_files = sorted(glob.glob(str(OPEN_DIR / "*_open.glsl")))

def clean_source(src):
    lines = src.splitlines()
    filtered = []
    for l in lines:
        if l.strip().startswith("#version") or l.strip().startswith("// @"):
            continue
        filtered.append(l)
    return "\n".join(filtered)

def extract_parts(src):
    clean = clean_source(src)
    match = re.search(r'\bvoid\s+main\s*\(\s*\)\s*\{', clean)
    if not match:
        return "", clean
    helpers = clean[:match.start()]
    main_body = clean[match.end():]
    rbrace = main_body.rfind('}')
    if rbrace != -1:
        main_body = main_body[:rbrace]
    
    cleaned_helpers = []
    for line in helpers.splitlines():
        if re.match(r'^\s*(precision|in\s+vec2\s+v_texcoord|out\s+vec4\s+fragColor|uniform\s+sampler2D\s+tex|uniform\s+float\s+progress|uniform\s+float\s+seed|uniform\s+vec2\s+surface_size|uniform\s+vec2\s+resolution)\s*;', line):
            continue
        cleaned_helpers.append(line)
    
    return "\n".join(cleaned_helpers), main_body

def build_focus(name, helpers, main_body):
    adapted_body = re.sub(r'\bprogress\b', '_focus_progress', main_body)
    return f"""#version 320 es
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

{helpers}

void main() {{
    float _focus_p_raw = clamp(progress, 0.0, 1.0);
    float _focus_env = sin(_focus_p_raw * 3.14159265);

    if (_focus_env < 0.001) {{
        fragColor = texture(tex, v_texcoord);
        return;
    }}

    float _focus_progress = 1.0 - _focus_env * 0.85;

{adapted_body}
}}
"""

def build_move(name, helpers, main_body):
    adapted_body = re.sub(r'\bprogress\b', '_move_progress', main_body)
    return f"""#version 320 es
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

{helpers}

void main() {{
    float _move_spd = length(velocity);
    float _move_peak_spd = length(peak_velocity);

    float _move_energy_val = clamp(_move_spd / 8000.0, 0.0, 1.0);
    float _move_tail_energy = clamp(_move_peak_spd / 8000.0, 0.0, 1.0) * (1.0 - settle) * (1.0 - settle);
    float _move_energy = (settle > 0.001 || is_moving < 0.5) ? _move_tail_energy : _move_energy_val;

    if (is_dragging > 0.5) {{
        _move_energy = max(_move_energy, clamp(_move_spd / 1500.0, 0.08, 0.8));
    }}

    if (_move_energy < 0.002) {{
        fragColor = texture(tex, v_texcoord);
        return;
    }}

    vec2 _move_dir = _move_spd > 1.0 ? normalize(velocity) : (_move_peak_spd > 1.0 ? normalize(peak_velocity) : vec2(0.0, -1.0));
    float _move_progress = 1.0 - _move_energy * 0.75;

{adapted_body}
}}
"""

def build_resize(name, helpers, main_body):
    adapted_body = re.sub(r'\bprogress\b', '_resize_progress', main_body)
    return f"""#version 320 es
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

{helpers}

void main() {{
    float _resize_spd = length(size_velocity);
    float _resize_peak_spd = length(peak_size_velocity);

    float _resize_energy_val = clamp(_resize_spd / 1200.0, 0.0, 1.0);
    float _resize_tail_energy = clamp(_resize_peak_spd / 1200.0, 0.0, 1.0) * (1.0 - settle) * (1.0 - settle);
    float _resize_energy = (settle > 0.001 || is_resizing < 0.5) ? _resize_tail_energy : _resize_energy_val;

    if (is_dragging > 0.5) {{
        _resize_energy = max(_resize_energy, clamp(_resize_spd / 400.0, 0.08, 0.8));
    }}

    if (_resize_energy < 0.002) {{
        fragColor = texture(tex, v_texcoord);
        return;
    }}

    vec2 _resize_dir = normalize(size_velocity);
    float _resize_progress = 1.0 - _resize_energy * 0.75;

{adapted_body}
}}
"""

def build_workspace(name, helpers, main_body):
    adapted_body = re.sub(r'\bprogress\b', '_ws_progress', main_body)
    return f"""#version 320 es
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

{helpers}

void main() {{
    float _ws_spd = length(velocity);
    float _ws_peak_spd = length(peak_velocity);

    float _ws_slide_energy = clamp(_ws_spd / 10000.0, 0.0, 1.0);
    float _ws_tail_energy = clamp(_ws_peak_spd / 10000.0, 0.0, 1.0) * (1.0 - settle) * (1.0 - settle);
    float _ws_energy = (settle > 0.001 || is_moving < 0.5) ? _ws_tail_energy : _ws_slide_energy;

    if (_ws_energy < 0.002) {{
        fragColor = texture(tex, v_texcoord);
        return;
    }}

    vec2 _ws_dir = _ws_spd > 1.0 ? normalize(velocity) : (length(move_delta) > 1.0 ? normalize(move_delta) : vec2(1.0, 0.0));
    float _ws_progress = 1.0 - _ws_energy * 0.75;

{adapted_body}
}}
"""

generated_count = 0
for f in open_files:
    base_name = os.path.basename(f).replace("_open.glsl", "")
    with open(f, "r") as fp:
        src = fp.read()
    
    helpers, main_body = extract_parts(src)
    if not main_body.strip():
        continue
    
    focus_src = build_focus(base_name, helpers, main_body)
    move_src = build_move(base_name, helpers, main_body)
    resize_src = build_resize(base_name, helpers, main_body)
    ws_src = build_workspace(base_name, helpers, main_body)
    
    with open(FOCUS_DIR / f"{base_name}_focus.glsl", "w") as out:
        out.write(focus_src)
    with open(MOVE_DIR / f"{base_name}_move.glsl", "w") as out:
        out.write(move_src)
    with open(RESIZE_DIR / f"{base_name}_resize.glsl", "w") as out:
        out.write(resize_src)
    with open(WS_DIR / f"{base_name}_workspace.glsl", "w") as out:
        out.write(ws_src)
        
    generated_count += 4

# Keep the hand-crafted smoke shaders for smoke
for fname in ["smoke_move.glsl", "smoke_resize.glsl", "smoke_focus.glsl", "smoke_workspace.glsl"]:
    src_p = BASE_DIR / fname
    if src_p.exists():
        cat = fname.split("_")[1].replace(".glsl", "")
        dest_p = BASE_DIR / cat / fname
        with open(src_p) as sfp, open(dest_p, "w") as dfp:
            dfp.write(sfp.read())

print(f"Generated {generated_count} shader variants across focus, move, resize, and workspace.")
