#!/usr/bin/env bash
# Installs the pinmonkey-desktop setup (quickshell + niri + theming) on an
# Arch/Manjaro machine. Idempotent - safe to re-run; anything it would
# overwrite gets backed up first.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

log() { echo "==> $*"; }

backup_if_exists() {
    local target="$1"
    if [ -e "$target" ] || [ -L "$target" ]; then
        mv "$target" "${target}${BACKUP_SUFFIX}"
        log "backed up existing $target -> ${target}${BACKUP_SUFFIX}"
    fi
}

require_pacman() {
    if ! command -v pacman >/dev/null 2>&1; then
        echo "error: pacman not found - this installer only supports Arch/Manjaro." >&2
        exit 1
    fi
}

install_packages() {
    log "installing system packages"
    sudo pacman -S --needed --noconfirm \
        niri quickshell qt5ct qt6ct qt6-wayland polkit \
        brightnessctl playerctl networkmanager bluez upower \
        pipewire pipewire-pulse wireplumber wf-recorder libnotify
    log "note: GDM is only required for the power menu's \"Switch user\" action (not installed by this script)"
}

link_config_dir() {
    local target="$1" source="$2"
    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ]; then
        log "$target already linked correctly"
        return
    fi
    backup_if_exists "$target"
    mkdir -p "$(dirname "$target")"
    ln -s "$source" "$target"
    log "linked $target -> $source"
}

link_configs() {
    link_config_dir "$HOME/.config/quickshell" "$REPO_DIR/quickshell"
    link_config_dir "$HOME/.config/niri" "$REPO_DIR/niri"
}

copy_file() {
    local source="$1" target="$2"
    mkdir -p "$(dirname "$target")"
    if [ -e "$target" ] && cmp -s "$source" "$target"; then
        log "$target already up to date"
        return
    fi
    backup_if_exists "$target"
    cp "$source" "$target"
    log "installed $target"
}

install_qt_theme() {
    log "installing Qt theme"
    copy_file "$REPO_DIR/qt/qt5ct.conf" "$HOME/.config/qt5ct/qt5ct.conf"
    copy_file "$REPO_DIR/qt/colors/fall.conf" "$HOME/.config/qt5ct/colors/fall.conf"
    copy_file "$REPO_DIR/qt/qt6ct.conf" "$HOME/.config/qt6ct/qt6ct.conf"
    copy_file "$REPO_DIR/qt/style-colors.conf" "$HOME/.config/qt6ct/style-colors.conf"
    copy_file "$REPO_DIR/qt/colors/fall.conf" "$HOME/.config/qt6ct/colors/fall.conf"
}

install_icon_theme() {
    log "installing icon theme"
    mkdir -p "$HOME/.local/share/icons"
    for theme in pixelitos-dark pixelitos-light; do
        local target="$HOME/.local/share/icons/$theme"
        backup_if_exists "$target"
        rsync -a "$REPO_DIR/icons/$theme/" "$target/"
        log "installed $target"
    done
}

install_cursor_theme() {
    log "installing cursor theme"
    local target="$HOME/.local/share/icons/pixelfun2"
    backup_if_exists "$target"
    mkdir -p "$HOME/.local/share/icons"
    rsync -a "$REPO_DIR/cursors/pixelfun2/" "$target/"
    log "installed $target"

    gsettings set org.gnome.desktop.interface cursor-theme pixelfun2
    gsettings set org.gnome.desktop.interface cursor-size 24
    log "set gsettings cursor-theme/cursor-size"
}

install_font() {
    log "installing font"
    copy_file "$REPO_DIR/fonts/BitcountGridSingle.ttf" "$HOME/.local/share/fonts/BitcountGridSingle.ttf"
    fc-cache -f >/dev/null
    log "refreshed font cache"
}

