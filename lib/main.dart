import 'package:everyone_look_at_the_camera/screens/camera.dart';
import 'package:flutter/material.dart';

// TODO:
// last second sounds
// last second sound should have a way of getting length of sound, make minimum timer based on it
// voice recognition, start timer
// make noises consistent (buffer/audio/cache)
// funny image pop up?
// switching to app, camera is frozen
// bool saved state in preview, confirm on back that photo will be deleted
// multiple photos in succession, preview needs to have scrolling views of the photos

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
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
