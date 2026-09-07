import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import 'touch_emulation.dart';
import 'phone_button.dart';
import 'touch_dot.dart';

/// Whether the page it is being read on is a desk rather than a hand.
///
/// A phone browser gets no frame: drawing a picture of a phone inside a phone wastes the screen and
/// tells the reader nothing they cannot see by looking down. The threshold is the usual one for
/// "this is not a phone", and it is measured on the **window** and not on the device, so a browser
/// squeezed into half a laptop screen also gives the app the whole of it.
///
/// `web/index.html` says the same thing in CSS, because hiding the page's cursor is not something
/// Flutter can do; the query there is this number on the same window.
bool framesTheApp(Size viewport) => viewport.shortestSide >= 600;

/// The app inside a phone, for whoever opens it on a computer.
///
/// On a desktop the app would otherwise be stretched across a screen it was never designed for —
/// a chord sheet a metre wide, with the strumming ruler somewhere off to the right. The frame gives
/// it back the shape it was drawn in, and says out loud what it is: something you hold while your
/// other hand is on the neck of a guitar.
///
/// It is not decoration, and it is not a drawing of a phone either. Inside it the app is told it is
/// on **an iPhone 17 Pro** — that size, that safe area — and it is touched like one: the mouse
/// arrives as a finger, nothing hovers, and a list is dragged rather than wheeled. See
/// [TouchEmulation]. The measurements are Apple's own, off the dimensional drawing for this phone;
/// [pointsPerMillimetre] is what turns that drawing into this widget.
///
/// The whole thing scales down to whatever the window can spare, which is what makes it survive a
/// laptop that is shorter than the phone is tall.
class PhoneFrame extends StatefulWidget {
  const PhoneFrame({required this.child, this.desk, this.homeIndicator, super.key});

  final Widget child;

  /// The colour of the desk the phone is standing on.
  ///
  /// Deliberately **not** the app's own background: two of the same touching make one shape, and
  /// the whole point of the frame is that the phone is an object. Left out, it is a neutral a shade
  /// off the ambient theme's, which is what that rule comes to in the general case.
  final Color? desk;

  /// The colour of the home indicator's own strip, which belongs to the system and not to the app.
  ///
  /// Left out, it takes the ambient theme's foreground at a third, as the system's does: white on a
  /// dark screen, dark on a light one.
  final Color? homeIndicator;

  /// The iPhone 17 Pro's screen, in logical points.
  static const Size screenSize = Size(402, 874);

  /// What the system keeps for itself at the top and bottom: the Dynamic Island's row, and the home
  /// indicator. Handing these to the app is what makes the preview honest — a screen that ignores
  /// them looks right here and wrong in the hand.
  static const EdgeInsets safeArea = EdgeInsets.only(top: 59, bottom: 34);

  /// The display's own corner, which is the radius iOS rounds this screen with.
  static const double screenRadius = 62;

  /// One millimetre of the phone, in points — and the reason the rest of this file reads like the
  /// drawing it came from.
  ///
  /// Apple gives the display's active area as 66.57 × 144.73 mm, and that area is this app's
  /// 402 × 874 points. Both sides of that agree to five decimals, so every other number here is
  /// the drawing's own millimetres multiplied by this and nothing else.
  static const double pointsPerMillimetre = 874 / 144.73;

  /// The black mask on the glass, and the titanium edge outside it.
  ///
  /// Together they are the 2.64 mm the drawing puts between the housing and the first lit pixel:
  /// 1.44 of it is the glass's own black border, 1.20 is the metal you can see from the front.
  static const double _rim = 1.44 * pointsPerMillimetre;
  static const double _band = 1.20 * pointsPerMillimetre;

  /// Housing to screen, the same all the way round.
  static const double edge = _rim + _band;

  /// The whole phone: the drawing's 71.85 × 150.01 mm, to a tenth of a point.
  static final Size bodySize = Size(screenSize.width + edge * 2, screenSize.height + edge * 2);

  /// The Dynamic Island, 20.76 × 6.07 mm on the drawing.
  static const Size _island = Size(20.76 * pointsPerMillimetre, 6.07 * pointsPerMillimetre);

  /// Its lower edge is 7.99 mm below the first pixel, so its top is what is left of that.
  static const double _islandTop = (7.99 - 6.07) * pointsPerMillimetre;

  /// Each button as (centre below the top of the housing, length), in millimetres: the action
  /// button, then volume up and volume down.
  static const List<(double, double)> _leftButtons = [
    (34.28, 6.90),
    (48.43, 11.20),
    (62.63, 11.20),
  ];

  /// And on the other side, the side button alone. The drawing has Camera Control below it — 98.40
  /// down, 17.10 long — and it is deliberately not drawn: there is no camera behind this glass.
  static const List<(double, double)> _rightButtons = [(55.53, 17.70)];

  /// How far a button stands out of the housing: 0.45 mm, and the drawing says so of all five.
  static const double _rise = 0.45 * pointsPerMillimetre;

