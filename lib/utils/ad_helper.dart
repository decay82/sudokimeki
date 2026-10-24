import 'dart:async';
import 'package:flutter/foundation.dart';

// Web 전용 import (조건부)
import 'dart:js_interop' as js;

/// Toss 앱인토스 광고 시스템 연동 헬퍼
///
/// Web: Toss SDK (bedrock.js)를 통해 광고 표시
/// Native: 시뮬레이션 (Toss 앱 WebView에서만 동작)
class AdHelper {
  // 테스트용 광고 ID (개발/테스트 시 반드시 사용)
  static const String _testInterstitialId = 'ait-ad-test-interstitial-id';
  static const String _testRewardedId = 'ait-ad-test-rewarded-id';

  // 운영용 광고 ID (Toss 콘솔에서 발급받은 실제 ID)
  static const String _prodInterstitialId = 'ait.v2.live.983ced0758714be5'; // 전면형 광고
  static const String _prodRewardedId = 'ait.v2.live.015160fb89794384'; // 보상형 광고

  // 현재 환경에 따라 광고 ID 선택
  static String get _interstitialAdId =>
      kDebugMode ? _testInterstitialId : _prodInterstitialId;
  static String get _rewardedAdId =>
      kDebugMode ? _testRewardedId : _prodRewardedId;

  // 광고 로드 상태 추적
  static bool _isInterstitialLoaded = false;
  static bool _isRewardedLoaded = false;

  static Completer<void>? _interstitialCompleter;
  static Completer<void>? _rewardedCompleter;

  /// 전면형 광고 미리 로드
  static Future<void> preloadInterstitialAd() async {
    if (!kIsWeb) {
      debugPrint('[AdHelper] Native 환경에서는 Toss SDK를 사용할 수 없습니다.');
      return;
    }

    try {
      debugPrint('[AdHelper] 전면형 광고 로드 시작: $_interstitialAdId');

      _interstitialCompleter = Completer<void>();

      // JavaScript 함수 호출
      _loadTossAdJS(
        _interstitialAdId,
        () {
          // onSuccess
          _isInterstitialLoaded = true;
          if (_interstitialCompleter != null &&
              !_interstitialCompleter!.isCompleted) {
            _interstitialCompleter!.complete();
          }
          debugPrint('[AdHelper] 전면형 광고 로드 완료');
        }.toJS,
        (js.JSString error) {
          // onError
          _isInterstitialLoaded = false;
          if (_interstitialCompleter != null &&
              !_interstitialCompleter!.isCompleted) {
            _interstitialCompleter!.completeError(error.toDart);
          }
          debugPrint('[AdHelper] 전면형 광고 로드 실패: ${error.toDart}');
        }.toJS,
      );
    } catch (e) {
      debugPrint('[AdHelper] 전면형 광고 로드 예외: $e');
      _isInterstitialLoaded = false;
    }
  }

  /// 보상형 광고 미리 로드
  static Future<void> preloadRewardedAd() async {
    if (!kIsWeb) {
      debugPrint('[AdHelper] Native 환경에서는 Toss SDK를 사용할 수 없습니다.');
      return;
    }

    try {
      debugPrint('[AdHelper] 보상형 광고 로드 시작: $_rewardedAdId');

      _rewardedCompleter = Completer<void>();

      // JavaScript 함수 호출
      _loadTossAdJS(
        _rewardedAdId,
        () {
          // onSuccess
          _isRewardedLoaded = true;
          if (_rewardedCompleter != null && !_rewardedCompleter!.isCompleted) {
            _rewardedCompleter!.complete();
          }
          debugPrint('[AdHelper] 보상형 광고 로드 완료');
        }.toJS,
        (js.JSString error) {
          // onError
          _isRewardedLoaded = false;
          if (_rewardedCompleter != null && !_rewardedCompleter!.isCompleted) {
            _rewardedCompleter!.completeError(error.toDart);
          }
          debugPrint('[AdHelper] 보상형 광고 로드 실패: ${error.toDart}');
        }.toJS,
      );
    } catch (e) {
      debugPrint('[AdHelper] 보상형 광고 로드 예외: $e');
      _isRewardedLoaded = false;
    }
  }

