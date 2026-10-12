-- ~/.config/wezterm/keymaps.lua
--
-- Warp-flavoured shortcuts, adapted for Windows/WSL.
--
-- On macOS Warp uses Cmd. On Windows that maps to Ctrl, but a few Ctrl combos
-- are sacred to the shell, so they're protected here:
--   Ctrl+C  -> SIGINT (but copies first IF text is selected — best of both)
--   Ctrl+D  -> EOF / logout (NOT stolen; splits use Ctrl+Shift+D / Ctrl+Alt+D)
--   Ctrl+R  -> reverse history search (left alone)
--   Ctrl+L  -> clear screen (left alone)
--   Ctrl+A/E/Z, etc. -> left alone
--
-- One trade-off you should know: Ctrl+W closes the tab (Warp-like), which
-- shadows the shell's "delete word back". You can still delete a word with
-- Alt+Backspace. If you'd rather keep Ctrl+W for the shell, change the line
-- below to CTRL|SHIFT.

local wezterm = require('wezterm')
local act = wezterm.action
local M = {}

-- ── Why new tabs/splits need special handling in WSL ──────────────────
-- A FRESH window lands in your Linux $HOME because the WSL domain's
-- default_cwd = '~' (domains.lua) is passed to `wsl --cd ~`. A NEW TAB or
-- SPLIT doesn't get that: WezTerm first inherits the current pane's cwd, and
-- a WSL pane reports it as the Windows-side /mnt/c/... path, so it lands there.
--
-- An explicit cwd = '~' overrides that inheritance and also goes to
-- `wsl --cd ~`, i.e. your Linux $HOME whatever the distro or username. Outside
-- WSL (native Linux/macOS, a PowerShell tab) cwd stays nil and new panes
-- inherit the current directory like a normal terminal.
local function home_cwd(pane)
  if pane:get_domain_name():find('^WSL:') then return '~' end
end

-- New tab in your default shell (domains.lua). Used by Ctrl+T, Ctrl+Shift+T
-- and the "+" button, so every way of opening a tab lands in the same place.
local function spawn_tab_home(window, pane)
  window:mux_window():spawn_tab({ domain = 'DefaultDomain', cwd = home_cwd(pane) })
end

