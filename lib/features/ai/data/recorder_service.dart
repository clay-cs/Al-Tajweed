import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Thin wrapper over the `record` plugin: request permission, capture a
/// 16 kHz mono clip suitable for the AI service, and clean up temp files.
class RecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<bool> get isRecording => _recorder.isRecording();

  /// Starts recording to a temp file. Returns false if permission denied.
  Future<bool> start() async {
    if (!await _recorder.hasPermission()) return false;
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    _path = '${dir.path}/recitation_$ts.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000, // matches the AI service working rate
        numChannels: 1,
        bitRate: 64000,
      ),
      path: _path!,
    );
    return true;
  }

  /// Stops recording and returns the file path (null if nothing captured).
  Future<String?> stop() async {
    final path = await _recorder.stop();
    return path ?? _path;
  }

  Future<void> cancel() async {
    try {
      await _recorder.cancel();
    } catch (_) {}
    await _deleteTemp();
  }

  Future<void> _deleteTemp() async {
    final p = _path;
    if (p == null) return;
    try {
      final f = File(p);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    _path = null;
  }

  /// Deletes the last recorded file (call after a successful upload).
  Future<void> cleanup() => _deleteTemp();

  void dispose() {
    _recorder.dispose();
  }
}
