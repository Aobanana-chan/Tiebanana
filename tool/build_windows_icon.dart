import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as image;

/// 从应用源图生成多尺寸 Windows ICO：dart run tool/build_windows_icon.dart
void main() {
  final source = image
      .decodePng(File('assets/icon/ic_launcher_round.png').readAsBytesSync())!;
  final sizes = [16, 24, 32, 48, 64, 128, 256];
  final frames = [
    for (final size in sizes)
      image.encodePng(image.copyResize(source, width: size, height: size))
  ];
  final header = ByteData(6 + 16 * sizes.length);
  header.setUint16(2, 1, Endian.little);
  header.setUint16(4, sizes.length, Endian.little);
  var offset = header.lengthInBytes;
  for (var i = 0; i < sizes.length; i++) {
    final at = 6 + 16 * i;
    header.setUint8(at, sizes[i] % 256);
    header.setUint8(at + 1, sizes[i] % 256);
    header.setUint16(at + 4, 1, Endian.little);
    header.setUint16(at + 6, 32, Endian.little);
    header.setUint32(at + 8, frames[i].length, Endian.little);
    header.setUint32(at + 12, offset, Endian.little);
    offset += frames[i].length;
  }
  File('windows/runner/resources/app_icon.ico').writeAsBytesSync([
    ...header.buffer.asUint8List(),
    for (final frame in frames) ...frame,
  ]);
}
