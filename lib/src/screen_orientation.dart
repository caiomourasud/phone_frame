import 'device_screen_orientation.dart'
    if (dart.library.js_interop) 'web_screen_orientation.dart'
    as platform;

/// How far the display is turned from the device's natural orientation, in degrees.
///
/// On a phone the natural orientation is portrait, so 90 or 270 is a phone lying on its side and
/// the page turned with it. It is what [PortraitLock] uses to decide which way to turn it back.
///
/// It comes back **null** where nobody is saying: on the phones, where the app is locked upright by
/// `SystemChrome` and this question never arises, and in a browser too old to have the Screen
/// Orientation API.
int? displayRotation() => platform.displayRotation();

/// Asks the system to keep the screen upright, and lets it say no.
///
/// This is the real lock — the same thing `SystemChrome.setPreferredOrientations` does on the
/// phones — and on the web it is granted almost nowhere:
///
/// - **An installed copy on Android** gets it, though `manifest.json`'s `"orientation"` already
///   covers that case on its own.
/// - **iOS ships it turned off.** WebKit has had `lock()` since 16.4 but keeps it behind
///   Settings → Safari → Advanced → Experimental Features, and the manifest's `orientation` is one
///   of the members iOS ignores. So on the phone this app is for, this asks and is refused.
/// - **A browser tab** is refused everywhere: the standard only grants the lock to a document in
///   fullscreen or an app installed with a display mode of its own.
///
/// Which is why it is worth asking and never worth relying on: [PortraitLock] is what holds the app
/// upright when the answer is no, and the answer being yes simply means it never has to.
Future<void> lockToPortrait() => platform.lockToPortrait();
