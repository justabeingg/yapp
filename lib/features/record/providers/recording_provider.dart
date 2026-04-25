import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_service.dart';

enum RecordingState { idle, recording, uploading, completed, error }

class RecordingNotifier extends StateNotifier<RecordingState> {
  final AudioService _audioService;

  RecordingNotifier(this._audioService) : super(RecordingState.idle);

  String? _recordedFilePath;
  Map<String, dynamic>? _uploadResult;
  Map<String, dynamic>? _createdYap;
  DateTime? _recordingStartTime;
  double _recordingDurationSeconds = 0;

  String? get recordedFilePath => _recordedFilePath;
  Map<String, dynamic>? get uploadResult => _uploadResult;
  Map<String, dynamic>? get createdYap => _createdYap;

  Future<void> startRecording() async {
    state = RecordingState.recording;
    _recordingStartTime = DateTime.now();
    _recordedFilePath = await _audioService.startRecording();
    if (_recordedFilePath == null) {
      state = RecordingState.error;
    }
  }

  Future<void> stopRecording() async {
    final path = await _audioService.stopRecording();
    if (path != null) {
      _recordingDurationSeconds = _recordingStartTime != null
          ? DateTime.now()
                  .difference(_recordingStartTime!)
                  .inMilliseconds /
              1000.0
          : 0.0;
      _recordedFilePath = path;
      state = RecordingState.idle;
    } else {
      state = RecordingState.error;
    }
  }

  Future<void> uploadRecording() async {
    if (_recordedFilePath == null) return;
    state = RecordingState.uploading;

    _uploadResult = await _audioService.uploadAudio(
      _recordedFilePath!,
      _recordingDurationSeconds,
    );

    if (_uploadResult != null) {
      state = RecordingState.completed;
    } else {
      state = RecordingState.error;
    }
  }

  Future<void> publishYap({
    required String postId,
    String selectedFilter = 'normal',
    String? parentYapId,
  }) async {
    if (_recordedFilePath == null) return;
    state = RecordingState.uploading;

    _uploadResult = await _audioService.uploadAudio(
      _recordedFilePath!,
      _recordingDurationSeconds,
    );

    final mediaFileId = _uploadResult?['mediaFileId'] as String?;
    if (mediaFileId == null) {
      state = RecordingState.error;
      return;
    }

    _createdYap = await _audioService.createYap(
      mediaFileId: mediaFileId,
      postId: postId,
      selectedFilter: selectedFilter,
      parentYapId: parentYapId,
    );

    state = _createdYap != null ? RecordingState.completed : RecordingState.error;
  }

  Future<void> cancelRecording() async {
    await _audioService.cancelRecording();
    _recordedFilePath = null;
    _recordingStartTime = null;
    _recordingDurationSeconds = 0;
    state = RecordingState.idle;
  }

  void reset() {
    _recordedFilePath = null;
    _uploadResult = null;
    _createdYap = null;
    _recordingStartTime = null;
    _recordingDurationSeconds = 0;
    state = RecordingState.idle;
  }
}

final recordingProvider =
    StateNotifierProvider<RecordingNotifier, RecordingState>((ref) {
  return RecordingNotifier(ref.watch(audioServiceProvider));
});
