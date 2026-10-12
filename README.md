# WezTerm config (modular, cross-platform, Warp-style keys)

Works unchanged on **Windows + WSL** (any distro), **native Linux** and
**macOS**. Everything machine-dependent is a variable in `settings.lua` and is
auto-detected, so there's nothing to set up per machine.

## Install

On Linux/macOS put the `.lua` files in `~/.config/wezterm/`.

On Windows, WezTerm is a **Windows** app, so the config lives in your
**Windows** home, NOT inside WSL. Put all the `.lua` files in:

```
C:\Users\<YOU>\.config\wezterm\
```

Quick way (PowerShell):

```powershell
mkdir "$env:USERPROFILE\.config\wezterm" -Force
# then copy the .lua files into that folder
```

Final layout:

```
C:\Users\<YOU>\.config\wezterm\
├─ wezterm.lua      # entry point (don't really need to touch)
├─ settings.lua     # ← every machine-dependent variable (auto-detected)
├─ machine.lua      # ← OPTIONAL per-machine overrides (git-ignored)
├─ palette.lua      # ← colors live here
├─ appearance.lua   # fonts, window chrome, window buttons, light/dark
├─ domains.lua      # default shell: WSL on Windows, login shell elsewhere
├─ keymaps.lua      # Warp-style shortcuts
├─ workspaces.lua   # ← your projects + the project picker
└─ bar.lua          # the themed status panel (pills)
```

## First steps

1. Launch WezTerm. On Windows it drops you straight into WSL — it prefers a
   distro matching `Fedora`, then `Ubuntu`, else whichever is installed. On
   Linux/macOS you get your login shell.
2. Edit any file and save — it reloads live. Or press `Ctrl+Shift+R`.

## Per-machine settings

`settings.lua` holds the variables: `wsl_distros`, `shell`, `projects_dir`,
`startup_project`, `font`, `font_size`, `front_end`, `bar_at_bottom`,
`fancy_tabs`. Don't edit it per
machine — create a `machine.lua` next to it returning only what differs:

```lua
-- machine.lua (git-ignored)
return {
  wsl_distros = { 'Ubuntu' },      -- prefer Ubuntu on this PC (false = PowerShell)
  shell = { 'fish', '-l' },        -- instead of the login shell
  projects_dir = '/home/me/code',
  startup_project = 'mia_medical', -- open this workspace at launch
  font_size = 12,
}
```

Every installed WSL distro is always available from the shell launcher:
**middle-click the `+` button** in the tab bar. Left-click opens a new tab;
right-click opens the workspace switcher.

## Quit everything and switch workspaces

| Control | Action |
| --- | --- |
| `Alt+F4` or `Ctrl+Alt+Shift+Q` | Quit this WezTerm instance, including all hidden local workspaces, **without confirmation** |
| Window close button (`×`) | Close the current window with the normal safety prompt; not a global quit |
| Right-click `+` | Show all open workspaces, their pane counts, and the current-workspace marker; click a row to switch |
| `Ctrl+Shift+L` | Open the same searchable workspace switcher |
| `Ctrl+Shift+,` / `Ctrl+Shift+.` | Previous / next workspace |
| `Ctrl+Shift+O` | Open a configured project layout, or switch to it if already open |
| `Ctrl+Shift+Q` | Pick one workspace to close, with confirmation (Shift+select skips it) |

The left status pill shows the current workspace and total open count, e.g.
`mia_medical [3]`. It updates every second; copy/search mode temporarily shows
its original mode indicator instead. On WezTerm 20240203 the status pill itself
is display-only; right-click the original `+` button for mouse switching.
Both retro and fancy tab bars support the button's mouse actions.

**Warning:** the quit shortcuts close terminal sessions abruptly, so unsaved
work can be lost. They do not send a graceful `Ctrl+C` to every program, shut
down WSL itself, or guarantee that detached jobs, services, Docker containers,
or independent tmux/remote mux sessions stop. Independently started WezTerm
instances are not affected. Ordinary tab/window close prompts remain enabled.

## Customizing

- **Colors / theme:** edit `palette.lua` only. Change `accent`, `dark.bg`,
  `dim.bg`, the `ansi` table, etc. Everything else reads from it.
- **Light/dark rule:** OS Dark → pure black; OS Light → lifted dark.
  Set both in `palette.lua` (`dark` and `dim`). The bar stays dark always.
- **Keybindings:** edit `keymaps.lua`. There's a "want it exactly like Warp"
  block at the bottom you can uncomment.
- **Bar contents:** edit `bar.lua` (`update-status`). Add/remove pills.
- **Bar not visible enough / too dark:** raise `bar.bg` in `palette.lua`
  (e.g. `#1b1c25`). Lower it toward `#000000` to make it blacker.
- **Window buttons + dragging + bar position.** WezTerm has only ONE bar (the
  tab bar), and both the status pills and the window buttons live inside it —
  so they always sit together, at the top or at the bottom. Two knobs
  control this:
  - `window_decorations` (`appearance.lua`):
    - `'INTEGRATED_BUTTONS | RESIZE'` *(default)* — frameless, themed buttons
      drawn into our own bar. No white native title bar. Tweak which buttons
      show via `integrated_title_buttons`.
    - `'TITLE | RESIZE'` — native title bar (buttons top-right) but it follows
      Windows and goes **white in OS light mode**, clashing with the theme.
    - `'RESIZE'` — totally bare, no buttons.
  - `bar_at_bottom` (`settings.lua` / `machine.lua`):
    - `false` *(default)* — bar + buttons at the **top** (Warp-style). Safer:
      the bar can't slide under the taskbar or off screen.
    - `true` — bar + buttons at the **bottom**.
- **Window lost under the taskbar / off screen?** `Ctrl+Alt+Enter` toggles
  maximize (Windows' own `Win+Up` / `Win+Down` work too).

## Notes

- The path pill needs your WSL shell to emit OSC 7 (most modern prompts —
  starship, oh-my-zsh, etc. — already do). If it's blank, the pill just hides.
- Fonts: the default `JetBrainsMono Nerd Font` must be installed; without it
  WezTerm falls back to its built-in JetBrains Mono, and `Symbols Nerd Font
  Mono` (also built in) keeps the icons working. Change `font` per machine.

## Session save/restore — removed

There used to be a `session.lua` that restored tabs/panes across restarts via
the `resurrect` GitHub plugin. It was removed: it needs to `git clone` a plugin
on Windows (which caused the startup window-flashing) and depends on an
archived, unmaintained project. Your `Ctrl+Shift+S` / `Ctrl+Shift+E` keys are
now free again. The `workspaces.lua` project picker covers the day-to-day need —
re-launch a project layout from scratch with `Ctrl+Shift+O`.
