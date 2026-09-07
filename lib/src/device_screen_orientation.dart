/// On the phones `SystemChrome` locks the app upright in `main` and the system honours it, so
/// there is no turned display to undo and nothing left to ask for. This side of
/// `screen_orientation.dart` exists so that what reads it compiles for the phones as well.
int? displayRotation() => null;

Future<void> lockToPortrait() async {}
