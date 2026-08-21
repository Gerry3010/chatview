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

- **Initials-circle avatar fallback** — tag `chattr-3.1.0-p12`. Upstream
  `ProfileImageWidget` collapsed to a 0px `SizedBox.shrink` whenever no image
  resolved (the `defaultAvatarImage` fallback is unreachable — the switch keys on
  `imageUrl`, not on the default), so a picture-less user's grouped bubble jumped
  to the far left. Added an optional `userName` to `ProfileImageWidget` (threaded
  through `ProfileCircle`, the incoming-bubble avatar in `chat_bubble_widget`, and
  the `ChatViewAppBar` header slot): when there is no image but a name is given,
  it renders a filled initials circle with a deterministic per-name colour instead
  of the empty box. Callers that pass no `userName` keep the original behaviour.
  `src/widgets/profile_image_widget.dart`, `profile_circle.dart`,
  `chat_bubble_widget.dart`, `chat_view_appbar.dart`.

- **Reply-quote cap + inline emoji size** — tag `chattr-3.1.0-p13`. Two message
  rendering fixes. (a) The SENT-bubble reply quote (`ReplyMessageWidget`) rendered
  `Text(replyMessage)` with no line cap, so a long text or media filename grew
  into a many-line block that broke the bubble; now `maxLines: 2` + ellipsis
  (mirrors the composer banner's cap). (b) New `ChatBubble.emojiSize` (double?):
  inline EMOJI runs of a text message render at that size instead of the body
  size — bare/inline emojis at the text size read as too small. `TextMessageView`
  renders the message via `Text.rich`, splitting emoji vs non-emoji runs
  (`src/utils/emoji_text.dart`, tested); emoji-run spans carry only a `fontSize`
  override so colour is preserved, and ZWJ/variation-selector sequences are never
  split. Opt-in: `emojiSize == null` keeps a single unstyled span (unchanged).
  `src/widgets/reply_message_widget.dart`, `text_message_view.dart`,
  `src/models/chat_bubble.dart`, `src/utils/emoji_text.dart`.

- **AppBar title/avatar tap** — tag `chattr-3.1.0-p14`. New
  `ChatViewAppBar.onTitleTap` (`VoidCallback?`): the profile-picture + title
  area is wrapped in a `GestureDetector` so the host can open a profile/contact
  sheet from the header. Opt-in — `null` keeps the area non-interactive
  (`HitTestBehavior.deferToChild`), so default behaviour is unchanged.
  `src/widgets/chat_view_appbar.dart`.

- **Configurable bubble radius (grouping preserved) + reaction self-slot** —
  tag `chattr-3.1.0-p15`. Two independent fixes:
  1. `ChatBubble.shortMessageBorderRadius` / `longMessageBorderRadius`
     (`double?`): override the package's hardcoded base corner radii
     (`replyBorderRadius1` = 30 for short, `replyBorderRadius2` = 18 for long,
     the former reads as a near-circular pill on one-word messages) while
     message-grouping corner chaining is STILL applied — so a host can dial
     roundness down without losing the grouped-conversation look. Null → the
     package defaults (unchanged). A flat `borderRadius` still wins verbatim
     (no grouping). `src/models/chat_bubble.dart`,
     `src/widgets/text_message_view.dart`.
  2. Reaction pill: a reactor not in the chat's user list (`getUserFromId` →
     null — e.g. a user who left) no longer renders an empty default-avatar
     circle, which left a dead ~20px slot to the right of the emoji. Now renders
     nothing for a null user. `src/extensions/extensions.dart`.

- **Reaction pill: initials for a picture-less reactor** — tag
  `chattr-3.1.0-p16`. Refines p15(2): `getUserProfilePicture` now passes
  `userName` to `ProfileImageWidget`, so a reactor WITH a user record but NO
  profile photo (incl. your own reaction) renders a filled initials circle (the
  p12 fallback) instead of the empty default-avatar that still left a dead slot
  to the right of the emoji. Truly-unknown reactors (null user) still render
  nothing. `src/extensions/extensions.dart`.

- **Starred/favorited message badge** — tag `chattr-3.1.0-p17`.
  `MessageConfiguration.isMessageStarred` (a `bool Function(Message)?` predicate)
  plus an optional `starredIndicator` widget. When the predicate returns true,
  `MessageView` overlays a small star badge on the bubble's inner-top corner —
  wrapping the whole content so it works for EVERY message type (text/image/
  voice/custom). The default badge is a frosted-glass chip (backdrop blur +
  theme-primary border + theme-primary star), fully theme-aware. The app owns
  the meaning of "starred"; the package only renders the badge.
  `src/models/config_models/message_configuration.dart`,
  `src/widgets/message_view.dart`.

