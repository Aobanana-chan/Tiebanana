/// 页签与桌面端顶栏之间的「刷新」协作对象。
///
/// 桌面端顶栏点击刷新或按 `F5` / `Ctrl+R` 时，由主界面转发给当前激活的页签，
/// 避免把未显示的离屏页签也一并打出去，并把异步任务交还给顶栏用于展示加载态。
class TabRefreshController {
  Object? _owner;
  Future<void> Function()? _onRefresh;

  /// 当前是否有页签注册。
  bool get isAttached => _owner != null;

  /// 由页签注册。同一时间只认一个注册者。
  void attach(
    Object owner, {
    required Future<void> Function() onRefresh,
  }) {
    _owner = owner;
    _onRefresh = onRefresh;
  }

  /// 仅注册者本人可以注销。
  void detach(Object owner) {
    if (!identical(_owner, owner)) {
      return;
    }
    _owner = null;
    _onRefresh = null;
  }

  /// 触发当前页签刷新。无注册者时直接返回。
  Future<void> refresh() async => await _onRefresh?.call();
}
