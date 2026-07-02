import 'dart:ffi';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'RunningData.dart';
import 'dart:convert';

class DatabaseHelper {

  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory applicationDirectory;

    if (Platform.isIOS) {
      // iOSは Application Support ディレクトリ
      applicationDirectory = await getApplicationSupportDirectory();
    } else if (Platform.isAndroid) {
      // Androidは Documents ディレクトリ
      applicationDirectory = await getApplicationDocumentsDirectory();
    } else {
      throw UnsupportedError("このプラットフォームではサポートされていません");
    }

    // ディレクトリパスを表示（デバッグ用）
    print('Application Directory: ${applicationDirectory.path}');

    // ディレクトリがなければ作成
    await Directory(applicationDirectory.path).create(recursive: true);

    // DBファイルのフルパス
    final String path = join(applicationDirectory.path, 'run_tracker.sqlite');
    print('Database path: $path');

    // データベースを開く（存在しなければ onCreate に従って作成）
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }


  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS runningData (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        points TEXT NOT NULL,
        distance REAL NOT NULL,
        steps INT NOT NULL,
        elapsedSeconds INT NOT NULL,
        pace REAL NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        temp REAL NOT NULL,
        avgBpm REAL NOT NULL
      )
    ''');
  }


// READ
  Future<List<Map<String, dynamic>>> fetchAllRunningData() async {
    final db = await database;
    return await db.query(
      'runningData',
      orderBy: 'startDate DESC',
    );
  }

// INSERT
  Future<void> insertRunningData(
      String points,
      double distance,
      int steps,
      int elapsedSeconds,
      double pace,
      String startDate,
      String endDate,
      double temp,
      double avgBpm
      ) async {
    final db = await database;
    await db.insert(
      'runningData',
      {
        'points': points,
        'distance': distance,
        'steps': steps,
        'elapsedSeconds': elapsedSeconds,
        'pace': pace,
        'startDate': startDate,
        'endDate': endDate,
        'temp': temp,
        'avgBpm': avgBpm
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

// DELETE
  Future<void> deleteRunningData(int pk) async {
    final db = await database;
    await db.delete(
      'runningData',
      where: 'id = ?',
      whereArgs: [pk],
    );
  }

// DELETE ALL
  Future<void> deleteAllRunningData() async {
    final db = await database;
    await db.delete(
      'runningData',
    );
  }

// UPDATE
  Future<void> updateRunningData(int pk, {
    String? points,
    Double? distance,
    int? steps,
    int? elapsedSeconds,
    Float? pace,
    String? startDate,
    String? endDate,
    Double? temp,
    Double? avgBpm
  }) async {
    final db = await database;
    await db.update(
      'runningData',
      {
        if (points != null) 'points': points,
        if (distance != null) 'distance': distance,
        if (steps != null) 'steps': steps,
        if (elapsedSeconds != null) 'elapsedSeconds': elapsedSeconds,
        if (pace != null) 'pace': pace,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (temp != null) 'temp': temp,
        if (avgBpm != null) 'avgBpm': avgBpm
      },
      where: 'id = ?',
      whereArgs: [pk],
    );
  }

  //最新の1件を返す
  Future<RunningData?> getLatestRunningData() async {
  final db = await database;

  final result = await db.query(
    'runningData',
    orderBy: 'startDate DESC',
    limit: 1,
  );

  if (result.isEmpty) return null;

  final row = result.first;

    return RunningData(
      points: (jsonDecode(row['points'] as String) as List)
          .map((e) => Point.fromJson(e))
          .toList(),
      distance: row['distance'] as double,
      steps: row['steps'] as int,
      elapsedSeconds: row['elapsedSeconds'] as int,
      startDate: row['startDate'] as String,
      endDate: row['endDate'] as String,
      temp: row['temp'] as double,
      avgBpm: row['avgBpm'] as double
    );
  }
}