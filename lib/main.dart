import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'package:vosk_record/audio_player.dart';
import 'package:vosk_record/audio_recorder.dart';
import 'package:vosk_record/vosk_result.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool showPlayer = false;
  String? audioPath;
// vosk
  static const _textStyle = TextStyle(fontSize: 30, color: Colors.black);
  static const _modelName = 'vosk-model-small-en-us-0.15';
  static const _sampleRate = 16000;

  final _vosk = VoskFlutterPlugin.instance();
  final _modelLoader = ModelLoader();

  String? _fileRecognitionResult;
  String? _error;
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;

  bool _recognitionStarted = false;
  String _sttAllWords = '';

  bool isLoading = false;

  @override
  void initState() {
    showPlayer = false;
    if (_speechService == null && !isLoading) {
      loadModel();
    }
    super.initState();
  }

  void loadModel() async {
    setState(() => isLoading = true);
    await Permission.microphone.request();
    _modelLoader
        .loadModelsList()
        .then((modelsList) =>
            modelsList.firstWhere((model) => model.name == _modelName))
        .then((modelDescription) =>
            _modelLoader.loadFromNetwork(modelDescription.url)) // load model
        .then(
            (modelPath) => _vosk.createModel(modelPath)) // create model object
        .then((model) => setState(() => _model = model))
        .then((_) => _vosk.createRecognizer(
            model: _model!, sampleRate: _sampleRate)) // create recognizer
        .then((value) => _recognizer = value)
        .then((recognizer) async {
      if (Platform.isAndroid) {
        _vosk
            .initSpeechService(_recognizer!) // init speech service
            .then((speechService) => setState(() {
                  _speechService = speechService;
                  setState(() => isLoading = false);
                }))
            .catchError((e) => setState(() => _error = e.toString()));
      }
    }).catchError((e) {
      setState(() => _error = e.toString());
      return null;
    });
  }

  void _onSpeechResult(dynamic result) async {
    Map<String, dynamic> decoded = json.decode(result);
    VoskResult voskResult = VoskResult.fromJson(decoded);
    _sttAllWords += voskResult.text;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: !isLoading && _error == null
              ? Column(children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 200,
                      child: Text(
                        _sttAllWords,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: showPlayer
                        ? Center(
                            child: AudioPlayer(
                              source: audioPath!,
                              onDelete: () {
                                setState(() => showPlayer = false);
                              },
                            ),
                          )
                        : Recorder(
                            onStart: () {
                              _speechService?.start();
                              if (_speechService != null) {
                                _speechService!.onResult().listen((event) {
                                  _onSpeechResult(event);
                                });
                              }
                            },
                            onStop: (path) {
                              _speechService?.stop();
                              if (kDebugMode)
                                print('Recorded file path: $path');
                              setState(() {
                                audioPath = path;
                                showPlayer = true;
                              });
                            },
                          ),
                  ),
                  const SizedBox(height: 20),
                ])
              : Center(child: Text(_error != null ? _error! : 'Loading...')),
        ),
      ),
    );
  }
}
