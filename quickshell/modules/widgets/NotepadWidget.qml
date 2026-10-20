import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.modules.services

// Freeform scratchpad - plain text, saved per widget instance via ShellSettings.notepadNotes
// (keyed by whatever noteKey the host grid/layer binds in, e.g. the desktop widget's id).
ColumnLayout {
    id: root

    property string noteKey: ""

    // Loads once per noteKey rather than binding text directly to the store: a live
    // `text: ShellSettings.notepadNotes[...]` binding alongside the onTextChanged write-back
    // below is a binding loop (every keystroke re-triggers the same binding expression).
    onNoteKeyChanged: textArea.text = root.noteKey ? (ShellSettings.notepadNotes[root.noteKey] ?? "") : ""
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Config.spacingSmall

    Text {
        text: "Notepad"
        font.family: Config.fontFamily
        font.bold: true
        font.pixelSize: Config.fontSizeBody
        color: Config.colText
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
            font.pixelSize: Config.fontSizeCaption
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
