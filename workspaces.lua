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
local M = {}

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
-- Paths are WSL paths (e.g. /home/you/...), because WSL is the default.
local projects = {
  {
    label = 'Mia Medical',
    workspace = 'mia_medical',
    cwd = '/mnt/wsl/Projects/project/coderov/mia-medical', -- ← change to your real path
    panes = {
      { id = 'web',   from = 'edit', dir = 'Right',  size = 0.40,},
      { id = 'shell', from = 'web',  dir = 'Right', size = 0.45 },     -- spare shell
    },
  },
  {
    label = 'Fugitive-Club',
    workspace = 'fugitives.club',
    panes = {
      { id = 'edit', size = 0.50,  cwd = '/mnt/wsl/Projects/project/jobs/altlantis/fugitive-club/Fugitive_Server'  },
      { id = 'run',  from = 'edit', dir = 'Right', size = 0.50,  cwd = '/mnt/wsl/Projects/project/jobs/altlantis/fugitive-club/Fugitive_Client' },
    },
  },
}

-- ── Layout builder (you rarely need to touch below this line) ─────
local function build(proj)
  local _tab, base = mux.spawn_window({
    workspace = proj.workspace,
    cwd = proj.cwd,
  })

  local by_id = {}
  local specs = proj.panes or { { id = 'main' } }

  by_id[specs[1].id or 1] = base
  if specs[1].run then base:send_text(specs[1].run .. '\n') end

  for i = 2, #specs do
    local s = specs[i]
    local src = by_id[s.from] or base
    local p = src:split({
      direction = s.dir or 'Right',
      size = s.size or 0.5,
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

  -- ── OPTIONAL: auto-open a project when WezTerm launches ─────────
  -- Uncomment and pick the workspace you want to land in. Leaving it
  -- commented just starts a plain default WSL window.
  --
  -- wezterm.on('gui-startup', function()
  --   for _, p in ipairs(projects) do
  --     if p.workspace == 'hedera' then build(p) end
  --   end
  --   mux.set_active_workspace('hedera')
  -- end)
end

return M
