#!/bin/sh
# Focus a running app by bundle id, cycling its windows, or launch it.
#
#   focus-or-launch.sh <bundle-id>

set -u

AEROSPACE=/opt/homebrew/bin/aerospace

bundle_id=${1:?usage: focus-or-launch.sh <bundle-id>}

all=$("$AEROSPACE" list-windows --monitor all --app-bundle-id "$bundle_id" \
	--format '%{window-id}|%{window-title}' 2>/dev/null | sort -n)

if [ -z "$all" ]; then
	open -b "$bundle_id"
	exit $?
fi

app_name=$("$AEROSPACE" list-windows --monitor all --app-bundle-id "$bundle_id" \
	--format '%{app-name}' 2>/dev/null | head -1)

ax=$(osascript - "$app_name" 2>/dev/null <<'APPLESCRIPT'
on run argv
	set anyMinimized to "no"
	set titles to ""
	try
		tell application "System Events" to tell process (item 1 of argv)
			repeat with w in windows
				try
					if value of attribute "AXMinimized" of w then set anyMinimized to "yes"
					set titles to titles & (name of w) & linefeed
				end try
			end repeat
		end tell
	end try
	return anyMinimized & linefeed & titles
end run
APPLESCRIPT
)
any_minimized=$(printf '%s\n' "$ax" | sed -n 1p)
real_titles=$(printf '%s\n' "$ax" | sed -n '2,$p' | sed '/^$/d')
front_title=$(printf '%s\n' "$real_titles" | sed -n 1p)

ids=$(printf '%s\n' "$all" | sed 's/|.*//')
aero_count=$(printf '%s\n' "$ids" | wc -l | tr -d ' ')
ax_count=0
[ -n "$real_titles" ] && ax_count=$(printf '%s\n' "$real_titles" | wc -l | tr -d ' ')

focused_bundle=$("$AEROSPACE" list-windows --focused --format '%{app-bundle-id}' 2>/dev/null)

# Extra AeroSpace nodes mean a macOS tab group sharing one frame; let macOS pick.
if [ "$ax_count" -gt 0 ] && [ "$aero_count" -gt "$ax_count" ]; then
	[ "$focused_bundle" = "$bundle_id" ] && exit 0
	open -b "$bundle_id"
	exit $?
fi

focused_id=$("$AEROSPACE" list-windows --focused --format '%{window-id}' 2>/dev/null)

target=''
if [ "$focused_bundle" = "$bundle_id" ]; then
	target=$(printf '%s\n' "$ids" | awk -v cur="$focused_id" \
		'{a[NR]=$0} END {for (i=1; i<=NR; i++) if (a[i]==cur) {print a[i%NR+1]; exit}}')
else
	workspace=$("$AEROSPACE" list-workspaces --focused --format '%{workspace}' 2>/dev/null)
	target=$("$AEROSPACE" list-windows --workspace "$workspace" --app-bundle-id "$bundle_id" \
		--format '%{window-id}' 2>/dev/null | sort -n | head -1)

	# AXWindows is z-ordered, so its first entry is the most recently used.
	if [ -z "$target" ] && [ -n "$front_title" ]; then
		target=$(printf '%s\n' "$all" | awk -v t="$front_title" \
			'{ i = index($0, "|"); if (i && substr($0, i + 1) == t) { print substr($0, 1, i - 1); exit } }')
	fi
fi

[ -z "$target" ] && target=$(printf '%s\n' "$ids" | head -1)

# Restores every window of the app: AeroSpace exposes no per-window minimized state.
if [ "$any_minimized" = "yes" ] && [ -n "$app_name" ]; then
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
