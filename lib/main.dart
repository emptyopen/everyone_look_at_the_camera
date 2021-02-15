import 'package:everyone_look_at_the_camera/screens/camera.dart';
import 'package:flutter/material.dart';

// TODO:
// make app icon
// publish
// voice recognition, start timer
// make noises consistent (buffer/audio/cache)
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
