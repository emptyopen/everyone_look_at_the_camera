import 'package:everyone_look_at_the_camera/screens/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// TODO:
// ensure that if there is a camera error, re-init camera? (prevent "camera loading" stuck)
// freeze in landscape, (prevent rotation)
// BIG: multiple photos in succession, preview needs to have scrolling views of the photos
// fix 10 9 8 for durations other than 10
// move preview buttons up (for iphone only?)
// sound bug - doesn't play more than once unless changing (iphone only?)
// use cooler font for voice activation
// background color for icon
// make noises consistent (buffer/audio/cache)
// look at front facing flash, or white screen flash
// possible: funny image pop up?

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled) {
    print('crash enabled');
  } else {
    print('crash disabled');
  }
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
