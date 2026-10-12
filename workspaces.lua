-- ~/.config/wezterm/workspaces.lua
--
-- Projects-as-workspaces. Each project is a named workspace with a
-- pre-built pane layout — your "launch configurations" / Warp tab configs.
--
-- Keys this adds:
--   Ctrl+Shift+O   open a project from your list (builds it, or jumps to it)
--   Ctrl+Shift+L   fuzzy-switch between workspaces that are already OPEN
--   Right-click +   same open-workspace picker, with count and pane totals
--   Ctrl+Shift+,   previous workspace
--   Ctrl+Shift+.   next workspace
--   Ctrl+Alt+W     rename the current workspace
--   Ctrl+Shift+Q   pick a workspace and close it (everything in it), after
--                  confirming; Shift+click / Shift+Enter closes without asking

local wezterm = require('wezterm')
local act = wezterm.action
local mux = wezterm.mux
local S = require('settings')
local M = {}

-- A path under settings.projects_dir, so the same list works on every machine.
local function path(rel) return S.projects_dir .. '/' .. rel end

-- ════════════════════════════════════════════════════════════════
--  YOUR PROJECTS  ← this is the only part you normally edit
-- ════════════════════════════════════════════════════════════════
--
-- Each entry = one workspace. `panes` describes the layout:
--   id    : a name you pick, so later panes can split off it
--   from  : split off the pane with this id  (omit for the FIRST pane)
--   dir   : 'Right' | 'Left' | 'Top' | 'Bottom'
--   size  : fraction (0..1) of the pane being split
--   run   : a command to type & run there (optional)
--   cwd   : override the project cwd for that pane (optional)
--
-- Wrap paths in path('...') so they're relative to settings.projects_dir
-- (a WSL path on Windows, ~/Projects/project elsewhere by default).
local projects = {
  {
    label = 'Mia Medical',
    workspace = 'mia_medical',
    cwd = path('coderov/mia-medical'),
    panes = {
      { id = 'web',   from = 'edit', dir = 'Right',  size = 0.40,},
      { id = 'shell', from = 'web',  dir = 'Right', size = 0.45 },     -- spare shell
    },
  },
  {
    -- [Client][Server ]
    --         [Server ]
    label = 'Fugitive-Club',
    workspace = 'fugitives.club',
    cwd = path('jobs/altlantis/fugitive-club/Fugitive_Workspace'),
    panes = {
      { id = 'client', cwd = path('jobs/altlantis/fugitive-club/Fugitive_Workspace/Client') },
      { id = 'server', from = 'client', dir = 'Right',  size = 0.50, cwd = path('jobs/altlantis/fugitive-club/Fugitive_Workspace/Server') },
      { id = 'server2', from = 'server', dir = 'Bottom', size = 0.50, cwd = path('jobs/altlantis/fugitive-club/Fugitive_Workspace/Server') },
    },
  },
}

-- ── Layout builder (you rarely need to touch below this line) ─────
local function build(proj)
  local specs = proj.panes or { { id = 'main' } }
  local _tab, base = mux.spawn_window({
    workspace = proj.workspace,
    cwd = specs[1].cwd or proj.cwd,
  })

  local by_id = {}

  by_id[specs[1].id or 1] = base
  if specs[1].run then base:send_text(specs[1].run .. '\n') end

  for i = 2, #specs do
    local s = specs[i]
    local src = by_id[s.from] or base
    local p = src:split({
      direction = s.dir or 'Right',
      size = s.size or 0.5,
      domain = 'CurrentPaneDomain', -- stay in WSL (without it, splits can be cmd.exe)
      cwd = s.cwd or proj.cwd,
    })
    by_id[s.id or i] = p
    if s.run then p:send_text(s.run .. '\n') end
  end

  base:activate() -- focus the first pane
end

local function exists(name)
  for _, w in ipairs(mux.get_workspace_names()) do
    if w == name then return true end
  end
  return false
end

-- Build the project if it isn't open yet, then switch to it.
local function launch(proj)
  if not exists(proj.workspace) then
    build(proj)
  end
  mux.set_active_workspace(proj.workspace)
end

-- ── The picker (your Warp-style launch list) ─────────────────────
local function picker(window, pane)
  local choices = {}
  for _, p in ipairs(projects) do
    table.insert(choices, { id = p.workspace, label = p.label })
  end
  window:perform_action(
    act.InputSelector({
      title = ' Open project ',
      fuzzy = true,
      choices = choices,
      action = wezterm.action_callback(function(_win, _pn, id)
        if not id then return end -- escape = cancel
        for _, p in ipairs(projects) do
          if p.workspace == id then
            launch(p)
            return
          end
        end
      end),
    }),
    pane
  )
end

