import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slay_the_flutter/main.dart';
import 'package:slay_the_flutter/presentation/battle/battle_constants.dart';

void main() {
  testWidgets('BattleScreen 연기 테스트 — 앱이 오류 없이 실행된다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pump();

    expect(find.text(BattleStrings.endTurn), findsOneWidget);
    expect(find.text('${BattleStrings.stageLabel} 1'), findsOneWidget);
  });
}
