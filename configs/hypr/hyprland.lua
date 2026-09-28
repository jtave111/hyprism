-- =====================================================================
--  Hyprland config shipped by Hyprism (Lua, Hyprland >= 0.56)
--
--  You rarely need to edit this file. Hyprism writes the parts you
--  customize and this file only reads them:
--
--    ~/.config/hypr/colors.lua    palette            (hyprism palette)
--    ~/.config/hypr/look.lua      look & behavior    (hyprism / visualconf)
--    ~/.config/hypr/monitors.lua  displays           (hyprism-settings → Display)
--    ~/.config/hyprism/autostart  startup apps       (hyprism-settings → Startup)
--
--  Every file has a fallback, so this config works before Hyprism ever
--  runs. Live changes go through `hyprctl eval '<lua>'` — with a Lua config
--  `hyprctl keyword` and raw `hyprctl dispatch <name>` do not work.
-- =====================================================================

local HOME     = os.getenv("HOME")
local mod      = "SUPER"
local term     = os.getenv("TERMINAL") or "kitty"
local launcher = "hyprism-launcher"

local function exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

-- Loads a generated Lua table. Missing keys fall back to the defaults, so a
-- file written by an older Hyprism never produces nil on reload.
local function load(path, fallback)
    local ok, val = pcall(dofile, HOME .. path)
    if ok and type(val) == "table" then
        for key, default in pairs(fallback) do
            if val[key] == nil then val[key] = default end
        end
        return val
    end
    return fallback
end

local c = load("/.config/hypr/colors.lua", {
    bg = "#111111", bg2 = "#1a1a1a", fg = "#d0d0d0", dim = "#7a7a7a",
    line = "#333333", accent = "#5e81ac", accent_lit = "#88c0d0",
    sel = "#3b4252", on_accent = "#ffffff",
})

local L = load("/.config/hypr/look.lua", {
    border = 2, rounding = 6, rounding_power = 2.0,
    gaps_in = 4, gaps_out = 8,
    blur = false, blur_size = 6, blur_passes = 2,
    blur_xray = false, blur_brightness = 1.0, blur_vibrancy = 0.17,
    shadow = false, shadow_range = 14, shadow_power = 3,
    shadow_scale = 1.0, shadow_offset_x = 0, shadow_offset_y = 2,
    active_opacity = 1.0, inactive_opacity = 1.0,
    fullscreen_opacity = 1.0, dim_inactive = false, dim_strength = 0.10,
    anim = "rapida",
    float_all = false, win_size = "50% 50%",
    layout = "dwindle", snap = true, snap_gap = 10,
    snap_overlap = false, snap_respect_gaps = true,
    resize_border = true, focus_activate = false, preserve_split = true,
    workspace_count = 9, workspace_persistent = false,
    workspace_smart_gaps = false, workspace_layout = "global",
    workspace_gap = 0, workspace_wrap = false, workspace_backforth = true,
    kb_layout = "us", kb_variant = "",
    follow_mouse = 1, mouse_sensitivity = 0, mouse_scroll = 1.0,
    mouse_natural = false, touch_natural = true, touch_tap = true,
    touch_dwt = true, touch_scroll = 1.0, gesture_fingers = 3,
    cursor_theme = "Adwaita", cursor_size = 24,
    cursor_hide_key = false, cursor_timeout = 0,
    bar_enabled = true,
})

local WORKSPACE_COUNT = math.max(1, math.min(10,
    math.floor(tonumber(L.workspace_count) or 9)))

local function rgba(hex) return "rgba(" .. hex:gsub("#", "") .. "ff)" end

-- Virtual machines (VirtualBox, QEMU/KVM, VMware) often draw no hardware
-- cursor: detect them and fall back to a software cursor.
local IS_VM = (function()
    for _, f in ipairs({ "/sys/class/dmi/id/sys_vendor", "/sys/class/dmi/id/product_name" }) do
        local h = io.open(f, "r")
        if h then
            local s = (h:read("*l") or ""):lower()
            h:close()
            for _, k in ipairs({ "innotek", "virtualbox", "qemu", "kvm", "vmware" }) do
                if s:find(k, 1, true) then return true end
            end
        end
    end
    return false
end)()

