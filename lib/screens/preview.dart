import 'dart:io';
import 'dart:typed_data';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:flutter/services.dart';

import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PreviewScreen extends StatefulWidget {
  final List<String> imgPaths;
  final List<String> fileNames;
  PreviewScreen({this.imgPaths, this.fileNames});

  @override
  _PreviewScreenState createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  List<bool> saved = [];
  List<bool> deleteConfirms = [];
  int index = 0;
  int alpha = 150;
  bool visible = true;

  @override
  void initState() {
    super.initState();
    // forced landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    widget.imgPaths.forEach((v) {
      saved.add(false);
      deleteConfirms.add(false);
    });
  }

  delete() {
    softVibrate();
    if (saved.length > 1) {
      setState(() {
        saved.removeAt(index);
        widget.imgPaths.removeAt(index);
        widget.fileNames.removeAt(index);
        if (index > widget.imgPaths.length - 1) {
          index = widget.imgPaths.length - 1;
        }
      });
      resetDeleteConfirms();
    } else {
      Navigator.of(context).pop();
    }
  }

  resetDeleteConfirms() {
    setState(() {
      deleteConfirms = [];
      widget.imgPaths.forEach((v) {
        deleteConfirms.add(false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    bool indexAtZero = index == 0;
    bool indexAtEnd = index == widget.imgPaths.length - 1;
    List<Widget> circles = [];
    double circleRadius = 20;
    saved.asMap().forEach((i, v) {
      bool localPhotoSaved = false;
      if (v) {
        localPhotoSaved = true;
      }
      if (index == i) {
        circles.add(Container(
          height: circleRadius,
          width: circleRadius,
          decoration: BoxDecoration(
              color: Colors.black.withAlpha(alpha),
              border: Border.all(color: Theme.of(context).highlightColor),
              borderRadius: BorderRadius.circular(circleRadius)),
          child: localPhotoSaved
              ? Icon(
                  MdiIcons.download,
                  size: circleRadius - 5,
                  color: Theme.of(context).accentColor.withAlpha(200),
                )
              : Container(),
        ));
      } else {
        circles.add(Container(
          height: circleRadius,
          width: circleRadius,
          decoration: BoxDecoration(
              color: Colors.white.withAlpha(alpha),
              border: Border.all(color: Theme.of(context).highlightColor),
              borderRadius: BorderRadius.circular(circleRadius)),
          child: localPhotoSaved
              ? Icon(
                  MdiIcons.download,
                  size: circleRadius - 5,
                  color: Theme.of(context).accentColor.withAlpha(200),
                )
              : Container(),
        ));
      }
      circles.add(SizedBox(width: 10));
    });
    if (visible) {
      circles.add(SizedBox(width: 20));
      circles.add(SizedBox(
        height: 40,
        width: 60,
        child: RaisedButton(
          child: Center(
            child: Icon(
              MdiIcons.eyeOff,
              color: Colors.black,
              size: 30,
            ),
          ),
          color: Colors.purple.withAlpha(130),
          onPressed: () {
            softVibrate();
            resetDeleteConfirms();
            setState(() {
              visible = !visible;
            });
          },
        ),
      ));
    }
    print(deleteConfirms);
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: Image.file(
                File(widget.imgPaths[index]),
                fit: BoxFit.contain,
              ),
            ),
            Text('$index', style: TextStyle(color: Colors.white)),
            Positioned(
              bottom: 30,
              right: 10,
              child: !visible
                  ? SizedBox(
                      height: 40,
                      width: 60,
                      child: RaisedButton(
                        child: Center(
                          child: Icon(
                            MdiIcons.eye,
                            color: Colors.black,
                            size: 30,
                          ),
                        ),
                        color: Colors.purple.withAlpha(130),
                        onPressed: () {
                          softVibrate();
                          resetDeleteConfirms();
                          setState(() {
                            visible = !visible;
                          });
                        },
                      ),
                    )
                  : Column(
                      children: [
                        Row(
                          children: circles,
                        ),
                        SizedBox(height: 10),
                        ButtonBar(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            SizedBox(
                              height: 40,
                              width: 80,
                              child: RaisedButton(
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Icon(
                                        deleteConfirms[index]
                                            ? Icons.delete_forever
                                            : Icons.delete,
                                        color: Colors.white.withAlpha(
                                            deleteConfirms[index] ? 50 : 255),
                                        size: 30,
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        deleteConfirms[index] ? 'CONFIRM' : '',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                color: Colors.redAccent.withAlpha(alpha),
                                onPressed: () {
                                  softVibrate();
                                  if (!deleteConfirms[index]) {
                                    setState(() {
                                      deleteConfirms[index] = true;
                                    });
                                  } else {
                                    delete();
                                  }
                                },
                              ),
                            ),
                            SizedBox(
                              height: 40,
                              width: 80,
                              child: RaisedButton(
                                child: saved[index]
                                    ? Text('SAVED')
                                    : Icon(
                                        Icons.file_download,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                color: saved[index]
                                    ? Colors.grey.withAlpha(alpha)
                                    : Colors.blueAccent.withAlpha(alpha),
                                onPressed: saved[index]
                                    ? () {}
                                    : () {
                                        softVibrate();
                                        resetDeleteConfirms();
                                        GallerySaver.saveImage(
                                            widget.imgPaths[index]);
                                        setState(() {
                                          saved[index] = true;
                                        });
                                      },
                              ),
                            ),
                            SizedBox(
                              height: 40,
                              width: 80,
                              child: RaisedButton(
                                child: Icon(
                                  Icons.share_sharp,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                color: Colors.greenAccent.withAlpha(alpha),
                                onPressed: () {
                                  softVibrate();
                                  resetDeleteConfirms();
                                  getBytes().then((bytes) {
                                    Share.file(
                                        'Share via',
                                        widget.fileNames[index],
                                        bytes.buffer.asUint8List(),
                                        'image/path');
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        ButtonBar(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            SizedBox(
                              height: 40,
                              width: 50,
                              child: RaisedButton(
                                child: Icon(
                                  Icons.keyboard_return,
                                  color: Colors.black,
                                  size: 30,
                                ),
                                color: Colors.white.withAlpha(alpha),
                                onPressed: () {
                                  softVibrate();
                                  resetDeleteConfirms();
                                  showDialog<Null>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Return?'),
                                        backgroundColor:
                                            Colors.white.withAlpha(220),
                                        contentPadding:
                                            EdgeInsets.fromLTRB(30, 0, 30, 0),
                                        content: Text(
                                            '\nAll photos will be deleted.'),
                                        actions: <Widget>[
                                          FlatButton(
                                            onPressed: () {
                                              softVibrate();
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(fontSize: 20),
                                            ),
                                          ),
                                          FlatButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(
                                              'Whatever',
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            SizedBox(
                              height: 40,
                              width: 95,
                              child: RaisedButton(
                                child: Icon(
                                  Icons.chevron_left,
                                  color: indexAtZero
                                      ? Colors.white.withAlpha(50)
                                      : Colors.white,
                                  size: 30,
                                ),
                                color: indexAtZero
                                    ? Colors.white.withAlpha(50)
                                    : Colors.black.withAlpha(alpha),
                                onPressed: indexAtZero
                                    ? () {}
                                    : () {
                                        softVibrate();
                                        resetDeleteConfirms();
                                        setState(() {
                                          index -= 1;
                                        });
                                      },
                              ),
                            ),
                            SizedBox(
                              height: 40,
                              width: 95,
                              child: RaisedButton(
                                child: Icon(
                                  Icons.chevron_right,
                                  color: indexAtEnd
                                      ? Colors.white.withAlpha(50)
                                      : Colors.white,
                                  size: 30,
                                ),
                                color: indexAtEnd
                                    ? Colors.white.withAlpha(50)
                                    : Colors.black.withAlpha(alpha),
                                onPressed: indexAtEnd
                                    ? () {}
                                    : () {
                                        softVibrate();
                                        resetDeleteConfirms();
                                        setState(() {
                                          index += 1;
                                        });
                                      },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  softVibrate() {
    Vibration.vibrate(amplitude: 30, duration: 50);
  }

  Future getBytes() async {
    Uint8List bytes =
        File(widget.imgPaths[index]).readAsBytesSync() as Uint8List;
//    print(ByteData.view(buffer))
    return ByteData.view(bytes.buffer);
  }
}
