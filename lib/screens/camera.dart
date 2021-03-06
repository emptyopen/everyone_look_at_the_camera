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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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
      ],
      ['reduce'],
    ],
    [
      false,
      'Plucks',
      ['plucked1', 'plucked2'],
    ],
    [
      false,
      'Light Ring',
      ['beep1'],
    ],
    [
      false,
      'Asteroid Gun',
      ['asteroid-gun'],
    ],
    [
      false,
      'Upward Beep',
      ['upward-beep'],
    ],
    [
      false,
      'Upward Chime',
      ['up-chime'],
    ],
    [
      false,
      'Info Bleep',
      ['info-bleep'],
    ],
    [
      false,
      'Sneeze',
      ['sneeze'],
    ],
    [
      false,
      'Small Alarm',
      ['alarm-short-b'],
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
    [false, 'have you brushed your teeth'],
    [false, 'custom phrase 1'],
    [false, 'custom phrase 2'],
    [false, 'custom phrase 3'],
  ];
  List shutterNoises = [
    [
      false,
      'None',
    ],
    [
      true,
      'dslr',
    ],
    [
      false,
      'modern',
    ],
    [
      false,
      'minolta',
    ],
    [
      false,
      'polaroid',
    ]
  ];
  Animation<int> flashAnimation;
  AnimationController flashAnimationController;
  Animation<int> fadeAnimation;
  AnimationController fadeAnimationController;
  SoundManager sampleSoundManager = SoundManager();
  SoundManager endingSoundManager = SoundManager();
  List<SoundManager> shutterSoundManagers = [];
  SoundManager confirmationManager = SoundManager();
  List<double> _accelerometerValues;
  List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];
  SpeechToText speech = SpeechToText();
  String transcription = '';
  String newTranscription = '';
  bool activatedOrGaveUp = false;
  String voiceFontFamily = 'BebasNeue';
  int numPhotos = 2;
  bool cancelled = false;
  SharedPreferences prefs;
  int customPhraseWordLimit = 7;

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
    // shared prefs
    initPrefs();
  }

  initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    // load prefs
    countdownTimer = prefs.getInt('countdownTimer') ?? 3;
    giantNumbersEnabled = prefs.getBool('giantNumbersEnabled') ?? true;
    int countdownNoiseIndex = prefs.getInt('countdownNoiseIndex') ?? 0;
    setTo(countdownNoises, countdownNoiseIndex);
    int endingNoiseIndex = prefs.getInt('endingNoiseIndex') ?? 0;
    setTo(endingNoises, endingNoiseIndex);
    int voiceActivationIndex = prefs.getInt('voiceActivationIndex') ?? 0;
    setTo(voiceActivations, voiceActivationIndex);
    String customPhrase1 =
        prefs.getString('customPhrase1') ?? 'custom phrase 1';
    String customPhrase2 =
        prefs.getString('customPhrase2') ?? 'custom phrase 2';
    String customPhrase3 =
        prefs.getString('customPhrase3') ?? 'custom phrase 3';
    setState(() {
      voiceActivations[4][1] = customPhrase1;
      voiceActivations[5][1] = customPhrase2;
      voiceActivations[6][1] = customPhrase3;
    });
    int shutterNoiseIndex = prefs.getInt('shutterNoiseIndex') ?? 0;
    setTo(shutterNoises, shutterNoiseIndex);
    numPhotos = prefs.getInt('numPhotos') ?? 2;
    // save prefs
    saveIntPref('countdownTimer', countdownTimer);
    saveBoolPref('giantNumbersEnabled', giantNumbersEnabled);
    saveIntPref('countdownNoiseIndex', countdownNoiseIndex);
    saveIntPref('endingNoiseIndex', endingNoiseIndex);
    saveIntPref('voiceActivationIndex', voiceActivationIndex);
    saveStringPref('customPhrase1', customPhrase1);
    saveStringPref('customPhrase2', customPhrase2);
    saveStringPref('customPhrase3', customPhrase3);
    saveIntPref('shutterNoiseIndex', shutterNoiseIndex);
    saveIntPref('numPhotos', numPhotos);
  }

  saveIntPref(key, value) {
    prefs.setInt(key, value);
  }

  saveBoolPref(key, value) {
    prefs.setBool(key, value);
  }

  saveStringPref(key, value) {
    prefs.setString(key, value);
  }

  playShutter(index) {
    if (shutterNoises[1][0]) {
      shutterSoundManagers[index].playLocal('camera-dslr.wav');
    } else if (shutterNoises[2][0]) {
      shutterSoundManagers[index].playLocal('camera-modern.wav');
    } else if (shutterNoises[3][0]) {
      shutterSoundManagers[index].playLocal('camera-minolta.wav');
    } else if (shutterNoises[4][0]) {
      shutterSoundManagers[index].playLocal('camera-polaroid.wav');
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

  cancelPhoto() {
    setState(() {
      takingPhoto = false;
      countdownSeconds = 0;
      transcription = '';
      activatedOrGaveUp = true;
    });
    speech.stop();
  }

  onCapture(context) async {
    setState(() {
      takingPhoto = true;
      activatedOrGaveUp = false;
      cancelled = false;
    });

    // init shutter sound manager
    shutterSoundManagers = [];
    for (int i = 0; i < numPhotos; i++) {
      shutterSoundManagers.add(SoundManager());
    }

    // speech recognition holding pattern
    DateTime start = DateTime.now();
    if (!voiceActivations[0][0]) {
      fadeAnimationController.reset();
      recognizeSpeech();
      while (activatedOrGaveUp == false &&
          DateTime.now().difference(start).inSeconds < 30) {
        if (cancelled) {
          cancelPhoto();
          return;
        }
        await Future.delayed(Duration(milliseconds: 200));
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
    List reducedCountdownNoises = countdownNoise[2];
    if (countdownNoise.length > 3) {
      // 4th variable assumes reduction
      reducedCountdownNoises = reducedCountdownNoises
          .sublist(reducedCountdownNoises.length - countdownTimer);
    }
    if (!countdownNoises[0][0]) {
      for (int i = 0; i < numSecondsOfCountdownNoises; i++) {
        countdownSoundManagers.add(SoundManager());
        countdownSoundOrchestration.add(reducedCountdownNoises[patternIndex]);
        patternIndex += 1;
        if (patternIndex == reducedCountdownNoises.length) {
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
        if (cancelled) {
          setState(() {
            timer.cancel();
          });
        }
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
      if (cancelled) {
        cancelPhoto();
        return;
      }
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

    if (cancelled) {
      cancelPhoto();
      return;
    }

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
        playShutter(i);
        await cameraController.takePicture(path);
        fileNames.add("$name.png");
        paths.add(path);
        flashAnimationController.reverse();
        if (cancelled) {
          cancelPhoto();
          return;
        }
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
      cancelled = false;
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

  setTo(list, index) {
    for (int i = 0; i < list.length; i++) {
      if (list[i] is List) {
        list[i][0] = index == i;
      } else {
        list[i] = index == i;
      }
    }
  }

  statusListener(status) async {
    print('-- new listening status: $status  @${DateTime.now()}');
    if (!activatedOrGaveUp && status == 'notListening') {
      await Future.delayed(Duration(milliseconds: 100));
      print('restarting the listen');
      speech.listen(
        onResult: resultListener,
      );
    }
    if (activatedOrGaveUp) {
      speech.stop();
    }
  }

  errorListener(error) async {
    print('!!!! listening error: $error ||| gave up? $activatedOrGaveUp');
    if (!activatedOrGaveUp) {
      await Future.delayed(Duration(milliseconds: 100));
      print('restarting the listen');
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

  voiceRecognitionDisplay() {
    var width = MediaQuery.of(context).size.width;
    voiceFontFamily = 'Righteous';
    // transcription = 'test test test reasonable length words strawberry fields';
    // newTranscription = '';
    String fullTranscription =
        (transcription + ' ' + newTranscription).trim().toUpperCase();
    List words = fullTranscription.split(' ');
    // display only the amount of words in the voice activation phrase
    String correctPhrase =
        voiceActivations.firstWhere((x) => x[0])[1].toUpperCase();
    int displayWordLimit = correctPhrase.split(' ').length;
    List limitedWords =
        words.sublist(max(0, words.length - displayWordLimit), words.length);
    bool gotIt = fullTranscription.contains(correctPhrase);
    Color gotItColor = Colors.pink;
    List<Widget> wordColumn = [];
    limitedWords.forEach((v) {
      wordColumn.add(Container(
        height: width / limitedWords.length,
        child: Center(
          child: AutoSizeText(
            v,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: voiceFontFamily,
              fontSize: 200,
              color: gotIt
                  ? gotItColor.withAlpha(fadeAnimation.value)
                  : Colors.white.withAlpha(fadeAnimation.value),
            ),
          ),
        ),
      ));
    });
    return Transform.rotate(
      angle: getAngle(),
      child: Container(
        height: width,
        width: width,
        child: Column(
          children: wordColumn,
        ),
      ),
    );
  }

  selectCallback(int index) {
    // select custom phrase index, deselect suggested phrases
    setState(() {
      setTo(voiceActivations, index);
      saveIntPref('voiceActivationIndex', index);
    });
  }

  saveCallback(int index, String phrase) {
    if (phrase.split(' ').length > customPhraseWordLimit) {
      phrase = 'phrase is too long';
    } else if (phrase.length == 0) {
      phrase = 'no words recorded';
    }
    saveStringPref('customPhrase${index - 3}', phrase);
    setState(() {
      voiceActivations[index][1] = phrase;
    });
  }

  customPhraseSelected() {
    return voiceActivations.indexWhere((element) => element[0]) < 3;
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
                              saveIntPref('countdownTimer', countdownTimer);
                              fadeAnimationController = AnimationController(
                                  duration: Duration(seconds: newValue),
                                  vsync: this);
                              fadeAnimation = IntTween(begin: 200, end: 0)
                                  .animate(fadeAnimationController);
                              // clear messages in other sections
                              clearMessagesExcept('countdown');
                              if (!countdownNoises[0][0] &&
                                  countdownTimer < 3) {
                                setToNone(countdownNoises);
                                countdownMessage = 'Disabled countdown noise.';
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
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Number of photos'),
                      SizedBox(width: 10),
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
                          saveIntPref('numPhotos', numPhotos);
                        },
                        items: <int>[1, 2, 3, 4, 5]
                            .map<DropdownMenuItem<int>>((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(value.toString(),
                                style: TextStyle(fontSize: 20)),
                          );
                        }).toList(),
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
                            saveIntPref('countdownNoiseIndex', index);
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
                            saveIntPref('endingNoiseIndex', index);
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
                            .sublist(0, 4)
                            .map((x) => x[1] as String)
                            .toList(),
                        isSelected: voiceActivations
                            .sublist(0, 4)
                            .map((x) => x[0] as bool)
                            .toList(),
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
                            saveIntPref('voiceActivationIndex', index);
                          });
                        },
                      ),
                      // CUSTOM
                      CustomVoiceActivationContainer(
                        index: 4,
                        voiceActivations: voiceActivations,
                        selectCallback: (int index) {
                          selectCallback(index);
                          setState(() {});
                        },
                        saveCallback: (int index, String phrase) {
                          saveCallback(index, phrase);
                          setState(() {});
                        },
                      ),
                      CustomVoiceActivationContainer(
                        index: 5,
                        voiceActivations: voiceActivations,
                        selectCallback: (int index) {
                          selectCallback(index);
                          setState(() {});
                        },
                        saveCallback: (int index, String phrase) {
                          saveCallback(index, phrase);
                          setState(() {});
                        },
                      ),
                      CustomVoiceActivationContainer(
                        index: 6,
                        voiceActivations: voiceActivations,
                        selectCallback: (int index) {
                          selectCallback(index);
                          setState(() {});
                        },
                        saveCallback: (int index, String phrase) {
                          saveCallback(index, phrase);
                          setState(() {});
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
                        textList:
                            shutterNoises.map((x) => x[1] as String).toList(),
                        isSelected:
                            shutterNoises.map((x) => x[0] as bool).toList(),
                        onPressed: (int index) {
                          softVibrate();
                          setState(() {
                            for (int buttonIndex = 0;
                                buttonIndex < shutterNoises.length;
                                buttonIndex++) {
                              if (buttonIndex == index) {
                                shutterNoises[buttonIndex][0] = true;
                              } else {
                                shutterNoises[buttonIndex][0] = false;
                              }
                            }
                            saveIntPref('shutterNoiseIndex', index);
                          });
                          // play sound
                          List shutterNoise =
                              shutterNoises.firstWhere((x) => x[0]);
                          sampleSoundManager.audioPlayer.stop();
                          if (!shutterNoises[0][0]) {
                            sampleSoundManager
                                .playLocal('camera-${shutterNoise[1]}.wav');
                          }
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
                          saveBoolPref(
                              'giantNumbersEnabled', giantNumbersEnabled);
                        }),
                  ],
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

  Widget cancelButton() {
    return !takingPhoto
        ? Container()
        : Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: getAngle(),
                child: Container(
                  height: 50,
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.black.withAlpha(100),
                  ),
                  child: FlatButton(
                    onPressed: () {
                      setState(() {
                        cancelled = true;
                      });
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
            ],
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

  addFieldValue(fields, icons, values, field, icon, value) {
    fields.add(Container(
      height: 30,
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
    icons.add(Container(
      height: 30,
      child: Center(
        child: Icon(
          icon,
          size: 20,
          color: Colors.white,
        ),
      ),
    ));
    values.add(Container(
      height: 30,
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
    List<Widget> icons = [];
    List<Widget> values = [];
    addFieldValue(
        fields, icons, values, 'TIMER', MdiIcons.cameraTimer, countdownTimer);
    addFieldValue(fields, icons, values, 'NUM PHOTOS', MdiIcons.contentCopy,
        '$numPhotos');
    if (!countdownNoises[0][0]) {
      addFieldValue(
          fields,
          icons,
          values,
          'COUNTDOWN NOISE',
          MdiIcons.musicNote,
          countdownNoises.firstWhere((x) => x[0])[1].toUpperCase());
    }
    if (!endingNoises[0][0]) {
      addFieldValue(
          fields,
          icons,
          values,
          'ENDING NOISE',
          MdiIcons.musicNotePlus,
          endingNoises.firstWhere((x) => x[0])[1].toUpperCase());
    }
    if (!voiceActivations[0][0]) {
      String limitedPhrase =
          voiceActivations.firstWhere((x) => x[0])[1].toUpperCase();
      int phraseLimit = 18;
      if (limitedPhrase.length > phraseLimit) {
        limitedPhrase = limitedPhrase.substring(0, phraseLimit) + '...';
      }
      addFieldValue(fields, icons, values, 'VOICE ACTIVATION',
          MdiIcons.textToSpeech, '"$limitedPhrase"');
    }
    if (!giantNumbersEnabled) {
      addFieldValue(
          fields, icons, values, 'GIANT NUMBERS', MdiIcons.formatSize, 'OFF');
    }
    return Transform.rotate(
      angle: getAngle(),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(5),
          color: Colors.black.withAlpha(100),
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 5),
            Container(
              width: 150,
              height: 1,
              decoration: BoxDecoration(
                color: Colors.white,
              ),
            ),
            SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: fields,
                ),
                SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: icons,
                ),
                SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: values,
                ),
              ],
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
            Align(
              alignment: Alignment.center,
              child: takingPhoto ? Container() : settingsPreview(),
            ),
            Align(
              alignment: Alignment.center,
              child: voiceRecognitionDisplay(),
            ),
            Positioned(
              child: cancelButton(),
              bottom:
                  ['portrait', 'reversedPortrait'].contains(angle) ? 20 : 50,
              left: 20,
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

class CustomVoiceActivationContainer extends StatefulWidget {
  final int index;
  final List voiceActivations;
  final Function selectCallback;
  final Function saveCallback;

  CustomVoiceActivationContainer({
    this.index,
    this.voiceActivations,
    this.selectCallback,
    this.saveCallback,
  });

  @override
  _CustomVoiceActivationContainerState createState() =>
      _CustomVoiceActivationContainerState();
}

class _CustomVoiceActivationContainerState
    extends State<CustomVoiceActivationContainer> {
  SpeechToText speech = SpeechToText();
  String phrase = '';
  bool listening = false;

  statusListener(status) async {
    print('-- new listening status: $status  @${DateTime.now()}');
  }

  errorListener(error) async {
    print('!!!! listening error: $error');
  }

  resultListener(result) {
    setState(() {
      print('hearing ${result.recognizedWords}');
      if (result.finalResult) {
        phrase = result.recognizedWords;
        listening = false;
      }
    });
  }

  recognizeSpeech() async {
    bool available = await speech.initialize(
        onStatus: statusListener, onError: errorListener);
    if (available) {
      print('starting speech');
      speech.stop();
      speech.listen(
        onResult: resultListener,
      );
    } else {
      print("The user has denied the use of speech recognition.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 45,
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.voiceActivations.indexWhere((element) => element[0]) ==
                  widget.index
              ? Theme.of(context).accentColor
              : Colors.grey,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: EdgeInsets.fromLTRB(10, 3, 10, 3),
      child: InkWell(
          child: Stack(
            children: [
              listening
                  ? Container()
                  : Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AutoSizeText(
                            '"${widget.voiceActivations[widget.index][1]}"',
                            maxLines: 1,
                            style: TextStyle(
                              color: widget.voiceActivations[widget.index][0]
                                  ? Colors.black
                                  : Theme.of(context).disabledColor,
                            ),
                          ),
                          SizedBox(height: 5),
                        ],
                      ),
                    ),
              !listening
                  ? Container()
                  : Align(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.mic,
                        color: Theme.of(context).accentColor,
                      ),
                    ),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'custom text #${widget.index - 3}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ),
              !listening &&
                      widget.voiceActivations
                              .indexWhere((element) => element[0]) ==
                          widget.index
                  ? Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        'tap again to record',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).accentColor,
                        ),
                      ),
                    )
                  : Container(),
            ],
          ),
          onTap: () async {
            // if not selected, callback to select\
            listening = false;
            if (widget.voiceActivations.indexWhere((x) => x[0]) !=
                widget.index) {
              widget.selectCallback(widget.index);
              setState(() {});
            } else {
              // if not listening, start listening
              if (!listening) {
                print('listening');
                listening = true;
                setState(() {});
                recognizeSpeech();
                DateTime start = DateTime.now();
                while (DateTime.now().difference(start).inSeconds < 10 &&
                    listening) {
                  await Future.delayed(Duration(milliseconds: 100));
                }
                print('done listening');
                listening = false;
                setState(() {});
                // callback to save phrase
                widget.saveCallback(widget.index, phrase);
              }
            }
          }),
    );
  }
}
