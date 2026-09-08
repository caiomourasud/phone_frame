/// On the phones `MediaQuery` already carries the real inset, so there is nothing to go and read.
/// This side of `status_bar_inset.dart` exists so that what reads it compiles for the phones too.
double statusBarInset() => 0;
