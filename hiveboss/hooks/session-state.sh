#!/bin/sh
# HiveBoss Connect plugin: local hook helper.
#
#   session-state.sh session-start    SessionStart: names the git repo for bare commands (none outside git)
#   session-state.sh mark-changed     PostToolUse on Edit|Write|MultiEdit|NotebookEdit
#   session-state.sh mark-published   PostToolUse on publish_page
#   session-state.sh busy             UserPromptSubmit: marks the session busy (the listener never wakes it then)
#   session-state.sh stop             Stop: clears the busy mark; offers a publish at most once per session
#                                     and shows HiveBoss's "/hiveboss" nudge to the person once
#   session-state.sh pre-compact      PreCompact: in an agent's home, marks that STATE.md needs updating
#   session-state.sh after-compact    SessionStart (compact): then reminds the agent to update STATE.md
#
# Runs on this machine only: no network, no token, no prompt text sent anywhere
# (the first Stop only searches the session's transcript for HiveBoss's nudge
# line). State is empty marker files per session under the plugin's data directory
# (${CLAUDE_PLUGIN_DATA}/sessions), mode 700, pruned after 7 days. Never blocks:
# every path exits 0, and the Stop answer is a soft `additionalContext` and a
# `systemMessage` to the person, never `decision: block`.
set -u
umask 077

ACTION="${1:-}"
INPUT=$(cat 2>/dev/null || true)

# One JSON string field of the hook input (Claude Code sends flat JSON objects).
field() {
	printf '%s' "$INPUT" | tr -d '\n' | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n 1
}

SID=$(field session_id)
case "$SID" in
	"" | *[!A-Za-z0-9._-]*) SID="" ;;
esac

DATA="${CLAUDE_PLUGIN_DATA:-}"
DIR=""
if [ -n "$DATA" ] && [ -n "$SID" ]; then
	DIR="$DATA/sessions"
	mkdir -p "$DIR" 2>/dev/null && chmod 700 "$DIR" 2>/dev/null || DIR=""
fi

# agent-homes REQ-AGH31: the session's folder is an agent's home (the listener writes AGENT.md and STATE.md there).
in_agent_home() {
	dir="${HIVEBOSS_AGENT_HOME:-${CLAUDE_PROJECT_DIR:-.}}"
	[ -f "$dir/AGENT.md" ] && [ -f "$dir/STATE.md" ]
}

json_string() {
	# Escape for a JSON string: backslash, quote, and control characters out.
	printf '%s' "$1" | tr -d '\000-\037' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

case "$ACTION" in
	session-start)
		root=""
		if command -v git >/dev/null 2>&1; then
			root=$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --show-toplevel 2>/dev/null || true)
		fi
		# Outside a git repository there is no repo to name: a folder such as
		# ~/Downloads must never become a room's name.
		repo=$(basename "$root" 2>/dev/null || true)
		[ -n "$repo" ] && [ "$repo" != "/" ] || exit 0
		repo=$(json_string "$repo")
		printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"HiveBoss: this session works in the repository \\"%s\\". Pass repo: \\"%s\\" to HiveBoss tools so bare commands use its room. Read hiveboss://skill/connector before your first HiveBoss call."}}\n' "$repo" "$repo"
		;;
	mark-changed)
		[ -n "$DIR" ] && : >"$DIR/$SID.changed"
		;;
	mark-published)
		[ -n "$DIR" ] && : >"$DIR/$SID.published"
		;;
	busy)
		[ -n "$DIR" ] && : >"$DIR/$SID.busy"
		;;
	stop)
		[ -n "$DIR" ] && rm -f "$DIR/$SID.busy"
		# A stop that a hook already continued: never nudge again (no loops).
		if printf '%s' "$INPUT" | tr -d '\n' | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
			exit 0
		fi
		[ -n "$DIR" ] || exit 0
		find "$DIR" -type f -mtime +7 -exec rm -f {} + 2>/dev/null || true
		# connect-session-setup REQ-CSS16: HiveBoss's prompt hook tells only the model that this
		# session is none of the person's agents (additionalContext). On the session's first
		# Stop, the line Claude Code recorded from that hook is shown to the person as well,
		# once. The shown text is this script's own, never text copied from the transcript.
		# A fallback once the server's hook answer carries the line as its own systemMessage.
		nudge=""
		if [ ! -f "$DIR/$SID.nudge-checked" ]; then
			: >"$DIR/$SID.nudge-checked"
			transcript=$(field transcript_path)
			if [ -f "$transcript" ] && grep -F '"attachment":{"type":"hook_additional_context"' "$transcript" 2>/dev/null | grep -F '"hookEvent":"UserPromptSubmit"' | grep -qF "This session isn't one of your agents yet."; then
				nudge="HiveBoss: this session isn't one of your agents yet. Run /hiveboss to set it up."
				# A HiveBoss that already showed it to the person on the prompt (its own systemMessage): not twice.
				if grep -F '"attachment":{"type":"hook_system_message"' "$transcript" 2>/dev/null | grep -F '"hookEvent":"UserPromptSubmit"' | grep -qiF "isn't one of your agents yet"; then
					nudge=""
				fi
			fi
		fi
		offer=""
		if [ -f "$DIR/$SID.changed" ] && [ ! -f "$DIR/$SID.published" ] && [ ! -f "$DIR/$SID.offered" ]; then
			: >"$DIR/$SID.offered"
			offer='"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"HiveBoss: this session changed files and nothing was published to HiveBoss. End your reply with one short sentence offering to publish this work to the HiveBoss room as a page, saying in a few words what the page would hold, and wait. Do not call any HiveBoss tool now: publish only after the person says yes. Offer once; do not repeat it."}'
		fi
		if [ -n "$nudge" ] && [ -n "$offer" ]; then
			printf '{"systemMessage":"%s",%s}\n' "$nudge" "$offer"
		elif [ -n "$nudge" ]; then
			printf '{"systemMessage":"%s"}\n' "$nudge"
		elif [ -n "$offer" ]; then
			printf '{%s}\n' "$offer"
		fi
		;;
	pre-compact)
		# agent-homes REQ-AGH31: Claude Code gives a PreCompact hook no way to speak to the model, so the
		# reminder is marked here and said by the SessionStart hook that runs right after the compaction.
		in_agent_home || exit 0
		[ -n "$DIR" ] && : >"$DIR/$SID.compacted"
		;;
	after-compact)
		in_agent_home || exit 0
		# Without the plugin's data folder there is no mark to read: remind anyway.
		if [ -n "$DIR" ]; then
			[ -f "$DIR/$SID.compacted" ] || exit 0
			rm -f "$DIR/$SID.compacted"
		fi
		printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"HiveBoss: this conversation was just compacted. Before going on, update STATE.md with the state_update tool: what you have in flight and your open items, so nothing is lost at the next compaction or run."}}\n'
		;;
esac
exit 0
