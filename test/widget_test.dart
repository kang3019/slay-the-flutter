import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slay_the_flutter/application/meta_progress_provider.dart';
import 'package:slay_the_flutter/main.dart';
import 'package:slay_the_flutter/presentation/map/map_constants.dart';

void main() {
  testWidgets('앱이 오류 없이 실행되고 MapScreen을 표시한다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const App(),
      ),
    );
    await tester.pump();

    // AppRouter가 RunPhase.map 초기 상태에서 MapScreen을 표시해야 한다.
    expect(find.text(MapStrings.screenTitle), findsOneWidget);
    expect(find.text(MapStrings.hintFirst), findsOneWidget);
  });
}
