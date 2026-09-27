import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../models/scam_model.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;

  // In-memory storage for web or fallback
  final List<ScamModel> _inMemoryLogs = [];
  final Map<String, Map<String, dynamic>> _inMemoryRefs = {};
  int _nextId = 1;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    try {
      _database = await _initDB();
      return _database!;
    } catch (e) {
      debugPrint('[DatabaseService] Native DB init error (using memory fallback): $e');
      return null;
    }
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'scam_shield_v4.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE scam_logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender TEXT NOT NULL,
            senderType INTEGER NOT NULL,
            message TEXT NOT NULL,
            confidence INTEGER NOT NULL,
            classification TEXT NOT NULL,
            flags TEXT NOT NULL,
            warnings TEXT NOT NULL,
            isScam INTEGER NOT NULL,
            timestamp TEXT NOT NULL,
            claimedOrganization TEXT,
            userFeedback TEXT,
            fraudType TEXT,
            recommendedAction TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE reference_checks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            referenceNumber TEXT UNIQUE NOT NULL,
            firstCheckedAt TEXT NOT NULL,
            timesChecked INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS reference_checks(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              referenceNumber TEXT UNIQUE NOT NULL,
              firstCheckedAt TEXT NOT NULL,
              timesChecked INTEGER NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<int> insertAlert(ScamModel alert) async {
    final db = await database;
    if (db == null) {
      final newAlert = alert.id == null ? alert.copyWith(id: _nextId++) : alert;
      _inMemoryLogs.insert(0, newAlert);
      return newAlert.id ?? _nextId;
    }
    return await db.insert('scam_logs', alert.toMap());
  }

  Future<int> updateAlert(ScamModel alert) async {
    final db = await database;
    if (db == null) {
      final index = _inMemoryLogs.indexWhere((a) => a.id == alert.id);
      if (index != -1) {
        _inMemoryLogs[index] = alert;
        return 1;
      }
      return 0;
    }
    return await db.update(
      'scam_logs',
      alert.toMap(),
      where: 'id = ?',
      whereArgs: [alert.id],
    );
  }

  Future<List<ScamModel>> getAllAlerts() async {
    final db = await database;
    if (db == null) {
      return List<ScamModel>.from(_inMemoryLogs);
    }
    final maps = await db.query('scam_logs', orderBy: 'timestamp DESC');
    return maps.map((map) => ScamModel.fromMap(map)).toList();
  }

  Future<List<ScamModel>> getAlertsByFilter(String filter) async {
    final db = await database;
    final now = DateTime.now();

    if (db == null) {
      switch (filter) {
        case 'today':
          final startOfDay = DateTime(now.year, now.month, now.day);
          return _inMemoryLogs.where((a) => a.timestamp.isAfter(startOfDay)).toList();
        case 'week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          return _inMemoryLogs.where((a) => a.timestamp.isAfter(startOfWeekDay)).toList();
        case 'month':
          final startOfMonth = DateTime(now.year, now.month, 1);
          return _inMemoryLogs.where((a) => a.timestamp.isAfter(startOfMonth)).toList();
        case 'all':
        default:
          return List<ScamModel>.from(_inMemoryLogs);
      }
    }

    String? where;
    List<String>? whereArgs;

    switch (filter) {
      case 'today':
        final startOfDay = DateTime(now.year, now.month, now.day);
        where = 'timestamp >= ?';
        whereArgs = [startOfDay.toIso8601String()];
        break;
      case 'week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDay =
            DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        where = 'timestamp >= ?';
        whereArgs = [startOfWeekDay.toIso8601String()];
        break;
      case 'month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        where = 'timestamp >= ?';
        whereArgs = [startOfMonth.toIso8601String()];
        break;
      case 'all':
      default:
        where = null;
        whereArgs = null;
    }

    final maps = await db.query(
      'scam_logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => ScamModel.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    if (db == null) {
      final totalScanned = _inMemoryLogs.length;
      final scamsBlocked = _inMemoryLogs.where((a) => a.isScam).length;
      final blockRate =
          totalScanned > 0 ? ((scamsBlocked / totalScanned) * 100).round() : 0;
      return {
        'totalScanned': totalScanned,
        'scamsBlocked': scamsBlocked,
        'blockRate': blockRate,
        'familyProtected': 1,
      };
    }
    final allAlerts = await db.query('scam_logs');
    final totalScanned = allAlerts.length;
    final scamsBlocked =
        allAlerts.where((a) => (a['isScam'] as int) == 1).length;
    final blockRate =
        totalScanned > 0 ? ((scamsBlocked / totalScanned) * 100).round() : 0;

    return {
      'totalScanned': totalScanned,
      'scamsBlocked': scamsBlocked,
      'blockRate': blockRate,
      'familyProtected': 1,
    };
  }

  Future<void> deleteAlert(int id) async {
    final db = await database;
    if (db == null) {
      _inMemoryLogs.removeWhere((a) => a.id == id);
      return;
    }
    await db.delete('scam_logs', where: 'id = ?', whereArgs: [id]);
  }

  /// Local duplicate reference check (stores ONLY reference code & timestamp)
  Future<Map<String, dynamic>> checkAndRecordReference(String rawRef) async {
    final db = await database;
    final cleanRef = rawRef.trim().toUpperCase();
    final nowFormatted = DateFormat('MMM d, yyyy · h:mm a').format(DateTime.now());

    if (db == null) {
      if (_inMemoryRefs.containsKey(cleanRef)) {
        final prev = _inMemoryRefs[cleanRef]!;
        final times = (prev['timesChecked'] as int) + 1;
        _inMemoryRefs[cleanRef] = {
          'firstCheckedAt': prev['firstCheckedAt'],
          'timesChecked': times,
        };
        return {
          'isDuplicate': true,
          'firstCheckedAt': prev['firstCheckedAt'],
          'timesChecked': times,
        };
      } else {
        _inMemoryRefs[cleanRef] = {
          'firstCheckedAt': nowFormatted,
          'timesChecked': 1,
        };
        return {
          'isDuplicate': false,
          'firstCheckedAt': nowFormatted,
          'timesChecked': 1,
        };
      }
    }

    final existing = await db.query(
      'reference_checks',
      where: 'referenceNumber = ?',
      whereArgs: [cleanRef],
    );

    if (existing.isNotEmpty) {
      final firstCheckedAt = existing.first['firstCheckedAt'] as String;
      final timesChecked = (existing.first['timesChecked'] as int) + 1;

      await db.update(
        'reference_checks',
        {'timesChecked': timesChecked},
        where: 'referenceNumber = ?',
        whereArgs: [cleanRef],
      );

      return {
        'isDuplicate': true,
        'firstCheckedAt': firstCheckedAt,
        'timesChecked': timesChecked,
      };
    } else {
      await db.insert('reference_checks', {
        'referenceNumber': cleanRef,
        'firstCheckedAt': nowFormatted,
        'timesChecked': 1,
      });

      return {
        'isDuplicate': false,
        'firstCheckedAt': nowFormatted,
        'timesChecked': 1,
      };
    }
  }
}
