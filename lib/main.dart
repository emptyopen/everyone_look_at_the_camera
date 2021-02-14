import 'package:everyone_look_at_the_camera/screens/camera.dart';
import 'package:flutter/material.dart';

// TODO:
// last second sounds
// voice recognition, start timer
// consistent timing of sounds
// download a pic locally
// make noises consistent (buffer/audio/cache)
// exclusive choice of noisy countdown vs last second sound
// last second sound should have a way of getting length of sound, make minimum timer based on it
// need minimum 5 seconds for noisy countdown
// funny image pop up?
// switching to app, camera is frozen

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
