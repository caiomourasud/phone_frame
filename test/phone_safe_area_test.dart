import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_frame/phone_frame.dart';

/// The strips a phone's browser knows about and does not pass on.
void main() {
  /// What the app is told, on a window of that shape, with the browser reporting [reported] and the
  /// keyboard covering [keyboard].
  Future<MediaQueryData> told(
    WidgetTester tester,
    Size window, {
    EdgeInsets reported = EdgeInsets.zero,
    double keyboard = 0,
  }) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late MediaQueryData data;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: window,
          padding: reported,
          viewPadding: reported,
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: PhoneSafeArea(
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

  testWidgets('a phone standing up is given the home indicator it was not told about', (
    tester,
  ) async {
    final data = await told(tester, const Size(402, 874));
    expect(data.padding.bottom, PhoneSafeArea.homeIndicator);
    expect(data.viewPadding.bottom, PhoneSafeArea.homeIndicator);
  });

  testWidgets('what the browser does report wins where it is bigger', (tester) async {
    final data = await told(
      tester,
      const Size(402, 874),
      reported: const EdgeInsets.only(bottom: 48),
    );
    expect(data.padding.bottom, 48);
  });

  testWidgets('a phone lying down is left alone', (tester) async {
    // In landscape the browser hands the page a viewport already clear of the system's furniture,
    // and adding the strip there put a band of nothing along an edge with nothing to avoid.
    final data = await told(tester, const Size(874, 402));
    expect(data.padding.bottom, 0);
  });

  testWidgets('the keyboard takes the home indicator off what the app avoids', (tester) async {
    final data = await told(tester, const Size(402, 874), keyboard: 336);
    // Otherwise the app keeps 34 points of nothing between the field and the keys.
    expect(data.padding.bottom, 0);
    // And the strip is still where it always was: it is covered, not gone.
    expect(data.viewPadding.bottom, PhoneSafeArea.homeIndicator);
  });

  testWidgets('a keyboard shorter than the strip only takes its own height off', (tester) async {
    final data = await told(tester, const Size(402, 874), keyboard: 10);
    expect(data.padding.bottom, PhoneSafeArea.homeIndicator - 10);
  });
}
