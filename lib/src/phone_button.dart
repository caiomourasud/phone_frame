import 'package:flutter/material.dart';

/// One of the buttons down the side of the phone, seen from the front.
///
/// All that shows of it is the fraction of a millimetre it stands out of the housing: the rest is
/// behind the body, which is drawn over it. That is also all you see of it in the hand.
class PhoneButton extends StatelessWidget {
  const PhoneButton({required this.length, required this.width, required this.onLeft, super.key});

  /// How long it is along the edge of the phone, in points.
  final double length;

  /// How wide it is drawn, which is what stands out plus what the housing covers.
  final double width;

  /// Which side of the phone it is on: the corner it rounds is the outer one.
  final bool onLeft;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: length,
    decoration: BoxDecoration(
      // A shade off the band's own titanium: on the phone a button is the same metal, and what
      // separates it is the line of shadow around it.
      color: const Color(0xFF3F3F47),
      borderRadius: BorderRadius.horizontal(
        left: Radius.circular(onLeft ? 2 : 0),
        right: Radius.circular(onLeft ? 0 : 2),
      ),
    ),
  );
}
