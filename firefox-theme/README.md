# Pinmonkey Fall — Firefox theme

Maps the pinmonkey-desktop shell's "fall" palette (`#282422` background, `#524840` surfaces,
`#d65d0e` orange accent, `#fbf1c7` cream text) onto Firefox's browser chrome (tabs, toolbar,
address bar, menus, sidebar). Colors only — no page content is touched.

## Install

Firefox requires every theme to be signed by Mozilla before it can be installed permanently
on release Firefox. Pick whichever of these fits:

**Quick, no signing needed, but temporary (cleared on restart):**
1. Go to `about:debugging#/runtime/this-firefox`
2. "Load Temporary Add-on…" → select `manifest.json` in this folder

**Permanent, no signing needed (Developer Edition / Nightly / ESR only):**
1. In those builds, set `xpinstall.signatures.required` to `false` in `about:config`
2. Drag `pinmonkey-fall.xpi` into a Firefox window, or open it via `File > Open`

**Permanent on regular Firefox, properly signed:**
1. Create a free account at https://addons.mozilla.org/developers/
2. Submit `pinmonkey-fall.xpi` for signing as an **unlisted** add-on (no public review, just
   signing) — see https://extensionworkshop.com/documentation/publish/signing-and-distribution-overview/
3. Download the signed `.xpi` Mozilla sends back and install that one normally

## Rebuilding the .xpi after editing manifest.json

```sh
cd firefox-theme
zip -r -X pinmonkey-fall.xpi manifest.json icon-48.png icon-96.png
```

Validated with `web-ext lint` (0 errors, 0 warnings).
