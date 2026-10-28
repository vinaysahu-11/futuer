import 'package:insforge_flutter/insforge_flutter.dart';
import 'insforge_service.dart';

/// Database service wrapping InsForge PostgREST database operations.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  InsforgeClient get _client => InsforgeService.instance.client;

  /// Fetches rows from the given [tableName].
  Future<List<Map<String, dynamic>>> fetchRecords({
    required String tableName,
    int limit = 50,
    String? orderBy,
    bool ascending = false,
  }) async {
    var query = _client.database.from(tableName).select();

    if (orderBy != null) {
      query = query.order(orderBy, ascending: ascending);
    }

    query = query.limit(limit);
    return await query.execute();
  }

  /// Inserts a new row into [tableName] and returns the inserted row.
  Future<List<Map<String, dynamic>>> insertRecord({
    required String tableName,
    required Map<String, dynamic> data,
  }) async {
    return await _client.database
        .from(tableName)
        .insert(data)
        .select()
        .execute();
  }

  /// Updates rows in [tableName] where [idColumn] == [idValue].
  Future<List<Map<String, dynamic>>> updateRecord({
    required String tableName,
    required String idColumn,
    required dynamic idValue,
    required Map<String, dynamic> data,
  }) async {
    return await _client.database
        .from(tableName)
        .eq(idColumn, idValue)
        .update(data)
        .select()
        .execute();
  }

  /// Deletes rows in [tableName] where [idColumn] == [idValue].
  Future<void> deleteRecord({
    required String tableName,
    required String idColumn,
    required dynamic idValue,
  }) async {
    await _client.database
        .from(tableName)
        .eq(idColumn, idValue)
        .delete()
        .execute();
  }
}
