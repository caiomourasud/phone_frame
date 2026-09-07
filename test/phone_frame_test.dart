import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_frame/phone_frame.dart';

/// The frame the app is drawn in when it is opened on a computer.
void main() {
  group('who gets a frame', () {
    test('a phone browser does not: it is already the shape the app wants', () {
      expect(framesTheApp(const Size(402, 874)), isFalse);
      expect(framesTheApp(const Size(874, 402)), isFalse, reason: 'the same phone, turned');
      expect(framesTheApp(const Size(360, 800)), isFalse);
    });

    test('a computer does, and so does a window squeezed to half of one', () {
      expect(framesTheApp(const Size(1440, 900)), isTrue);
      expect(framesTheApp(const Size(720, 900)), isTrue);
      expect(framesTheApp(const Size(1024, 768)), isTrue, reason: 'a tablet is not a hand either');
    });
  });

  group('the safe area a phone browser withholds', () {
    /// What the app is told about the screen it is on, inside [PhoneSafeArea].
    Future<MediaQueryData> mediaInside(
      WidgetTester tester, {
      EdgeInsets? reported,
      Size window = const Size(402, 874),
    }) async {
      tester.view.physicalSize = window;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late MediaQueryData inside;
      Widget probe = Builder(
        builder: (context) {
          inside = MediaQuery.of(context);
          return const SizedBox.shrink();
        },
      );
      probe = PhoneSafeArea(child: probe);
      if (reported != null) {
        probe = MediaQuery(
          data: MediaQueryData(padding: reported, viewPadding: reported),
          child: probe,
        );
      }
      await tester.pumpWidget(MaterialApp(theme: ThemeData.dark(), home: probe));
      return inside;
    }

    testWidgets('the home indicator gets its strip, which the browser never mentions', (
      tester,
    ) async {
      final media = await mediaInside(tester);
      expect(media.padding.bottom, PhoneSafeArea.homeIndicator);
      expect(media.viewPadding.bottom, PhoneSafeArea.homeIndicator);
    });

    testWidgets('the top is left alone: the system already keeps it', (tester) async {
      final media = await mediaInside(tester);
      expect(media.padding.top, 0);
    });

    testWidgets('a phone lying on its side is left alone: the browser already kept the strip', (
      tester,
    ) async {
      // In landscape the page does not even reach the end of the screen — the notch's strip and
      // the indicator's are outside the viewport the browser handed over — so the 34 would be a
      // band of nothing along an edge with nothing on it.
      final media = await mediaInside(tester, window: const Size(852, 393));
      expect(media.padding, EdgeInsets.zero);
    });

    testWidgets('a browser that does report an inset is believed', (tester) async {
      // The number here is written down because no browser hands it over. The day one does, and it
      // is bigger, it is the one that counts.
      final media = await mediaInside(tester, reported: const EdgeInsets.only(bottom: 50, top: 47));
      expect(media.padding.bottom, 50);
      expect(media.padding.top, 47, reason: 'what the browser knows is not overwritten');
    });
  });

  testWidgets('the bottom bar comes up off the home indicator', (tester) async {
    // The complaint this exists for: on a phone browser the *Play* and *Listen* bar was drawn
    // under the line the system paints over everything.
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<double> barBottom({required bool inset}) async {
      // Anything an app anchors at the bottom, with the safe area under it: what this is about is
      // the strip, not the bar.
      const page = Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(top: false, child: SizedBox(key: ValueKey('bar'), height: 40, width: 200)),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: inset ? const PhoneSafeArea(child: page) : page,
        ),
      );
      return tester.getRect(find.byKey(const ValueKey('bar'))).bottom;
    }

    expect(
      await barBottom(inset: false) - await barBottom(inset: true),
      PhoneSafeArea.homeIndicator,
    );
  });

  group('the frame', () {
    /// Reads what the app inside the frame is told about the screen it is on.
    Future<MediaQueryData> mediaInside(WidgetTester tester, Size window) async {
      tester.view.physicalSize = window;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late MediaQueryData inside;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: PhoneFrame(
            child: Builder(
              builder: (context) {
                inside = MediaQuery.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      return inside;
    }

    testWidgets('the app inside it is told it is on the phone, not on the window', (tester) async {
      final media = await mediaInside(tester, const Size(1600, 1000));
      expect(media.size, PhoneFrame.screenSize);
      expect(media.padding, PhoneFrame.safeArea, reason: 'the island and the home indicator');
      expect(media.viewInsets, EdgeInsets.zero);
    });

    testWidgets('a window shorter than the phone gets the whole phone anyway', (tester) async {
      // The frame shrinks to fit; what the app is told does not change, which is the point — the
      // preview is of a phone, whatever the laptop is.
      final media = await mediaInside(tester, const Size(1280, 700));
      expect(media.size, PhoneFrame.screenSize);

      final device = tester.getSize(find.byType(FittedBox).first);
      expect(device.height, lessThanOrEqualTo(700));
    });

    testWidgets('the screen is clipped to the phone s corners', (tester) async {
      await mediaInside(tester, const Size(1600, 1000));
      final clip = tester.widget<ClipRRect>(
        find.descendant(of: find.byType(PhoneFrame), matching: find.byType(ClipRRect)).first,
      );
      expect(clip.borderRadius, BorderRadius.circular(PhoneFrame.screenRadius));
    });

    test('the housing has the proportions of the phone it is a picture of', () {
      // 71.85 by 150.01 mm, sheet 1 of Apple's dimensional drawing for the iPhone 17 Pro. The
      // screen is the drawing's active area, so the bezel is the only thing that can get this
      // wrong — and a bezel of the wrong width is a phone of the wrong shape.
      expect(
        PhoneFrame.bodySize.width / PhoneFrame.bodySize.height,
        closeTo(71.85 / 150.01, 0.001),
      );
    });

    testWidgets('every button sits where the drawing puts it', (tester) async {
      await mediaInside(tester, const Size(1600, 1200));
      final screen = tester.getRect(
        find.descendant(of: find.byType(PhoneFrame), matching: find.byType(ClipRRect)).first,
      );
      final housingTop = screen.top - PhoneFrame.edge;

      // Centre below the top of the housing, and length, in millimetres: the action button, the
      // two volume keys, then the side button. Camera Control is on the drawing and not on this
      // phone, on purpose.
      const drawing = [(34.28, 6.90), (48.43, 11.20), (62.63, 11.20), (55.53, 17.70)];
      expect(find.byType(PhoneButton), findsNWidgets(drawing.length));

      for (var i = 0; i < drawing.length; i++) {
        final (centre, length) = drawing[i];
        final button = tester.getRect(find.byType(PhoneButton).at(i));
        expect(
          (button.center.dy - housingTop) / PhoneFrame.pointsPerMillimetre,
          closeTo(centre, 0.01),
          reason: 'button $i is $centre mm below the top of the phone',
        );
        expect(
          button.height / PhoneFrame.pointsPerMillimetre,
          closeTo(length, 0.01),
          reason: 'button $i is $length mm long',
        );
      }
    });
  });
}
