import 'package:flutter/painting.dart';

/// chattr fork p13: split a message string into inline spans where EMOJI runs
/// are rendered at [emojiSize] instead of the surrounding text size — inline
/// emojis at the body size read as too small. Opt-in via
/// `ChatBubble.emojiSize`; when [emojiSize] is null the string is returned as a
/// single unstyled span (default, no behaviour change).
///
/// Emoji-run spans carry only a `fontSize` override, so they MERGE onto the
/// inherited text style (colour etc. preserved). Non-emoji runs get a null style
/// and inherit the ambient message style. ZWJ / variation selectors stay inside
/// the current run so a joined emoji (👨‍👩‍👧, ❤️) is never split.
List<InlineSpan> emojiUpscaledSpans(String text, {double? emojiSize}) {
  if (emojiSize == null) {
    return text.isEmpty ? const [] : [TextSpan(text: text)];
  }
  final spans = <InlineSpan>[];
  final buf = <int>[];
  bool? bufIsEmoji;

  void flush() {
    if (buf.isEmpty) return;
    spans.add(
      TextSpan(
        text: String.fromCharCodes(buf),
        style: (bufIsEmoji ?? false) ? TextStyle(fontSize: emojiSize) : null,
      ),
    );
    buf.clear();
  }

  for (final r in text.runes) {
    // ZWJ (0x200D) / variation selectors (0xFE0E/0xFE0F) join the current run.
    if (r == 0x200D || r == 0xFE0F || r == 0xFE0E) {
      bufIsEmoji ??= true;
      buf.add(r);
      continue;
    }
    final isEmoji = isEmojiRune(r);
    if (bufIsEmoji == null) {
      bufIsEmoji = isEmoji;
    } else if (bufIsEmoji != isEmoji) {
      flush();
      bufIsEmoji = isEmoji;
    }
    buf.add(r);
  }
  flush();
  return spans;
}

/// Whether a code point is (part of) an emoji we want to upscale. Deliberately
/// broad-but-safe: the emoji planes + misc-symbols/dingbats + stars/arrows,
/// which cover the everyday set (😂 👍 🎉 🔥 ❤ ✅ ➡ ⭐ …) without swallowing
/// ordinary punctuation/letters.
bool isEmojiRune(int r) =>
    r >= 0x1F000 || // emoji planes (faces, symbols, flags, supplemental …)
    (r >= 0x2600 && r <= 0x27BF) || // misc symbols + dingbats (❤ ✅ ✨ ➡ ☀ …)
    (r >= 0x2B00 && r <= 0x2BFF); // stars/arrows (⭐ ⬆ …)
