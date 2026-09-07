import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'page_cursor.dart';
import 'touch_emulation.dart' show Fingertip;

/// The pointer, over the phone's screen, drawn as a fingertip.
///
/// It is not decoration on top of a cursor: it **is** the cursor while the pointer is over the
/// glass. The arrow is taken away by hand ([hidePageCursor]) because once the mouse reaches the
/// framework as a finger there are no hover events left for Flutter to change a cursor from — and
/// what replaces it is the pale circle a browser's own device mode draws, roughly the size of the
/// thing that would be pressing the glass.
///
/// It only claims the pointer **inside its own bounds**, which is why it is mounted over the screen
/// and not over the page: on the desk around the phone the arrow comes straight back, the way it
/// does the moment you leave the device panel in a browser's device mode.
///
/// **A press is drawn.** A mouse gives no sign of being held down, and on a screen recording that
/// makes every tap invisible: the sheet just moves. So while the finger is on the glass the dot
/// grows, fills in and takes a ring around it, and lets all three go the moment it lifts.
///
/// It paints over everything and hit-tests to nothing, so it is never in the way of what it is
/// pointing at.
class TouchDot extends LeafRenderObjectWidget {
  const TouchDot({required this.pointer, super.key});

  /// Where the pointer is, in the window's own coordinates, and whether it is pressed:
  /// `TouchEmulation.pointer`.
  final ValueListenable<Fingertip?> pointer;

  @override
  RenderTouchDot createRenderObject(BuildContext context) => RenderTouchDot(pointer: pointer);

  @override
  void updateRenderObject(BuildContext context, RenderTouchDot renderObject) {
    renderObject.pointer = pointer;
  }
}

/// Paints [TouchDot]'s circle, and nothing else, when the pointer moves.
///
/// A widget that rebuilt on every mouse move would take the whole page with it. This listens to the
/// pointer itself, asks only for paint, and is its own layer — so what a moving mouse costs is one
/// circle, not a frame of the app.
///
/// It is also what answers "is the pointer on the glass?", because it is the only thing here that
/// knows where the glass is: the answer is its own bounds, scale of the frame and all.
class RenderTouchDot extends RenderBox {
  RenderTouchDot({required ValueListenable<Fingertip?> pointer}) : _pointer = pointer;

  /// A fingertip, near enough, and the same dot the browser draws. Pressed, it is the fingertip
  /// flattening against the glass.
  static const double _radius = 11;
  static const double _pressedRadius = 14;

  /// How far outside the dot the press shows. Big enough to be seen at half size in a video, and
  /// not so big that it covers what is being pressed.
  static const double _halo = 8;

  /// White reads on a dark screen, the ring reads on a light one, and the pointer travels over
  /// both. Neither colour alone is enough.
  static final Paint _fill = Paint()..color = const Color(0x59FFFFFF);
  static final Paint _pressedFill = Paint()..color = const Color(0x99FFFFFF);
  static final Paint _ring = Paint()
    ..color = const Color(0x40000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  /// Pressed, the dark half of the dot has to carry the change on its own: over a light screen the
  /// fill going brighter reads as *less* ink, not more, so what says "held" there is this ring
  /// closing in around it.
  static final Paint _pressedRing = Paint()
    ..color = const Color(0x73000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  /// The ring the press draws around the dot: white for the dark screens, and dark inside it so it
  /// survives a light one.
  static final Paint _haloRing = Paint()
    ..color = const Color(0x73FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _haloEdge = Paint()
    ..color = const Color(0x33000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  ValueListenable<Fingertip?> get pointer => _pointer;
  ValueListenable<Fingertip?> _pointer;
  set pointer(ValueListenable<Fingertip?> value) {
    if (value == _pointer) return;
    if (attached) _pointer.removeListener(markNeedsPaint);
    _pointer = value;
    if (attached) _pointer.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  /// Where the pointer was last painted in this box, and null when it was not in it at all — which
  /// is also the answer to who owns the cursor: the fingertip in here, or the page's arrow out
  /// there.
  Offset? get onTheGlass => _onTheGlass;
  Offset? _onTheGlass;

  @override
  bool get sizedByParent => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _pointer.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _pointer.removeListener(markNeedsPaint);
    // The frame is going: whatever else happens on this page, it happens with a cursor.
    hidePageCursor(hidden: false);
    super.detach();
  }

  /// The point, if it is on the glass, and null if it is anywhere else.
  Offset? _within(Offset local) =>
      local.dx >= 0 && local.dy >= 0 && local.dx <= size.width && local.dy <= size.height
      ? local
      : null;

  @override
  void paint(PaintingContext context, Offset offset) {
    // Worked out here and not when the pointer moves, because `globalToLocal` reads the chain of
    // transforms above this box and that chain is only true once everything above it has been laid
    // out. Paint is after layout; a pointer that moves while the frame is still being built is not.
    final mark = _pointer.value;
    final was = _onTheGlass;
    _onTheGlass = mark == null ? null : _within(globalToLocal(mark.at));

    // Only on the way in and the way out: this writes to the page's body, and doing it on every
    // mouse move would be a style recalculation for each pixel a mouse travels.
    if ((_onTheGlass == null) != (was == null)) {
      hidePageCursor(hidden: _onTheGlass != null);
    }

    final centre = _onTheGlass;
    if (centre == null || mark == null) return;
    final at = offset + centre;
    final radius = mark.pressing ? _pressedRadius : _radius;
    if (mark.pressing) {
      context.canvas
        ..drawCircle(at, radius + _halo, _haloRing)
        ..drawCircle(at, radius + _halo - 1, _haloEdge);
    }
    context.canvas
      ..drawCircle(at, radius, mark.pressing ? _pressedFill : _fill)
      ..drawCircle(at, radius, mark.pressing ? _pressedRing : _ring);
  }
}
