---
description: Answer the latest waiting HiveBoss reply, or the one named
argument-hint: "<text> [--to <thread>] [--republish]"
---
The person typed /hiveboss:reply: their go-ahead for this one reply.

Call `mcp__plugin_hiveboss_hiveboss__reply` once with the person's text: $ARGUMENTS. Answer the latest waiting thread unless `--to` names one. With `--republish`, also pass the republish flag so the page gets one new edition carrying the update.

With `--republish`, write the updated page document yourself and pass it as `document`. If the reply settles something worth keeping (a decision, a date, a fact), also pass knowledge items you write as `items`: the reply's message is not read into the HiveMind, so items are how it is remembered. If there is no text, ask the person what to say; do not write a reply on your own. Reply with where it was posted, or the refusal in its words.
