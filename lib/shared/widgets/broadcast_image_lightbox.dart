import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tiebanana/shared/layout/app_breakpoints.dart';
import 'package:tiebanana/shared/media/img_explorer.dart';
import 'package:tiebanana/shared/theme/tiebanana_tokens.dart';

/// 吧广播配图预览：窄屏沿用全屏图片浏览，桌面端（`>= 720dp`）弹出居中灯箱，
/// 支持滚轮/按钮缩放与 `Esc` 关闭，避免强行跳出当前广播上下文。
Future<void> showBroadcastImageLightbox(
  BuildContext context, {
  required String url,
  String title = '',
  String forumName = '',
  bool? desktop,
}) async {
  if (url.isEmpty) return;
  final bool isDesktop =
      desktop ?? MediaQuery.sizeOf(context).width >= AppBreakpoints.compactMax;
  if (!isDesktop) {
    await Navigator.of(context).push(
      ImageExplorerRoute(
        builder: (_) => ZoomedImgExplorer(
          imgUrls: <String>[url],
          heroTagSalt: 'broadcast-$url',
        ),
      ),
    );
    return;
  }

  final TiebananaTokens tokens = TiebananaTokens.of(context);
  await showDialog<void>(
    context: context,
    barrierColor: tokens.imageScrim.withValues(alpha: 0.56),
    builder: (BuildContext dialogContext) => _DesktopBroadcastLightbox(
      url: url,
      title: title,
      forumName: forumName,
    ),
  );
}

class _DesktopBroadcastLightbox extends StatefulWidget {
  const _DesktopBroadcastLightbox({
    required this.url,
    required this.title,
    required this.forumName,
  });

  final String url;
  final String title;
  final String forumName;

  @override
  State<_DesktopBroadcastLightbox> createState() =>
      _DesktopBroadcastLightboxState();
}

class _DesktopBroadcastLightboxState extends State<_DesktopBroadcastLightbox> {
  final TransformationController _transform = TransformationController();
  double _scale = 1.0;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _setScale(double next) {
    final double clamped = next.clamp(1.0, 3.0);
    setState(() => _scale = clamped);
    _transform.value = Matrix4.diagonal3Values(clamped, clamped, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    final Size size = MediaQuery.sizeOf(context);
    final String titleText =
        widget.title.trim().isNotEmpty ? widget.title.trim() : '广播配图预览';
    final String forumText = widget.forumName.trim();
    final String forumLabel = forumText.isEmpty
        ? ''
        : (forumText.endsWith('吧') ? forumText : '$forumText吧');

    return Dialog(
      backgroundColor: tokens.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 18,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: tokens.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: size.height * 0.86,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 10, 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: tokens.line)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      titleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: tokens.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭 (Esc)',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded,
                        size: 18, color: tokens.textTertiary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: (size.height * 0.52).clamp(240.0, 420.0),
                  color: const Color(0xFF0E1218),
                  child: Listener(
                    onPointerSignal: (PointerSignalEvent event) {
                      if (event is PointerScrollEvent) {
                        final double delta =
                            event.scrollDelta.dy < 0 ? 0.2 : -0.2;
                        _setScale(_scale + delta);
                      }
                    },
                    child: InteractiveViewer(
                      transformationController: _transform,
                      minScale: 1.0,
                      maxScale: 3.0,
                      onInteractionEnd: (_) {
                        final double current =
                            _transform.value.getMaxScaleOnAxis();
                        if (mounted) setState(() => _scale = current);
                      },
                      child: Center(
                        child: Image.network(
                          widget.url,
                          fit: BoxFit.contain,
                          errorBuilder: (BuildContext context, Object error,
                              StackTrace? stack) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(Icons.broken_image_outlined,
                                    size: 32, color: Colors.white54),
                                const SizedBox(height: 8),
                                const Text(
                                  '图片未能加载',
                                  style: TextStyle(
                                      color: Colors.white60, fontSize: 12),
                                ),
                              ],
                            );
                          },
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white70,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      forumLabel.isEmpty ? '按 Esc 或点击空白处关闭' : '来源：$forumLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  _ZoomBtn(
                    label: '-',
                    tooltip: '缩小',
                    onTap:
                        _scale > 1.01 ? () => _setScale(_scale - 0.25) : null,
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${(_scale * 100).round()}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 12,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                  _ZoomBtn(
                    label: '+',
                    tooltip: '放大',
                    onTap:
                        _scale < 2.99 ? () => _setScale(_scale + 0.25) : null,
                  ),
                  const SizedBox(width: 6),
                  _ZoomBtn(
                    label: '1:1',
                    tooltip: '重置缩放',
                    onTap: _scale != 1.0 ? () => _setScale(1.0) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  const _ZoomBtn({
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TiebananaTokens tokens = TiebananaTokens.of(context);
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          side: BorderSide(color: tokens.line),
          minimumSize: const Size(32, 28),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle:
              const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}
