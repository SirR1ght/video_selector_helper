import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

const Color kDefaultBg = Color(0xFF0D1018);

const List<({String label, Color color})> kAppBackgrounds =
    <({String label, Color color})>[
  (label: 'Dark / bgDefaultSecondary (main)', color: Color(0xFF0D1018)),
  (label: 'Dark / bgDefaultPrimary', color: Color(0xFF06070B)),
  (label: 'Dark / bgDefaultTertiary', color: Color(0xFF141926)),
  (label: 'Light / bgDefaultSecondary', color: Color(0xFFBBC8D3)),
  (label: 'Light / bgDefaultPrimary', color: Color(0xFFF4F7F8)),
  (label: 'Light / bgDefaultTertiary', color: Color(0xFFFFFFFF)),
];

void main() => runApp(const VideoSelectorApp());

class VideoSelectorApp extends StatelessWidget {
  const VideoSelectorApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        title: 'Video Selector Helper',
        debugShowCheckedModeBanner: false,
        home: VideoSelectorPage(),
      );
}

class VideoSelectorPage extends StatefulWidget {
  const VideoSelectorPage({super.key});

  @override
  State<VideoSelectorPage> createState() => _VideoSelectorPageState();
}

class _VideoSelectorPageState extends State<VideoSelectorPage> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  Color _bg = kDefaultBg;
  final List<({Color color, String label})> _customColors =
      <({Color color, String label})>[];

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.video,
    );
    if (result == null || result.files.single.path == null) return;

    final VideoPlayerController? old = _controller;
    setState(() {
      _isInitialized = false;
      _controller = null;
    });
    await old?.dispose();

    final VideoPlayerController controller = VideoPlayerController.file(
      File(result.files.single.path!),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    await controller.initialize();
    await controller.setLooping(true);
    await controller.setVolume(0);
    await controller.play();

    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _isInitialized = true;
    });
  }

  Future<void> _addCustomColor() async {
    final ({Color color, String label})? picked =
        await showDialog<({Color color, String label})>(
      context: context,
      builder: (BuildContext _) => const _HexColorDialog(),
    );
    if (picked == null) return;
    setState(() {
      final bool exists = _customColors
          .any((({Color color, String label}) e) => e.color == picked.color);
      if (!exists) _customColors.add(picked);
      _bg = picked.color;
    });
  }

  void _removeCustomColor(Color color) {
    setState(() {
      _customColors.removeWhere(
        (({Color color, String label}) e) => e.color == color,
      );
      if (_bg == color) _bg = kDefaultBg;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildPalette(),
            Expanded(
              child: Center(
                child: _isInitialized && _controller != null
                    ? IgnorePointer(
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: RepaintBoundary(
                            child: VideoPlayer(_controller!),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.video_library),
                label: const Text('Pick video'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hexCode(Color c) {
    final int rgb = c.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Widget _chipLabel(String label, Color color, bool selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label),
        Text(
          _hexCode(color),
          style: TextStyle(
            fontSize: 10,
            color: selected ? Colors.white70 : Colors.grey,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildPalette() {
    const Color selectedBg = Color(0xFF1F1F1F);
    const TextStyle selectedLabel = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Add HEX'),
              onPressed: _addCustomColor,
            ),
          ),
          for (final ({String label, Color color}) entry in kAppBackgrounds)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                avatar: _swatch(entry.color),
                label: _chipLabel(entry.label, entry.color, _bg == entry.color),
                selected: _bg == entry.color,
                showCheckmark: false,
                selectedColor: selectedBg,
                labelStyle: _bg == entry.color ? selectedLabel : null,
                onSelected: (_) => setState(() => _bg = entry.color),
              ),
            ),
          for (final ({Color color, String label}) entry in _customColors)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InputChip(
                avatar: _swatch(entry.color),
                label: _chipLabel(entry.label, entry.color, _bg == entry.color),
                selected: _bg == entry.color,
                showCheckmark: false,
                selectedColor: selectedBg,
                labelStyle: _bg == entry.color ? selectedLabel : null,
                onSelected: (_) => setState(() => _bg = entry.color),
                onDeleted: () => _removeCustomColor(entry.color),
              ),
            ),
        ],
      ),
    );
  }

  Widget _swatch(Color c) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black26),
      ),
    );
  }
}

class _HexColorDialog extends StatefulWidget {
  const _HexColorDialog();

  @override
  State<_HexColorDialog> createState() => _HexColorDialogState();
}

class _HexColorDialogState extends State<_HexColorDialog> {
  final TextEditingController _textController = TextEditingController();
  String? _error;
  ({Color color, String label})? _parsed;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    final ({({Color color, String label})? value, String? error}) r =
        _tryParse(raw);
    setState(() {
      _parsed = r.value;
      _error = r.error;
    });
  }

  ({({Color color, String label})? value, String? error}) _tryParse(
    String raw,
  ) {
    String s = raw.trim().toUpperCase();
    if (s.isEmpty) return (value: null, error: null);
    if (s.startsWith('#')) s = s.substring(1);
    if (s.startsWith('0X')) s = s.substring(2);
    // Drop alpha if user pasted full ARGB (FFRRGGBB).
    if (s.length == 8) s = s.substring(2);
    if (s.length != 6) {
      return (value: null, error: 'Need 6 hex digits (RRGGBB)');
    }
    final int? rgb = int.tryParse(s, radix: 16);
    if (rgb == null) {
      return (value: null, error: 'Invalid hex characters');
    }
    return (
      value: (color: Color(0xFF000000 | rgb), label: '#$s'),
      error: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ({Color color, String label})? parsed = _parsed;
    return AlertDialog(
      title: const Text('Add custom color'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _textController,
            autofocus: true,
            keyboardType: TextInputType.text,
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(fontFamily: 'monospace'),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              prefixText: '#',
              hintText: 'RRGGBB',
              errorText: _error,
            ),
            onChanged: _onChanged,
            onSubmitted: (_) {
              if (parsed != null) Navigator.of(context).pop(parsed);
            },
          ),
          if (parsed != null) ...<Widget>[
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: parsed.color,
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Text(parsed.label),
              ],
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed:
              parsed == null ? null : () => Navigator.of(context).pop(parsed),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
