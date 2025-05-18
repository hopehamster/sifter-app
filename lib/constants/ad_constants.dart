import 'dart:io';

/// Constants for AdMob ad unit IDs
class AdConstants {
  // Banner ad unit IDs
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Android test ad unit
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOS test ad unit
    } else {
      throw UnsupportedError('Unsupported platform for ads');
    }
  }

  // Interstitial ad unit IDs
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Android test ad unit
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // iOS test ad unit
    } else {
      throw UnsupportedError('Unsupported platform for ads');
    }
  }

  // Rewarded ad unit IDs
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Android test ad unit
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS test ad unit
    } else {
      throw UnsupportedError('Unsupported platform for ads');
    }
  }

  // Rewarded interstitial ad unit IDs
  static String get rewardedInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5354046379'; // Android test ad unit
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/6978759866'; // iOS test ad unit
    } else {
      throw UnsupportedError('Unsupported platform for ads');
    }
  }
  
  // App open ad unit IDs
  static String get appOpenAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/3419835294'; // Android test ad unit
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/5662855259'; // iOS test ad unit
    } else {
      throw UnsupportedError('Unsupported platform for ads');
    }
  }
} 