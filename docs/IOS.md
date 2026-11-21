# iOS
CI job `ios` builds unsigned on macOS. To ship: open `apps/mobile/ios` in Xcode after `flutter create`, set your team/bundle id, add `GoogleService-Info.plist`, enable Push Notifications + Background Modes, add `NSLocationWhenInUseUsageDescription` to Info.plist, upload an APNs key to Firebase, then `flutter build ipa`. Not built or tested here.
