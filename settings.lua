-- ~/.config/wezterm/settings.lua
--
-- Every machine-dependent value lives here, so no other module hardcodes a
-- distro, username, path or OS. The defaults are auto-detected and work as-is
-- on Windows + WSL (any distro), native Linux and macOS.
--
-- Don't edit this file per machine. Instead create `machine.lua` next to it
-- (git-ignored) that returns ONLY the keys you want to change, e.g.
--
--   return { wsl_distros = { 'Ubuntu' }, font_size = 12 }

local wezterm = require('wezterm')

local triple = wezterm.target_triple
local OS = triple:find('windows') and 'windows'
  or triple:find('darwin') and 'macos'
  or 'linux'

local S = {
  -- ── Shell ──
  -- Windows only: WSL distros to launch, in order of preference. Each entry is
  -- matched as a substring of the installed name ('Fedora' -> 'FedoraLinux-44',
  -- 'Ubuntu' -> 'Ubuntu-22.04'). No match -> the first installed distro.
  -- Set to false to start in the native Windows shell instead of WSL.
  wsl_distros = { 'Fedora', 'Ubuntu' },
  -- Program for new panes. nil = your login shell (in WSL: the distro user's
  -- shell). e.g. { 'fish', '-l' } or { 'zsh', '-l' }.
  shell = nil,

  -- ── Projects (workspaces.lua) ──
  -- Root that project paths are relative to. On Windows it's a path INSIDE WSL.
  projects_dir = OS == 'windows' and '/mnt/wsl/Projects/project'
    or wezterm.home_dir .. '/Projects/project',
  -- Project workspace to open at launch (a `workspace` id from
  -- workspaces.lua), or nil for a plain shell window.
  startup_project = nil,

  -- ── Look ──
  font      = 'JetBrainsMono Nerd Font', -- must be installed (WezTerm falls back to plain JetBrains Mono)
  font_size = OS == 'macos' and 14 or 11, -- macOS points render smaller (72 vs 96 dpi)
  -- Renderer. 'OpenGL' usually has lower typing latency on Windows/Linux
  -- (WebGpu queues frames there); macOS gets 'WebGpu' because it runs on Metal.
  -- Needs a full WezTerm restart to switch.
  front_end = OS == 'macos' and 'WebGpu' or 'OpenGL',
  -- Tab/status bar (and the min/max/close buttons) at the bottom instead of
  -- the top. Top is safer: the bar can't slide under the taskbar or off screen.
  bar_at_bottom = false,
  -- false = sravioli-style slanted powerline tabs. WezTerm (any version) has
  --         no × on this bar: middle-click a tab, Ctrl+W or Ctrl+Shift+W.
  -- true  = WezTerm's rounded tabs, each with a clickable × close button.
  fancy_tabs = false,
  -- Fancy bar only: text size. The bar's HEIGHT scales with it (WezTerm pads the
  -- tabs by a fraction of this font), so smaller = slimmer bar.
  -- nil = font_size - 2.
  bar_font_size = nil,
}

-- Per-machine overrides from machine.lua (optional).
local ok, overrides = pcall(require, 'machine')
if ok and type(overrides) == 'table' then
  for k, v in pairs(overrides) do S[k] = v end
elseif not ok and not tostring(overrides):find("module 'machine' not found", 1, true) then
  wezterm.log_error('settings.lua: machine.lua failed to load: ' .. tostring(overrides))
end

-- Host OS (detected; set after overrides so machine.lua can't desync them).
S.os         = OS
S.is_windows = OS == 'windows'
S.is_macos   = OS == 'macos'
S.is_linux   = OS == 'linux'

return S
