// chattr fork (p8): SwipeToReply now distinguishes the reply gesture from an
// opposite-direction "peek the timestamp" gesture. These tests guard that the
// two directions route to their own callbacks and never cross-fire, and that
// the reveal content is built lazily (only once a reveal drag begins).

import 'package:chatview/src/widgets/swipe_to_reply.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpSwipe(
    WidgetTester tester, {
    required bool isOwn,
    required VoidCallback onSwipe,
    VoidCallback? onSwipeToTimestamp,
    ValueGetter<Widget?>? revealBuilder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SwipeToReply(
              isMessageByCurrentUser: isOwn,
              onSwipe: onSwipe,
              onSwipeToTimestamp: onSwipeToTimestamp,
              timestampRevealBuilder: revealBuilder,
              child: const SizedBox(width: 120, height: 40, child: Text('hi')),
            ),
          ),
        ),
      ),
    );
  }

  // Drag the bubble in [dx] direction over several move events so the padding
  // crosses the threshold and the callback branch fires (needs >1 update).
  Future<void> dragBy(WidgetTester tester, double dx) async {
    final g = await tester.startGesture(tester.getCenter(find.text('hi')));
    for (var i = 0; i < 6; i++) {
      await g.moveBy(Offset(dx, 0));
      await tester.pump();
    }
    await g.up();
    await tester.pump();
  }

  testWidgets('own message: reply swipe (left) fires onSwipe only', (t) async {
    var replied = 0, revealed = 0, built = 0;
    await pumpSwipe(
      t,
      isOwn: true,
      onSwipe: () => replied++,
      onSwipeToTimestamp: () => revealed++,
      revealBuilder: () {
        built++;
        return const SizedBox();
      },
    );
    // Own reply direction = right-to-left (negative dx).
    await dragBy(t, -40);
    expect(replied, greaterThan(0));
    expect(revealed, 0);
    expect(built, 0, reason: 'reply drag must not build the reveal chip');
  });

  testWidgets('own message: opposite swipe (right) reveals + fires timestamp',
      (t) async {
    var replied = 0, revealed = 0, built = 0;
    await pumpSwipe(
      t,
      isOwn: true,
      onSwipe: () => replied++,
      onSwipeToTimestamp: () => revealed++,
      revealBuilder: () {
        built++;
        return const SizedBox();
      },
    );
    // Own reveal direction = left-to-right (positive dx).
    await dragBy(t, 40);
    expect(revealed, greaterThan(0));
    expect(built, greaterThan(0), reason: 'reveal chip built lazily on drag');
    expect(replied, 0, reason: 'reveal drag must not fire reply');
  });

  testWidgets('incoming message: directions mirror (reply=right)', (t) async {
    var replied = 0, revealed = 0;
    await pumpSwipe(
      t,
      isOwn: false,
      onSwipe: () => replied++,
      onSwipeToTimestamp: () => revealed++,
      revealBuilder: () => const SizedBox(),
    );
    await dragBy(t, 40); // incoming reply = left-to-right
    expect(replied, greaterThan(0));
    expect(revealed, 0);
  });
}
