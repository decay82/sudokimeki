import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

import 'l10n/app_localizations.dart';
import 'models/sudoku_game.dart';
import 'screens/main_screen.dart';
import 'utils/analytics_helper.dart';
import 'utils/ad_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 (웹 제외)
  if (!kIsWeb) {
    await Firebase.initializeApp();
    // 앱 오픈 이벤트 로깅
    await AnalyticsHelper.logAppOpen();
  } else {
    // Web 환경에서만 Toss 광고 미리 로드
    AdHelper.preloadInterstitialAd();
    AdHelper.preloadRewardedAd();
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => SudokuGame(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '스도쿠',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        brightness: Brightness.light, // Toss 요구사항: 라이트 모드 고정
      ),
      themeMode: ThemeMode.light, // 다크모드 비활성화
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('ko'), // Korean
      ],
      home: const MainScreen(),
    );
  }
}