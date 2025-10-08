import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class AdHelper {
  static InterstitialAd? _preloadedInterstitialAd;
  static bool _isLoadingInterstitial = false;
  static RewardedAd? _preloadedRewardedAd;
  static bool _isLoadingRewarded = false;

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static String get rewardedAdUnitId {
    if (isAndroid) return 'ca-app-pub-9751200480414081/5713098588';
    if (isIOS) return 'ca-app-pub-9751200480414081/8793793155';
    return 'ca-app-pub-9751200480414081/5713098588';
  }

  static String get interstitialAdUnitId {
    if (isAndroid) return 'ca-app-pub-9751200480414081/7492443484';
    if (isIOS) return 'ca-app-pub-9751200480414081/7424887070';
    return 'ca-app-pub-9751200480414081/7492443484';
  }

  static String get bannerAdUnitId {
    if (isAndroid) return 'ca-app-pub-9751200480414081/6301638985';
    if (isIOS) return 'ca-app-pub-9751200480414081/2523790478';
    return 'ca-app-pub-9751200480414081/6301638985';
  }

  static void preloadInterstitialAd() {
    if (_preloadedInterstitialAd != null || _isLoadingInterstitial) {
      return;
    }

    _isLoadingInterstitial = true;
    print('>>> 전면 광고 미리 로드 시작...');

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('✓ 전면 광고 미리 로드 성공!');
          _preloadedInterstitialAd = ad;
          _isLoadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          print('✗✗✗ 전면 광고 미리 로드 실패: ${error.message}');
          _isLoadingInterstitial = false;
        },
      ),
    );
  }

  static InterstitialAd? getPreloadedInterstitialAd() {
    final ad = _preloadedInterstitialAd;
    _preloadedInterstitialAd = null;

    // 광고를 사용했으므로 다시 미리 로드
    preloadInterstitialAd();

    return ad;
  }

  static void preloadRewardedAd() {
    if (_preloadedRewardedAd != null || _isLoadingRewarded) {
      return;
    }

    _isLoadingRewarded = true;
    print('>>> 보상형 광고 미리 로드 시작...');

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('✓ 보상형 광고 미리 로드 성공!');
          _preloadedRewardedAd = ad;
          _isLoadingRewarded = false;
        },
        onAdFailedToLoad: (error) {
          print('✗✗✗ 보상형 광고 미리 로드 실패: ${error.message}');
          _isLoadingRewarded = false;
        },
      ),
    );
  }

  static RewardedAd? getPreloadedRewardedAd() {
    final ad = _preloadedRewardedAd;
    _preloadedRewardedAd = null;

    // 광고를 사용했으므로 다시 미리 로드
    preloadRewardedAd();

    return ad;
  }

  static Future<RewardedAd?> loadRewardedAd() async {
    print('>>> 보상형 광고 로드 시도 중...');
    final Completer<RewardedAd?> completer = Completer<RewardedAd?>();

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('✓ 보상형 광고 로드 성공!');
          completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          print('✗✗✗ 보상형 광고 로드 실패: ${error.message}');
          completer.complete(null);
        },
      ),
    );

    return completer.future;
  }

  static Future<InterstitialAd?> loadInterstitialAd() async {
    print('>>> 전면 광고 로드 시도 중...');
    final Completer<InterstitialAd?> completer = Completer<InterstitialAd?>();

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('✓ 전면 광고 로드 성공!');
          completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          print('✗✗✗ 전면 광고 로드 실패: ${error.message}');
          completer.complete(null);
        },
      ),
    );

    return completer.future;
  }
}