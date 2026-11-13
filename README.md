# HyprWindowShade Shader Collection

60 open/close animation effects for [HyprWindowShade](https://github.com/ManofJELLO/HyprWindowShade),
plus the Lua config that wires them into Hyprland.

**How the plugin works — install, tags, stacking, uniforms, writing shaders — is documented
in the [plugin's README](https://github.com/ManofJELLO/HyprWindowShade#readme).** This page
only covers what lives in *this* repo: which shader goes where, and the config that binds
them. I won't duplicate the plugin docs here; they change and I'd fall out of date again.

https://github.com/user-attachments/assets/809aaa16-e1ff-4237-aca4-2210e1138c60

---

## Layout

```
shaders/
├── open/    <name>_open.glsl    62 files — plays once when a window opens
└── close/   <name>_close.glsl   62 files — plays once as it closes
```

60 effects as pairs: every name in `open/` has its counterpart in `close/`.

Copy `shaders/` to `~/.config/hypr/shaders/` (or anywhere stable — then set `shaderDir` in
`HyprWindowShade.lua`). Window-rule paths must be absolute; `~` is not expanded.

---

## Config

Only `HyprWindowShade.lua` ships here — the other two are part of my Hyprland config, so
adapt them to your own file layout:

| File | Role | In repo |
|---|---|---|
| `HyprWindowShade.lua` | Which shader plays for which app class, and how long. | yes |
| `WindowRules.lua` | Turns that table into `hl.window_rule()` calls. | no |
| `Keybinds.lua` *(optional)* | Runtime toggles. | no |

The helpers in `HyprWindowShade.lua` build the tag strings, so paths and the `_<kind>`
suffix cannot drift apart:

```
+shader_close:/home/jan/.config/hypr/shaders/close/smoke_close.glsl@1.0
└────┬─────┘ └──────────────────────────┬──────────────────────────┘└┬┘
  tag kind                            path                     duration
```

In the table you write just `shader = "smoke"`. A trailing `_close` or `.glsl` is stripped,
so both spellings work.

**Duration.** Both open and close are one-shots: `duration` overrides the shader's own
length, and is capped at 5 s.

### Catch-all rules need `_default`

Hyprland keeps window tags in an alphabetically sorted set, so two rules setting the *same*
tag resolve by whichever **path** sorts later — not by which rule is more specific. A
catch-all `+shader_close:` therefore fights your per-app closes, and renaming a file can flip
the winner.

Append `_default` to fix it. A fallback applies only when the same tag without the suffix is
absent:

```lua
-- every window closes with smoke…
hl.window_rule({ match = { class = ".*" },
                 tag = "+shader_close_default:/path/close/smoke_close.glsl@1.0" })

-- …except kitty
hl.window_rule({ match = { class = "^(kitty)$" },
                 tag = "+shader_close:/path/close/matrix_close.glsl@0.8" })
```

`HyprWindowShade.lua` ships helpers for exactly this (`default_close_anim_tag`, etc.) —
use them for every `M.default_*` entry.

---

## Writing a new shader

The plugin's README has the full rules. What this collection adds on top, and what a new
effect must do to fit in:

1. **`#version 320 es` on line 1**, `// @duration` on line 2 — otherwise the plugin falls
   back to 0.3 s.
2. **Close shaders must reach alpha 0** when `progress` hits 1.0 — the plugin pins the
   snapshot's alpha and your shader owns the disappearance. If your effect only tints or
   wipes, add `// @overlay` and let Hyprland's fade do it.
3. **Premultiply.** `fragColor = vec4(rgb * mask, mask)`, never `vec4(rgb, alpha)` with
   unscaled colour — otherwise a pale rectangle shows through popups and shadows.
4. **Fall back when `surface_size` is degenerate** — don't divide by it unchecked:
   ```glsl
   vec2 res = surface_size.x > 1.0 ? surface_size
            : (resolution.x > 1.0 ? resolution : vec2(1920.0, 1080.0));
   ```
5. **Positional effects need `window_rect`.** During a close, `v_texcoord` spans a
   monitor-sized snapshot, not the window — a radial wipe keys off the *monitor's* centre.
   ```glsl
   vec2 local = (v_texcoord - window_rect.xy) / window_rect.zw;  // 0..1 across the view
   ```

---

## Known gaps

- **`open/` shaders have no `// @duration`.** All 62 declare `progress` but carry no
  directive, so the plugin uses its 0.3 s default and toasts once per edit. The `duration`
  field in `HyprWindowShade.lua` masks this for configured apps; a new open animation without
  one plays for 0.3 s. *Fix: add `// @duration 0.5` under `#version`.*
- **No shader uses `window_rect`.** Four effects (`circle`, `crosshatch`, `heat-melt`,
  `polka-dots-curtain`) are positional and will play from the monitor's centre on close.
- **Case-duplicate sets.** `crumpledWave`/`crumpledwave` and `EmberCircles`/`embercircles`
  exist in both directories. On a case-insensitive filesystem (macOS, Windows) one of each
  pair silently overwrites the other. *Fix: drop the camel-case copies.*

---

## Shader sets

| Shader | Type |
|---|---|
| asciiterminal | Green phosphor ASCII terminal & CRT bloom (ryk) |
| astral | Star Nest volumetric raymarching (Kali) |
| bitmapascii | Bitmapped 5×5 ASCII character matrix (movAX13h) |
| bounce | Elastic bounce transition |
| cfdfluid | Single-pass fluid dynamics advection (flockaroo) |
| circle | Circular iris reveal / wipe *(positional)* |
| clearlyabug | 'Clearly a bug' raymarching fractal (XorDev / community) |
| colour-distance | Color distance threshold wipe |
| crazy-parametric | Parametric wave and curve distortion |
| crosshatch | Crosshatch shading pattern wipe *(positional)* |
| crosswarp | Diagonal cross-warp distortion |
| crumpledwave | Harmonic sine wave silk interference (nasana) |
| directional | Linear directional slide / wipe |
| directional-wipe | Smooth directional gradient wipe |
| dissolve | Organic particulate noise dissolve |
| electricwave | Glowing electric plasma wave caustics (nasana) |
| embercircles | Simplex 3D noise LED pegboard dot matrix |
| fade | Standard linear alpha fadeout |
| fadecolor | Color tint transition fade |
| fire | Procedural flame burning & heat distortion |
| flyeye | Compound lens / fly-eye facet distortion |
| glass-warp | Refractive glass warp distortion |
| glitch | Digital chromatic glitch & scanline displacement |
| happyaccident | Twigl 'happy accident' fragment (CC0) |
| heat-melt | Thermal wave shimmer & melting effect *(positional)* |
| heavenly | Ethereal celestial volumetric light (XorDev) |
| ink-splash | Expanding organic ink splatter |
| inkwell-drop | Concentric fluid ink drops |
| ionize | Ionization electric discharge field (XorDev) |
| liquiddos | Analog liquid CRT / DOS digit matrix (studiobloom) |
| matrix | Digital green matrix code rain |
| moltenbismuth | Iridescent molten bismuth fluid metal (flockaroo) |
| moltenglass | Iterated molten glass refraction & dispersion (mherreshoff) |
| morph | Fluid morphing transition |
| nebula1 | Volumetric deep space nebula (XorDev) |
| overexposure | High-exposure flash overexposure |
| perlin | Perlin noise combustion & burn away |
| pixelate | Dynamic pixelation mosaic |
| pixelfade-wave | Pixelated wave dissolution |
| plasma | Classic retro plasma field |
| plasma-flow | Flowing liquid chromatic plasma |
| polar-function | Polar coordinate spiral rotation |
| polka-dots-curtain | Expanding halftone polka-dot curtain *(positional)* |
| randomsquares | Randomized square tile dissolve |
| ripple | Concentric water ripple displacement |
| smoke | Rising dense particulate smoke |
| snap | Disintegration ash / snap dissolve |
| soft-warp-fade | Smooth warp with progressive fade |
| spilled | CFD vortex advection (flockaroo) |
| starfield | Procedural starfield particle drift (XorDev) |
| static-fade | Analog TV static noise fade |
| synapse | Volumetric gyroid neural glow (anAccount) |
| synapseparametric | Parametric variant of synapse (anAccount) |
| vcrdistort | VCR tape distortion / tracking glitch |
| vhs | Analog CRT distortion & VHS tape tracking glitch |
| voronoi-shatter | Voronoi crystalline glass shatter |
| warpspeed | Warp-speed tunnel (David Hoskins) |
| warpspeed2 | Warp Speed 2 hyperdrive tunnel (David Hoskins) |
| wave-warp | Sine wave displacement warp |
| wobbl | Elastic jello wobble oscillation |

For a jelly wobble of the *geometry* rather than the image, use Hyprland's own
`decoration:wobble` (0.57+) instead — it can deform past the window box, which a fragment
shader never can.

---

## License & credits

MIT — see [LICENSE](LICENSE) for the full text and complete third-party notices.

The collection builds on work by other people. Most of the base shaders and the initial
transitions come from **[liixini/shaders](https://github.com/liixini/shaders)** (MIT,
© liixini), originally ported to niri; I adapted them for Hyprland/Wayland. Everything else,
by source:

| Source | License | Used in |
|---|---|---|
| [liixini/shaders](https://github.com/liixini/shaders) | MIT | base collection, initial transitions |
| [gl-transitions](https://github.com/gl-transitions/gl-transitions) | MIT | `circle`, `ripple` |
| [skwd-wall](https://github.com/skwd-org/skwd-wall) | MIT | `bounce`, `colour-distance`, `crazy-parametric`, `crosshatch`, `crosswarp`, `directional`, `directional-wipe`, `fadecolor`, `flyeye`, `heat-melt`, `ink-splash`, `inkwell-drop`, `morph`, `overexposure`, `perlin`, `pixelfade-wave`, `plasma-flow`, `polar-function`, `polka-dots-curtain`, `randomsquares`, `soft-warp-fade`, `static-fade`, `voronoi-shatter`, `wave-warp` |
| XorDev | — | `heavenly`, `ionize`, `nebula1`, `starfield` |
| Pablo Roman Andrioli (Kali) — Star Nest | MIT | `astral` |
| Matrix Digital Rain | — | `matrix` |
| nasana — CineShader | — | `crumpledwave`, `electricwave` (Electric Wave) |
| David Hoskins — Warp Speed 2 | CC BY-NC-SA 3.0 | `warpspeed`, `warpspeed2` |
| Clearly a bug (Twigl) | CC0 | `clearlyabug`, `happyaccident` |
| EmberCircles (Simplex 3D noise palette) | — | `embercircles` |
| anAccount — Synapse | — | `synapse`, `synapseparametric` |
| florian berger (flockaroo) | CC BY-NC-SA 3.0 | `moltenbismuth`, `spilled`, `cfdfluid` |
| mherreshoff — Molten Glass | — | `moltenglass` |
| VCR Distortion | CC BY-NC-SA 4.0 | `vhs`, `vcrdistort` |
| ryk — ascii terminal | — | `asciiterminal` |
| movAX13h — Bitmap to ASCII | — | `bitmapascii` |
| studiobloom — Liquid DOS | — | `liquiddos` |

Several upstream effects are **CC BY-NC-SA** — check the per-shader notices in
[LICENSE](LICENSE) for the exact scope before redistributing commercially.

Plugin: [ManofJELLO/HyprWindowShade](https://github.com/ManofJELLO/HyprWindowShade).
