/// A Flutter web app drawn inside an iPhone on a computer, and touched like one.
///
/// The one thing to reach for is [PhoneOnTheWeb], which is the whole contract as a `builder`.
/// Everything else is exported because an app may want a piece on its own — the frame for a
/// screenshot, the lock for a page that is not framed, the emulation's pointer for something drawn
/// over the glass.
library;

export 'src/phone_button.dart';
export 'src/phone_frame.dart';
export 'src/phone_on_the_web.dart';
export 'src/phone_safe_area.dart';
export 'src/portrait_lock.dart';
export 'src/screen_orientation.dart' show displayRotation, lockToPortrait;
export 'src/touch_dot.dart';
export 'src/touch_emulation.dart';
