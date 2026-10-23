import 'package:characters/characters.dart';
import 'package:flutter/painting.dart';

/// chattr fork p13: split a message string into inline spans where EMOJI runs
/// are rendered at [emojiSize] instead of the surrounding text size — inline
/// emojis at the body size read as too small. Opt-in via
/// `ChatBubble.emojiSize`; when [emojiSize] is null the string is returned as a
/// single unstyled span (default, no behaviour change).
///
/// Emoji-run spans carry only a `fontSize` override, so they MERGE onto the
/// inherited text style (colour etc. preserved). Non-emoji runs get a null style
/// and inherit the ambient message style.
///
/// chattr fork p27: the walk is over GRAPHEME CLUSTERS, not code points. A
/// joined emoji is one cluster, and a cluster must never land in two spans:
/// two spans are two shaping runs with two font sizes, so the font cannot form
/// the ligature and the parts render side by side. Per code point that happened
/// to every ZWJ sequence whose tail is a BMP symbol — 🙂‍↕️ (1F642 200D 2195
/// FE0F) broke at the ↕, which sits in the Arrows block outside every emoji
/// range, and showed as 🙂 + ↕️. Classification now asks the whole cluster, so
/// one emoji-looking rune anywhere in it carries the rest along.
///
/// chattr fork p29: [emojiStyle] carries a whole style instead of a size (see
/// `ChatBubble.emojiStyle`) and wins over [emojiSize]. Exported, so the host
/// app splits its composer and captions exactly the same way.
List<InlineSpan> emojiUpscaledSpans(
  String text, {
  double? emojiSize,
  TextStyle? emojiStyle,
}) {
  final style =
      emojiStyle ?? (emojiSize == null ? null : TextStyle(fontSize: emojiSize));
  if (style == null) {
    return text.isEmpty ? const [] : [TextSpan(text: text)];
  }
  final spans = <InlineSpan>[];
  final buf = StringBuffer();
  bool? bufIsEmoji;

  void flush() {
    if (buf.isEmpty) return;
    spans.add(
      TextSpan(
        text: buf.toString(),
        style: (bufIsEmoji ?? false) ? style : null,
      ),
    );
    buf.clear();
  }

  for (final cluster in text.characters) {
    final isEmoji = isEmojiCluster(cluster);
    if (bufIsEmoji == null) {
      bufIsEmoji = isEmoji;
    } else if (bufIsEmoji != isEmoji) {
      flush();
      bufIsEmoji = isEmoji;
    }
    buf.write(cluster);
  }
  flush();
  return spans;
}

/// Whether a grapheme cluster should be upscaled as an emoji.
///
/// The variation selectors decide first, because they are the author's explicit
/// statement about presentation: FE0E asks for the text look (❤︎ stays at body
/// size), FE0F for the emoji look. FE0F is also what makes the BMP symbols
/// readable as emoji at all — ↕️, ⏰, 1️⃣ carry no rune inside the emoji planes,
/// only a selector. Everything else falls back to the code-point ranges below.
bool isEmojiCluster(String cluster) {
  var sawEmojiRune = false;
  for (final r in cluster.runes) {
    if (r == 0xFE0E) return false;
    if (r == 0xFE0F) return true;
    if (isEmojiRune(r)) sawEmojiRune = true;
  }
  return sawEmojiRune;
}

/// Whether a code point is (part of) an emoji we want to upscale. Deliberately
/// broad-but-safe: the emoji planes + misc-symbols/dingbats + stars/arrows,
/// which cover the everyday set (😂 👍 🎉 🔥 ❤ ✅ ➡ ⭐ …) without swallowing
/// ordinary punctuation/letters. Bare BMP symbols outside these ranges (→, ™,
/// ↕ without a selector) stay text on purpose — they read as punctuation far
/// more often than as emoji.
bool isEmojiRune(int r) =>
    r >= 0x1F000 || // emoji planes (faces, symbols, flags, supplemental …)
    (r >= 0x2600 && r <= 0x27BF) || // misc symbols + dingbats (❤ ✅ ✨ ➡ ☀ …)
    (r >= 0x2B00 && r <= 0x2BFF); // stars/arrows (⭐ ⬆ …)
