import 'dart:math';
import 'dart:ui';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:tiebanana/common/API/Constants.dart';

///TODO:生成百度的fuid,待完善
///fuid是浏览器唯一标识
class FingerPrint {
  var ofuid = {};
  String fuid = "";
  final _pubkey = "FfdsnvsootJmvNfl";
  FingerPrint() {
    _getfuid();
  }
  void _getfuid() {
    ofuid = {
      "userAgent": ChromeUA,
      "canvas": md5.convert([Random().nextInt(2 << 31)]).toString(),
      "language": "zh-CN",
      "colorDepth": "24",
      "deviceMemory": "8",
      "hardwareConcurrency": "8",
      "screenResolution":
          "${window.physicalSize.width.toInt()}%2C${window.physicalSize.height.toInt()}",
      "availableScreenResolution":
          "${window.physicalSize.width.toInt()}%2C${window.physicalSize.height.toInt()}",
      "timezoneOffset": "-480",
      "timezone": "",
      "sessionStorage": "true",
      "localStorage": "true",
      "indexedDb": "true",
      "addBehavior": "false",
      "openDatabase": "true",
      "cpuClass": "",
      "platform": "Win32",
      "plugins": "undefined",
      "webgl": md5.convert([Random().nextInt(2 << 31)]).toString(),
      "webglVendorAndRenderer":
          "Google%20Inc.%20(Intel)~ANGLE%20(Intel%2C%20Intel(R)%20UHD%20Graphics%20630%20Direct3D11%20vs_5_0%20ps_5_0%2C%20D3D11-26.20.100.7324)",
      "adBlock": "false",
      "hasLiedLanguages": "false",
      "hasLiedResolution": "false",
      "hasLiedOs": "false",
      "hasLiedBrowser": "false",
      "touchSupport": "0%2Cfalse%2Cfalse",
      "fonts": "41",
      "audio": "undefined"
    };
    fuid = Encrypter(AES(Key.fromUtf8(_pubkey), mode: AESMode.ecb))
        .encrypt(ofuid.toString(), iv: IV.fromLength(0))
        .base64;
  }
}
