import QtQuick
import Quickshell.Services.Pipewire
import qs.modules.components
import qs.modules.osd

SliderRow {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0

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
    muted: sink?.audio?.muted ?? false

    onVolumeChanged: Osd.show(volumeIconName(), volume, iconFallback, muted)
    onMutedChanged: Osd.show(volumeIconName(), volume, iconFallback, muted)

    onMoved: newValue => sink.audio.volume = newValue
    onIconClicked: sink.audio.muted = !sink.audio.muted

    PwObjectTracker {
        objects: [root.sink]
    }
}
