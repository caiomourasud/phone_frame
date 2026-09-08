import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'status_bar_inset.dart';

/// The insets a phone's browser knows about and does not pass on.
///
/// On a phone the app is drawn edge to edge, and `MediaQuery.padding` comes back **zero**: the
/// browser reserves the status bar's strip for the system and says nothing about the home
/// indicator's. So the bottom bar — the one with *Play* and *Listen* on it — ends up under the white
/// line the system draws over everything, and the app looks like it does not know where the screen
/// ends.
///
/// There is a standard for this, `env(safe-area-inset-*)`, and it lives in CSS where Flutter cannot
/// read it. So the number is written down here instead. It is the iPhone's, which is the phone this
/// app is for, and it is only ever **added** to what the browser reports: the day a browser starts
/// telling the truth, the truth wins.
///
/// The top is only touched when the page is the one drawing under the clock — that is, when it
/// asked for the whole screen with `viewport-fit=cover`. Then, and only then,
/// `env(safe-area-inset-top)` has a height in it, and [statusBarInset] hands it over; without
/// `cover` the browser keeps that strip and answers zero, and insetting it again would leave a band
/// of nothing under the clock. So the same code is right either way, and an app that has not opted
/// into `cover` sees no change at all.
///
/// Unlike the bottom, this number is not written down here: CSS knows the real one for the phone in
/// hand, and asking is better than guessing at every screen ever made.
///
/// And a phone lying on its side is not touched at all, for the same reason one step further: in
/// landscape the browser hands the page a viewport already clear of the system's furniture — the
/// notch's strip and the indicator's are outside it, which you can see by the page not reaching the
/// end of the screen. Adding the strip there put a band of nothing along an edge of the app that
/// had nothing to avoid. The number below is for the shape it was written for: a phone standing up.
class PhoneSafeArea extends StatelessWidget {
  const PhoneSafeArea({required this.child, super.key});

  final Widget child;

  /// The home indicator's strip on every iPhone that has one.
  static const double homeIndicator = 34;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width > media.size.height) return child;
    final padding = media.padding.copyWith(
      top: math.max(media.padding.top, statusBarInset()),
      bottom: math.max(media.padding.bottom, homeIndicator),
    );
    return MediaQuery(
      data: media.copyWith(padding: padding, viewPadding: padding),
      child: child,
    );
  }
}