  /// 전면형 광고 표시
  ///
  /// [onAdClosed] 광고 종료 시 콜백
  /// [onAdFailed] 광고 표시 실패 시 콜백
  static Future<void> showInterstitialAd({
    VoidCallback? onAdClosed,
    VoidCallback? onAdFailed,
  }) async {
    if (!kIsWeb) {
      debugPrint('[AdHelper] Native 환경에서는 Toss SDK를 사용할 수 없습니다.');
      onAdFailed?.call();
      return;
    }

    if (!_isInterstitialLoaded && _interstitialCompleter != null) {
      debugPrint('[AdHelper] 전면형 광고 로드를 기다립니다...');
      try {
        await _interstitialCompleter!.future.timeout(
          const Duration(seconds: 5),
        );
      } catch (e) {
        debugPrint('[AdHelper] 전면형 광고 로드 타임아웃: $e');
        onAdFailed?.call();
        return;
      }
    }

    try {
      debugPrint('[AdHelper] 전면형 광고 표시 시작');

      // JavaScript 함수 호출
      _showTossAdJS(
        _interstitialAdId,
        () {
          // onSuccess
          debugPrint('[AdHelper] 전면형 광고 종료');
          _isInterstitialLoaded = false;
          onAdClosed?.call();

          // 다음 광고 미리 로드
          preloadInterstitialAd();
        }.toJS,
        null, // onRewarded (전면형은 보상 없음)
        () {
          // onClosed
          debugPrint('[AdHelper] 전면형 광고 닫힘');
          _isInterstitialLoaded = false;
          onAdClosed?.call();

          // 다음 광고 미리 로드
          preloadInterstitialAd();
        }.toJS,
        (js.JSString error) {
          // onError
          debugPrint('[AdHelper] 전면형 광고 표시 실패: ${error.toDart}');
          onAdFailed?.call();
        }.toJS,
      );
    } catch (e) {
      debugPrint('[AdHelper] 전면형 광고 표시 예외: $e');
      onAdFailed?.call();
    }
  }

  /// 보상형 광고 표시
  ///
  /// [onRewarded] 광고 시청 완료 시 콜백 (보상 지급)
  /// [onAdClosed] 광고 종료 시 콜백
  /// [onAdFailed] 광고 표시 실패 시 콜백
  static Future<void> showRewardedAd({
    VoidCallback? onRewarded,
    VoidCallback? onAdClosed,
    VoidCallback? onAdFailed,
  }) async {
    if (!kIsWeb) {
      debugPrint('[AdHelper] Native 환경에서는 Toss SDK를 사용할 수 없습니다.');
      onAdFailed?.call();
      return;
    }

    if (!_isRewardedLoaded && _rewardedCompleter != null) {
      debugPrint('[AdHelper] 보상형 광고 로드를 기다립니다...');
      try {
        await _rewardedCompleter!.future.timeout(
          const Duration(seconds: 5),
        );
      } catch (e) {
        debugPrint('[AdHelper] 보상형 광고 로드 타임아웃: $e');
        onAdFailed?.call();
        return;
      }
    }

    try {
      debugPrint('[AdHelper] 보상형 광고 표시 시작');

      // JavaScript 함수 호출
      _showTossAdJS(
        _rewardedAdId,
        () {
          // onSuccess
          debugPrint('[AdHelper] 보상형 광고 완료');
        }.toJS,
        (js.JSAny reward) {
          // onRewarded
          debugPrint('[AdHelper] 보상형 광고 시청 완료 - 보상 지급: $reward');
          _isRewardedLoaded = false;
          onRewarded?.call();
        }.toJS,
        () {
          // onClosed
          debugPrint('[AdHelper] 보상형 광고 닫힘');
          _isRewardedLoaded = false;
          onAdClosed?.call();

          // 다음 광고 미리 로드
          preloadRewardedAd();
        }.toJS,
        (js.JSString error) {
          // onError
          debugPrint('[AdHelper] 보상형 광고 표시 실패: ${error.toDart}');
          onAdFailed?.call();
        }.toJS,
      );
    } catch (e) {
      debugPrint('[AdHelper] 보상형 광고 표시 예외: $e');
      onAdFailed?.call();
    }
  }

  /// 레거시 호환성을 위한 더미 메서드 (삭제 예정)
  @Deprecated('Use preloadInterstitialAd and showInterstitialAd instead')
  static dynamic getPreloadedInterstitialAd() => null;

  @Deprecated('Use preloadRewardedAd and showRewardedAd instead')
  static dynamic getPreloadedRewardedAd() => null;
}

// JavaScript 함수 정의 (External 선언)
@js.JS('loadTossAd')
external void _loadTossAdJS(
  String adUnitId,
  js.JSFunction onSuccess,
  js.JSFunction onError,
);

@js.JS('showTossAd')
external void _showTossAdJS(
  String adUnitId,
  js.JSFunction onSuccess,
  js.JSFunction? onRewarded,
  js.JSFunction onClosed,
  js.JSFunction onError,
);