- **Jump-to-message + animated pulse highlight** — tag `chattr-3.1.0-p18`.
  A new `ChatView.highlightMessageNotifier` (a `ValueNotifier<String?>`) lets the
  host request a programmatic jump to any message by id (from a favorites list,
  global search, etc.), reusing the existing reply-scroll + highlight machinery.
  `ChatGroupedListWidget` listens and calls the reply-tap scroll path; the guard
  is relaxed so far-away/older messages page in via `loadOldReplyMessage` instead
  of being skipped. The highlight itself now pulses (3× blink) and fades smoothly
  via `AnimatedContainer` (300ms) instead of a hard on/off, with `highlightScale`
  left at 1.0 so it reads as a colour pulse, not a stretch.
  `src/widgets/chat_view.dart`, `src/widgets/chat_view_inherited_widget.dart`,
  `src/widgets/chat_groupedlist_widget.dart`, `src/widgets/text_message_view.dart`.

- **Robust jump-to-message + uniform highlight glow** — tag `chattr-3.1.0-p19`.
  Hardens p18 after device testing:
  1. **No crash**: guard `scrollController.position` behind `hasClients` — a jump
     firing before the list attaches threw "Bad state: No element".
  2. **No freeze**: the old fixed linear-position estimate never lined up with
     variable-height content (media albums) and looped forever. Replaced with a
     bounded, direction-flipping viewport scan that sweeps toward the target and
     gives up gracefully at the edges.
  3. **Single scan**: a `_scanGeneration` token ensures only the latest jump
     scans — concurrent scans (host + subscribe-time trigger) fought over the
     scroll controller and oscillated without progress.
  4. **Uniform glow**: the per-type highlight (text bg tint / image scale /
     custom) is replaced by ONE animated bloom (`boxShadow`) around the bubble in
     `MessageView`, so every message type — including opaque media — pulses
     identically with no shape/border mismatch.
  `src/widgets/chat_groupedlist_widget.dart`, `src/widgets/chat_list_widget.dart`,
  `src/widgets/message_view.dart`.

- **In-flow composer banners + injectable avatar colour** — tag `chattr-3.1.0-p20`.
  1. **Composer overflow fix**: `SendMessageWidget`'s inner `Stack(bottomCenter)`
     becomes a `Column(mainAxisSize: min)` — `ReplyMessageView`, `EditMessageView`
     and `SelectedImageViewWidget` sit in flow ABOVE `ChatUITextField`. Previously
     the text field painted last over a fixed reserved strip (reply: margin 17 +
     padding 30; edit: padding 48), so a multi-line draft covered the banner.
     The banners drop those reservations and render as self-contained rounded
     cards (radius 14, bottom margin 4).
     `src/widgets/send_message_widget.dart`, `src/widgets/reply_message_view.dart`,
     `src/widgets/edit_message_view.dart`.
  2. **Injectable avatar colour**: static
     `ProfileImageWidget.fallbackColorResolver` (`Color? Function(String? userId,
     String? userName)?`) plus per-instance `fallbackBackgroundColor` and `userId`
     params. Priority: explicit colour > resolver > legacy name-hash. The initials
     text auto-contrasts via `computeLuminance()`. `userId` is threaded from every
     site that knows it (`ProfileCircle` → message circles, reaction-pill
     `getUserProfilePicture`, reactions bottom sheet); the bottom sheet also gains
     `userName`, so a picture-less reactor now renders the p12 initials circle
     instead of a blank slot. `ProfileImageWidget` is exported from
     `package:chatview/chatview.dart` so the host can set the resolver.
     `src/widgets/profile_image_widget.dart`, `src/widgets/profile_circle.dart`,
     `src/widgets/chat_bubble_widget.dart`, `src/widgets/reactions_bottomsheet.dart`,
     `src/extensions/extensions.dart`, `lib/chatview.dart`.

- **WCAG-correct initials contrast + injectable foreground** — tag
  `chattr-3.1.0-p21`. `_fallbackAvatar` picked the letter colour with a plain
  `computeLuminance() > 0.5`, but the black/white crossover sits at relative
  luminance **≈0.179**: on mid-luminance hues (yellow/green/amber) that rule
  chose white at as little as **1.9:1**, below even the 3:1 AA-large floor. The
  new `_foregroundOn()` compares both contrast ratios and picks the winner.
  Additionally a static `ProfileImageWidget.fallbackForegroundResolver`
  (`Color? Function(Color background)?`) lets the host app supply its own rule,
  so an app that already contrast-picks for its own avatars (chattr does) keeps
  ONE implementation across in-package and app-side circles instead of two that
  silently diverge. `src/widgets/profile_image_widget.dart`.