install_pam_service() {
    log "installing PAM service file (requires sudo)"
    if [ -e /etc/pam.d/quickshell ] && sudo cmp -s "$REPO_DIR/pam.d/quickshell" /etc/pam.d/quickshell; then
        log "/etc/pam.d/quickshell already up to date"
        return
    fi
    if [ -e /etc/pam.d/quickshell ]; then
        sudo cp /etc/pam.d/quickshell "/etc/pam.d/quickshell${BACKUP_SUFFIX}"
        log "backed up existing /etc/pam.d/quickshell"
    fi
    sudo install -m644 "$REPO_DIR/pam.d/quickshell" /etc/pam.d/quickshell
    log "installed /etc/pam.d/quickshell"
}

install_environment_d() {
    log "installing environment.d cursor variables"
    copy_file "$REPO_DIR/environment.d/cursor.conf" "$HOME/.config/environment.d/cursor.conf"
}

find_firefox_profile_dir() {
    local base="$HOME/.mozilla/firefox" pattern d
    for pattern in "*.default-release" "*.default"; do
        for d in "$base"/$pattern; do
            [ -d "$d" ] && { echo "$d"; return 0; }
        done
    done
    return 1
}

install_firefox_theme() {
    log "installing Firefox chrome tweaks (userChrome.css)"
    local profile_dir
    if ! profile_dir="$(find_firefox_profile_dir)"; then
        log "no Firefox profile found under ~/.mozilla/firefox - skipping (run Firefox once first, then re-run this script)"
        return
    fi

    copy_file "$REPO_DIR/firefox-theme/userChrome.css" "$profile_dir/chrome/userChrome.css"

    local user_js="$profile_dir/user.js"
    local pref_line='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
    touch "$user_js"
    if grep -q "legacyUserProfileCustomizations.stylesheets" "$user_js"; then
        sed -i "s|.*legacyUserProfileCustomizations\.stylesheets.*|$pref_line|" "$user_js"
    else
        printf '%s\n' "$pref_line" >> "$user_js"
    fi
    log "enabled legacyUserProfileCustomizations.stylesheets in $user_js"

    cat <<'EOF'

Firefox color theme (the "Pinmonkey Fall" tab/toolbar theme) can't be installed by this
script - Firefox requires an explicit click to install any extension/theme, signed or not:
  1. Open Firefox
  2. Visit https://addons.mozilla.org/en-US/developers/addon/671fe9047ab342d6b3c3/versions/6592808
  3. Download the signed .xpi and open it in Firefox (or drag it into a Firefox window)
  4. Click "Add" on the install prompt
Restart Firefox afterwards so userChrome.css takes effect too.
EOF
}

install_chrome_theme() {
    cat <<'EOF'

==> Chrome theme (Pinmonkey Fall)
Chrome only loads unpacked themes with Developer mode on - there's no file this script can
drop in place for it, same as Firefox's color theme:
  1. Open Chrome, go to chrome://extensions
  2. Turn on "Developer mode" (top right)
  3. "Load unpacked" -> select the chrome-theme/ folder in this repo
EOF
}

seed_env_file() {
    if [ ! -e "$REPO_DIR/.env" ]; then
        cp "$REPO_DIR/.env.example" "$REPO_DIR/.env"
        log "created $REPO_DIR/.env from .env.example - fill in CTA_TRAIN_API_KEY/CTA_BUS_API_KEY to enable the lock screen's transit widget (optional)"
    fi
}

ensure_video_group() {
    if id -nG "$USER" | tr ' ' '\n' | grep -qx video; then
        log "$USER already in the video group"
    else
        sudo usermod -aG video "$USER"
        log "added $USER to the video group (needed for the brightness slider) - log out and back in for this to take effect"
    fi
}

main() {
    require_pacman
    install_packages
    link_configs
    install_qt_theme
    install_icon_theme
    install_cursor_theme
    install_font
    install_pam_service
    install_environment_d
    install_firefox_theme
    install_chrome_theme
    seed_env_file
    ensure_video_group

    cat <<'EOF'

==> Done.

Log out and back in (or restart niri) for everything to take full effect:
  - niri will spawn quickshell at startup from the newly linked config
  - the XCURSOR_THEME/XCURSOR_SIZE environment variables need a fresh session
  - video group membership (if just added) needs a fresh login

Check niri/config.kdl's output block against `niri msg outputs` if this is a
different machine than the one this repo was built on - monitor name/scale
may need adjusting.
EOF
}

main "$@"
