# 私有后端构建

公开构建默认使用 `packages/tieba_backend_demo`（本地数据，不联网）。
需要真实贴吧协议时，用这里的 `pubspec_overrides.example.yaml` 把应用依赖的
`tieba_backend_demo` 地址替换成本目录下的私有适配包；应用源码不需要改动。

## 用法

```bash
git submodule update --init packages/tieba_contract packages/headless_tieba
# Linux / macOS
cp tool/private/pubspec_overrides.example.yaml pubspec_overrides.yaml
# Windows
copy tool\private\pubspec_overrides.example.yaml pubspec_overrides.yaml

flutter pub get
dart run build_runner build
flutter build apk --split-per-abi
```

`pubspec_overrides.yaml` 只在仓库根目录生效，且已被 `.gitignore` 忽略。

## 恢复演示后端

删除根目录的 `pubspec_overrides.yaml` 后重新 `flutter pub get` 即可：

```bash
rm pubspec_overrides.yaml   # Windows: del pubspec_overrides.yaml
flutter pub get
```

界面测试直接使用 `package:tieba_contract/testing.dart` 里的 `DemoTiebaApi`，
所以保留 override 也能正常运行 `flutter test`；上面的恢复步骤只用于运行 /
构建公开演示后端（`flutter run`、公开 APK）。
