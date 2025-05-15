import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';

class AudioMessage extends StatefulWidget {
  final String audioUrl;
  AudioMessage({required this.audioUrl});

  static Future<String?> record() async {
    final record = Record();
    if (await record.hasPermission()) {
      await record.start();
      await Future.delayed(Duration(seconds: 10)); // Placeholder duration
      final path = await record.stop();
      return path;
    }
    return null;
  }

  @override
  _AudioMessageState createState() => _AudioMessageState();
}

class _AudioMessageState extends State<AudioMessage> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: IconButton(
        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
            color: Color(0xFF2196F3)),
        onPressed: () async {
          if (_isPlaying) {
            await _player.pause();
            setState(() => _isPlaying = false);
          } else {
            await _player.play(UrlSource(widget.audioUrl));
            setState(() => _isPlaying = true);
          }
        },
      ),
    );
  }
}
