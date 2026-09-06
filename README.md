# Workspaces Per Monitor

A Windows-style paired dual-monitor Hyprland workspace switcher for the Ryoku shell.

Display 1 (Primary, e.g. `HDMI-A-1`) displays workspaces **1, 2, 3, 4, 5...**, while Display 2 (Secondary, e.g. `eDP-1`) displays paired workspaces **A1, A2, A3, A4, A5...** (backed by integer workspace IDs 11, 12, 13, 14, 15...).

When you switch desktops—via the bar buttons, mouse wheel, or `Ctrl + Super + Left / Right` keyboard shortcuts—both displays advance in sync like Windows virtual desktops, while maintaining focus on whichever screen you are actively using.

## Features

- **Windows-style Synchronized Desktop Switching**: Moving to Desktop 2 simultaneously switches Display 1 to `2` and Display 2 to `A2`.
- **Conflict-Free Workspace IDs**: Hyprland uses distinct integer workspace IDs (`1..5` and `11..15`) so workspaces never collide across monitors.
- **Dynamic Monitor Detection**: Detects which screen the bar surface is rendered on and automatically shows `1..5` on the primary monitor and `A1..A5` on the secondary monitor.
- **Keyboard Shortcuts**: Built-in support for `Ctrl + Super + Left` and `Ctrl + Super + Right` to advance or retreat both displays synchronously.
- **Interactive Bar Widget**:
  - **Left-Click**: Switch both monitors to the chosen virtual desktop.
  - **Scroll Wheel**: Cycle through virtual desktops across both monitors.
  - **Right-Click**: Open the settings & quick jump panel.

## Install

Install directly using the Ryoku CLI:

```sh
ryoku plugin add https://github.com/TheRuckh/workspaces-per-monitor.git --bar --yes
```

Or from a local checkout:

```sh
ryoku plugin add . --bar --yes
```

Once installed, the widget appears on your Ryoku bar and under **QS Bar Settings > Community**.

## Settings

Settings can be changed graphically in **QS Bar Settings > Community**, or via the plugin's popout panel (right-click any workspace button on the bar):

| Setting            | Type | Default    | Purpose |
|--------------------|------|------------|---------|
| `desktopCount`     | int  | `5`        | Number of virtual desktops (e.g. 5 gives 1–5 & A1–A5). |
| `secondaryPrefix`  | text | `"A"`      | Prefix label for the secondary monitor (e.g. `A` for A1..A5). |
| `offset`           | int  | `10`       | Hyprland ID offset for the secondary monitor (e.g. 10 maps Desktop 1 to WS 11). |
| `primaryMonitor`   | text | `"HDMI-A-1"` | Output name for primary display (1, 2, 3...). |
| `secondaryMonitor` | text | `"eDP-1"`    | Output name for secondary display (A1, A2, A3...). |

## Keyboard Shortcuts

Add the following to your `~/.config/hypr/user.lua`:

```lua
local paired_script = (os.getenv("HOME") or "") .. "/.config/hypr/scripts/ryoku-paired-workspaces"
hl.bind("SUPER + CTRL + Right", hl.dsp.exec_cmd(paired_script .. " next"))
hl.bind("SUPER + CTRL + Left",  hl.dsp.exec_cmd(paired_script .. " prev"))
```

## Security & System Access (Ryoku Plugin Standard)

- **Programs executed**: `bin/ryoku-paired-workspaces` (invoking `hyprctl` and `jq`).
- **What it reads**: Current monitor and workspace states via `hyprctl monitors -j`.
- **What it writes**: Hyprland focus dispatches via `hyprctl dispatch hl.dsp.focus(...)` and plugin settings via `pluginApi.saveSetting`.
- **Network access**: None.
- **Privileged actions**: None.

## Remove

```sh
ryoku plugin remove workspaces-per-monitor
```

## License

MIT
