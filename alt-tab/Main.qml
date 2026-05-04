import QtQuick
import Quickshell
import qs.Commons

QtObject {
    id: root

    property var pluginApi: null

    IpcHandler {
        target: "alt-tab"

        function toggle() {
            if (root.pluginApi)
                root.pluginApi.togglePanel(Quickshell.screens[0])
        }

        function open() {
            if (root.pluginApi)
                root.pluginApi.openPanel(Quickshell.screens[0])
        }

        function close() {
            if (root.pluginApi)
                root.pluginApi.closePanel(Quickshell.screens[0])
        }
    }

    Component.onCompleted: {
        Logger.i("AltTab", "IPC handler registered — target: alt-tab")
    }
}
