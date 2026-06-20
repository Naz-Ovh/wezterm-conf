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

-- ── Why new tabs/splits need special handling on Windows ──────────────
-- A FRESH window lands in your Linux $HOME because the WSL domain's
-- default_cwd = '~' (domains.lua) is passed verbatim to `wsl --cd ~`, and a
-- fresh window has no parent pane to inherit from. A NEW TAB can't reuse that:
-- per WezTerm's rules it resolves cwd from the current pane FIRST (before
-- default_cwd ever applies), and a WSL pane reports its directory as the
-- Windows-mapped /mnt/c/... path — so the tab lands there.
--
-- The only thing that overrides that inheritance is an explicit cwd, and it
-- must be the ABSOLUTE Linux path: for an explicit spawn cwd WezTerm expands
-- '~' to the *Windows* home (C:\Users\you) before launching wsl, so '~' would
-- give /mnt/c. We can't discover the real path without a child process — which
-- is illegal at config-load (yields) and doesn't run in key callbacks — so it's
-- set here as a one-line constant. Off Windows it stays nil and tabs/splits
-- inherit the current directory like a normal terminal.
local IS_WINDOWS = wezterm.target_triple:find('windows') ~= nil
-- 👇 Your WSL home. Change it if your Linux username isn't 'bns'
--    (run `wsl -- bash -c 'echo $HOME'` to check).
local WSL_HOME = IS_WINDOWS and '~' or nil

-- New tab in the WSL home (Windows) / current dir elsewhere. Spawns via mux so
-- the absolute cwd goes straight to `wsl --cd /home/...`, like a fresh launch.
local function spawn_tab_home(window, _pane)
  window:mux_window():spawn_tab({ cwd = WSL_HOME }) -- nil => inherit/default cwd
end

-- Split helper: same path, so a new pane also opens in WSL_HOME on Windows
-- (and inherits the current dir on Linux/macOS, where WSL_HOME is nil).
local function split_home(direction)
  return wezterm.action_callback(function(_window, pane)
    pane:split({ direction = direction, cwd = WSL_HOME })
  end)
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
    -- Ctrl+T opens a new tab in the WSL home (Windows) / current dir (elsewhere).
    { key = 't',   mods = 'CTRL',       action = wezterm.action_callback(spawn_tab_home) },
    -- Ctrl+W closes the current tab immediately without asking for confirmation.
    { key = 'w',   mods = 'CTRL',       action = act.CloseCurrentTab({ confirm = false }) },
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
    -- Ctrl+Shift+N opens a new WezTerm window.
    { key = 'n', mods = 'CTRL|SHIFT', action = act.SpawnWindow },

    -- ── Panes / splits ─────────────────────────────────────
    -- Ctrl+Shift+D splits the current pane horizontally, creating a pane on the right.
    { key = 'd',     mods = 'CTRL|SHIFT', action = split_home('Right') },
    -- Ctrl+Alt+D splits the current pane vertically, creating a pane below.
    { key = 'd',     mods = 'CTRL|ALT',   action = split_home('Bottom') },
    -- Ctrl+Shift+W closes the current pane immediately without asking for confirmation.
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
