import 'vault_record.dart';

abstract interface class VaultRecordRepository {
  Future<List<VaultRecord>> loadRecords();
  Future<void> saveRecords(List<VaultRecord> records);
}
