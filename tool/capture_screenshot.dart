// dart run tool/capture_screenshot.dart <设备 ID> <页面名>
// 将 Android 当前界面保存到 docs/screenshots/<页面名>.png。
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.length != 2 || !RegExp(r'^[a-z_]+$').hasMatch(args[1])) {
    stderr.writeln('用法：dart run tool/capture_screenshot.dart <设备 ID> <页面名>');
    exitCode = 64;
    return;
  }
  final result = await Process.run(
    'adb',
    ['-s', args[0], 'exec-out', 'screencap', '-p'],
    stdoutEncoding: null,
  );
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exitCode = result.exitCode;
    return;
  }
  final file = File('docs/screenshots/${args[1]}.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(result.stdout as List<int>);
  stdout.writeln(file.path);
}
