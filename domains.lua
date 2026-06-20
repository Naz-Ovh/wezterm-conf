-- ~/.config/wezterm/domains.lua
--
-- On Windows: makes WSL the default for every new tab/window.
-- On Linux/macOS: there is no WSL, so this leaves the default local shell
-- alone. The whole module is a no-op off Windows — the config stays portable.

local wezterm = require('wezterm')
local M = {}

-- True only on Windows (e.g. "x86_64-pc-windows-msvc"). WSL is Windows-only,
-- so everything below is gated on this.
local IS_WINDOWS = wezterm.target_triple:find('windows') ~= nil

-- 👇 Set this to YOUR distro name (Windows only).
--    In PowerShell run:  wsl -l -q
--    and copy the exact name (e.g. "Ubuntu", "Ubuntu-22.04", "Debian").
local WSL_DISTRO = 'Ubuntu'

function M.apply(config)
  -- Off Windows there is no WSL: keep WezTerm's default local domain (your
  -- login shell) and do nothing else.
  if not IS_WINDOWS then
    return
  end

  -- Register every installed WSL distro as a launchable domain.
  config.wsl_domains = wezterm.default_wsl_domains()

  -- Tweak the chosen distro (start in $HOME, optionally force a shell).
  local found = false
  for _, dom in ipairs(config.wsl_domains) do
    if dom.name == ('WSL:' .. WSL_DISTRO) then
      found = true
      dom.default_cwd = '~'
      -- dom.default_prog = { 'zsh', '-l' } -- uncomment to force zsh / fish / etc.
    end
  end

  -- Launch straight into WSL by default.
  if found then
    config.default_domain = 'WSL:' .. WSL_DISTRO
  else
    wezterm.log_warn('domains.lua: WSL distro "' .. WSL_DISTRO ..
      '" not found. Run `wsl -l -q` and fix WSL_DISTRO.')
  end
end

return M
