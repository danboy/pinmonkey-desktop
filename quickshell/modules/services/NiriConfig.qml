pragma Singleton
import Quickshell
import Quickshell.Io

// Targeted editor for specific known settings in niri's config.kdl input{} block (not a
// general KDL parser - it only knows how to find/toggle/set the handful of lines the Mouse/
// Keyboard/Tablet settings pages expose). niri watches config.kdl and hot-reloads it, so a
// write here takes effect live without restarting niri. Every write backs up the previous
// file content to .bak.<timestamp> first.
Singleton {
    id: root

    readonly property string configPath: Quickshell.env("HOME") + "/.config/niri/config.kdl"

    property bool loaded: false
    property bool numlockEnabled: false
    property bool mouseNaturalScroll: false
    property bool mouseLeftHanded: false
    property string mouseAccelProfile: ""
    property real mouseAccelSpeed: 0
    property bool tabletConfigured: false
    property string tabletOutput: ""

    // --- Block extraction (brace-counting, not full KDL parsing) ---
    function findBlock(text, blockName) {
        const re = new RegExp(`\\n(\\s*)${blockName}\\s*\\{`);
        const m = text.match(re);
        if (!m)
            return null;
        const contentStart = m.index + m[0].length;
        let depth = 1;
        let i = contentStart;
        while (depth > 0 && i < text.length) {
            if (text[i] === "{")
                depth++;
            else if (text[i] === "}")
                depth--;
            i++;
        }
        return {
            contentStart,
            contentEnd: i - 1,
            indent: m[1]
        };
    }

    function blockText(text, blockName) {
        const block = findBlock(text, blockName);
        return block ? text.substring(block.contentStart, block.contentEnd) : "";
    }

    function hasFlag(blockContent, name) {
        return new RegExp(`^\\s*${name}\\s*$`, "m").test(blockContent);
    }

    function flagValue(blockContent, name) {
        const m = blockContent.match(new RegExp(`^\\s*(?:// *)?${name}\\s+"?([^"\\n]*)"?\\s*$`, "m"));
        return m ? m[1] : "";
    }

    function reparse() {
        const text = file.text();
        root.numlockEnabled = root.hasFlag(root.blockText(text, "keyboard"), "numlock");
        const mouseBlock = root.blockText(text, "mouse");
        root.mouseNaturalScroll = root.hasFlag(mouseBlock, "natural-scroll");
        root.mouseLeftHanded = root.hasFlag(mouseBlock, "left-handed");
        root.mouseAccelProfile = root.flagValue(mouseBlock, "accel-profile") || "adaptive";
        root.mouseAccelSpeed = parseFloat(root.flagValue(mouseBlock, "accel-speed")) || 0;
        const tabletBlock = root.findBlock(text, "tablet");
        root.tabletConfigured = tabletBlock !== null;
        root.tabletOutput = root.flagValue(root.blockText(text, "tablet"), "map-to-output");
        root.loaded = true;
    }

    // Sets a bare flag (e.g. "numlock", "natural-scroll") on or off within blockName,
    // uncommenting/commenting or appending the line as needed.
    function setFlag(blockName, name, enabled) {
        const text = file.text();
        const block = root.findBlock(text, blockName);
        if (!block) {
            console.log("NiriConfig: block not found:", blockName);
            return;
        }
        let content = text.substring(block.contentStart, block.contentEnd);
        const activeRe = new RegExp(`^(\\s*)${name}\\s*$`, "m");
        const commentRe = new RegExp(`^(\\s*)//\\s*${name}\\s*$`, "m");
        if (enabled) {
            if (activeRe.test(content)) {
                return;
            } else if (commentRe.test(content)) {
                content = content.replace(commentRe, `$1${name}`);
            } else {
                content = content.replace(/\s*$/, `\n${block.indent}    ${name}\n${block.indent}`);
            }
        } else {
            if (commentRe.test(content) || (!activeRe.test(content))) {
                return;
            }
            content = content.replace(activeRe, `$1// ${name}`);
        }
        root.writeConfig(text.substring(0, block.contentStart) + content + text.substring(block.contentEnd));
    }

    // Sets a valued line (e.g. `accel-speed 0.2`, `accel-profile "flat"`) within blockName,
    // creating/uncommenting/replacing the line as needed. Pass quoted: true for string values.
    function setValue(blockName, name, value, quoted) {
        const text = file.text();
        const block = root.findBlock(text, blockName);
        if (!block) {
            console.log("NiriConfig: block not found:", blockName);
            return;
        }
        let content = text.substring(block.contentStart, block.contentEnd);
        const v = quoted ? `"${value}"` : value;
        const line = `${name} ${v}`;
        const activeRe = new RegExp(`^(\\s*)${name}\\s+\\S.*$`, "m");
        const commentRe = new RegExp(`^(\\s*)//\\s*${name}\\s+\\S.*$`, "m");
        if (activeRe.test(content)) {
            content = content.replace(activeRe, `$1${line}`);
        } else if (commentRe.test(content)) {
            content = content.replace(commentRe, `$1${line}`);
        } else {
            content = content.replace(/\s*$/, `\n${block.indent}    ${line}\n${block.indent}`);
        }
        root.writeConfig(text.substring(0, block.contentStart) + content + text.substring(block.contentEnd));
    }

    // Ensures a top-level block exists (e.g. "tablet"), appending an empty one at the end of
    // the file if it's missing, and returns the (possibly updated) full text.
    function ensureBlock(text, blockName) {
        if (root.findBlock(text, blockName))
            return text;
        return text.replace(/\s*$/, "") + `\n\n${blockName} {\n}\n`;
    }

    function setTabletOutput(outputName) {
        let text = root.ensureBlock(file.text(), "tablet");
        const block = root.findBlock(text, "tablet");
        let content = text.substring(block.contentStart, block.contentEnd);
        const line = `map-to-output "${outputName}"`;
        const activeRe = /^(\s*)map-to-output\s+\S.*$/m;
        if (activeRe.test(content))
            content = content.replace(activeRe, `$1${line}`);
        else
            content = content.replace(/\s*$/, `\n${block.indent}    ${line}\n${block.indent}`);
        root.writeConfig(text.substring(0, block.contentStart) + content + text.substring(block.contentEnd));
    }

    function writeConfig(newText) {
        const backupPath = `${root.configPath}.bak.${Date.now()}`;
        backupProcess.command = ["cp", root.configPath, backupPath];
        backupProcess.running = true;
        file.setText(newText);
    }

    Process {
        id: backupProcess
    }

    FileView {
        id: file

        path: root.configPath
        watchChanges: true

        onLoaded: root.reparse()
        onFileChanged: reload()
    }
}
