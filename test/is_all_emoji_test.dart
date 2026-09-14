// `isAllEmoji` entscheidet, ob eine Nachricht als GROSSES Emoji neben der Blase
// steht statt als gewöhnlicher Text darin. Verglichen wurde die Zahl der
// CODEPOINTS mit der Zahl der gefundenen Emoji — und die zählt `parseEmojis`
// über Graphem-Cluster. Für jedes Emoji, das aus mehr als einem Codepoint
// besteht, konnten die beiden gar nicht übereinstimmen: 🙂‍↕️ sind vier
// Codepoints und ein Cluster, ❤️ zwei und einer, 👍🏽 zwei und einer.
// Gemeldet von Gerry (2026-09-14) am Bild: das Kopfnicken sass klein in der
// Blase, mit Uhrzeit daneben.

import 'package:chatview/src/extensions/extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isAllEmoji', () {
    test('ein einzelnes einfaches Emoji', () {
      expect('😂'.isAllEmoji, isTrue);
    });

    test('ZWJ-Folge mit BMP-Ende (🙂‍↕️) — der gemeldete Fall', () {
      expect('\u{1F642}\u{200D}\u{2195}\u{FE0F}'.isAllEmoji, isTrue);
    });

    test('Familie mit zwei Verbindern', () {
      expect('\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}'.isAllEmoji, isTrue);
    });

    test('Herz mit Variantenwähler', () {
      expect('\u{2764}\u{FE0F}'.isAllEmoji, isTrue);
    });

    test('Emoji mit Hautton', () {
      expect('\u{1F44D}\u{1F3FD}'.isAllEmoji, isTrue);
    });

    test('Flagge (zwei Regionalzeichen)', () {
      expect('\u{1F1E6}\u{1F1F9}'.isAllEmoji, isTrue);
    });

    test('Keycap', () {
      expect('\u{0031}\u{FE0F}\u{20E3}'.isAllEmoji, isTrue);
    });

    test('mehrere verbundene Emoji hintereinander', () {
      expect('\u{2764}\u{FE0F}\u{1F642}\u{200D}\u{2195}\u{FE0F}'.isAllEmoji,
          isTrue);
    });

    test('Text ist NICHT alles Emoji', () {
      expect('Hallo'.isAllEmoji, isFalse);
    });

    test('Text mit Emoji ist NICHT alles Emoji', () {
      expect('Hi 😂'.isAllEmoji, isFalse);
    });

    test('ein Leerzeichen zwischen Emoji zählt als Text (wie bisher)', () {
      expect('😂 😂'.isAllEmoji, isFalse);
    });

    test('leer ist NICHT alles Emoji (fork p10)', () {
      expect(''.isAllEmoji, isFalse);
    });

    test('gewöhnliche Zeichen bleiben Text (→, ™, Ziffer)', () {
      expect('\u{2192}'.isAllEmoji, isFalse);
      expect('\u{2122}'.isAllEmoji, isFalse);
      expect('1'.isAllEmoji, isFalse);
    });

    test('Schrift-Variante des Herzens ist Text, nicht Emoji', () {
      expect('\u{2764}\u{FE0E}'.isAllEmoji, isFalse);
    });
  });
}
