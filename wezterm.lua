-- ~/.config/wezterm/wezterm.lua
--
-- Entry point. This file stays tiny on purpose: it just loads each
-- module and lets them mutate the config. Edit the modules, not this file.
--
--   palette.lua     -> all your colors live here (change the look)
--   appearance.lua  -> fonts, window chrome, light/dark behaviour
--   domains.lua     -> makes WSL the default (set your distro name here)
--   keymaps.lua     -> Warp-style keyboard shortcuts
--   workspaces.lua  -> projects-as-workspaces + the project picker
--   bar.lua         -> the themed status panel (pills) + tab styling

local wezterm = require('wezterm')
local config = wezterm.config_builder() -- validates keys & gives nicer errors

-- Re-read this config automatically whenever you save a file. Handy while tweaking.
config.automatically_reload_config = true

require('appearance').apply(config)
require('domains').apply(config)
require('keymaps').apply(config)    -- everyday keys (must come before workspaces/session)
require('workspaces').apply(config) -- adds project + workspace keys
require('bar').setup(config)

return config
