/// 后端装配点：**全应用唯一**引用具体后端实现的地方。
/// 想接自己的后端，只需要提供一个同名包并导出 `createTiebaApi`，
/// 或者在本地直接改这里引用自己的工厂函数。
library;

export 'package:tieba_backend_demo/tieba_backend_demo.dart' show createTiebaApi;
