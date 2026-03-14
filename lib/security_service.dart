/*
 * Copyright 2026 Lumina Strategy G.K.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class AegisSecurityService {
  static final _algorithm = Xchacha20(macAlgorithm: Poly1305());
  static SecretKey? _masterKey;

  static Future<void> initializeKey(String password) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 600000,
      bits: 256,
    );
    final salt = utf8.encode("aegis_note_secure_salt_2024");
    _masterKey = await pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
  }

  static void wipeKey() => _masterKey = null;

  static Future<Uint8List> encrypt(String plainText) async {
    if (_masterKey == null) throw Exception("ログインが必要です");
    final secretBox = await _algorithm.encryptString(
      plainText,
      secretKey: _masterKey!,
    );
    final builder = BytesBuilder();
    builder.add(secretBox.nonce);
    builder.add(secretBox.cipherText);
    builder.add(secretBox.mac.bytes);
    return builder.toBytes();
  }

  static Future<String> decrypt(Uint8List data) async {
    if (_masterKey == null) return "";
    if (data.length < 40) return "";
    final secretBox = SecretBox(
      data.sublist(24, data.length - 16),
      nonce: data.sublist(0, 24),
      mac: Mac(data.sublist(data.length - 16)),
    );
    return await _algorithm.decryptString(secretBox, secretKey: _masterKey!);
  }

  static Future<void> clearClipboard() async {
    await Clipboard.setData(const ClipboardData(text: ''));
  }
}
