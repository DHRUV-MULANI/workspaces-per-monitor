pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import Ryoku.PluginKit.Singletons

// content/Panel.qml is the popout panel for paired workspace control & settings.
Item {
    id: root

    property var pluginApi
    property string density: "full"
    property real s: 1
    property real widthBudget: 320
    property bool active: false

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property int desktopCount: service ? service.desktopCount : 5
    readonly property string primaryMonitor: service ? service.primaryMonitor : "HDMI-A-1"
    readonly property string secondaryMonitor: service ? service.secondaryMonitor : "eDP-1"
    readonly property string secondaryPrefix: service ? service.secondaryPrefix : "A"
    readonly property int currentDesktop: service ? service.currentDesktop : 1

    function monitorName() {
        var win = root.Window ? root.Window.window : null;
        var winScreen = win ? win["screen"] : null;
        if (winScreen && winScreen.name) {
            return String(winScreen.name);
        }
        if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name) {
            return String(Hyprland.focusedMonitor.name);
        }
        return primaryMonitor;
    }

    implicitWidth: root.widthBudget
    implicitHeight: col.implicitHeight + 24 * root.s

    Column {
        id: col
        x: 14 * root.s
        y: 12 * root.s
        width: root.width - 28 * root.s
        spacing: 12 * root.s

        // Header
        Row {
            width: parent.width
            spacing: 8 * root.s

            Text {
                text: "\uDB85\uDCFB" // workspace icon
                color: Theme.accent
                font.family: Theme.mono
                font.pixelSize: 18 * root.s
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: "Paired Workspaces"
                    color: Theme.bright
                    font.family: Theme.display
                    font.pixelSize: 14 * root.s
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "Desktop " + root.currentDesktop + " (" + root.primaryMonitor + ": " + root.currentDesktop + " | " + root.secondaryMonitor + ": " + root.secondaryPrefix + root.currentDesktop + ")"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 11 * root.s
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
            opacity: 0.5
        }

        // Quick Jump Row
        Text {
            text: "Switch Desktop (Both Displays)"
            color: Theme.bright
            font.family: Theme.font
            font.pixelSize: 12 * root.s
            font.weight: Font.Medium
        }

        Row {
            spacing: 6 * root.s
            Repeater {
                model: Math.max(root.desktopCount, root.currentDesktop)

                delegate: Rectangle {
                    id: jumpBtn
                    required property int index
                    readonly property int deskNum: index + 1
                    readonly property bool isCurrent: root.currentDesktop === deskNum

                    width: 32 * root.s
                    height: 28 * root.s
                    radius: 6

                    color: isCurrent
                        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
                        : jumpMa.containsMouse
                        ? Qt.rgba(Theme.bright.r, Theme.bright.g, Theme.bright.b, 0.12)
                        : Qt.rgba(Theme.bright.r, Theme.bright.g, Theme.bright.b, 0.05)

                    border.width: isCurrent ? 1.5 : 1
                    border.color: isCurrent ? Theme.accent : Qt.rgba(Theme.bright.r, Theme.bright.g, Theme.bright.b, 0.15)

                    Text {
                        anchors.centerIn: parent
                        text: String(jumpBtn.deskNum)
                        color: jumpBtn.isCurrent ? Theme.accent : Theme.bright
                        font.family: Theme.mono
                        font.pixelSize: 12 * root.s
                        font.weight: jumpBtn.isCurrent ? Font.Bold : Font.Normal
                    }

                    MouseArea {
                        id: jumpMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.service) {
                                root.service.switchDesktop(jumpBtn.deskNum, root.monitorName());
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
            opacity: 0.5
        }

        // Setting: Virtual desktop count
        Row {
            width: parent.width
            spacing: 8 * root.s

            Column {
                width: parent.width - countControls.width - 8 * root.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2 * root.s

                Text {
                    text: "Desktop Count"
                    color: Theme.bright
                    font.family: Theme.font
                    font.pixelSize: 13 * root.s
                }

                Text {
                    text: root.desktopCount + " paired desktops (1-" + root.desktopCount + " & " + root.secondaryPrefix + "1-" + root.secondaryPrefix + root.desktopCount + ")"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 11 * root.s
                }
            }

            Row {
                id: countControls
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4 * root.s

                Rectangle {
                    width: 26 * root.s
                    height: 26 * root.s
                    radius: 4
                    color: Qt.rgba(Theme.bright.r, Theme.bright.g, Theme.bright.b, 0.1)
                    Text {
                        anchors.centerIn: parent
                        text: "-"
                        color: Theme.bright
                        font.family: Theme.mono
                        font.pixelSize: 14 * root.s
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var n = Math.max(1, root.desktopCount - 1);
                            if (root.pluginApi) root.pluginApi.saveSetting("desktopCount", n);
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: String(root.desktopCount)
                    color: Theme.bright
                    font.family: Theme.mono
                    font.pixelSize: 13 * root.s
                    width: 24 * root.s
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    width: 26 * root.s
                    height: 26 * root.s
                    radius: 4
                    color: Qt.rgba(Theme.bright.r, Theme.bright.g, Theme.bright.b, 0.1)
                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: Theme.bright
                        font.family: Theme.mono
                        font.pixelSize: 14 * root.s
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var n = Math.min(10, root.desktopCount + 1);
                            if (root.pluginApi) root.pluginApi.saveSetting("desktopCount", n);
                        }
                    }
                }
            }
        }

        // Shortcuts hint card
        Rectangle {
            width: parent.width
            height: shortcutCol.implicitHeight + 12 * root.s
            radius: 6
            color: Qt.rgba(Theme.bright.r, Theme.bright.g, Theme.bright.b, 0.05)
            border.width: 1
            border.color: Qt.rgba(Theme.bright.r, Theme.bright.g, Theme.bright.b, 0.1)

            Column {
                id: shortcutCol
                x: 10 * root.s
                y: 6 * root.s
                width: parent.width - 20 * root.s
                spacing: 4 * root.s

                Text {
                    text: "Keyboard Navigation"
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: 11 * root.s
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "Ctrl + Super + \u2192 : Next desktop (both)\nCtrl + Super + \u2190 : Prev desktop (both)\nSuper + 1..0 : Jump to paired desktop 1..10\nSuper + Alt + 1..0 : Move window to desktop"
                    color: Theme.dim
                    font.family: Theme.mono
                    font.pixelSize: 10 * root.s
                    lineHeight: 1.2
                }
            }
        }

        // Close button
        Rectangle {
            width: parent.width
            height: 28 * root.s
            radius: Theme.radius > 0 ? Theme.radius : 6
            color: closeMa.pressed ? Theme.vermDeep : Theme.accent

            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: "Close"
                color: Theme.cardBot
                font.family: Theme.font
                font.pixelSize: 12 * root.s
                font.weight: Font.DemiBold
            }

            MouseArea {
                id: closeMa
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.pluginApi) root.pluginApi.closePanel()
            }
        }
    }
}
