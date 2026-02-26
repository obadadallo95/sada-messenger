import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Callback signature for when a recording is finished.
/// Receives the file path of the recorded Opus audio.
typedef OnRecordingDone = void Function(String filePath);

/// Hold-to-record microphone button with animated ring.
/// Releases → triggers [onDone] with the recorded file path.
class VoiceRecorderButton extends StatefulWidget {
  final OnRecordingDone onDone;

  const VoiceRecorderButton({super.key, required this.onDone});

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton>
    with SingleTickerProviderStateMixin {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) _pulseCtrl.reverse();
        if (s == AnimationStatus.dismissed && _isRecording) _pulseCtrl.forward();
      });
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.ogg';
    final filePath = p.join(dir.path, 'mesh_files', fileName);

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.opus, bitRate: 16000),
      path: filePath,
    );

    HapticFeedback.mediumImpact();
    _elapsed = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    _pulseCtrl.forward();

    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _pulseCtrl.reset();
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    HapticFeedback.lightImpact();
    if (path != null) widget.onDone(path);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) {
          return Transform.scale(
            scale: _isRecording ? _pulseAnim.value : 1.0,
            child: child,
          );
        },
        child: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isRecording
                ? theme.colorScheme.error
                : theme.colorScheme.surface.withValues(alpha: 0.6),
            border: Border.all(
              color: _isRecording
                  ? theme.colorScheme.error
                  : Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: _isRecording
                ? [
                    BoxShadow(
                      color: theme.colorScheme.error.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                color: _isRecording ? Colors.white : Colors.white70,
                size: 22.sp,
              ),
              if (_isRecording)
                Positioned(
                  top: 2,
                  child: Text(
                    _formatDuration(_elapsed),
                    style: TextStyle(
                      fontSize: 7.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
