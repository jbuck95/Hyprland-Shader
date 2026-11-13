-- HyprWindowShade — central configuration
-- WindowRules.lua (open/close/move/resize/focus/workspace animations)
-- read from here via require("HyprWindowShade").

local home      = os.getenv("HOME")
local shaderDir = home .. "/.config/hypr/shaders"

local M = {}

-- Helper to resolve shader file path (checks subfolder first, falls back to root)
local function resolve_path(category, base)
    return shaderDir .. "/" .. category .. "/" .. base .. "_" .. category .. ".glsl"
end

-- ── Open animations (per-app class) ──
M.open_animations = {
    { name = "open-browsers", class = "^(firefox|zen|chromium)$", shader = "nebula1", duration = 0.5 },
    { name = "open-kitty",    class = "^(kitty)$",                shader = "astral",  duration = 0.8 },
    { name = "open-thunar",   class = "^(thunar)$",               shader = "perlin",  duration = 0.8 },
}

-- ── Specific close animations per app class ──
-- Wenn für eine App hier nichts definiert ist, greift automatisch default_close_animation.
M.close_animations = {
    { name = "close-kitty",    class = "^(kitty)$",                shader = "smoke",  duration = 0.8 },
    { name = "close-browsers", class = "^(firefox|zen|chromium)$", shader = "fire",   duration = 1.0 },
    { name = "close-thunar",   class = "^(thunar)$",               shader = "perlin", duration = 1.0 },
}

-- ── Global default close animation (gilt für alle Apps ohne eigene Regel) ──
M.default_close_animation = {
    shader   = "smoke",
    duration = 1.0,
}

-- ── Move & Drag animations ──
M.move_animations = {
    -- Beispiel: { name = "move-kitty", class = "^(kitty)$", shader = "smoke", settle = 0.4 },
}
M.default_move_animation = {
    shader = "smoke",
    settle = 0.4,
}

-- ── Resize animations ──
M.resize_animations = {
    -- Beispiel: { name = "resize-kitty", class = "^(kitty)$", shader = "smoke", settle = 0.35 },
}
M.default_resize_animation = {
    shader = "smoke",
    settle = 0.35,
}

-- ── Focus pulse animations ──
M.focus_animations = {
    -- Beispiel: { name = "focus-kitty", class = "^(kitty)$", shader = "smoke", duration = 0.45 },
}
M.default_focus_animation = {
    shader   = "smoke",
    duration = 0.45,
}

-- ── Workspace switch animations ──
M.workspace_animations = {
    -- Beispiel: { name = "ws-kitty", class = "^(kitty)$", shader = "smoke", settle = 0.35 },
}
M.default_workspace_animation = nil

-- ── Helpers: build the tag / path strings ──
function M.open_anim_tag(entry)
    local base = entry.shader:gsub("%.glsl$", ""):gsub("_open$", "")
    local tag = "+shader_open:" .. resolve_path("open", base)
    if entry.duration then tag = tag .. "@" .. entry.duration end
    return tag
end

function M.close_anim_tag(entry)
    local base = entry.shader:gsub("%.glsl$", ""):gsub("_close$", "")
    local tag = "+shader_close:" .. resolve_path("close", base)
    if entry.duration then tag = tag .. "@" .. entry.duration end
    return tag
end

function M.default_close_anim_tag(entry)
    local base = entry.shader:gsub("%.glsl$", ""):gsub("_close$", "")
    local tag = "+shader_close_default:" .. resolve_path("close", base)
    if entry.duration then tag = tag .. "@" .. entry.duration end
    return tag
end

function M.move_anim_tag(entry)
    local base = entry.shader:gsub("%.glsl$", ""):gsub("_move$", "")
    local tag = "+shader_move:" .. resolve_path("move", base)
    if entry.settle then tag = tag .. "@" .. entry.settle end
    return tag
end

function M.default_move_anim_tag(entry)
    local base = entry.shader:gsub("%.glsl$", ""):gsub("_move$", "")
    local tag = "+shader_move_default:" .. resolve_path("move", base)
    if entry.settle then tag = tag .. "@" .. entry.settle end
    return tag
end

function M.resize_anim_tag(entry)
    local base = entry.shader:gsub("%.glsl$", ""):gsub("_resize$", "")
    local tag = "+shader_resize:" .. resolve_path("resize", base)
    if entry.settle then tag = tag .. "@" .. entry.settle end
    return tag
end

function M.default_resize_anim_tag(entry)
    local base = entry.shader:gsub("%.glsl$", ""):gsub("_resize$", "")
    local tag = "+shader_resize_default:" .. resolve_path("resize", base)
    if entry.settle then tag = tag .. "@" .. entry.settle end
    return tag
end

function M.focus_anim_tag(entry)
    local base = entry.shader:gsub("%.glsl$", ""):gsub("_focus$", "")
    local tag = "+shader_focus:" .. resolve_path("focus", base)
    if entry.duration then tag = tag .. "@" .. entry.duration end
    return tag
end

function M.default_focus_anim_tag(entry)
    local base = entry.shader:gsub("%.glsl$", ""):gsub("_focus$", "")
    local tag = "+shader_focus_default:" .. resolve_path("focus", base)
    if entry.duration then tag = tag .. "@" .. entry.duration end
    return tag
end

function M.workspace_anim_tag(entry)
    local base = entry.shader:gsub("%.glsl$", ""):gsub("_workspace$", "")
    local tag = "+shader_workspace:" .. resolve_path("workspace", base)
    if entry.settle then tag = tag .. "@" .. entry.settle end
    return tag
end

function M.default_workspace_anim_tag(entry)
    local base = entry.shader:gsub("%.glsl$", ""):gsub("_workspace$", "")
    local tag = "+shader_workspace_default:" .. resolve_path("workspace", base)
    if entry.settle then tag = tag .. "@" .. entry.settle end
    return tag
end

return M