-- ── Switch between open workspaces (keyboard and tab-bar menu) ─────
local function switch_picker(window, pane)
  local names = mux.get_workspace_names()
  table.sort(names)
  local current = window:active_workspace()
  local counts = {}
  for _, win in ipairs(mux.all_windows()) do
    local name = win:get_workspace()
    counts[name] = counts[name] or 0
    for _, tab in ipairs(win:tabs()) do
      counts[name] = counts[name] + #tab:panes()
    end
  end

  local choices = {}
  for _, name in ipairs(names) do
    local n = counts[name] or 0
    choices[#choices + 1] = {
      id = name,
      label = string.format('%s  (%d pane%s)%s', name, n, n == 1 and '' or 's',
        name == current and '  <- current' or ''),
    }
  end
  window:perform_action(act.InputSelector({
    title = string.format(' Switch workspace (%d open) ', #names),
    fuzzy = true,
    choices = choices,
    action = wezterm.action_callback(function(_win, _pn, name)
      if name and exists(name) then mux.set_active_workspace(name) end
    end),
  }), pane)
end

-- ── Close a whole workspace ──────────────────────────────────────
-- WezTerm has no "delete workspace": a workspace exists while it has panes,
-- and Lua can't close panes. So each pane id goes to WezTerm's own CLI
-- (`wezterm cli kill-pane`), which finds this instance through the
-- WEZTERM_UNIX_SOCKET variable the GUI sets for its child processes.
local WEZTERM_CLI = wezterm.executable_dir .. '/wezterm' .. (S.is_windows and '.exe' or '')

local function panes_in(workspace)
  local ids = {}
  for _, win in ipairs(mux.all_windows()) do
    if win:get_workspace() == workspace then
      for _, tab in ipairs(win:tabs()) do
        for _, p in ipairs(tab:panes()) do ids[#ids + 1] = p:pane_id() end
      end
    end
  end
  return ids
end

local function close_workspace(window, name)
  local ids = panes_in(name)
  -- Don't leave the window showing a workspace that's about to vanish.
  if name == window:active_workspace() then
    for _, other in ipairs(mux.get_workspace_names()) do
      if other ~= name then
        mux.set_active_workspace(other)
        break
      end
    end
  end
  for _, id in ipairs(ids) do
    wezterm.background_child_process({ WEZTERM_CLI, 'cli', 'kill-pane', '--pane-id', tostring(id) })
  end
end

-- Pick a workspace, confirm, close it (default answer is "No"). Shift+click
-- or Shift+Enter skips the confirmation: the selector accepts either, and
-- the callback reads which modifiers are still held.
local function close_picker(window, pane)
  local names = mux.get_workspace_names()
  if #names < 2 then
    window:toast_notification('wezterm', "Can't close the only workspace", nil, 3000)
    return
  end
  local current = window:active_workspace()
  local choices = {}
  for _, name in ipairs(names) do
    local n = #panes_in(name)
    table.insert(choices, {
      id = name,
      label = string.format('%s  (%d pane%s)%s', name, n, n == 1 and '' or 's',
        name == current and '  <- current' or ''),
    })
  end
  window:perform_action(
    act.InputSelector({
      title = ' Close workspace (Shift+click: no confirmation) ',
      fuzzy = true,
      choices = choices,
      action = wezterm.action_callback(function(win, pn, name)
        if not name then return end -- escape = cancel
        if (win:keyboard_modifiers() or ''):find('SHIFT') then
          close_workspace(win, name)
          return
        end
        win:perform_action(
          act.InputSelector({
            title = ' Close "' .. name .. '" and everything running in it? ',
            choices = { { id = 'no', label = 'No, keep it' }, { id = 'yes', label = 'Yes, close it' } },
            action = wezterm.action_callback(function(w, _p, answer)
              if answer == 'yes' then close_workspace(w, name) end
            end),
          }),
          pn
        )
      end),
    }),
    pane
  )
end

function M.apply(config)
  config.keys = config.keys or {}

  local extra = {
    { key = 'o', mods = 'CTRL|SHIFT', action = wezterm.action_callback(picker) },
    { key = 'l', mods = 'CTRL|SHIFT', action = wezterm.action_callback(switch_picker) },
    -- phys: = the physical , and . keys. With Shift held they produce < and >,
    -- so a plain ',' / '.' binding would never match.
    { key = 'phys:Comma',  mods = 'CTRL|SHIFT', action = act.SwitchWorkspaceRelative(-1) },
    { key = 'phys:Period', mods = 'CTRL|SHIFT', action = act.SwitchWorkspaceRelative(1) },
    { key = 'q', mods = 'CTRL|SHIFT', action = wezterm.action_callback(close_picker) },
    { key = 'w', mods = 'CTRL|ALT', action = act.PromptInputLine({
        description = 'Rename workspace to: ',
        action = wezterm.action_callback(function(win, _pn, line)
          if line and line ~= '' then
            mux.rename_workspace(win:active_workspace(), line)
          end
        end),
      }) },
  }
  for _, k in ipairs(extra) do
    table.insert(config.keys, k)
  end

  wezterm.on('new-tab-button-click', function(window, pane, button)
    if button == 'Right' then
      switch_picker(window, pane)
      return false
    end
  end)

  -- ── Auto-open a project when WezTerm launches ───────────────────
  -- Set `startup_project` in settings.lua / machine.lua to a workspace id.
  -- nil just starts a plain default-shell window.
  if S.startup_project then
    wezterm.on('gui-startup', function()
      for _, p in ipairs(projects) do
        if p.workspace == S.startup_project then
          launch(p)
          return
        end
      end
      wezterm.log_warn('workspaces.lua: no project "' .. S.startup_project .. '"')
      mux.spawn_window({})
    end)
  end
end

return M
