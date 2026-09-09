import 'package:flutter/foundation.dart';

/// On the phones the keyboard is already in `MediaQuery.viewInsets` before the app is built, so
/// there is nothing to go and measure and nothing that will ever change. This side of
/// `visible_page_height.dart` exists so that what reads it compiles for the phones too.
ValueListenable<double?> visiblePageHeight() => _nobodyIsSaying;

final ValueNotifier<double?> _nobodyIsSaying = ValueNotifier<double?>(null);
