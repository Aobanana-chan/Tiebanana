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

  testWidgets('Windows 使用文件选择器，多次选择保留图片，不申请相册权限', (tester) async {
    var pick = 0;
    await tester.pumpWidget(MaterialApp(
      theme: TiebananaTheme.light(seedOf('blue'), 16),
      home: ImagePickerRoute(
          filePicker: (_) async => [
                AssetEntity(
                    id: '${pick++}', typeInt: 1, width: 100, height: 200),
              ]),
    ));
    await tester.pumpAndSettle();
    expect(find.text('已选 1 张'), findsOneWidget);
    await tester.tap(find.text('选择文件'));
    await tester.pumpAndSettle();
    expect(find.text('已选 2 张'), findsOneWidget);
    expect(permissionRequests, isEmpty);
    expect(albumQueries, 0);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

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

  testWidgets('宽屏桌面文件模式：空态、双栏检视、保序调整与灯箱预览', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var round = 0;
    List<dynamic>? poppedResult;
    await tester.pumpWidget(MaterialApp(
      theme: TiebananaTheme.light(seedOf('blue'), 14),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              poppedResult = await Navigator.push<List<dynamic>>(
                context,
                MaterialPageRoute(
                  builder: (_) => ImagePickerRoute(
                    filePicker: (_) async {
                      round++;
                      if (round == 1) return <AssetEntity>[];
                      return <AssetEntity>[
                        AssetEntity(
                            id: 'file-a',
                            typeInt: 1,
                            width: 1920,
                            height: 1080),
                        AssetEntity(
                            id: 'file-b', typeInt: 1, width: 800, height: 600),
                      ];
                    },
                  ),
                ),
              );
            },
            child: const Text('打开选图'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('打开选图'));
    await tester.pumpAndSettle();

    // 首次返回空列表时显示虚线引导空态，不留空白
    expect(find.text('从本地文件夹选择图片'), findsOneWidget);
    expect(find.text('已选 0 张'), findsOneWidget);

    // 再次选择两张图片，展示双栏网格与右侧检视顺序
    await tester.tap(find.text('从文件夹选择'));
    await tester.pumpAndSettle();
    expect(find.text('已选 2 张'), findsOneWidget);
    expect(find.text('焦点预览与顺序'), findsOneWidget);
    expect(find.text('发送顺序（2）'), findsOneWidget);
    expect(find.text('1920 × 1080 px'), findsOneWidget);

    // 点击第二张图片切换焦点而不误删
    await tester.tap(find.byKey(const ValueKey('selected-file-b')));
    await tester.pumpAndSettle();
    expect(find.text('已选 2 张'), findsOneWidget);
    expect(find.text('800 × 600 px'), findsOneWidget);

    // 将第 2 张上移到第 1 位
    await tester.tap(find.byTooltip('上移').last);
    await tester.pumpAndSettle();

    // 打开居中灯箱预览并测试缩放与翻页
    await tester.tap(find.text('放大查看'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    await tester.tap(find.byTooltip('放大'));
    await tester.pumpAndSettle();
    expect(find.text('125%'), findsOneWidget);
    await tester.tap(find.text('下一张'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();

    // 开启原图并确认返回：保持调序后的 LinkedHashSet 顺序
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加（2）'));
    await tester.pumpAndSettle();

    expect(poppedResult, isNotNull);
    final selected = poppedResult![0] as Set<AssetEntity>;
    expect(selected.map((e) => e.id).toList(), <String>['file-b', 'file-a']);
    expect(poppedResult![1], isTrue);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('宽屏桌面头像模式：隐藏原图开关并展示头像校验面板', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: TiebananaTheme.dark(seedOf('pink'), 14),
      home: ImagePickerRoute(
        singleSelection: true,
        filePicker: (_) async => <AssetEntity>[
          AssetEntity(id: 'av-1', typeInt: 1, width: 1024, height: 1024),
        ],
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('选择头像'), findsOneWidget);
    expect(find.text('头像预览与校验'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    expect(find.text('裁切头像'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('宽屏相册模式：1280 三栏切换相册保留已选，1080 收起左栏改用弹窗', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await open(tester);
    expect(find.text('全部相册'), findsOneWidget);
    expect(find.text('另一个相册'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('recent-0')));
    await tester.pumpAndSettle();
    expect(find.text('发送顺序（1）'), findsOneWidget);

    await tester.tap(find.text('另一个相册'));
    await tester.pumpAndSettle();
    expect(albumQueries, 2);
    expect(find.text('添加（1）'), findsOneWidget);

    // 收缩到 1080dp：左侧相册目录收起，改为按钮弹窗切换
    tester.view.physicalSize = const Size(1080, 800);
    await tester.pumpAndSettle();
    expect(find.text('全部相册 ›'), findsOneWidget);
    await tester.tap(find.text('全部相册 ›'));
    await tester.pumpAndSettle();
    expect(find.text('全部相册'), findsOneWidget);
    await tester.tap(find.text('最近项目').last);
    await tester.pumpAndSettle();
    expect(albumQueries, 3);
    expect(tester.takeException(), isNull);
  });

  for (final width in <double>[1280, 1080, 820, 640]) {
    testWidgets('多断点宽度 $width 下桌面选图无溢出', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        theme: TiebananaTheme.light(seedOf('blue'), 16),
        home: ImagePickerRoute(
          filePicker: (_) async => <AssetEntity>[
            AssetEntity(id: 'w1', typeInt: 1, width: 1200, height: 800),
            AssetEntity(id: 'w2', typeInt: 1, width: 800, height: 1200),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('已选 2 张'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  }
}
