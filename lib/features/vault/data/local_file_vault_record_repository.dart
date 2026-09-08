import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/vault_record.dart';
import '../domain/vault_record_repository.dart';

class LocalFileVaultRecordRepository implements VaultRecordRepository {
  static const _fileName = 'vault_records.json';

  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  @override
  Future<List<VaultRecord>> loadRecords() async {
    try {
      final file = await _file;
      if (!await file.exists()) {
        return <VaultRecord>[];
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as List<dynamic>;

      return json
          .map((dynamic e) => VaultRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // In a real app, log the error to the security journal.
      return <VaultRecord>[];
    }
  }

  @override
  Future<void> saveRecords(List<VaultRecord> records) async {
    final file = await _file;
    final json = records.map((r) => r.toJson()).toList();
    await file.writeAsString(jsonEncode(json));
  }
}
