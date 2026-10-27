import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs
import qs.modules.components

ColumnLayout {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property var outputs: {
        const list = [];
        for (const n of Pipewire.nodes.values)
            if ((n.type & PwNodeType.AudioSink) && !n.isStream)
                list.push(n);
        return list;
    }
    readonly property var inputs: {
        const list = [];
        for (const n of Pipewire.nodes.values)
            if ((n.type & PwNodeType.AudioSource) && !n.isStream)
                list.push(n);
        return list;
    }

    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    spacing: Config.spacingLarge

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Config.spacingXSmall

        Text {
            text: "Output"
            font.family: Config.fontFamily
            font.bold: true
            font.pixelSize: Config.fontSizeBody
            color: Config.colText
        }

        SliderRow {
            iconName: root.sink?.audio?.muted ? "audio-volume-muted" : "audio-volume-high"
            iconFallback: "audio-volume-high"
            value: root.sink?.audio?.volume ?? 0
            onMoved: newValue => root.sink.audio.volume = newValue
            onIconClicked: root.sink.audio.muted = !root.sink.audio.muted
        }

        DropdownSelect {
            options: root.outputs.map(n => ({
                label: n.description || n.nickname,
                value: n
            }))
            selectedValue: root.sink
            onSelected: value => Pipewire.preferredDefaultAudioSink = value
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Config.spacingXSmall

        Text {
            text: "Input"
            font.family: Config.fontFamily
            font.bold: true
            font.pixelSize: Config.fontSizeBody
            color: Config.colText
        }

        SliderRow {
            iconName: root.source?.audio?.muted ? "microphone-sensitivity-muted-symbolic" : "microphone-sensitivity-high-symbolic"
            iconFallback: "audio-input-microphone-symbolic"
            value: root.source?.audio?.volume ?? 0
            onMoved: newValue => root.source.audio.volume = newValue
            onIconClicked: root.source.audio.muted = !root.source.audio.muted
        }

        DropdownSelect {
            options: root.inputs.map(n => ({
                label: n.description || n.nickname,
                value: n
            }))
            selectedValue: root.source
            onSelected: value => Pipewire.preferredDefaultAudioSource = value
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
