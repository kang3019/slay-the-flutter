import '../../application/run_provider.dart';

/// 세이브 슬롯 하나의 데이터 — 런 상태 스냅샷과 저장 메타 정보.
///
/// 순수 Dart 클래스 — Flutter·Riverpod import 금지.
class SaveSlot {
  /// 슬롯 번호 (1~3).
  final int slotId;

  /// 저장된 런 상태 스냅샷.
  final RunState runState;

  /// 슬롯에 저장된 시각.
  final DateTime savedAt;

  const SaveSlot({
    required this.slotId,
    required this.runState,
    required this.savedAt,
  });

  // ── 표시용 게터 ──────────────────────────────────────────────────────────

  /// "YYYY-MM-DD HH:mm" 형식의 저장 시각 문자열.
  String get savedAtLabel {
    final y = savedAt.year.toString().padLeft(4, '0');
    final m = savedAt.month.toString().padLeft(2, '0');
    final d = savedAt.day.toString().padLeft(2, '0');
    final h = savedAt.hour.toString().padLeft(2, '0');
    final min = savedAt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  /// "Floor N" 형식의 현재 층 문자열.
  String get stageLabel {
    final floor = runState.floor;
    if (floor < 0) return '시작 전';
    return 'Floor ${floor + 1}';
  }

  // ── 직렬화 ────────────────────────────────────────────────────────────────

  /// SharedPreferences 저장을 위한 JSON 직렬화.
  Map<String, dynamic> toJson() => {
    'slotId':   slotId,
    'savedAt':  savedAt.toIso8601String(),
    'runState': runState.toJson(),
  };

  /// JSON에서 [SaveSlot]을 복원한다.
  static SaveSlot fromJson(Map<String, dynamic> json) => SaveSlot(
    slotId:   json['slotId']  as int,
    savedAt:  DateTime.parse(json['savedAt'] as String),
    runState: RunState.fromJson(json['runState'] as Map<String, dynamic>),
  );
}
