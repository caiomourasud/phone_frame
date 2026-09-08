# phone_frame

On a computer, a Flutter web app drawn inside an iPhone **and touched like one**. On a phone's own
browser, the same app bare and edge to edge, with the insets the browser withholds and held upright
when the page turns.

```dart
MaterialApp(
  builder: PhoneOnTheWeb.builder,
  home: const MyApp(),
)
```

That is the whole setup. Nothing in `main`, nothing per screen.

## Setting it up in a new app

```yaml
# pubspec.yaml
environment:
  sdk: ^3.11.0          # the package needs it

dependencies:
  phone_frame:
    git:
      url: https://github.com/caiomourasud/phone_frame.git
      ref: main
```

> `ref: main` names a branch, but `pubspec.lock` pins the **commit** it resolved to the day the
> dependency went in, and `pub get` honours the lock. An app that took the package before a change
> here keeps the old one indefinitely, and the symptom is not a version error — it is a feature
> quietly not being there. One app's content collided with the clock for a whole round of debugging
> because its lock predated the commit that taught `PhoneSafeArea` about the top; everything else in
> the recipe was already right. `flutter pub upgrade phone_frame` is what moves it, and
> `grep -c safe-area-inset-top build/web/main.dart.js` says whether the reader actually shipped.

```dart
MaterialApp(
  builder: PhoneOnTheWeb.builder,   // or PhoneOnTheWeb(desk:, homeIndicator:, child:) for colours
  ...
)
```

That is everything for the frame, the touch and the home indicator. Two more things are the app's,
not the package's:

