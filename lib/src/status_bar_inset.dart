import 'device_status_bar_inset.dart'
    if (dart.library.js_interop) 'web_status_bar_inset.dart'
    as platform;

/// The strip the clock sits in, when the page is the one drawing under it.
///
/// Zero unless the page asked for the whole screen; see the web side for what that means and why
/// the number answers the question at the same time.
double statusBarInset() => platform.statusBarInset();
