// Flutter's bootstrap, templated so the engine is handed a host element of the
// app's own instead of taking over the document.
//
// Handed a host, the engine measures that element through a ResizeObserver on
// it. Handed nothing, it measures `documentElement.clientHeight` — which, under
// `viewport-fit=cover`, leaves out the strip behind the status bar and reports a
// viewport shorter than the screen.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {hostElement: document.querySelector('#flutter-host')},
});
