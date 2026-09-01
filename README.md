

# HyprWindowShade — Animation Shaders Setup & Tuning Guide

Supplementary guide for integrating and tuning open and close shader animations in
Hyprland. 

Official plugin documentation: [ManofJELLO/HyprWindowShade](https://github.com/ManofJELLO/HyprWindowShade)
Most of the Shaders are from [liixini](https://github.com/liixini/shaders)


![DEMO:](https://github.com/user-attachments/assets/954fd063-01a7-4192-a307-4fcf95e56ac4)
https://github.com/user-attachments/assets/809aaa16-e1ff-4237-aca4-2210e1138c60

---

## 1. Hyprland Animation Settings

To prevent Hyprland's internal compositor animations from interfering with
HyprWindowShade's snapshot close shaders, configure the animation leaves in
`Settings.lua`:

```lua
-- 1. Geometry: popin 100% keeps window size fixed (prevents shrinking toward center or sliding off-screen during close)
hl.animation({ leaf = "windowsOut", enabled = anim_enabled, speed = 15, bezier = "linear", style = "popin 100%" })

-- 2. Fadeout duration: Must match or exceed the longest shader duration (speed is in deciseconds: 10 = 1.0s, 15 = 1.5s)
hl.animation({ leaf = "fade",    enabled = anim_enabled, speed = 15, bezier = "linear" })
hl.animation({ leaf = "fadeOut", enabled = anim_enabled, speed = 15, bezier = "linear" })
```

> **Why this matters:** If `fadeOut` is left at default values (e.g. `speed = 1` = 100
> ms), Hyprland forces the snapshot opacity to 0 after 0.1 s, cutting off longer
> close animations mid-flight.

---

## 2. HyprWindowShade.lua

Manages all open and close shader bindings in one central table. Shaders can be
referenced by base name without `_open`/`_close` or `.glsl`:

```lua
-- HyprWindowShade — central configuration
-- WindowRules.lua (open animations) and Keybinds.lua (close animation)
-- read from here via require("HyprWindowShade").

local home      = os.getenv("HOME")
local shaderDir = home .. "/.config/hypr/shaders" -- change this accordingly!

local M = {}

--  Open animations (per-app class)
M.open_animations = {
    { name = "open-browsers", class = "^(firefox|zen|chromium)$", shader = "nebula1", duration = 0.5 },
    { name = "open-kitty",    class = "^(kitty)$",                shader = "astral",  duration = 0.8 },
    { name = "open-thunar",   class = "^(thunar)$",               shader = "perlin",  duration = 0.8 },
}

-- Optional: specific close animations per app class 
-- Wenn für eine App hier nichts definiert ist, greift automatisch default_close_animation.
M.close_animations = {
    { name = "close-kitty",    class = "^(kitty)$",                shader = "smoke",  duration = 0.8 },
    { name = "close-browsers", class = "^(firefox|zen|chromium)$", shader = "fire",   duration = 1.0 },
    { name = "close-thunar",   class = "^(thunar)$",               shader = "perlin", duration = 1.0 },
}

--  Global default close animation (gilt für alle Apps ohne eigene Regel) 
M.default_close_animation = {
    shader   = "smoke",
    duration = 1.0,
}

-- ── Helpers: build the tag / path strings ──
function M.open_anim_tag(entry)
    local base = entry.shader:gsub("%.glsl$", ""):gsub("_open$", "")
    local tag = "+shader_open:" .. shaderDir .. "/" .. base .. "_open.glsl"
    if entry.duration then tag = tag .. "@" .. entry.duration end
    return tag
end

function M.close_anim_tag(entry)
    local base = entry.shader:gsub("%.glsl$", ""):gsub("_close$", "")
    local tag = "+shader_close:" .. shaderDir .. "/" .. base .. "_close.glsl"
    if entry.duration then tag = tag .. "@" .. entry.duration end
    return tag
end

function M.default_close_anim_tag(entry)
    local base = entry.shader:gsub("%.glsl$", ""):gsub("_close$", "")
    local tag = "+shader_close_default:" .. shaderDir .. "/" .. base .. "_close.glsl"
    if entry.duration then tag = tag .. "@" .. entry.duration end
    return tag
end

return M
```

---

## 3. Window Rules & Keybind Integration

### Windowrules.lua

Generates `+shader_open:`, `+shader_close:`, and `+shader_close_default:` tags from
the configuration table:

```lua
local shade = require("HyprWindowShade")

--  HyprWindowShade: Open- & Close-Animationen 
-- Einstellungen (Klassen, Shader, Dauer) in HyprWindowShade.lua
for _, anim in ipairs(shade.open_animations or {}) do
    hl.window_rule({
        name = anim.name,
        match = { class = anim.class },
        tag = shade.open_anim_tag(anim),
    })
end

--  HyprWindowShade: Close-Animationen (Spezifische Apps) 
if shade.close_animations then
    for _, anim in ipairs(shade.close_animations) do
        hl.window_rule({
            name = anim.name or "close-anim",
            match = { class = anim.class },
            tag = shade.close_anim_tag(anim),
        })
    end
end

--  HyprWindowShade: global fallback 
local default_close = shade.default_close_animation or shade.close_animation
if default_close then
    hl.window_rule({
        name = "close-anim-default",
        match = { class = ".*" },
        tag = shade.default_close_anim_tag(default_close),
    })
end
```

---

## 4. Shader Development 

All shaders adhere to these requirements:

1. **Premultiplied Alpha Masking:** Hyprland uses Premultiplied Alpha
   (`GL_ONE, GL_ONE_MINUS_SRC_ALPHA`). Any non-zero RGB value outputs additive light onto
   the monitor even if alpha is `0`.
   * **Wrong:** `fragColor = vec4(final_rgb, screen.a) * remain * tail;` *(glows across
     entire screen)*
   * **Correct:**
     ```glsl
     float mask = screen.a * remain * tail;
     fragColor = vec4(final_rgb * mask, mask);
     ```

2. **Resolution Fallback during Close Fadeouts:** When closing, the live window view
   is destroyed and the plugin provides `surface_size = vec2(0, 0)`. Geometry
   calculations must use `resolution` as fallback:
   ```glsl
   uniform vec2 surface_size;
   uniform vec2 resolution;

   vec2 res = surface_size.x > 1.0 ? surface_size : (resolution.x > 1.0 ? resolution : vec2(1920.0, 1080.0));
   ```

3. **Smooth Dissolve Progress Curve:** In dissolve/particle shaders, avoid
   multiplying `p` (progress 0.0 → 1.0) by large factors that make the effect finish
   too early:
   ```glsl
   float dissolve = (1.0 - dist) * 0.9 + energy * 0.4;
   float remain = smoothstep(dissolve + 0.3, dissolve - 0.3, p * 1.35);
   float tail = smoothstep(1.0, 0.85, p);
   ```

4. **Directive Order:** `#version 320 es` must strictly be on **line 1** (GLSL ES
   specification). Upstream `@duration` comment directive follows on **line 2**:
   ```glsl
   #version 320 es
   // @duration 0.5
   precision highp float;
   ```

---

## 5. Included Shader Sets (42 Pairs)

Each set in [`shaders/`](file:///home/jan/own/shader/shaders/) provides paired `_open.glsl` and `_close.glsl` animation variants:


| # | Shader | Variants | Type / Description |
|---|---|---|---|
| 1 | **astral** | `_open` / `_close` | Star Nest volumetric raymarching (cosmic deep space) |
| 2 | **bounce** | `_open` / `_close` | Elastic bounce transition |
| 3 | **circle** | `_open` / `_close` | Circular iris reveal / wipe |
| 4 | **colour-distance** | `_open` / `_close` | Color distance threshold wipe |
| 5 | **crazy-parametric** | `_open` / `_close` | Parametric wave and curve distortion |
| 6 | **crosshatch** | `_open` / `_close` | Crosshatch shading pattern wipe |
| 7 | **crosswarp** | `_open` / `_close` | Diagonal cross-warp distortion |
| 8 | **directional** | `_open` / `_close` | Linear directional slide / wipe |
| 9 | **directional-wipe** | `_open` / `_close` | Smooth directional gradient wipe |
| 10 | **dissolve** | `_open` / `_close` | Organic particulate noise dissolve |
| 11 | **fade** | `_open` / `_close` | Standard linear alpha fadeout |
| 12 | **fadecolor** | `_open` / `_close` | Color tint transition fade |
| 13 | **fire** | `_open` / `_close` | Procedural flame burning & heat distortion |
| 14 | **flyeye** | `_open` / `_close` | Compound lens / fly-eye facet distortion |
| 15 | **glass-warp** | `_open` / `_close` | Refractive glass warp distortion |
| 16 | **glitch** | `_open` / `_close` | Digital chromatic glitch & scanline displacement |
| 17 | **heat-melt** | `_open` / `_close` | Thermal wave shimmer & melting effect |
| 18 | **heavenly** | `_open` / `_close` | Ethereal celestial volumetric light (XorDev) |
| 19 | **ink-splash** | `_open` / `_close` | Expanding organic ink splatter |
| 20 | **inkwell-drop** | `_open` / `_close` | Concentric fluid ink drops |
| 21 | **ionize** | `_open` / `_close` | Ionization electric discharge field (XorDev) |
| 22 | **matrix** | `_open` / `_close` | Digital green matrix code rain |
| 23 | **morph** | `_open` / `_close` | Fluid morphing transition |
| 24 | **nebula1** | `_open` / `_close` | Volumetric deep space nebula (XorDev) |
| 25 | **overexposure** | `_open` / `_close` | High-exposure flash overexposure |
| 26 | **perlin** | `_open` / `_close` | Perlin noise combustion & burn away |
| 27 | **pixelate** | `_open` / `_close` | Dynamic pixelation mosaic |
| 28 | **pixelfade-wave** | `_open` / `_close` | Pixelated wave dissolution |
| 29 | **plasma** | `_open` / `_close` | Classic retro plasma field |
| 30 | **plasma-flow** | `_open` / `_close` | Flowing liquid chromatic plasma |
| 31 | **polar-function** | `_open` / `_close` | Polar coordinate spiral rotation |
| 32 | **polka-dots-curtain** | `_open` / `_close` | Expanding halftone polka-dot curtain |
| 33 | **randomsquares** | `_open` / `_close` | Randomized square tile dissolve |
| 34 | **ripple** | `_open` / `_close` | Concentric water ripple displacement |
| 35 | **smoke** | `_open` / `_close` | Rising dense particulate smoke |
| 36 | **snap** | `_open` / `_close` | Disintegration ash / snap dissolve |
| 37 | **soft-warp-fade** | `_open` / `_close` | Smooth warp with progressive fade |
| 38 | **starfield** | `_open` / `_close` | Procedural starfield particle drift (XorDev) |
| 39 | **static-fade** | `_open` / `_close` | Analog TV static noise fade |
| 40 | **voronoi-shatter** | `_open` / `_close` | Voronoi crystalline glass shatter |
| 41 | **wave-warp** | `_open` / `_close` | Sine wave displacement warp |
| 42 | **wobbl** | `_open` / `_close` | Elastic jello wobble oscillation |

---

## 6. License & Credits

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details and complete third-party attributions.
