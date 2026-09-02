#!/bin/sh
# Focus a running app, or launch it if it has no windows.
# macOS/AeroSpace port of the GlazeWM focus-or-launch.ps1.
#
#   focus-or-launch.sh <bundle-id>
#
# Three things this does that a `aerospace list-windows | grep -i <name>`
# one-liner does not:
#
#   1. Matches on bundle id only. `list-windows` prints window titles too, so
#      `grep -i arc` matched "Google Search" and sent alt-a to Chrome.
#   2. Cycles. Pressing the binding again advances to the app's next window
#      rather than re-focusing whichever one happened to sort first.
#   3. Restores minimized windows. `aerospace focus --window-id` reports
#      success on a minimized window while leaving it in the Dock, so the
#      binding looks like it did nothing.

set -u

AEROSPACE=/opt/homebrew/bin/aerospace

bundle_id=${1:?usage: focus-or-launch.sh <bundle-id>}

ids=$("$AEROSPACE" list-windows --monitor all --app-bundle-id "$bundle_id" \
	--format '%{window-id}' 2>/dev/null | sort -n)

# Not running, or running with no windows (common for menu-bar-only states).
if [ -z "$ids" ]; then
	open -b "$bundle_id"
	exit $?
fi

focused_id=$("$AEROSPACE" list-windows --focused --format '%{window-id}' 2>/dev/null)
focused_bundle=$("$AEROSPACE" list-windows --focused --format '%{app-bundle-id}' 2>/dev/null)

if [ "$focused_bundle" = "$bundle_id" ]; then
	# Already in this app: advance to its next window, wrapping around.
	target=$(printf '%s\n' "$ids" | awk -v cur="$focused_id" \
		'{a[NR]=$0} END {for (i=1; i<=NR; i++) if (a[i]==cur) {print a[i%NR+1]; exit}}')
else
	# Prefer a window already on the focused workspace, so a jump from a
	# workspace that has this app does not yank you somewhere else.
	workspace=$("$AEROSPACE" list-workspaces --focused --format '%{workspace}' 2>/dev/null)
	target=$("$AEROSPACE" list-windows --workspace "$workspace" --app-bundle-id "$bundle_id" \
		--format '%{window-id}' 2>/dev/null | sort -n | head -1)
fi

[ -z "${target:-}" ] && target=$(printf '%s\n' "$ids" | head -1)

# Un-minimize before focusing. AeroSpace exposes no minimized state (there is no
# %{window-is-minimized} placeholder), so this cannot target one window -- it
# restores every window of the app. Inherits AeroSpace.app's Accessibility grant.
app_name=$("$AEROSPACE" list-windows --monitor all --app-bundle-id "$bundle_id" \
	--format '%{app-name}' 2>/dev/null | head -1)
if [ -n "$app_name" ]; then
	osascript - "$app_name" >/dev/null 2>&1 <<'APPLESCRIPT'
on run argv
	try
		tell application "System Events"
			tell process (item 1 of argv)
				set value of attribute "AXMinimized" of every window to false
			end tell
		end tell
	end try
end run
APPLESCRIPT
fi

"$AEROSPACE" focus --window-id "$target"
