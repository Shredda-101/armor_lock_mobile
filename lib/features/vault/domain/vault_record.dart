import 'dart:convert';

class VaultRecord {
  const VaultRecord({
    required this.id,
    required this.name,
    required this.cipherText,
    required this.nonce,
    required this.mac,
    required this.version,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final List<int> cipherText;
  final List<int> nonce;
  final List<int> mac;
  final int version;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'cipherText': base64Encode(cipherText),
      'nonce': base64Encode(nonce),
      'mac': base64Encode(mac),
      'version': version,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory VaultRecord.fromJson(Map<String, dynamic> json) {
    return VaultRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      cipherText: base64Decode(json['cipherText'] as String),
      nonce: base64Decode(json['nonce'] as String),
      mac: base64Decode(json['mac'] as String),
      version: json['version'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
