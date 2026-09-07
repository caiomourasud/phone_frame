import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// What the browser says about how the screen is turned.
///
/// `screen.orientation` is the only thing that knows, and it is worth the try/catch: Safari only
/// learned the Screen Orientation API in 16.4, and on the ones before it the property is not there
/// at all — reading through it throws rather than answering null. A browser that cannot say is
/// answered with null, and the page is left as it laid itself out.
int? displayRotation() {
  try {
    return web.window.screen.orientation.angle;
  } catch (_) {
    return null;
  }
}

/// Asks the screen to stay upright.
///
/// Both halves of this can fail, and both are the same shrug: a browser with no `lock()` throws on
/// the way in, and one that has it rejects the promise with `NotSupportedError` unless the app is
/// installed or in fullscreen. Neither is worth reporting — nothing the app does next depends on
/// the answer, because the fallback is a widget that reads the window rather than this.
Future<void> lockToPortrait() async {
  try {
    // `portrait` and not `portrait-primary`: upside down is a way of holding a phone, and it is
    // the pair `SystemChrome` is given on the phones.
    await web.window.screen.orientation.lock('portrait').toDart;
  } catch (_) {
    // Refused, which is the usual answer.
  }
}
