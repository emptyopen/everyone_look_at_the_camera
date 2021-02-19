import 'package:everyone_look_at_the_camera/screens/camera.dart';
import 'package:flutter/material.dart';

// TODO:
// make sounds be either: countdown or finish
// move settings up (relative to camera buttons)
// move preview buttons up
// soften vibration
// change bomb countdown to 5 4 3 2 1 explosion
// sound bug - doesn't play more than once unless changing
// add random noise
// clarify what different noises do
// maybe consolidate into one type of sound selection
// voice activation text is spazzy
// background color for icon
// text overflow in settings
// allow 3 seconds for noises
// make noises consistent (buffer/audio/cache)
// look at front facing flash, or white screen flash
// BIG: multiple photos in succession, preview needs to have scrolling views of the photos
// possible: funny image pop up?

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Everyone look at the camera',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Rubik',
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CameraScreen(),
    );
  }
}
