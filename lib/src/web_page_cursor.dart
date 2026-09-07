import 'package:web/web.dart' as web;

/// Sets the page's cursor, on the same property the engine itself uses.
///
/// Flutter's own web engine writes `document.body.style.cursor` and *removes* the property for the
/// default arrow rather than naming it, so giving it back is a removal here too — anything else
/// would leave an inline `cursor: default` behind that the engine could no longer override.
void hidePageCursor({required bool hidden}) {
  final body = web.document.body;
  if (body == null) return;
  if (hidden) {
    body.style.cursor = 'none';
  } else {
    body.style.removeProperty('cursor');
  }
}
