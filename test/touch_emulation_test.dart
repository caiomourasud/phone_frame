import 'dart:ui';

import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_frame/phone_frame.dart';

/// The mouse, on the page where the app is drawn inside a phone.
void main() {
  PointerData mouse(PointerChange change, {PointerSignalKind? signal}) => PointerData(
    kind: PointerDeviceKind.mouse,
    change: change,
    signalKind: signal,
    physicalX: 30,
    physicalY: 60,
    buttons: kPrimaryButton,
  );

  test('a press arrives as a finger, and that is what takes the hover off every button', () {
    final finger = TouchEmulation.asFinger([
      mouse(PointerChange.down),
      mouse(PointerChange.move),
      mouse(PointerChange.up),
    ]);

    expect(finger.map((datum) => datum.kind), everyElement(PointerDeviceKind.touch));
    expect(finger.map((datum) => datum.change), [
      PointerChange.down,
      PointerChange.move,
      PointerChange.up,
    ]);
    expect(finger.first.physicalX, 30, reason: 'and it lands where the mouse was');
  });

  test('hovering is dropped: a finger is either on the glass or nowhere', () {
    expect(TouchEmulation.asFinger([mouse(PointerChange.hover)]), isEmpty);
    expect(TouchEmulation.asFinger([mouse(PointerChange.add)]), isEmpty);
  });

  test('the wheel is left alone, so the page is still read the way a computer reads one', () {
    final wheel = TouchEmulation.asFinger([
      mouse(PointerChange.hover, signal: PointerSignalKind.scroll),
    ]);

    expect(wheel.single.kind, PointerDeviceKind.mouse);
    expect(wheel.single.signalKind, PointerSignalKind.scroll);
  });

  test('a real finger is not touched at all', () {
    const touch = PointerData(kind: PointerDeviceKind.touch, change: PointerChange.down);

    expect(TouchEmulation.asFinger([touch]).single, same(touch));
  });

  testWidgets('it takes over where the phone is drawn, and nowhere else', (tester) async {
    // The complaint the whole thing exists for, and the one thing only the real engine callback
    // can be asked about: whether what the app is given still hovers.
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // There is no uninstalling it — in the app it goes in once and stays — so the test puts the
    // binding's own handler back before the next one runs. It stays installed for both halves
    // below: the only thing that changes is whether there is a phone on screen.
    final handler = PlatformDispatcher.instance.onPointerDataPacket;
    addTearDown(() => PlatformDispatcher.instance.onPointerDataPacket = handler);
    TouchEmulation.install();

    var entered = 0;
    final target = MouseRegion(
      onEnter: (_) => entered++,
      child: const SizedBox(key: ValueKey('target'), width: 200, height: 100),
    );
    void fromTheMouse(PointerChange change) {
      final at = tester.getCenter(find.byKey(const ValueKey('target')));
      PlatformDispatcher.instance.onPointerDataPacket?.call(
        PointerDataPacket(
          data: [
            PointerData(
              viewId: tester.view.viewId,
              change: change,
              kind: PointerDeviceKind.mouse,
              device: 1,
              physicalX: at.dx,
              physicalY: at.dy,
            ),
          ],
        ),
      );
    }

    // No frame, so no finger: the arrow arrives as itself and the app lights up under it. This is
    // also what makes the second half mean something.
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Center(child: target),
      ),
    );
    fromTheMouse(PointerChange.hover);
    await tester.pump();
    expect(entered, 1);

    // It has to leave before it can arrive again — and it has to leave while it is still a mouse,
    // because a finger cannot do that either.
    fromTheMouse(PointerChange.remove);
    await tester.pump();

    // Now with a phone on the page, which is the only thing that turns the rewrite on.
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: PhoneFrame(child: Center(child: target)),
      ),
    );
    fromTheMouse(PointerChange.hover);
    await tester.pump();
    expect(entered, 1, reason: 'the second arrival never happened: a finger does not hover');
  });

  test('where the mouse is stays known, because nothing else is left to ask', () {
    // The pointer is drawn by hand over the glass, and the events it would be read from are the
    // ones this drops. So it is read here or nowhere.
    TouchEmulation.asFinger([mouse(PointerChange.hover)]);
    expect(TouchEmulation.pointer.value?.at, const Offset(30, 60) / 3);

    TouchEmulation.asFinger([mouse(PointerChange.remove)]);
    expect(TouchEmulation.pointer.value, isNull);
  });

  test('and whether it is held, which is the only sign a video has of a tap', () {
    // A mouse gives no sign of being pressed. Without this, every tap in a screen recording is a
    // sheet that moves for no visible reason.
    TouchEmulation.asFinger([mouse(PointerChange.hover)]);
    expect(TouchEmulation.pointer.value?.pressing, isFalse);

    TouchEmulation.asFinger([mouse(PointerChange.down)]);
    expect(TouchEmulation.pointer.value?.pressing, isTrue);

    // A move only ever arrives with a button held: a mouse moving free of them is a hover.
    TouchEmulation.asFinger([mouse(PointerChange.move)]);
    expect(TouchEmulation.pointer.value?.pressing, isTrue, reason: 'still down, and dragging');

    TouchEmulation.asFinger([mouse(PointerChange.up)]);
    expect(TouchEmulation.pointer.value?.pressing, isFalse);
  });
}
