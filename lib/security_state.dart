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
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:aegis_note/security_service.dart';
import 'package:aegis_note/file_manager.dart';

class FolderNode {
  final Directory directory;
  final List<FolderNode> subFolders;
  bool isExpanded = false;
  FolderNode(this.directory, this.subFolders);
}

class AegisSecurityState extends ChangeNotifier {
  // --- 状態フラグ ---
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  bool isEditing = false;
  bool isProcessing = false;
  bool _isPreviewMode = false;
  bool get isPreviewMode => _isPreviewMode;
  bool _isFirstRun = true;
  bool get isFirstRun => _isFirstRun;
  bool _needsAndroidPath = false;
  bool get needsAndroidPath => _needsAndroidPath;
  bool _isInFolder = false;
  bool get isInFolder => _isInFolder;

  // --- IMEガード ---
  bool _isImeBlocked = false;
  bool get isImeBlocked => _isImeBlocked;
  void setImeBlocked(bool value) {
    if (_isImeBlocked != value) {
      _isImeBlocked = value;
      notifyListeners();
    }
  }

  // Windows用ダミー
  Future<void> disableSystemIme() async {}
  Future<void> enableSystemIme() async {}

  // --- 管理データ ---
  String? loginErrorMessage;
  double passwordChangeProgress = 0.0;
  Directory? rootDirectory;
  Directory? selectedDirectory;
  File? selectedFile;
  FolderNode? rootNode;
  List<File> files = [];
  final TextEditingController editorController = TextEditingController();
  final Set<String> _expandedPaths = {};

