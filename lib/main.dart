import 'package:everyone_look_at_the_camera/screens/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// done:
// custom phrase for speech to text

// TODO:
// "have you brushed your teeth"
// increase phrase max to 10
// fix SpeechRecognitionError msg: error_busy, general flow of speech still has issues
// ensure that if there is a camera error, re-init camera? (prevent "camera loading" stuck)
// play shutter noises when selected

// TODO (maybe):
// create timer bar for voice timeout
// have an arrow point at the camera
// add gesture to swipe on image previews
// move preview buttons up (for iphone only?)
// sound bug - doesn't play more than once unless changing (iphone only?)
// background color for icon
// make noises consistent (buffer/audio/cache)
// look at front facing flash, or white screen flash
// possible: funny image pop up?

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
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
