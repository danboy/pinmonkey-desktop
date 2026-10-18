# pinmonkey-desktop

A portable desktop setup: a [Quickshell](https://quickshell.outfoxxed.me/) panel/launcher/
lock screen for [niri](https://github.com/YaLTeR/niri), themed with a pinmonkey-app-matched
"fall" palette, a custom pixel-art icon theme, and a matching cursor theme.

## Install

Arch/Manjaro only (uses `pacman`).

```sh
./install.sh
```

This installs missing system packages, symlinks `~/.config/quickshell` and `~/.config/niri`
into this repo, and copies in the Qt theme, icon theme, cursor theme, font, lock-screen PAM
service file, and cursor environment variables. Safe to re-run — every step is idempotent and
backs up anything it would otherwise overwrite.

After installing, log out and back in (or restart niri) to pick up the `spawn-at-startup
"quickshell"` launch, the cursor environment variable, and (if it had to add you to the
`video` group for the brightness slider) the new group membership.

## Known manual steps

- **CTA transit widget** (optional): copy `.env.example` to `.env` and fill in
  `CTA_TRAIN_API_KEY` / `CTA_BUS_API_KEY` (free keys from
  [transitchicago.com](https://www.transitchicago.com/developers/)) if you want Chicago
  transit arrivals on the lock screen. Without it, that widget just shows
  "Transit not configured" — everything else works fine.
- **niri output config**: `niri/config.kdl` may reference this machine's specific monitor
  name/scale/transform. Check the `output "..."` block against `niri msg outputs` on a new
  machine and adjust as needed.
- **"Switch user" in the power menu** calls GNOME Display Manager's dbus interface — only
  works if GDM is the active display manager.

## Layout

| Path | What |
|---|---|
| `quickshell/` | Panel, launcher, control center, lock screen, OSD — symlinked to `~/.config/quickshell` |
| `niri/` | Compositor config — symlinked to `~/.config/niri` |
| `qt/` | qt5ct/qt6ct settings + the shared "fall" color scheme |
| `icons/` | `pixelitos-dark`/`pixelitos-light` icon theme |
| `cursors/pixelfun2` | Cursor theme |
| `fonts/` | Bitcount Grid Single (the shell's only font) |
| `pam.d/quickshell` | PAM service used by the lock screen's password check |
| `environment.d/cursor.conf` | `XCURSOR_THEME`/`XCURSOR_SIZE` |