  // --- 多言語化 ---
  String _lang = 'en';
  String get lang => _lang;
  static const Map<String, Map<String, String>> _dict = {
    'en': {
      'folders': 'DIRECTORIES',
      'files': 'FILES',
      'login': 'AUTHENTICATION',
      'setup': 'INITIAL CONFIGURATION',
      'password': 'Master Password',
      'confirm_pw': 'Confirm Password',
      'new_pw': 'New Master Password',
      'current_pw': 'Current Master Password',
      'start': 'START',
      'setup_done': 'COMPLETE CONFIGURATION',
      'save': 'SAVE CHANGES',
      'discard': 'DISCARD CHANGES',
      'edit': 'EDIT MODE',
      'preview': 'VIEW MODE',
      'new_folder': 'NEW DIRECTORY',
      'new_file': 'NEW FILE',
      'rename': 'RENAME',
      'delete': 'DELETE',
      'logout': 'TERMINATE SESSION',
      'pw_change': 'UPDATE PASSWORD',
      'license': 'LICENSE INFORMATION',
      'msg_inactivity': 'Inactivity detected. Automatic logout in ',
      'msg_sec': ' seconds',
      'msg_continue': 'CONTINUE SESSION',
      'msg_unsaved': 'UNSAVED CHANGES',
      'msg_confirm_discard': 'Discard unsaved changes and proceed?',
      'msg_confirm_delete': 'Permanently delete this item and its contents?',
      'text_file': 'Plain Text (.ext)',
      'md_file': 'Markdown (.mde)',
      'cancel': 'CANCEL',
      'execute': 'EXECUTE',
      'err_login': 'Authentication failed. Incorrect password.',
      'pick_folder': 'SELECT DATA REPOSITORY',
      'android_pick_msg':
          'Please select a persistent directory for encrypted data storage.',
      'err_ime': 'Please disable the IME.',
      'msg_clipboard': 'Clipboard content has been securely cleared. 🗑️',
    },
    'ja': {
      'folders': 'ディレクトリ一覧',
      'files': 'ファイル一覧',
      'login': '認証実行',
      'setup': '初期セットアップ',
      'password': 'マスターパスワード',
      'confirm_pw': 'パスワード（再入力）',
      'new_pw': '新規マスターパスワード',
      'current_pw': '現在のマスターパスワード',
      'start': '開始',
      'setup_done': '設定を完了する',
      'save': '変更を保存',
      'discard': '変更を破棄',
      'edit': '編集モード',
      'preview': '閲覧モード',
      'new_folder': 'ディレクトリ作成',
      'new_file': '新規ファイル作成',
      'rename': '名称変更',
      'delete': '削除実行',
      'logout': 'セッション終了',
      'pw_change': 'パスワードの更新',
      'license': 'ライセンス情報',
      'msg_inactivity': '無操作状態を検知しました。自動ログアウトまで残り ',
      'msg_sec': ' 秒',
      'msg_continue': '作業を継続',
      'msg_unsaved': '未保存の変更',
      'msg_confirm_discard': '未保存の変更を破棄してよろしいですか？',
      'msg_confirm_delete': '対象の項目（および内部データ）を完全に削除しますか？',
      'text_file': 'テキスト (.ext)',
      'md_file': 'マークダウン (.mde)',
      'cancel': 'キャンセル',
      'execute': '実行',
      'err_login': '認証に失敗しました。パスワードを確認してください。',
      'pick_folder': 'データ保存先の選択',
      'android_pick_msg': '暗号化データを保管するための永続的なディレクトリを選択してください。',
      'err_ime': 'IMEを無効にしてください。',
      'msg_clipboard': 'クリップボードのデータを消去しました。 🗑️',
    },
    'fr': {
      'folders': 'RÉPERTOIRES',
      'files': 'FICHIERS',
      'login': 'AUTHENTIFICATION',
      'setup': 'CONFIGURATION INITIALE',
      'password': 'Mot de passe maître',
      'confirm_pw': 'Confirmer le mot de passe',
      'new_pw': 'Nouveau mot de passe',
      'current_pw': 'Mot de passe actuel',
      'start': 'DÉMARRER',
      'setup_done': 'TERMINER LA CONFIGURATION',
      'save': 'ENREGISTRER',
      'discard': 'ABANDONNER',
      'edit': 'MODE ÉDITION',
      'preview': 'MODE APERÇU',
      'new_folder': 'NOUVEAU RÉPERTOIRE',
      'new_file': 'NOUVEAU FICHIER',
      'rename': 'RENOMMER',
      'delete': 'SUPPRIMER',
      'logout': 'TERMINER LA SESSION',
      'pw_change': 'METTRE À JOUR LE MOT DE PASSE',
      'license': 'INFORMATIONS DE LICENCE',
      'msg_inactivity': 'Inactivité détectée. Déconnexion dans ',
      'msg_sec': ' secondes',
      'msg_continue': 'CONTINUER LA SESSION',
      'msg_unsaved': 'MODIFICATIONS NON ENREGISTRÉES',
      'msg_confirm_discard': 'Abandonner les modifications et continuer ?',
      'msg_confirm_delete':
          'Supprimer définitivement cet élément et son contenu ?',
      'text_file': 'Texte brut (.ext)',
      'md_file': 'Markdown (.mde)',
      'cancel': 'ANNULER',
      'execute': 'EXÉCUTER',
      'err_login': 'Échec de l\'authentification. Mot de passe incorrect.',
      'pick_folder': 'SÉLECTIONNER LE RÉPERTOIRE',
      'android_pick_msg':
          'Veuillez choisir un répertoire pour le stockage des données chiffrées.',
      "err_ime": "Désactivez la méthode de saisie.",
      'msg_clipboard': 'Le contenu du presse-papiers a été effacé. 🗑️',
    },
    'es': {
      'folders': 'DIRECTORIOS',
      'files': 'ARCHIVOS',
      'login': 'AUTENTICACIÓN',
      'setup': 'CONFIGURACIÓN INICIAL',
      'password': 'Contraseña maestra',
      'confirm_pw': 'Confirmar contraseña',
      'new_pw': 'Nueva contraseña maestra',
      'current_pw': 'Contraseña actual',
      'start': 'INICIAR',
      'setup_done': 'COMPLETAR CONFIGURACIÓN',
      'save': 'GUARDAR CAMBIOS',
      'discard': 'DESCARTAR CAMBIOS',
      'edit': 'MODO EDICIÓN',
      'preview': 'MODO VISTA PREVIA',
      'new_folder': 'NUEVO DIRECTORIO',
      'new_file': 'NUEVO ARCHIVO',
      'rename': 'RENOMBRAR',
      'delete': 'ELIMINAR',
      'logout': 'CERRAR SESIÓN',
      'pw_change': 'ACTUALIZAR CONTRASEÑA',
      'license': 'INFORMACIÓN DE LICENCIA',
      'msg_inactivity': 'Inactividad detectada. Cierre de sesión en ',
      'msg_sec': ' segundos',
      'msg_continue': 'CONTINUAR SESIÓN',
      'msg_unsaved': 'CAMBIOS NO GUARDADOS',
      'msg_confirm_discard': '¿Descartar cambios y continuar?',
      'msg_confirm_delete': '¿Eliminar permanentemente este elemento?',
      'text_file': 'Texto plano (.ext)',
      'md_file': 'Markdown (.mde)',
      'cancel': 'CANCELAR',
      'execute': 'EJECUTAR',
      'err_login': 'Fallo de autenticación. Contraseña incorrecta.',
      'pick_folder': 'SELECCIONAR DIRECTORIO DE DATOS',
      'android_pick_msg':
          'Seleccione un directorio para el almacenamiento de datos cifrados.',
      'err_ime': 'Por favor, desactive el IME.',
      'msg_clipboard': 'El portapapeles se ha borrado de forma segura. 🗑️',
    },
    'ru': {
      'folders': 'ДИРЕКТОРИИ',
      'files': 'ФАЙЛЫ',
      'login': 'АУТЕНТИФИКАЦИЯ',
      'setup': 'НАЧАЛЬНАЯ НАСТРОЙКА',
      'password': 'Мастер-пароль',
      'confirm_pw': 'Подтверждение пароля',
      'new_pw': 'Новый мастер-пароль',
      'current_pw': 'Текущий мастер-пароль',
      'start': 'ПУСК',
      'setup_done': 'ЗАВЕРШИТЬ НАСТРОЙКУ',
      'save': 'СОХРАНИТЬ ИЗМЕНЕНИЯ',
      'discard': 'ОТМЕНИТЬ ИЗМЕНЕНИЯ',
      'edit': 'РЕЖИМ ПРАВКИ',
      'preview': 'РЕЖИМ ПРОСМОТРА',
      'new_folder': 'НОВАЯ ДИРЕКТОРИЯ',
      'new_file': 'НОВЫЙ ФАЙЛ',
      'rename': 'ПЕРЕИМЕНОВАТЬ',
      'delete': 'УДАЛИТЬ',
      'logout': 'ЗАВЕРШИТЬ СЕССИЮ',
      'pw_change': 'ОБНОВИТЬ ПАРОЛЬ',
      'license': 'ЛИЦЕНЗИОННАЯ ИНФОРМАЦИЯ',
      'msg_inactivity': 'Обнаружена неактивность. Выход через ',
      'msg_sec': ' секунд',
      'msg_continue': 'ПРОДОЛЖИТЬ СЕССИЮ',
      'msg_unsaved': 'НЕСОХРАНЕННЫЕ ИЗМЕНЕНИЯ',
      'msg_confirm_discard': 'Отменить изменения и продолжить?',
      'msg_confirm_delete': 'Удалить этот объект и его содержимое?',
      'text_file': 'Текст (.ext)',
      'md_file': 'Markdown (.mde)',
      'cancel': 'ОТМЕНА',
      'execute': 'ВЫПОЛНИТЬ',
      'err_login': 'Ошибка аутентификации. Неверный пароль.',
      'pick_folder': 'ВЫБРАТЬ ХРАНИЛИЩЕ ДАННЫХ',
      'android_pick_msg':
          'Выберите директорию для хранения зашифрованных данных.',
      'err_ime': 'Пожалуйста, отключите IME.',
      'msg_clipboard': 'Буфер обмена успешно очищен. 🗑️',
    },
    'zh': {
      'folders': '目录列表',
      'files': '文件列表',
      'login': '身份验证',
      'setup': '初始配置',
      'password': '主密码',
      'confirm_pw': '确认密码',
      'new_pw': '新主密码',
      'current_pw': '当前主密码',
      'start': '开始',
      'setup_done': '完成配置',
      'save': '保存更改',
      'discard': '放弃更改',
      'edit': '编辑模式',
      'preview': '预览模式',
      'new_folder': '新建目录',
      'new_file': '新建文件',
      'rename': '更改名称',
      'delete': '执行删除',
      'logout': '终止会话',
      'pw_change': '更新密码',
      'license': '许可证信息',
      'msg_inactivity': '检测到无操作。自动退出剩余时间：',
      'msg_sec': ' 秒',
      'msg_continue': '继续操作',
      'msg_unsaved': '更改未保存',
      'msg_confirm_discard': '确定要放弃更改并继续吗？',
      'msg_confirm_delete': '确定要永久删除此项目及其内容吗？',
      'text_file': '纯文本 (.ext)',
      'md_file': 'Markdown (.mde)',
      'cancel': '取消',
      'execute': '执行',
      'err_login': '身份验证失败。密码错误。',
      'pick_folder': '选择数据存储目录',
      'android_pick_msg': '请选择用于存放加密数据的持久目录。',
      'err_ime': '请禁用输入法。',
      'msg_clipboard': '剪贴板内容已清除。 🗑️',
    },
  };
  String t(String key) => _dict[_lang]?[key] ?? _dict['en']![key] ?? key;

