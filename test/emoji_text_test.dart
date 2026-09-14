// chattr fork p13: emojiUpscaledSpans renders emoji runs of a message at the
// configured `ChatBubble.emojiSize` (text size unchanged). These tests pin the
// run splitting + sizing so a refactor can't silently break inline-emoji sizing
// or (worse) upscale ordinary letters/punctuation — and that the feature is OFF
// (single plain span) when no emojiSize is configured.

import 'package:chatview/src/utils/emoji_text.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // (text, isEmojiRun) pairs for each produced span, at a fixed emojiSize.
  List<(String, bool)> runsOf(String s, {double emojiSize = 22}) {
    final spans = emojiUpscaledSpans(s, emojiSize: emojiSize);
    return [
      for (final span in spans.cast<TextSpan>())
        (span.text ?? '', span.style?.fontSize != null),
    ];
  }

  test('emojiSize null → single unstyled span (feature off, default)', () {
    final spans = emojiUpscaledSpans('Hi 😂', emojiSize: null).cast<TextSpan>();
    expect(spans.length, 1);
    expect(spans.first.text, 'Hi 😂');
    expect(spans.first.style, isNull);
  });

  test('plain text is a single non-emoji run (no upscale)', () {
    expect(runsOf('Hallo Welt'), [('Hallo Welt', false)]);
  });

  test('a lone emoji is one run at the configured emojiSize', () {
    final spans = emojiUpscaledSpans('😂', emojiSize: 24).cast<TextSpan>();
    expect(spans.length, 1);
    expect(spans.first.text, '😂');
    expect(spans.first.style!.fontSize, 24);
  });

  test('text + emoji splits into text run then bigger emoji run', () {
    expect(runsOf('Hi 😂'), [('Hi ', false), ('😂', true)]);
  });

  test('emoji then text', () {
    expect(runsOf('😂 super'), [('😂', true), (' super', false)]);
  });

  test('consecutive emoji collapse into one upscaled run', () {
    expect(runsOf('😂🎉🔥'), [('😂🎉🔥', true)]);
  });

  test('mixed text/emoji/text keeps every run', () {
    expect(
      runsOf('gut 👍 gemacht 🎉!'),
      [('gut ', false), ('👍', true), (' gemacht ', false), ('🎉', true), ('!', false)],
    );
  });

  test('ZWJ family emoji is NOT split by the joiner', () {
    expect(runsOf('👨‍👩‍👧'), [('👨‍👩‍👧', true)]);
  });

  test('ZWJ sequence whose tail is a BMP symbol stays ONE run (head-shake)', () {
    // 🙂‍↕️ = 1F642 200D 2195 FE0F. Splitting per code point tore this apart at
    // the ↕ (Arrows block, outside every emoji range), producing two spans with
    // DIFFERENT font sizes — two shaping runs, so the font could never form the
    // ligature and the bubble showed 🙂 + ↕️ side by side.
    expect(runsOf('\u{1F642}\u{200D}\u{2195}\u{FE0F}'),
        [('\u{1F642}\u{200D}\u{2195}\u{FE0F}', true)]);
  });

  test('ZWJ sequence inline with text keeps exactly one emoji run', () {
    expect(
      runsOf('na \u{1F642}\u{200D}\u{2195}\u{FE0F} nope'),
      [('na ', false), ('\u{1F642}\u{200D}\u{2195}\u{FE0F}', true), (' nope', false)],
    );
  });

  test('a BMP symbol with FE0F is an emoji on its own (\u{2195}\u{FE0F})', () {
    expect(runsOf('\u{2195}\u{FE0F}'), [('\u{2195}\u{FE0F}', true)]);
  });

  test('keycap digit is one emoji run, not a text digit', () {
    expect(runsOf('\u{0031}\u{FE0F}\u{20E3}'),
        [('\u{0031}\u{FE0F}\u{20E3}', true)]);
  });

  test('FE0E asks for TEXT presentation — not upscaled', () {
    expect(runsOf('\u{2764}\u{FE0E}'), [('\u{2764}\u{FE0E}', false)]);
  });

  test('variation-selector heart stays one emoji run', () {
    expect(runsOf('❤️'), [('❤️', true)]);
  });

  test('ordinary symbols/letters are NOT upscaled (no false positive)', () {
    expect(runsOf('Preis 5€ ™ für Café!'), [('Preis 5€ ™ für Café!', false)]);
  });

  test('empty string yields no spans', () {
    expect(emojiUpscaledSpans('', emojiSize: 22), isEmpty);
    expect(emojiUpscaledSpans('', emojiSize: null), isEmpty);
  });
}
