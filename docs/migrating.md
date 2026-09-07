# Migrating an app that already fakes a phone

Most apps that need this have already built half of it: a frame with made-up measurements, a
hard-coded safe area, a `- 20` somewhere in a bottom bar. This is what to keep, what to delete, and
what will bite.

## The shape of the change

```dart
MaterialApp(
  builder: PhoneOnTheWeb.builder,   // or (context, child) => PhoneOnTheWeb(child: child, desk: …)
  ...
)
```

Then **delete**, in this order:

1. **The old frame widget.** Whatever draws the bezel, injects a `MediaQuery` size, and picks a
   threshold. All three are in `PhoneFrame` now, and the threshold is the part most likely to have
   been wrong.
2. **The safe-area hacks.** A hard-coded inset in the app root, a `padding.top` injected for phone
   browsers, a `- 20` in a bottom bar to undo an inset that was too generous. `PhoneSafeArea`
   replaces the lot, and it is deliberately narrower than most hand-rolled versions: **only the
   bottom, only in portrait, and only ever added to what the browser reports.**
3. **Anything in `main`.** The emulation installs itself with the first frame; the orientation lock
   is asked for by `PhoneOnTheWeb`. There is nothing to remember.

## What will look different, and why it is not a regression

- **The phone is an iPhone 17 Pro: 402 × 874 points**, radius 62, safe area 59 top / 34 bottom, and
  a 15.9 pt bezel. Those are Apple's own numbers, not a designer's guess. If your app was being
  previewed at a Pro Max's 440 × 956, every screen gets 38 points narrower — which is the point:
  that is a phone people own. Walk the screens once and look for what was only just fitting.
- **The threshold moves to `shortestSide >= 600`, measured on the window.** A width-only rule frames
  a phone held sideways — a picture of a phone inside a phone — and refuses to frame a narrow
  desktop window that would benefit. This one gets both right.
- **Nothing hovers on the desk shape.** Buttons stop lighting up before they are pressed, a list is
  dragged rather than wheeled, and the arrow becomes a fingertip over the glass. If a feature of
  your app *only* works on hover, that feature does not exist on a phone, and the frame is now
  telling you so.

## Three things it deliberately does not do

- **It does not touch the top inset.** iOS keeps the status bar's strip for itself and hands the page
  what is left, so insetting the top again leaves a band of nothing under the clock. If your app
  injects a top padding on phone browsers, that is the bug this refuses to have — check it on a
  real phone before putting it back.
- **It does not lock iOS.** `lockToPortrait()` is asked for and refused there: WebKit ships
  `screen.orientation.lock()` behind an experimental flag and ignores the manifest's `orientation`.
  `PortraitLock` turns the app back instead, which is what a locked native app looks like once the
  phone is sideways — nothing reflows.
- **It does not draw into the bands Safari keeps.** In landscape the page is handed a viewport
  already clear of the notch and the indicator. That black past the edge of the app is the
  browser's, and no app can paint it.

## What will bite

- **`Color.withValues(alpha:)` replaces the alpha, it does not scale it.** If your palette has
  tokens that are *already* translucent — an 8 % white overlay for surfaces is common — then
  `token.withValues(alpha: 0.7)` is a near-solid colour, not a thinned one. Use an opaque token as
  the base.
- **`SafeArea` goes outside `PortraitLock`, never inside.** Outside, it can see the window's own
  shape (which is how it knows to add nothing in landscape) and the lock turns whatever the browser
  did report along with the app. Inside, it reserves a strip along an edge of the app that has
  nothing on it.
- **A floating bottom bar under `Scaffold.extendBody` leaks its height into modal sheets.** The
  Scaffold hands the bar's height to the body as `MediaQuery.padding.bottom`, which is exactly what
  a list wants as scroll padding — and exactly what a bottom sheet shown from that branch's
  navigator does *not*. Open modals with `useRootNavigator: true`: a modal covers the bar anyway.
- **A deploy is served one load late** if you ship Flutter's service worker. Every fix takes two
  refreshes to appear, and on a page added to the home screen it takes more than that. For a build
  people are reviewing, `--pwa-strategy=none` and a script that unregisters whatever an older
  deploy left behind.

## How to check it

Three window sizes and a phone:

```bash
flutter build web --release
cd build/web && python3 -m http.server 8080
```

- **1440 × 900** — the phone is drawn, centred, and the pointer is a pale circle over the glass and
  an arrow on the desk. Press and hold: the circle grows and takes a ring.
- **500 × 900** — no frame, and the app is the whole page.
- **900 × 500** — no frame either, and nothing is stood on its side: a short, wide *desktop* window
  is not a phone lying down.
- **A phone, turned sideways** — the app stays exactly as it was, lying on its side, with nothing
  reflowed. That is the only check that needs a hand.
