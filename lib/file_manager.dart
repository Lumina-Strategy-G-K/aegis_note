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

import 'dart:io';
import 'package:aegis_note/security_service.dart';

class AegisFileManager {
  static Future<void> saveEncryptedFile(
    String path,
    String content, [
    String? password,
  ]) async {
    if (password != null) {
      await AegisSecurityService.initializeKey(password);
    }

    final encrypted = await AegisSecurityService.encrypt(content);
    final file = File(path);
    final temp = File("$path.tmp");
    await temp.writeAsBytes(encrypted, flush: true);
    if (await file.exists()) await file.delete();
    await temp.rename(path);
  }

  static Future<String> readEncryptedFile(
    String path, [
    String? password,
  ]) async {
    final file = File(path);
    if (!await file.exists()) return "";

    if (password != null) {
      await AegisSecurityService.initializeKey(password);
    }

    final bytes = await file.readAsBytes();
    return await AegisSecurityService.decrypt(bytes);
  }
}
