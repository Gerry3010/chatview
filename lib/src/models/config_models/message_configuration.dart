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

import '../../values/typedefs.dart';
import '../models.dart';

class MessageConfiguration {
  const MessageConfiguration({
    this.showReactionsOnCustomMessages = true,
    this.imageMessageConfig,
    this.messageReactionConfig,
    this.emojiMessageConfig,
    this.customMessageBuilder,
    this.voiceMessageConfig,
    this.customMessageReplyViewBuilder,
    this.isMessageStarred,
    this.starredIndicator,
  });

  /// Provides configuration of image message appearance.
  final ImageMessageConfiguration? imageMessageConfig;

  /// Provides configuration of image message appearance.
  final MessageReactionConfiguration? messageReactionConfig;

  /// Provides configuration of emoji messages appearance.
  final EmojiMessageConfiguration? emojiMessageConfig;

  /// Provides builder to create view for custom messages.
  final CustomMessageBuilder? customMessageBuilder;

  /// Configurations for voice message bubble
  final VoiceMessageConfiguration? voiceMessageConfig;

  /// To customize reply view for custom message type
  final CustomMessageReplyViewBuilder? customMessageReplyViewBuilder;

  /// To show or hide reactions on custom message types
  ///
  /// Default is `true`.
  final bool showReactionsOnCustomMessages;

  /// Predicate deciding whether a given message is "starred"/favorited. When it
  /// returns true, a small star badge is overlaid on the message bubble's top
  /// outer corner (works across ALL message types — text/image/voice/custom).
  /// The app owns the meaning of "starred"; the package only renders the badge.
  final bool Function(Message message)? isMessageStarred;

  /// Optional custom widget for the starred badge. Defaults to a small amber
  /// star with a subtle contrasting background.
  final Widget? starredIndicator;
}
