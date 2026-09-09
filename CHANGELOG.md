## 0.2.1

- `KeyboardInset` brings the field being typed into up above the keys, which making the room does
  not do on its own: the framework's own scroll is wired to the *view's* insets, and those are the
  ones the engine will not report. A field left under the keyboard is also what makes iOS scroll
  the page to reveal the browser's input element, which slid the app off the top of the screen and
  dismissed the keyboard at the first drag — so the page is put back too.
- The `MediaQuery` it writes now stands whether or not the keyboard is up. Dropping it while there
  was nothing to say changed the depth of the tree the moment there was, so everything under it was
  rebuilt from nothing and the focus went with it: the keyboard opened and closed again.

## 0.2.0

- `KeyboardInset`, the on-screen keyboard handed to the app as `MediaQuery.viewInsets` where the
  engine will not: a page hosted in an element of its own is told the keyboard is zero points tall
  and never asked again, so a field tapped near the bottom of the screen stayed under the keys with
  nothing in the app able to know.
- `PhoneSafeArea` takes whatever the keyboard covers off the strips the app lays out against, so
  the home indicator's 34 points stop standing between a field and the keys.

## 0.1.0

First cut, lifted out of [Vibra](https://caiomourasud.github.io/vibra-web/), where every piece of
it was written against a real app and a real phone.

- `PhoneOnTheWeb`, the whole contract as one `builder`: the frame on a desk-sized window, the
  phone shape everywhere else.
- `PhoneFrame`, an iPhone 17 Pro to the tenth of a point, off Apple's own dimensional drawing, and
  the app inside it told the truth about the screen it is on.
- The mouse arriving as a finger: no hover, drag to scroll, and a fingertip drawn where the arrow
  was — pressed states included, so a screen recording shows the taps.
- `PhoneSafeArea`, the home indicator's strip a phone browser will not report.
- `PortraitLock`, the app held upright when the page turns with the phone.
