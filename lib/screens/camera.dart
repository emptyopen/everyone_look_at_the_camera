import 'package:everyone_look_at_the_camera/screens/preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:math';
import 'package:vibration/vibration.dart';
import 'package:sensors/sensors.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../sound_manager.dart';
import 'package:everyone_look_at_the_camera/components/wrap_toggle_text_buttons.dart';
import 'package:everyone_look_at_the_camera/components/lifecycle_event_handler.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  CameraController cameraController;
  List cameras;
  int selectedCameraIndex;
  String imgPath;
  bool takingPhoto = false;
  String angle = 'portrait';
  List<int> countdownChoices = [0, 3, 5, 7, 10, 15];
  int countdownTimer = 3;
  String countdownMessage;
  String countdownNoiseMessage;
  String endingNoiseMessage;
  int countdownSeconds;
  bool giantNumbersEnabled = true;
  List countdownNoises = [
    [true, 'None', []],
    [
      false,
      '10 to 1',
      [
        'countdown-ten',
        'countdown-nine',
        'countdown-eight',
        'countdown-seven',
        'countdown-six',
        'countdown-five',
        'countdown-four',
        'countdown-three',
        'countdown-two',
        'countdown-one',
      ]
    ],
    [
      false,
      'Plucks',
      ['plucked1', 'plucked2']
    ],
    [
      false,
      'Light Ring',
      ['beep1']
    ],
    [
      false,
      'Asteroid Gun',
      ['asteroid-gun']
    ],
    [
      false,
      'Upward Beep',
      ['upward-beep']
    ],
    [
      false,
      'Upward Chime',
      ['up-chime']
    ],
    [
      false,
      'Info Bleep',
      ['info-bleep']
    ],
    [
      false,
      'Sneeze',
      ['sneeze']
    ],
    [
      false,
      'Small Alarm',
      ['alarm-short-b']
    ],
  ];
  List endingNoises = [
    [true, 'None', '', 0.0],
    [false, 'Strings', 'string-ending', 4.0],
    [false, 'Bell', 'bell-jingle', 3.6],
    [false, 'Boing', 'boing', 2.5],
    [false, 'Change', 'change-rattling', 4.9],
    [false, 'Disney', 'disney-chime', 4],
    [false, 'Electric', 'electric-jingle', 4.6],
    [false, 'Guitar', 'guitar-jingle', 4.6],
    [false, 'Ouch', 'ouch', 2.4],
    [false, 'Dropped Pans', 'pans-dropping', 3.8],
    [false, 'Squeaky Door', 'squeaky-door', 5.0],
    [false, 'Synth', 'synth-jingle', 4.6],
    [false, 'Mongol', 'throat-chant', 6.1],
    [false, 'Toilet', 'toilet', 3.9],
    [false, 'Dog', 'dog', 6.0],
    [false, 'Grunt Smash', 'grunt-smash', 3.0],
    [false, 'Fail Horn', 'horn-fail', 3.0],
    [false, 'Mystery', 'mystery', 2],
    [false, 'Vocoder', 'oops-vocoder', 7],
    [false, 'Ship Horn', 'ship-horn', 4],
    [false, 'Splash', 'splash', 2],
    [false, 'Transformer', 'transformer', 4],
    [false, 'Explosion', 'explosion', 1],
  ];
  List voiceActivations = [
    [true, 'None'],
    [false, 'cheese'],
    [false, 'strawberry fields'],
    [false, 'where is daisy'],
    [false, 'treasure chest'],
    [false, 'kangaroo'],
  ];
  List<bool> shutterNoise = [false, true, false, false, false];
  Animation<int> flashAnimation;
  AnimationController flashAnimationController;
  Animation<int> fadeAnimation;
  AnimationController fadeAnimationController;
  SoundManager sampleSoundManager = SoundManager();
  SoundManager endingSoundManager = SoundManager();
  SoundManager shutterSoundManager = SoundManager();
  SoundManager confirmationManager = SoundManager();
  List<double> _accelerometerValues;
  List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];
  SpeechToText speech = SpeechToText();
  String transcription = '';
  String newTranscription = '';
  bool activatedOrGaveUp = false;
  String voiceFontFamily = 'BebasNeue';
  int numPhotos = 1;

  @override
  void initState() {
    super.initState();
    availableCameras().then((value) {
      cameras = value;
      if (cameras.length > 0) {
        setState(() {
          selectedCameraIndex = 1;
        });
        initCamera(cameras[selectedCameraIndex]); //.then((value) {});
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
    flashAnimationController =
        AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    flashAnimation =
        IntTween(begin: 0, end: 255).animate(flashAnimationController);
    // fade
    fadeAnimationController =
        AnimationController(duration: Duration(seconds: 3), vsync: this);
    fadeAnimation =
        IntTween(begin: 200, end: 0).animate(fadeAnimationController);
    // resume camera
    WidgetsBinding.instance.addObserver(
      LifecycleEventHandler(
        resumeCallBack: () async => setState(() {
          cameraController.initialize();
        }),
      ),
    );
    // forced landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  playShutter() {
    if (shutterNoise[1]) {
      shutterSoundManager.playLocal('camera-dslr.wav');
    } else if (shutterNoise[2]) {
      shutterSoundManager.playLocal('camera-modern.wav');
    } else if (shutterNoise[3]) {
      shutterSoundManager.playLocal('camera-minolta.wav');
    } else if (shutterNoise[4]) {
      shutterSoundManager.playLocal('camera-polaroid.wav');
    }
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

  softVibrate() {
    Vibration.vibrate(amplitude: 30, duration: 50);
  }

  onCapture(context) async {
    setState(() {
      takingPhoto = true;
      activatedOrGaveUp = false;
    });

    // speech recognition holding pattern
    DateTime start = DateTime.now();
    if (!voiceActivations[0][0]) {
      fadeAnimationController.reset();
      recognizeSpeech();
      while (activatedOrGaveUp == false &&
          DateTime.now().difference(start).inSeconds < 30) {
        await Future.delayed(Duration(seconds: 1));
      }
      activatedOrGaveUp = true;
      speech.stop();
    }

    // START COUNTDOWN

    bool endingNoiseStarted = false;

    // construct countdown noises
    // for each second between the countdown start and the beginning of the ending noise,
    //   create a sound manager and a sound based on the pattern
    List<SoundManager> countdownSoundManagers = [];
    List<String> countdownSoundOrchestration = [];
    int patternIndex = 0;
    List countdownNoise = countdownNoises.firstWhere((x) => x[0]);
    List endingNoise = endingNoises.firstWhere((x) => x[0]);
    int numSecondsOfCountdownNoises =
        (countdownTimer - endingNoise[3]).ceil() + 1;
    if (!countdownNoises[0][0]) {
      for (int i = 0; i < numSecondsOfCountdownNoises; i++) {
        countdownSoundManagers.add(SoundManager());
        countdownSoundOrchestration.add(countdownNoise[2][patternIndex]);
        patternIndex += 1;
        if (patternIndex == countdownNoise[2].length) {
          patternIndex = 0;
        }
      }
    }

    DateTime startTime = DateTime.now();
    int countdownIndex = 0;

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

          // play countdown if ending noise hasn't started
          if (!endingNoiseStarted &&
              !countdownNoises[0][0] &&
              countdownSeconds != 0) {
            countdownSoundManagers[countdownIndex].playLocal(
                '${countdownSoundOrchestration[countdownIndex]}.wav');
          }
        }
        countdownIndex += 1;
      },
    );
    while (countdownSeconds > 0) {
      // check if ending noise should be played
      if (!endingNoises[0][0]) {
        double elapsedSeconds = DateTime.now()
                .difference(startTime.add(Duration(seconds: 1)))
                .inMilliseconds /
            1000.0;
        double remainingSeconds = countdownTimer.toDouble() - elapsedSeconds;
        List endingNoise = endingNoises.firstWhere((x) => x[0]);
        if (!endingNoiseStarted && endingNoise[3] > remainingSeconds) {
          endingSoundManager.playLocal('${endingNoise[2]}.wav');
          endingNoiseStarted = true;
        }
      }

      await Future.delayed(Duration(milliseconds: 100));
    }

    // reset voice activation transcription
    setState(() {
      transcription = '';
      fadeAnimationController.reverse();
    });

    try {
      List<String> fileNames = [];
      List<String> paths = [];
      for (int i = 0; i < numPhotos; i++) {
        flashAnimationController.forward();
        var p = await getTemporaryDirectory();
        var name = 'ELATC-' +
            DateTime.now()
                .toString()
                .replaceAll(' ', 'T')
                .replaceAll(':', '-')
                .replaceAll('.', '-');
        var path = "${p.path}/$name.png";
        playShutter();
        await cameraController.takePicture(path);
        fileNames.add("$name.png");
        paths.add(path);
        flashAnimationController.reverse();
        if (i < numPhotos - 1) {
          await Future.delayed(Duration(seconds: 1));
        }
      }
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PreviewScreen(
                    imgPaths: paths,
                    fileNames: fileNames,
                  )));
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
            softVibrate();
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
                softVibrate();
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
    if (section != 'countdownNoise') {
      countdownNoiseMessage = null;
    }
    if (section != 'endingNoise') {
      endingNoiseMessage = null;
    }
  }

  setToNone(list) {
    list[0][0] = true;
    for (int i = 1; i < list.length; i++) {
      list[i][0] = false;
    }
  }

  statusListener(status) async {
    if (!activatedOrGaveUp && status == 'notListening') {
      await Future.delayed(Duration(milliseconds: 100));
      speech.listen(
        onResult: resultListener,
      );
    }
    if (activatedOrGaveUp) {
      speech.stop();
    }
  }

  errorListener(error) async {
    print('!!!! listening error: $error, gave up? $activatedOrGaveUp');
    if (!activatedOrGaveUp) {
      await Future.delayed(Duration(milliseconds: 100));
      speech.listen(
        onResult: resultListener,
      );
    }
    if (activatedOrGaveUp) {
      speech.stop();
    }
  }

  resultListener(result) {
    setState(() {
      newTranscription = result.recognizedWords;
      if (result.finalResult) {
        transcription = transcription + ' ' + result.recognizedWords;
        transcription = transcription.trim();
        newTranscription = '';
      }
      if (voiceActivations[0][0]) {
        return;
      } else {
        String correctPhrase = voiceActivations.firstWhere((x) => x[0])[1];
        if (transcription.toUpperCase().contains(correctPhrase.toUpperCase())) {
          confirmationManager.playLocal('confirmation.wav');
          speech.stop();
          activatedOrGaveUp = true;
        }
      }
      if (result.finalResult && activatedOrGaveUp) {
        fadeAnimationController.forward();
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
      speech.stop();
      speech.listen(
        onResult: resultListener,
      );
    } else {
      print("The user has denied the use of speech recognition.");
    }
  }

  getAngle() {
    if (angle == 'portrait') {
      return 0.0;
    } else if (angle == 'reversedPortrait') {
      return pi;
    } else if (angle == 'landscape') {
      return pi / 2;
    } else {
      return -pi / 2;
    }
  }

  getOffset(index) {
    var width = MediaQuery.of(context).size.width;
    // print(angle);
    if (angle == 'portrait') {
      return Offset(0, -100 - (10.0 * index));
    } else if (angle == 'reversedPortrait') {
      return Offset(0, 30 + (30.0 * index));
    } else if (angle == 'landscape') {
      return Offset(0 - (30.0 * index), (index - 1) * width / 3);
    } else {
      return Offset(-240 + (230.0 * index), (index - 1) * width / 3);
    }
  }

  voiceRecognition() {
    var width = MediaQuery.of(context).size.width;
    String correctWord1;
    String correctWord2;
    String correctWord3;
    if (voiceActivations[0][0]) {
      return;
    } else {
      String correctPhrase = voiceActivations.firstWhere((x) => x[0])[1];
      List<String> correctWords = correctPhrase.split(' ');
      if (correctWords.length == 3) {
        correctWord1 = correctWords[0].toUpperCase();
        correctWord2 = correctWords[1].toUpperCase();
        correctWord3 = correctWords[2].toUpperCase();
      }
      if (correctWords.length == 2) {
        correctWord2 = correctWords[0].toUpperCase();
        correctWord3 = correctWords[1].toUpperCase();
      }
      if (correctWords.length == 1) {
        correctWord3 = correctWords[0].toUpperCase();
      }
    }
    // transcription = 'reasonable length words';
    // newTranscription = '';
    List words = (transcription + newTranscription).trim().split(' ');
    String word1 = words[max(0, words.length - 3)].toUpperCase();
    String word2 = words[max(0, words.length - 2)].toUpperCase();
    String word3 = words[max(0, words.length - 1)].toUpperCase();
    if (angle == 'reversedPortrait') {
      String tempWord = word1;
      word1 = word3;
      word3 = tempWord;
    }
    if (words.length < 3) {
      word2 = '';
      word3 = '';
    }
    if (words.length < 2) {
      word3 = '';
    }
    bool allWordsCorrect = (correctWord1 == word1 || correctWord1 == null) &&
        (correctWord2 == word2 || correctWord2 == null) &&
        (correctWord3 == word3 || correctWord3 == null);
    voiceFontFamily = 'Righteous';
    Color gotItColor = Colors.pink;
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Text(
          //   '$_accelerometerValues',
          //   style: TextStyle(
          //     fontSize: 30,
          //     color: Colors.red,
          //   ),
          // ),
          Transform.rotate(
            angle: getAngle(),
            child: Transform.translate(
              offset: getOffset(0),
              child: Container(
                height: width / 3,
                child: Center(
                  child: AutoSizeText(
                    word1,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: voiceFontFamily,
                      fontSize: 200,
                      color: word1 == correctWord1 && allWordsCorrect
                          ? gotItColor.withAlpha(fadeAnimation.value)
                          : Colors.white.withAlpha(fadeAnimation.value),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: getAngle(),
            child: Transform.translate(
              offset: getOffset(1),
              child: Container(
                height: width / 3,
                child: Center(
                  child: AutoSizeText(
                    word2,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: voiceFontFamily,
                      fontSize: 200,
                      color: word2 == correctWord2 && allWordsCorrect
                          ? gotItColor.withAlpha(fadeAnimation.value)
                          : Colors.white.withAlpha(fadeAnimation.value),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: getAngle(),
            child: Transform.translate(
              offset: getOffset(2),
              child: Container(
                height: width / 3,
                child: Center(
                  child: AutoSizeText(
                    word3,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: voiceFontFamily,
                      fontSize: 200,
                      color: word3 == correctWord3 && allWordsCorrect
                          ? gotItColor.withAlpha(fadeAnimation.value)
                          : Colors.white.withAlpha(fadeAnimation.value),
                    ),
                  ),
                ),
              ),
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
                            softVibrate();
                            setState(() {
                              countdownTimer = newValue;
                              fadeAnimationController = AnimationController(
                                  duration: Duration(seconds: newValue),
                                  vsync: this);
                              fadeAnimation = IntTween(begin: 200, end: 0)
                                  .animate(fadeAnimationController);
                              // clear messages in other sections
                              clearMessagesExcept('countdown');
                              if (!countdownNoises[0][0] &&
                                  countdownTimer < 5) {
                                setToNone(countdownNoises);
                                countdownMessage = 'Disabled noisy countdown.';
                              } else if (!endingNoises[0][0]) {
                                if (countdownTimer <
                                    endingNoises.firstWhere((x) => x[0])[3]) {
                                  setToNone(endingNoises);
                                  countdownMessage = 'Disabled ending noise.';
                                }
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
                          softVibrate();
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
                      Text('Countdown noise'),
                      countdownNoiseMessage != null
                          ? Column(
                              children: [
                                SizedBox(height: 5),
                                Text(
                                  countdownNoiseMessage,
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
                        textList:
                            countdownNoises.map((x) => x[1] as String).toList(),
                        isSelected:
                            countdownNoises.map((x) => x[0] as bool).toList(),
                        boxWidth: 100,
                        onPressed: (int index) {
                          softVibrate();
                          setState(() {
                            for (int buttonIndex = 0;
                                buttonIndex < countdownNoises.length;
                                buttonIndex++) {
                              if (buttonIndex == index) {
                                countdownNoises[buttonIndex][0] = true;
                              } else {
                                countdownNoises[buttonIndex][0] = false;
                              }
                            }
                            // play sound
                            List countdownNoise =
                                countdownNoises.firstWhere((x) => x[0]);
                            sampleSoundManager.audioPlayer.stop();
                            if (!countdownNoises[0][0]) {
                              sampleSoundManager
                                  .playLocal('${countdownNoise[2][0]}.wav');
                            }
                            // clear messages in other sections
                            clearMessagesExcept('countdownNoise');
                            // if selected
                            if (!countdownNoises[0][0]) {
                              // ensure countdown timer is at least 3. if less than 3, set to 3 and set message
                              if (countdownTimer < 3) {
                                countdownTimer = 3;
                                countdownNoiseMessage =
                                    'Countdown increased to 3.';
                              } else {
                                countdownNoiseMessage = null;
                              }
                              // if timer & endingNoise result in no countdown noise, notify
                            } else {
                              countdownNoiseMessage = null;
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
                      Text('Final noise'),
                      endingNoiseMessage != null
                          ? Column(
                              children: [
                                SizedBox(height: 5),
                                Text(
                                  endingNoiseMessage,
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
                        textList:
                            endingNoises.map((x) => x[1] as String).toList(),
                        isSelected:
                            endingNoises.map((x) => x[0] as bool).toList(),
                        boxWidth: 100,
                        onPressed: (int index) {
                          softVibrate();
                          setState(() {
                            for (int buttonIndex = 0;
                                buttonIndex < endingNoises.length;
                                buttonIndex++) {
                              if (buttonIndex == index) {
                                endingNoises[buttonIndex][0] = true;
                              } else {
                                endingNoises[buttonIndex][0] = false;
                              }
                            }
                            // play sound
                            List endingNoise =
                                endingNoises.firstWhere((x) => x[0]);
                            sampleSoundManager.audioPlayer.stop();
                            if (!endingNoises[0][0]) {
                              sampleSoundManager
                                  .playLocal('${endingNoise[2]}.wav');
                            }
                            // clear messages in other sections
                            clearMessagesExcept('endingNoise');
                            // if selected
                            if (!endingNoises[0][0]) {
                              int endingNoiseIndex = endingNoises
                                  .indexWhere((endingNoise) => endingNoise[0]);
                              var endingNoiseDuration =
                                  endingNoises[endingNoiseIndex][3];
                              if (countdownTimer < endingNoiseDuration) {
                                int minRequiredCountdown = 0;
                                countdownChoices.reversed.forEach((v) {
                                  if (v > endingNoiseDuration) {
                                    minRequiredCountdown = v;
                                  }
                                });
                                countdownTimer = minRequiredCountdown;
                                endingNoiseMessage =
                                    'Minimum timer set to $minRequiredCountdown.';
                              } else {
                                endingNoiseMessage = null;
                              }
                            } else {
                              endingNoiseMessage = null;
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
                        textList: voiceActivations
                            .map((x) => x[1] as String)
                            .toList(),
                        isSelected:
                            voiceActivations.map((x) => x[0] as bool).toList(),
                        boxWidth: 200,
                        onPressed: (int index) {
                          softVibrate();
                          setState(() {
                            for (int buttonIndex = 0;
                                buttonIndex < voiceActivations.length;
                                buttonIndex++) {
                              if (buttonIndex == index) {
                                voiceActivations[buttonIndex][0] = true;
                              } else {
                                voiceActivations[buttonIndex][0] = false;
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
                          'dslr',
                          'modern',
                          'minolta',
                          'polaroid',
                        ],
                        isSelected: shutterNoise,
                        onPressed: (int index) {
                          softVibrate();
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
                      Text('Number of photos'),
                      DropdownButton<int>(
                        value: numPhotos,
                        elevation: 16,
                        style: TextStyle(color: Theme.of(context).accentColor),
                        underline: Container(
                          height: 2,
                          color: Theme.of(context).accentColor,
                        ),
                        onChanged: (int newValue) {
                          setState(() {
                            numPhotos = newValue;
                          });
                        },
                        items: <int>[1, 2, 3, 4, 5]
                            .map<DropdownMenuItem<int>>((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(value.toString()),
                          );
                        }).toList(),
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
                softVibrate();
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
                softVibrate();
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
      angle = 'portrait';
    } else {
      // hysteresis
      if (_accelerometerValues[1] > 6 && angle != 'portrait') {
        angle = 'portrait';
      }
      if (_accelerometerValues[1] < -6 && angle != 'reversedPortrait') {
        angle = 'reversedPortrait';
      }
      if (_accelerometerValues[1] < 4.5 &&
          _accelerometerValues[0] > 3 &&
          angle != 'landscape') {
        angle = 'landscape';
      }
      if (_accelerometerValues[1] < 4.5 &&
          _accelerometerValues[0] < -3 &&
          angle != 'reversedLandscape') {
        angle = 'reversedLandscape';
      }
    }
    if (countdownSeconds == null ||
        countdownSeconds == 0 ||
        countdownSeconds > countdownTimer) {
      return Container();
    }
    return Transform.rotate(
      angle: getAngle(),
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
    addFieldValue(fields, values, 'TIMER', countdownTimer);
    if (giantNumbersEnabled) {
      addFieldValue(fields, values, 'GIANT NUMBERS', 'ON');
    }
    if (!countdownNoises[0][0]) {
      addFieldValue(fields, values, 'COUNTDOWN NOISE',
          countdownNoises.firstWhere((x) => x[0])[1].toUpperCase());
    }
    if (!endingNoises[0][0]) {
      addFieldValue(fields, values, 'ENDING NOISE',
          endingNoises.firstWhere((x) => x[0])[1].toUpperCase());
    }
    if (!voiceActivations[0][0]) {
      addFieldValue(fields, values, 'VOICE ACTIVATION',
          '"${voiceActivations.firstWhere((x) => x[0])[1].toUpperCase()}"');
    }
    if (numPhotos != 1) {
      addFieldValue(fields, values, 'NUM PHOTOS', '$numPhotos');
    }
    return Transform.rotate(
      angle: getAngle(), //portraitAngle ? 0 : pi / 2,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(5),
          color: Colors.black.withAlpha(100),
        ),
        padding: EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: fields,
            ),
            SizedBox(width: 15),
            Column(
              // mainAxisAlignment: MainAxisAlignment.center,
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
              bottom: angle == 'portrait' || angle == 'reversedPortrait'
                  ? 180
                  : 220,
              right:
                  angle == 'portrait' || angle == 'reversedPortrait' ? 20 : 0,
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
    print('!!!!!!! Camera Error $e');
    initCamera(cameras[selectedCameraIndex]);
  }
}
