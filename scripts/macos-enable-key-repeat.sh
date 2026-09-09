#!/usr/bin/env sh
set -eu

# Disable macOS press-and-hold accent popups so held keys repeat.
# Useful for VS Code Neovim, JetBrains IDEs, terminal editors, and other apps
# where holding h/j/k/l should keep moving.

print_usage() {
  cat <<'EOF'
Usage: macos-enable-key-repeat.sh [options] [bundle-id-or-app-path ...]

Options:
  --all-installed   Also write the preference for every app found in
                    /Applications and ~/Applications.
  --dry-run         Print the defaults commands without changing anything.
  -h, --help        Show this help.

Examples:
  ./macos-enable-key-repeat.sh
  ./macos-enable-key-repeat.sh --all-installed
  ./macos-enable-key-repeat.sh com.microsoft.VSCode "/Applications/Cursor.app"
EOF
}

DRY_RUN=0
ALL_INSTALLED=0
DOMAINS_FILE=$(mktemp "${TMPDIR:-/tmp}/key-repeat-domains.XXXXXX")
trap 'rm -f "$DOMAINS_FILE"' EXIT

add_domain() {
  if [ -n "${1:-}" ]; then
    printf '%s\n' "$1" >>"$DOMAINS_FILE"
  fi
}

add_common_domains() {
  cat <<'EOF' >>"$DOMAINS_FILE"
com.microsoft.VSCode
com.microsoft.VSCodeInsiders
com.visualstudio.code
com.vscodium
com.todesktop.230313mzl4w4u92
EOF
}

bundle_id_for_app() {
  app_path=$1
  /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' \
    "$app_path/Contents/Info.plist" 2>/dev/null || true
}

add_app_path() {
  app_path=$1
  bundle_id=$(bundle_id_for_app "$app_path")
  if [ -n "$bundle_id" ]; then
    add_domain "$bundle_id"
  else
    printf 'warning: could not read bundle id from %s\n' "$app_path" >&2
  fi
}

add_installed_app_domains() {
  for root in /Applications "$HOME/Applications"; do
    [ -d "$root" ] || continue
    find "$root" -maxdepth 2 -type d -name '*.app' -print 2>/dev/null |
      while IFS= read -r app_path; do
        add_app_path "$app_path"
      done
  done
}

write_global_preference() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'defaults write -g ApplePressAndHoldEnabled -bool false\n'
  else
    defaults write -g ApplePressAndHoldEnabled -bool false
    printf 'set %-42s ApplePressAndHoldEnabled=false\n' '-g'
  fi
}

write_app_preference() {
  domain=$1
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'defaults write %s ApplePressAndHoldEnabled -bool false\n' "$domain"
  else
    defaults write "$domain" ApplePressAndHoldEnabled -bool false
    printf 'set %-42s ApplePressAndHoldEnabled=false\n' "$domain"
  fi
}

add_common_domains

while [ "$#" -gt 0 ]; do
  case "$1" in
    --all-installed)
      ALL_INSTALLED=1
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *.app)
      add_app_path "$1"
      ;;
    *)
      add_domain "$1"
      ;;
  esac
  shift
done

if [ "$ALL_INSTALLED" -eq 1 ]; then
  add_installed_app_domains
fi

write_global_preference

sort -u "$DOMAINS_FILE" |
  while IFS= read -r domain; do
    write_app_preference "$domain"
  done

cat <<'EOF'

Done. Fully quit and reopen affected apps.
For VS Code, Cursor, and other Electron apps, use Cmd+Q instead of just reloading a window.
EOF
