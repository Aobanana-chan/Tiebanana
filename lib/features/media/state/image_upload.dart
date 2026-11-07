import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tieba_contract/tieba_contract.dart';
import 'package:tiebanana/app/global.dart';

///图片上传notify
class ImageUploadTask {
  ImageUploadTask(this.asset, this.saveOrigin);
  final AssetEntity asset;
  final bool saveOrigin;
  int sent = 0;
  int total = 0;
  bool uploading = false;
  String? error;
  TiebaUploadedImage? result;
}

class ImageUploadProviderModel with ChangeNotifier {
  ImageUploadProviderModel(this._forumnName);
  late final String _forumnName;
  final Map<TiebaUploadedImage, AssetEntity> _picture = {};
  final List<ImageUploadTask> tasks = [];
  bool _disposed = false;
  bool get hasPending => tasks.any((t) => t.result == null);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  ImageUploadTask enqueue(AssetEntity asset, bool saveOrigin) {
    for (final existing in tasks) {
      if (existing.asset.id == asset.id) return existing;
    }
    final task = ImageUploadTask(asset, saveOrigin);
    tasks.add(task);
    _notify();
    return task;
  }

  void remove(ImageUploadTask task) {
    if (task.uploading) return;
    tasks.remove(task);
    if (task.result != null) _picture.remove(task.result);
    _notify();
  }

  Future<TiebaUploadedImage?> upload(ImageUploadTask task) async {
    if (_disposed ||
        !tasks.contains(task) ||
        task.uploading ||
        task.result != null) {
      return null;
    }
    task.uploading = true;
    task.error = null;
    task.sent = 0;
    task.total = 0;
    _notify();
    try {
      final file =
          task.saveOrigin ? await task.asset.originFile : await task.asset.file;
      if (file == null) throw StateError('读取图片文件失败');
      if (_disposed) return null;
      final result = await Global.tiebaAPI.uploadPicture(
        _forumnName,
        task.saveOrigin,
        UploadFile(
            path: file.path,
            width: task.asset.width,
            height: task.asset.height,
            resourceId: task.asset.id,
            onProgress: (sent, total) {
              task.sent = sent;
              task.total = total;
              _notify();
            }),
      );
      if (_disposed) return null;
      task.result = result;
      _picture[result] = task.asset;
      return result;
    } catch (e) {
      task.error = e.toString();
      return null;
    } finally {
      task.uploading = false;
      _notify();
    }
  }

  Map<TiebaUploadedImage, AssetEntity> get pictures => _picture;
}
