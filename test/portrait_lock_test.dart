import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_frame/phone_frame.dart';

/// The app held upright on a phone that was turned on its side.
void main() {
  group('how far to turn the app back', () {
    test('a phone lying down is turned back, and the angle only says which way', () {
      expect(PortraitLock.quarterTurnsFor(90, onAPhone: true), 3);
      expect(PortraitLock.quarterTurnsFor(270, onAPhone: true), 1);
    });

    test('a phone that will not say is turned anyway: the window already said', () {
      // Safari before 16.4 has no Screen Orientation API at all, and has been reported answering
      // 0 in landscape. The window being wider than it is tall is the answer that matters.
      expect(PortraitLock.quarterTurnsFor(null, onAPhone: true), 3);
      expect(PortraitLock.quarterTurnsFor(0, onAPhone: true), 3);
    });

    test('a screen nobody can turn is left alone unless it says it is turned', () {
      // A desktop window that happens to be short and wide. Standing that on its side would be
      // nonsense, and a desktop screen always reports 0.
      expect(PortraitLock.quarterTurnsFor(0, onAPhone: false), 0);
      expect(PortraitLock.quarterTurnsFor(null, onAPhone: false), 0);
      expect(PortraitLock.quarterTurnsFor(90, onAPhone: false), 3, reason: 'a turned monitor');
    });
  });

  /// What the app is told about the screen it is on, and where it ends up on the page.
  Future<(MediaQueryData, Size, Rect)> inside(
    WidgetTester tester,
    Size window, {
    required int? rotation,
    TargetPlatform platform = TargetPlatform.iOS,
    EdgeInsets reported = EdgeInsets.zero,
  }) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late MediaQueryData told;
    Widget app = PortraitLock(
      rotation: () => rotation,
      child: Builder(
        builder: (context) {
          told = MediaQuery.of(context);
          return const SizedBox.expand(
            child: ColoredBox(key: ValueKey('app'), color: Colors.red),
          );
        },
      ),
    );
    if (reported != EdgeInsets.zero) {
      app = MediaQuery(
        data: MediaQueryData(size: window, padding: reported, viewPadding: reported),
        child: app,
      );
    }
    // Put back inside the body: what reads it is the build below, and the framework checks the
    // debug variables are as it left them the moment the test body returns.
    debugDefaultTargetPlatformOverride = platform;
    await tester.pumpWidget(MaterialApp(theme: ThemeData.dark(), home: app));
    debugDefaultTargetPlatformOverride = null;

    final target = find.byKey(const ValueKey('app'));
    return (told, tester.getSize(target), tester.getRect(target));
  }

  testWidgets('a phone on its side is laid out in the portrait it was drawn for', (tester) async {
    final (told, size, onThePage) = await inside(tester, const Size(874, 402), rotation: 90);

    expect(told.size, const Size(402, 874), reason: 'the app is told the phone standing up');
    expect(size, const Size(402, 874), reason: 'and it is laid out in it');
    // Turned, that portrait covers the window exactly: the two axes swap, so nothing is scaled and
    // nothing is left over.
    expect(onThePage.width, closeTo(874, 0.01));
    expect(onThePage.height, closeTo(402, 0.01));
    expect(onThePage.left, closeTo(0, 0.01));
    expect(onThePage.top, closeTo(0, 0.01));
  });

  testWidgets('a phone standing up is not touched at all', (tester) async {
    final (told, size, _) = await inside(tester, const Size(402, 874), rotation: 0);

    expect(told.size, const Size(402, 874));
    expect(size, const Size(402, 874));
  });

  testWidgets('a small landscape window on a screen nobody turned is left as it is', (
    tester,
  ) async {
    // A browser squeezed into the bottom half of a laptop screen: landscape, but not a phone lying
    // down, and standing it on its side would be nonsense.
    final (told, size, _) = await inside(
      tester,
      const Size(800, 400),
      rotation: 0,
      platform: TargetPlatform.macOS,
    );

    expect(told.size, const Size(800, 400));
    expect(size, const Size(800, 400));
  });

  testWidgets('a phone lying down has nothing added to it', (tester) async {
    // The order these two are nested in is the whole of it, and it has been wrong both ways: the
    // safe area stands outside, where it can see the window's own shape, and in landscape it adds
    // nothing at all — the browser already handed the page a viewport clear of the notch and the
    // indicator. What is left is the app's own margins, the same ones it has standing up.
    tester.view.physicalSize = const Size(852, 393);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late MediaQueryData told;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: PhoneSafeArea(
          child: PortraitLock(
            rotation: () => 90,
            child: Builder(
              builder: (context) {
                told = MediaQuery.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    debugDefaultTargetPlatformOverride = null;

    expect(told.size, const Size(393, 852), reason: 'still the portrait it was drawn for');
    expect(told.padding, EdgeInsets.zero);
  });

  testWidgets('what is under the lock knows the app was turned', (tester) async {
    // It cannot work that out for itself — it is handed a portrait window and told nothing — and
    // the nav capsule measures the room under itself differently in this shape.
    tester.view.physicalSize = const Size(852, 393);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late bool turnedInside;
    late bool turnedStandingUp;
    Widget probe(void Function(bool) tell) => Builder(
      builder: (context) {
        tell(PortraitLock.turned(context));
        return const SizedBox.shrink();
      },
    );

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: PortraitLock(rotation: () => 90, child: probe((value) => turnedInside = value)),
      ),
    );
    debugDefaultTargetPlatformOverride = null;
    expect(turnedInside, isTrue);

    // And a window nobody turned says nothing at all.
    tester.view.physicalSize = const Size(402, 874);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: PortraitLock(rotation: () => 0, child: probe((value) => turnedStandingUp = value)),
      ),
    );
    expect(turnedStandingUp, isFalse);
  });

  testWidgets('what the window reserves is turned with the app', (tester) async {
    // The notch and the keyboard do not move when the app is turned back, so which of the app's
    // edges they are on does. On a phone turned this way its top edge points to the left of the
    // window, so what the window reserves on the left is the app's top, and the strip along the
    // bottom of the window — the home indicator's — runs down the app's left-hand side.
    final (told, _, _) = await inside(
      tester,
      const Size(874, 402),
      rotation: 90,
      reported: const EdgeInsets.only(bottom: 21, left: 44),
    );

    expect(told.padding.top, 44);
    expect(told.padding.left, 21);
    expect(told.padding.bottom, 0, reason: 'nothing is reserved along the app s own bottom');
  });
}
