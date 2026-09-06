# Workspaces Per Monitor

A Windows-style paired dual-monitor Hyprland workspace switcher for the Ryoku shell.

Display 1 (Primary, e.g. `HDMI-A-1`) displays workspaces **1, 2, 3, 4, 5... (1 to infinite)**, while Display 2 (Secondary, e.g. `eDP-1`) displays paired workspaces **A1, A2, A3, A4, A5... (A1 to infinite)** (natively named Hyprland workspaces `name:A1`, `name:A2`...).

When you switch desktops—via the bar buttons, mouse wheel, or keyboard shortcuts—both displays advance in sync like Windows virtual desktops, while maintaining focus on whichever screen you are actively using.

## Features

- **Windows-style Synchronized Desktop Switching**: Moving to Desktop 2 simultaneously switches Display 1 to `2` and Display 2 to `A2`.
- **Dynamic 1..Infinite Workspaces**: Displays can scale beyond 5 to 6, 7, 8... dynamically.
- **Native Named Workspaces**: Secondary monitor workspaces are cleanly named `name:A1`, `name:A2`... eliminating ID collision.
- **Pinned Workspace Rules**: Pinned workspace rules guarantee workspaces 1..30 stay on Display 1 and A1..A30 stay on Display 2.
- **Comprehensive Keybindings**:
  - `Ctrl + Super + Left / Right`: Advance or retreat both displays synchronously.
  - `Super + 1..0`: Jump directly to paired desktop 1..10 (both displays switch together).
  - `Super + Alt + 1..0`: Move active window to that desktop slot on the current monitor.
  - `Super + Shift + 1..0`: Move active window silently to that desktop slot.
- **Interactive Bar Widget**:
  - **Left-Click**: Switch both monitors to the chosen virtual desktop.
  - **Scroll Wheel**: Cycle through virtual desktops across both monitors.
  - **Right-Click**: Open the settings & quick jump panel.

## Install

Install directly using the Ryoku CLI:

```sh
ryoku plugin add https://github.com/DHRUV-MULANI/workspaces-per-monitor.git --bar --yes
```

Or from a local checkout:

```sh
ryoku plugin add . --bar --yes
```

Once installed, the widget appears on your Ryoku bar and under **QS Bar Settings > Community**.

## Settings

Settings can be changed graphically in **QS Bar Settings > Community**, or via the plugin's popout panel (right-click any workspace button on the bar):

| Setting            | Type | Default      | Purpose |
|--------------------|------|--------------|---------|
| `desktopCount`     | int  | `5`          | Minimum virtual desktops visible on the bar (expands dynamically). |
| `secondaryPrefix`  | text | `"A"`        | Prefix label for the secondary monitor (e.g. `A` for A1, A2...). |
| `primaryMonitor`   | text | `"HDMI-A-1"` | Output name for primary display (1, 2, 3...). |
| `secondaryMonitor` | text | `"eDP-1"`    | Output name for secondary display (A1, A2, A3...). |

## Keyboard Shortcuts

Configured in `~/.config/hypr/user.lua`:

```lua
local paired_script = (os.getenv("HOME") or "") .. "/.config/hypr/scripts/ryoku-paired-workspaces"

-- Next / Prev paired desktop
hl.bind("SUPER + CTRL + Right", hl.dsp.exec_cmd(paired_script .. " next"))
hl.bind("SUPER + CTRL + Left",  hl.dsp.exec_cmd(paired_script .. " prev"))

-- Direct jump to paired desktop 1..10
for i = 1, 10 do
    local key = tostring(i % 10)
    hl.bind("SUPER + " .. key,         hl.dsp.exec_cmd(paired_script .. " goto " .. i))
    hl.bind("SUPER + ALT + " .. key,   hl.dsp.exec_cmd(paired_script .. " move " .. i))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.exec_cmd(paired_script .. " movesilent " .. i))
end
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
