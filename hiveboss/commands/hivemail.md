---
description: Send a HiveBoss page by HiveMail to people who need no account
argument-hint: "<recipients> [note] [--stamp 1000|10000|100000]"
---
The person typed /hiveboss:hivemail: their go-ahead for this one send.

Follow the HiveBoss skill (resource `hiveboss://skill/connector`). Input: $ARGUMENTS. With no page named, attach the page published last in this session. A send is FYI with no stamp unless `--stamp` is given.

1. Write the note, then call `mcp__plugin_hiveboss_hiveboss__send_hivemail` with the recipients, note and page and no `briefings`. Nothing is sent or charged: it returns a `write_briefings` task and a `briefingCode`.
2. For each recipient in the task, call `mcp__plugin_hiveboss_hiveboss__ask_hivemind` with their `askHivemind.question`, then write their own briefing from the note, the page and what came back (at least 40 characters, different for each person, following `task.rules`).
3. Call `send_hivemail` again with exactly the same recipients, note, subject, page and stamp, plus `briefings` (one per recipient) and the `briefingCode`. A send missing any briefing is refused.
4. If the pre-send check warns, show the warning and call again with `confirmWarning` only if the person says yes. Reply with what was sent to whom and the Honey, or the refusal in its words.
