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
import 'package:speech_to_text/speech_to_text.dart';

import '../sound_manager.dart';
import 'package:everyone_look_at_the_camera/components/wrap_toggle_text_buttons.dart';
import 'package:everyone_look_at_the_camera/components/lifecycle_event_handler.dart';

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
  List<int> countdownChoices = [0, 3, 5, 7, 10, 15];
  int countdownTimer = 3;
  String countdownMessage;
  int countdownSeconds;
  bool giantNumbersEnabled = true;
  List<bool> noisyCountdown = [true, false, false, false];
  String noisyCountdownMessage;
  List<bool> weirdNoise = [
    true,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false
  ];
  String weirdNoiseMessage;
  List<bool> voiceActivationCapture = [true, false, false];
  List<bool> shutterNoise = [false, true, false, false, false];
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
  SoundManager shutterSoundManager = SoundManager();
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
  List<String> weirdNoiseList = [
    'bell-jingle',
    'boing',
    'change-rattling',
    'disney-chime',
    'electric-jingle',
    'guitar-jingle',
    'ouch',
    'pans-dropping',
    'squeaky-door',
    'synth-jingle',
    'throat-chant',
    'toilet',
  ];
  Map<String, double> weirdNoiseTimeMap = {
    'bell-jingle': 3.6,
    'boing': 2.5,
    'change-rattling': 4.9,
    'disney-chime': 4,
    'electric-jingle': 4.6,
    'guitar-jingle': 4,
    'ouch': 2.4,
    'pans-dropping': 3.8,
    'squeaky-door': 5.0,
    'synth-jingle': 4.6,
    'throat-chant': 6.1,
    'toilet': 3.9,
  };
  List<double> _accelerometerValues;
  List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];
  SpeechToText speech = SpeechToText();
  String transcription = '';

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
    // resume camera
    WidgetsBinding.instance.addObserver(
      LifecycleEventHandler(
        resumeCallBack: () async => setState(() {
          cameraController.initialize();
        }),
      ),
    );
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
      final name = 'ELATC-' +
          DateTime.now()
              .toString()
              .replaceAll(' ', 'T')
              .replaceAll(':', '-')
              .replaceAll('.', '-');
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

      DateTime startTime = DateTime.now();

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
      bool weirdNoiseStarted = false;
      while (countdownSeconds > 0) {
        // check if weird noise should be played
        if (!weirdNoise[0]) {
          double elapsedSeconds = DateTime.now()
                  .difference(startTime.add(Duration(seconds: 1)))
                  .inMilliseconds /
              1000.0;
          double remainingSeconds = countdownTimer.toDouble() - elapsedSeconds;
          String weirdNoiseName = weirdNoiseList[weirdNoise.indexOf(true) - 1];
          if (!weirdNoiseStarted &&
              weirdNoiseTimeMap[weirdNoiseName] > remainingSeconds) {
            soundManagers[0].playLocal('$weirdNoiseName.wav');
            weirdNoiseStarted = true;
          }
        }

        await Future.delayed(Duration(milliseconds: 200));
      }

      flashAnimationController.forward();

      if (shutterNoise[1]) {
        shutterSoundManager.playLocal('camera-dslr.wav');
      } else if (shutterNoise[2]) {
        shutterSoundManager.playLocal('camera-modern.wav');
      } else if (shutterNoise[3]) {
        shutterSoundManager.playLocal('camera-minolta.wav');
      } else if (shutterNoise[4]) {
        shutterSoundManager.playLocal('camera-polaroid.wav');
      }

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

  clearMessagesExcept(String section) {
    if (section != 'countdown') {
      countdownMessage = null;
    }
    if (section != 'noisyCountdown') {
      noisyCountdownMessage = null;
    }
    if (section != 'weirdNoise') {
      weirdNoiseMessage = null;
    }
  }

  setToNone(list) {
    list[0] = true;
    for (int i = 1; i < list.length; i++) {
      list[i] = false;
    }
  }

  statusListener(status) {
    print('listening status: $status');
  }

  errorListener(error) {
    print('listening error: $error');
  }

  resultListener(result) {
    setState(() {
      transcription = result.recognizedWords;
      if (result.recognizedWords.last == 'strawberry') {
        speech.stop();
      }
      if (result.finalResult) {
        print('listening complete');
        // failed to find
      }
    });
  }

  recognizeSpeech() async {
    bool available = await speech.initialize(
        onStatus: statusListener, onError: errorListener);
    if (available) {
      setState(() {
        transcription = '';
      });
      speech.listen(
        onResult: resultListener,
        // --- this doesn't seem to be working
        --
        listenFor: Duration(seconds: 30),
      );
    } else {
      print("The user has denied the use of speech recognition.");
    }
  }

  voiceRecognition() {
    List words = transcription.split(' ');
    String partialTranscription =
        words.sublist(max(0, words.length - 3), words.length).join(' ');
    // String partialTranscription = 'lol';
    return Container(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('voice recognition'),
          FlatButton(
              onPressed: () {
                recognizeSpeech();
              },
              child: Text('start')),
          Text(
            partialTranscription.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              color: Colors.white,
            ),
          ),
        ],
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
          height: 320,
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Countdown timer'),
                        SizedBox(width: 10),
                        DropdownButton<int>(
                          value: countdownTimer,
                          iconSize: 24,
                          elevation: 16,
                          style:
                              TextStyle(color: Theme.of(context).accentColor),
                          underline: Container(
                            height: 2,
                            color: Theme.of(context).accentColor,
                          ),
                          onChanged: (int newValue) {
                            HapticFeedback.vibrate();
                            setState(() {
                              countdownTimer = newValue;
                              // clear messages in other sections
                              clearMessagesExcept('countdown');
                              if (!noisyCountdown[0] && countdownTimer < 5) {
                                setToNone(noisyCountdown);
                                countdownMessage = 'Disabled noisy countdown.';
                              } else if (!weirdNoise[0]) {
                                String weirdNoiseName = weirdNoiseList[
                                    weirdNoise.indexOf(true) - 1];
                                if (countdownTimer <
                                    weirdNoiseTimeMap[weirdNoiseName])
                                  setToNone(weirdNoise);
                                countdownMessage = 'Disabled weird noise.';
                              } else {
                                countdownMessage = null;
                              }
                            });
                          },
                          items: countdownChoices
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
                    countdownMessage != null
                        ? Column(
                            children: [
                              Text(
                                countdownMessage,
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 5),
                            ],
                          )
                        : Container(),
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
                      noisyCountdownMessage != null
                          ? Column(
                              children: [
                                SizedBox(height: 5),
                                Text(
                                  noisyCountdownMessage,
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          : Container(),
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
                            // clear messages in other sections
                            clearMessagesExcept('noisyCountdown');
                            // if selected
                            if (!noisyCountdown[0]) {
                              // ensure countdown timer is at least 5
                              // if less than 5, set to 5 and set message
                              if (countdownTimer < 5) {
                                countdownTimer = 5;
                                noisyCountdownMessage =
                                    'Minimum timer set to 5.';
                              } else {
                                noisyCountdownMessage = null;
                              }
                              // ensure weird noise is not enabled
                              // if enabled, disable and set message
                              if (!weirdNoise[0]) {
                                setToNone(weirdNoise);
                                String disableWeirdNoiseMessage =
                                    'Disabled weird noise.';
                                if (noisyCountdownMessage == null) {
                                  noisyCountdownMessage =
                                      disableWeirdNoiseMessage;
                                } else {
                                  noisyCountdownMessage +=
                                      '\n' + disableWeirdNoiseMessage;
                                }
                              }
                            } else {
                              noisyCountdownMessage = null;
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
                      Text('Weird noise'),
                      weirdNoiseMessage != null
                          ? Column(
                              children: [
                                SizedBox(height: 5),
                                Text(
                                  weirdNoiseMessage,
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          : Container(),
                      SizedBox(height: 10),
                      WrapToggleTextButtons(
                        textList: [
                          'None',
                          'Bell',
                          'Boing',
                          'Change',
                          'Disney',
                          'Electric',
                          'Guitar',
                          'Ouch',
                          'Pans',
                          'Squeak',
                          'Synth',
                          'Mongol',
                          'Toilet',
                        ],
                        isSelected: weirdNoise,
                        onPressed: (int index) {
                          HapticFeedback.vibrate();
                          setState(() {
                            for (int buttonIndex = 0;
                                buttonIndex < weirdNoise.length;
                                buttonIndex++) {
                              if (buttonIndex == index) {
                                weirdNoise[buttonIndex] = true;
                              } else {
                                weirdNoise[buttonIndex] = false;
                              }
                            }
                            // clear messages in other sections
                            clearMessagesExcept('weirdNoise');
                            // if selected
                            if (!weirdNoise[0]) {
                              // TODO: ensure countdown timer is at mapped duration

                              String weirdNoiseName =
                                  weirdNoiseList[weirdNoise.indexOf(true) - 1];
                              double weirdNoiseDuration =
                                  weirdNoiseTimeMap[weirdNoiseName];
                              if (countdownTimer < weirdNoiseDuration) {
                                int minRequiredCountdown = 0;
                                countdownChoices.reversed.forEach((v) {
                                  if (v > weirdNoiseDuration) {
                                    minRequiredCountdown = v;
                                  }
                                });
                                countdownTimer = minRequiredCountdown;
                                weirdNoiseMessage =
                                    'Minimum timer set to $minRequiredCountdown.';
                              } else {
                                weirdNoiseMessage = null;
                              }
                              // ensure noisy countdown is not enabled
                              // if enabled, disable and set message
                              if (!noisyCountdown[0]) {
                                setToNone(noisyCountdown);
                                String disableNoisyCountdownMessage =
                                    'Disabled noisy countdown.';
                                if (weirdNoiseMessage == null) {
                                  weirdNoiseMessage =
                                      disableNoisyCountdownMessage;
                                } else {
                                  weirdNoiseMessage +=
                                      '\n' + disableNoisyCountdownMessage;
                                }
                              }
                            } else {
                              weirdNoiseMessage = null;
                            }
                          });
                        },
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
                      WrapToggleTextButtons(
                        textList: [
                          'None',
                          '"cherry tomatoes"',
                          '"capture"',
                        ],
                        isSelected: voiceActivationCapture,
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
                      WrapToggleTextButtons(
                        textList: [
                          'None',
                          '"dslr"',
                          '"modern"',
                          '"minolta"',
                          '"polaroid"',
                        ],
                        isSelected: shutterNoise,
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
                clearMessagesExcept('');
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

  addFieldValue(fields, values, field, value) {
    fields.add(Container(
      height: 20,
      child: Center(
        child: Text(
          '$field',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ),
    ));
    values.add(Container(
      height: 20,
      child: Center(
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    ));
  }

  settingsPreview() {
    List<Widget> fields = [];
    List<Widget> values = [];
    addFieldValue(fields, values, 'COUNTDOWN', countdownTimer);
    if (giantNumbersEnabled) {
      addFieldValue(fields, values, 'GIANT', 'ON');
    }
    if (!noisyCountdown[0]) {
      addFieldValue(fields, values, 'NOISY', 'ON');
    }
    if (!weirdNoise[0]) {
      addFieldValue(fields, values, 'WEIRD', 'ON');
    }
    if (!voiceActivationCapture[0]) {
      addFieldValue(fields, values, 'VOICE', 'ON');
    }
    return Transform.rotate(
      angle: portraitAngle ? 0 : pi / 2,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(5),
        ),
        padding: EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: fields,
            ),
            SizedBox(width: 15),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: values,
            ),
          ],
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
            Positioned(
              child: takingPhoto ? Container() : settingsPreview(),
              bottom: portraitAngle ? 140 : 160,
              right: 20,
            ),
            Align(
              alignment: Alignment.center,
              child: voiceRecognition(),
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
