# Pinmonkey Fall — Chrome theme

Maps the pinmonkey-desktop shell's "fall" palette (`#141110` shadow, `#282422` background,
`#524840` surfaces, `#d65d0e` orange accent, `#fbf1c7` cream text) onto Chrome's browser chrome
(frame, tab strip, toolbar, bookmark bar, new tab page). Colors only — no page content is
touched.

The tab strip (`frame`) uses the darkest shadow tone and the active tab/toolbar uses the
lighter `#524840` surface tone, so the focused tab reads clearly against its unfocused
siblings - previously both were the same background color and the active tab was nearly
invisible.

Chrome themes can't recolor the omnibox/address bar field itself (unlike Firefox's
`toolbar_field_*` keys) - that's a Chrome limitation, not something left out here.

## Install

Chrome only loads unpacked/local themes with Developer mode on - there's no signed-package
install path for a personal theme like this:

1. Go to `chrome://extensions`
2. Turn on "Developer mode" (top right)
3. "Load unpacked" → select this `chrome-theme` folder
4. Chrome applies it immediately as the active theme

To go back to the default Chrome theme later, remove it from `chrome://extensions` (or set
another theme) - this doesn't delete the folder, just unloads it.

## Rebuilding

Nothing to build - `chrome://extensions`'s "Load unpacked" reads `manifest.json` directly.
Edit colors there and click the reload icon on the extension's card to see changes.
