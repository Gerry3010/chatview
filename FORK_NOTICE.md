# ⚠️ AI-agent-maintained fork

This is a **fork of [`chatview`](https://github.com/SimformSolutionsPvtLtd/chatview)**
(MIT) maintained for the **Chattr** app.

- **Purpose:** apply Chattr-specific fixes/features at the source instead of working
  around the package's limitations in the app.
- **Maintenance:** **auto-synced with upstream weekly** and kept current on a
  **best-effort basis by an AI agent**. Patches are applied at the agent's best
  judgement. **No warranty** — use at your own risk.
- **Upstream:** https://github.com/SimformSolutionsPvtLtd/chatview — please file
  general `chatview` issues/PRs there, not here.
- **Integration branch:** `chattr` (Chattr patches on top of an upstream release tag).

Chattr-specific changes on top of upstream `3.1.0` (branch `chattr`):

- **24-hour local time** — tag `chattr-3.1.0-p1`. Bubble times and date
  separators render in **24-hour** format in the **device's local timezone**
  (upstream rendered `hh:mm a` on the raw UTC value).
  `src/extensions/extensions.dart`, `src/utils/helper.dart`.
- **`SendMessageConfiguration.sendOnEnter`** — tag `chattr-3.1.0-p3`. Enter
  sends the message, **Shift+Enter** inserts a newline. Nullable with a platform
  default (web + desktop on, Android/iOS off). Promotes the previously web-only
  handler and adds a focus guard so the global key handler only fires while the
  composer is focused. `src/widgets/chatui_textfield.dart`,
  `src/models/config_models/send_message_configuration.dart`.
- **`SendMessageConfiguration.onPaste` + `enableClipboardPaste`** — tag
  `chattr-3.1.0-p4`. **Ctrl/Cmd+V** invokes a host paste callback (given the
  composer's `TextEditingController`) so the app can send a pasted image/file
  through its own pipeline. The event is **not** consumed, so the field's native
  text paste still handles plain text. Same platform default as `sendOnEnter`.
  `src/widgets/chatui_textfield.dart`,
  `src/models/config_models/send_message_configuration.dart`.
- **Public composer barrel `package:chatview/composer.dart`** — tag
  `chattr-3.1.0-p5`. A stable public surface for apps that build a **custom
  send-message composer** (send-message widgets, sub-widgets, layout constants,
  ambient config getters) so they no longer import `package:chatview/src/...`.
  If upstream reorganizes its internals, only this one barrel needs to follow —
  the app stays put. `lib/composer.dart`.
- **`ChatBackgroundConfiguration.scrollViewKeyboardDismissBehavior`** — tag
  `chattr-3.1.0-p6`. Exposes the message list's `keyboardDismissBehavior` (e.g.
  `onDrag` to unfocus the composer when the user drags the list). Defaults to
  `manual` (unchanged). `src/models/config_models/message_list_configuration.dart`,
  `src/widgets/chat_groupedlist_widget.dart`.

Manual patches are tagged `chattr-3.1.0-pN`; the weekly auto-sync re-tags as
`chattr-<upstream-version>` after rebasing these patches onto a new upstream
release. See the `chattr` branch history for the exact diffs.
