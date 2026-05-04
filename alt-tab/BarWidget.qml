import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Rectangle {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    property int windowCount: 0

    implicitWidth: row.implicitWidth + Style.marginM * 2
    implicitHeight: Style.barHeight
    color: Style.capsuleColor
    radius: Style.radiusM

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: countProc.refresh()
    }

    Process {
        id: countProc

        stderr: StdioCollector {}

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                root.windowCount = this.text.trim() === "" ? 0 : lines.length
            }
        }

        function refresh() {
            var script = root.pluginApi?.pluginDir + "/script"
            command = [script, "--list"]
            running = false
            running = true
        }
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Style.marginS

        NIcon {
            icon: "window"
            color: Color.mPrimary
        }

        NText {
            text: root.windowCount.toString()
            color: Color.mOnSurface
            pointSize: Style.fontSizeS
            font.weight: Font.Bold
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: {
            if (root.pluginApi)
                root.pluginApi.togglePanel(root.screen, root)
        }
    }

    Component.onCompleted: {
        Logger.i("AltTab", "Bar widget loaded")
    }
}
