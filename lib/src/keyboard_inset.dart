import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'visible_page_height.dart';

/// The strip the on-screen keyboard covers, handed to the app as `MediaQuery.viewInsets` — and the
/// field being typed into brought up above it.
///
/// A phone hands the keyboard over without being asked, and so does a Flutter page that fills the
/// browser window. A page hosted in an element of its own does not: the engine answers a flat zero
/// for it there, and never re-measures, because the keyboard does not resize the host. What the app
/// is left with is the one thing that looks like nothing being wrong — a field tapped at the bottom
/// of the screen stays under the keys.
///
/// So the number is measured on the page ([visiblePageHeight]) and put where the framework already
/// looks for it. `Scaffold`, `SafeArea` and a bottom sheet reading `MediaQuery.viewInsetsOf` all
/// read that one field, and none of them has to know where it came from.
///
/// **The scroll has to be asked for by hand**, though, and that is the other half of this widget.
/// See [reveal]: the framework's own is wired to the *view's* insets rather than the query's, so
/// making room is not enough on its own.
///
/// It only ever fills in a silence. Whatever the platform did manage to say stands, so an embedding
/// where the engine reports the keyboard properly is left exactly as it was.
class KeyboardInset extends StatefulWidget {
  const KeyboardInset({required this.child, this.visible = visiblePageHeight, super.key});

  final Widget child;

  /// Where "how much of the page is still on screen" is read from.
  ///
  /// It is a parameter for one reason: `flutter test` has no browser to cover half of, so a test
  /// that wants a keyboard has to say so.
  final ValueListenable<double?> Function() visible;

  /// How long the field takes to come up. Short: the keyboard is already on its way, and the two
  /// arriving together is what makes it read as one movement.
  static const Duration revealDuration = Duration(milliseconds: 150);

  /// How much room is asked for around the field on top of the field itself.
  ///
  /// It is `TextField`'s own `scrollPadding`, which is what the framework reveals the caret with
  /// where it does this itself. Without it the field is brought up until it touches the keys, and
  /// what is revealed is the text rather than the field: the bottom of the box it is drawn in
  /// stays under them.
  static const double revealPadding = 20;

  /// How much of an app that tall the keyboard is covering, given what is still on screen.
  ///
  /// Never negative, and never a guess: a page nobody is measuring — null — is not covered at all.
  static double coveredOf(double appHeight, double? visiblePageHeight) {
    if (visiblePageHeight == null) return 0;
    return math.max(0, appHeight - visiblePageHeight);
  }

  /// Brings whatever is being typed into back above the keyboard.
  ///
  /// The framework does this by itself wherever the platform reports the keyboard: `EditableText`
  /// takes the metrics change and scrolls the caret on screen. What it reads is
  /// `View.of(context).viewInsets` — the **view's** own insets, straight from the engine — and not
  /// the `MediaQuery` this widget writes, so where the engine says zero the field never moves.
  ///
  /// And standing still is worse than it sounds, because the browser's own input element does not
  /// move either: iOS answers an input under the keyboard by scrolling the page up to reveal it,
  /// which takes the top of the app off the screen and leaves its background showing along the
  /// bottom, and then dismisses the keyboard at the first drag. All of that is one field that was
  /// never brought up.
  ///
  /// `showOnScreen` is where `EditableText` ends up too, and it reveals as little as it has to: a
  /// field already clear of the keys does not move, and nothing happens at all where there is
  /// nothing scrollable above the field.
  static void reveal() {
    final focused = FocusManager.instance.primaryFocus?.context;
    final field = focused?.findRenderObject();
    if (field == null || !field.attached) return;
    field.showOnScreen(
      rect: field.paintBounds.inflate(revealPadding),
      duration: revealDuration,
      curve: Curves.easeOut,
    );
  }

  @override
  State<KeyboardInset> createState() => _KeyboardInsetState();
}

class _KeyboardInsetState extends State<KeyboardInset> {
  late ValueListenable<double?> _visible;

  /// What the app was told last, so that the keyboard arriving can be told from it leaving: the
  /// field is brought up when the strip grows, and left where it is when the strip goes away.
  double _covered = 0;

  @override
  void initState() {
    super.initState();
    _visible = widget.visible()..addListener(_changed);
  }

  @override
  void didUpdateWidget(KeyboardInset oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible == oldWidget.visible) return;
    _visible.removeListener(_changed);
    _visible = widget.visible()..addListener(_changed);
  }

  @override
  void dispose() {
    _visible.removeListener(_changed);
    super.dispose();
  }

  // The height is read in `build`, where the size to take it off is: what changed here is only
  // that there is something new to read.
  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottom = math.max(
      media.viewInsets.bottom,
      KeyboardInset.coveredOf(media.size.height, _visible.value),
    );
    if (bottom > _covered) {
      // After this frame, because the room the field is being brought into is the room this build
      // is making. Scheduling is all that happens here; nothing in this frame depends on it.
      WidgetsBinding.instance.addPostFrameCallback((_) => KeyboardInset.reveal());
    }
    _covered = bottom;
    // The `MediaQuery` stands whether or not there is anything to add to it, and that is not a
    // detail: dropping it while the keyboard is down and putting it back when the keyboard opens
    // changes the depth of the tree under it, and everything below is rebuilt from nothing —
    // which loses the focus, and with it the keyboard that had just opened.
    return MediaQuery(
      data: bottom == media.viewInsets.bottom
          ? media
          : media.copyWith(viewInsets: media.viewInsets.copyWith(bottom: bottom)),
      child: widget.child,
    );
  }
}