  /// What a drag inside the frame may come from: the framework's own set, plus the mouse.
  ///
  /// Dragging the screen is how a phone scrolls, and on a computer the mouse is the finger. It is
  /// belt and braces — the events already arrive as touches — for the day this widget is looked at
  /// somewhere the emulation is not installed.
  static const Set<PointerDeviceKind> _fingerAndMouse = {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.unknown,
    PointerDeviceKind.mouse,
  };

  @override
  State<PhoneFrame> createState() => _PhoneFrameState();
}

class _PhoneFrameState extends State<PhoneFrame> {
  @override
  void initState() {
    super.initState();
    // The mouse is a finger for exactly as long as there is a phone on the page to press, and this
    // is where that is known. See [TouchEmulation].
    TouchEmulation.takeOver();
  }

  @override
  void dispose() {
    TouchEmulation.handBack();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final desk = widget.desk ?? (dark ? const Color(0xFF17171A) : const Color(0xFFE7E7E4));
    final ink = widget.homeIndicator ?? (dark ? Colors.white : Colors.black);
    final media = MediaQuery.of(context);

    Widget button(double centre, double length, {required bool onLeft}) => Positioned(
      top: (centre - length / 2) * PhoneFrame.pointsPerMillimetre,
      left: onLeft ? -PhoneFrame._rise : null,
      right: onLeft ? null : -PhoneFrame._rise,
      child: PhoneButton(
        length: length * PhoneFrame.pointsPerMillimetre,
        width: PhoneFrame.edge + PhoneFrame._rise,
        onLeft: onLeft,
      ),
    );

    final device = SizedBox.fromSize(
      size: PhoneFrame.bodySize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Drawn before the body, so all that shows of them is the part that stands out of it.
          for (final (centre, length) in PhoneFrame._leftButtons)
            button(centre, length, onLeft: true),
          for (final (centre, length) in PhoneFrame._rightButtons)
            button(centre, length, onLeft: false),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PhoneFrame.screenRadius + PhoneFrame.edge),
              color: const Color(0xFF3C3C45),
              // Titanium is not a colour, it is the outer PhoneFrame.edge catching the light. Without this
              // line the phone and the page are two blacks touching, and the frame disappears.
              border: Border.all(color: const Color(0xFF6E6E7A), width: 1.2),
              boxShadow: const [
                BoxShadow(color: Color(0x99000000), blurRadius: 56, offset: Offset(0, 22)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(PhoneFrame._band),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF08080A),
                  borderRadius: BorderRadius.circular(PhoneFrame.screenRadius + PhoneFrame._rim),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(PhoneFrame._rim),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(PhoneFrame.screenRadius),
                    child: Stack(
                      children: [
                        MediaQuery(
                          // The app is told the truth about the phone it is drawn in, and nothing else
                          // in it has to know this frame exists.
                          data: media.copyWith(
                            size: PhoneFrame.screenSize,
                            padding: PhoneFrame.safeArea,
                            viewPadding: PhoneFrame.safeArea,
                            viewInsets: EdgeInsets.zero,
                          ),
                          child: ScrollConfiguration(
                            // A phone's list bounces at the end, has no scrollbar down the side, and
                            // moves because a finger moved it. The platform is named rather than
                            // inherited so that a Windows laptop gets the phone's behaviour too.
                            behavior: ScrollConfiguration.of(context).copyWith(
                              platform: TargetPlatform.iOS,
                              scrollbars: false,
                              dragDevices: PhoneFrame._fingerAndMouse,
                            ),
                            child: SizedBox.fromSize(
                              size: PhoneFrame.screenSize,
                              child: widget.child,
                            ),
                          ),
                        ),
                        // Over the app and clipped to the glass, because that is the whole of the
                        // question it answers: the pointer is a fingertip on this screen and an
                        // arrow everywhere else on the page.
                        Positioned.fill(child: TouchDot(pointer: TouchEmulation.pointer)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // The home indicator, which belongs to the system and not to the app — the app is kept
          // clear of it by the safe area, exactly as it is on the phone.
          Positioned(
            bottom: PhoneFrame.edge + 8,
            left: (PhoneFrame.bodySize.width - 140) / 2,
            child: Container(
              width: 140,
              height: 5,
              decoration: BoxDecoration(
                // It takes the colour of whatever is under it, as the system's own does: white on a
                // dark screen, dark on a light one.
                color: ink.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          // The island floats over the screen, as it does on the phone — which is why the app is
          // given a safe area instead of being drawn around it.
          Positioned(
            top: PhoneFrame.edge + PhoneFrame._islandTop,
            left: (PhoneFrame.bodySize.width - PhoneFrame._island.width) / 2,
            child: Container(
              width: PhoneFrame._island.width,
              height: PhoneFrame._island.height,
              decoration: BoxDecoration(
                color: const Color(0xFF000000),
                borderRadius: BorderRadius.circular(PhoneFrame._island.height / 2),
              ),
            ),
          ),
        ],
      ),
    );

    return ColoredBox(
      // The desk the phone is put down on. See [PhoneFrame.desk] for why it is never the app's own
      // background.
      color: desk,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          // A laptop is shorter than this phone is tall, so the frame is allowed to shrink. It
          // never grows: a phone the size of a monitor is a poster, not a preview.
          child: FittedBox(fit: BoxFit.scaleDown, child: device),
        ),
      ),
    );
  }
}
