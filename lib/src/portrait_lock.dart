import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';

import 'screen_orientation.dart';

/// The app kept upright on a phone that was turned on its side.
///
/// On the phones this is not a preference: `main` tells `SystemChrome` `portraitUp` and
/// `portraitDown` and that is the end of it. A browser has no such switch — a page turns with the
/// phone whatever the app would rather — and the app turned with it, into a shape it was never
/// drawn for: a chord sheet 874 points wide and 402 tall, with the strumming ruler off to one side.
///
/// So the turn is undone. The app is laid out in the portrait it was drawn for and then rotated
/// back by however far the display was rotated, which is exactly what a locked app looks like once
/// the phone is sideways: nothing reflows, and the way back is to turn the phone back.
///
/// A rotated portrait fits a landscape window exactly — the two axes swap — so nothing is scaled
/// and nothing is letterboxed.
///
/// It does nothing at all where the screen was not laid down, which is what keeps a small
/// **desktop** window — landscape, on a screen nobody turned — from being stood on its side.
///
/// What the window reserves is turned along with the app, and nothing is added to it: it stands
/// *inside* `PhoneSafeArea` so that the one deciding whether the phone even needs a strip written
/// down for it can see the window's own shape. Lying down it does not — the browser already hands
/// the page a viewport clear of the notch and the indicator — so all the app is left with here are
/// the margins it has standing up.
class PortraitLock extends StatelessWidget {
  const PortraitLock({required this.child, this.rotation = displayRotation, super.key});

  final Widget child;

  /// Where the display's rotation is read from.
  ///
  /// It is a parameter for one reason: `flutter test` has no display to turn, so a test that wants
  /// to be a phone on its side has to say so.
  final int? Function() rotation;

  /// How far to turn the app back, in quarter turns clockwise.
  ///
  /// On a phone the window has already answered the question: it is lying down, so the phone was
  /// laid down, and the app is turned back whatever the browser says about itself. It is worth
  /// being that blunt — Safari's Screen Orientation API disagrees with Android's about which
  /// landscape is which, and has been reported answering nothing at all before 16.4 — and the cost
  /// of reading it wrong is an app on its side either way, never a broken layout.
  ///
  /// The angle is used for the one thing left: which way. And where the thing being looked at is
  /// **not** a phone — a desktop window that happens to be short and wide — nothing is turned
  /// unless the screen itself is turned, which a desktop's never is.
  static int quarterTurnsFor(int? rotation, {required bool onAPhone}) {
    if (onAPhone) return rotation == 270 ? 1 : 3;
    return switch (rotation) {
      90 => 3,
      270 => 1,
      _ => 0,
    };
  }

  /// Whether the app is being held upright on a phone that was laid down.
  ///
  /// Asked by whatever has to be measured differently in that shape — the nav capsule, so far.
  /// Nothing below here can work it out for itself: the whole point of the lock is that what is
  /// under it reads a portrait window and knows nothing about the turn.
  static bool turned(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Turned>() != null;

  /// Whether this is a screen that can be turned at all.
  ///
  /// It is the one question in the web build that the *window* cannot answer, and the only one
  /// asked of the platform: how wide the window is says nothing about whether somebody can lay the
  /// screen on its side.
  static bool get _onAPhone => switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.android => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Only a phone lying on its side has anything to undo, and the page has to agree it is lying
    // down: a display can report 90 while the window is a portrait strip beside something else.
    if (media.size.width <= media.size.height) return child;

    final turns = quarterTurnsFor(rotation(), onAPhone: _onAPhone);
    if (turns == 0) return child;

    return MediaQuery(
      // The app is told the screen it is being laid out on, which is the window with its sides
      // swapped — everything from where a line of lyrics wraps to whether the sheet scrolls reads
      // this and would otherwise read the landscape it is not being drawn in.
      data: media.copyWith(
        size: Size(media.size.height, media.size.width),
        padding: _turned(media.padding, turns),
        viewPadding: _turned(media.viewPadding, turns),
        viewInsets: _turned(media.viewInsets, turns),
      ),
      child: RotatedBox(
        quarterTurns: turns,
        child: _Turned(child: child),
      ),
    );
  }

  /// The window's insets, seen from the app once it has been turned: the notch and the keyboard do
  /// not move, so which edge of the app they are on changes with the turn.
  static EdgeInsets _turned(EdgeInsets insets, int turns) => switch (turns) {
    1 => EdgeInsets.fromLTRB(insets.top, insets.right, insets.bottom, insets.left),
    3 => EdgeInsets.fromLTRB(insets.bottom, insets.left, insets.top, insets.right),
    _ => insets,
  };
}

/// Says, to anything that asks, that the app above it was turned back. See [PortraitLock.turned].
class _Turned extends InheritedWidget {
  const _Turned({required super.child});

  // It is either there or it is not; there is nothing about it that can change while it stands.
  @override
  bool updateShouldNotify(_Turned oldWidget) => false;
}
