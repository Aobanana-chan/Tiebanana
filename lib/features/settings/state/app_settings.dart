import 'package:flutter/material.dart';
import 'package:tiebanana/core/config/default_config.dart';
import 'package:tiebanana/app/global.dart';
import 'package:tiebanana/shared/theme/tiebanana_seed.dart';

///应用设置Provider
class APPSettingProvider with ChangeNotifier {
  // 获取当前主题，如果未设置主题，则默认使用蓝色主题
  String get theme {
    return Global.setting.theme!;
  }

  /// 当前主题的种子（色相 / 彩度系数 / 亮色主色明度）。
  ///
  /// 整套配色都由它派生，见 [TiebananaTheme]。
  TiebananaSeed get seed => seedOf(theme);

  /// 主题选择器里的圆点颜色。
  Color get themeColor {
    if (Global.setting.theme == "white") {
      return tiebananaSeeds["white"]!.color;
    }
    return seed.color;
  }

  // 主题改变后，通知其依赖项
  set theme(String color) {
    if (color != theme) {
      // theme = color;
      //保存APP配置项
      Global.setting.theme = color;
      Global.saveProfile();

      notifyListeners();
    }
  }

  //字号大小
  double get fontSize {
    return Global.setting.fontSize;
  }

  set fontSize(double size) {
    Global.setting.fontSize = size;
    Global.saveProfile();
    notifyListeners();
  }

  /// 深色模式：0 跟随系统 / 1 深色 / 2 浅色（见 `defaultAPPSetting`）。
  ///
  /// `main.dart` 的 `themeMode` 直接读 [Global.setting]，
  /// 修改后调用 `notifyListeners()` 让整屏跟随切换。
  int get darkModel => Global.setting.darkModel ?? 0;

  set darkModel(int mode) {
    if (mode != Global.setting.darkModel) {
      Global.setting.darkModel = mode;
      Global.saveProfile();
      notifyListeners();
    }
  }

  ///首页「我关注的吧」缩略状态显示数量（3–30，默认 12）。
  int get homeForumMaxCount {
    return Global.setting.homeForumMaxCountSafe;
  }

  set homeForumMaxCount(int count) {
    if (count != Global.setting.homeForumMaxCount) {
      Global.setting.homeForumMaxCount = count;
      Global.saveProfile();
      notifyListeners();
    }
  }

  /// 首页最近浏览显示数量（1–50，默认 15）。
  int get homeHistoryMaxCount => Global.setting.homeHistoryMaxCountSafe;

  set homeHistoryMaxCount(int count) {
    final int value = count.clamp(
        APPSetting.minHomeHistoryMaxCount, APPSetting.maxHomeHistoryMaxCount);
    if (value != Global.setting.homeHistoryMaxCount) {
      Global.setting.homeHistoryMaxCount = value;
      Global.saveProfile();
      notifyListeners();
    }
  }
}