1. **To draw under the clock**, `web/index.html` has to ask for the screen — see
   [Drawing under the clock](#drawing-under-the-clock-what-indexhtml-has-to-say). Skip it and the
   app simply keeps the system's strip; nothing breaks.
2. **Build with `--pwa-strategy=none` while you are working on `index.html`.** Flutter's service
   worker caches that file, so an installed copy keeps serving the old one — a fix can be deployed,
   verified on the server, and still not be what the phone is running. It cost several rounds of
   chasing the wrong cause in two apps before anyone suspected it. Keep this in `index.html` too,
   for the copies installed while there still was a worker:

   ```html
   <script>
     if ('serviceWorker' in navigator) {
       navigator.serviceWorker.getRegistrations()
         .then(function (all) { all.forEach(function (one) { one.unregister(); }); });
     }
   </script>
   ```

## Why

A phone app stretched across a monitor is not a preview of anything: a chord sheet a metre wide,
with the controls off to one side. Drawing a bezel around that layout would only be a nicer lie.

So the frame does two things a picture cannot:

- **The app is told it is on the phone.** Inside the frame `MediaQuery` reports 402 × 874 points and
  the iPhone's safe area — so the page shows what a phone would show, down to where a line of text
  wraps.
- **It is touched like the phone.** Every mouse event reaches the framework as a **touch**: nothing
  hovers, a drag scrolls, a list bounces at the end, and the arrow becomes a fingertip on the glass
  — pressed states included, so a screen recording shows the taps.

And below the frame's threshold, where the app really is on a phone, it does the opposite: gives
back the home indicator's strip that no browser reports, and holds the app upright when the phone is
laid on its side.

> Not to be confused with [`device_preview`](https://pub.dev/packages/device_preview), which frames
> many devices behind a settings panel. This is one phone, no UI of its own, and the touch and the
> orientation are the point rather than the frame.

## The two shapes

| Window | What is drawn | Where it is decided |
|---|---|---|
| Shortest side ≥ 600 | The app inside an iPhone, centred, scaled to fit, touched like one | `PhoneFrame` |
| Shortest side < 600 | The app edge to edge, held upright, plus the missing safe area | `PhoneSafeArea`, `PortraitLock` |

The line is `framesTheApp(Size)`, measured on the **window** and never on the user agent: a browser
squeezed into half a laptop gets the whole width, and a phone in landscape stays unframed. On
Android and iOS the builder hands the child straight back — none of this belongs on a device that
really is one.

## The phone is Apple's phone

Everything the frame draws comes off Apple's own
[dimensional drawing](https://developer.apple.com/accessories/dimensional-drawings/) for the
iPhone 17 Pro, through one number:

```dart
static const double pointsPerMillimetre = 874 / 144.73;   // 6.0388
```

The drawing gives the display's active area as 66.57 × 144.73 mm, and that area **is** 402 × 874
points — both sides agree to five decimals, which is what makes the rest a multiplication:

| From the drawing | mm | Drawn as |
|---|---|---|
| Housing | 71.85 × 150.01 | `PhoneFrame.bodySize`, 433.9 × 905.8 pt |
| Housing to first lit pixel | 2.64 | `PhoneFrame.edge`, 15.9 pt — 1.44 of black glass, 1.20 of metal |
| Action button, centre below the top | 34.28, 6.90 long | a `PhoneButton` |
| Volume up / down | 48.43 and 62.63, 11.20 long | two more |
| Side button | 55.53, 17.70 long | one on the other side |
| How far a button stands out | 0.45 | `_rise` |
| Dynamic Island | 20.76 × 6.07, lower edge 7.99 below the first pixel | drawn over the screen |

A test holds the two things that can drift: the housing's proportions, and each button's centre and
length in millimetres.

## What you get, piece by piece

- **`PhoneOnTheWeb`** — the contract as one `builder`. Everything below is exported too, for an app
  that wants a piece on its own.
- **`PhoneFrame`** — the phone, and the honest `MediaQuery` inside it. Takes `desk` and
  `homeIndicator` colours; without them it reads the ambient theme's brightness.
- **`TouchEmulation`** — the mouse rewritten as a finger, wrapping
  `PlatformDispatcher.onPointerDataPacket` before the framework sees it. It installs itself the
  first time a frame goes on screen, and is on only while one is.
- **`TouchDot`** — the fingertip, and the page's cursor while the pointer is over the glass. Off the
  glass the arrow comes straight back.
- **`PhoneSafeArea`** — the home indicator's 34 points, which a phone browser knows about and does
  not pass on. Only ever *added* to what the browser reports, only in portrait, and never at the top
  (iOS keeps that strip itself).
- **`PortraitLock`** — the app laid out in portrait and turned back by however far the display was
  turned, which is what a locked native app looks like once the phone is sideways: nothing reflows.

## Drawing under the clock: what `index.html` has to say

The package can put the app under the clock, but it cannot ask for the room — that is a handful of
lines of `web/index.html` plus a templated `flutter_bootstrap.js`, and without them the browser
keeps the strip and paints it itself.

```html
<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
```

```css
/* NOT `height: 100%`. Under `cover`, `100%` does not count the area behind the status bar: the
   document comes out shorter than the screen and a band of background is left along the bottom.
   `100vh` is already the whole screen here — do not add `env(safe-area-inset-top)` on top of it,
   which overshoots and pushes anything anchored to the bottom off the edge. */
html, body { margin: 0; padding: 0; height: 100vh; }

/* An element of the app's own for the Flutter view to live in. */
#flutter-host { position: fixed; top: 0; left: 0; right: 0; height: 100vh; }
```

That last one is not decoration. Handed a host, the engine measures **that element**, through a
`ResizeObserver` on it; handed nothing, it measures `documentElement.clientHeight`, which under
`cover` leaves out the strip behind the status bar and reports a viewport shorter than the screen.
So the host is named where the loader is called, which means the bootstrap is the app's rather than
the default one:

```js
// web/flutter_bootstrap.js — the two tokens are substituted at build time
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {hostElement: document.querySelector('#flutter-host')},
});
```

```html
<!-- web/index.html, in the body: the host, then that file inlined -->
<div id="flutter-host"></div>
<script>{{flutter_bootstrap_js}}</script>
```

Then [PhoneSafeArea] reads `env(safe-area-inset-top)` and hands the app the inset, so the content
clears the clock while the background runs behind it. An app that skips this sees no change: without
`cover` the value is zero and nothing is inset.

One thing the engine undoes on the way in: **Flutter removes every viewport meta on the page and
writes its own, which has no `viewport-fit`.** Putting it back from Dart is too late — the engine
measures the page during initialization, before `main` — so it goes back the moment the engine's
meta appears:

```html
<script>
  new MutationObserver(function () {
    var m = document.querySelector('meta[name="viewport"]');
    if (m && m.content.indexOf('viewport-fit') === -1) {
      m.content += ', viewport-fit=cover';
    }
  }).observe(document.head, {childList: true, subtree: true, attributes: true});
</script>
```

And the trade to know before taking it: `black-translucent` hands the strip to the app, so the app's
own colour runs up under the clock and there is no band of a different colour to match. iOS draws
the clock over it and picks no background of its own, which is the point. With `default` instead,
iOS keeps the strip and paints it the `theme-color` meta — it reads that **once, at launch**, and
ignores every change made afterwards, so an app whose theme the user can switch is stuck with
whichever colour it opened with.

## A bottom bar that touches the edge

`PhoneSafeArea` hands the app 34 points along the bottom — the home indicator's strip, which a phone
browser knows about and does not pass on. What the app owes in return depends on the shape of its
bottom bar, and only one of the two shapes owes nothing.

A bar that **floats** — a pill with a margin around it — is already clear of the indicator. The
margin is the clearance, the page shows underneath, and there is nothing to do. This is the shape
the package was written against, so it is the shape that never revealed the rest of this section.

A bar that **touches the bottom edge** has to spend those points itself, and in two parts:

- its **background** runs all the way down, so the colour reaches the end of the screen;
- its **content** stops 34 points short, so no tab lands under the white line the system draws over
  everything.

Which is a background with an inner padding — not a shorter bar, and not a gap below it:

```dart
DecoratedBox(
  decoration: BoxDecoration(color: barColour),          // reaches the edge
  child: Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
    child: SizedBox(height: 64, child: tabs),           // stops above the indicator
  ),
)
```

Read the inset; do not write `34` down. The same code is then right inside the frame, on the phone,
and on a native build, and it is what a browser that starts reporting the truth would feed.

The result looks wrong in a screenshot before it looks right on glass: a band of flat background
below the tabs, a third of the bar's height, apparently dead. That band is the indicator's, and a
native app reserves exactly the same one — the screenshot just cannot show the line that is about
to be drawn over it.

## Three things a browser will not do, and what happens instead

- **iOS will not lock the orientation.** `lockToPortrait()` is asked for anyway — it is granted to an
  installed copy on Android — but WebKit ships `screen.orientation.lock()` behind an experimental
  flag and ignores the manifest's `orientation`. `PortraitLock` is what actually holds the app
  upright there.
- **Safari keeps a band of its own in landscape.** The page is handed a viewport already clear of the
  notch and the home indicator, which is why `PhoneSafeArea` adds nothing in that shape, and why
  there is black past the edge of the app that no app can draw in.
- **The cursor is CSS, not Flutter.** With no mouse events left, no `MouseRegion` can change one. So
  the arrow is taken away by writing `document.body.style.cursor` directly — the same property, and
  the same *remove it* for the default, that Flutter's own engine uses.

## Coming from an app that already fakes a phone

Most do: a frame with made-up measurements, a hard-coded safe area, a `- 20` in a bottom bar.
[docs/migrating.md](docs/migrating.md) is what to delete, what will look different and why it is
not a regression, and the four things that bite.

## Running the example

```bash
cd example
flutter run -d chrome
```

Resize the window past the threshold and the shape changes under you.

## Where it came from

Every piece of this was written against a real app on a real phone —
[Vibra](https://caiomourasud.github.io/vibra-web/) — and each rule in it exists because something
was wrong first. That history is why the comments say *why* rather than *what*.

MIT.
