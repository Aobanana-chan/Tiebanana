# 界面截图

截图来自 Tiebanana 1.0.0 的 Android profile 构建，使用公开演示后端、宝石蓝深色主题，
分辨率为 1080 × 1920。

| 文件 | 页面 |
| --- | --- |
| `home.png` | 首页 |
| `forum.png` | 吧页 |
| `thread.png` | 帖子 |
| `message.png` | 消息 |
| `profile.png` | 个人 |

用户头像为项目自绘的内置演示图片。昵称、正文、计数和消息均为演示数据。
帖子配图与吧头像由演示数据中的网络图片地址加载。

更新截图时，先确认根目录的 `pubspec_overrides.yaml` 使用
`packages/tieba_backend_demo`，然后构建并安装：

```bash
flutter pub get
dart run build_runner build
flutter build apk --profile --target-platform android-x64
adb -s <设备ID> install -r build/app/outputs/flutter-apk/app-profile.apk
```

在设备上打开目标页面，执行：

```bash
dart run tool/capture_screenshot.dart <设备ID> home
```

其余页面将最后一个参数替换为表格中的文件名（省略 `.png`）。
设备架构为 ARM 时，构建参数使用 `android-arm64`。
