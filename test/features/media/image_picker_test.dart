import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tiebanana/features/media/state/image_upload.dart';
import 'package:tiebanana/features/media/pages/image_picker_page.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';
import 'package:tiebanana/shared/theme/tiebanana_theme.dart';
import 'package:tiebanana/shared/content/emoji_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.fluttercandies/photo_manager');
  var permission = PermissionState.authorized;
  var empty = false;
  var settingsOpened = false;
  var albumQueries = 0;
  final permissionRequests = <Map<dynamic, dynamic>>[];
  setUp(() {
    permission = PermissionState.authorized;
    empty = false;
    settingsOpened = false;
    albumQueries = 0;
    permissionRequests.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'requestPermissionExtend':
          permissionRequests.add(call.arguments as Map<dynamic, dynamic>);
          return permission.index;
        case 'getSystemVersion':
          return '34';
        case 'getAssetPathList':
          albumQueries++;
          return {
            'data': empty
                ? []
                : [
                    {
                      'id': 'all',
                      'name': '最近项目',
                      'isAll': true,
                      'assetCount': 2
                    },
                    {
                      'id': 'other',
                      'name': '另一个相册',
                      'isAll': false,
                      'assetCount': 2
                    },
                  ]
          };
        case 'getAssetListPaged':
          return {
            'data': [
              for (var i = 0; i < 2; i++)
                {'id': '$i', 'type': 1, 'width': 100, 'height': 200},
            ]
          };
        case 'getThumb':
          return null;
        case 'openSetting':
          settingsOpened = true;
          return null;
        default:
          return null;
      }
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  Future<void> open(WidgetTester tester, {bool dark = false}) async {
    await tester.pumpWidget(MaterialApp(
      theme: dark
          ? TiebananaTheme.dark(seedOf('blue'), 16)
          : TiebananaTheme.light(seedOf('blue'), 16),
      home: const ImagePickerRoute(),
    ));
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    testWidgets('分区、已选删除与原图开关 dark=$dark', (tester) async {
      await open(tester, dark: dark);
      expect(find.text('已选 0 张'), findsOneWidget);
      final button = tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '请选择图片'));
      expect(button.onPressed, isNull);
      await tester.tap(find.byType(ImageSelectionTile).first);
      await tester.pumpAndSettle();
      expect(find.text('已选 1 张'), findsOneWidget);
      expect(find.text('添加（1）'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      await tester.tap(find.byType(ImageSelectionTile).first);
      await tester.pumpAndSettle();
      expect(find.text('已选 0 张'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('换相册保留已选资源', (tester) async {
    await open(tester);
    await tester.tap(find.byType(ImageSelectionTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('全部相册 ›'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('另一个相册'));
    await tester.pumpAndSettle();
    expect(find.text('已选 1 张'), findsOneWidget);
    expect(albumQueries, 2);
  });

  testWidgets('头像模式只能选一张，不显示原图开关', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: const ImagePickerRoute(singleSelection: true),
    ));
    await tester.pumpAndSettle();
    expect(find.text('选择头像'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    await tester.tap(find.byType(ImageSelectionTile).first);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recent-1')));
    await tester.pumpAndSettle();
    expect(
        tester.widget<ImagePickerFooter>(find.byType(ImagePickerFooter)).count,
        1);
    expect(
        tester
            .widget<ImageSelectionTile>(
                find.byKey(const ValueKey('selected-1')))
            .image
            .id,
        '1');
    expect(find.text('添加（2）'), findsNothing);
  });

  testWidgets('只申请图片读取权限，不申请视频、音频或位置信息', (tester) async {
    await open(tester);
    expect(permissionRequests, hasLength(1));
    expect(permissionRequests.single['androidPermission'], {
      'type': RequestType.image.value,
      'mediaLocation': false,
    });
    expect(permissionRequests.single['iosAccessLevel'],
        IosAccessLevel.readWrite.index + 1);
  });

  testWidgets('拒绝权限给设置入口，返回后重新读取相册', (tester) async {
    permission = PermissionState.denied;
    await open(tester);
    expect(find.text('需要访问相册'), findsOneWidget);
    await tester.tap(find.text('去设置'));
    await tester.pumpAndSettle();
    expect(settingsOpened, isTrue);
    expect(albumQueries, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    permission = PermissionState.authorized;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('需要访问相册'), findsNothing);
    expect(find.byType(ImageSelectionTile), findsNWidgets(2));
    expect(albumQueries, 1);
  });

  testWidgets('部分权限与空相册', (tester) async {
    permission = PermissionState.limited;
    empty = true;
    await open(tester);
    expect(find.text('目前只授权了部分照片'), findsOneWidget);
    expect(find.text('相册里还没有照片'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('失败配图有重试与移除入口，小屏大字号不溢出', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final model = ImageUploadProviderModel('测试吧');
    addTearDown(model.dispose);
    final task = model.enqueue(
        AssetEntity(id: '1', typeInt: 1, width: 100, height: 200), false);
    task.error = '模拟失败';
    var retried = false;
    var removed = false;
    await tester.pumpWidget(MaterialApp(
      theme: TiebananaTheme.dark(seedOf('blue'), 22.5),
      home: Scaffold(
          body: SizedBox(
              height: 267,
              child: ImagePanel(
                  uploaded: const {},
                  tasks: model.tasks,
                  onAddImage: () {},
                  onRetry: (_) => retried = true,
                  onRemove: (_) => removed = true))),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('重试'));
    await tester.tap(find.byTooltip('移除图片'));
    expect(retried, isTrue);
    expect(removed, isTrue);
    expect(model.hasPending, isTrue);
    model.remove(task);
    expect(model.hasPending, isFalse);
    expect(tester.takeException(), isNull);
  });
}