  // --- 初期化 ---
  String _norm(String path) => p.normalize(path);
  Future<void> initializeApp() async {
    final String locale = Platform.localeName.split('_')[0];
    _lang = _dict.containsKey(locale) ? locale : 'en';
    if (Platform.isWindows || Platform.isLinux) {
      final exeDir = Directory(Platform.resolvedExecutable).parent.path;
      rootDirectory = Directory(_norm(p.join(exeDir, 'user_data')));
      if (!rootDirectory!.existsSync())
        rootDirectory!.createSync(recursive: true);
    } else if (Platform.isAndroid) {
      final prefs = await SharedPreferences.getInstance();
      String? savedPath = prefs.getString('android_data_path');
      var status = await Permission.manageExternalStorage.status;
      if (savedPath == null || !status.isGranted) {
        _needsAndroidPath = true;
        notifyListeners();
        return;
      }
      rootDirectory = Directory(_norm(savedPath));
      if (!rootDirectory!.existsSync())
        rootDirectory!.createSync(recursive: true);
    }
    _isFirstRun = !File(
      p.join(rootDirectory!.path, '.aegis_config_v2'),
    ).existsSync();
    selectedDirectory = rootDirectory;
    _expandedPaths.add(_norm(rootDirectory!.path));
    _needsAndroidPath = false;
    refreshLists();
    notifyListeners();
  }

