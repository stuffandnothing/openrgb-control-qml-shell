import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Rectangle {
    id: root

    property var pluginApi: null
    property ShellScreen screen

    color: Qt.rgba(0, 0, 0, 0.45)

    ListModel {
        id: windowModel
    }

    Process {
        id: listProc

        stderr: StdioCollector {}

        stdout: StdioCollector {
            onStreamFinished: {
                windowModel.clear()
                var lines = this.text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()
                    if (!line)
                        continue
                    var sep = line.indexOf(") ")
                    if (sep < 0)
                        continue
                    var num = parseInt(line.substring(0, sep))
                    var label = line.substring(sep + 2)
                    windowModel.append({
                        "number": num,
                        "label": label
                    })
                }
                if (windowModel.count > 0)
                    listView.currentIndex = 0
                listView.forceActiveFocus()
            }
        }
    }

    Process {
        id: focusProc

        stderr: StdioCollector {}
    }

    function refreshWindows() {
        var script = pluginApi.pluginDir + "/script"
        listProc.command = [script, "--list"]
        listProc.running = false
        listProc.running = true
    }

    function focusWindow(number) {
        var script = pluginApi.pluginDir + "/script"
        focusProc.command = [script, "--focus", number.toString()]
        focusProc.running = false
        focusProc.running = true
        pluginApi.closePanel(screen)
    }

    Component.onCompleted: {
        refreshWindows()
    }

    Keys.onEscapePressed: pluginApi.closePanel(screen)

    MouseArea {
        anchors.fill: parent
        onClicked: pluginApi.closePanel(screen)
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(480, parent.width * 0.45)
        height: Math.min(windowModel.count * 52 + 64, parent.height * 0.65)
        color: Color.mSurface
        radius: Style.radiusL
        border.color: Color.mOutline
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginXS

            NText {
                text: "Windows"
                pointSize: Style.fontSizeM
                font.weight: Font.Bold
                color: Color.mOnSurface
                Layout.bottomMargin: Style.marginXS
            }

            NText {
                visible: windowModel.count === 0
                text: "No windows on this workspace"
                color: Color.mOnSurfaceVariant
                pointSize: Style.fontSizeS
                Layout.alignment: Qt.AlignHCenter
            }

            ListView {
                id: listView

                Layout.fillWidth: true
                Layout.fillHeight: true
                model: windowModel
                clip: true
                keyNavigationEnabled: true
                focus: true

                Keys.onEscapePressed: pluginApi.closePanel(screen)
                Keys.onReturnPressed: {
                    if (currentIndex >= 0)
                        root.focusWindow(windowModel.get(currentIndex).number)
                }
                Keys.onTabPressed: {
                    if (currentIndex < count - 1)
                        currentIndex++
                    else
                        currentIndex = 0
                }

                delegate: Rectangle {
                    required property int index
                    required property int number
                    required property string label

                    width: listView.width
                    height: 44
                    radius: Style.radiusS
                    color: listView.currentIndex === index ? Color.mPrimaryContainer : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: 80
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Style.marginS
                        anchors.rightMargin: Style.marginS
                        spacing: Style.marginS

                        NText {
                            text: number.toString()
                            color: listView.currentIndex === index ? Color.mOnPrimaryContainer : Color.mOnSurfaceVariant
                            pointSize: Style.fontSizeXS
                            font.weight: Font.Bold
                            Layout.preferredWidth: 16
                            Layout.alignment: Qt.AlignVCenter
                        }

                        NText {
                            text: label
                            color: listView.currentIndex === index ? Color.mOnPrimaryContainer : Color.mOnSurface
                            pointSize: Style.fontSizeS
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: listView.currentIndex = index
                        onClicked: root.focusWindow(number)
                    }
                }
            }
        }
    }
}
