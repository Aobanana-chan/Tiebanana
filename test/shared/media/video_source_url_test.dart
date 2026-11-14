import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiebanana/shared/media/video_source_url.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('Windows 视频 CDN 升级 HTTPS，签名字节与空参数保持不变', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    const tail = 'tb-video.bdstatic.com/video.mp4?sid=&tbau=a%2Fb%2B1&ptid=';
    expect(videoSourceUrl('http://$tail'), 'https://$tail');
  });

  test('其他主机、协议、自定义端口及凭证不改写', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    for (final url in [
      'https://tb-video.bdstatic.com/v.mp4',
      'http://example.com/v.mp4',
      'http://tb-video.bdstatic.com.example.com/v.mp4',
      'http://tb-video.bdstatic.com:8080/v.mp4',
      'http://user@tb-video.bdstatic.com/v.mp4',
      'file:///video.mp4',
    ]) {
      expect(videoSourceUrl(url), url);
    }
  });

  test('移动端保持原地址', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const url = 'http://tb-video.bdstatic.com/v.mp4?sid=';
    expect(videoSourceUrl(url), url);
  });
}
