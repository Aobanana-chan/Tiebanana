import 'package:flutter/material.dart';
import 'package:tiebanana/core/platform/platform_capabilities.dart';

/// Windows 按手机宽度布局，再随窗口宽度整体等比缩放。
///
/// 放在 MaterialApp.builder 中、Navigator 外，使路由、弹窗和媒体预览
/// 使用相同的约束与 MediaQuery；系统文字缩放保持不变，像素倍率和
/// 安全区、键盘等边距换算到内部布局坐标，避免只放大字体或横向拉伸。
class PhoneViewport extends StatelessWidget {
  const PhoneViewport({super.key, required this.child});

  static const double layoutWidth = 400;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isWindows) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }
        final scale = constraints.maxWidth / layoutWidth;
        final size = Size(layoutWidth, constraints.maxHeight / scale);
        final media = MediaQuery.of(context);
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topLeft,
            child: SizedBox.fromSize(
              size: size,
              child: MediaQuery(
                data: media.copyWith(
                  size: size,
                  devicePixelRatio: media.devicePixelRatio * scale,
                  padding: media.padding / scale,
                  viewPadding: media.viewPadding / scale,
                  viewInsets: media.viewInsets / scale,
                  systemGestureInsets: media.systemGestureInsets / scale,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 抵消手机视口对原生纹理的缩放，让 WebView 按实际显示尺寸渲染。
///
/// Windows WebView 插件读取 FlutterView 的真实 DPI，而非 MediaQuery 的
/// 有效 DPI。先给它实际显示尺寸，再反向缩放占位，可避免低分辨率纹理
/// 被外层放大；指针坐标也由 FittedBox 一并换算。
class NativeResolutionViewport extends StatelessWidget {
  const NativeResolutionViewport({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isWindows) return child;
    final media = MediaQuery.of(context);
    final nativePixelRatio = View.of(context).devicePixelRatio;
    final scale = media.devicePixelRatio / nativePixelRatio;
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest * scale;
      if (size.isEmpty) return const SizedBox.shrink();
      return FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.topLeft,
        child: SizedBox.fromSize(
          size: size,
          child: MediaQuery(
            data: media.copyWith(
              size: size,
              devicePixelRatio: nativePixelRatio,
              padding: media.padding * scale,
              viewPadding: media.viewPadding * scale,
              viewInsets: media.viewInsets * scale,
              systemGestureInsets: media.systemGestureInsets * scale,
            ),
            child: child,
          ),
        ),
      );
    });
  }
}