- **Optional reaction-pill avatars** — tag `chattr-3.1.0-p22`.
  `MessageReactionConfiguration.showReactedUserAvatars` (default `true`, i.e.
  upstream behaviour). The pill unconditionally listed a profile circle per
  reacting user, which is informative in a group but pure noise in a 1:1
  conversation: with exactly two possible reactors the pill's side already says
  who reacted, yet every single 👍 grew a circle beside it. With the flag off
  the pill renders a bare count instead, and only once more than one person has
  reacted — a lone reaction stays just the emoji. The avatar branch is
  otherwise untouched, so groups keep the p16 initials circles.
  `src/models/config_models/message_reaction_configuration.dart`,
  `src/widgets/reaction_widget.dart`.

- **Centred system-message notices** — tag `chattr-3.1.0-p23`.
  `ChatBubbleConfiguration.isCenteredMessage` (`bool Function(Message)?`). Apps
  model system messages ("X joined", a key-rotation warning) as a message from a
  reserved sender id, and the package then lays that out like any other incoming
  bubble. Three things go wrong. It is indented by the avatar slot, so a notice
  meant to be centred sits off-centre — and by a *varying* amount, because the
  slot is a full-width spacer mid-group but collapses to the avatar's own
  padding on the last message of a group, so consecutive notices don't even line
  up with each other. It is wrapped in `SwipeToReply`, so a notice can be swiped
  into a reply quote; an app that (rightly) refuses to send a reply to a system
  message then looks broken, because the send just does nothing. And it carries
  a sender name, a reply quote and an edited marker that a notice never has.
  Returning `true` lays the bubble out full-width and centred with none of that,
  and without the receipt. Long-press, the p18 jump-to-message highlight and the
  reaction overlay are deliberately untouched — the host app already gates those
  per message. Default `null` = upstream behaviour.
  `src/models/config_models/chat_bubble_configuration.dart`,
  `src/widgets/chat_bubble_widget.dart`.

- **App-owned reaction sheet** — tag `chattr-3.1.0-p24`.
  `MessageReactionConfiguration.onReactionPillTap`
  (`void Function(String messageId)?`) plus an optional
  `ReactionWidget.messageId`. Tapping the reaction pill was hardwired to the
  package's own `ReactionsBottomSheet`, and that sheet is a dead end for
  anything beyond looking: it builds from an immutable `Reaction`, so a row
  removed while it is open stays on screen, and its only hook —
  `reactedUserCallback` — fires per row **without a message id**. An app that
  wants to let someone take their own reaction back would have to search its
  message list for a message carrying that (user, emoji) pair, which is
  ambiguous the moment the same 👍 was used twice. With the callback set the
  package hands the tap over, id included, and the app renders its own sheet
  against live state; left null (the default) nothing changes. Also threads
  `messageId` through the five `ReactionWidget` call sites.
  `src/values/typedefs.dart`,
  `src/models/config_models/message_reaction_configuration.dart`,
  `src/widgets/reaction_widget.dart`, `src/widgets/text_message_view.dart`,
  `src/widgets/image_message_view.dart`, `src/widgets/voice_message_view.dart`,
  `src/widgets/message_view.dart`.

- **Stable avatar cache key** — tag `chattr-3.1.0-p25`. Static
  `ProfileImageWidget.cacheKeyResolver` (`String? Function(String url)?`), in
  the same shape as the p20/p21 resolvers. `CachedNetworkImage` keys its disk
  cache on the URL, which is correct only while avatar URLs are stable. Serve
  them from a private bucket via **signed** URLs and every refreshed signature
  reads as a new image: the same picture is downloaded again and its cache
  files accumulate without bound. The resolver returns a stable identity for a
  URL (the storage object path, say); null keeps keying on the URL, so the
  default is unchanged. `src/widgets/profile_image_widget.dart`.

- **Dimmable jump-to-message glow** — tag `chattr-3.1.0-p26`.
  `RepliedMsgAutoScrollConfig.highlightGlowSpread` (default **2**) and
  `highlightGlowBlur` (default 28), threaded through `ChatBubbleWidget` into
  `MessageView`. The p18/p19 pulse drew two stacked `BoxShadow`s at
  `spreadRadius` 4 and 8, hardcoded. `spreadRadius` inflates the shadow
  rectangle *before* it is blurred, so it does not soften into the blur — it
  adds to it. At 8 plus a 28px blur the glow reached roughly 20px past the
  bubble, further than the gap between two bubbles, so the pulse lit up the
  neighbours as well: it read as "somewhere around here" instead of "this one",
  which defeats the point of a jump target. Blur is what makes it a glow rather
  than a border, so only the spread came down; both radii are now the host
  app's to set, which also means the next adjustment is one app-side line
  rather than another tag. `src/models/config_models/replied_msg_auto_scroll_config.dart`,
  `src/widgets/message_view.dart`, `src/widgets/chat_bubble_widget.dart`.

Manual patches are tagged `chattr-3.1.0-pN`; the weekly auto-sync re-tags as
`chattr-<upstream-version>` after rebasing these patches onto a new upstream
release. See the `chattr` branch history for the exact diffs.
