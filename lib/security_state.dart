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

  String? loginErrorMessage;
  double passwordChangeProgress = 0.0;
  Directory? rootDirectory;
  Directory? selectedDirectory;
  File? selectedFile;
  FolderNode? rootNode;
  List<File> files = [];
  final TextEditingController editorController = TextEditingController();
  final Set<String> _expandedPaths = {};

  // --- 多言語化エンジン ---
  String _lang = 'en';
  String get lang => _lang;

  static const Map<String, Map<String, String>> _dict = {
    'en': {
      'folders': 'FOLDERS',
      'files': 'FILES',
      'login': 'Login',
      'setup': 'INITIAL SETUP',
      'password': 'Master Password',
      'confirm_pw': 'Confirm Password',
      'new_pw': 'New Password',
      'current_pw': 'Current Password',
      'start': 'Start',
      'setup_done': 'Complete Setup',
      'save': 'Save',
      'discard': 'Discard',
      'edit': 'Edit',
      'preview': 'Preview',
      'new_folder': 'New Folder',
      'new_file': 'New File',
      'rename': 'Rename',
      'delete': 'Delete',
      'logout': 'Logout',
      'pw_change': 'Change Password',
      'license': 'License',
      'msg_inactivity': 'Inactivity detected. Logging out in ',
      'msg_sec': 's',
      'msg_continue': 'Continue',
      'msg_unsaved': 'Unsaved changes',
      'msg_confirm_discard': 'Discard changes and proceed?',
      'msg_confirm_delete': 'Delete this item?',
      'text_file': 'Text',
      'md_file': 'Markdown',
      'cancel': 'Cancel',
      'execute': 'Execute',
      'err_login': 'Invalid password',
      'pick_folder': 'Select Storage Folder',
      'android_pick_msg':
          'Please select a folder to store your encrypted notes.',
    },
    'ja': {
      'folders': 'フォルダ',
      'files': 'ファイル',
      'login': 'ログイン',
      'setup': '初期セットアップ',
      'password': 'マスターパスワード',
      'confirm_pw': '確認用入力',
      'new_pw': '新しいパスワード',
      'current_pw': '現在のパスワード',
      'start': '開始する',
      'setup_done': '設定完了',
      'save': '保存',
      'discard': '破棄',
      'edit': '編集',
      'preview': '閲覧',
      'new_folder': 'フォルダ作成',
      'new_file': '新規作成',
      'rename': '名前変更',
      'delete': '削除',
      'logout': 'ログアウト',
      'pw_change': 'パスワード変更',
      'license': 'ライセンス',
      'msg_inactivity': '放置を検知しました。あと ',
      'msg_sec': ' 秒でログアウトします',
      'msg_continue': '継続',
      'msg_unsaved': '未保存の変更',
      'msg_confirm_discard': '変更を破棄してよろしいですか？',
      'msg_confirm_delete': '本当に削除しますか？',
      'text_file': 'テキスト',
      'md_file': 'マークダウン',
      'cancel': 'キャンセル',
      'execute': '実行',
      'err_login': 'パスワードが正しくありません',
      'pick_folder': '保存場所の選択',
      'android_pick_msg': 'データを保存するフォルダを選んでください。',
    },
    'fr': {
      'folders': 'DOSSIERS',
      'files': 'FICHIERS',
      'login': 'Connexion',
      'setup': 'CONFIGURATION',
      'password': 'Mot de passe maître',
      'confirm_pw': 'Confirmer le mot de passe',
      'new_pw': 'Nouveau mot de passe',
      'current_pw': 'Mot de passe actuel',
      'start': 'Démarrer',
      'setup_done': 'Terminer la configuration',
      'save': 'Enregistrer',
      'discard': 'Abandonner',
      'edit': 'Modifier',
      'preview': 'Aperçu',
      'new_folder': 'Nouveau dossier',
      'new_file': 'Nouveau fichier',
      'rename': 'Renommer',
      'delete': 'Supprimer',
      'logout': 'Déconnexion',
      'pw_change': 'Changer le mot de passe',
      'license': 'Licence',
      'msg_inactivity': 'Inactivité détectée. Déconnexion dans ',
      'msg_sec': 's',
      'msg_continue': 'Continuer',
      'msg_unsaved': 'Modifications non enregistrées',
      'msg_confirm_discard': 'Abandonner les modifications et continuer ?',
      'msg_confirm_delete': 'Supprimer cet élément ?',
      'text_file': 'Texte',
      'md_file': 'Markdown',
      'cancel': 'Annuler',
      'execute': 'Exécuter',
      'err_login': 'Mot de passe invalide',
      'pick_folder': 'Choisir le dossier de stockage',
      'android_pick_msg':
          'Veuillez choisir un dossier pour stocker vos notes chiffrées.',
    },
    'es': {
      'folders': 'CARPETAS',
      'files': 'ARCHIVOS',
      'login': 'Iniciar sesión',
      'setup': 'CONFIGURACIÓN INICIAL',
      'password': 'Contraseña maestra',
      'confirm_pw': 'Confirmar contraseña',
      'new_pw': 'Nueva contraseña',
      'current_pw': 'Contraseña actual',
      'start': 'Comenzar',
      'setup_done': 'Completar configuración',
      'save': 'Guardar',
      'discard': 'Descartar',
      'edit': 'Editar',
      'preview': 'Vista previa',
      'new_folder': 'Nueva carpeta',
      'new_file': 'Nuevo archivo',
      'rename': 'Renombrar',
      'delete': 'Eliminar',
      'logout': 'Cerrar sesión',
      'pw_change': 'Cambiar contraseña',
      'license': 'Licencia',
      'msg_inactivity': 'Inactividad détectada. Cerrando sesión en ',
      'msg_sec': 's',
      'msg_continue': 'Continuar',
      'msg_unsaved': 'Cambios no guardados',
      'msg_confirm_discard': '¿Descartar cambios y continuar?',
      'msg_confirm_delete': '¿Eliminar este elemento?',
      'text_file': 'Texto',
      'md_file': 'Markdown',
      'cancel': 'Cancelar',
      'execute': 'Ejecutar',
      'err_login': 'Contraseña incorrecta',
      'pick_folder': 'Seleccionar carpeta de almacenamiento',
      'android_pick_msg':
          'Seleccione una carpeta para guardar sus notas cifradas.',
    },
    'ru': {
      'folders': 'ПАПКИ',
      'files': 'ФАЙЛЫ',
      'login': 'Вход',
      'setup': 'НАЧАЛЬНАЯ НАСТРОЙКА',
      'password': 'Мастер-пароль',
      'confirm_pw': 'Подтвердите пароль',
      'new_pw': 'Новый пароль',
      'current_pw': 'Текущий пароль',
      'start': 'Начать',
      'setup_done': 'Завершить настройку',
      'save': 'Сохранить',
      'discard': 'Отменить',
      'edit': 'Правка',
      'preview': 'Просмотр',
      'new_folder': 'Новая папка',
      'new_file': 'Новый файл',
      'rename': 'Переименовать',
      'delete': 'Удалить',
      'logout': 'Выход',
      'pw_change': 'Сменить пароль',
      'license': 'Лицензия',
      'msg_inactivity': 'Неактивность. Выход через ',
      'msg_sec': 'сек',
      'msg_continue': 'Продолжить',
      'msg_unsaved': 'Несохраненные изменения',
      'msg_confirm_discard': 'Отменить изменения и продолжить?',
      'msg_confirm_delete': 'Удалить этот объект?',
      'text_file': 'Текст',
      'md_file': 'Markdown',
      'cancel': 'Отмена',
      'execute': 'Выполнить',
      'err_login': 'Неверный пароль',
      'pick_folder': 'Выбрать папку для хранения',
      'android_pick_msg': 'Выберите папку для хранения зашифрованных заметок.',
    },
    'zh': {
      'folders': '文件夹',
      'files': '文件',
      'login': '登录',
      'setup': '初始设置',
      'password': '主密码',
      'confirm_pw': '确认密码',
      'new_pw': '新密码',
      'current_pw': '当前密码',
      'start': '开始',
      'setup_done': '完成设置',
      'save': '保存',
      'discard': '放弃',
      'edit': '编辑',
      'preview': '预览',
      'new_folder': '新建文件夹',
      'new_file': '新建文件',
      'rename': '重命名',
      'delete': '删除',
      'logout': '登出',
      'pw_change': '修改密码',
      'license': '许可证',
      'msg_inactivity': '检测到长时间未操作。将在 ',
      'msg_sec': ' 秒后登出',
      'msg_continue': '继续操作',
      'msg_unsaved': '更改未保存',
      'msg_confirm_discard': '放弃更改并继续？',
      'msg_confirm_delete': '确认删除此项目？',
      'text_file': '文本',
      'md_file': 'Markdown',
      'cancel': '取消',
      'execute': '执行',
      'err_login': '密码错误',
      'pick_folder': '选择存储文件夹',
      'android_pick_msg': '请选择一个文件夹来存储您的加密笔记。',
    },
  };

  String t(String key) => _dict[_lang]?[key] ?? _dict['en']![key] ?? key;

  String _norm(String path) => p.normalize(path);

  // --- 初期化 (多言語 + AppImageパス対応) ---
  Future<void> initializeApp() async {
    try {
      // 言語判別
      final String locale = Platform.localeName.split('_')[0];
      _lang = _dict.containsKey(locale) ? locale : 'en';

      String dataPath = "";

      if (Platform.isWindows || Platform.isLinux) {
        final exeDir = Directory(Platform.resolvedExecutable).parent.path;
        dataPath = _norm(p.join(exeDir, 'user_data'));
      } else if (Platform.isAndroid) {
        final prefs = await SharedPreferences.getInstance();
        String? savedPath = prefs.getString('android_data_path');
        var status = await Permission.manageExternalStorage.status;
        if (savedPath == null || !status.isGranted) {
          _needsAndroidPath = true;
          notifyListeners();
          return;
        }
        dataPath = _norm(savedPath);
      }

      final dataDir = Directory(dataPath);
      if (!dataDir.existsSync()) dataDir.createSync(recursive: true);

      rootDirectory = dataDir;
      _isFirstRun = !File(
        p.join(rootDirectory!.path, '.aegis_config_v2'),
      ).existsSync();
      selectedDirectory = rootDirectory;
      _expandedPaths.add(_norm(rootDirectory!.path));
      _needsAndroidPath = false;
      refreshLists();
    } catch (e) {
      debugPrint("Init Error: $e");
      if (Platform.isAndroid) _needsAndroidPath = true;
    }
    notifyListeners();
  }

  // --- アクション ---
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

  Future<bool> login(String pw) async {
    loginErrorMessage = null;
    notifyListeners();
    try {
      await AegisSecurityService.initializeKey(pw);
      final data = await File(
        p.join(rootDirectory!.path, '.aegis_config_v2'),
      ).readAsBytes();
      if (await AegisSecurityService.decrypt(data) == "LOGIN_SUCCESS") {
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

  void logout() {
    AegisSecurityService.wipeKey();
    _isLoggedIn = false;
    isEditing = false;
    selectedFile = null;
    _expandedPaths.clear();
    _isInFolder = false;
    notifyListeners();
  }

  void refreshLists() {
    if (rootDirectory == null) return;
    rootNode = _buildTree(rootDirectory!);
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
      final all = rootDirectory!
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.ext') || f.path.endsWith('.mde'))
          .toList();
      for (int i = 0; i < all.length; i++) {
        await AegisSecurityService.initializeKey(curPw);
        final content = await AegisFileManager.readEncryptedFile(all[i].path);
        await AegisSecurityService.initializeKey(newPw);
        await AegisFileManager.saveEncryptedFile(all[i].path, content);
        passwordChangeProgress = (i + 1) / all.length;
        notifyListeners();
      }
      final flag = await AegisSecurityService.encrypt("LOGIN_SUCCESS");
      await File(
        _norm(p.join(rootDirectory!.path, '.aegis_config_v2')),
      ).writeAsBytes(flag);
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> clearClipboard(BuildContext context) async {
    await AegisSecurityService.clearClipboard();
    if (context.mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('license'))));
  }
}
