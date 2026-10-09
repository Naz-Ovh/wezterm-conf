-- ~/.config/wezterm/bar.lua
--
-- A faithful, self-contained port of the sravioli/wezterm RETRO powerline bar
-- (https://github.com/sravioli/wezterm). Top or bottom: settings.bar_at_bottom.
-- With settings.fancy_tabs = true the tabs are WezTerm's rounded ones with a
-- × close button instead of slanted; everything else below is the same.
-- Reading left -> right:
--
--    workspace      <- rounded pill; becomes a COPY / SEARCH pill in that mode
--   1   2  ...     <- slanted tabs; each shows the running program's ICON
--   ...............  <- empty fill (the bar background)
--             cwd  host  clock  battery   <- right chain on a brightening gradient
--
-- The headline sravioli touch: each tab shows a glyph for the *foreground
-- process* (a terminal icon for the shell,  for nvim,  for git, etc.) so
-- you never see a raw "wslhost.exe". Colors come from palette.lua; glyphs are
-- looked up from wezterm.nerdfonts using sravioli's exact icon names.

local wezterm = require('wezterm')
local nf = wezterm.nerdfonts
local P = require('palette')
local S = require('settings') -- fancy_tabs: rounded tabs with × vs slanted retro tabs
local M = {}

-- ── Separators (sravioli's exact set) ─────────────────────────────
-- Tabs: a half-block left cap for the first tab, slanted triangles otherwise;
-- a solid block + lower-left triangle closes each tab into a leaning pill.
local TB_LEFTMOST = '▐'
local TB_LEFT  = nf.ple_upper_right_triangle or utf8.char(0xe0bc) --
local TB_RIGHT = nf.ple_lower_left_triangle  or utf8.char(0xe0b8) --
local BLOCK    = '█'
-- Status chain: hard dividers; rounded half-circles cap the workspace/mode pill.
local SEP_R = nf.pl_right_hard_divider     or utf8.char(0xe0b0) --  closes a left chain
local SEP_L = nf.pl_left_hard_divider      or utf8.char(0xe0b2) --  opens a right chain
local CAP_L = nf.ple_left_half_circle_thick  or utf8.char(0xe0b6) -- ◖ rounded left cap
local CAP_R = nf.ple_right_half_circle_thick or utf8.char(0xe0b4) -- ◗ rounded right cap

-- ── Standalone icons (sravioli's exact names) ─────────────────────
local ICON_WS     = nf.md_shield              or '◆' -- workspace
local ICON_CWD    = nf.md_folder              or '▣' -- current working directory
local ICON_HOST   = nf.md_monitor_shimmer     or nf.md_monitor or '▢' -- hostname
local ICON_HOME   = nf.md_home                or '~' -- cwd == $HOME
local ICON_COPY   = nf.md_content_copy        or '⧉' -- copy-mode pill
local ICON_FIND   = nf.md_magnify             or '⌕' -- search-mode pill
local ICON_NOTIFY = nf.cod_circle_small_filled or '●' -- tab has unseen output
-- Default tab glyph when the foreground process isn't in the map below
-- (this is the "default terminal icon" you see instead of wslhost.exe).
-- fa_terminal is a SOLID/filled terminal — far more noticeable than the thin
-- cod_terminal outline.
local ICON_TERM   = nf.fa_terminal or nf.md_console or nf.cod_terminal or '>'

-- Window-control caption glyphs for the integrated buttons (VS Code "chrome"
-- set — clean thin line / square / X, much nicer than the default . - X).
local BTN_HIDE  = nf.cod_chrome_minimize or nf.md_window_minimize or '_'
local BTN_MAX   = nf.cod_chrome_maximize or nf.md_window_maximize or '□'
local BTN_CLOSE = nf.cod_chrome_close    or nf.md_window_close    or '✕'

-- ── Process -> icon map (sravioli's Progs table) ──────────────────
-- Keyed by lowercase program basename. A missing Nerd Font name resolves to
-- nil here, so that entry is simply skipped (no crash on older builds).
local PROGS = {
  bash             = nf.cod_terminal_bash,
  zsh              = nf.dev_terminal,
  fish             = nf.md_fish,
  sh               = nf.cod_terminal,
  pwsh             = nf.md_console,
  powershell       = nf.md_console,
  cmd              = nf.md_console_line,
  ['cmd.exe']      = nf.md_console_line,
  wt               = nf.md_console,
  btm              = nf.md_chart_donut_variant,
  btop             = nf.md_chart_areaspline,
  htop             = nf.md_chart_areaspline,
  cargo            = nf.dev_rust,
  rustc            = nf.dev_rust,
  curl             = nf.mdi_flattr or nf.md_download,
  wget             = nf.mdi_arrow_down_box or nf.md_download,
  docker           = nf.linux_docker,
  ['docker-compose'] = nf.linux_docker,
  kubectl          = nf.linux_docker,
  kuberlr          = nf.linux_docker,
  lazydocker       = nf.linux_docker,
  lazygit          = nf.cod_github,
  gh               = nf.dev_github_badge or nf.cod_github,
  git              = nf.dev_git,
  go               = nf.seti_go or nf.md_language_go,
  lua              = nf.seti_lua or nf.md_language_lua,
  make             = nf.seti_makefile,
  node             = nf.md_nodejs or nf.dev_nodejs_small,
  nvim             = nf.custom_neovim or nf.dev_vim,
  vim              = nf.dev_vim,
  vi               = nf.dev_vim,
  pacman           = '󰮯',
  paru             = '󰮯',
  yay              = '󰮯',
  perl             = nf.seti_perl,
  psql             = nf.dev_postgresql,
  python           = nf.seti_python or nf.md_language_python,
  python3          = nf.seti_python or nf.md_language_python,
  ipython          = nf.seti_python or nf.md_language_python,
  ruby             = nf.cod_ruby or nf.dev_ruby,
  sudo             = nf.fa_hashtag,
  topgrade         = nf.md_rocket_launch,
  yazi             = nf.md_duck,
  ssh              = nf.md_remote_desktop or nf.fa_server,
  vifm             = nf.md_folder_outline,
  lf               = nf.md_folder_outline,
  ranger           = nf.md_folder_outline,
}

-- Hour (1..12) -> matching clock-face glyph (sravioli's signature touch).
local CLOCK = { 'one', 'two', 'three', 'four', 'five', 'six',
                'seven', 'eight', 'nine', 'ten', 'eleven', 'twelve' }
local function clock_icon()
  local h = tonumber(wezterm.strftime('%I')) or 12
  return nf['md_clock_time_' .. CLOCK[h]] or nf.md_clock_outline or nf.md_clock or ''
end

-- Battery glyph from the charge state + percentage (sravioli's Bat table).
local function batt_icon(state, pct)
  local lvl = math.max(0, math.min(100, math.floor(pct / 10 + 0.5) * 10))
  if state == 'Charging' then
    if lvl <= 0 then return nf.md_battery_alert or nf.md_battery_charging_outline or '' end
    if lvl >= 100 then return nf.md_battery_charging_100 or nf.md_battery or '' end
    return nf['md_battery_charging_' .. lvl] or nf.md_battery_charging_outline or ''
  end
  if lvl >= 100 then return nf.md_battery or '▮' end
  if lvl <= 0 then return nf.md_battery_outline or '▯' end
  return nf['md_battery_' .. lvl] or nf.md_battery or '▮'
end

-- Numeric glyph for a tab index (plain number past the icon set).
local function num_icon(i)
  return nf['md_numeric_' .. i] or tostring(i)
end

-- ── Right-chain gradient ──────────────────────────────────────────
-- Four light tones derived from the bar foreground; the chain brightens
-- toward the screen edge. Dark "ink" text sits on top of them.
local C = wezterm.color
local FG = C.parse(P.bar.fg)
local TONE = { FG:darken(0.20), FG:darken(0.04), FG:lighten(0.14), FG:lighten(0.26) }
local INK = P.bar.bg

-- wezterm.format wants exactly ONE key per item, so a colored run is 3 items.
-- Order matches Layout:append(background, foreground, text).
local function push(out, bg, fg, text)
  out[#out + 1] = { Background = { Color = bg } }
  out[#out + 1] = { Foreground = { Color = fg } }
  out[#out + 1] = { Text = text }
end

-- Every bar sequence starts here. The Bold+Italic tag is what the Medium
-- font_rule in appearance.lua matches (the terminal/prompt never use that
-- combo), so the WHOLE bar renders at Medium without touching the terminal.
local function medium()
  return { { Attribute = { Intensity = 'Bold' } }, { Attribute = { Italic = true } } }
end

-- Rounded pill (workspace / mode indicator) with half-circle caps.
-- The leading Bold attribute makes the whole pill render at Medium weight (see
-- the font_rules in appearance.lua) — that's how the bar gets its Medium look.
local function render_pill(text, bg, fg)
  local out = medium()
  push(out, P.bar.bg, bg, CAP_L)
  push(out, bg, fg, ' ' .. text .. ' ')
  push(out, P.bar.bg, bg, CAP_R)
  return wezterm.format(out)
end

-- RIGHT chain (sravioli style): each cell is opened by a right-pointing hard
-- divider that transitions from the previous color into the cell. Listed
-- inner -> outer (left -> right): cwd, host, clock, battery.
local function render_right(segs)
  local prev = P.bar.bg
  local out = medium()
  for _, s in ipairs(segs) do
    push(out, prev, s.bg, SEP_R)            --  transition prev -> this cell
    push(out, s.bg, s.fg, ' ' .. s.text .. ' ')
    prev = s.bg
  end
  push(out, P.bar.bg, P.bar.bg, ' ')        -- pad so the integrated window buttons never overlap
  return wezterm.format(out)
end

-- ── cwd / host helpers ────────────────────────────────────────────
local function basename(p)
  if not p or p == '' then return '' end
  p = p:gsub('[/\\]+$', '')
  return (p:match('[^/\\]+$')) or p
end

-- Pull cwd + host out of a pane/PaneInformation (old string and new Url APIs).
local function cwd_and_host(uri)
  if not uri then return nil, nil end
  if type(uri) == 'userdata' then return uri.file_path, uri.host end -- newer: Url object
  local s = tostring(uri)
  return (s:gsub('^file://[^/]*', '')), s:match('^file://([^/]*)')    -- older: string
end

-- Display path the way sravioli does: collapse $HOME to "~" (so C:\Users\hi -> ~),
-- normalize WSL mount forms (/mnt/c/.. and /c/.. -> C:/..), shorten very long
-- paths to …/last2.
local HOME = (os.getenv('USERPROFILE') or os.getenv('HOME') or ''):gsub('\\', '/'):gsub('/+$', '')
local function display_cwd(p)
  if not p or p == '' then return nil end
  p = p:gsub('\\', '/')
  p = p:gsub('^/mnt/([A-Za-z])/', function(d) return d:upper() .. ':/' end) -- /mnt/c/.. -> C:/..
  p = p:gsub('^/([A-Za-z])/', function(d) return d:upper() .. ':/' end)     -- /c/..     -> C:/..
  p = p:gsub('^/([A-Za-z]:)', '%1')                                         -- /C:/..    -> C:/..
  p = p:gsub('/+$', '')
  if p == '' then return '/' end
  if HOME ~= '' then
    local pl, hl = p:lower(), HOME:lower()
    if pl == hl then
      p = '~'
    elseif pl:sub(1, #HOME + 1) == hl .. '/' then
      p = '~' .. p:sub(#HOME + 1)
    end
  end
  if #p > 28 then
    local parts = {}
    for s in p:gmatch('[^/]+') do parts[#parts + 1] = s end
    if #parts >= 2 then p = '…/' .. parts[#parts - 1] .. '/' .. parts[#parts] end
  end
  return p
end

-- ── Tab title (sravioli's format_tab_title, hardened for WSL) ──────
-- Build "<process-icon> <label>". The process icon comes from PROGS keyed by
-- the foreground process; the label is the OSC title when it's meaningful,
-- otherwise the current directory's name. The WSL bridge reports "wslhost.exe"
-- as the title/process, which we treat as noise and replace with the terminal
-- icon + directory — exactly the "default terminal icon" sravioli shows.
local NOISE = { wslhost = true, wsl = true, [''] = true }

local function tab_label(pane, explicit, max_width, tab_max_width, reserve)
  local raw = (pane.title or ''):gsub('^Copy mode: ', '')

  local exe   = basename(pane.foreground_process_name or '')
  local exe_l = exe:gsub('%.[Ee][Xx][Ee]$', ''):lower()

  -- leading word of the OSC title (sravioli detects the process this way too)
  local word = raw:match('^(%S+)')
  local word_l = word and word:gsub('%.[Ee][Xx][Ee]$', ''):lower() or nil

  -- process icon: title word > foreground exe > default terminal glyph.
  -- Computed up front so even a RENAMED tab keeps its icon.
  local pic = (word_l and PROGS[word_l]) or PROGS[exe_l] or ICON_TERM

  local label
  if explicit and #explicit > 0 then
    -- a renamed tab: keep the icon, show the chosen name verbatim
    label = explicit
  else
    -- is the title just bridge/process noise (no real OSC title)?
    local title_noisy = NOISE[raw:lower()]
      or NOISE[(basename(raw):gsub('%.[Ee][Xx][Ee]$', '')):lower()]
    if (not title_noisy) and word_l and PROGS[word_l] then
      -- title leads with a known program -> show what follows it
      local rest = raw:gsub('^%S+%s*%-?%s*', '')
      label = (rest ~= '' and rest) or word
    elseif not title_noisy then
      label = raw
    else
      -- no useful title: fall back to the directory name
      local path = (cwd_and_host(pane.current_working_dir))
      local dir = basename(path or '')
      label = (dir ~= '' and dir) or (exe_l ~= '' and exe_l) or 'shell'
    end
  end

  local text = pic .. ' ' .. label

  -- Truncate only when the whole tab would exceed its width, capped at
  -- tab_max_width (sravioli's rule). `reserve` = cells the caller adds around
  -- this text (number, edges). Measured in cells, not bytes: the icons are
  -- multi-byte but one cell wide.
  local cap = tab_max_width or 32
  local room = (max_width and math.min(max_width, cap) or cap) - reserve
  if room > 1 and wezterm.column_width(text) > room then
    text = wezterm.truncate_right(text, room - 1) .. '…'
  end
  return text
end

function M.setup(config)
  config.status_update_interval = 1000 -- refresh the clock / battery every second

  -- New-tab "+" button, shaped into a slanted pill like the tabs
  -- (sravioli's set_tab_button). Runs last in wezterm.lua, so this is the
  -- single source of truth for the button — overrides appearance.lua.
  config.show_new_tab_button_in_tab_bar = true
  config.tab_bar_style = {}
  for state, s in pairs({
    new_tab       = { bg = P.brights[1], fg = P.bar.fg },     -- slate, like an inactive tab
    new_tab_hover = { bg = P.subtle,     fg = P.bar.bg },     -- lifts on hover
  }) do
    local out = medium()
    push(out, s.bg, P.bar.bg, TB_RIGHT)   --  left wedge into the button
    push(out, s.bg, s.fg, ' + ')
    push(out, s.bg, P.bar.bg, TB_LEFT)    --  right wedge back into the bar
    config.tab_bar_style[state] = wezterm.format(out)
  end

  -- Integrated window buttons (min / max / close). On the RETRO tab bar these
  -- are styled here via tab_bar_style — that's what replaces the cheap-looking
  -- default ". - X" with clean caption glyphs. Each is a formatted cell;
  -- hover brightens, and close turns red like a native title bar.
  local function btn(glyph, fg, bg)
    return wezterm.format({
      { Attribute = { Intensity = 'Bold' } }, -- Bold+Italic tag -> Medium via font_rules
      { Attribute = { Italic = true } },
      { Background = { Color = bg } },
      { Foreground = { Color = fg } },
      { Text = ' ' .. glyph .. ' ' },
    })
  end
  local ts = config.tab_bar_style
  ts.window_hide           = btn(BTN_HIDE,  P.bar.fg_dim, P.bar.bg)
  ts.window_hide_hover     = btn(BTN_HIDE,  P.bar.fg,     P.brights[1])
  ts.window_maximize       = btn(BTN_MAX,   P.bar.fg_dim, P.bar.bg)
  ts.window_maximize_hover = btn(BTN_MAX,   P.bar.fg,     P.brights[1])
  ts.window_close          = btn(BTN_CLOSE, P.bar.fg_dim, P.bar.bg)
  ts.window_close_hover    = btn(BTN_CLOSE, '#ffffff',    P.ansi[2]) -- red, like a real titlebar

  wezterm.on('update-status', function(window, pane)
    -- LEFT: a COPY / SEARCH mode pill while that key table is active, else workspace.
    local kt = window:active_key_table()
    if kt == 'copy_mode' then
      window:set_left_status(render_pill(ICON_COPY .. ' COPY', P.brights[3], P.bar.bg))
    elseif kt == 'search_mode' then
      window:set_left_status(render_pill(ICON_FIND .. ' SEARCH', P.accent, P.bar.bg))
    else
      local ws = window:active_workspace()
      window:set_left_status(render_pill(ICON_WS .. ' ' .. ws, P.brights[7], P.bar.bg))
    end

    -- RIGHT: cwd · host · clock · battery. Each label is followed by its icon
    -- (sravioli puts the glyph on the RIGHT), brightening toward the edge.
    local segs = {}

    local path, host = cwd_and_host(pane:get_current_working_dir())
    local sp = display_cwd(path)
    if sp then
      segs[#segs + 1] = { text = sp .. ' ' .. ICON_CWD, fg = INK, bg = TONE[1] }
    end

    host = host or wezterm.hostname()
    if host and host ~= '' then
      host = host:gsub('%..*$', '')           -- strip domain suffix
      host = host:gsub('^%l', string.upper)   -- capitalize (sravioli does this)
      segs[#segs + 1] = { text = host .. ' ' .. ICON_HOST, fg = INK, bg = TONE[2] }
    end

    segs[#segs + 1] = {
      text = wezterm.strftime('%a %b %d %H:%M') .. ' ' .. clock_icon(),
      fg = INK, bg = TONE[3],
    }

    local batts = wezterm.battery_info()
    if batts and #batts > 0 then
      local b = batts[1]
      local pct = math.floor(b.state_of_charge * 100 + 0.5)
      segs[#segs + 1] = { text = pct .. '% ' .. batt_icon(b.state, pct), fg = INK, bg = TONE[4] }
    end

    window:set_right_status(render_right(segs))
  end)

  -- Tabs. The active tab fills with the accent color; inactive tabs are a
  -- subtle slate. The tab NUMBER is always shown (so tabs stay distinguishable
  -- even when several share a directory); a small dot trails the label of a
  -- background tab that has produced new output.
  wezterm.on('format-tab-title', function(tab, tabs, panes, conf, hover, max_width)
    local idx    = tab.tab_index
    local active = tab.is_active

    -- unseen output on a background tab -> trailing activity dot
    local unseen = false
    if not active then
      for _, p in ipairs(tab.panes) do
        local ok, u = pcall(function() return p.has_unseen_output end)
        if ok and u then unseen = true break end
      end
    end

    local num   = num_icon(idx + 1)
    -- Cells around the label: "N " on the fancy bar; edge + " N " + " " +
    -- edge on the retro bar; plus " ●" when there's unseen output.
    local reserve = wezterm.column_width(num) + (S.fancy_tabs and 1 or 6)
      + (unseen and 2 or 0)
    local label = tab_label(tab.active_pane, tab.tab_title, max_width,
      conf and conf.tab_max_width, reserve)
    if unseen then label = label .. ' ' .. ICON_NOTIFY end

    -- Fancy bar: plain text. WezTerm draws the rounded tab, its × button and
    -- the colors (colors.tab_bar in appearance.lua) itself.
    if S.fancy_tabs then
      return num .. ' ' .. label
    end

    -- Retro bar: slanted tabs. Fill color (sravioli draws the tab in its
    -- "foreground" color).
    local fill
    if active then
      fill = P.accent
    elseif hover then
      fill = P.subtle
    else
      fill = P.brights[1]
    end
    local ink = P.bar.bg

    -- Medium weight for the whole tab (Bold+Italic tag -> font_rules)
    local out = medium()
    -- left edge: half-block for the first tab, slanted triangle thereafter
    push(out, P.bar.bg, fill, idx == 0 and TB_LEFTMOST or TB_LEFT)
    -- always-visible tab number, then the label, on the filled body
    push(out, fill, ink, ' ' .. num .. ' ')
    push(out, fill, ink, label .. ' ')
    -- right edge: solid block + lower-left triangle, slanting back into the bar
    push(out, P.bar.bg, fill, BLOCK .. TB_RIGHT)
    return out
  end)
end

return M
