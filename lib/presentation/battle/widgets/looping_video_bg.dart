import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 에셋 MP4를 소리 없이 무한 루프 재생하는 전체 화면 배경 위젯.
///
/// 초기화 전에는 투명 빈 공간을 표시해 위 레이어가 가려지지 않도록 한다.
/// [cropScale]로 영상을 확대해 파일에 구워진 상·하 검은 공백을 화면 밖으로 밀어낸다.
class LoopingVideoBg extends StatefulWidget {
  const LoopingVideoBg({
    super.key,
    required this.assetPath,
    this.cropScale = 1.20,
  });

  final String assetPath;

  /// 1.0 = 원본 크기(BoxFit.cover 기준). 값을 높이면 상·하 공백이 잘린다.
  final double cropScale;

  @override
  State<LoopingVideoBg> createState() => _LoopingVideoBgState();
}

class _LoopingVideoBgState extends State<LoopingVideoBg> {
  late VideoPlayerController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.asset(widget.assetPath)
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (mounted) {
          _ctrl.play();
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ctrl.value.isInitialized) return const SizedBox.expand();

    return ClipRect(
      child: Transform.scale(
        scale: widget.cropScale,
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width:  _ctrl.value.size.width,
              height: _ctrl.value.size.height,
              child: VideoPlayer(_ctrl),
            ),
          ),
        ),
      ),
    );
  }
}
