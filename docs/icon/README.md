# 图标资源

图标以「贴」字为主体，用香蕉和叶子替换「占」上部的竖笔与短横。
字形使用 ZCOOL 快乐体，轮廓已转为路径；香蕉和叶子为带透明通道的 PNG。
当前应用使用 `royal` 配色：蓝色渐变背景（`#4C86F5` → `#2B5FD9`）、白色字形。

<img src="../../assets/icon/ic_launcher.png" width="160" alt="Tiebanana 图标">

## 文件

| 文件 | 用途 |
| --- | --- |
| `tiebanana.svg` | 1024 × 1024 图标模板，包含字形路径、素材位置和配色占位符 |
| `banana.png`、`leaf.png` | 香蕉、叶子构成素材，也用于开屏动画 |
| `fonts/ZCOOLKuaiLe-Regular.ttf` | 字形与开屏字标使用的完整字体 |
| `fonts/OFL.txt` | 字体的 SIL Open Font License 1.1 许可证 |
| `build_svg.py`、`_stroke_boxes.py` | 从字体生成字形模板并计算素材位置 |
| `build_icons.js` | 填充模板，生成预览与各平台图标 |
| `subset_wordmark_font.py` | 为开屏字标生成字体子集，并复制许可证 |

`tiebanana.svg` 是模板，不能直接作为成品图标使用。脚本会填入颜色，并将香蕉和叶子
以内联图片嵌入。字体随资源保留原始许可证，分发字体或字标子集时须一并保留。

## 生成

在仓库根目录执行。图标输出需要 Node.js 和本机 Chrome 或 Edge；修改字形或重新
生成字标字体还需要 Python 3，以及 `fonttools`、`Pillow`、`numpy`。

```sh
# 查看配色预览和小尺寸预览，输出在本目录 _wip/ 中
node docs/icon/build_icons.js preview
node docs/icon/build_icons.js ladder royal

# 输出应用、Android 与 iOS 图标，会覆盖对应资源文件
node docs/icon/build_icons.js build royal

# 仅在调整字形或素材布局时重新生成模板
py -3 docs/icon/build_svg.py

# 生成 assets/fonts/ 下的开屏字标字体和许可证
py -3 docs/icon/subset_wordmark_font.py
```

平台图标输出至 `android/app/src/main/res/`、
`ios/Runner/Assets.xcassets/AppIcon.appiconset/`；应用内图标输出至 `assets/icon/`。
更换配色时还需同步 Android 的 `drawable/ic_launcher_background.xml` 和
`drawable*/launch_background.xml` 中的背景色。

修改构成素材后，同步 `assets/splash/` 下的对应图片；调整模板几何时，同步
`lib/features/splash/tiebanana_glyph.dart`，配色对应 `splash_brand.dart`。
