import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_frame/phone_frame.dart';

/// The keyboard a browser covers the app with and does not mention.
void main() {
  group('how much of the app is covered', () {
    test('what the page no longer shows of it', () {
      expect(KeyboardInset.coveredOf(874, 538), 336);
    });

    test('a page nobody is measuring is not covered', () {
      // No field has focus, or the browser has no visual viewport to ask. Either way the app is
      // left exactly as the platform laid it out.
      expect(KeyboardInset.coveredOf(874, null), 0);
    });

    test('a page showing more than the app is tall covers none of it', () {
      // It should not happen, and a negative inset is an assertion in the framework rather than a
      // layout that comes out slightly wrong.
      expect(KeyboardInset.coveredOf(874, 900), 0);
    });
  });

  /// What the app is told, with a page that is showing [visible] of its height.
  Future<MediaQueryData> told(
    WidgetTester tester,
    double? visible, {
    EdgeInsets reported = EdgeInsets.zero,
  }) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late MediaQueryData data;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: const Size(402, 874), viewInsets: reported),
        child: KeyboardInset(
          visible: () => ValueNotifier<double?>(visible),
          child: Builder(
            builder: (context) {
              data = MediaQuery.of(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    return data;
  }

  testWidgets('the covered strip reaches the app as the keyboard', (tester) async {
    final data = await told(tester, 538);
    expect(data.viewInsets.bottom, 336);
  });

  testWidgets('a page showing all of the app says nothing', (tester) async {
    final data = await told(tester, 874);
    expect(data.viewInsets.bottom, 0);
  });

  testWidgets('whatever the platform managed to say stands', (tester) async {
    // An embedding where the engine does report the keyboard: this only ever fills in a silence,
    // and the bigger of the two is the one the app is laid out against.
    final data = await told(tester, 874, reported: const EdgeInsets.only(bottom: 336));
    expect(data.viewInsets.bottom, 336);
  });

  testWidgets('the keyboard opening moves what the app has room for', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final visible = ValueNotifier<double?>(null);
    addTearDown(visible.dispose);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(402, 874)),
        child: KeyboardInset(
          visible: () => visible,
          child: const MaterialApp(home: Scaffold(body: SizedBox.expand())),
        ),
      ),
    );
    expect(tester.getSize(find.byType(SizedBox)).height, 874);

    visible.value = 538;
    await tester.pump();

    // Nothing in the app was told anything: `Scaffold` reads the keyboard out of `MediaQuery` on
    // its own, which is the whole point of putting the number there.
    expect(tester.getSize(find.byType(SizedBox)).height, 538);
  });
}
