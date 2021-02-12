import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

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
  @override
  Widget build(BuildContext context) {
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
                      HapticFeedback.vibrate();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                SizedBox(
                  height: 40,
                  width: 80,
                  child: RaisedButton(
                    child: Icon(
                      Icons.file_download,
                      color: Colors.white,
                      size: 30,
                    ),
                    color: Colors.blueAccent,
                    onPressed: () {
                      HapticFeedback.vibrate();
                      print('will download');
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
                      HapticFeedback.vibrate();
                      getBytes().then((bytes) {
                        print(widget.imgPath);
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

  Future getBytes() async {
    Uint8List bytes = File(widget.imgPath).readAsBytesSync() as Uint8List;
//    print(ByteData.view(buffer))
    return ByteData.view(bytes.buffer);
  }
}
