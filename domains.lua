-- ~/.config/wezterm/domains.lua
--
-- Which shell new tabs/windows start in, driven by settings.lua:
--   Windows      -> a WSL distro picked from `wsl_distros` (all installed
--                   distros are still listed in the launcher: right-click "+").
--   Linux/macOS  -> your login shell (or `shell` if set).

local wezterm = require('wezterm')
local S = require('settings')
local M = {}

-- First preference that matches an installed distro, else the first installed.
local function pick(domains)
  for _, want in ipairs(S.wsl_distros) do
    for _, dom in ipairs(domains) do
      if (dom.distribution or dom.name):lower():find(want:lower(), 1, true) then
        return dom
      end
    end
  end
  return domains[1]
end

function M.apply(config)
  if not S.is_windows then
    config.default_prog = S.shell -- nil keeps your login shell
    return
  end

  -- Register every installed WSL distro as a launchable domain.
  config.wsl_domains = wezterm.default_wsl_domains()
  if not S.wsl_distros then
    return -- native Windows shell requested
  end

  local dom = pick(config.wsl_domains)
  if not dom then
    wezterm.log_warn('domains.lua: no WSL distros installed; using the Windows shell.')
    return
  end

  -- Start in the Linux $HOME (`wsl --cd ~`) and launch straight into it.
  dom.default_cwd = '~'
  dom.default_prog = S.shell
  config.default_domain = dom.name
end

return M
