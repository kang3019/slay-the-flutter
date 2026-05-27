import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slay_the_flutter/application/meta_progress_provider.dart';
import 'package:slay_the_flutter/main.dart';
import 'package:slay_the_flutter/presentation/battle/battle_constants.dart';

void main() {
  testWidgets('BattleScreen 연기 테스트 — 앱이 오류 없이 실행된다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const App(),
      ),
    );
    await tester.pump();

    expect(find.text(BattleStrings.endTurn), findsOneWidget);
    expect(find.text('${BattleStrings.stageLabel} 1'), findsOneWidget);
  });
}
