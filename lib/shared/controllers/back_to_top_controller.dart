/// 页签与主界面之间的「返回先回顶」协作对象。
///
/// 返回键的优先级（见 `lib/features/home/pages/home_page.dart` 的 `onWillPop`）：
/// 1. 搜索栏展开 → 收起搜索栏；
/// 2. 当前页签的列表不在顶部 → 列表回顶并刷新，回顶操作不计入退出次数；
/// 3. 再按一次退出。
///
/// 页签在 `initState` / `dispose` 里注册与注销自己：主界面不需要知道
/// 具体是哪个列表、怎么滚动、怎么刷新。
class BackToTopController {
  Object? _owner;
  bool Function()? _isScrolled;
  Future<void> Function()? _onBackToTop;

  /// 由页签注册。同一时间只认一个注册者。
  void attach(
    Object owner, {
    required bool Function() isScrolled,
    required Future<void> Function() onBackToTop,
  }) {
    _owner = owner;
    _isScrolled = isScrolled;
    _onBackToTop = onBackToTop;
  }

  /// 仅注册者本人可以注销。
  void detach(Object owner) {
    if (!identical(_owner, owner)) {
      return;
    }
    _owner = null;
    _isScrolled = null;
    _onBackToTop = null;
  }

  /// 列表是否已离开顶部。没有注册者或已在顶部时为 false。
  bool get needsBackToTop => _isScrolled?.call() ?? false;

  /// 回顶并刷新。无注册者时直接返回。
  Future<void> backToTop() async => await _onBackToTop?.call();
}
