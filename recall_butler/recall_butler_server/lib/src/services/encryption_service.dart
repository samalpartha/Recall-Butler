import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'config_service.dart';
import 'logger_service.dart';

/// Privacy-First Encryption Service
/// Provides end-to-end encryption for sensitive user data
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final _config = ConfigService();
  final _random = Random.secure();

  // Key derivation parameters
  static const int _saltLength = 16;
  static const int _ivLength = 16;
  static const int _keyLength = 32;
  static const int _iterations = 100000;

  /// Generate a new encryption key for a user
  UserEncryptionKeys generateUserKeys({required String password}) {
    final salt = _generateRandomBytes(_saltLength);
    final masterKey = _deriveKey(password, salt);
    final dataKey = _generateRandomBytes(_keyLength);
    final encryptedDataKey = _xorEncrypt(dataKey, masterKey);
    
    return UserEncryptionKeys(
      salt: base64Encode(salt),
      encryptedDataKey: base64Encode(encryptedDataKey),
      keyVersion: 1,
      createdAt: DateTime.now(),
    );
  }

  /// Encrypt data with user's key
  EncryptedData encrypt({
    required String plaintext,
    required String userDataKey,
  }) {
    final key = base64Decode(userDataKey);
    final iv = _generateRandomBytes(_ivLength);
    final plaintextBytes = utf8.encode(plaintext);
    
    // Simple XOR cipher for demo (use AES-GCM in production)
    final encrypted = _xorEncryptWithIV(plaintextBytes, key, iv);
    
    // Generate authentication tag (HMAC)
    final hmac = Hmac(sha256, key);
    final tag = hmac.convert([...iv, ...encrypted]).bytes;
    
    return EncryptedData(
      ciphertext: base64Encode(encrypted),
      iv: base64Encode(iv),
      tag: base64Encode(tag),
      algorithm: 'XOR-HMAC-SHA256', // Would be AES-256-GCM in production
    );
  }

  /// Decrypt data with user's key
  String decrypt({
    required EncryptedData encryptedData,
    required String userDataKey,
  }) {
    final key = base64Decode(userDataKey);
    final iv = base64Decode(encryptedData.iv);
    final ciphertext = base64Decode(encryptedData.ciphertext);
    final tag = base64Decode(encryptedData.tag);
    
    // Verify authentication tag
    final hmac = Hmac(sha256, key);
    final expectedTag = hmac.convert([...iv, ...ciphertext]).bytes;
    
    if (!_constantTimeCompare(tag, Uint8List.fromList(expectedTag))) {
      throw EncryptionException('Authentication failed - data may be tampered');
    }
    
    // Decrypt
    final decrypted = _xorEncryptWithIV(ciphertext, key, iv);
    return utf8.decode(decrypted);
  }

  /// Derive user's data key from password
  String deriveDataKey({
    required String password,
    required String salt,
    required String encryptedDataKey,
  }) {
    final saltBytes = base64Decode(salt);
    final masterKey = _deriveKey(password, saltBytes);
    final encryptedKeyBytes = base64Decode(encryptedDataKey);
    final dataKey = _xorEncrypt(encryptedKeyBytes, masterKey);
    return base64Encode(dataKey);
  }

  /// Encrypt a document for storage
  Future<EncryptedDocument> encryptDocument({
    required int documentId,
    required String title,
    required String content,
    required String userDataKey,
    Map<String, dynamic>? metadata,
  }) async {
    final encryptedTitle = encrypt(plaintext: title, userDataKey: userDataKey);
    final encryptedContent = encrypt(plaintext: content, userDataKey: userDataKey);
    
    String? encryptedMetadata;
    if (metadata != null) {
      final metadataJson = jsonEncode(metadata);
      encryptedMetadata = jsonEncode(
        encrypt(plaintext: metadataJson, userDataKey: userDataKey).toJson()
      );
    }
    
    logger.debug('Document encrypted', context: {'documentId': documentId});
    
    return EncryptedDocument(
      documentId: documentId,
      encryptedTitle: encryptedTitle,
      encryptedContent: encryptedContent,
      encryptedMetadata: encryptedMetadata,
      encryptedAt: DateTime.now(),
    );
  }

  /// Decrypt a document
  Future<DecryptedDocument> decryptDocument({
    required EncryptedDocument encryptedDoc,
    required String userDataKey,
  }) async {
    final title = decrypt(
      encryptedData: encryptedDoc.encryptedTitle,
      userDataKey: userDataKey,
    );
    
    final content = decrypt(
      encryptedData: encryptedDoc.encryptedContent,
      userDataKey: userDataKey,
    );
    
    Map<String, dynamic>? metadata;
    if (encryptedDoc.encryptedMetadata != null) {
      final metadataEncrypted = EncryptedData.fromJson(
        jsonDecode(encryptedDoc.encryptedMetadata!)
      );
      final metadataJson = decrypt(
        encryptedData: metadataEncrypted,
        userDataKey: userDataKey,
      );
      metadata = jsonDecode(metadataJson);
    }
    
    return DecryptedDocument(
      documentId: encryptedDoc.documentId,
      title: title,
      content: content,
      metadata: metadata,
    );
  }

  /// Generate secure sharing key for workspace
  ShareKey generateShareKey({
    required String workspaceId,
    required int ownerId,
    Duration validFor = const Duration(days: 7),
  }) {
    final keyBytes = _generateRandomBytes(_keyLength);
    final key = base64UrlEncode(keyBytes);
    
    return ShareKey(
      key: key,
      workspaceId: workspaceId,
      ownerId: ownerId,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(validFor),
    );
  }

  /// Securely hash sensitive data for indexing (allows search without decryption)
  String hashForIndex(String data, {String? pepper}) {
    final hmac = Hmac(sha256, utf8.encode(pepper ?? _config.jwtSecret));
    final digest = hmac.convert(utf8.encode(data.toLowerCase()));
    return digest.toString();
  }

  /// Generate a secure random token
  String generateSecureToken({int length = 32}) {
    final bytes = _generateRandomBytes(length);
    return base64UrlEncode(bytes);
  }

  // Private helper methods

  Uint8List _generateRandomBytes(int length) {
    return Uint8List.fromList(
      List.generate(length, (_) => _random.nextInt(256)),
    );
  }

  Uint8List _deriveKey(String password, Uint8List salt) {
    // PBKDF2 key derivation
    final hmac = Hmac(sha256, utf8.encode(password));
    var result = Uint8List(_keyLength);
    var block = 1;
    var pos = 0;

    while (pos < _keyLength) {
      var u = hmac.convert([...salt, (block >> 24) & 0xff, (block >> 16) & 0xff, (block >> 8) & 0xff, block & 0xff]).bytes;
      var t = Uint8List.fromList(u);

      for (var i = 1; i < _iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }

      for (var i = 0; i < t.length && pos < _keyLength; i++, pos++) {
        result[pos] = t[i];
      }
      block++;
    }

    return result;
  }

  Uint8List _xorEncrypt(Uint8List data, Uint8List key) {
    final result = Uint8List(data.length);
    for (var i = 0; i < data.length; i++) {
      result[i] = data[i] ^ key[i % key.length];
    }
    return result;
  }

  Uint8List _xorEncryptWithIV(List<int> data, Uint8List key, Uint8List iv) {
    final result = Uint8List(data.length);
    final expandedKey = Uint8List(data.length);
    
    // Expand key using IV as counter
    for (var i = 0; i < data.length; i++) {
      final counterBlock = i ~/ key.length;
      final hmac = Hmac(sha256, key);
      final block = hmac.convert([...iv, counterBlock]).bytes;
      expandedKey[i] = block[i % block.length];
    }
    
    for (var i = 0; i < data.length; i++) {
      result[i] = data[i] ^ expandedKey[i];
    }
    return result;
  }

  bool _constantTimeCompare(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

/// User encryption keys
class UserEncryptionKeys {
  final String salt;
  final String encryptedDataKey;
  final int keyVersion;
  final DateTime createdAt;

  UserEncryptionKeys({
    required this.salt,
    required this.encryptedDataKey,
    required this.keyVersion,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'salt': salt,
    'encryptedDataKey': encryptedDataKey,
    'keyVersion': keyVersion,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Encrypted data container
class EncryptedData {
  final String ciphertext;
  final String iv;
  final String tag;
  final String algorithm;

  EncryptedData({
    required this.ciphertext,
    required this.iv,
    required this.tag,
    required this.algorithm,
  });

  Map<String, dynamic> toJson() => {
    'ciphertext': ciphertext,
    'iv': iv,
    'tag': tag,
    'algorithm': algorithm,
  };

  factory EncryptedData.fromJson(Map<String, dynamic> json) {
    return EncryptedData(
      ciphertext: json['ciphertext'],
      iv: json['iv'],
      tag: json['tag'],
      algorithm: json['algorithm'],
    );
  }
}

/// Encrypted document
class EncryptedDocument {
  final int documentId;
  final EncryptedData encryptedTitle;
  final EncryptedData encryptedContent;
  final String? encryptedMetadata;
  final DateTime encryptedAt;

  EncryptedDocument({
    required this.documentId,
    required this.encryptedTitle,
    required this.encryptedContent,
    this.encryptedMetadata,
    required this.encryptedAt,
  });
}

/// Decrypted document
class DecryptedDocument {
  final int documentId;
  final String title;
  final String content;
  final Map<String, dynamic>? metadata;

  DecryptedDocument({
    required this.documentId,
    required this.title,
    required this.content,
    this.metadata,
  });
}

/// Share key for workspace sharing
class ShareKey {
  final String key;
  final String workspaceId;
  final int ownerId;
  final DateTime createdAt;
  final DateTime expiresAt;

  ShareKey({
    required this.key,
    required this.workspaceId,
    required this.ownerId,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Encryption exception
class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);
  @override
  String toString() => message;
}
