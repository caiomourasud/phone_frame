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
