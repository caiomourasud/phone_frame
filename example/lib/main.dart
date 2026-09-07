import 'package:flutter/material.dart';
import 'package:phone_frame/phone_frame.dart';

/// What `phone_frame` does, in the smallest app that can show it.
///
/// Open it on a computer and the list is inside a phone, on a desk, pressed by a fingertip. Shrink
/// the window past the frame's threshold — or open it on a phone — and the same list is the whole
/// page, upright, clear of the home indicator.
void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'phone_frame',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    // The whole of it. Nothing in `main`, nothing else anywhere.
    builder: PhoneOnTheWeb.builder,
    home: const ExampleList(),
  );
}

class ExampleList extends StatefulWidget {
  const ExampleList({super.key});

  @override
  State<ExampleList> createState() => _ExampleListState();
}

class _ExampleListState extends State<ExampleList> {
  int _pressed = 0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('phone_frame')),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + media.padding.bottom),
          children: [
            // Proof that the app is told the truth about the screen it is on, rather than about
            // the window: on a 1440-wide monitor this still reads 402.0 x 874.0.
            Card(
              child: ListTile(
                title: Text('${media.size.width} x ${media.size.height}'),
                subtitle: Text('safe area: ${media.padding}'),
              ),
            ),
            for (var i = 1; i <= 12; i++)
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('$i')),
                  title: Text('Tap me, and watch the pointer $i'),
                  subtitle: const Text('The dot grows and takes a ring while it is held'),
                  onTap: () => setState(() => _pressed = i),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: media.padding.bottom + 12),
        child: Center(
          child: Text(
            _pressed == 0 ? 'nothing pressed yet' : 'last pressed: $_pressed',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ),
    );
  }
}
