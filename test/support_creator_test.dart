import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskapp/utils/app_theme.dart';
import 'package:taskapp/utils/external_link_helper.dart';
import 'package:taskapp/widgets/support_creator_card.dart';

void main() {
  group('ExternalLinkHelper', () {
    test('isValidHttpUrl accepts http/https URLs and rejects invalid schemes', () {
      expect(ExternalLinkHelper.isValidHttpUrl('https://saweria.co/yusufarrofi'), isTrue);
      expect(ExternalLinkHelper.isValidHttpUrl('https://ko-fi.com/yusufarrofi/'), isTrue);
      expect(ExternalLinkHelper.isValidHttpUrl('https://yapp.ink/yusufarrofi21'), isTrue);
      expect(ExternalLinkHelper.isValidHttpUrl('http://example.com'), isTrue);
      expect(ExternalLinkHelper.isValidHttpUrl('javascript:alert(1)'), isFalse);
      expect(ExternalLinkHelper.isValidHttpUrl('not-a-url'), isFalse);
    });
  });

  group('SupportCreatorCard', () {
    testWidgets('renders all 3 support platforms cleanly on narrow viewports', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: SupportCreatorCard(),
            ),
          ),
        ),
      );

      expect(find.text('Dukung Pengembangan TaskApp'), findsOneWidget);
      expect(find.text('Saweria'), findsOneWidget);
      expect(find.text('Ko-fi'), findsOneWidget);
      expect(find.text('Yapp.ink'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping each platform invokes launcher with the exact URL', (tester) async {
      final launchedUrls = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SupportCreatorCard(
                launcherOverride: (url) async {
                  launchedUrls.add(url);
                  return true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Saweria'));
      await tester.pump();
      await tester.tap(find.text('Ko-fi'));
      await tester.pump();
      await tester.tap(find.text('Yapp.ink'));
      await tester.pump();

      expect(launchedUrls, [
        'https://saweria.co/yusufarrofi',
        'https://ko-fi.com/yusufarrofi/',
        'https://yapp.ink/yusufarrofi21',
      ]);
    });

    testWidgets('copy button copies exact URL to clipboard and shows snackbar', (tester) async {
      String? clipboardText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SupportCreatorCard(),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Salin tautan Yapp.ink'));
      await tester.pump();

      expect(clipboardText, 'https://yapp.ink/yusufarrofi21');
      expect(find.text('Tautan Yapp.ink disalin ke clipboard!'), findsOneWidget);
    });
  });
}
