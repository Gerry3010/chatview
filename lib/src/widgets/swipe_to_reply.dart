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
import 'package:flutter/material.dart';

import '../extensions/extensions.dart';
import 'reply_icon.dart';

class SwipeToReply extends StatefulWidget {
  const SwipeToReply({
    super.key,
    required this.onSwipe,
    required this.child,
    this.isMessageByCurrentUser = true,
    this.timestampRevealBuilder,
    this.onSwipeToTimestamp,
  });

  /// Provides callback when user swipes chat bubble from left side.
  final VoidCallback onSwipe;

  /// Allow user to set widget which is showed while user swipes chat bubble.
  final Widget child;

  /// A boolean variable that indicates if the message is sent by the current user.
  ///
  /// This is `true` if the message is authored by the sender (the current user),
  /// and `false` if it is authored by someone else.
  final bool isMessageByCurrentUser;

  /// (chattr fork, p8) Builds the widget revealed in the gutter when the user
  /// swipes the bubble in the OPPOSITE direction from the reply gesture
  /// (WhatsApp-style "peek the timestamp"). The bubble slides aside and
  /// progressively uncovers it; releasing snaps it back. Invoked **lazily** —
  /// only once a reveal drag begins — so the (possibly expensive) build isn't
  /// paid for every bubble on every frame. `null` ⇒ opposite swipes are a
  /// no-op and the reply gesture is unaffected.
  final ValueGetter<Widget?>? timestampRevealBuilder;

  /// (chattr fork, p8) Fired once when an opposite-direction swipe passes the
  /// reveal threshold — used to open a detailed per-recipient timestamp sheet
  /// (e.g. for group chats). Optional; the peek works without it.
  final VoidCallback? onSwipeToTimestamp;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> {
  double paddingValue = 0;
  double revealValue = 0;
  double trackPaddingValue = 0;
  double initialTouchPoint = 0;
  bool isCallBackTriggered = false;
  bool isRevealTriggered = false;

  // Lazily-built reveal content, cached for the duration of one reveal drag.
  Widget? _revealWidget;

  late bool isMessageByCurrentUser = widget.isMessageByCurrentUser;

  final paddingLimit = 50;

  // The reveal side needs a little more travel than the reply icon so a
  // compact "delivered/read HH:MM" strip becomes fully visible before the
  // threshold callback fires.
  final revealLimit = 96;
  final double replyIconSize = 25;

  bool get _revealEnabled =>
      widget.timestampRevealBuilder != null ||
      widget.onSwipeToTimestamp != null;

  @override
  Widget build(BuildContext context) {
    final replyEnabled =
        chatViewIW?.featureActiveConfig.enableSwipeToReply ?? true;
    if (!replyEnabled && !_revealEnabled) return widget.child;

    return GestureDetector(
      onHorizontalDragStart: (details) =>
          initialTouchPoint = details.globalPosition.dx,
      onHorizontalDragEnd: (details) => setState(
        () {
          paddingValue = 0;
          revealValue = 0;
          isCallBackTriggered = false;
          isRevealTriggered = false;
          _revealWidget = null;
        },
      ),
      onHorizontalDragUpdate: (details) =>
          _onHorizontalDragUpdate(details, replyEnabled),
      child: Stack(
        alignment: isMessageByCurrentUser
            ? Alignment.centerRight
            : Alignment.centerLeft,
        fit: StackFit.passthrough,
        children: [
          // Reply icon, on the reply-gesture side.
          ReplyIcon(
            replyIconSize: replyIconSize,
            animationValue: paddingValue > replyIconSize
                ? (paddingValue) / (paddingLimit)
                : 0.0,
          ),
          // Timestamp reveal, on the OPPOSITE side. Painted before the bubble
          // so the bubble covers it until slid aside (progressive reveal).
          if (_revealWidget != null && revealValue > 0)
            Align(
              alignment: isMessageByCurrentUser
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Opacity(
                opacity: (revealValue / revealLimit).clamp(0.0, 1.0),
                child: _revealWidget,
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
              right: isMessageByCurrentUser ? paddingValue : revealValue,
              left: isMessageByCurrentUser ? revealValue : paddingValue,
            ),
            child: widget.child,
          ),
        ],
      ),
    );
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, bool replyEnabled) {
    // Positive = reply direction; negative = timestamp-reveal direction.
    final signedDistance = isMessageByCurrentUser
        ? (initialTouchPoint - details.globalPosition.dx)
        : (details.globalPosition.dx - initialTouchPoint);

    if (signedDistance >= 0) {
      // ── Reply gesture (unchanged behaviour) ──────────────────────────
      if (replyEnabled) {
        if (revealValue != 0) revealValue = 0;
        if (trackPaddingValue < paddingLimit) {
          setState(() {
            paddingValue = signedDistance;
          });
        } else if (paddingValue >= paddingLimit) {
          if (!isCallBackTriggered) {
            widget.onSwipe();
            isCallBackTriggered = true;
          }
        } else {
          setState(() {
            paddingValue = 0;
          });
        }
      }
    } else if (_revealEnabled) {
      // ── Timestamp reveal (opposite direction) ────────────────────────
      final revealDistance = -signedDistance;
      if (paddingValue != 0) paddingValue = 0;
      // Build the reveal content once, on the first reveal frame.
      _revealWidget ??= widget.timestampRevealBuilder?.call();
      if (trackPaddingValue > -revealLimit) {
        setState(() {
          revealValue = revealDistance;
        });
      } else if (revealValue >= revealLimit) {
        if (!isRevealTriggered) {
          widget.onSwipeToTimestamp?.call();
          isRevealTriggered = true;
        }
      } else {
        setState(() {
          revealValue = 0;
        });
      }
    }
    trackPaddingValue = signedDistance;
  }
}
