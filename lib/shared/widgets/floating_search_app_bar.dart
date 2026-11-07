import 'package:flutter/material.dart';

/// In-repo replacement for the discontinued
/// `material_floating_search_bar` package, covering only the API surface
/// this app uses: a top search bar with a query field and an optional
/// expandable `body` rendered below it.
class FloatingSearchBarController {
  final TextEditingController _input = TextEditingController();
  final FocusNode focusNode = FocusNode();

  String get query => _input.text;
  set query(String value) {
    _input.text = value;
    _input.selection =
        TextSelection(baseOffset: value.length, extentOffset: value.length);
  }

  void close() => focusNode.unfocus();
  void open() => focusNode.requestFocus();

  bool get isOpen => focusNode.hasFocus;

  void dispose() {
    _input.dispose();
    focusNode.dispose();
  }
}

class FloatingSearchAppBar extends StatefulWidget {
  const FloatingSearchAppBar({
    super.key,
    this.color,
    this.controller,
    this.clearQueryOnClose = false,
    this.onSubmitted,
    this.onQueryChanged,
    this.leadingActions,
    this.hint,
    this.body,
    this.actions,
    this.onFocusChanged,
    this.height = 56.0,
    this.margin,
    this.borderRadius,
    this.shadow,
  });

  final Color? color;
  final FloatingSearchBarController? controller;
  final bool clearQueryOnClose;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onQueryChanged;
  final List<Widget>? leadingActions;
  final String? hint;
  final Widget? body;
  final List<Widget>? actions;
  final ValueChanged<bool>? onFocusChanged;
  final double height;

  /// 药丸形态：搜索栏四周留白（露出页面底色）。null 为旧的全宽直角形态。
  final EdgeInsetsGeometry? margin;

  /// 药丸圆角。null 为全宽直角。
  final BorderRadius? borderRadius;

  /// 药丸投影。
  final List<BoxShadow>? shadow;

  @override
  State<FloatingSearchAppBar> createState() => _FloatingSearchAppBarState();
}

class _FloatingSearchAppBarState extends State<FloatingSearchAppBar> {
  FloatingSearchBarController? _ownController;
  FloatingSearchBarController get controller =>
      widget.controller ?? (_ownController ??= FloatingSearchBarController());

  void _handleFocusChange() {
    final focused = controller.focusNode.hasFocus;
    if (!focused && widget.clearQueryOnClose) {
      controller.query = "";
    }
    widget.onFocusChanged?.call(focused);
  }

  @override
  void initState() {
    super.initState();
    controller.focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    controller.focusNode.removeListener(_handleFocusChange);
    _ownController?.dispose();
    super.dispose();
  }

  Widget _buildBar() {
    // 状态栏留白始终由 bar 承担，展开下拉时包裹结构保持不变，
    // 避免 TextField 重建丢失焦点。
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;
    final Color fill =
        widget.color ?? Theme.of(context).scaffoldBackgroundColor;
    // 外层透明，颜色只落在内层：margin/borderRadius 为 null 时，
    // 内层铺满整宽，视觉与旧的全宽直角形态一致。
    return Container(
      padding: EdgeInsets.only(top: statusBarHeight),
      child: Container(
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: widget.borderRadius,
          boxShadow: widget.shadow,
        ),
        // 与下拉列表共用点击区域；列表收起动画期间继续拦截外部点击。
        child: TapRegion(
          groupId: controller,
          enabled: widget.body != null,
          consumeOutsideTaps: true,
          onTapOutside: (_) => controller.close(),
          child: Row(
            children: [
              ...(widget.leadingActions ?? const <Widget>[]),
              Expanded(
                child: TextField(
                  controller: controller._input,
                  focusNode: controller.focusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) => widget.onSubmitted?.call(value),
                  onChanged: (value) => widget.onQueryChanged?.call(value),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    border: InputBorder.none,
                  ),
                ),
              ),
              ...(widget.actions ?? const <Widget>[]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 整条搜索栏都可点：点在图标 / 药丸留白上也能直接聚焦输入，
    // 不用先点一次「唤醒」再点第二次。
    final Widget bar = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: controller.focusNode.requestFocus,
      child: _buildBar(),
    );
    final Widget? body = widget.body;
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;
    // 展开态要把整条 bar 的实际高度算进去（含 margin 的上下留白），
    // 否则下拉浮窗会盖住药丸底部一小截。
    final EdgeInsetsGeometry? margin = widget.margin;
    double marginVertical = 0;
    if (margin is EdgeInsets) {
      marginVertical = margin.top + margin.bottom;
    } else if (margin != null) {
      final EdgeInsets resolved = margin.resolve(TextDirection.ltr);
      marginVertical = resolved.top + resolved.bottom;
    }
    final double barHeight = widget.height + statusBarHeight + marginVertical;
    // bar 固定在 children[0]：展开时只在末尾追加 body，
    // 保持 bar 的 Element 位置稳定，避免 TextField 重建丢失焦点。
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        bar,
        if (body != null)
          Padding(
            padding: EdgeInsets.only(top: barHeight),
            child: body,
          ),
      ],
    );
  }
}
