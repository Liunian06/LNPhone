import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// 智能表情图片显示组件
/// 支持 PNG、GIF、JPG 等格式，正确处理透明背景
/// 针对 GIF 和 PNG 格式，强制使用内存加载方式以规避 FileImage 在部分设备上的透明度 bug
class EmojiImageWidget extends StatefulWidget {
  final String imagePath;
  final BoxFit fit;
  final Widget? errorWidget;
  final bool useMemoryImage;

  const EmojiImageWidget({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.contain,
    this.errorWidget,
    this.useMemoryImage = false,
  });

  @override
  State<EmojiImageWidget> createState() => _EmojiImageWidgetState();
}

class _EmojiImageWidgetState extends State<EmojiImageWidget> {
  Future<Uint8List>? _imageFuture;

  @override
  void initState() {
    super.initState();
    _initImageFuture();
  }

  @override
  void didUpdateWidget(EmojiImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath ||
        oldWidget.useMemoryImage != widget.useMemoryImage) {
      _initImageFuture();
    }
  }

  void _initImageFuture() {
    final extension = p.extension(widget.imagePath).toLowerCase();
    // 如果是 GIF、PNG 或者显式要求使用内存加载，则初始化 Future
    // PNG 也需要使用 Image.memory 以正确处理透明背景
    if (extension == '.gif' || extension == '.png' || widget.useMemoryImage) {
      _imageFuture = File(widget.imagePath).readAsBytes();
    } else {
      _imageFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final extension = p.extension(widget.imagePath).toLowerCase();

    // 针对 GIF 和 PNG 文件，强制使用 Image.memory
    // 这可以规避 FileImage 在某些 Android 设备上解码导致透明背景变黑的问题
    if (extension == '.gif' || extension == '.png' || widget.useMemoryImage) {
      return FutureBuilder<Uint8List>(
        future: _imageFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: widget.fit,
              gaplessPlayback: true,
              isAntiAlias: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) =>
                  widget.errorWidget ?? const Icon(Icons.broken_image),
            );
          }
          // 加载过程中显示占位符，避免布局跳动
          return const SizedBox();
        },
      );
    }

    // 对于 JPG 等非透明格式，FileImage 工作正常且性能更好
    return Image.file(
      File(widget.imagePath),
      fit: widget.fit,
      isAntiAlias: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) =>
          widget.errorWidget ?? const Icon(Icons.broken_image),
    );
  }
}
