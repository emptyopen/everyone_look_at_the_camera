import 'package:everyone_look_at_the_camera/screens/preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController cameraController;
  List cameras;
  int selectedCameraIndex;
  String imgPath;
  bool noisyCountdownEnabled = false;
  bool giantNumbersEnabled = true;
  List<bool> lastSecondNoise = [true, false, false];
  List<bool> voiceActivationCapture = [true, false, false];

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

  /// Display camera preview
  Widget cameraPreview() {
    if (cameraController == null || !cameraController.value.isInitialized) {
      return Text(
        'Loading...',
        style: TextStyle(color: Colors.white, fontSize: 40.0),
      );
    }

    return AspectRatio(
      aspectRatio: cameraController.value.aspectRatio,
      child: CameraPreview(cameraController),
    );
  }

  Widget cameraControl(context) {
    return Expanded(
      child: Align(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            FloatingActionButton(
              child: Icon(
                Icons.camera,
                color: Colors.black,
                size: 40,
              ),
              backgroundColor: Colors.white,
              onPressed: () {
                onCapture(context);
              },
            )
          ],
        ),
      ),
    );
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
              child: Icon(
                Icons.settings,
                color: Colors.black,
                size: 40,
              ),
              backgroundColor: Colors.white,
              onPressed: () {
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
        contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
        content: Container(
          height: 500,
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
                    Text('Giant numbers'),
                    Switch(
                        value: giantNumbersEnabled,
                        onChanged: (bool newValue) {
                          setState(() {
                            giantNumbersEnabled = newValue;
                          });
                        }),
                  ],
                ),
              ),
              SizedBox(height: 20),
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
                          Icon(Icons.format_list_numbered),
                          Icon(Icons.cake),
                        ],
                        onPressed: (int index) {
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
              SizedBox(height: 20),
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
              SizedBox(height: 20),
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
            ],
          ),
        ),
        actions: <Widget>[
          Container(
            child: FlatButton(
              onPressed: () {
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

  Widget cameraToggle() {
    if (cameras == null || cameras.isEmpty) {
      return Spacer();
    }

    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    CameraLensDirection lensDirection = selectedCamera.lensDirection;

    return Expanded(
      child: Align(
        alignment: Alignment.centerLeft,
        child: FlatButton.icon(
            onPressed: () {
              onSwitchCamera();
            },
            icon: Icon(
              getCameraLensIcons(lensDirection),
              color: Colors.white,
              size: 24,
            ),
            label: Text(
              '${lensDirection.toString().substring(lensDirection.toString().indexOf('.') + 1).toUpperCase()}',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            )),
      ),
    );
  }

  onCapture(context) async {
    try {
      final p = await getTemporaryDirectory();
      final name = DateTime.now();
      final path = "${p.path}/$name.png";

      await cameraController.takePicture(path).then((value) {
        print('here');
        print(path);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PreviewScreen(
                      imgPath: path,
                      fileName: "$name.png",
                    )));
      });
    } catch (e) {
      showCameraException(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    availableCameras().then((value) {
      cameras = value;
      if (cameras.length > 0) {
        setState(() {
          selectedCameraIndex = 0;
        });
        initCamera(cameras[selectedCameraIndex]).then((value) {});
      } else {
        print('No camera available');
      }
    }).catchError((e) {
      print('Error : ${e.code}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        child: Stack(
          children: <Widget>[
//            Expanded(
//              flex: 1,
//              child: _cameraPreviewWidget(),
//            ),
            Align(
              alignment: Alignment.center,
              child: cameraPreview(),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 120,
                width: double.infinity,
                padding: EdgeInsets.all(15),
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    cameraToggle(),
                    cameraControl(context),
                    settingsControl(context),
                    Spacer(),
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
