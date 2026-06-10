import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slay_the_flutter/application/meta_progress_provider.dart';
import 'package:slay_the_flutter/data/local_storage.dart';
import 'package:slay_the_flutter/main.dart';
import 'package:slay_the_flutter/presentation/intro/intro_constants.dart';

void main() {
  testWidgets('앱이 오류 없이 실행되고 IntroScreen을 표시한다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(LocalStorage(prefs)),
        ],
        child: const App(),
      ),
    );
    await tester.pump();

    // 앱 진입점은 IntroScreen — 게임 시작 버튼이 표시되어야 한다.
    expect(find.text(IntroStrings.startGame), findsOneWidget);
  });
}
