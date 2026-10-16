-- ~/.config/wezterm/scrollbar.lua
--
-- settings.scroll_bar = 'auto': the scrollbar appears only when the active
-- pane has more lines than fit on screen (i.e. there is something to
-- scroll), like a browser. A fresh tab, a cleared screen (Ctrl+Shift+K) and
-- full-screen apps such as nvim/htop show none.
--
-- WezTerm has no native "auto" mode, so this flips enable_scroll_bar per
-- window through config overrides. It runs on the status tick
-- (status_update_interval, 1s), and only touches the config when the
-- answer changes. The bar lives in the right window padding, so showing or
-- hiding it never reflows the text.

local wezterm = require('wezterm')
local S = require('settings')
local M = {}

function M.setup(config)
  if S.scroll_bar ~= 'auto' then
    return
  end

  wezterm.on('update-status', function(window, pane)
    local d = pane:get_dimensions()
    -- scrollback_rows counts the whole buffer, viewport included.
    local want = d.scrollback_rows > d.viewport_rows

    local overrides = window:get_config_overrides() or {}
    local shown = overrides.enable_scroll_bar
    if shown == nil then shown = config.enable_scroll_bar end
    if shown ~= want then
      overrides.enable_scroll_bar = want
      window:set_config_overrides(overrides)
    end
  end)
end

return M
