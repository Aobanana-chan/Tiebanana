import 'package:flutter/foundation.dart';

bool get isDesktop =>
    !kIsWeb &&
    const {
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.macOS,
    }.contains(defaultTargetPlatform);

bool get isWindows =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
