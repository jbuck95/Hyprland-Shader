-- HyprWindowShade — central configuration
-- WindowRules.lua (open animations) and Keybinds.lua (close animation)
-- read from here via require("HyprWindowShade").

local home      = os.getenv("HOME")
local shaderDir = home .. "/.config/hypr/shaders"

local M = {}

-- ── Open animations (per-app class) ──
M.open_animations = {
    { name = "open-browsers", class = "^(firefox|zen|chromium)$", shader = "nebula1", duration = 0.5 },
    { name = "open-kitty",    class = "^(kitty)$", shader = "astral",  duration = 0.8 },
    { name = "open-thunar",    class = "^(thunar)$", shader = "perlin",  duration = 0.8 },
}

-- ── specific close animations per app class ──
-- Wenn für eine App hier nichts definiert ist, greift automatisch default_close_animation.
M.close_animations = {
     { name = "close-kitty",    class = "^(kitty)$",                shader = "smoke", duration = 0.8 },
     { name = "close-browsers", class = "^(firefox|zen|chromium)$", shader = "fire",   duration = 1.0 },
     { name = "close-thunar", class = "^(thunar)$", shader = "perlin",   duration = 1.0 },
}

-- ── Global default close animation (gilt für alle Apps ohne eigene Regel) ──
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
