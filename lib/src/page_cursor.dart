import 'device_page_cursor.dart' if (dart.library.js_interop) 'web_page_cursor.dart' as platform;

/// Takes the page's own cursor away, or gives it back.
///
/// The arrow belongs to the page and not to the app: it is CSS, and once the mouse arrives at the
/// framework as a finger there is nothing left for Flutter to hang a `MouseRegion` on — no hover
/// events, so no cursor changes. So the app asks for it by hand, and asks only where it means it:
/// over the phone's screen, where [TouchDot] is drawing a fingertip in its place. On the desk
/// around the phone the arrow is what a pointer should be.
void hidePageCursor({required bool hidden}) => platform.hidePageCursor(hidden: hidden);
