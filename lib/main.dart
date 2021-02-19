import 'package:everyone_look_at_the_camera/screens/camera.dart';
import 'package:flutter/material.dart';

// TODO:
// fix 10 9 8 for durations other than 10
// move preview buttons up (for iphone only?)
// freeze in landscape, (prevent rotation)
// sound bug - doesn't play more than once unless changing (iphone only?)
// use cooler font for voice activation
// background color for icon
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
