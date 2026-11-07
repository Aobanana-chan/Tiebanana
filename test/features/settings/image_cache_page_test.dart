import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiebanana/core/cache/image_cache_manager.dart';
import 'package:tiebanana/features/settings/pages/image_cache_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/widgets/setting_group.dart';

Finder switchOf(String title) => find.descendant(
      of: find.ancestor(
          of: find.text(title), matching: find.byType(SettingRow)),
      matching: find.byType(Switch),
    );

class PageTestCacheManager extends ImageCacheManager {
  int bytes = 2048;
  @override
  Future<void> loadPolicy() async {}
  @override
  Future<int> sizeBytes() async => bytes;
  @override
  Future<ImageCacheCleanupResult> clean(
      {bool all = false, DateTime? now}) async {
    final removed = bytes;
    bytes = 0;
    return ImageCacheCleanupResult(removed, 0);
  }
}

void main() {
  late ImageCacheManager manager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    manager = PageTestCacheManager();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(
        theme: TiebananaTheme.light(seedOf('default'), 14),
        home: ImageCachePage(manager: manager),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('显示大小，确认后调用清理并更新占用', (tester) async {
    await pumpPage(tester);
    expect(find.text('2.0 KiB'), findsOneWidget);
    await tester.tap(find.text('立即清理'));
    await tester.pumpAndSettle();
    expect(find.text('清理图片缓存？'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('清理'));
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect((manager as PageTestCacheManager).bytes, 0);
    expect(find.text('0 B'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('自动清理开关、输入校验与规则保存', (tester) async {
    await pumpPage(tester);
    expect(tester.widget<Switch>(switchOf('自动清理')).value, isFalse);
    expect(tester.widget<Switch>(switchOf('按时间清理')).onChanged, isNull);
    await tester.tap(switchOf('自动清理'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '0');
    await tester.ensureVisible(find.text('保存设置'));
    await tester.tap(find.text('保存设置'));
    await tester.pumpAndSettle();
    expect(find.text('请输入 1–3650 的整数'), findsOneWidget);
    expect(manager.policy.enabled, isFalse);
    await tester.ensureVisible(find.byType(TextFormField).first);
    await tester.enterText(find.byType(TextFormField).first, '14');
    await tester.ensureVisible(find.text('保存设置'));
    await tester.runAsync(() async {
      await tester.tap(find.text('保存设置'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(manager.policy.enabled, isTrue);
    expect(manager.policy.days, 14);
    expect(tester.takeException(), isNull);
  });
}
