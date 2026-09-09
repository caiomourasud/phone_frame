import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'visible_page_height.dart';

/// The strip the on-screen keyboard covers, handed to the app as `MediaQuery.viewInsets`.
///
/// A phone hands this over without being asked, and so does a Flutter page that fills the browser
/// window. A page hosted in an element of its own does not — the engine answers a flat zero for the
/// keyboard there, and never even re-measures, because the keyboard does not resize the host. What
/// the app is left with is the one thing that looks like nothing being wrong: a field tapped at the
/// bottom of the screen stays under the keys, because with `viewInsets.bottom` at zero the
/// `Scaffold` has nothing to shrink and `EditableText` has nowhere to scroll the caret to.
///
/// So the number is measured on the page ([visiblePageHeight]) and put where the framework already
/// looks for it. Nothing in the app has to know: `Scaffold`, `SafeArea`, a bottom sheet reading
/// `MediaQuery.viewInsetsOf` and the caret scrolling itself into view all read this one field.
///
/// It only ever fills in a silence. Whatever the platform did manage to say stands, so an embedding
/// where the engine reports the keyboard properly is left exactly as it was.
class KeyboardInset extends StatelessWidget {
  const KeyboardInset({required this.child, this.visible = visiblePageHeight, super.key});

  final Widget child;

  /// Where "how much of the page is still on screen" is read from.
  ///
  /// It is a parameter for one reason: `flutter test` has no browser to cover half of, so a test
  /// that wants a keyboard has to say so.
  final ValueListenable<double?> Function() visible;

  /// How much of an app that tall the keyboard is covering, given what is still on screen.
  ///
  /// Never negative, and never a guess: a page nobody is measuring — null — is not covered at all.
  static double coveredOf(double appHeight, double? visiblePageHeight) {
    if (visiblePageHeight == null) return 0;
    return math.max(0, appHeight - visiblePageHeight);
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double?>(
    valueListenable: visible(),
    builder: (context, visiblePageHeight, _) {
      final media = MediaQuery.of(context);
      final bottom = math.max(
        media.viewInsets.bottom,
        coveredOf(media.size.height, visiblePageHeight),
      );
      // The common case, and the whole of it on a phone with the keyboard down: nothing to say, so
      // no `MediaQuery` of ours between the app and the one the platform wrote.
      if (bottom == media.viewInsets.bottom) return child;
      return MediaQuery(
        data: media.copyWith(viewInsets: media.viewInsets.copyWith(bottom: bottom)),
        child: child,
      );
    },
  );
}
