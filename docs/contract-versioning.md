# 契约版本与后端兼容

`tieba_contract` 独立发版，版本号遵循语义化版本（SemVer）。Tiebanana 的版本号
和契约版本号**不一一对应**：应用只声明自己需要的契约范围，具体关系以本页表格和
根目录 `pubspec.yaml` 为准。

## 给后端开发者：怎么选契约版本

1. 在下面的兼容表找到目标 Tiebanana 版本，记下它要求的 `tieba_contract` 范围，
   例如 `^1.1.0`（等价于 `>=1.1.0 <2.0.0`）。
2. 让后端包直接依赖同一份契约，不要把契约源码复制进自己的仓库：

   ```yaml
   dependencies:
     tieba_contract:
       git:
         url: https://github.com/Aobanana-chan/tieba_contract.git
         ref: v1.1.0
   ```

   与 Tiebanana 在同一个工作区时也可以继续用 path 依赖，但必须同时写版本范围：

   ```yaml
   dependencies:
     tieba_contract:
       path: packages/tieba_contract
       version: ^1.1.0
   ```

3. 同一主版本内可以直接使用更高的次版本/补丁版本；主版本变化表示需要修改后端代码。
4. 如果要同时支持多个 Tiebanana 版本，取这些版本要求的契约范围的交集；没有交集时
   需要分开发版。

Tiebanana 根 `pubspec.yaml` 中的 `tieba_contract` 范围是该版本应用的真实要求。
兼容表与 pubspec 不一致时，以 pubspec 和子模块指针为准，并立即修正兼容表。

## 兼容表

| Tiebanana | tieba_contract | 契约 tag | 说明 |
| --- | --- | --- | --- |
| 1.1.0（开发中） | >=1.2.0 <2.0.0 | v1.2.0 | 动图识别改用显式标记；新增私信模型与可选 `TiebaChatApi` |
| 1.0.2 | >=1.1.0 <2.0.0 | v1.1.0 | 识别帖子动图；演示头像离线显示 |
| 1.0.0 – 1.0.1 | >=1.0.0 <2.0.0 | v1.0.0 | 首个公开契约 |

应用发版时更新本表。历史版本已经使用的子模块指针可能比 tag 多几个兼容性提交，
但只要没有主版本变化，后端仍应按上表的范围选择。

## 契约版本的升级规则

| 版本位 | 含义 | 典型变更 |
| --- | --- | --- |
| 主版本 `X` | 不兼容 | 删除/重命名字段；修改字段类型；增加必填构造参数；给 `TiebaApi` 增删抽象成员或修改方法签名；改变接口语义 |
| 次版本 `Y` | 向后兼容 | 新增带默认值的可选字段；新增数据类、枚举值、辅助函数；补充演示数据 |
| 补丁 `Z` | 修复 | 不改变公开 API 与语义的修复、注释和文档 |

**给 `TiebaApi` 增加抽象方法也是主版本变更**，因为所有后端实现都必须补上实现。
如果只是界面可选能力，优先新增独立接口，由界面用 `is` 判断后启用，避免为了一个
小功能把所有后端拖进主版本升级。

## 发版检查

契约仓库：

1. 修改 `pubspec.yaml` 的 `version` 和 `CHANGELOG.md`。
2. 提交后打 tag `vX.Y.Z`，并推送提交和 tag（由维护者执行）。

Tiebanana：

1. 更新 `packages/tieba_contract` 子模块指针。
2. 更新根 `pubspec.yaml` 的 `tieba_contract` 范围，以及
   `packages/tieba_backend_demo`、私有适配包和 `headless_tieba` 中的同一范围。
3. 更新本页兼容表、`CHANGELOG.md` 和 README 顶部版本号。
4. 执行 `flutter pub get`、`flutter analyze` 和 `flutter test`。

后端：

1. 按兼容表修改 `tieba_contract` 依赖范围和 `ref`。
2. 补上接口变更所需的实现。
3. 更新后端自己的版本号和说明。
