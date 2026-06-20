-- ~/.config/wezterm/appearance.lua
--
-- Fonts, window look, and how the two dark variants get chosen.

local wezterm = require('wezterm')
local P = require('palette')

local M = {}

-- Host OS, used to pick native-feeling window-button styling below.
local triple = wezterm.target_triple
local IS_WINDOWS = triple:find('windows') ~= nil
local IS_MACOS   = triple:find('darwin') ~= nil

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
  -- JetBrains Mono and "Symbols Nerd Font Mono" both ship WITH WezTerm,
  -- so the icons in the bar work out of the box. Swap 'JetBrains Mono'
  -- for any installed font you like (e.g. 'CaskaydiaCove Nerd Font').
  config.font = wezterm.font_with_fallback({
    { family = 'JetBrainsMono Nerd Font', weight = 'Regular' }, -- patched: JetBrains Mono + all icons
    'Symbols Nerd Font Mono',                                   -- built-in safety net (rarely hit)
  })
  config.font_size = 11
  config.line_height = 1.1
  config.harfbuzz_features = { 'calt=1', 'liga=1' } -- ligatures on; set to 0 to turn off

  -- ── Bottom-bar weight (terminal left untouched) ──
  -- The retro tab bar shares this terminal font, so the only way to give the
  -- bar its own weight is a font_rule. bar.lua tags ALL of its text as
  -- Bold + Italic — a combination your shell prompt and program output don't
  -- use — and we map JUST that combo to Medium (upright). Result: the bar
  -- renders Medium while the terminal and prompt keep their DEFAULT rendering.
  --   Want the bar heavier/lighter? change 'Medium' below.
  config.font_rules = {
    { intensity = 'Bold', italic = true,
      font = wezterm.font({ family = 'JetBrainsMono Nerd Font', weight = 'Medium' }) },
  }

  -- ── Rendering / performance ──
  config.front_end = 'WebGpu' -- best on modern GPUs; switch to 'OpenGL' if you see glitches
  config.max_fps = 120
  config.animation_fps = 60

  -- ── Window chrome ──
  -- Frameless (no native title bar — that one follows Windows and turns white
  -- in OS light mode, clashing with the dark theme). Instead the window buttons
  -- (min/max/close) are drawn INTO our own themed bar via INTEGRATED_BUTTONS.
  -- WezTerm has only ONE bar and the buttons live inside it, so because the bar
  -- now sits at the BOTTOM (tab_bar_at_bottom = true below), the buttons land at
  -- the bottom-right alongside the status chain.
  --
  -- Alternatives:
  --   'TITLE | RESIZE' -> native title bar (buttons top-right) BUT it can't be
  --                       themed dark on Windows, so it goes white in light mode.
  --   'RESIZE'         -> totally bare, no buttons at all.
  config.window_decorations = 'INTEGRATED_BUTTONS | RESIZE'
  -- Draw the integrated buttons in the host OS's idiom: square on Windows,
  -- traffic-lights on macOS, GNOME-style elsewhere (Linux). The buttons still
  -- live inside our themed bottom bar on every platform.
  config.integrated_title_button_style =
    IS_WINDOWS and 'Windows'
    or IS_MACOS and 'MacOsNative'
    or 'Gnome'
  config.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' } -- minimize, maximize, close
  config.integrated_title_button_alignment = 'Right'          -- bottom-right (bar is at the bottom)
  config.integrated_title_button_color = 'auto'

  -- Default launch size, measured in character cells (columns x rows).
  config.initial_cols = 160
  config.initial_rows = 40

  config.window_padding = { left = 14, right = 14, top = 10, bottom = 6 }
  config.window_background_opacity = 1.0 -- set e.g. 0.96 for slight transparency
  config.enable_scroll_bar = true
  config.default_cursor_style = 'BlinkingBlock' -- block that blinks
  config.cursor_blink_rate = 450                -- blink period in ms (lower = faster)
  config.inactive_pane_hsb = { saturation = 0.9, brightness = 0.65 } -- dim unfocused split panes
  config.scrollback_lines = 10000

  -- ── Tab bar -> our themed status panel ──
  -- RETRO tab bar (not fancy): it renders the bar as terminal CELLS using the
  -- main font, which is what lets bar.lua draw the seamless sravioli-style
  -- powerline — slanted tabs and the gradient status chain. (The fancy tab bar
  -- draws rounded "pills" instead and can't reproduce that look.)
  -- It lives at the BOTTOM; the integrated window buttons travel down with it.
  --   Want the bar back at the TOP? set tab_bar_at_bottom = false.
  config.use_fancy_tab_bar = false
  config.tab_bar_at_bottom = true        -- <- bar (and buttons) at the BOTTOM
  config.hide_tab_bar_if_only_one_tab = false -- keep the bar (and clock) visible always
  -- The "+" new-tab button is enabled AND styled in bar.lua (it runs last and
  -- owns config.tab_bar_style), so it's intentionally not set here.
  config.show_tab_index_in_tab_bar = false    -- bar.lua draws its own numbered tabs
  config.tab_max_width = 32

  -- window_frame styles the fancy tab bar / resize border. With the retro bar
  -- the panel color comes from colors.tab_bar.background (below) instead, but
  -- this is kept harmless for the resize border + light/dark button contrast.
  config.window_frame = {
    font = wezterm.font_with_fallback({
      { family = 'JetBrainsMono Nerd Font', weight = 'Regular' }, -- patched: JetBrains Mono + all icons
      'Symbols Nerd Font Mono', -- built-in safety net
    }),
    font_size = 11,
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

    -- Tab bar colors are pinned dark so the panel never goes light.
    tab_bar = {
      background = P.bar.bg,
      active_tab        = { bg_color = P.bar.bg, fg_color = P.accent, intensity = 'Bold' },
      inactive_tab      = { bg_color = P.bar.bg, fg_color = P.bar.fg_dim },
      inactive_tab_hover= { bg_color = P.bar.bg, fg_color = v.fg },
      new_tab           = { bg_color = P.bar.bg, fg_color = P.bar.fg_dim },
      new_tab_hover     = { bg_color = P.bar.bg, fg_color = v.fg },
    },
  }
end

return M
