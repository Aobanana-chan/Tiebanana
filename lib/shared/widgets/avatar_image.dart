import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tiebanana/core/cache/avatar_image_cache.dart';

/// URL 不变时复用已有请求；切换 URL 后丢弃旧请求的结果。
class AvatarImage extends StatefulWidget {
  const AvatarImage({super.key, required this.url, this.cache});

  final String url;
  final AvatarImageCache? cache;

  @override
  State<AvatarImage> createState() => _AvatarImageState();
}

class _AvatarImageState extends State<AvatarImage> {
  StreamSubscription<Uint8List>? _subscription;
  Uint8List? _bytes;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.cache != widget.cache) _load();
  }

  void _load() {
    final generation = ++_generation;
    _subscription?.cancel();
    _bytes = null;
    _subscription = (widget.cache ?? AvatarImageCache.shared)
        .watch(widget.url)
        .listen((bytes) {
      if (mounted && generation == _generation) {
        setState(() => _bytes = bytes);
      }
    });
  }

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _bytes == null
      ? const SizedBox.expand()
      : Image.memory(_bytes!, fit: BoxFit.cover, gaplessPlayback: true);
}
