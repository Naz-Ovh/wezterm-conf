-- ~/.config/wezterm/workspaces.lua
--
-- Projects-as-workspaces. Each project is a named workspace with a
-- pre-built pane layout — your "launch configurations" / Warp tab configs.
--
-- Keys this adds:
--   Ctrl+Shift+O   open a project from your list (builds it, or jumps to it)
--   Ctrl+Shift+L   fuzzy-switch between workspaces that are already OPEN
--   Ctrl+Shift+,   previous workspace
--   Ctrl+Shift+.   next workspace
--   Ctrl+Alt+W     rename the current workspace

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
    label = 'Fugitive-Club',
    workspace = 'fugitives.club',
    panes = {
      { id = 'edit', size = 0.50,  cwd = path('jobs/altlantis/fugitive-club/Fugitive_Server') },
      { id = 'run',  from = 'edit', dir = 'Right', size = 0.50,  cwd = path('jobs/altlantis/fugitive-club/Fugitive_Client') },
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

function M.apply(config)
  config.keys = config.keys or {}

  local extra = {
    { key = 'o', mods = 'CTRL|SHIFT', action = wezterm.action_callback(picker) },
    { key = 'l', mods = 'CTRL|SHIFT', action = act.ShowLauncherArgs({ flags = 'FUZZY|WORKSPACES' }) },
    { key = ',', mods = 'CTRL|SHIFT', action = act.SwitchWorkspaceRelative(-1) },
    { key = '.', mods = 'CTRL|SHIFT', action = act.SwitchWorkspaceRelative(1) },
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
