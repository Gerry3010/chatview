> ⚠️ **AI-agent-maintained fork for the Chattr app.** Auto-synced with upstream
> weekly and kept current on a best-effort basis by an AI agent; patches applied at
> the agent's best judgement, **no warranty**. Upstream (file issues/PRs there):
> https://github.com/SimformSolutionsPvtLtd/chatview — see [FORK_NOTICE.md](FORK_NOTICE.md).

## Chattr fork changes (on top of upstream `3.1.0`)

| Patch | Tag | What |
|-------|-----|------|
| 24-hour local time | `chattr-3.1.0-p1` | Bubble times / date separators render 24-hour in the device's local timezone (upstream: `hh:mm a` on raw UTC). |
| `sendOnEnter` | `chattr-3.1.0-p3` | `SendMessageConfiguration.sendOnEnter` — Enter sends, Shift+Enter newlines; platform default (web + desktop on, mobile off); focus-guarded. |
| `onPaste` | `chattr-3.1.0-p4` | `SendMessageConfiguration.onPaste` + `enableClipboardPaste` — Ctrl/Cmd+V hands the controller to a host paste callback (image/file paste) without consuming native text paste. |
| composer barrel | `chattr-3.1.0-p5` | Public `package:chatview/composer.dart` exposing the custom-composer surface, so apps stop importing `package:chatview/src/...` (rebase-safe). |
| keyboard dismiss | `chattr-3.1.0-p6` | `ChatBackgroundConfiguration.scrollViewKeyboardDismissBehavior` exposes the message list's `keyboardDismissBehavior` (e.g. `onDrag`). |
| clean long-press | `chattr-3.1.0-p7` | `ChatBubbleConfiguration.onLongPress(Message)` delivers the message directly, so apps open their own actions UI without hijacking `replyPopupBuilder`. |
| slide-to-timestamp | `chattr-3.1.0-p8` | `ChatBubbleConfiguration.timestampRevealBuilder` + `onSwipeToTimestamp` — an opposite-direction swipe peeks a host-built timestamp chip (built lazily) and a hard swipe opens a per-recipient sheet; reply gesture untouched. |
| composer context menu | `chattr-3.1.0-p9` | `SendMessageConfiguration.composerContextMenuBuilder` threads a custom `contextMenuBuilder` into the composer TextField (host adds e.g. an iOS "Paste image" entry); platform default kept when unset. |
| reply-author + empty-msg fixes | `chattr-3.1.0-p10` | Reply-quote header names the quoted message's author (`replyTo`), not the replier (`replyBy`); and `''.isAllEmoji` is now false so empty custom messages reach `customMessageBuilder` instead of rendering as a blank emoji bubble. |
| stable default sort | `chattr-3.1.0-p11` | When `sortEnable` is on with no custom `messageSorter`, the fallback comparator breaks `createdAt` ties by message `id` — a strict total order (deterministic across rebuilds/devices, safe as a keyset-pagination boundary). |
| initials avatar fallback | `chattr-3.1.0-p12` | `userName` on `ProfileImageWidget`/`ProfileCircle`/`ChatViewAppBar` renders a deterministic initials circle when no image resolves, instead of a 0px collapse — lets a host show other-user avatars everywhere without picture-less users breaking the layout. |
| reply cap + inline emoji size | `chattr-3.1.0-p13` | Sent-bubble reply quote is capped at `maxLines: 2`+ellipsis (a long text/filename can't grow a many-line quote); and `ChatBubble.emojiSize` renders inline EMOJI runs of a message larger than the body text (opt-in, null = unchanged). |
| appbar title/avatar tap | `chattr-3.1.0-p14` | `ChatViewAppBar.onTitleTap` (`VoidCallback?`) wraps the profile-picture + title area in a `GestureDetector` so the host can open a profile/contact sheet from the header. Opt-in — null keeps the area non-interactive. |
| bubble radius + reaction slot | `chattr-3.1.0-p15` | `ChatBubble.shortMessageBorderRadius`/`longMessageBorderRadius` (`double?`) override the hardcoded base corner radii (30 short / 18 long) while message-grouping corner chaining STILL applies — dial roundness down without losing the grouped look (null = package defaults; a flat `borderRadius` still wins verbatim). Plus: a reactor absent from the user list no longer renders an empty avatar circle (dead ~20px slot beside the emoji). |
| reaction pill initials | `chattr-3.1.0-p16` | Refines p15: `getUserProfilePicture` passes `userName` to `ProfileImageWidget`, so a reactor WITH a record but NO photo (incl. your own reaction) renders a filled initials circle (the p12 fallback) instead of the empty default-avatar slot. Truly-unknown (null) reactors still render nothing. |
| starred message badge | `chattr-3.1.0-p17` | `MessageConfiguration.isMessageStarred` (`bool Function(Message)?`) + optional `starredIndicator`; when true, `MessageView` overlays a small star badge (default: frosted-glass, theme-aware) on the bubble — wrapping the whole content so it works for EVERY message type. The host owns the meaning of "starred". |
| jump-to-message + pulse | `chattr-3.1.0-p18` | `ChatView.highlightMessageNotifier` (`ValueNotifier<String?>`) jumps to any message by id (favorites, global search, …), reusing the reply-scroll + highlight machinery; the guard is relaxed so far/older messages page in via `loadOldReplyMessage`. The highlight pulses (3× blink) and fades via `AnimatedContainer` (`highlightScale` 1.0 = colour pulse, not a stretch). |
| robust jump + uniform glow | `chattr-3.1.0-p19` | Hardens p18 after device testing: `hasClients` guard (no "Bad state: No element" crash), a bounded direction-flipping viewport scan (no infinite loop on variable-height content like media albums), a `_scanGeneration` token (only the latest jump scans — no host/subscribe oscillation), and ONE animated `boxShadow` bloom around the bubble in `MessageView` so every type — incl. opaque media — pulses uniformly. |
| in-flow composer banners + injectable avatar colour | `chattr-3.1.0-p20` | (a) `SendMessageWidget` lays the reply/edit/selected-image banners out in a `Column` ABOVE the text field instead of a `Stack` behind it — a growing multi-line draft can no longer paint over the "Reply to" banner; the banners drop their fixed bottom reservations and become self-contained rounded cards. (b) `ProfileImageWidget.fallbackColorResolver` (static) + `fallbackBackgroundColor`/`userId` params let the host app inject ONE deterministic identity colour for every initials-circle fallback (message circles, reaction pills, reaction sheet, app bar); text colour auto-contrasts by luminance. The reactions bottom sheet now passes `userName`/`userId`, so picture-less reactors get the p12 initials circle there too. `ProfileImageWidget` is exported from `package:chatview/chatview.dart`. |

Full detail (files + rationale) in [FORK_NOTICE.md](FORK_NOTICE.md). The sibling
[`chatview_utils` fork](https://github.com/Gerry3010/chatview_utils) carries the
`getUserFromId` null-guard and the `updateMessage`/`removeMessage` patches.

![Banner](https://raw.githubusercontent.com/SimformSolutionsPvtLtd/chatview/main/preview/banner.png)

# ChatView

[![Build](https://github.com/SimformSolutionsPvtLtd/chatview/actions/workflows/flutter.yaml/badge.svg?branch=main)](https://github.com/SimformSolutionsPvtLtd/chatview/actions) 
[![chatview](https://img.shields.io/pub/v/chatview?label=chatview)](https://pub.dev/packages/chatview)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/SimformSolutionsPvtLtd/chatview/blob/main/LICENSE)

ChatView is a Flutter package that allows you to integrate a highly customizable chat UI in your
Flutter applications with [Flexible Backend Integration][chatViewConnect].

| ChatList                                                                                                         | ChatView                                                                                                         |
|------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------|
| ![ChatList_Preview](https://raw.githubusercontent.com/SimformSolutionsPvtLtd/chatview/main/preview/chatlist.gif) | ![ChatView Preview](https://raw.githubusercontent.com/SimformSolutionsPvtLtd/chatview/main/preview/chatview.gif) |

## Features

### ChatList:

- Smooth animations for adding, removing, and pinning chats
- Pagination support for large chat histories
- Search functionality by name or other criteria
- Long press menu with options like pin and mute
- User online status indicators
- Typing indicators for active users
- Unread message count badges
- Header and Footer support for additional widgets
- Highly customizable UI components
- Plug-and-play backend support using [chatview_connect][chatViewConnect]

### ChatView:

- One-on-one and group chat support
- Message reactions with emoji
- Reply to messages functionality
- Link preview for URLs
- Voice messages support
- Image sharing capabilities
- Custom message types
- Typing indicators
- Reply suggestions
- Edit Message
- Message status indicators (sent, delivered, read)
- Highly customizable UI components
- Plug-and-play backend support using [chatview_connect][chatViewConnect]

For a live web demo, visit [Chat View Example](https://simformsolutionspvtltd.github.io/chatview/).

## Documentation

Visit our [documentation](https://simform-flutter-packages.web.app/chatView) site for all
implementation details, usage instructions, code examples, and advanced features.

## Installation

```yaml
dependencies:
  chatview: <latest-version>
```

## Compatibility with [`chatview_connect`][chatViewConnect]

| `chatview` version | [`chatview_connect`][chatViewConnect] version |
|--------------------|-----------------------------------------------|
| `>=2.4.1 <3.0.0`   | `0.0.1`                                       |
| `>= 3.0.0`         | `3.0.0`                                       |

## ChatView with Backend Support

Make `ChatView` backend-ready with [chatview_connect][chatViewConnect]

- 🔌 Easy backend integration without boilerplate (🔥 Firebase)
- ⚙️ Setup in 3 steps: set **Service Type** -> **User ID** and get **`ChatManager`**
- 💬 Supports **1-on-1** and **group chats** with **media uploads** *(audio not supported).*

## Support

For questions, issues, or feature
requests, [create an issue](https://github.com/SimformSolutionsPvtLtd/chatview/issues) on GitHub or
reach out via the GitHub Discussions tab. We're happy to help and encourage community contributions.
To contribute documentation updates specifically, please make changes to the doc/documentation.md
file and submit a pull request.

## License

This project is licensed under the MIT License - see
the [LICENSE](https://simform-flutter-packages.web.app/chatView/license).

[chatViewConnect]: https://pub.dev/packages/chatview_connect
