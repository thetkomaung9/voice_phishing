import Flutter
import AVFoundation
import CallKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let methodChannelName = "com.safecall.ai/callMonitor"
  private static let eventChannelName = "com.safecall.ai/callEvents"
  private static let protectionEnabledKey = "protection_enabled"
  private static let preferredLanguageKey = "preferred_language"
  private static let cloudTranslationApiKeyKey = "cloud_translation_api_key"

  private let speechSynthesizer = AVSpeechSynthesizer()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let didFinishLaunching = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      registerNativeChannels(binaryMessenger: controller.binaryMessenger)
    }
    return didFinishLaunching
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func registerNativeChannels(binaryMessenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(
      name: Self.methodChannelName,
      binaryMessenger: binaryMessenger
    ).setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }

      switch call.method {
      case "startMonitoring", "stopMonitoring":
        // iOS does not expose live phone-call audio to third-party apps.
        result(nil)
      case "hasOverlayPermission":
        // iOS has no Android-style overlay permission.
        result(false)
      case "requestOverlayPermission":
        self.openAppSettings(result: result)
      case "setProtectionEnabled":
        let args = call.arguments as? [String: Any]
        UserDefaults.standard.set(args?["enabled"] as? Bool ?? true, forKey: Self.protectionEnabledKey)
        result(nil)
      case "getProtectionEnabled":
        if UserDefaults.standard.object(forKey: Self.protectionEnabledKey) == nil {
          result(true)
        } else {
          result(UserDefaults.standard.bool(forKey: Self.protectionEnabledKey))
        }
      case "setPreferredLanguage":
        let args = call.arguments as? [String: Any]
        UserDefaults.standard.set(args?["languageCode"] as? String ?? "en", forKey: Self.preferredLanguageKey)
        result(nil)
      case "setCloudTranslationApiKey":
        let args = call.arguments as? [String: Any]
        UserDefaults.standard.set(args?["apiKey"] as? String ?? "", forKey: Self.cloudTranslationApiKeyKey)
        result(nil)
      case "getPreferredLanguage":
        result(UserDefaults.standard.string(forKey: Self.preferredLanguageKey) ?? "en")
      case "openCallScreeningSettings":
        self.openCallScreeningSettings(result: result)
      case "isCallScreeningEnabled":
        self.isCallScreeningEnabled(result: result)
      case "openAccessibilitySettings":
        // Apple does not provide a public deep link to Accessibility settings.
        self.openAppSettings(result: result)
      case "isSamsungTextCallCaptureEnabled":
        result(false)
      case "speakTextCallMessage":
        let args = call.arguments as? [String: Any]
        self.speakTextCallMessage(
          args?["text"] as? String ?? "",
          languageCode: args?["languageCode"] as? String ?? "en"
        )
        result(nil)
      case "stopTextCallSpeaker":
        self.speechSynthesizer.stopSpeaking(at: .immediate)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    FlutterEventChannel(
      name: Self.eventChannelName,
      binaryMessenger: binaryMessenger
    ).setStreamHandler(EmptyCallEventStreamHandler())
  }

  private func openCallScreeningSettings(result: @escaping FlutterResult) {
    if #available(iOS 13.4, *) {
      CXCallDirectoryManager.sharedInstance.openSettings { [weak self] error in
        DispatchQueue.main.async {
          if error == nil {
            result(nil)
          } else {
            self?.openAppSettings(result: result)
          }
        }
      }
    } else {
      openAppSettings(result: result)
    }
  }

  private func isCallScreeningEnabled(result: @escaping FlutterResult) {
    guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
      result(false)
      return
    }

    let extensionIdentifier = Bundle.main.object(
      forInfoDictionaryKey: "CallDirectoryExtensionBundleIdentifier"
    ) as? String ?? "\(bundleIdentifier).CallDirectoryExtension"

    CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(
      withIdentifier: extensionIdentifier
    ) { status, error in
      DispatchQueue.main.async {
        result(error == nil && status == .enabled)
      }
    }
  }

  private func openAppSettings(result: @escaping FlutterResult) {
    guard let url = URL(string: UIApplication.openSettingsURLString),
          UIApplication.shared.canOpenURL(url) else {
      result(nil)
      return
    }

    UIApplication.shared.open(url) { _ in
      result(nil)
    }
  }

  private func speakTextCallMessage(_ text: String, languageCode: String) {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return
    }

    speechSynthesizer.stopSpeaking(at: .immediate)
    let utterance = AVSpeechUtterance(string: text)
    let voiceLanguage = languageCode.replacingOccurrences(of: "_", with: "-")
    utterance.voice = AVSpeechSynthesisVoice(language: voiceLanguage)
      ?? AVSpeechSynthesisVoice(language: "en-US")
    speechSynthesizer.speak(utterance)
  }
}

private final class EmptyCallEventStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    nil
  }
}