-----------------
---- DISPLAYS ---
-----------------
-- hyprism-settings → Display writes monitors.lua (resolution, refresh rate,
-- scale, position, rotation, VRR). Any display not listed uses its highest
-- refresh rate — without this, many monitors come up at 60 Hz.
local monitors = (function()
    local ok, v = pcall(dofile, HOME .. "/.config/hypr/monitors.lua")
    if ok and type(v) == "table" then return v end
    return {}
end)()
for _, m in ipairs(monitors) do
    if type(m) == "table" and m.output then hl.monitor(m) end
end
-- VMs advertise a tiny mode (800x600@60.3) as the "highest refresh", so they
-- follow the window size instead.
hl.monitor({ output = "", mode = IS_VM and "preferred" or "highrr", position = "auto", scale = IS_VM and 1 or "auto" })

--------------------
---- ENVIRONMENT ---
--------------------
-- Hyprism's programs live in ~/.local/bin, which a fresh login session does
-- not have on PATH: without this, launcher/power/settings binds find nothing.
local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
if not path:find(HOME .. "/.local/bin", 1, true) then
    hl.env("PATH", HOME .. "/.local/bin:" .. path)
end
hl.env("XCURSOR_THEME", L.cursor_theme)
hl.env("XCURSOR_SIZE", tostring(L.cursor_size))
hl.env("HYPRCURSOR_THEME", L.cursor_theme)
hl.env("HYPRCURSOR_SIZE", tostring(L.cursor_size))
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- NVIDIA: hardware video decode (libva-nvidia-driver) and NVIDIA GLX.
-- Only applied when the proprietary/open NVIDIA driver is loaded.
if exists("/proc/driver/nvidia/version") then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("NVD_BACKEND", "direct")
end

-------------------
---- APPEARANCE ---
-------------------
hl.config({
    general = {
        gaps_in         = L.gaps_in,
        gaps_out        = L.gaps_out,
        gaps_workspaces = L.workspace_gap,
        border_size     = L.border,
        col = {
            active_border   = rgba(c.border_active   or c.accent),
            inactive_border = rgba(c.border_inactive or c.line),
        },
        layout        = L.layout,
        allow_tearing = false,
        -- drag any window edge to resize, with a comfortable grab area
        resize_on_border        = L.resize_border,
        hover_icon_on_border    = true,
        extend_border_grab_area = 22,
        snap = {
            enabled        = L.snap,
            window_gap     = L.snap_gap,
            monitor_gap    = L.snap_gap,
            border_overlap = L.snap_overlap,
            respect_gaps   = L.snap_respect_gaps,
        },
    },

    decoration = {
        rounding           = L.rounding,
        rounding_power     = L.rounding_power,
        active_opacity     = L.active_opacity,
        inactive_opacity   = L.inactive_opacity,
        fullscreen_opacity = L.fullscreen_opacity,
        dim_inactive       = L.dim_inactive,
        dim_strength       = L.dim_strength,
        blur = {
            enabled    = L.blur,
            size       = L.blur_size,
            passes     = L.blur_passes,
            xray       = L.blur_xray,
            brightness = L.blur_brightness,
            vibrancy   = L.blur_vibrancy,
        },
        shadow = {
            enabled      = L.shadow,
            range        = L.shadow_range,
            render_power = L.shadow_power,
            scale        = L.shadow_scale,
            offset       = { L.shadow_offset_x, L.shadow_offset_y },
            color        = rgba(c.bg),
        },
    },

    input = {
        kb_layout      = L.kb_layout,
        kb_variant     = L.kb_variant,
        follow_mouse   = L.follow_mouse,
        sensitivity    = L.mouse_sensitivity,
        scroll_factor  = L.mouse_scroll,
        natural_scroll = L.mouse_natural,
        touchpad = {
            natural_scroll       = L.touch_natural,
            disable_while_typing = L.touch_dwt,
            tap_to_click         = L.touch_tap,
            scroll_factor        = L.touch_scroll,
        },
    },

    dwindle = { preserve_split = L.preserve_split },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        focus_on_activate        = L.focus_activate,
    },

    cursor = {
        sync_gsettings_theme = true,
        hide_on_key_press    = L.cursor_hide_key,
        inactive_timeout     = L.cursor_timeout,
        no_hardware_cursors  = IS_VM and 1 or nil,
    },

    animations = {
        enabled              = L.anim ~= "desligada" and L.anim ~= "nenhuma",
        workspace_wraparound = L.workspace_wrap,
    },

    binds = { workspace_back_and_forth = L.workspace_backforth },
})

