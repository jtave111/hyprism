-- Hyprism VM mode. Loaded by hyprland.lua:
--   local ok, vm = pcall(dofile, HOME .. "/.config/hypr/vm-mode.lua")
--   if ok and type(vm) == "function" then vm({ mod = mod }) end
--
-- Host: while a virtual machine window has focus, every shortcut goes to the
-- VM (SUPER+Q closes the guest's window, not the VM). Focus any other window
-- and the shortcuts come back. Each VM window is tracked on its own, so
-- several VMs can be open at once.
--   SUPER + ALT + P      on a VM: give the shortcuts back to the host (again:
--                        back to the VM). On any other window: VM mode by hand
--   SUPER + ALT + TAB    next window without leaving VM mode (hop between VMs)
--   SUPER + ALT + 1..9   workspace 1..9 without leaving VM mode first
-- A focused VM window keeps the host from going idle and is never
-- transparent, blurred or dimmed.
--
-- Guest: when this Hyprland runs inside VirtualBox or VMware, it starts the
-- session side of the guest tools (shared clipboard, screen resize), which
-- desktops get from XDG autostart and Hyprland does not run.
--
-- vm_mode in ~/.config/hypr/themes/.state (hyprism vm auto|manual|off):
--   auto (default) follows focus · manual only SUPER+ALT+P · off disabled

return function(opts)
    opts = opts or {}
    local HOME   = os.getenv("HOME") or ""
    local STATE  = HOME .. "/.config/hypr/themes/.state"
    local mod    = opts.mod or "SUPER"
    local SUBMAP = "VM"

    local function state(key)
        local f = io.open(STATE, "r")
        if not f then return nil end
        local val
        for line in f:lines() do
            local k, v = line:match("^([%w_]+)=(.*)$")
            if k == key then val = v end
        end
        f:close()
        return val
    end

    local function read(path)
        local f = io.open(path, "r")
        if not f then return "" end
        local s = f:read("*a") or ""
        f:close()
        return s:lower()
    end

    ---------------
    ---- GUEST ----
    ---------------
    local dmi = read("/sys/class/dmi/id/sys_vendor") .. " " .. read("/sys/class/dmi/id/product_name")
    local guest_tools
    if dmi:find("innotek", 1, true) or dmi:find("virtualbox", 1, true) then
        guest_tools = "command -v VBoxClient-all >/dev/null && VBoxClient-all"
    elseif dmi:find("vmware", 1, true) then
        guest_tools = "command -v vmware-user-suid-wrapper >/dev/null && vmware-user-suid-wrapper"
    end
    if guest_tools then
        hl.on("hyprland.start", function() hl.exec_cmd(guest_tools) end)
    end

    local mode = state("vm_mode")
    if mode == "off" then return end
    if mode ~= "manual" then mode = "auto" end

    --------------
    ---- HOST ----
    --------------
    -- Window classes of VM displays. The managers (VirtualBox Manager,
    -- virt-manager's list) are normal windows; only the machine screens count.
    local EXACT  = { "VirtualBox Machine", "VirtualBoxVM", "virt-viewer", "remote-viewer",
                     "spicy", "looking-glass-client", "vmplayer", "Vmplayer" }
    local PREFIX = { "qemu", "Qemu", "QEMU", "vmware", "Vmware" }
    for _, c in ipairs(opts.classes or {}) do EXACT[#EXACT + 1] = c end

    local exact = {}
    for _, c in ipairs(EXACT) do exact[c] = true end

    local function is_vm(w)
        if not w then return false end
        local c = w.class
        if not c or c == "" then c = w.initial_class or "" end
        if exact[c] then return true end
        for _, p in ipairs(PREFIX) do
            if c:sub(1, #p) == p then return true end
        end
        -- virt-manager: its console windows are titled "<vm> on QEMU/KVM"
        if c == "virt-manager" or c == ".virt-manager-wrapped" then
            local t = w.title or ""
            return t:find("QEMU", 1, true) ~= nil or t:find("KVM", 1, true) ~= nil or t:find("Xen", 1, true) ~= nil
        end
        return false
    end

    local function re_escape(s) return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?%|\\{}]", "\\%0")) end
    local alts = {}
    for _, c in ipairs(EXACT) do alts[#alts + 1] = re_escape(c) end
    for _, p in ipairs(PREFIX) do alts[#alts + 1] = re_escape(p) .. ".*" end
    local VM_WINDOW = { idle_inhibit = "focus", opaque = true, no_blur = true, no_dim = true }
    local function vm_rule(name, match)
        local r = { name = name, match = match }
        for k, v in pairs(VM_WINDOW) do r[k] = v end
        hl.window_rule(r)
    end
    vm_rule("hyprism-vm", { class = "^(" .. table.concat(alts, "|") .. ")$" })
    vm_rule("hyprism-vm-virt-manager", { class = "^(virt-manager|\\.virt-manager-wrapped)$", title = ".*(QEMU|KVM|Xen).*" })

    -- English base, Portuguese when lang=pt (the language Hyprism is set to)
    local keys = mod .. "+ALT+P"
    local MSG = {
        en = {
            on_title  = "VM mode",
            on_body   = "Shortcuts go to the VM. " .. keys .. " gives them back.",
            off_title = "VM mode off",
            off_body  = "Shortcuts are back on the host. " .. keys .. " hands them to the VM again.",
        },
        pt = {
            on_title  = "Modo VM",
            on_body   = "Os atalhos vão para a VM. " .. keys .. " devolve.",
            off_title = "Modo VM desligado",
            off_body  = "Os atalhos voltaram para o sistema. " .. keys .. " entrega de novo para a VM.",
        },
    }
    local function say(what)
        local m = MSG[state("lang") == "pt" and "pt" or "en"]
        local function q(s) return "'" .. s:gsub("'", "'\\''") .. "'" end
        hl.exec_cmd("notify-send -a Hyprism -u low -t 2500 -h string:x-dunst-stack-tag:hyprism-vm "
            .. q(m[what .. "_title"]) .. " " .. q(m[what .. "_body"]))
    end

    local released = {}   -- [address] = true: the host took this VM window's shortcuts back
    local greeted  = {}   -- [address] = true: the VM mode hint was already shown for it
    local forced   = false -- VM mode switched on by hand (manual mode, or a non-VM window)

    -- window address as a table key; nil when the window is already gone
    local function key(w)
        local ok, a = pcall(function() return w and w.address end)
        if ok and a and a ~= "" then return a end
    end

    local function active() return hl.get_current_submap() == SUBMAP end
    local function enter() if not active() then hl.dispatch(hl.dsp.submap(SUBMAP)) end end
    local function leave() if active() then hl.dispatch(hl.dsp.submap("reset")) end end

    -- auto mode: VM mode exactly while a VM window that was not released has focus
    local function sync(w)
        if mode ~= "auto" or forced then return end
        local a = key(w)
        if a and is_vm(w) and not released[a] then
            if not active() then
                enter()
                if not greeted[a] then greeted[a] = true; say("on") end
            end
        else
            leave()
        end
    end

    local function toggle()
        local w = hl.get_active_window()
        local a = key(w)
        if active() then
            if mode == "auto" and a and is_vm(w) then released[a] = true end
            forced = false
            leave()
            say("off")
        else
            if mode == "auto" and a and is_vm(w) then
                released[a] = nil
                greeted[a] = true
            else
                forced = true
            end
            enter()
            say("on")
        end
    end

    hl.bind(mod .. " + ALT + P", toggle)
    hl.define_submap(SUBMAP, function()
        hl.bind(mod .. " + ALT + P", toggle)
        hl.bind(mod .. " + ALT + TAB", hl.dsp.window.cycle_next())
        for i = 1, 9 do
            hl.bind(mod .. " + ALT + " .. i, hl.dsp.focus({ workspace = i }))
        end
    end)

    if mode == "auto" then
        hl.on("window.active", function(w) sync(w) end)
        -- switching to an empty workspace leaves no window to report
        hl.on("workspace.active", function() sync(hl.get_active_window()) end)
        -- a destroyed window may no longer report its address (or raise on access)
        hl.on("window.destroy", function(w)
            local a = key(w)
            if a then released[a] = nil; greeted[a] = nil end
        end)
    end
end
