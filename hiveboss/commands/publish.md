---
description: Publish this session's work as a page in your HiveBoss room
argument-hint: "[what to publish] [--room <name>] [--repo <name>]"
---
The person typed /hiveboss:publish: that is their go-ahead for this one publish (no need to ask again).

Follow the HiveBoss skill (resource `hiveboss://skill/connector`; read it now if you have not this session).

1. Input: $ARGUMENTS. With no text, the input is the work done in this session.
2. Write the page document (title, sections, figures, sources) for a teammate who was not here, plus knowledge items for each decision or fact worth keeping.
3. Call `mcp__plugin_hiveboss_hiveboss__publish_page` once with the document and items. Pass `repo` with the repository name HiveBoss gave at session start (the git top-level folder) unless `--repo` names another. Outside a git repository, pass no `repo`. Pass `room` only if `--room` was given.
4. Reply with the page link and the room link the tool returns, and the Honey it charged. When the result says "Created room #<name>: <link>", print that line exactly. If it refused (secret found, out of Honey, room limit), say why in its words and stop.