-- Animation presets (hyprism animations fast|balanced|smooth|elastic|off).
-- Preset keys stay in Portuguese: they are values stored by Hyprism.
hl.curve("hyprthemeLinear",   { type = "bezier", points = { { 0.00, 0.00 }, { 1.00, 1.00 } } })
hl.curve("hyprthemeQuick",    { type = "bezier", points = { { 0.15, 0.00 }, { 0.10, 1.00 } } })
hl.curve("hyprthemeBalanced", { type = "bezier", points = { { 0.23, 1.00 }, { 0.32, 1.00 } } })
hl.curve("hyprthemeSmooth",   { type = "bezier", points = { { 0.33, 0.00 }, { 0.20, 1.00 } } })
hl.curve("hyprthemeElastic",  { type = "spring", mass = 1.0, stiffness = 220.0, dampening = 22.0 })

local animation_presets = {
    rapida = {
        { leaf = "global",     speed = 8.5, bezier = "hyprthemeQuick" },
        { leaf = "windowsIn",  speed = 6.0, bezier = "hyprthemeQuick", style = "popin 94%" },
        { leaf = "windowsOut", speed = 5.0, bezier = "hyprthemeQuick", style = "popin 94%" },
        { leaf = "fade",       speed = 7.0, bezier = "hyprthemeQuick" },
        { leaf = "layersIn",   speed = 6.0, bezier = "hyprthemeQuick", style = "fade" },
        { leaf = "layersOut",  speed = 6.0, bezier = "hyprthemeQuick", style = "fade" },
        { leaf = "workspaces", speed = 7.0, bezier = "hyprthemeQuick", style = "slide" },
    },
    equilibrada = {
        { leaf = "global",     speed = 6.0, bezier = "hyprthemeBalanced" },
        { leaf = "windowsIn",  speed = 4.8, bezier = "hyprthemeBalanced", style = "popin 90%" },
        { leaf = "windowsOut", speed = 4.2, bezier = "hyprthemeBalanced", style = "popin 90%" },
        { leaf = "fade",       speed = 5.0, bezier = "hyprthemeBalanced" },
        { leaf = "layersIn",   speed = 4.5, bezier = "hyprthemeBalanced", style = "fade" },
        { leaf = "layersOut",  speed = 4.2, bezier = "hyprthemeBalanced", style = "fade" },
        { leaf = "workspaces", speed = 4.8, bezier = "hyprthemeBalanced", style = "slide" },
    },
    suave = {
        { leaf = "global",     speed = 3.5, bezier = "hyprthemeSmooth" },
        { leaf = "windowsIn",  speed = 3.0, bezier = "hyprthemeSmooth", style = "popin 88%" },
        { leaf = "windowsOut", speed = 2.8, bezier = "hyprthemeSmooth", style = "popin 88%" },
        { leaf = "fade",       speed = 3.2, bezier = "hyprthemeSmooth" },
        { leaf = "layersIn",   speed = 3.0, bezier = "hyprthemeSmooth", style = "fade" },
        { leaf = "layersOut",  speed = 2.8, bezier = "hyprthemeSmooth", style = "fade" },
        { leaf = "workspaces", speed = 3.0, bezier = "hyprthemeSmooth", style = "slide" },
    },
    elastica = {
        { leaf = "global",     speed = 5.0, bezier = "hyprthemeBalanced" },
        { leaf = "windows",    speed = 5.0, spring = "hyprthemeElastic" },
        { leaf = "windowsIn",  speed = 4.5, spring = "hyprthemeElastic", style = "popin 90%" },
        { leaf = "windowsOut", speed = 4.0, bezier = "hyprthemeBalanced", style = "popin 90%" },
        { leaf = "fade",       speed = 4.5, bezier = "hyprthemeBalanced" },
        { leaf = "layersIn",   speed = 4.0, bezier = "hyprthemeBalanced", style = "fade" },
        { leaf = "layersOut",  speed = 3.8, bezier = "hyprthemeBalanced", style = "fade" },
        { leaf = "workspaces", speed = 4.5, spring = "hyprthemeElastic", style = "slide" },
    },
}

