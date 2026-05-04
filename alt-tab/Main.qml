import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
    property var pluginApi: null

    IpcHandler {
        target: "plugin:alt-tab"

        function toggle() {
            if (!pluginApi)
                return
            pluginApi.withCurrentScreen(screen => {
                pluginApi.togglePanel(screen)
            })
        }

        function open() {
            if (!pluginApi)
                return
            pluginApi.withCurrentScreen(screen => {
                pluginApi.openPanel(screen)
            })
        }

        function close() {
            if (!pluginApi)
                return
            pluginApi.withCurrentScreen(screen => {
                pluginApi.closePanel(screen)
            })
        }
    }

    Component.onCompleted: {
        Logger.i("AltTab", "IPC handler registered — target: plugin:alt-tab")
    }
}
