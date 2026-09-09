import 'package:flutter/foundation.dart';

import 'device_visible_page_height.dart'
    if (dart.library.js_interop) 'web_visible_page_height.dart'
    as platform;

/// How much of the page the browser is still showing, in logical pixels, while a field is being
/// typed into — and a way of being told when that changes.
///
/// It is the on-screen keyboard, seen from the only side a browser shows it from: the keyboard does
/// not resize the page, it covers it, and what is left uncovered is this. Whatever reads it knows
/// how tall the app is and can take the difference; see [KeyboardInset].
///
/// **Null when nobody is saying**, which is every case where the number would be an answer to some
/// other question: on the phones, where the keyboard already reaches `MediaQuery.viewInsets` on its
/// own, and on the web whenever no field has focus. The web side is where the reasons are written
/// down.
ValueListenable<double?> visiblePageHeight() => platform.visiblePageHeight();
