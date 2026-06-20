# WezTerm config (modular, WSL-default, Warp-style keys)

## Install (Windows)

WezTerm is a **Windows** app, so the config lives in your **Windows** home,
NOT inside WSL. Put all the `.lua` files in:

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
├─ palette.lua      # ← colors live here
├─ appearance.lua   # fonts, window chrome, window buttons, light/dark
├─ domains.lua      # ← set your WSL distro name here
├─ keymaps.lua      # Warp-style shortcuts
├─ workspaces.lua   # ← your projects + the project picker
└─ bar.lua          # the themed status panel (pills)
```

## First steps

1. Open `domains.lua`, set `WSL_DISTRO` to your distro
   (run `wsl -l -q` in PowerShell to see the exact name).
2. Launch WezTerm. It should drop you straight into WSL with the themed bar
   (tabs + status + window buttons) across the top.
3. Edit any file and save — it reloads live. Or press `Ctrl+Shift+R`.

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
  so they always sit together, at the top or at the bottom. Two knobs in
  `appearance.lua` control this:
  - `window_decorations`:
    - `'INTEGRATED_BUTTONS | RESIZE'` *(default)* — frameless, themed buttons
      drawn into our own bar. No white native title bar. Tweak which buttons
      show via `integrated_title_buttons`.
    - `'TITLE | RESIZE'` — native title bar (buttons top-right) but it follows
      Windows and goes **white in OS light mode**, clashing with the theme.
    - `'RESIZE'` — totally bare, no buttons.
  - `tab_bar_at_bottom`:
    - `false` *(default)* — bar + buttons at the **top** (Warp-style).
    - `true` — bar + buttons at the **bottom**.

## Notes

- The path pill needs your WSL shell to emit OSC 7 (most modern prompts —
  starship, oh-my-zsh, etc. — already do). If it's blank, the pill just hides.
- Fonts: `JetBrains Mono` + `Symbols Nerd Font Mono` ship with WezTerm, so
  icons work with no extra install.

## Session save/restore — removed

There used to be a `session.lua` that restored tabs/panes across restarts via
the `resurrect` GitHub plugin. It was removed: it needs to `git clone` a plugin
on Windows (which caused the startup window-flashing) and depends on an
archived, unmaintained project. Your `Ctrl+Shift+S` / `Ctrl+Shift+E` keys are
now free again. The `workspaces.lua` project picker covers the day-to-day need —
re-launch a project layout from scratch with `Ctrl+Shift+O`.
