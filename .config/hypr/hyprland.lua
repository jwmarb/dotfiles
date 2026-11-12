-- Hyprland config (Lua, Hyprland >= 0.57). Migrated from hyprland.conf.
-- Wiki: https://wiki.hypr.land/configuring/

local HOME = os.getenv("HOME")

---------------------
---- WAL COLOURS ----
---------------------

-- Pywal writes ~/.cache/wal/colors-hyprland as `$name = value` lines (hyprlock
-- sources the same file), so parse it here instead of changing its format.
local function load_wal_colors(path)
    local colors = {}
    local f = io.open(path, "r")
    if not f then
        return colors
    end
    for line in f:lines() do
        local name, value = line:match("^%s*%$([%w_]+)%s*=%s*(.-)%s*$")
        if name then
            colors[name] = value
        end
    end
    f:close()
    return colors
end

local wal = load_wal_colors(HOME .. "/.cache/wal/colors-hyprland")

-- Fallbacks are the .setup-wal defaults, used only if the wal file is missing.
local function color(name, fallback)
    return wal[name] or fallback
end


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/configuring/core/monitors/

-- Laptop panel (this machine); DP-3 / HDMI-A-1 below are the upstream desktop outputs.
hl.monitor({ output = "eDP-1",    mode = "highres@highrr", position = "0x0",    scale = 1.6 })
hl.monitor({ output = "DP-3",     mode = "2560x1440@300", position = "1920x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@75",  position = "0x0",    scale = 1 })


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty --config " .. HOME .. "/.config/kitty/kitty.conf"
local fileManager = "nemo"
local menu        = "wofi --show drun -n"


-------------------
---- AUTOSTART ----
-------------------

-- Equivalent of exec-once: runs once at startup, not on config reload.
hl.on("hyprland.start", function()
    hl.exec_cmd(HOME .. "/.config/hypr/launch_waybar.sh")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("pywalfox start")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("swaync")
    hl.exec_cmd("pypr")
    hl.exec_cmd("swaync-client -df")
    hl.exec_cmd("nm-applet --indicator")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("GTK_THEME", "Materia-dark")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 20,

        border_size = 3,

        col = {
            active_border   = { colors = { color("color1", "0xffED8E69"), color("color11", "0xff9B7188") }, angle = 45 },
            inactive_border = color("color0", "0xff0e0a17"),
        },

        resize_on_border = false,
        allow_tearing    = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = true,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})

-- See https://wiki.hypr.land/configuring/core/animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}  } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}  } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}     } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}  } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}   } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.12, bezier = "quick",        style = "slidefade" })


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- See https://wiki.hypr.land/configuring/core/devices/
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Keybind registry for the SUPER+H menu (wofi_keybinds.sh). It reads the list
-- and runs entries through `hyprctl repl`, so it never parses this file.
KEYBIND_MENU = {}

-- exec_cmd that remembers its command line, so the menu can show it
local exec_labels = setmetatable({}, { __mode = "k" })
local function exec(cmd)
    local d = hl.dsp.exec_cmd(cmd)
    exec_labels[d] = cmd
    return d
end

local function bind(keys, action, opts)
    local label
    if exec_labels[action] then
        label = "exec " .. exec_labels[action]
    else
        label = tostring(action):gsub("^HL%.Dispatcher%((.-)%)$", "%1")
        if type(action) == "function" then
            label = (opts and opts.description) or "lua function"
        end
    end
    -- mouse binds can't be triggered from a menu; skip them
    if not (opts and opts.mouse) then
        table.insert(KEYBIND_MENU, { keys = keys, label = label, action = action })
    end
    return hl.bind(keys, action, opts)
end

bind(mainMod .. " + T",     exec(terminal))
bind(mainMod .. " + Q",     hl.dsp.window.close())
bind(mainMod .. " + M",     hl.dsp.exit())
bind(mainMod .. " + E",     exec(fileManager))
bind(mainMod .. " + V",     hl.dsp.window.float({ action = "toggle" }))
bind(mainMod .. " + space", exec(menu))
bind(mainMod .. " + P",     hl.dsp.window.pseudo())

