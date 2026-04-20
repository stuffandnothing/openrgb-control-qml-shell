import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Rectangle {
    id: root

    // --- Required plugin API properties ---
    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    // --- Plugin state ---
    property var profiles: pluginApi?.pluginSettings?.profiles ?? ["Default", "Gaming", "Off"]
    property string activeProfile: pluginApi?.pluginSettings?.activeProfile ?? "Default"
    property string host: pluginApi?.pluginSettings?.serverHost ?? "127.0.0.1"
    property int port: pluginApi?.pluginSettings?.serverPort ?? 6742
    property bool rgbOn: activeProfile !== "Off"
    property bool expanded: false
    property bool busy: false

    // --- Layout ---
    implicitWidth: expanded ? mainRow.implicitWidth + Style.marginM * 2 : collapsedRow.implicitWidth + Style.marginM * 2
    implicitHeight: Style.barHeight
    color: Style.capsuleColor
    radius: Style.radiusM

    Behavior on implicitWidth {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    // --- Collapsed view: just the icon + active profile name ---
    RowLayout {
        id: collapsedRow
        anchors.centerIn: parent
        visible: !expanded
        spacing: Style.marginS

        NIcon {
            icon: root.rgbOn ? "lightbulb" : "lightbulb_off"
            color: root.rgbOn ? Color.mPrimary : Color.mOnSurfaceVariant
        }
        NText {
            text: root.activeProfile
            color: Color.mOnSurface
            pointSize: Style.fontSizeS
        }
    }

    // --- Expanded view: profile buttons ---
    RowLayout {
        id: mainRow
        anchors.centerIn: parent
        visible: expanded
        spacing: Style.marginXS

        NIcon {
            icon: "lightbulb"
            color: Color.mPrimary
        }

        Repeater {
            model: root.profiles

            Rectangle {
                required property string modelData
                property bool isActive: root.activeProfile === modelData

                implicitWidth: profileLabel.implicitWidth + Style.marginS * 2
                implicitHeight: Style.barHeight - Style.marginXS * 2
                radius: Style.radiusS
                color: isActive ? Color.mPrimary : "transparent"
                opacity: root.busy ? 0.5 : 1.0

                NText {
                    id: profileLabel
                    anchors.centerIn: parent
                    text: modelData
                    color: isActive ? Color.mOnPrimary : Color.mOnSurface
                    pointSize: Style.fontSizeS
                    font.weight: isActive ? Font.Bold : Font.Normal
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !root.busy
                    onClicked: root.applyProfile(modelData)
                }
            }
        }
    }

    // --- Toggle expand on click (collapsed area) ---
    MouseArea {
        anchors.fill: parent
        visible: !expanded
        onClicked: root.expanded = true
    }

    // Clicking outside collapses
    MouseArea {
        id: collapseArea
        anchors.fill: parent
        visible: expanded
        propagateComposedEvents: true
        // clicks on child MouseAreas still propagate; this just catches misses
        onClicked: (mouse) => {
            mouse.accepted = false
        }
    }

    // --- Process to run openrgb CLI ---
    Process {
        id: openrgbProc
        property string pendingProfile: ""

        onExited: (exitCode) => {
            root.busy = false
            if (exitCode === 0) {
                root.activeProfile = openrgbProc.pendingProfile
                if (pluginApi) {
                    pluginApi.pluginSettings.activeProfile = root.activeProfile
                    pluginApi.saveSettings()
                }
                root.expanded = false
                ToastService.showNotice("RGB → " + root.activeProfile)
                Logger.i("OpenRGB", "Profile applied:", root.activeProfile)
            } else {
                ToastService.showError("OpenRGB failed (exit " + exitCode + ")")
                Logger.e("OpenRGB", "Failed to apply profile:", root.activeProfile, "exit:", exitCode)
            }
        }
    }

    // --- Functions ---
    function applyProfile(profileName) {
        if (busy) return
        busy = true
        openrgbProc.pendingProfile = profileName

        if (profileName === "Off") {
            // Turn all devices off by setting brightness to 0 via color black
            openrgbProc.command = [
                "openrgb",
                "--server-host", root.host,
                "--server-port", root.port.toString(),
                "--alldevices",
                "--color", "000000"
            ]
        } else {
            openrgbProc.command = [
                "openrgb",
                "--server-host", root.host,
                "--server-port", root.port.toString(),
                "--profile", profileName
            ]
        }
        openrgbProc.running = true
    }

    Component.onCompleted: {
        Logger.i("OpenRGB", "Widget loaded, active profile:", root.activeProfile)
    }
}