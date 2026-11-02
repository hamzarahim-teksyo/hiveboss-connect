#!/bin/sh
# HiveBoss Connect plugin: runs the Playbook's local hooks (playbook-hook.mjs)
# with Node. Without Node on PATH every hook exits 0 with no output (fail open),
# and the server keeps delivering the floor on the first prompt (REQ-HPB5).
command -v node >/dev/null 2>&1 || exit 0
exec node "${0%/*}/playbook-hook.mjs" "$@"
