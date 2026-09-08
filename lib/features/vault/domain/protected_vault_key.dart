class ProtectedVaultKey {
  const ProtectedVaultKey({
    required this.keyId,
    required this.wrappedKeyMaterial,
    required this.version,
    required this.createdAt,
  });

  final String keyId;
  final List<int> wrappedKeyMaterial;
  final int version;
  final DateTime createdAt;
}