-- Window resizing (held key repeats)
bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -25, y = 0,   relative = true }), { repeating = true })
bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0,   y = -25, relative = true }), { repeating = true })
bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 25,  y = 0,   relative = true }), { repeating = true })
bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0,   y = 25,  relative = true }), { repeating = true })

-- Window moving
bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ direction = "left" }))
bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "right" }))
bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ direction = "up" }))
bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ direction = "down" }))

-- Move focus with mainMod + arrow keys
bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Per-monitor workspaces (replaces hyprsome, whose legacy IPC dispatches 0.57
-- rejects). Each monitor owns its own block of ten: monitor 0 gets 1-10,
-- monitor 1 gets 11-20, and so on, matching waybar's persistent-workspaces.
local function monitor_workspace(n)
    local mon = hl.get_active_monitor()
    return (mon and mon.id or 0) * 10 + n
end

local workspaceKeys = {
    -- { number row, numpad }
    { "1", "KP_End"    },
    { "2", "KP_Down"   },
    { "3", "KP_Next"   },
    { "4", "KP_Left"   },
    { "5", "KP_Begin"  },
    { "6", "KP_Right"  },
    { "7", "KP_Home"   },
    { "8", "KP_Up"     },
    { "9", "KP_Prior"  },
    { "0", "KP_Insert" },
}

for n, keys in ipairs(workspaceKeys) do
    for _, key in ipairs(keys) do
        -- Switch workspace (hyprsome workspace N)
        bind(mainMod .. " + " .. key, function()
            return hl.dispatch(hl.dsp.focus({ workspace = monitor_workspace(n) }))
        end, { description = "workspace " .. n .. " (this monitor)" })
        -- Move active window to the workspace and follow it (hyprsome movefocus N)
        bind(mainMod .. " + SHIFT + " .. key, function()
            return hl.dispatch(hl.dsp.window.move({ workspace = monitor_workspace(n) }))
        end, { description = "move window to workspace " .. n .. " (this monitor)" })
    end
end

bind(mainMod .. " + SHIFT + f", hl.dsp.window.fullscreen())

-- Scroll through existing workspaces with mainMod + scroll
bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

bind("ALT + Tab", hl.dsp.focus({ workspace = "previous" }))

-- Multimedia keys for volume and LCD brightness (bindel)
bind("XF86AudioRaiseVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),      { locked = true, repeating = true })
bind("XF86AudioLowerVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
bind("XF86AudioMute",         exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
bind("XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
bind("XF86MonBrightnessUp",   exec("brightnessctl s 10%+"),                           { locked = true, repeating = true })
bind("XF86MonBrightnessDown", exec("brightnessctl s 10%-"),                           { locked = true, repeating = true })

-- Requires playerctl (bindl)
bind("XF86AudioNext",  exec("playerctl next"),       { locked = true })
bind("XF86AudioPause", exec("playerctl play-pause"), { locked = true })
bind("XF86AudioPlay",  exec("playerctl play-pause"), { locked = true })
bind("XF86AudioPrev",  exec("playerctl previous"),   { locked = true })

-- Screenshot
bind(mainMod .. " + SHIFT + S", exec("wayfreeze --after-freeze-cmd 'hyprshot -m region -o ~/Screenshots/; killall wayfreeze'"))
bind(mainMod .. " + SHIFT + D", exec("wayfreeze --after-freeze-cmd 'hyprshot -m window -o ~/Screenshots/; killall wayfreeze'"))
bind(mainMod .. " + SHIFT + A", exec("wayfreeze --after-freeze-cmd 'hyprshot -m active -m output -o ~/Screenshots/; killall wayfreeze'"))

-- System
bind(mainMod .. " + Escape", exec("wlogout -b 3 -p layer-shell"))
bind(mainMod .. " + l",      exec("hyprlock"))
bind("ALT + w",              exec(HOME .. "/.config/hypr/wallpaper.sh"))
bind("ALT + a",              exec(HOME .. "/.config/waybar/scripts/refresh.sh"))
bind("ALT + B",              exec(HOME .. "/.config/waybar/scripts/select.sh"))
bind("ALT + r",              exec(HOME .. "/.config/swaync/refresh.sh"))
bind(mainMod .. " + b",      exec("zen-browser"))
bind(mainMod .. " + h",      exec(HOME .. "/.config/hypr/wofi_keybinds.sh"))
