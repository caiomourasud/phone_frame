import 'package:web/web.dart' as web;

/// The height of the strip the clock and the battery live in, as CSS knows it.
///
/// It is `env(safe-area-inset-top)`, which is **not zero only when the page asked for the whole
/// screen** — `viewport-fit=cover` in the viewport meta. Without that the browser keeps the strip
/// for itself, hands the page what is left, and answers zero here, which is the right answer: an
/// app that is not drawing under the clock has nothing to clear.
///
/// So the number doubles as the question. A page that owns the strip gets its real height, on
/// whichever phone it is; a page that does not gets nothing added.
///
/// Flutter cannot read this on its own — the value lives in CSS and never reaches `MediaQuery`,
/// which is why an app under `cover` is drawn under the clock with no inset at all until something
/// puts it back. Reading it needs an element to hang the value on, so the measurement is done once
/// and kept: `getComputedStyle` on every build would be paid on every frame of a scroll.
double? _cached;

double statusBarInset() => _cached ??= _read();

double _read() {
  final body = web.document.body;
  if (body == null) return 0;
  final probe = web.document.createElement('div') as web.HTMLElement;
  probe.style.cssText =
      'position:fixed;top:0;left:0;width:0;height:0;'
      'visibility:hidden;pointer-events:none;'
      'padding-top:env(safe-area-inset-top);';
  body.appendChild(probe);
  final value = web.window.getComputedStyle(probe).paddingTop;
  probe.remove();
  return double.tryParse(value.replaceAll('px', '').trim()) ?? 0;
}