if L.anim == "desligada" or L.anim == "nenhuma" then
    hl.animation({ leaf = "global", enabled = false, speed = 1.0, bezier = "hyprthemeLinear" })
else
    for _, a in ipairs(animation_presets[L.anim] or animation_presets.rapida) do
        local spec = { leaf = a.leaf, enabled = true, speed = a.speed, style = a.style }
        if a.spring then spec.spring = a.spring else spec.bezier = a.bezier end
        hl.animation(spec)
    end
end

if L.workspace_persistent or L.workspace_layout ~= "global" then
    for i = 1, WORKSPACE_COUNT do
        local rule = { workspace = tostring(i) }
        if L.workspace_persistent then rule.persistent = true end
        if L.workspace_layout ~= "global" then rule.layout = L.workspace_layout end
        hl.workspace_rule(rule)
    end
end

-- Smart gaps: no gaps/border with a single tiled window
if L.workspace_smart_gaps then
    hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
    hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
    hl.window_rule({ name = "smart-gaps-single", match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 })
    hl.window_rule({ name = "smart-gaps-first",  match = { float = false, workspace = "f[1]" },   border_size = 0, rounding = 0 })
end

-- Touchpad: 3-finger horizontal swipe switches workspace
hl.gesture({ fingers = L.gesture_fingers, direction = "horizontal", action = "workspace" })

------------------
---- AUTOSTART ---
------------------
hl.on("hyprland.start", function()
    -- wallpaper (swaybg, or mpvpaper for animated files) — path in ~/.config/hypr/wallpaper
    hl.exec_cmd("set-wallpaper \"$(cat $HOME/.config/hypr/wallpaper 2>/dev/null)\"")
    if L.bar_enabled then hl.exec_cmd("waybar") end
    hl.exec_cmd("dunst")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprctl setcursor " .. L.cursor_theme .. " " .. tostring(L.cursor_size))
    -- right-click menu on the empty desktop
    hl.exec_cmd("hyprism-desktop")

    -- first polkit agent found (password prompts for pkexec: SDDM theme, time zone, cleanup…)
    for _, agent in ipairs({
        "/usr/lib/hyprpolkitagent/hyprpolkitagent",
        "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
        "/usr/lib/polkit-kde-authentication-agent-1",
        "/usr/lib/xfce-polkit/xfce-polkit",
    }) do
        if exists(agent) then hl.exec_cmd(agent) break end
    end

    -- startup apps managed by hyprism-settings → Startup (one command per line)
    local f = io.open(HOME .. "/.config/hyprism/autostart", "r")
    if f then
        for line in f:lines() do
            local cmd = line:match("^%s*(.-)%s*$")
            if cmd ~= "" and cmd:sub(1, 1) ~= "#" then hl.exec_cmd(cmd) end
        end
        f:close()
    end
end)

