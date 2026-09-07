import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'phone_frame.dart';
import 'phone_safe_area.dart';
import 'portrait_lock.dart';

/// The whole of it, as one widget: on the web the app is a phone.
///
/// Hand it to `MaterialApp`'s `builder` and there is nothing else to do:
///
/// ```dart
/// MaterialApp(
///   builder: PhoneOnTheWeb.builder,
///   ...
/// )
/// ```
///
/// What that buys, and why each half exists:
///
/// - **A desk-sized window gets the phone drawn in it**, and the app inside is *told* it is on that
///   phone — that size, that safe area — so the page shows what a phone would, down to where a line
///   of text wraps. It is also touched like one: the mouse arrives as a finger, nothing hovers, a
///   drag scrolls, and the arrow becomes a fingertip over the glass. See [PhoneFrame].
/// - **Anything smaller is a phone already**, and what it needs is the opposite: the insets the
///   browser withholds ([PhoneSafeArea]) and to be held upright when the page turns with the phone
///   ([PortraitLock]).
///
/// The line between the two is [framesTheApp], measured on the **window** and never on the user
/// agent: a browser squeezed into half a laptop gets the whole width, and a phone in landscape
/// stays unframed.
///
/// On Android and iOS it hands the child straight back. None of this belongs on a device that
/// really is one.
class PhoneOnTheWeb extends StatelessWidget {
  const PhoneOnTheWeb({required this.child, this.desk, this.homeIndicator, super.key});

  /// The app. Nullable because that is the shape `MaterialApp`'s `builder` hands over.
  final Widget? child;

  /// Passed through to [PhoneFrame.desk].
  final Color? desk;

  /// Passed through to [PhoneFrame.homeIndicator].
  final Color? homeIndicator;

  /// Ready to be handed to `MaterialApp`'s `builder` as it is, for the case with nothing to say
  /// about colours.
  static Widget builder(BuildContext context, Widget? child) => PhoneOnTheWeb(child: child);

  @override
  Widget build(BuildContext context) {
    final child = this.child;
    if (child == null) return const SizedBox.shrink();
    if (!kIsWeb) return child;
    if (framesTheApp(MediaQuery.sizeOf(context))) {
      return PhoneFrame(desk: desk, homeIndicator: homeIndicator, child: child);
    }
    // The safe area stands outside the lock on purpose: out there it can see the shape of the
    // window, which is how it knows a phone lying down needs nothing written down for it — and
    // whatever the browser did report is turned along with the app by the lock.
    return PhoneSafeArea(child: PortraitLock(child: child));
  }
}
