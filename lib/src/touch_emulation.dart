import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Where the finger is, and whether it is on the glass or only above it.
///
/// The two travel as one value so they cannot disagree: a dot drawn pressed at the position the
/// pointer had a frame ago is the one bug this shape rules out.
typedef Fingertip = ({Offset at, bool pressing});

/// The mouse, turned into a finger — what a browser's own device mode does once you pick a phone.
///
/// Inside the frame the app is already told it is on an iPhone: that screen, that safe area. What
/// it was not told is how it is being touched. A mouse hovers, so every button lit up before
/// anybody pressed it, and a list waited for a wheel instead of a drag. A phone does neither, and
/// a preview that behaves like a desktop answers a question nobody is asking of it.
///
/// So each mouse event is rewritten as a touch on its way into the framework, and the ones a
/// finger cannot produce are dropped. Nothing else in the app has to know: the hover states go out
/// on their own, because the framework's mouse tracker ignores every kind but the mouse, and a
/// drag scrolls because touch is what a `Scrollable` takes a drag from.
///
/// The wheel is left alone. It is not a finger either, but it is how a page is read on a computer,
/// and the browser's device mode keeps it as well.
class TouchEmulation {
  TouchEmulation._();

  /// Where the mouse is, in logical pixels of the window, and null when it is not on the page.
  ///
  /// The hover it comes from never reaches the framework, so no `MouseRegion` can answer this any
  /// more — and something has to, because the arrow is hidden over the glass and the pointer is
  /// drawn by hand. That is `TouchDot`, and this is what it reads: the position to draw at, and
  /// whether to draw it pressed.
  static final ValueNotifier<Fingertip?> pointer = ValueNotifier<Fingertip?>(null);

  /// Puts the rewrite in front of whatever the binding registered for pointer packets.
  ///
  /// **An app never has to call this.** The frame does it the first time it goes on screen, which
  /// is the first moment there is anything to emulate for — and by then the binding exists, which
  /// is the only precondition. It is public because a test needs to be able to say when.
  ///
  /// Installing it does not turn it on: the frame does that, with [takeOver], for exactly as long
  /// as it is on screen.
  static void install() {
    if (_installed) return;
    final binding = PlatformDispatcher.instance.onPointerDataPacket;
    // Nothing registered yet, so there is nothing to hand the events on to. Taking the callback
    // anyway would swallow every touch in the app, which is a worse outcome than doing nothing.
    if (binding == null) return;
    _installed = true;
    PlatformDispatcher.instance.onPointerDataPacket = (packet) {
      if (_framesOnScreen == 0) {
        binding(packet);
        return;
      }
      binding(PointerDataPacket(data: asFinger(packet.data)));
    };
  }

  /// Whether the rewrite is already in front of the binding. Wrapping twice would rewrite the
  /// same packet twice, which is harmless, and would also leak a closure per frame that ever
  /// mounted, which is not.
  static bool _installed = false;

  /// How many phone frames are on screen. It is a count and not a flag because a frame replacing
  /// another is mounted before the old one is disposed, and a flag would end up off with a phone
  /// still on the page.
  static int _framesOnScreen = 0;

  /// Said by the frame when it goes on screen: from here on the mouse is a finger.
  ///
  /// Nothing else says it. The app is only ever touched like a phone where it is *drawn* as one,
  /// and keeping the rule in the frame keeps it from being a second copy of `framesTheApp` that
  /// can disagree with the first.
  static void takeOver() {
    // Here and not in the app's `main`, so that a project using the frame has nothing to remember.
    // Only on the web: on a desktop the frame is a picture for a screenshot, and turning that
    // machine's mouse into a finger would be taking a working pointer away.
    if (kIsWeb) install();
    _framesOnScreen++;
  }

  /// And said again when it leaves, which also puts the pointer away: the circle drawn for it
  /// belongs to the frame, and a mouse is a mouse everywhere else.
  static void handBack() {
    _framesOnScreen--;
    pointer.value = null;
  }

  /// The same packet as a phone would have sent it — and, on the way past, where the mouse was.
  ///
  /// The position is a side effect on purpose: this is the last place in the app where the mouse
  /// still exists as a mouse.
  static List<PointerData> asFinger(Iterable<PointerData> data) {
    final finger = <PointerData>[];
    for (final datum in data) {
      final signal = datum.signalKind ?? PointerSignalKind.none;
      // A real finger, a stylus, a trackpad gesture, a wheel: none of them is the mouse being
      // stood in for. The wheel goes through untouched on purpose, and it keeps its `onRespond`
      // by being the very object the engine sent.
      if (datum.kind != PointerDeviceKind.mouse || signal != PointerSignalKind.none) {
        finger.add(datum);
        continue;
      }
      switch (datum.change) {
        // Hovering belongs to the mouse alone, and dropping it here is what takes the hover state
        // off every button in the app.
        case PointerChange.add:
        case PointerChange.hover:
          _movedTo(datum, pressing: false);
        case PointerChange.remove:
          pointer.value = null;
        // A move only ever arrives with a button held — a mouse moving free of them is a hover —
        // so these two are the finger on the glass, and the other two are it coming off.
        case PointerChange.down:
        case PointerChange.move:
          _movedTo(datum, pressing: true);
          finger.add(_asTouch(datum));
        case PointerChange.up:
        case PointerChange.cancel:
          _movedTo(datum, pressing: false);
          finger.add(_asTouch(datum));
        case PointerChange.panZoomStart:
        case PointerChange.panZoomUpdate:
        case PointerChange.panZoomEnd:
          finger.add(datum);
      }
    }
    return finger;
  }

  static void _movedTo(PointerData datum, {required bool pressing}) {
    final view = PlatformDispatcher.instance.view(id: datum.viewId);
    pointer.value = (
      at: Offset(datum.physicalX, datum.physicalY) / (view?.devicePixelRatio ?? 1),
      pressing: pressing,
    );
  }

  /// The same event with a finger's kind on it.
  ///
  /// Everything the framework reads out of a touch is carried over; what is left behind belongs to
  /// a wheel or a trackpad, and neither of those ever gets this far.
  static PointerData _asTouch(PointerData datum) => PointerData(
    viewId: datum.viewId,
    embedderId: datum.embedderId,
    timeStamp: datum.timeStamp,
    change: datum.change,
    kind: PointerDeviceKind.touch,
    device: datum.device,
    pointerIdentifier: datum.pointerIdentifier,
    physicalX: datum.physicalX,
    physicalY: datum.physicalY,
    physicalDeltaX: datum.physicalDeltaX,
    physicalDeltaY: datum.physicalDeltaY,
    buttons: datum.buttons,
    obscured: datum.obscured,
    synthesized: datum.synthesized,
    pressure: datum.pressure,
    pressureMin: datum.pressureMin,
    pressureMax: datum.pressureMax,
    distance: datum.distance,
    distanceMax: datum.distanceMax,
    size: datum.size,
    radiusMajor: datum.radiusMajor,
    radiusMinor: datum.radiusMinor,
    radiusMin: datum.radiusMin,
    radiusMax: datum.radiusMax,
    orientation: datum.orientation,
    tilt: datum.tilt,
    platformData: datum.platformData,
  );
}
