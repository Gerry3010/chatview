// chattr fork (p12): ProfileImageWidget renders an initials-circle fallback
// when no image resolves but a userName is given, instead of collapsing to a
// 0px SizedBox (which made picture-less grouped bubbles jump to the far left).
// These tests guard that the fallback appears only when a name is supplied and
// derives sensible initials, and that the historical empty behaviour is kept
// for callers that pass no name.

import 'package:chatview/src/widgets/profile_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester,
      {String? imageUrl, String? userName}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ProfileImageWidget(
              imageUrl: imageUrl,
              userName: userName,
              networkImageProgressIndicatorBuilder: null,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('no image + name → single-letter initials circle', (tester) async {
    await pump(tester, userName: 'Yogi');
    expect(find.text('Y'), findsOneWidget);
  });

  testWidgets('no image + two-word name → two initials', (tester) async {
    await pump(tester, userName: 'Yogi Bear');
    expect(find.text('YB'), findsOneWidget);
  });

  testWidgets('no image + no name → keeps the empty box (no initials)',
      (tester) async {
    await pump(tester);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('empty image string + name still falls back to initials',
      (tester) async {
    await pump(tester, imageUrl: '', userName: 'zoe');
    expect(find.text('Z'), findsOneWidget);
  });

  testWidgets('same name yields a stable (deterministic) colour', (tester) async {
    await pump(tester, userName: 'Yogi');
    final first = tester.widget<Container>(find.byType(Container)).color;
    await pump(tester, userName: 'Yogi');
    final second = tester.widget<Container>(find.byType(Container)).color;
    expect(first, isNotNull);
    expect(first, second);
  });
}
