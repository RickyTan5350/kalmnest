import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:code_play/models/achievement_data.dart';
// Note: Requires adding 'encrypt: ^latest' to pubspec.yaml
import 'package:encrypt/encrypt.dart' as encrypt;
// Note: Requires adding 'flutter_secure_storage: ^latest' to pubspec.yaml
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalAchievementStorage {
  // --- 1. SECURE STORAGE SETUP ---
  // Use platform-specific secure storage for storing the crypto key/IV.
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Internal variables to hold the encryption components after retrieval/generation
  encrypt.Key? _key;
  encrypt.IV? _iv;
  encrypt.Encrypter? _encrypter;

  // Key names used in secure storage
  static const String _keyName = 'local_achievement_key';
  static const String _ivName = 'local_achievement_iv';

  // --- 2. ASYNCHRONOUS KEY INITIALIZATION ---
  Future<void> _initEncrypter() async {
    if (_encrypter != null) {
      return; // Already initialized
    }

    // Attempt to read key and IV from secure storage
    String? keyBase64 = await _secureStorage.read(key: _keyName);
    String? ivBase64 = await _secureStorage.read(key: _ivName);

    if (keyBase64 == null || ivBase64 == null) {
      // Keys do not exist yet, generate them securely and store them
      print('Generating new secure encryption keys...');

      _key = encrypt.Key.fromSecureRandom(32); // 256-bit key
      _iv = encrypt.IV.fromSecureRandom(16);    // 128-bit IV

      // Store them as Base64 strings for persistence
      await _secureStorage.write(key: _keyName, value: _key!.base64);
      await _secureStorage.write(key: _ivName, value: _iv!.base64);
    } else {
      // Keys exist, load them
      print('Loading encryption keys from secure storage...');
      _key = encrypt.Key.fromBase64(keyBase64);
      _iv = encrypt.IV.fromBase64(ivBase64);
    }

    // Initialize the Encrypter once we have the key/IV
    _encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.cbc));
  }
  // ------------------------------------------

  // 3. GET FILE REFERENCE
  Future<File> _getLocalFile(String userId) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$userId.json');
  }

  // 4. SAVE ACHIEVEMENTS (ENCRYPT)
  Future<void> saveUnlockedAchievements(String userId, List<AchievementData> achievements) async {
    await _initEncrypter(); // Ensure encrypter is ready

    final file = await _getLocalFile(userId);

    // Convert the list of objects into a List of JSON maps
    final List<Map<String, dynamic>> achievementMaps = achievements.map((a) => {
      'achievement_id': a.achievementId,
      'title': a.achievementTitle,
      'description': a.achievementDescription,
      'icon': a.icon,
      'associated_level': a.levelName,
      'obtained_at': DateTime.now().toIso8601String(),
    }).toList();

    // 1. Convert data to JSON string
    final String jsonString = jsonEncode(achievementMaps);

    // 2. Encrypt the JSON string using the securely loaded components
    final encrypted = _encrypter!.encrypt(jsonString, iv: _iv!);

    // 3. Write the Base64-encoded encrypted data to storage
    await file.writeAsString(encrypted.base64);
    print('Saved and encrypted local achievements to: ${file.path}');
  }

  // 5. READ ACHIEVEMENTS (DECRYPT)
  Future<List<AchievementData>> getUnlockedAchievements(String userId) async {
    await _initEncrypter(); // Ensure encrypter is ready

    try {
      final file = await _getLocalFile(userId);

      if (!await file.exists()) {
        print('No local file found for user: $userId');
        return [];
      }

      // 1. Read the encrypted contents (Base64 string)
      final String encryptedBase64 = await file.readAsString();

      // 2. Decrypt the contents
      // Use the securely loaded _encrypter and _iv
      final decryptedBytes = _encrypter!.decrypt64(encryptedBase64, iv: _iv!);
      final String contents = decryptedBytes; // This is the original JSON string

      // 3. Decode the JSON string
      final List<dynamic> jsonList = jsonDecode(contents);

      // 4. Map back to AchievementData objects
      return jsonList.map((json) => AchievementData.fromJson(json)).toList();

    } catch (e) {
      print('Error reading or decrypting local achievements: $e');
      return [];
    }
  }

  // 6. CLEAR DATA (Optional) - Also clear the secure storage keys if needed on logout
  Future<void> clearLocalCache(String userId) async {
    final file = await _getLocalFile(userId);
    if (await file.exists()) {
      await file.delete();
    }
    // Optional: Clear the keys as well, typically done during full app reset or logout
    // await _secureStorage.delete(key: _keyName);
    // await _secureStorage.delete(key: _ivName);
    _encrypter = null; // Reset internal state
  }
}
