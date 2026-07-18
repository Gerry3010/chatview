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
- **`ChatBubbleConfiguration.onLongPress(Message)`** — tag `chattr-3.1.0-p7`.
  A clean long-press callback that hands the message to the host directly, so an
  app can open its own message-actions UI without hijacking `replyPopupBuilder`
  (empty snackbar + microtask). Enables long-press on its own and bypasses the
  built-in reaction-popup/reply-snackbar path. `src/models/config_models/
  chat_bubble_configuration.dart`, `src/widgets/chat_bubble_widget.dart`.
- **`ChatBubbleConfiguration.timestampRevealBuilder` + `onSwipeToTimestamp`** —
  tag `chattr-3.1.0-p8`. WhatsApp-style "slide-to-timestamp": swiping a bubble in
  the OPPOSITE direction from the reply gesture (which upstream ignored — the
  negative-distance branch just reset) peeks a host-built timestamp chip in the
  gutter, and a hard swipe past the threshold fires `onSwipeToTimestamp(Message)`
  (e.g. to open a per-recipient info sheet). The reveal chip is built lazily via
  a `ValueGetter<Widget?>` — only once a reveal drag begins, never per bubble per
  frame — and the reply gesture is untouched. `src/models/config_models/
  chat_bubble_configuration.dart`, `src/widgets/chat_bubble_widget.dart`,
  `src/widgets/swipe_to_reply.dart`. Test: `test/swipe_to_reply_test.dart`.
- **`SendMessageConfiguration.composerContextMenuBuilder`** — tag
  `chattr-3.1.0-p9`. Threads a custom `contextMenuBuilder` into the COMPOSER's
  `TextField` (upstream hard-wired the default toolbar), so a host app can add
  its own selection-menu entries — e.g. a "Paste image" action on iOS, where the
  native menu offers paste for text only. Falls back to the platform-default
  editable-text toolbar when unset (passing `null` straight through would remove
  the menu). `src/models/config_models/send_message_configuration.dart`,
  `src/widgets/chatui_textfield.dart`.
- **Reply-quote author + empty-message fixes** — tag `chattr-3.1.0-p10`. Two
  upstream-behaviour fixes: (1) `ReplyMessageWidget` named the reply-quote header
  from `replyBy` (the reply's sender) instead of `replyTo` (the quoted message's
  author), so a reply read "reply to <the replier>"; it now resolves `replyTo`
  (bubble alignment still follows the sender). (2) `String.isAllEmoji` returned
  `true` for the empty string, so an empty custom message (e.g. a host "unread"
  divider) hit the 30px emoji-bubble path and never reached
  `customMessageBuilder`, rendering as a blank gap; `''` is now not all-emoji.
  `src/widgets/reply_message_widget.dart`, `src/extensions/extensions.dart`.
- **Stable default message sort** — tag `chattr-3.1.0-p11`. When
  `ChatBackgroundConfiguration.sortEnable` is on and no custom `messageSorter`
  is supplied, `sortMessage`'s fallback comparator sorted only by `createdAt`.
  `createdAt` is not a unique key (sub-second collisions, mixed clock sources)
  and `List.sort` is not stable, so equal timestamps rendered in an arbitrary,
  jittering order. The fallback now breaks ties by message `id`, making it a
  strict total order (deterministic across rebuilds/devices; also safe as a
  keyset-pagination boundary). Hosts that pass their own `messageSorter` are
  unaffected. `src/widgets/chat_groupedlist_widget.dart`.

Manual patches are tagged `chattr-3.1.0-pN`; the weekly auto-sync re-tags as
`chattr-<upstream-version>` after rebasing these patches onto a new upstream
release. See the `chattr` branch history for the exact diffs.
