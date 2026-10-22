import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.modules.components
import qs.modules.services

// Freeform scratchpad - plain text, saved per widget instance via ShellSettings.notepadNotes
// (keyed by whatever noteKey the host grid/layer binds in, e.g. the desktop widget's id).
WidgetLayout {
    id: root

    title: "Notepad"
    property string noteKey: ""

    // Loads once per noteKey rather than binding text directly to the store: a live
    // `text: ShellSettings.notepadNotes[...]` binding alongside the onTextChanged write-back
    // below is a binding loop (every keystroke re-triggers the same binding expression).
    //
    // Called from two places because noteKey (set by a host Binding right after the Loader
    // creates this item) and ShellSettings.loaded (flipped once its own async FileView read
    // finishes) can resolve in either order. Whichever fires first used to win permanently -
    // when ShellSettings hadn't loaded yet, the store lookup below just returned "" and
    // nothing ever re-ran it, so the real saved text got silently dropped every time this
    // widget happened to spin up faster than the settings file read.
    function loadNote() {
        if (root.noteKey)
            textArea.text = ShellSettings.notepadNotes[root.noteKey] ?? "";
    }

    onNoteKeyChanged: root.loadNote()

    Connections {
        target: ShellSettings
        function onLoadedChanged() {
            root.loadNote();
        }
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        TextArea {
            id: textArea

            wrapMode: TextArea.Wrap
            selectByMouse: true
            placeholderText: "Type here…"
            font.family: Config.fontFamily
            font.pixelSize: root.captionFontSize
            color: Config.colText
            placeholderTextColor: Config.colSubtext
            onTextChanged: {
                if (root.noteKey)
                    ShellSettings.setNotepadText(root.noteKey, text);

            }

            background: Rectangle {
                color: Config.colBackground
            }

        }

    }

}
