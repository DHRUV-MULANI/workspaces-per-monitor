pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland

// service/Main.qml manages synchronized paired dual-monitor workspaces.
// Virtual Desktop D maps:
//   Primary Monitor   (Display 1) -> Workspace D          (1, 2, 3...)
//   Secondary Monitor (Display 2) -> Workspace name:AD    (A1, A2, A3...)
Item {
    id: svc

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null

    readonly property int desktopCount: (settings && typeof settings.desktopCount === "number" && settings.desktopCount > 0)
        ? settings.desktopCount : 5
    readonly property string primaryMonitor: (settings && typeof settings.primaryMonitor === "string" && settings.primaryMonitor.length > 0)
        ? settings.primaryMonitor : "HDMI-A-1"
    readonly property string secondaryMonitor: (settings && typeof settings.secondaryMonitor === "string" && settings.secondaryMonitor.length > 0)
        ? settings.secondaryMonitor : "eDP-1"
    readonly property string secondaryPrefix: (settings && typeof settings.secondaryPrefix === "string" && settings.secondaryPrefix.length > 0)
        ? settings.secondaryPrefix : "A"

    function parseDesktopFromWs(wsName, wsId) {
        var sName = String(wsName || "");
        if (secondaryPrefix.length > 0 && sName.indexOf(secondaryPrefix) === 0) {
            var num = parseInt(sName.substring(secondaryPrefix.length), 10);
            if (!isNaN(num) && num > 0) return num;
        }
        var num2 = parseInt(sName, 10);
        if (!isNaN(num2) && num2 > 0) return num2;
        if (typeof wsId === "number" && wsId > 0) return wsId;
        return 0;
    }

    // Derive current virtual desktop (1-based) from active workspaces
    readonly property int currentDesktop: {
        var mons = Hyprland.monitors ? Hyprland.monitors.values : [];
        var pDesk = 0;
        var sDesk = 0;

        for (var i = 0; i < mons.length; i++) {
            var m = mons[i];
            if (!m) continue;
            var mName = String(m.name || "");
            var awName = (m.activeWorkspace && m.activeWorkspace.name) ? m.activeWorkspace.name
                : (m.lastIpcObject && m.lastIpcObject.activeWorkspace && m.lastIpcObject.activeWorkspace.name ? m.lastIpcObject.activeWorkspace.name : "");
            var awId = (m.activeWorkspace && typeof m.activeWorkspace.id === "number") ? m.activeWorkspace.id : 0;
            var d = parseDesktopFromWs(awName, awId);

            if (mName === primaryMonitor) {
                pDesk = d;
            } else if (mName === secondaryMonitor) {
                sDesk = d;
            }
        }

        var focused = Hyprland.focusedMonitor;
        if (focused) {
            var fName = String(focused.name || "");
            if (fName === secondaryMonitor && sDesk > 0) return sDesk;
            if (fName === primaryMonitor && pDesk > 0) return pDesk;
        }

        if (pDesk > 0) return pDesk;
        if (sDesk > 0) return sDesk;

        var fWs = Hyprland.focusedWorkspace;
        if (fWs) {
            var fd = parseDesktopFromWs(fWs.name, fWs.id);
            if (fd > 0) return fd;
        }
        return 1;
    }

    // Switch both displays synchronously to virtual desktop D
    function switchDesktop(targetDesk, originatingMonitor) {
        var d = parseInt(targetDesk, 10);
        if (isNaN(d) || d < 1) d = 1;

        var targetWs1 = d;
        var targetWs2 = "name:" + secondaryPrefix + d;
        var orig = originatingMonitor ? String(originatingMonitor) : primaryMonitor;

        // Switch the non-originating display first, then the originating display,
        // so focus ends on the screen the user interacted with.
        if (orig === secondaryMonitor) {
            Hyprland.dispatch('hl.dsp.focus({ monitor = "' + primaryMonitor + '" })');
            Hyprland.dispatch('hl.dsp.focus({ workspace = ' + targetWs1 + ' })');
            Hyprland.dispatch('hl.dsp.focus({ monitor = "' + secondaryMonitor + '" })');
            Hyprland.dispatch('hl.dsp.focus({ workspace = "' + targetWs2 + '" })');
        } else {
            Hyprland.dispatch('hl.dsp.focus({ monitor = "' + secondaryMonitor + '" })');
            Hyprland.dispatch('hl.dsp.focus({ workspace = "' + targetWs2 + '" })');
            Hyprland.dispatch('hl.dsp.focus({ monitor = "' + primaryMonitor + '" })');
            Hyprland.dispatch('hl.dsp.focus({ workspace = ' + targetWs1 + ' })');
        }
    }

    function cycleDesktop(delta, originatingMonitor) {
        var next = currentDesktop + (delta > 0 ? 1 : -1);
        if (next < 1) next = 1;
        switchDesktop(next, originatingMonitor);
    }

    function saveSetting(key, value) {
        if (pluginApi && typeof pluginApi.saveSetting === "function") {
            pluginApi.saveSetting(key, value);
        }
    }
}
