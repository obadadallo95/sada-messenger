import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Chat bubble for received/sent voice messages.
/// Shows play/pause, elapsed time, and a simple linear progress indicator.
class VoiceMessageBubble extends StatefulWidget {
  final String filePath;
  final bool isMe;
  final DateTime timestamp;

  const VoiceMessageBubble({
    super.key,
    required this.filePath,
    required this.isMe,
    required this.timestamp,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  StreamSubscription? _posSub, _durSub, _compSub;

  @override
  void initState() {
    super.initState();
    _posSub = _player.onPositionChanged.listen((d) {
      if (mounted) setState(() => _position = d);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _total = d);
    });
    _compSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _isPlaying = false; _position = Duration.zero; });
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _compSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      await _player.play(DeviceFileSource(widget.filePath));
      setState(() => _isPlaying = true);
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _total.inMilliseconds > 0
        ? (_position.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final bubbleColor = widget.isMe
        ? theme.colorScheme.primary
        : theme.colorScheme.surface.withValues(alpha: 0.7);
    final contentColor = widget.isMe ? Colors.black : Colors.white;
    final borderRadius = widget.isMe
        ? BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomLeft: Radius.circular(20.r),
            bottomRight: Radius.circular(4.r),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomLeft: Radius.circular(4.r),
            bottomRight: Radius.circular(20.r),
          );

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: widget.isMe ? 48.w : 16.w,
          right: widget.isMe ? 16.w : 48.w,
          top: 4.h,
          bottom: 4.h,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
          boxShadow: widget.isMe
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play / Pause button
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: contentColor.withValues(alpha: 0.15),
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: contentColor,
                  size: 22.sp,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            // Progress + Time
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Waveform-style progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4.h,
                      backgroundColor: contentColor.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(contentColor),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // Elapsed / Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _fmt(_position),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: contentColor.withValues(alpha: 0.8),
                        ),
                      ),
                      if (_total > Duration.zero)
                        Text(
                          _fmt(_total),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: contentColor.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Voice icon badge
            SizedBox(width: 8.w),
            Icon(Icons.spatial_audio_off,
                size: 14.sp,
                color: contentColor.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
