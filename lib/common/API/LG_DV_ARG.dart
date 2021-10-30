import 'dart:math';
import 'dart:ui';

///此类用来模拟window.LG_DV_ARG，用于获取dv参数
///目前做到了简单的模拟
class WindowsDv {
  String dv = "";
  //生成dv
  WindowsDv() {
    dv = _getDv();
  }
  String _getDv() {
    var start = "tk" +
        Random().nextDouble().toString() +
        DateTime.now().millisecondsSinceEpoch.toString();
    var r = _getDvn(start);
    var o = {
          "flashInfo": 0,
          "mouseDown": 1,
          "keyDown": 2,
          "mouseMove": 3,
          "version": 4,
          "loadTime": 5,
          "browserInfo": 6,
          "token": 7,
          "location": 8,
          "screenInfo": 9
        },
        a = [
          _getDviary(r, [2])
        ];
    var e = <String, dynamic>{
      "browserInfo": "1,2,94",
      "flashInfo": null,
      "keyDown": "",
      "loadTime": DateTime.now().millisecondsSinceEpoch / 1000,
      "location": "https://www.baidu.com/,undefined",
      "mouseDown": "",
      "mouseMove": "",
      "screenInfo":
          "0,0,${window.physicalSize.width.toInt()},${window.physicalSize.height.toInt()},${window.physicalSize.width.toInt()},1080,${window.physicalSize.width.toInt()},${window.physicalSize.width.toInt()},${window.physicalSize.height.toInt()}",
      "token": start,
      "version": 26
    };
    for (var i in e.keys) {
      var d = e[i];
      if (d != null && o[i] != null) {
        var c;
        if (d is num) {
          c = d >= 0 ? 1 : 2;
          // ignore: unnecessary_cast
          d = _getDvint(r, d as num);
        } else if (d is bool) {
          c = 3;
          d = _getDvint(r, d ? 1 : 0);
        } else if (d is List) {
          c = 4;
          d = _getDvbary(r, d);
        } else {
          c = 0;
          d = _getDvstr(r, d + "");
          if (d != null) {
            a.add(_getDviary(r, [o[i], c, d.length]) + d);
          }
        }
      }
    }
    return start + "@" + a.join("");
  }

  //移植于g.min,js
  List _getDvo(dynamic e) {
    var t = [];
    for (var n = 0; n < e.length; n++)
      for (var r = e[n][0]; r <= e[n][1]; r++) t.add(String.fromCharCode(r));
    return t;
  }

  //移植于g.min,js
  Map<String, dynamic> _getDvn(e) {
    Map<String, dynamic> result = {};
    var t = [
          [48, 57],
          [65, 90],
          [97, 122],
          [45, 45],
          [126, 126]
        ],
        n = _getDvo(t),
        a = _getDvo(t.sublist(1));
    n = _getDvr(n, e);
    a = _getDvr(a, e);
    result["dict"] = n;
    result["dict2"] = a;
    return result;
  }

  //移植于g.min,js
  List _getDvr(e, t) {
    for (var n = t.split(""), r = 0; r < e.length; r++) {
      var o = r % n.length;
      o = (n[o] as String).codeUnitAt(0);
      o %= e.length;
      var a = e[r];
      e[r] = e[o];
      e[o] = a;
    }
    return e;
  }

  //移植于g.min,js
  String _getDviary(Map<String, dynamic> map, List e) {
    var t = "";
    for (var n = 0; n < e.length; n++) {
      String r = _getDva(e[n], map["dict2"]);
      t += r.length > 1 ? (r.length - 2).toString() + r : r;
    }
    return t;
  }

  String _getDva(num e, List t) {
    var n = "", r = e.toInt().abs();
    if (r != 0) {
      for (; r != 0;) {
        n += t[r % t.length];
        r = r ~/ t.length;
      }
    } else {
      n = t[0];
    }

    return n;
  }

  String _getDvstr(Map<String, dynamic> map, String e) {
    var t = [];
    for (var n = 0; n < e.length; n++) {
      var r = e.codeUnitAt(n);
      if (r >= 1 && 127 >= r) {
        t.add(r);
      } else if (r > 2047) {
        t.add(224 | r >> 12 & 15);
        t.add(128 | r >> 6 & 63);
        t.add(128 | r >> 0 & 63);
      } else {
        t.add(192 | r >> 6 & 31);
        t.add(128 | r >> 0 & 63);
      }
    }
    var o = "";
    for (var n = 0, a = t.length; a > n;) {
      var i = t[n++];
      if (n >= a) {
        o += map["dict"][i >> 2];
        o += map["dict"][(3 & i) << 4];
        o += "__";
        break;
      }
      var d = t[n++];
      if (n >= a) {
        o += map["dict"][i >> 2];
        o += map["dict"][(3 & i) << 4 | (240 & d) >> 4];
        o += map["dict"][(15 & d) << 2];
        o += "_";
        break;
      }
      var c = t[n++];
      o += map["dict"][i >> 2];
      o += map["dict"][(3 & i) << 4 | (240 & d) >> 4];
      o += map["dict"][(15 & d) << 2 | (192 & c) >> 6];
      o += map["dict"][63 & c];
    }
    return o;
  }

  String _getDvint(Map<String, dynamic> map, num e) {
    return _getDva(e, map["dict"]);
  }

  String _getDvbary(Map<String, dynamic> map, List e) {
    var t = 0, n = {};
    for (var r = 0; r < e.length; r++) {
      t = e[r];
      n[e[r]] = true;
    }

    var o = t ~/ 6;
    o += t % 6 != 0 ? 1 : 0;
    var a = "";
    for (var r = 0; o > r; r++) {
      num d = 0;
      for (var i = 6 * r, c = 0; 6 > c; c++) {
        if (n[i] != null) {
          d += pow(2, c);
        }
        i++;
      }

      a += map["dict"][d];
    }
    return a;
  }
}
