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

import '../extensions/extensions.dart';
import '../models/config_models/message_reaction_configuration.dart';
import '../utils/measure_size.dart';
import 'reactions_bottomsheet.dart';

class ReactionWidget extends StatefulWidget {
  const ReactionWidget({
    super.key,
    required this.reaction,
    this.messageReactionConfig,
    required this.isMessageBySender,
    this.messageId,
  });

  /// Provides reaction instance of message.
  final Reaction reaction;

  /// chattr p24: id of the message this pill belongs to, handed to
  /// [MessageReactionConfiguration.onReactionPillTap]. Null keeps the
  /// package's own bottom sheet.
  final String? messageId;

  /// Provides configuration of reaction appearance in chat bubble.
  final MessageReactionConfiguration? messageReactionConfig;

  /// Represents current message is sent by current user.
  final bool isMessageBySender;

  @override
  State<ReactionWidget> createState() => _ReactionWidgetState();
}

class _ReactionWidgetState extends State<ReactionWidget> {
  bool needToExtend = false;

  MessageReactionConfiguration? get messageReactionConfig =>
      widget.messageReactionConfig;
  final _reactionTextStyle = const TextStyle(fontSize: 13);
  ChatController? chatController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (chatViewIW != null) {
      chatController = chatViewIW!.chatController;
    }
  }

  @override
  Widget build(BuildContext context) {
    //// Convert into set to remove reduntant values
    final reactionsSet = widget.reaction.reactions.toSet();
    return Positioned(
      bottom: 0,
      right: widget.isMessageBySender && needToExtend ? 0 : null,
      child: InkWell(
        onTap: () {
          // chattr p24: hand the tap to the app when it asked for it, so the
          // sheet can be one the app owns. Without a callback (or without a
          // message id) this is exactly the upstream behaviour.
          final onPillTap = messageReactionConfig?.onReactionPillTap;
          final messageId = widget.messageId;
          if (onPillTap != null && messageId != null) {
            onPillTap(messageId);
            return;
          }
          if (chatController == null) return;
          ReactionsBottomSheet().show(
            context: context,
            reaction: widget.reaction,
            chatController: chatController!,
            reactionsBottomSheetConfig:
                messageReactionConfig?.reactionsBottomSheetConfig,
          );
        },
        child: MeasureSize(
          onSizeChange: (extend) => setState(() => needToExtend = extend),
          child: Container(
            padding: messageReactionConfig?.padding ??
                const EdgeInsets.symmetric(vertical: 1.7, horizontal: 6),
            margin: messageReactionConfig?.margin ??
                EdgeInsets.only(
                  left: widget.isMessageBySender ? 10 : 16,
                  right: 10,
                ),
            decoration: BoxDecoration(
              color: messageReactionConfig?.backgroundColor ??
                  Colors.grey.shade200,
              borderRadius: messageReactionConfig?.borderRadius ??
                  BorderRadius.circular(16),
              border: Border.all(
                color: messageReactionConfig?.borderColor ?? Colors.white,
                width: messageReactionConfig?.borderWidth ?? 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  reactionsSet.join(' '),
                  style: TextStyle(
                    fontSize: messageReactionConfig?.reactionSize ?? 13,
                  ),
                ),
                // Avatars suppressed (a 1:1 chat, where the circles say
                // nothing the emoji doesn't): show a bare count, and only
                // once more than one person has reacted.
                if (!(messageReactionConfig?.showReactedUserAvatars ?? true)) ...[
                  if (widget.reaction.reactedUserIds.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        widget.reaction.reactedUserIds.length.toString(),
                        style: messageReactionConfig?.reactionCountTextStyle ??
                            _reactionTextStyle,
                      ),
                    ),
                ] else if (chatController?.otherUsers.isNotEmpty ?? false) ...[
                  if (!(widget.reaction.reactedUserIds.length > 3) &&
                      !(reactionsSet.length > 1))
                    ...List.generate(
                      widget.reaction.reactedUserIds.length,
                      (reactedUserIndex) => widget
                          .reaction.reactedUserIds[reactedUserIndex]
                          .getUserProfilePicture(
                        getChatUser: (userId) =>
                            chatController?.getUserFromId(userId),
                        profileCirclePadding:
                            messageReactionConfig?.profileCirclePadding,
                        profileCircleRadius:
                            messageReactionConfig?.profileCircleRadius,
                      ),
                    ),
                  if (widget.reaction.reactedUserIds.length > 3 &&
                      !(reactionsSet.length > 1))
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        '+${widget.reaction.reactedUserIds.length}',
                        style:
                            messageReactionConfig?.reactedUserCountTextStyle ??
                                _reactionTextStyle,
                      ),
                    ),
                  if (reactionsSet.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        widget.reaction.reactedUserIds.length.toString(),
                        style: messageReactionConfig?.reactionCountTextStyle ??
                            _reactionTextStyle,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