-----------------
---- KEYBINDS ---
-----------------
-- Apps & Hyprism
hl.bind(mod .. " + SPACE",  hl.dsp.exec_cmd(launcher))
hl.bind(mod .. " + TAB",    hl.dsp.exec_cmd("rofi -show window"))
hl.bind(mod .. " + R",      hl.dsp.exec_cmd("rofi -show run"))
hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(term))
hl.bind(mod .. " + K",      hl.dsp.exec_cmd(term))
hl.bind(mod .. " + E",      hl.dsp.exec_cmd("xdg-open " .. HOME))
hl.bind(mod .. " + I",      hl.dsp.exec_cmd("control-center"))                  -- quick settings (rofi)
hl.bind(mod .. " + H",      hl.dsp.exec_cmd("hyprism-open visualconf"))        -- Hyprism
hl.bind(mod .. " + comma",  hl.dsp.exec_cmd("hyprism-open hyprism-settings"))  -- System settings
hl.bind(mod .. " + W",      hl.dsp.exec_cmd("hyprism-open hyprism-settings network"))
hl.bind(mod .. " + B",      hl.dsp.exec_cmd("restart-waybar"))
hl.bind(mod .. " + ESCAPE", hl.dsp.exec_cmd("hyprism-power"))
hl.bind(mod .. " + L",      hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mod .. " + Q",      hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + Q", hl.dsp.exit())

-- Window state
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
-- M toggles maximize without telling the client (browsers keep tabs/toolbars)
hl.bind(mod .. " + M", function()
    local w = hl.get_active_window()
    if not w then return end
    hl.dispatch(hl.dsp.window.fullscreen_state({ internal = (w.fullscreen ~= 0) and 0 or 1, client = 0 }))
end)
hl.bind(mod .. " + C", hl.dsp.window.center())
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"))
-- T: toggle the whole workspace between floating and tiled
hl.bind(mod .. " + T", function()
    local ws = hl.get_active_workspace()
    if not ws then return end
    local wins = ws:get_windows()
    if not wins or #wins == 0 then return end
    local any_float = false
    for _, w in ipairs(wins) do if w.floating then any_float = true break end end
    for _, w in ipairs(wins) do
        if w.floating == any_float then
            hl.dispatch(hl.dsp.window.float({ window = "address:" .. w.address, action = "toggle" }))
        end
    end
end)
-- D: minimize to a hidden special workspace; SHIFT + D brings them all back
hl.bind(mod .. " + D", function()
    local w = hl.get_active_window()
    if not w then return end
    hl.dispatch(hl.dsp.window.move({ window = "address:" .. w.address, workspace = "special:minimized" }))
    hl.dispatch(hl.dsp.workspace.toggle_special("minimized"))
end)
hl.bind(mod .. " + SHIFT + D", function()
    local sp = hl.get_workspace("special:minimized")
    if not sp then return end
    local wins = sp:get_windows()
    if not wins or #wins == 0 then return end
    local cur = hl.get_active_workspace()
    local target = tostring((cur and cur.id) or 1)
    for _, w in ipairs(wins) do
        hl.dispatch(hl.dsp.window.move({ window = "address:" .. w.address, workspace = target }))
    end
end)

-- Screenshots
hl.bind(mod .. " + P",         hl.dsp.exec_cmd("hyprshot -m region --freeze -o $HOME/Pictures/Screenshots"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
hl.bind("PRINT",               hl.dsp.exec_cmd("grim - | wl-copy"))
hl.bind("SHIFT + PRINT",       hl.dsp.exec_cmd("mkdir -p ~/Pictures/Screenshots && grim ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"))

-- Lua window.resize/window.move are ABSOLUTE, so relative steps read the
-- current geometry first.
local STEP_R, STEP_M, STEP_S = 40, 60, 40
local function resize_by(dx, dy)
    local w = hl.get_active_window()
    if w then hl.dispatch(hl.dsp.window.resize({ x = w.size.x + dx, y = w.size.y + dy })) end
end
local function move_by(dx, dy)
    local w = hl.get_active_window()
    if w then hl.dispatch(hl.dsp.window.move({ x = w.at.x + dx, y = w.at.y + dy })) end
end
local function area()
    local m = hl.get_active_monitor()
    if not m then return nil end
    local r = m.reserved
    return m.x + r.left, m.y + r.top, m.width - r.left - r.right, m.height - r.top - r.bottom
end
local function snap(side)
    if not hl.get_active_window() then return end
    local ax, ay, aw, ah = area(); if not ax then return end
    local hw, hh = math.floor(aw / 2), math.floor(ah / 2)
    local g = ({ left = { hw, ah, ax, ay }, right = { hw, ah, ax + hw, ay },
                 up = { aw, hh, ax, ay },   down = { aw, hh, ax, ay + hh } })[side]
    hl.dispatch(hl.dsp.window.resize({ x = g[1], y = g[2] }))
    hl.dispatch(hl.dsp.window.move({ x = g[3], y = g[4] }))
end

for _, k in ipairs({ { "right", STEP_R, 0 }, { "left", -STEP_R, 0 }, { "down", 0, STEP_R }, { "up", 0, -STEP_R } }) do
    hl.bind(mod .. " + CTRL + " .. k[1], function() resize_by(k[2], k[3]) end, { repeating = true })
end
for _, k in ipairs({ { "right", STEP_M, 0 }, { "left", -STEP_M, 0 }, { "down", 0, STEP_M }, { "up", 0, -STEP_M } }) do
    hl.bind(mod .. " + ALT + " .. k[1], function() move_by(k[2], k[3]) end, { repeating = true })
end
for _, d in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mod .. " + " .. d, hl.dsp.focus({ direction = d }))
    hl.bind(mod .. " + SHIFT + " .. d, function() snap(d) end)
end

-- move window to / focus the previous or next monitor
hl.bind(mod .. " + SHIFT + bracketleft",  hl.dsp.window.move({ monitor = "-1" }))
hl.bind(mod .. " + SHIFT + bracketright", hl.dsp.window.move({ monitor = "+1" }))
hl.bind(mod .. " + bracketleft",  hl.dsp.focus({ monitor = "-1" }))
hl.bind(mod .. " + bracketright", hl.dsp.focus({ monitor = "+1" }))

-- workspaces (the 10th uses key 0)
for i = 1, WORKSPACE_COUNT do
    local key = i == 10 and "0" or tostring(i)
    hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- mouse: SUPER + scroll resizes, SUPER + ALT + scroll switches workspace
hl.bind(mod .. " + mouse_down", function() resize_by(-STEP_S, -STEP_S) end, { repeating = true })
hl.bind(mod .. " + mouse_up",   function() resize_by( STEP_S,  STEP_S) end, { repeating = true })
hl.bind(mod .. " + ALT + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + ALT + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- media / brightness keys (brightness only does something on laptops)
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),        { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),    { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set +5%"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })

----------------
---- WINDOWS ---
----------------
-- Optional "everything floats" mode (hyprism windows → floating)
if L.float_all then
    hl.window_rule({ name = "all-floating", match = { class = ".*" }, float = true })
end
hl.window_rule({ name = "open-size", match = { class = ".*", float = true }, size = L.win_size })

hl.window_rule({ name = "polkit-float",    match = { class = "^(polkit-gnome-authentication-agent-1|hyprpolkitagent)$" }, float = true })
hl.window_rule({ name = "utilities-float", match = { class = "^(pavucontrol|nm-connection-editor|blueman-manager|nwg-look|qt6ct)$" }, float = true })

-- Hyprism windows (visualconf, hyprism-settings, SUPER+I terminal items)
hl.window_rule({ name = "hyprism-center", match = { class = "^(hyprism-center)$" }, float = true, size = "1100 700" })

-----------------
---- VM MODE ----
-----------------
-- A focused VM window gets every shortcut; SUPER+ALT+P hands them back.
-- Details and options in ~/.config/hypr/vm-mode.lua.
do
    local ok, vm = pcall(dofile, HOME .. "/.config/hypr/vm-mode.lua")
    if ok and type(vm) == "function" then vm({ mod = mod }) end
end