-- New window, same rule (WezTerm's own SpawnWindow would inherit /mnt/c/...).
local function spawn_window_home(_window, pane)
  wezterm.mux.spawn_window({ domain = 'DefaultDomain', cwd = home_cwd(pane) })
end

-- Split helper: the new pane runs in the SAME shell/distro as the current
-- one. The explicit domain matters: without it a split from a WSL pane can
-- come up as cmd.exe.
local function split_home(direction)
  return wezterm.action_callback(function(_window, pane)
    pane:split({ direction = direction, domain = 'CurrentPaneDomain', cwd = home_cwd(pane) })
  end)
end

-- Maximize <-> restore. Also rescues a window that slid under the taskbar or
-- off screen. WezTerm can't report "maximized", so a window (nearly) as wide
-- as its screen counts as maximized; the slack absorbs frame/border pixels.
local function toggle_maximize(window, _pane)
  local screen = wezterm.gui.screens().active
  if window:get_dimensions().pixel_width >= screen.width - 32 then
    window:restore()
  else
    window:maximize()
  end
end

-- Quit all local workspaces, including hidden ones. Only this action bypasses
-- window confirmation; ordinary window/tab close keeps its safety prompt.
local function quit_without_confirmation(window, pane)
  local overrides = window:get_config_overrides() or {}
  overrides.window_close_confirmation = 'NeverPrompt'
  window:set_config_overrides(overrides)
  window:perform_action(act.QuitApplication, pane)
end

-- Ctrl+C that copies a selection if you have one, else sends a real SIGINT.
local function smart_copy_or_interrupt(window, pane)
  local sel = window:get_selection_text_for_pane(pane)
  if sel and sel ~= '' then
    window:perform_action(act.CopyTo('ClipboardAndPrimarySelection'), pane)
    window:perform_action(act.ClearSelection, pane)
  else
    window:perform_action(act.SendKey({ key = 'c', mods = 'CTRL' }), pane)
  end
end

function M.apply(config)
  config.keys = {
    -- ── Tabs ───────────────────────────────────────────────
    -- Ctrl+T opens a new tab in the WSL home (in WSL) / current dir (elsewhere).
    { key = 't',   mods = 'CTRL',       action = wezterm.action_callback(spawn_tab_home) },
    -- Ctrl+Shift+T (WezTerm's own new-tab key) does the same instead of inheriting /mnt/c/...
    { key = 't',   mods = 'CTRL|SHIFT', action = wezterm.action_callback(spawn_tab_home) },
    -- Ctrl+W closes the current tab AFTER confirming.
    { key = 'w',   mods = 'CTRL',       action = act.CloseCurrentTab({ confirm = true }) },
    -- Ctrl+Shift+E renames the current tab (the name sticks and shows in the bar).
    { key = 'e',   mods = 'CTRL|SHIFT', action = act.PromptInputLine({
        description = 'Rename tab (empty = clear):',
        action = wezterm.action_callback(function(window, pane, line)
          -- line is nil if you press Esc; "" if you submit empty (clears the name)
          if line ~= nil then window:active_tab():set_title(line) end
        end),
    }) },
    -- Ctrl+Tab switches to the next tab.
    { key = 'Tab', mods = 'CTRL',       action = act.ActivateTabRelative(1) },
    -- Ctrl+Shift+Tab switches to the previous tab.
    { key = 'Tab', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
    -- Ctrl+Shift+] switches to the next tab.
    { key = ']',   mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(1) },
    -- Ctrl+Shift+[ switches to the previous tab.
    { key = '[',   mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
    -- Ctrl+Shift+} moves the current tab one position to the right.
    { key = '}',   mods = 'CTRL|SHIFT', action = act.MoveTabRelative(1) },
    -- Ctrl+Shift+{ moves the current tab one position to the left.
    { key = '{',   mods = 'CTRL|SHIFT', action = act.MoveTabRelative(-1) },

    -- ── Windows ────────────────────────────────────────────
    -- Destructive: quit the entire app, not just the visible workspace.
    { key = 'F4', mods = 'ALT', action = wezterm.action_callback(quit_without_confirmation) },
    { key = 'q', mods = 'CTRL|ALT|SHIFT', action = wezterm.action_callback(quit_without_confirmation) },
    -- Ctrl+Shift+N opens a new WezTerm window (in the WSL home, like Ctrl+T).
    { key = 'n', mods = 'CTRL|SHIFT', action = wezterm.action_callback(spawn_window_home) },
    -- Ctrl+Alt+Enter maximizes the window, or restores it if already maximized.
    { key = 'Enter', mods = 'CTRL|ALT', action = wezterm.action_callback(toggle_maximize) },

    -- ── Panes / splits ─────────────────────────────────────
    -- Ctrl+Shift+D splits the current pane horizontally, creating a pane on the right.
    { key = 'd',     mods = 'CTRL|SHIFT', action = split_home('Right') },
    -- Ctrl+Alt+D splits the current pane vertically, creating a pane below.
    { key = 'd',     mods = 'CTRL|ALT',   action = split_home('Bottom') },
    -- Ctrl+Shift+W closes the current pane immediately, no confirmation (an
    -- unsplit tab closes with it).
    { key = 'w',     mods = 'CTRL|SHIFT', action = act.CloseCurrentPane({ confirm = false }) },
    -- Ctrl+Shift+Enter maximizes the current pane or restores it if already zoomed.
    { key = 'Enter', mods = 'CTRL|SHIFT', action = act.TogglePaneZoomState },

    -- Ctrl+Shift+Left moves focus to the pane on the left.
    { key = 'LeftArrow',  mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Left') },
    -- Ctrl+Shift+Right moves focus to the pane on the right.
    { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Right') },
    -- Ctrl+Shift+Up moves focus to the pane above.
    { key = 'UpArrow',    mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Up') },
    -- Ctrl+Shift+Down moves focus to the pane below.
    { key = 'DownArrow',  mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection('Down') },

    -- Ctrl+Alt+Left shrinks the current pane toward the left by 3 cells.
    { key = 'LeftArrow',  mods = 'CTRL|ALT', action = act.AdjustPaneSize({ 'Left', 3 }) },
    -- Ctrl+Alt+Right expands the current pane toward the right by 3 cells.
    { key = 'RightArrow', mods = 'CTRL|ALT', action = act.AdjustPaneSize({ 'Right', 3 }) },
    -- Ctrl+Alt+Up shrinks the current pane upward by 3 cells.
    { key = 'UpArrow',    mods = 'CTRL|ALT', action = act.AdjustPaneSize({ 'Up', 3 }) },
    -- Ctrl+Alt+Down expands the current pane downward by 3 cells.
    { key = 'DownArrow',  mods = 'CTRL|ALT', action = act.AdjustPaneSize({ 'Down', 3 }) },

    -- ── Clipboard ──────────────────────────────────────────
    -- Ctrl+C copies selected text, or sends Ctrl+C to the shell when nothing is selected.
    { key = 'c', mods = 'CTRL',       action = wezterm.action_callback(smart_copy_or_interrupt) },
    -- Ctrl+V pastes text from the clipboard.
    { key = 'v', mods = 'CTRL',       action = act.PasteFrom('Clipboard') },
    -- Ctrl+Shift+C copies selected text to the clipboard.
    { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo('Clipboard') },
    -- Ctrl+Shift+V pastes text from the clipboard.
    { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom('Clipboard') },

    -- ── Search / select / palette ──────────────────────────
    -- Warp uses Cmd+F; here it's Ctrl+Shift+F so vim/less keep Ctrl+F (page down).
    -- Ctrl+Shift+F opens search, prefilled with the current selection if there is one.
    { key = 'f', mods = 'CTRL|SHIFT', action = act.Search('CurrentSelectionOrEmptyString') },
    -- Ctrl+Shift+X enters copy mode for vim-like scrolling and text selection.
    { key = 'x', mods = 'CTRL|SHIFT', action = act.ActivateCopyMode },
    -- Ctrl+Shift+P opens the WezTerm command palette.
    { key = 'p', mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },
    -- Ctrl+Shift+Space opens quick select so you can jump to detected URLs, paths, and text.
    { key = ' ', mods = 'CTRL|SHIFT', action = act.QuickSelect },

    -- ── Clear screen + scrollback (Warp's Cmd+K) ───────────
    -- Ctrl+Shift+K clears the scrollback and viewport, then sends Ctrl+L to clear the shell screen.
    { key = 'k', mods = 'CTRL|SHIFT', action = act.Multiple({
        act.ClearScrollback('ScrollbackAndViewport'),
        act.SendKey({ key = 'L', mods = 'CTRL' }),
    }) },

    -- ── Font size ──────────────────────────────────────────
    -- Ctrl+= increases the terminal font size.
    { key = '=', mods = 'CTRL', action = act.IncreaseFontSize },
    -- Ctrl+- decreases the terminal font size.
    { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
    -- Ctrl+0 resets the terminal font size to the configured default.
    { key = '0', mods = 'CTRL', action = act.ResetFontSize },

    -- ── Scrolling ──────────────────────────────────────────
    -- Shift+PageUp scrolls one page up through the terminal scrollback.
    { key = 'PageUp',   mods = 'SHIFT', action = act.ScrollByPage(-1) },
    -- Shift+PageDown scrolls one page down through the terminal scrollback.
    { key = 'PageDown', mods = 'SHIFT', action = act.ScrollByPage(1) },

    -- ── Reload this config ─────────────────────────────────
    -- Ctrl+Shift+R reloads the WezTerm configuration.
    { key = 'r', mods = 'CTRL|SHIFT', action = act.ReloadConfiguration },
  }

  -- Ctrl+1 through Ctrl+9 jumps directly to tabs 1 through 9, matching Warp's Cmd+1..9.
  for i = 1, 9 do
    table.insert(config.keys, {
      key = tostring(i),
      mods = 'CTRL',
      action = act.ActivateTab(i - 1),
    })
  end

  config.disable_default_key_bindings = false -- keep WezTerm's other sensible defaults

  -- ── Links ──────────────────────────────────────────────
  -- WezTerm's defaults open a link on a plain click (only if the mouse didn't
  -- move, and only when the program isn't capturing the mouse) or Shift+click
  -- (inside mouse-capturing programs like vim/htop). Ctrl+click — the Windows
  -- Terminal / VS Code habit — does nothing by default, so add it, both for
  -- normal panes and for programs that capture the mouse. The Down event is
  -- swallowed so the program never sees half a click.
  config.mouse_bindings = {}
  for _, reporting in ipairs({ false, true }) do
    table.insert(config.mouse_bindings, {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      mouse_reporting = reporting,
      action = act.OpenLinkAtMouseCursor,
    })
    table.insert(config.mouse_bindings, {
      event = { Down = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      mouse_reporting = reporting,
      action = act.Nop,
    })
  end

  -- Confirmation (Ctrl+W, middle-clicking a tab, a fancy-bar ×) is
  -- skipped only when the pane runs nothing but a plain shell. To Windows a
  -- WSL pane is always wsl.exe, so in WSL it always asks — intentionally.

  -- The "+" button: left-click opens a tab exactly like Ctrl+T.
  -- workspaces.lua handles right-click; middle-click opens the shell launcher.
  wezterm.on('new-tab-button-click', function(window, pane, button, _default_action)
    if button == 'Left' then
      spawn_tab_home(window, pane)
      return false -- skip the default SpawnTab
    elseif button == 'Middle' then
      window:perform_action(act.ShowLauncherArgs({ flags = 'FUZZY|DOMAINS|LAUNCH_MENU' }), pane)
      return false
    end
  end)

  -- ─────────────────────────────────────────────────────────
  -- WANT IT *EXACTLY* LIKE WARP? (overrides shell keys — your call)
  -- Uncomment these to mirror Warp 1:1. They will shadow vim page-down
  -- and the shell's EOF, so only do this if you don't rely on them.
  --
  -- Ctrl+F would open search, but would also shadow vim/less page-down.
  -- table.insert(config.keys, { key = 'f', mods = 'CTRL',
  --   action = act.Search('CurrentSelectionOrEmptyString') })
  -- Ctrl+D would split the current pane horizontally, but would also shadow shell EOF/logout.
  -- table.insert(config.keys, { key = 'd', mods = 'CTRL',
  --   action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) })
  -- ─────────────────────────────────────────────────────────
end

return M
