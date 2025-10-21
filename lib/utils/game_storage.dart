import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GameStorage {
  static const String _keySavedGame = 'saved_game';

  static Future<void> saveGame({
    required int currentStage,
    required List<List<int>> board,
    required List<List<int>> initialBoard,
    required List<List<Set<int>>> memos,
    required List<List<bool>> correctCells,
    required int hearts,
    required int hintsUsed,
    required int elapsedSeconds,
    required Set<String> completedLines,
    int? hintsAvailable,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final memosJson = memos
        .map((row) => row.map((cell) => cell.toList()).toList())
        .toList();

    final gameData = {
      'currentStage': currentStage,
      'board': board,
      'initialBoard': initialBoard,
      'memos': memosJson,
      'correctCells': correctCells,
      'hearts': hearts,
      'hintsUsed': hintsUsed,
      'elapsedSeconds': elapsedSeconds,
      'completedLines': completedLines.toList(),
      'hintsAvailable': hintsAvailable ?? 1,
    };

    await prefs.setString(_keySavedGame, jsonEncode(gameData));
  }

  static Future<Map<String, dynamic>?> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keySavedGame);

    if (jsonString == null) {
      return null;
    }

    final Map<String, dynamic> gameData = jsonDecode(jsonString);

    final board = (gameData['board'] as List)
        .map((row) => (row as List).map((e) => e as int).toList())
        .toList();

    final initialBoard = (gameData['initialBoard'] as List)
        .map((row) => (row as List).map((e) => e as int).toList())
        .toList();

    final memos = (gameData['memos'] as List)
        .map((row) => (row as List)
            .map((cell) => (cell as List).map((e) => e as int).toSet())
            .toList())
        .toList();

    final correctCells = (gameData['correctCells'] as List)
        .map((row) => (row as List).map((e) => e as bool).toList())
        .toList();

    final completedLines =
        (gameData['completedLines'] as List).map((e) => e as String).toSet();

    return {
      'currentStage': gameData['currentStage'],
      'board': board,
      'initialBoard': initialBoard,
      'memos': memos,
      'correctCells': correctCells,
      'hearts': gameData['hearts'],
      'hintsUsed': gameData['hintsUsed'],
      'elapsedSeconds': gameData['elapsedSeconds'],
      'completedLines': completedLines,
      'hintsAvailable': gameData['hintsAvailable'] ?? 1,
    };
  }

  static Future<bool> hasSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keySavedGame);
  }

  static Future<void> clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySavedGame);
  }
}