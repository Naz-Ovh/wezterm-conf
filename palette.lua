-- ~/.config/wezterm/palette.lua
--
-- This is the ONE file you edit to change how everything looks.
-- It's just a table of colors. Every other module reads from here.
--
-- The terminal background switches with your OS theme, but never goes light:
--   OS Dark  -> `dark` (true black, OLED-friendly)
--   OS Light -> `dim`  (a slightly lifted dark)
-- The status bar at the bottom is ALWAYS dark regardless of OS mode.

return {
  -- ── Background variants (picked automatically by OS appearance) ──
  dark = { -- used when the OS is in Dark mode  -> pure black
    bg = '#000000',
    fg = '#d6d6d6',
  },
  dim = { -- used when the OS is in Light mode -> lifted dark
    bg = '#121317',
    fg = '#d6d6d6',
  },

  -- ── Accents & UI colors (shared by both variants) ──
  accent  = '#7aa2f7', -- soft indigo-blue (main accent: active tab, clock, workspace)
  accent2 = '#9d7cd8', -- muted violet (secondary: domain pill)
  muted   = '#2a2d3a', -- dim slate (path pill background)
  subtle  = '#6b7089', -- low-contrast text
  cursor  = '#8b8d94', -- dim white (block cursor fill)
  sel_bg  = '#283457', -- text selection background

  -- ── ANSI 16-color palette (what programs / your prompt use) ──
  ansi = {
    '#1b1d27', -- 0 black
    '#f7768e', -- 1 red
    '#9ece6a', -- 2 green
    '#e0af68', -- 3 yellow
    '#7aa2f7', -- 4 blue
    '#bb9af7', -- 5 magenta
    '#7dcfff', -- 6 cyan
    '#a9b1d6', -- 7 white
  },
  brights = {
    '#414868', -- 8  bright black
    '#ff7a93', -- 9  bright red
    '#b9f27c', -- 10 bright green
    '#ff9e64', -- 11 bright yellow
    '#7da6ff', -- 12 bright blue
    '#bb9af7', -- 13 bright magenta
    '#0db9d7', -- 14 bright cyan
    '#c0caf5', -- 15 bright white
  },

  -- ── Status bar (ALWAYS dark, independent of OS mode) ──
  -- bar.bg is lifted slightly above pure black on purpose: against a #000000
  -- terminal a near-black bar looks "missing". This reads as a real panel.
  -- Want it blacker? Lower it toward '#000000'. Want it to pop more? Raise it.
  bar = {
    bg     = '#15161d', -- the panel background (visible strip)
    fg     = '#c0caf5', -- active text on the bar
    fg_dim = '#6b7089', -- inactive tab text
  },
}
