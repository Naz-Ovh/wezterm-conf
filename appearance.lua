-- ~/.config/wezterm/appearance.lua
--
-- Fonts, window look, and how the two dark variants get chosen.

local wezterm = require('wezterm')
local P = require('palette')
local S = require('settings') -- font, size, renderer + host OS

local M = {}

-- Decide which background variant to use based on the OS theme.
-- `wezterm.gui` is nil in the background mux process, so guard it.
local function variant()
  local appearance = 'Dark'
  if wezterm.gui then
    appearance = wezterm.gui.get_appearance() -- "Dark" | "Light" | "*HighContrast"
  end
  if appearance:find('Dark') then
    return P.dark -- OS dark  -> true black
  else
    return P.dim  -- OS light -> lifted dark
  end
end

function M.apply(config)
  local v = variant()

  -- ── Font ──
  -- Family and size come from settings.lua. "Symbols Nerd Font Mono" ships
  -- WITH WezTerm, so the bar icons work even if the main font lacks them.
  config.font = wezterm.font_with_fallback({
    { family = S.font, weight = 'Regular' },
    'Symbols Nerd Font Mono', -- built-in safety net (rarely hit)
  })
  config.font_size = S.font_size
  config.line_height = 1.1
  config.harfbuzz_features = { 'calt=1', 'liga=1' } -- ligatures on; set to 0 to turn off

  -- ── Bar weight (terminal left untouched) ──
  -- The retro tab bar shares this terminal font, so the only way to give the
  -- bar its own weight is a font_rule. bar.lua tags ALL of its text as
  -- Bold + Italic — a combination your shell prompt and program output don't
  -- use — and we map JUST that combo to Medium (upright). Result: the bar
  -- renders Medium while the terminal and prompt keep their DEFAULT rendering.
  --   Want the bar heavier/lighter? change 'Medium' below.
  config.font_rules = {
    { intensity = 'Bold', italic = true,
      font = wezterm.font({ family = S.font, weight = 'Medium' }) },
  }

  -- ── Rendering / performance ──
  config.front_end = S.front_end
  config.max_fps = 120 -- keep high: a frame can start sooner after each keystroke
  -- No easing animations. With 60 here the blinking cursor FADES, which
  -- repaints the whole window 60x/second while focused and idle — the main
  -- GPU drain. At 1 (plus the Constant easing below) it's a hard on/off blink
  -- that repaints only when the cursor actually toggles.
  config.animation_fps = 1

  -- ── Window chrome ──
  -- Frameless (no native title bar — that one follows Windows and turns white
  -- in OS light mode, clashing with the dark theme). Instead the window buttons
  -- (min/max/close) are drawn INTO our own themed bar via INTEGRATED_BUTTONS.
  -- WezTerm has only ONE bar and the buttons live inside it, so they land at
  -- the right end of the bar, wherever it sits (settings.bar_at_bottom).
  --
  -- Alternatives:
  --   'TITLE | RESIZE' -> native title bar (buttons top-right) BUT it can't be
  --                       themed dark on Windows, so it goes white in light mode.
  --   'RESIZE'         -> totally bare, no buttons at all.
  config.window_decorations = 'INTEGRATED_BUTTONS | RESIZE'
  -- Draw the integrated buttons in the host OS's idiom: square on Windows,
  -- traffic-lights on macOS, GNOME-style elsewhere (Linux). The buttons still
  -- live inside our themed bar on every platform.
  config.integrated_title_button_style =
    S.is_windows and 'Windows'
    or S.is_macos and 'MacOsNative'
    or 'Gnome'
  config.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' } -- minimize, maximize, close
  config.integrated_title_button_alignment = 'Right'          -- right end of the bar
  config.integrated_title_button_color = 'auto'

  -- Default launch size, measured in character cells (columns x rows).
  config.initial_cols = 160
  config.initial_rows = 40

  config.window_padding = { left = 14, right = 14, top = 10, bottom = 6 }
  config.window_background_opacity = 1.0 -- set e.g. 0.96 for slight transparency
  config.enable_scroll_bar = true
  config.default_cursor_style = 'BlinkingBlock' -- block that blinks
  config.cursor_blink_rate = 450                -- blink period in ms (lower = faster)
  config.cursor_blink_ease_in = 'Constant'      -- hard blink, no fade (see animation_fps)
  config.cursor_blink_ease_out = 'Constant'
  config.inactive_pane_hsb = { saturation = 0.9, brightness = 0.65 } -- dim unfocused split panes
  config.scrollback_lines = 10000

  -- ── Tab bar -> our themed status panel ──
  -- settings.fancy_tabs picks the bar:
  --   RETRO (default): the bar is terminal CELLS in the main font, which is
  --     what lets bar.lua draw seamless sravioli-style slanted tabs — but
  --     WezTerm has no × button on that bar.
  --   FANCY: WezTerm draws rounded tabs, each with a × close button, in
  --     window_frame's font; tab colors come from colors.tab_bar.
  -- Top or bottom comes from settings.bar_at_bottom; the integrated window
  -- buttons travel with it.
  config.use_fancy_tab_bar = S.fancy_tabs
  config.tab_bar_at_bottom = S.bar_at_bottom
  config.hide_tab_bar_if_only_one_tab = false -- keep the bar (and clock) visible always
  -- The "+" new-tab button is enabled AND styled in bar.lua (it runs last and
  -- owns config.tab_bar_style), so it's intentionally not set here.
  config.show_tab_index_in_tab_bar = false    -- bar.lua draws its own numbered tabs
  config.tab_max_width = 32

  -- window_frame styles the fancy tab bar (its ONE font for tabs + status, and
  -- the panel color) and the window buttons. With the retro bar the panel
  -- color comes from colors.tab_bar.background (below) instead.
  config.window_frame = {
    font = wezterm.font_with_fallback({
      { family = S.font, weight = 'Regular' },
      'Symbols Nerd Font Mono', -- built-in safety net
    }),
    font_size = S.bar_font_size or S.font_size - 2, -- smaller font = slimmer fancy bar
    active_titlebar_bg   = P.bar.bg,
    inactive_titlebar_bg = P.bar.bg,
    active_titlebar_fg   = P.bar.fg,
    inactive_titlebar_fg = P.bar.fg_dim,
    button_bg          = P.bar.bg,
    button_fg          = P.bar.fg_dim,
    button_hover_bg    = P.muted,
    button_hover_fg    = v.fg,
  }

  -- ── Colors ──
  config.colors = {
    foreground = v.fg,
    background = v.bg,
    cursor_bg = P.cursor,
    cursor_fg = v.bg,
    cursor_border = P.cursor,
    selection_bg = P.sel_bg,
    selection_fg = '#ffffff',
    scrollbar_thumb = P.muted, -- the draggable scrollbar handle (right edge) — kept faint so it doesn't fight the minimal look
    ansi = P.ansi,
    brights = P.brights,

    -- Tab bar colors are pinned dark so the panel never goes light. The tab
    -- fills match the retro bar's (accent / slate / lifted-on-hover with dark
    -- ink); the fancy bar paints tabs and their × with these, while retro
    -- tabs paint their own colors in bar.lua.
    tab_bar = {
      background = P.bar.bg,
      active_tab         = { bg_color = P.accent,      fg_color = P.bar.bg },
      inactive_tab       = { bg_color = P.brights[1], fg_color = P.bar.bg },
      inactive_tab_hover = { bg_color = P.subtle,      fg_color = P.bar.bg },
      inactive_tab_edge  = P.bar.bg, -- thin divider between inactive tabs
      new_tab            = { bg_color = P.brights[1], fg_color = P.bar.fg },
      new_tab_hover      = { bg_color = P.subtle,      fg_color = P.bar.bg },
    },
  }
end

return M
