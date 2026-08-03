/*
 * Copyright (c) 2022 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'package:chatview_utils/chatview_utils.dart';
import 'package:flutter/material.dart';

import '../models.dart';

class ChatBubbleConfiguration {
  const ChatBubbleConfiguration({
    this.padding,
    this.margin,
    this.maxWidth,
    this.longPressAnimationDuration,
    this.inComingChatBubbleConfig,
    this.outgoingChatBubbleConfig,
    this.onDoubleTap,
    this.onLongPress,
    this.onSwipeToTimestamp,
    this.timestampRevealBuilder,
    this.isCenteredMessage,
    this.disableLinkPreview = false,
  });

  /// Used for giving padding of chat bubble.
  final EdgeInsetsGeometry? padding;

  /// Used for giving margin of chat bubble.
  final EdgeInsetsGeometry? margin;

  /// Used for giving maximum width of chat bubble.
  final double? maxWidth;

  /// Provides callback when user long press on chat bubble.
  final Duration? longPressAnimationDuration;

  /// Provides configuration of other users message's chat bubble.
  final ChatBubble? inComingChatBubbleConfig;

  /// Provides configuration of current user message's chat bubble.
  final ChatBubble? outgoingChatBubbleConfig;

  /// Provides callback when user tap twice on chat bubble.
  final ValueSetter<Message>? onDoubleTap;

  /// Provides callback when the user long-presses a chat bubble, giving the
  /// [Message] directly. When set, long-press is enabled and this fires instead
  /// of the built-in reaction popup / reply snackbar — a host app can open its
  /// own message-actions UI without hijacking `replyPopupBuilder`.
  final ValueSetter<Message>? onLongPress;

  /// (chattr fork, p8) Fired with the [Message] when the user swipes a bubble
  /// in the OPPOSITE direction from reply past the reveal threshold — used to
  /// open a detailed per-recipient timestamp sheet (e.g. for group chats).
  final ValueSetter<Message>? onSwipeToTimestamp;

  /// (chattr fork, p8) Builds the compact widget revealed while opposite-swiping
  /// a bubble (WhatsApp-style "peek the delivered/read time"). Receives the
  /// [Message]; return `null`/omit to disable the peek for a bubble.
  final Widget? Function(Message message)? timestampRevealBuilder;

  /// (chattr fork, p23) Marks a message as a **centred notice** rather than a
  /// bubble sent by a participant — a system message such as "X joined" or a
  /// key-rotation warning.
  ///
  /// Apps model these as a message from a reserved sender id, which the package
  /// then lays out like any incoming bubble: indented by the avatar slot (so the
  /// notice reads off-centre, and by a *varying* amount, because the slot
  /// collapses on the last message of a group), wrapped in the swipe-to-reply
  /// detector (so a notice can be swiped into a reply that no app can send) and
  /// carrying a sender name, a reply quote and an edited marker that a notice
  /// never has.
  ///
  /// Return `true` and the bubble is laid out full-width and centred, with no
  /// avatar slot, no receipt, no swipe gestures and none of those affordances.
  /// Long-press, the jump-to-message highlight and the reaction overlay are
  /// untouched — the host app already gates those per message where it wants to.
  final bool Function(Message message)? isCenteredMessage;

  /// A flag to disable link preview functionality.
  ///
  /// When `true`, link previews will be disabled, rendering links as plain text
  /// or standard hyperlinks without additional preview metadata.
  /// When `false`, link previews will be enabled by default (current behavior).
  ///
  /// Default value: `false`.
  final bool disableLinkPreview;
}
