import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/meta_progress.dart';

/// 전투 종료 후 맵 화면에 표시할 레벨업 결과를 임시 보관하는 provider.
///
/// BattleScreen에서 레벨업 시 값을 설정하고,
/// MapScreen에서 다이얼로그를 표시한 뒤 null로 초기화한다.
final levelUpPendingProvider = StateProvider<LevelUpResult?>((ref) => null);
