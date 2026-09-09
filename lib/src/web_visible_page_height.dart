import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// What the browser is still showing of the page, while a field is being typed into.
///
/// This is `window.visualViewport`, and it is the only thing that knows the keyboard is there. The
/// keyboard does not resize the page: the **layout** viewport — what `100vh` measures, and what
/// Flutter is laid out in — stays the full height of the screen, and the **visual** one shrinks to
/// what is left above the keys.
///
/// Flutter reads it by itself for a page that fills the window. It does not for a page hosted in an
/// element of its own, which is what `_flutter.loader.load({config: {hostElement: ...}})` asks for:
/// there the engine watches that element with a `ResizeObserver` and answers a flat zero for the
/// keyboard — `CustomElementDimensionsProvider.computeKeyboardInsets` returns
/// `ViewPadding(bottom: 0, ...)`, and no resize of the host ever happens to ask it again, because a
/// host pinned at `100vh` is exactly the thing the keyboard does not resize. So the app is never
/// told: the `Scaffold` does not shrink, `EditableText` has nowhere to scroll the caret to, and the
/// field being typed into stays under the keys. That is the hole this fills.
///
/// **Only while a field has focus**, which is the condition the engine puts on it too. Without that
/// the number answers a second question at the same time: in a browser tab the visual viewport is
/// also short of the layout one by whatever Safari's toolbar is taking, and a page that asked for
/// the whole screen would sit permanently inset by a strip that is not a keyboard.
ValueListenable<double?> visiblePageHeight() {
  final viewport = web.window.visualViewport;
  // Nothing to read, and nothing that will ever change it: whatever reads this is left with the app
  // as the browser laid it out. Safari has had the API since 13, so this is the old-browser branch.
  if (viewport == null) return _visible;
  if (!_listening) {
    _listening = true;
    final read = ((web.Event _) {
      putThePageBack();
      _visible.value = _read(viewport);
    }).toJS;
    viewport.addEventListener('resize', read);
    // The keyboard covers the page, and iOS may also slide it to bring the field into what is
    // left — a scroll of the visual viewport, with no resize of anything.
    viewport.addEventListener('scroll', read);
    _visible.value = _read(viewport);
  }
  return _visible;
}

/// Read once and kept, because there is only one page: a notifier per caller would be a listener
/// per caller on the same two events.
final ValueNotifier<double?> _visible = ValueNotifier<double?>(null);

bool _listening = false;

double? _read(web.VisualViewport viewport) {
  if (!_typing()) return null;
  final scale = viewport.scale;
  // A page the browser is not showing at all answers zero to everything (`0` is what the API says
  // for a document that is not fully active), and zero here would read as the keyboard covering the
  // whole app.
  if (viewport.height <= 0 || scale <= 0) return null;
  // A pinch-zoomed page has a smaller visual viewport for a reason that has nothing to do with the
  // keyboard, and `height` shrinks with the zoom. Multiplying it back by the scale answers the one
  // question being asked — how much of the page is still on screen — zoomed or not.
  return viewport.height * scale;
}

/// Whether there is a field being typed into.
///
/// Flutter's own text input is a real `<input>` or `<textarea>`, and it is put in the light DOM —
/// `<flt-text-editing-host>` hangs off the view's root element, not off its shadow root — so it is
/// what `document.activeElement` answers with while the app is editing.
bool _typing() {
  final active = web.document.activeElement;
  if (active == null) return false;
  return active.tagName == 'INPUT' || active.tagName == 'TEXTAREA';
}

/// Undoes the scroll iOS does when the keyboard comes up over the field being typed into.
///
/// iOS answers an input under the keyboard by scrolling the page up to reveal it, and stays there.
/// The keyboard does not shorten the layout viewport, which is what the app is drawn in, so that
/// scroll takes the top of the app off the screen and reveals its own background past the end of
/// its content along the bottom — the app looking like it slid, when all that moved was the page
/// around it.
///
/// The page a Flutter app is hosted in has nothing of its own to scroll, so putting it back costs
/// nothing. The check is what keeps this from answering its own event, and what leaves alone every
/// browser that never did it.
///
/// It is the second half of a pair: [KeyboardInset.reveal] is what stops iOS from wanting to
/// scroll in the first place, by bringing the field above the keys where it can see it.
void putThePageBack() {
  if (web.window.scrollY != 0) web.window.scrollTo(0.toJS, 0);
}
