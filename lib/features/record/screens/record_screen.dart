import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../feed/providers/feed_provider.dart';
import '../providers/recording_provider.dart';
import '../services/audio_service.dart';

class RecordScreen extends ConsumerStatefulWidget {
  final String? postId;

  const RecordScreen({super.key, this.postId});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingProvider);
    final recordingNotifier = ref.read(recordingProvider.notifier);
    final audioService = ref.read(audioServiceProvider);
    final isReply = widget.postId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isReply ? 'Record Yap' : 'Test Audio Pipeline',
          style: AppTextStyles.headlineLarge,
        ),
        backgroundColor: AppColors.background,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getStatusText(recordingState, isReply),
                style: AppTextStyles.titleMedium.copyWith(
                  color: _getStatusColor(recordingState),
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(32),
              if (recordingState == RecordingState.idle)
                _buildRecordButton(recordingNotifier),
              if (recordingState == RecordingState.recording)
                _buildStopButton(recordingNotifier),
              if (recordingState == RecordingState.idle &&
                  recordingNotifier.recordedFilePath != null) ...[
                const Gap(16),
                _buildUploadButton(recordingNotifier),
                const Gap(16),
                _buildPlayLocalButton(audioService, recordingNotifier),
              ],
              if (recordingState == RecordingState.completed &&
                  recordingNotifier.uploadResult != null) ...[
                const Gap(24),
                Text(
                  isReply ? 'Yap posted!' : 'Upload complete!',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.green[400],
                  ),
                ),
                const Gap(16),
                _buildPlayS3Button(audioService, recordingNotifier.uploadResult!),
                const Gap(16),
                ElevatedButton(
                  onPressed: () => recordingNotifier.reset(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: const Text('Record Another'),
                ),
                if (isReply) ...[
                  const Gap(12),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(feedProvider);
                      context.go('/feed');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Back to feed'),
                  ),
                ],
              ],
              if (recordingState == RecordingState.uploading)
                const CircularProgressIndicator(),
              if (recordingState == RecordingState.error) ...[
                const Gap(16),
                Text(
                  'Error: ${audioService.lastError ?? "Unknown error"}',
                  style: TextStyle(color: Colors.red[400]),
                  textAlign: TextAlign.center,
                ),
                const Gap(16),
                ElevatedButton(
                  onPressed: () => recordingNotifier.reset(),
                  child: const Text('Reset'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordButton(RecordingNotifier notifier) {
    return ElevatedButton.icon(
      onPressed: () => notifier.startRecording(),
      icon: const Icon(Icons.mic, size: 32),
      label: const Text('Start Recording'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    );
  }

  Widget _buildStopButton(RecordingNotifier notifier) {
    return ElevatedButton.icon(
      onPressed: () => notifier.stopRecording(),
      icon: const Icon(Icons.stop, size: 32),
      label: const Text('Stop Recording'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    );
  }

  Widget _buildUploadButton(RecordingNotifier notifier) {
    final postId = widget.postId;
    return ElevatedButton.icon(
      onPressed: () {
        if (postId == null) {
          notifier.uploadRecording();
        } else {
          notifier.publishYap(postId: postId);
        }
      },
      icon: const Icon(Icons.cloud_upload),
      label: Text(postId == null ? 'Upload to S3' : 'Publish Yap'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    );
  }

  Widget _buildPlayLocalButton(
    AudioService audioService,
    RecordingNotifier notifier,
  ) {
    return ElevatedButton.icon(
      onPressed: () {
        final path = notifier.recordedFilePath;
        if (path != null) audioService.playLocalFile(path);
      },
      icon: const Icon(Icons.play_arrow),
      label: const Text('Play Local Recording'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    );
  }

  Widget _buildPlayS3Button(
    AudioService audioService,
    Map<String, dynamic> uploadResult,
  ) {
    final playbackUrl = uploadResult['playbackUrl'] as String?;
    if (playbackUrl == null) return const Text('No playback URL available');

    return ElevatedButton.icon(
      onPressed: () => audioService.playAudio(playbackUrl),
      icon: const Icon(Icons.cloud_download),
      label: const Text('Play from S3'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    );
  }

  String _getStatusText(RecordingState state, bool isReply) {
    switch (state) {
      case RecordingState.idle:
        return isReply ? 'Ready to record your yap' : 'Ready to record';
      case RecordingState.recording:
        return 'Recording...';
      case RecordingState.uploading:
        return isReply ? 'Publishing yap...' : 'Uploading to S3...';
      case RecordingState.completed:
        return isReply ? 'Yap posted!' : 'Upload complete!';
      case RecordingState.error:
        return 'Error occurred';
    }
  }

  Color _getStatusColor(RecordingState state) {
    switch (state) {
      case RecordingState.idle:
        return AppColors.textSecondary;
      case RecordingState.recording:
        return Colors.red[400]!;
      case RecordingState.uploading:
        return Colors.blue[400]!;
      case RecordingState.completed:
        return Colors.green[400]!;
      case RecordingState.error:
        return Colors.red[400]!;
    }
  }
}
