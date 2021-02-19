import 'dart:io';
import 'dart:typed_data';
import 'package:vibration/vibration.dart';
import 'package:gallery_saver/gallery_saver.dart';

import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PreviewScreen extends StatefulWidget {
  final String imgPath;
  final String fileName;
  PreviewScreen({this.imgPath, this.fileName});

  @override
  _PreviewScreenState createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool saved = false;

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Column(
          children: <Widget>[
            Expanded(
              child: Image.file(
                File(widget.imgPath),
                fit: BoxFit.contain,
              ),
            ),
            ButtonBar(
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  height: 40,
                  width: 80,
                  child: RaisedButton(
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                    color: Colors.redAccent[100],
                    onPressed: () {
                      softVibrate();
                      if (!saved) {
                        showDialog<Null>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Delete?'),
                              backgroundColor: Colors.white.withAlpha(220),
                              contentPadding: EdgeInsets.fromLTRB(30, 0, 30, 0),
                              content: Container(
                                width: width * 0.95,
                                child:
                                    Text('\nGoing back will delete the photo.'),
                              ),
                              actions: <Widget>[
                                FlatButton(
                                  onPressed: () {
                                    softVibrate();
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                                FlatButton(
                                  onPressed: () {
                                    softVibrate();
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
                SizedBox(
                  height: 40,
                  width: 80,
                  child: RaisedButton(
                    child: saved
                        ? Text('SAVED')
                        : Icon(
                            Icons.file_download,
                            color: Colors.white,
                            size: 30,
                          ),
                    color: saved ? Colors.grey : Colors.blueAccent,
                    onPressed: saved
                        ? () {}
                        : () {
                            softVibrate();
                            GallerySaver.saveImage(widget.imgPath);
                            setState(() {
                              saved = true;
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
                      size: 20,
                    ),
                    color: Colors.greenAccent,
                    onPressed: () {
                      softVibrate();
                      getBytes().then((bytes) {
                        Share.file('Share via', widget.fileName,
                            bytes.buffer.asUint8List(), 'image/path');
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  softVibrate() {
    Vibration.vibrate(amplitude: 128, duration: 100);
  }

  Future getBytes() async {
    Uint8List bytes = File(widget.imgPath).readAsBytesSync() as Uint8List;
//    print(ByteData.view(buffer))
    return ByteData.view(bytes.buffer);
  }
}
