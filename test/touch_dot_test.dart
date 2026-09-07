import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_frame/phone_frame.dart';

/// The fingertip drawn over the phone's screen, in place of the page's arrow.
void main() {
  /// The dot over a 200 by 100 patch of glass in the top-left corner of the window.
  Future<RenderTouchDot> glass(WidgetTester tester, ValueListenable<Fingertip?> pointer) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 200, height: 100, child: TouchDot(pointer: pointer)),
        ),
      ),
    );
    return tester.renderObject<RenderTouchDot>(find.byType(TouchDot));
  }

  testWidgets('it claims the pointer on the glass, and nothing beyond it', (tester) async {
    // Beyond it is the desk the phone is standing on, where an arrow is what a pointer should be —
    // which is the whole reason the dot is mounted over the screen and not over the page.
    final pointer = ValueNotifier<Fingertip?>((at: const Offset(50, 40), pressing: false));
    addTearDown(pointer.dispose);
    final dot = await glass(tester, pointer);

    expect(dot.onTheGlass, const Offset(50, 40));

    // A pump each time: where the pointer is on the glass is worked out while painting, because
    // that is the only moment the transforms above this box are true.
    pointer.value = (at: const Offset(320, 40), pressing: false);
    await tester.pump();
    expect(dot.onTheGlass, isNull, reason: 'past the right-hand edge');

    pointer.value = (at: const Offset(50, 260), pressing: false);
    await tester.pump();
    expect(dot.onTheGlass, isNull, reason: 'below it');

    pointer.value = (at: const Offset(120, 90), pressing: true);
    await tester.pump();
    expect(dot.onTheGlass, const Offset(120, 90), reason: 'and back on it');

    pointer.value = null;
    await tester.pump();
    expect(dot.onTheGlass, isNull, reason: 'off the page altogether');
  });

  testWidgets('it is never in the way of what it is pointing at', (tester) async {
    // It is painted over the whole app now, so a tap that it swallowed would be a tap the app
    // never sees.
    var taps = 0;
    final pointer = ValueNotifier<Fingertip?>(null);
    addTearDown(pointer.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: GestureDetector(
                // A bare `SizedBox` is not a hit-test target, and a tap that missed for that
                // reason would look exactly like a tap the dot had swallowed.
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: const SizedBox(width: 200, height: 100),
              ),
            ),
            Positioned.fill(child: TouchDot(pointer: pointer)),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(GestureDetector));
    expect(taps, 1);
  });
}
