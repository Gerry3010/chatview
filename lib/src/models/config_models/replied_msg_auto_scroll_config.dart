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

class RepliedMsgAutoScrollConfig {
  /// Auto scrolls to original message when tapped on replied message.
  /// Defaults to true.
  final bool enableScrollToRepliedMsg;

  /// Highlights the text by changing background color of chat bubble for
  /// given duration. Default to true.
  final bool enableHighlightRepliedMsg;

  /// Chat bubble color when highlighted. Defaults to Colors.grey.
  final Color highlightColor;

  /// Chat will remain highlighted for this duration. Defaults to 500ms.
  final Duration highlightDuration;

  /// When replied message have image or only emojis. They will be scaled
  /// for provided [highlightDuration] to highlight them. Defaults to 1.1
  final double highlightScale;

  /// Animation curve for auto scroll. Defaults to Curves.easeIn.
  final Curve highlightScrollCurve;

  /// Alignment of the replied message when scrolled to.
  final double alignment;

  /// How far the jump-to-message glow reaches BEYOND the bubble, in logical
  /// pixels (the shadows' `spreadRadius`). Defaults to 2.
  ///
  /// This is the knob that decides whether the pulse points at ONE message or
  /// lights up the neighbourhood: `spreadRadius` inflates the shadow rectangle
  /// *before* it is blurred, so it adds to [highlightGlowBlur] rather than
  /// softening into it. The p18/p19 default of 8 reached further than the gap
  /// between two bubbles, which made the glow read as "somewhere around here"
  /// instead of "this one".
  final double highlightGlowSpread;

  /// How soft the jump-to-message glow is (the shadows' `blurRadius`).
  /// Defaults to 28.
  ///
  /// Blur is what makes it a glow rather than a border — reduce
  /// [highlightGlowSpread] to make it smaller, not this.
  final double highlightGlowBlur;

  /// Configuration for auto scrolling and highlighting a message when
  /// tapping on the original message above the replied message.
  const RepliedMsgAutoScrollConfig({
    this.enableHighlightRepliedMsg = true,
    this.enableScrollToRepliedMsg = true,
    this.highlightColor = Colors.grey,
    this.highlightDuration = const Duration(milliseconds: 500),
    this.highlightScale = 1.1,
    this.highlightScrollCurve = Curves.easeIn,
    this.alignment = 0.5,
    this.highlightGlowSpread = 2,
    this.highlightGlowBlur = 28,
  });
}
