---
description: Turn a published HiveBoss page into a vertical video
argument-hint: "[page link or id] [what the reel should say] [--room <name>]"
---
The person typed /hiveboss:reel: their go-ahead for this one reel.

Follow the HiveBoss skill (resource `hiveboss://skill/connector`). Input: $ARGUMENTS. Which reel:
- a page named: pass its `pageId`;
- no page named: pass `lastPublish: true` (the page this device published last);
- the person asks for a reel of their own material with no page: pass neither. It is a standalone reel in `room` (if `--room` was given) or the device's default room, and every figure must be one your script states.

When `mcp__plugin_hiveboss_hiveboss__reel_types` is listed, reels and Motion pages you make are free:

1. Call `reel_types` once for the 4 reel kinds. Pick the kind that fits (the page's design suggests one), and call `reel_types` with that `kind` for its scene rules, word caps, worked example and checklist.
2. For a page, call `make_reel` with the page choice and the kind as `recipe`, and no `script` and no `lines`: HiveBoss fills the script from the page. For a standalone reel, write the script yourself, as in the worked example. Nothing is drawn: it returns a `write_reel_lines` task (the speaking scenes in order, each with its purpose and `maxWords`) and a `submitCode`.
3. Write one spoken line per speaking scene, in order, within its `maxWords`, using only figures the page states. Check them against the kind's checklist.
4. Call `make_reel` again with the same arguments, plus `lines` and the `submitCode`. If the lines don't fit, the reply lists `task.problems`: fix them and submit again with the same code.
5. When the person also wants a Motion page (charts that draw and numbers that count) of a page in one of the 7 designs `reel_types` lists, call `publish_motion` with its `pageId`.
6. Reply with the links, and "0 Honey charged" as returned, or the refusal in its words.

When `reel_types` is not listed:

1. Write the recipe and the script yourself (from the page, when there is one), then call `mcp__plugin_hiveboss_hiveboss__make_reel` with that page choice, recipe, title and script and no `lines`. Nothing is drawn or charged: it returns a `write_reel_lines` task (the speaking scenes in order, each with its purpose and `maxWords`, and the figures you may use) and a `submitCode`.
2. Write one spoken line per speaking scene, in order, within its `maxWords`, using only the task's figures.
3. Call `make_reel` again with exactly the same arguments (page choice or room, recipe, title, script), plus `lines` and the `submitCode`. If the lines don't fit, the reply lists `task.problems`: fix them and submit again with the same code.
4. Reply with the video link and the Honey charged, or the refusal in its words.
