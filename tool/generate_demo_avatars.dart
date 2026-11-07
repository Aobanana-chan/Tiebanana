// 在仓库根执行 dart run tool/generate_demo_avatars.dart。
// 自绘几何小猫头像，输出为纯 Dart 图片数据。
import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const backgrounds = [
    0xdce9f5,
    0xf6e3d1,
    0xe3e9d5,
    0xe9e0f3,
    0xf5dce1,
    0xd8edeb,
    0xf5ebce,
    0xdfe3f3,
  ];
  const coats = [0x727f99, 0xc58c61, 0x929b77, 0x9983b1];
  img.ColorRgb8 color(int hex) =>
      img.ColorRgb8(hex >> 16, (hex >> 8) & 255, hex & 255);
  final avatars = <String>[];
  for (var i = 0; i < 16; i++) {
    final image = img.Image(width: 128, height: 128);
    final coat = color(coats[i % coats.length]);
    final ink = color(0x343849);
    img.fill(image, color: color(backgrounds[i % backgrounds.length]));
    img.fillCircle(image, x: 64, y: 129, radius: 48, color: coat);
    img.fillPolygon(image,
        vertices: [img.Point(25, 53), img.Point(27, 16), img.Point(54, 40)],
        color: coat);
    img.fillPolygon(image,
        vertices: [img.Point(74, 40), img.Point(101, 16), img.Point(103, 53)],
        color: coat);
    img.fillPolygon(image,
        vertices: [img.Point(31, 43), img.Point(32, 27), img.Point(46, 42)],
        color: color(0xe9b9b3));
    img.fillPolygon(image,
        vertices: [img.Point(82, 42), img.Point(96, 27), img.Point(97, 43)],
        color: color(0xe9b9b3));
    img.fillCircle(image, x: 64, y: 64, radius: 42, color: coat);
    img.fillCircle(image, x: 64, y: 77, radius: 24, color: color(0xf8f0e5));
    for (final x in [47, 81]) {
      img.fillCircle(image, x: x, y: 61, radius: 4, color: ink);
      img.fillCircle(image, x: x - 1, y: 60, radius: 1, color: color(0xffffff));
    }
    img.fillPolygon(image,
        vertices: [img.Point(59, 73), img.Point(69, 73), img.Point(64, 78)],
        color: ink);
    img.drawLine(image,
        x1: 64, y1: 77, x2: 64, y2: 82, color: ink, thickness: 2);
    img.drawLine(image,
        x1: 64, y1: 82, x2: 58, y2: 85, color: ink, thickness: 2);
    img.drawLine(image,
        x1: 64, y1: 82, x2: 70, y2: 85, color: ink, thickness: 2);
    for (final x in [35, 93]) {
      img.fillCircle(image, x: x, y: 74, radius: 6, color: color(0xe5a9a0));
    }
    if (i.isOdd) {
      img.drawLine(image,
          x1: 58, y1: 28, x2: 61, y2: 40, color: ink, thickness: 3);
      img.drawLine(image,
          x1: 70, y1: 28, x2: 67, y2: 40, color: ink, thickness: 3);
    }
    avatars.add('data:image/png;base64,${base64Encode(img.encodePng(image))}');
  }
  File('packages/tieba_contract/lib/src/testing/demo_avatars.dart')
      .writeAsStringSync(
    "part of 'demo_tieba_api.dart';\n\n"
    '// 自绘演示头像，由 tool/generate_demo_avatars.dart 生成。\n'
    '${avatars.indexed.map((entry) => "const String _demoAvatar${entry.$1} = '${entry.$2}';").join('\n')}\n\n'
    'const List<String> _demoAvatars = <String>[\n'
    '${List.generate(avatars.length, (i) => '  _demoAvatar$i,').join('\n')}\n];\n',
  );
}
