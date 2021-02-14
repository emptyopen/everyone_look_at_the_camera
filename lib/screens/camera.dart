import 'package:everyone_look_at_the_camera/screens/preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:sensors/sensors.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../sound_manager.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController cameraController;
  List cameras;
  int selectedCameraIndex;
  String imgPath;
  bool takingPhoto = false;
  bool portraitAngle = false;
  int countdownTimer = 3;
  int countdownSeconds;
  bool giantNumbersEnabled = true;
  List<bool> noisyCountdown = [true, false, false, false];
  List<bool> lastSecondNoise = [true, false, false];
  List<bool> voiceActivationCapture = [true, false, false];
  List<bool> shutterNoise = [true, false, false];
  Animation<int> flashAnimation;
  AnimationController flashAnimationController;
  List<SoundManager> soundManagers = [
    SoundManager(),
    SoundManager(),
    SoundManager(),
    SoundManager(),
    SoundManager(),
    SoundManager(),
  ];
  List<String> noisyCountdownBeeps = [
    'beep1.wav',
    'beep1.wav',
    'beep1.wav',
    'beep1.wav',
    'beep1.wav',
    'beep2.wav',
  ];
  List<String> noisyCountdownAlarms = [
    'alarm-short-b.wav',
    'alarm-short-b.wav',
    'alarm-short-b.wav',
    'alarm-short-b.wav',
    'alarm-short-b.wav',
    'factory-alarm.wav',
  ];
  List<String> noisyCountdownOrchestra = [
    'plucked1.wav',
    'plucked2.wav',
    'plucked1.wav',
    'string-ending.wav',
    null,
    null,
  ];

  List<double> _accelerometerValues;
  List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];

  @override
  void initState() {
    super.initState();
    availableCameras().then((value) {
      cameras = value;
      if (cameras.length > 0) {
        setState(() {
          selectedCameraIndex = 1;
        });
        initCamera(cameras[selectedCameraIndex]).then((value) {});
      } else {
        print('No camera available');
      }
    }).catchError((e) {
      print('Error : ${e.code}');
    });
    // acceleromter values
    _streamSubscriptions
        .add(accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _accelerometerValues = <double>[event.x, event.y, event.z];
      });
    }));
    // flash
    flashAnimationController = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    flashAnimation =
        IntTween(begin: 0, end: 255).animate(flashAnimationController);
  }

  Future initCamera(CameraDescription cameraDescription) async {
    if (cameraController != null) {
      await cameraController.dispose();
    }

    cameraController =
        CameraController(cameraDescription, ResolutionPreset.high);

    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    if (cameraController.value.hasError) {
      print('Camera Error ${cameraController.value.errorDescription}');
    }

    try {
      await cameraController.initialize();
    } catch (e) {
      showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  onCapture(context) async {
    try {
      final p = await getTemporaryDirectory();
      final name = DateTime.now();
      final path = "${p.path}/$name.png";

      setState(() {
        takingPhoto = true;
      });

      List<String> noisyCountdownSelection;
      if (noisyCountdown[0]) {
        noisyCountdownSelection = [null, null, null, null, null, null];
      } else if (noisyCountdown[1]) {
        noisyCountdownSelection = noisyCountdownBeeps;
      } else if (noisyCountdown[2]) {
        noisyCountdownSelection = noisyCountdownAlarms;
      } else if (noisyCountdown[3]) {
        noisyCountdownSelection = noisyCountdownOrchestra;
      }

      countdownSeconds = countdownTimer + 1;
      const oneSec = const Duration(seconds: 1);
      Timer.periodic(
        oneSec,
        (Timer timer) {
          if (countdownSeconds == 0) {
            setState(() {
              timer.cancel();
            });
          } else {
            setState(() {
              countdownSeconds--;
            });
            if (countdownSeconds <= 5) {
              if (noisyCountdownSelection[5 - countdownSeconds] != null) {
                soundManagers[5 - countdownSeconds]
                    .playLocal(noisyCountdownSelection[5 - countdownSeconds]);
              }
            }
          }
        },
      );

      while (countdownSeconds > 0) {
        await Future.delayed(Duration(milliseconds: 50));
      }

      flashAnimationController.forward();

      await cameraController.takePicture(path).then((value) {
        print(path);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PreviewScreen(
                      imgPath: path,
                      fileName: "$name.png",
                    )));
        flashAnimationController.reverse();
      });
    } catch (e) {
      showCameraException(e);
    }

    setState(() {
      takingPhoto = false;
    });
  }

  Future myLoadAsset(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (_) {
      return null;
    }
  }

  /// Display camera preview
  Widget cameraPreview() {
    if (cameraController == null || !cameraController.value.isInitialized) {
      return Text(
        'loading camera...',
        style: TextStyle(color: Colors.white, fontSize: 20.0),
      );
    }

    return AspectRatio(
      aspectRatio: cameraController.value.aspectRatio,
      child: CameraPreview(cameraController),
    );
  }

  Widget cameraControl(context) {
    return Container(
        width: 100.0,
        height: 100.0,
        child: RawMaterialButton(
          shape: CircleBorder(),
          elevation: 0.0,
          fillColor: Colors.white,
          child: Icon(
            Icons.camera,
            color: Colors.black,
            size: 70,
          ),
          onPressed: () {
            HapticFeedback.vibrate();
            onCapture(context);
          },
        ));
  }

  Widget settingsControl(context) {
    return Expanded(
      child: Align(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            FloatingActionButton(
              heroTag: 'settingsControl',
              child: Icon(
                Icons.settings,
                color: Colors.black,
                size: 40,
              ),
              backgroundColor: Colors.white,
              onPressed: () {
                HapticFeedback.vibrate();
                showDialog<Null>(
                  context: context,
                  builder: (BuildContext context) {
                    return settingsDialog();
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget settingsDialog() {
    var width = MediaQuery.of(context).size.width;
    return StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        title: Text('Camera settings:'),
        backgroundColor: Colors.white.withAlpha(220),
        contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
        content: Container(
          height: 520,
          width: width * 0.95,
          child: ListView(
            children: <Widget>[
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Countdown timer'),
                    SizedBox(width: 10),
                    DropdownButton<int>(
                      value: countdownTimer,
                      // icon: Icon(Icons.arrow_downward),
                      iconSize: 24,
                      elevation: 16,
                      style: TextStyle(color: Colors.deepPurple),
                      underline: Container(
                        height: 2,
                        color: Colors.deepPurpleAccent,
                      ),
                      onChanged: (int newValue) {
                        HapticFeedback.vibrate();
                        setState(() {
                          countdownTimer = newValue;
                        });
                      },
                      items: <int>[0, 3, 5, 10, 15]
                          .map<DropdownMenuItem<int>>((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(
                            '$value',
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Giant numbers'),
                    Switch(
                        value: giantNumbersEnabled,
                        onChanged: (bool newValue) {
                          HapticFeedback.vibrate();
                          setState(() {
                            giantNumbersEnabled = newValue;
                          });
                        }),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text('Noisy countdown'),
                      SizedBox(height: 10),
                      ToggleButtons(
                        children: <Widget>[
                          Icon(
                            Icons.cancel,
                            color: Colors.grey,
                          ),
                          Icon(MdiIcons.pulse),
                          Icon(MdiIcons.bomb),
                          Icon(MdiIcons.violin),
                        ],
                        onPressed: (int index) {
                          HapticFeedback.vibrate();
                          setState(() {
                            for (int buttonIndex = 0;
                                buttonIndex < noisyCountdown.length;
                                buttonIndex++) {
                              if (buttonIndex == index) {
                                noisyCountdown[buttonIndex] = true;
                              } else {
                                noisyCountdown[buttonIndex] = false;
                              }
                            }
                          });
                        },
                        isSelected: noisyCountdown,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text('Last-second noise'),
                      SizedBox(height: 10),
                      ToggleButtons(
                        children: <Widget>[
                          Icon(
                            Icons.cancel,
                            color: Colors.grey,
                          ),
                          Icon(Icons.call),
                          Icon(Icons.cake),
                        ],
                        onPressed: (int index) {
                          HapticFeedback.vibrate();
                          setState(() {
                            for (int buttonIndex = 0;
                                buttonIndex < lastSecondNoise.length;
                                buttonIndex++) {
                              if (buttonIndex == index) {
                                lastSecondNoise[buttonIndex] = true;
                              } else {
                                lastSecondNoise[buttonIndex] = false;
                              }
                            }
                          });
                        },
                        isSelected: lastSecondNoise,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text('Voice activation capture'),
                      SizedBox(height: 10),
                      ToggleButtons(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: Text(
                              'None',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: Text('"capture"'),
                          ),
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: Text('"cheese"'),
                          ),
                        ],
                        constraints: BoxConstraints.loose(Size.fromRadius(150)),
                        onPressed: (int index) {
                          HapticFeedback.vibrate();
                          setState(() {
                            for (int buttonIndex = 0;
                                buttonIndex < voiceActivationCapture.length;
                                buttonIndex++) {
                              if (buttonIndex == index) {
                                voiceActivationCapture[buttonIndex] = true;
                              } else {
                                voiceActivationCapture[buttonIndex] = false;
                              }
                            }
                          });
                        },
                        isSelected: voiceActivationCapture,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text('Shutter noise'),
                      SizedBox(height: 10),
                      ToggleButtons(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: Text(
                              'None',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: Text('"modern"'),
                          ),
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: Text('"retro"'),
                          ),
                        ],
                        constraints: BoxConstraints.loose(Size.fromRadius(150)),
                        onPressed: (int index) {
                          HapticFeedback.vibrate();
                          setState(() {
                            for (int buttonIndex = 0;
                                buttonIndex < shutterNoise.length;
                                buttonIndex++) {
                              if (buttonIndex == index) {
                                shutterNoise[buttonIndex] = true;
                              } else {
                                shutterNoise[buttonIndex] = false;
                              }
                            }
                          });
                        },
                        isSelected: shutterNoise,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          Container(
            child: FlatButton(
              onPressed: () {
                HapticFeedback.vibrate();
                Navigator.of(context).pop();
              },
              child: Text(
                'Done',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget flashBox() {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(flashAnimation.value),
      ),
      child: Text('${flashAnimation.value}'),
    );
  }

  Widget cameraToggle() {
    if (cameras == null || cameras.isEmpty) {
      return Spacer();
    }

    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    CameraLensDirection lensDirection = selectedCamera.lensDirection;

    return Expanded(
      child: Align(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            FloatingActionButton(
              heroTag: 'cameraToggle',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${lensDirection.toString().substring(lensDirection.toString().indexOf('.') + 1).toUpperCase()}',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                  Icon(
                    getCameraLensIcons(lensDirection),
                    color: Colors.black,
                    size: 20,
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              onPressed: () {
                HapticFeedback.vibrate();
                onSwitchCamera();
              },
            )
          ],
        ),
      ),
    );
  }

  Widget countdown() {
    var width = MediaQuery.of(context).size.width;
    if (_accelerometerValues == null) {
      portraitAngle = true;
    } else {
      if (_accelerometerValues[1] > 6 && !portraitAngle) {
        portraitAngle = true;
      }
      if (_accelerometerValues[1] < 4.5 && portraitAngle) {
        portraitAngle = false;
      }
    }
    if (countdownSeconds == null ||
        countdownSeconds == 0 ||
        countdownSeconds > countdownTimer) {
      return Container();
    }
    return Transform.rotate(
      angle: portraitAngle ? 0 : pi / 2,
      child: Text(
        '$countdownSeconds',
        textScaleFactor: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: giantNumbersEnabled
              ? countdownSeconds > 9
                  ? width - 100
                  : width
              : 100,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: cameraPreview(),
            ),
            Align(
              alignment: Alignment.center,
              child: countdown(),
            ),
            Align(
              alignment: Alignment.center,
              child: flashBox(),
            ),
            takingPhoto
                ? Container()
                : Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      padding: EdgeInsets.all(15),
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          cameraToggle(),
                          cameraControl(context),
                          settingsControl(context),
                          // Spacer(),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  getCameraLensIcons(lensDirection) {
    switch (lensDirection) {
      case CameraLensDirection.back:
        return CupertinoIcons.switch_camera;
      case CameraLensDirection.front:
        return CupertinoIcons.switch_camera_solid;
      case CameraLensDirection.external:
        return CupertinoIcons.photo_camera;
      default:
        return Icons.device_unknown;
    }
  }

  onSwitchCamera() {
    selectedCameraIndex =
        selectedCameraIndex < cameras.length - 1 ? selectedCameraIndex + 1 : 0;
    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    initCamera(selectedCamera);
  }

  showCameraException(e) {
    String errorText = 'Error ${e.code} \nError message: ${e.description}';
  }
}