  // --- アクション ---
  Future<bool> login(String pw) async {
    loginErrorMessage = null;
    notifyListeners();
    try {
      await AegisSecurityService.initializeKey(pw);
      final data = await File(
        p.join(rootDirectory!.path, '.aegis_config_v2'),
      ).readAsBytes();
      if (await AegisSecurityService.decrypt(data) == "LOGIN_SUCCESS") {
        selectedDirectory = rootDirectory;
        selectedFile = null;
        _expandedPaths.clear();
        _expandedPaths.add(_norm(rootDirectory!.path));
        _isInFolder = false;

        _isLoggedIn = true;
        refreshLists();
        notifyListeners();
        return true;
      }
    } catch (e) {
      AegisSecurityService.wipeKey();
    }
    loginErrorMessage = t('err_login');
    notifyListeners();
    return false;
  }

  Future<void> setupMasterPassword(String pw) async {
    await AegisSecurityService.initializeKey(pw);
    final flag = await AegisSecurityService.encrypt("LOGIN_SUCCESS");
    await File(
      p.join(rootDirectory!.path, '.aegis_config_v2'),
    ).writeAsBytes(flag);
    _isFirstRun = false;
    _isLoggedIn = true;
    refreshLists();
    notifyListeners();
  }

  void logout() {
    AegisSecurityService.wipeKey();
    _isLoggedIn = false;
    isEditing = false;

    selectedFile = null;
    selectedDirectory = rootDirectory;
    _expandedPaths.clear();
    _isInFolder = false;
    editorController.clear();

    notifyListeners();
  }

  void refreshLists() {
    if (rootDirectory == null) return;

    rootNode = _buildTree(rootDirectory!);

    if (selectedDirectory == null || !selectedDirectory!.existsSync()) {
      selectedDirectory = rootDirectory;
    }

    if (selectedDirectory != null) {
      files =
          selectedDirectory!
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.ext') || f.path.endsWith('.mde'))
              .toList()
            ..sort(
              (a, b) => compareNatural(p.basename(a.path), p.basename(b.path)),
            );
    }
    notifyListeners();
  }

  FolderNode _buildTree(Directory dir) {
    final subDirs = dir.listSync().whereType<Directory>().toList()
      ..sort((a, b) => compareNatural(p.basename(a.path), p.basename(b.path)));
    final node = FolderNode(dir, subDirs.map((d) => _buildTree(d)).toList());
    node.isExpanded = _expandedPaths.contains(_norm(dir.path));
    return node;
  }

