import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  html.VideoElement _preview = html.VideoElement();
  html.VideoElement _result = html.VideoElement();
  html.MediaRecorder? _recorder;
  String? url;

  @override
  void initState() {
    super.initState();
    _preview
      ..autoplay = true
      ..muted = true
      ..width = html.window.innerWidth!
      ..height = html.window.innerHeight!;

    _result
      ..autoplay = false
      ..muted = false
      ..width = html.window.innerWidth!
      ..height = html.window.innerHeight!
      ..controls = true;

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('preview', (int _) => _preview);

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('result', (int _) => _result);
  }

  Future<html.MediaStream?> _openCamera() async {
    final html.MediaStream? stream = await html.window.navigator.mediaDevices
        ?.getUserMedia({'video': true, 'audio': true});
    _preview.srcObject = stream;
    return stream;
  }

  void startRecording(html.MediaStream stream) {
    _recorder = html.MediaRecorder(stream, {
      _recorder?.audioBitsPerSecond: 128000,
      _recorder?.videoBitsPerSecond: 2500000,
      _recorder?.mimeType: "video/webm"
    });
    _recorder?.start();

    html.Blob blob = html.Blob([]);

    _recorder?.addEventListener('dataavailable', (event) {
      blob = js.JsObject.fromBrowserObject(event)['data'];
    }, true);

    _recorder?.addEventListener('stop', (event) {
      url = html.Url.createObjectUrl(blob);
      _result.src = url!;

      stream.getTracks().forEach((track) {
        if (track.readyState == 'live') {
          track.stop();
        }
      });
    });
  }

  void stopRecording() => _recorder?.stop();
  void downloadFile() {
    html.AnchorElement anchorElement = new html.AnchorElement(href: url);
    anchorElement.download = "Recorded video.webm";
    anchorElement.click();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Web Recording',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Web Recording'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Recording Preview',
                style: Theme.of(context).textTheme.headline6,
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 10.0),
                width: 300,
                height: 200,
                color: Colors.blue,
                child: HtmlElementView(
                  key: UniqueKey(),
                  viewType: 'preview',
                ),
              ),
              Container(
                margin: EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () async {
                        final html.MediaStream? stream = await _openCamera();
                        startRecording(stream!);
                      },
                      child: Text('Start Recording'),
                    ),
                    SizedBox(
                      width: 20.0,
                    ),
                    ElevatedButton(
                      onPressed: () => stopRecording(),
                      child: Text('Stop Recording'),
                    ),
                    SizedBox(
                      width: 20.0,
                    ),
                    ElevatedButton(
                      onPressed: () => downloadFile(),
                      child: Text('Download video'),
                    ),
                  ],
                ),
              ),
              Text(
                'Recording Result',
                style: Theme.of(context).textTheme.headline6,
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 10.0),
                width: 300,
                height: 200,
                color: Colors.blue,
                child: HtmlElementView(
                  key: UniqueKey(),
                  viewType: 'result',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
