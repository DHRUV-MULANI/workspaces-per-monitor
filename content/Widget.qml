pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Ryoku.PluginKit.Singletons

// content/Widget.qml renders the paired workspace buttons on each monitor's bar.
// Display 1 shows numbers (1, 2, 3...)
// Display 2 shows prefixed numbers (A1, A2, A3...)
// Clicking any button or scrolling switches both displays simultaneously.
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active: false
    property string density: "glyph"
    property real s: 1
    property real widthBudget: 0

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property int desktopCount: service ? service.desktopCount : 5
    readonly property int offset: service ? service.offset : 10
    readonly property string primaryMonitor: service ? service.primaryMonitor : "HDMI-A-1"
    readonly property string secondaryMonitor: service ? service.secondaryMonitor : "eDP-1"
    readonly property string secondaryPrefix: service ? service.secondaryPrefix : "A"
    readonly property int currentDesktop: service ? service.currentDesktop : 1

    // Detect the monitor this bar surface sits on
    function monitorName() {
        var win = root.Window ? root.Window.window : null;
        var winScreen = win ? win["screen"] : null;
        if (winScreen && winScreen.name) {
            return String(winScreen.name);
        }
        if (root.screen && root.screen.name) {
            return String(root.screen.name);
        }

        if (typeof Quickshell !== "undefined" && Quickshell.screens && Quickshell.screens.length > 0) {
            var pt = root.mapToGlobal(0, 0);
            var screens = Quickshell.screens;
            for (var i = 0; i < screens.length; i++) {
                var sc = screens[i];
                if (sc && pt.x >= sc.x && pt.x < sc.x + sc.width && pt.y >= sc.y && pt.y < sc.y + sc.height) {
                    return String(sc.name || "");
                }
            }
            if (screens.length === 1 && screens[0] && screens[0].name) {
                return String(screens[0].name);
            }
        }

        if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) {
            return String(Hyprland.focusedMonitor.name);
        }
        return primaryMonitor;
    }

    readonly property bool isSecondary: monitorName() === secondaryMonitor

    readonly property var desktopList: {
        var list = [];
        for (var i = 1; i <= desktopCount; i++) {
            list.push(i);
        }
        return list;
    }

    function workspaceById(id) {
        var values = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        for (var i = 0; i < values.length; i++) {
            if (values[i] && values[i].id === id) return values[i];
        }
        return null;
    }

    function isWorkspaceOccupied(wsId) {
        var w = workspaceById(wsId);
        if (!w) return false;
        if (w.toplevels && w.toplevels.values && w.toplevels.values.length > 0) return true;
        if (w.lastIpcObject && typeof w.lastIpcObject.windows === "number" && w.lastIpcObject.windows > 0) return true;
        return false;
    }

    implicitWidth: wsRow.implicitWidth
    implicitHeight: Math.max(28, 28 * root.s)

    Row {
        id: wsRow
        anchors.centerIn: parent
        spacing: 4 * root.s

        Repeater {
            model: root.desktopList

            delegate: Rectangle {
                id: wsCell
                required property int modelData
                readonly property int deskIdx: modelData
                readonly property int wsId: root.isSecondary ? (deskIdx + root.offset) : deskIdx
                readonly property string labelText: root.isSecondary ? (root.secondaryPrefix + String(deskIdx)) : String(deskIdx)
                readonly property bool isFocused: root.currentDesktop === deskIdx
                readonly property bool isOccupied: root.isWorkspaceOccupied(wsId)

                width: (root.isSecondary ? 28 : 24) * root.s
                height: 24 * root.s
                radius: 6

                color: isFocused
                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.28)
                    : isOccupied
                    ? Qt.rgba(Theme.bright.r, Theme.bright.g, Theme.bright.b, 0.12)
                    : cellMa.containsMouse
                    ? Qt.rgba(Theme.bright.r, Theme.bright.g, Theme.bright.b, 0.08)
                    : Qt.rgba(Theme.bright.r, Theme.bright.g, Theme.bright.b, 0.03)

                border.width: isFocused ? 1.5 : (isOccupied ? 1 : 0)
                border.color: isFocused
                    ? Theme.accent
                    : (isOccupied ? Qt.rgba(Theme.bright.r, Theme.bright.g, Theme.bright.b, 0.25) : "transparent")

                Behavior on color { ColorAnimation { duration: 160 } }
                Behavior on border.color { ColorAnimation { duration: 160 } }
                Behavior on scale { NumberAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: wsCell.labelText
                    font.family: Theme.mono
                    font.pixelSize: (root.isSecondary ? 11 : 12) * root.s
                    font.weight: wsCell.isFocused ? Font.Bold : Font.Normal
                    color: wsCell.isFocused
                        ? Theme.accent
                        : (wsCell.isOccupied ? Theme.bright : Theme.dim)
                    opacity: wsCell.isFocused ? 1.0 : (wsCell.isOccupied ? 0.9 : 0.45)
                    Behavior on color { ColorAnimation { duration: 160 } }
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }

                MouseArea {
                    id: cellMa
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onEntered: wsCell.scale = 1.08
                    onExited: wsCell.scale = 1.0
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            if (root.pluginApi) root.pluginApi.togglePanel();
                        } else {
                            if (root.service) {
                                root.service.switchDesktop(wsCell.deskIdx, root.monitorName());
                            }
                        }
                    }
                }
            }
        }
    }

    // Scroll wheel over the bar cycles through virtual desktops synchronously
    WheelHandler {
        onWheel: (event) => {
            if (root.service) {
                root.service.cycleDesktop(event.angleDelta.y > 0 ? -1 : 1, root.monitorName());
            }
        }
    }
}