  void toggleFolderExpanded(FolderNode node) {
    final path = _norm(node.directory.path);
    if (node.isExpanded) {
      _expandedPaths.remove(path);
    } else {
      _expandedPaths.add(path);
    }
    refreshLists();
  }

  void selectDirectory(Directory dir) {
    selectedDirectory = dir;
    selectedFile = null;
    isEditing = false;
    _isInFolder = true;
    editorController.clear();
    refreshLists();
  }

  void selectDirectoryOnly(Directory dir) {
    selectedDirectory = dir;
    refreshLists();
  }

  void exitFolder() {
    _isInFolder = false;
    selectedFile = null;
    notifyListeners();
  }

  void selectFile(File file) async {
    selectedFile = file;
    isEditing = false;
    _isPreviewMode = true;
    editorController.text = await AegisFileManager.readEncryptedFile(file.path);
    notifyListeners();
  }

  void closeFile() {
    selectedFile = null;
    isEditing = false;
    notifyListeners();
  }

  void setEditing(bool val) {
    isEditing = val;
    notifyListeners();
  }

  void setPreviewMode(bool val) {
    _isPreviewMode = val;
    notifyListeners();
  }

  Future<void> saveCurrentFile() async {
    if (selectedFile == null) return;
    await AegisFileManager.saveEncryptedFile(
      selectedFile!.path,
      editorController.text,
    );
    isEditing = false;
    notifyListeners();
  }

  Future<void> createNewFile(String name, String ext) async {
    if (selectedDirectory == null || name.isEmpty) return;
    await AegisFileManager.saveEncryptedFile(
      _norm(p.join(selectedDirectory!.path, "$name$ext")),
      "",
    );
    refreshLists();
  }

  Future<void> createFolder(String name) async {
    if (selectedDirectory == null || name.isEmpty) return;
    final d = Directory(_norm(p.join(selectedDirectory!.path, name)));
    if (!d.existsSync()) {
      d.createSync();
      _expandedPaths.add(_norm(selectedDirectory!.path));
      selectedDirectory = d;
      refreshLists();
    }
  }

  Future<void> renameFile(File file, String newName) async {
    await file.rename(
      _norm(p.join(file.parent.path, "$newName${p.extension(file.path)}")),
    );
    refreshLists();
  }

  Future<void> deleteFile(File file) async {
    await file.delete();
    selectedFile = null;
    refreshLists();
  }

  Future<void> renameFolder(Directory dir, String newName) async {
    final n = _norm(p.join(dir.parent.path, newName));
    await dir.rename(n);
    selectedDirectory = Directory(n);
    refreshLists();
  }

  Future<void> deleteFolder(Directory dir) async {
    if (_norm(dir.path) != _norm(rootDirectory!.path)) {
      dir.deleteSync(recursive: true);
      selectDirectory(rootDirectory!);
      _isInFolder = false;
    }
  }

  Future<void> changeMasterPassword(String curPw, String newPw) async {
    isProcessing = true;
    passwordChangeProgress = 0.0;
    notifyListeners();

    try {
      final allFiles = rootDirectory!
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.ext') || f.path.endsWith('.mde'))
          .toList();

      for (int i = 0; i < allFiles.length; i++) {
        final filePath = allFiles[i].path;

        final content = await AegisFileManager.readEncryptedFile(
          filePath,
          curPw,
        );

        await AegisFileManager.saveEncryptedFile(filePath, content, newPw);

        // 進捗を更新
        passwordChangeProgress = (i + 1) / allFiles.length;
        notifyListeners();
      }

      final encryptedFlag = await AegisSecurityService.encrypt("LOGIN_SUCCESS");
      await File(
        p.join(rootDirectory!.path, '.aegis_config_v2'),
      ).writeAsBytes(encryptedFlag);

      await AegisSecurityService.initializeKey(newPw);
    } catch (e) {
      debugPrint("Password Change Error: $e");

      await AegisSecurityService.initializeKey(curPw);
      rethrow;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> pickAndroidFolder() async {
    if (!Platform.isAndroid) return;
    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      String? result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('android_data_path', result);
        _needsAndroidPath = false;
        await initializeApp();
      }
    } else {
      await openAppSettings();
    }
  }

  Future<void> clearClipboard(BuildContext context) async {
    await AegisSecurityService.clearClipboard();
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('msg_clipboard')),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}
