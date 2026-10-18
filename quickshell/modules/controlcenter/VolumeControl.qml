import QtQuick
import Quickshell.Services.Pipewire
import qs.modules.components
import qs.modules.osd

SliderRow {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    function volumeIconName() {
        if (muted || volume <= 0)
            return "audio-volume-muted";
        if (volume < 0.34)
            return "audio-volume-low";
        if (volume < 0.67)
            return "audio-volume-medium";
        return "audio-volume-high";
    }

    iconName: volumeIconName()
    iconFallback: "audio-volume-high"
    value: volume

    onVolumeChanged: Osd.show(volumeIconName(), volume, iconFallback)
    onMutedChanged: Osd.show(volumeIconName(), volume, iconFallback)

    onMoved: newValue => sink.audio.volume = newValue
    onIconClicked: sink.audio.muted = !sink.audio.muted

    PwObjectTracker {
        objects: [root.sink]
    }
}
