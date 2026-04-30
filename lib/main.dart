import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

const Color kBackgroundColor = Color(0xFF0D1018);

void main() {
  runApp(const VideoSelectorApp());
}

class VideoSelectorApp extends StatelessWidget {
  const VideoSelectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Selector Helper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBackgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBackgroundColor,
          brightness: Brightness.dark,
          surface: kBackgroundColor,
        ),
      ),
      home: const VideoSelectorPage(),
    );
  }
}

class VideoSelectorPage extends StatefulWidget {
  const VideoSelectorPage({super.key});

  @override
  State<VideoSelectorPage> createState() => _VideoSelectorPageState();
}

class _VideoSelectorPageState extends State<VideoSelectorPage> {
  VideoPlayerController? _controller;
  String? _fileName;
  bool _loading = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    setState(() => _loading = true);
    try {
      final result = await FilePicker.pickFiles(type: FileType.video);
      if (result == null || result.files.single.path == null) {
        return;
      }
      final path = result.files.single.path!;
      final newController = VideoPlayerController.file(File(path));
      await newController.initialize();
      newController.setLooping(true);

      await _controller?.dispose();

      if (!mounted) {
        await newController.dispose();
        return;
      }

      setState(() {
        _controller = newController;
        _fileName = result.files.single.name;
      });
      await newController.play();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Background Color HEX: #0D1018',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loading ? null : _pickVideo,
                icon: const Icon(Icons.video_library),
                label: Text(_loading ? 'Loading…' : 'Select video'),
              ),
              if (_fileName != null) ...[
                const SizedBox(height: 8),
                Text(
                  _fileName!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(child: _buildPlayer()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Text('No video selected', style: TextStyle(color: Colors.white38)),
      );
    }
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        const SizedBox(height: 8),
        VideoProgressIndicator(controller, allowScrubbing: true),
        IconButton(
          color: Colors.white,
          iconSize: 48,
          onPressed: () {
            setState(() {
              controller.value.isPlaying ? controller.pause() : controller.play();
            });
          },
          icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
        ),
      ],
    );
  }
}
