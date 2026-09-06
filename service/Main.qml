pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland

// service/Main.qml manages synchronized paired dual-monitor workspaces.
// Virtual Desktop D maps:
//   Primary Monitor   (Display 1) -> Workspace D          (1, 2, 3...)
//   Secondary Monitor (Display 2) -> Workspace D + offset (A1, A2, A3...)
Item {
    id: svc

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null

    readonly property int desktopCount: (settings && typeof settings.desktopCount === "number" && settings.desktopCount > 0)
        ? settings.desktopCount : 5
    readonly property int offset: (settings && typeof settings.offset === "number" && settings.offset > 0)
        ? settings.offset : 10
    readonly property string primaryMonitor: (settings && typeof settings.primaryMonitor === "string" && settings.primaryMonitor.length > 0)
        ? settings.primaryMonitor : "HDMI-A-1"
    readonly property string secondaryMonitor: (settings && typeof settings.secondaryMonitor === "string" && settings.secondaryMonitor.length > 0)
        ? settings.secondaryMonitor : "eDP-1"
    readonly property string secondaryPrefix: (settings && typeof settings.secondaryPrefix === "string" && settings.secondaryPrefix.length > 0)
        ? settings.secondaryPrefix : "A"

    // Derive current virtual desktop (1-based) from active workspaces
    readonly property int currentDesktop: {
        var mons = Hyprland.monitors ? Hyprland.monitors.values : [];
        var pWs = 0;
        var sWs = 0;

        for (var i = 0; i < mons.length; i++) {
            var m = mons[i];
            if (!m) continue;
            var mName = String(m.name || "");
            var awId = (m.activeWorkspace && typeof m.activeWorkspace.id === "number")
                ? m.activeWorkspace.id
                : (m.lastIpcObject && m.lastIpcObject.activeWorkspace && typeof m.lastIpcObject.activeWorkspace.id === "number"
                    ? m.lastIpcObject.activeWorkspace.id : 0);

            if (mName === primaryMonitor) {
                pWs = awId;
            } else if (mName === secondaryMonitor) {
                sWs = awId;
            }
        }

        if (pWs > 0) {
            return pWs;
        }
        if (sWs > offset) {
            return sWs - offset;
        }

        var focused = Hyprland.focusedWorkspace;
        if (focused && focused.id > 0) {
            return focused.id > offset ? (focused.id - offset) : focused.id;
        }
        return 1;
    }

    // Switch both displays synchronously to virtual desktop D
    function switchDesktop(targetDesk, originatingMonitor) {
        var d = parseInt(targetDesk, 10);
        if (isNaN(d) || d < 1) d = 1;

        var targetWs1 = d;
        var targetWs2 = d + offset;
        var orig = originatingMonitor ? String(originatingMonitor) : primaryMonitor;

        // Switch the non-originating display first, then the originating display,
        // so focus ends on the screen the user interacted with.
        if (orig === secondaryMonitor) {
            Hyprland.dispatch('hl.dsp.focus({ monitor = "' + primaryMonitor + '" })');
            Hyprland.dispatch('hl.dsp.focus({ workspace = ' + targetWs1 + ' })');
            Hyprland.dispatch('hl.dsp.focus({ monitor = "' + secondaryMonitor + '" })');
            Hyprland.dispatch('hl.dsp.focus({ workspace = ' + targetWs2 + ' })');
        } else {
            Hyprland.dispatch('hl.dsp.focus({ monitor = "' + secondaryMonitor + '" })');
            Hyprland.dispatch('hl.dsp.focus({ workspace = ' + targetWs2 + ' })');
            Hyprland.dispatch('hl.dsp.focus({ monitor = "' + primaryMonitor + '" })');
            Hyprland.dispatch('hl.dsp.focus({ workspace = ' + targetWs1 + ' })');
        }
    }

    function cycleDesktop(delta, originatingMonitor) {
        var next = currentDesktop + (delta > 0 ? 1 : -1);
        if (next < 1) next = 1;
        if (desktopCount > 0 && next > desktopCount) next = desktopCount;
        switchDesktop(next, originatingMonitor);
    }

    function saveSetting(key, value) {
        if (pluginApi && typeof pluginApi.saveSetting === "function") {
            pluginApi.saveSetting(key, value);
        }
    }
}
