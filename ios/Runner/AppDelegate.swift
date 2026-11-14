import UIKit
import Flutter
import AVFAudio
import MediaPlayer
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var playerUtilsChannel: FlutterMethodChannel?
  private let volumeView = MPVolumeView(frame: CGRect(x: -100, y: -100, width: 100, height: 40))

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "tiebanana/player_utils",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    playerUtilsChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch call.method {
      case "getSystemVolume":
        result(Double(AVAudioSession.sharedInstance().outputVolume))
      case "getBrightness":
        result(Double(UIScreen.main.brightness))
      case "setSystemVolume", "setBrightness":
        guard let args = call.arguments as? [String: Any],
              let value = args["value"] as? NSNumber else {
          result(FlutterError(code: "invalid_arguments", message: "value is required", details: nil))
          return
        }
        let normalized = min(1.0, max(0.0, value.doubleValue))
        if call.method == "setBrightness" {
          UIScreen.main.brightness = CGFloat(normalized)
        } else {
          // Use the public system-volume control, not a private audio API.
          let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
          if self.volumeView.superview == nil {
            window?.addSubview(self.volumeView)
          }
          if let slider = self.volumeView.subviews.compactMap({ $0 as? UISlider }).first {
            slider.setValue(Float(normalized), animated: false)
            slider.sendActions(for: .valueChanged)
          }
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

// Keep the scene delegate in the same target source as AppDelegate.
class SceneDelegate: FlutterSceneDelegate {}
