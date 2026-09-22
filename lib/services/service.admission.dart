import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AdmissionDbService {
  // Physical Storage Locations:
  // - Windows: %APPDATA%\Roaming\<company_name>\<app_name>\databases\admission_assistant.db
  // This data survives app updates and reinstalls (if persistent storage is kept).

  static final AdmissionDbService _instance = AdmissionDbService._internal();
  factory AdmissionDbService() => _instance;
  AdmissionDbService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'admission_assistant.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE admissions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        age TEXT,
        className TEXT,
        phone TEXT,
        photoPath TEXT,
        createdAt TEXT
      )
    ''');
  }

  Future<int> insertAdmission(Map<String, dynamic> data) async {
    final db = await database;
    data['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('admissions', data);
  }

  Future<List<Map<String, dynamic>>> getAllAdmissions() async {
    final db = await database;
    return await db.query('admissions', orderBy: 'createdAt DESC');
  }
}
