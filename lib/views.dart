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
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:zxcvbn/zxcvbn.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:aegis_note/security_state.dart';

// --- 1. ライセンス表示 ---
void showAegisLicense(BuildContext context) {
  final state = Provider.of<AegisSecurityState>(context, listen: false);
  showAboutDialog(
    context: context,
    applicationName: "Aegis Note",
    applicationVersion: "1.0.2",
    applicationIcon: const Icon(Icons.shield, size: 48, color: Colors.amber),
    applicationLegalese: "Copyright 2026 Lumina Strategy G.K.",
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Aegis Note は、プライバシー保護とセキュリティを目的とした暗号化ノートです。",
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            Text(
              "Licensed under the Apache License 2.0.\nLanguage: ${state.lang.toUpperCase()}",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// --- 2. メイン作業画面 ---
class MainWorkbench extends StatefulWidget {
  const MainWorkbench({super.key});
  @override
  State<MainWorkbench> createState() => _MainWorkbenchState();
}

class _MainWorkbenchState extends State<MainWorkbench> {
  Future<bool> _confirmDiscard() async {
    final state = context.read<AegisSecurityState>();
    if (!state.isEditing) return true;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(state.t('msg_unsaved')),
        content: Text(state.t('msg_confirm_discard')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(state.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(state.t('discard')),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  void _showConfirmDeleteDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    final state = context.read<AegisSecurityState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(state.t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              onConfirm();
              Navigator.pop(ctx);
            },
            child: Text(
              state.t('delete'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AegisSecurityState>();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) return _buildDesktop(context, state);
        return _buildMobile(context, state);
      },
    );
  }

  Widget _buildDesktop(BuildContext context, AegisSecurityState state) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 260,
            color: Colors.black26,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    state.t('folders'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: state.rootNode == null
                        ? const SizedBox()
                        : FolderTreeWidget(
                            node: state.rootNode!,
                            depth: 0,
                            onBeforeSelect: _confirmDiscard,
                            onDeleteRequest: (dir) => _showConfirmDeleteDialog(
                              context,
                              state.t('delete'),
                              state.t('msg_confirm_delete'),
                              () => state.deleteFolder(dir),
                            ),
                            isMobile: false,
                          ),
                  ),
                ),
                const Divider(),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.vpn_key, size: 18),
                  title: Text(
                    state.t('pw_change'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    if (await _confirmDiscard())
                      _showPwChangeDialog(context, state);
                  },
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.exit_to_app, size: 18),
                  title: Text(
                    state.t('logout'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    if (await _confirmDiscard()) state.logout();
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.black12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.create_new_folder),
                        onPressed: () => _showInputDialog(
                          context,
                          state.t('new_folder'),
                          (v) => state.createFolder(v),
                        ),
                      ),
                      const SizedBox(width: 32),
                      IconButton(
                        icon: const Icon(Icons.drive_file_rename_outline),
                        onPressed: () => _showInputDialog(
                          context,
                          state.t('rename'),
                          (v) =>
                              state.renameFolder(state.selectedDirectory!, v),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Container(
            width: 300,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    state.t('files'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.files.length,
                    itemBuilder: (context, i) => ListTile(
                      leading: Icon(
                        state.files[i].path.endsWith('.mde')
                            ? Icons.description
                            : Icons.text_snippet,
                        size: 18,
                        color: state.files[i].path.endsWith('.mde')
                            ? Colors.blue
                            : Colors.orange,
                      ),
                      title: Text(p.basename(state.files[i].path)),
                      selected: state.selectedFile?.path == state.files[i].path,
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.white24,
                        ),
                        onPressed: () => _showConfirmDeleteDialog(
                          context,
                          state.t('delete'),
                          state.t('msg_confirm_delete'),
                          () => state.deleteFile(state.files[i]),
                        ),
                      ),
                      onTap: () async {
                        if (state.selectedFile?.path != state.files[i].path &&
                            await _confirmDiscard())
                          state.selectFile(state.files[i]);
                      },
                    ),
                  ),
                ),
                const Divider(),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.black12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.note_add),
                        onPressed: () => _showCreateFileDialog(context, state),
                      ),
                      const SizedBox(width: 32),
                      IconButton(
                        icon: const Icon(Icons.drive_file_rename_outline),
                        onPressed: state.selectedFile == null
                            ? null
                            : () => _showInputDialog(
                                context,
                                state.t('rename'),
                                (v) => state.renameFile(state.selectedFile!, v),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          const Expanded(child: NoteEditorView()),
        ],
      ),
    );
  }

  Widget _buildMobile(BuildContext context, AegisSecurityState state) {
    if (state.selectedFile != null) {
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (!didPop && await _confirmDiscard()) state.closeFile();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(p.basename(state.selectedFile!.path)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                if (await _confirmDiscard()) state.closeFile();
              },
            ),
          ),
          body: const NoteEditorView(),
        ),
      );
    } else if (state.isInFolder) {
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (!didPop) state.exitFolder();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              p.basename(state.selectedDirectory!.path).isEmpty
                  ? state.t('files')
                  : p.basename(state.selectedDirectory!.path),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => state.exitFolder(),
            ),
          ),
          body: ListView.builder(
            itemCount: state.files.length,
            itemBuilder: (context, i) => ListTile(
              leading: Icon(
                state.files[i].path.endsWith('.mde')
                    ? Icons.description
                    : Icons.text_snippet,
                color: state.files[i].path.endsWith('.mde')
                    ? Colors.blue
                    : Colors.orange,
              ),
              title: Text(p.basename(state.files[i].path)),
              onTap: () => state.selectFile(state.files[i]),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showConfirmDeleteDialog(
                  context,
                  state.t('delete'),
                  state.t('msg_confirm_delete'),
                  () => state.deleteFile(state.files[i]),
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateFileDialog(context, state),
            child: const Icon(Icons.note_add),
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Aegis Note"),
          actions: [
            IconButton(
              icon: const Icon(Icons.vpn_key),
              onPressed: () async {
                if (await _confirmDiscard())
                  _showPwChangeDialog(context, state);
              },
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => showAegisLicense(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: state.rootNode == null
              ? const SizedBox()
              : FolderTreeWidget(
                  node: state.rootNode!,
                  depth: 0,
                  onBeforeSelect: _confirmDiscard,
                  onDeleteRequest: (dir) => _showConfirmDeleteDialog(
                    context,
                    state.t('delete'),
                    state.t('msg_confirm_delete'),
                    () => state.deleteFolder(dir),
                  ),
                  isMobile: true,
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showInputDialog(
            context,
            state.t('new_folder'),
            (v) => state.createFolder(v),
          ),
          child: const Icon(Icons.create_new_folder),
        ),
      );
    }
  }

  void _showInputDialog(
    BuildContext context,
    String title,
    Function(String) onConfirm,
  ) {
    final state = Provider.of<AegisSecurityState>(context, listen: false);
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(state.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm(c.text);
              Navigator.pop(ctx);
            },
            child: Text(state.t('execute')),
          ),
        ],
      ),
    );
  }

  void _showCreateFileDialog(BuildContext context, AegisSecurityState state) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(state.t('new_file')),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
            onPressed: () {
              state.createNewFile(c.text, ".ext");
              Navigator.pop(ctx);
            },
            child: Text(state.t('text_file')),
          ),
          TextButton(
            onPressed: () {
              state.createNewFile(c.text, ".mde");
              Navigator.pop(ctx);
            },
            child: Text(state.t('md_file')),
          ),
        ],
      ),
    );
  }

  void _showPwChangeDialog(BuildContext context, AegisSecurityState state) {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    final c3 = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setInternalState) {
          return Consumer<AegisSecurityState>(
            builder: (context, st, _) => AlertDialog(
              title: Text(st.t('pw_change')),
              content: st.isProcessing
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: st.passwordChangeProgress,
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAegisPasswordField(
                          st,
                          c1,
                          st.t('current_pw'),
                          () => setInternalState(() {}),
                        ),
                        _buildAegisPasswordField(
                          st,
                          c2,
                          st.t('new_pw'),
                          () => setInternalState(() {}),
                        ),
                        _buildAegisPasswordField(
                          st,
                          c3,
                          st.t('confirm_pw'),
                          () => setInternalState(() {}),
                        ),
                      ],
                    ),
              actions: st.isProcessing
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(st.t('cancel')),
                      ),
                      ElevatedButton(
                        onPressed: (c2.text == c3.text && c2.text.length >= 3)
                            ? () async {
                                await st.changeMasterPassword(c1.text, c2.text);
                                if (context.mounted) Navigator.pop(ctx);
                              }
                            : null,
                        child: Text(st.t('execute')),
                      ),
                    ],
            ),
          );
        },
      ),
    );
  }
}

// --- 3. 共通部品：IMEリアクティブ・シールド搭載パスワード入力欄 ---
Widget _buildAegisPasswordField(
  AegisSecurityState state,
  TextEditingController controller,
  String label,
  VoidCallback onUpdate,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      readOnly: state.isImeBlocked,
      inputFormatters: [
        TextInputFormatter.withFunction((oldValue, newValue) {
          if (newValue.composing.start >= 0 ||
              newValue.text.contains(RegExp(r'[^\x20-\x7E]'))) {
            Future.microtask(() {
              state.setImeBlocked(true);
              onUpdate();
            });
            return oldValue;
          }
          return newValue;
        }),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorText: state.isImeBlocked ? state.t('err_ime') : null,
        filled: state.isImeBlocked,
        fillColor: state.isImeBlocked ? Colors.red.withOpacity(0.1) : null,
        suffixIcon: state.isImeBlocked
            ? IconButton(
                icon: const Icon(Icons.refresh, color: Colors.red),
                onPressed: () {
                  state.setImeBlocked(false);
                  onUpdate();
                },
              )
            : null,
      ),
      onChanged: (_) => onUpdate(),
    ),
  );
}

// --- 4. フォルダツリー ---
class FolderTreeWidget extends StatelessWidget {
  final FolderNode node;
  final int depth;
  final Future<bool> Function() onBeforeSelect;
  final bool isMobile;
  final Function(Directory) onDeleteRequest;
  const FolderTreeWidget({
    super.key,
    required this.node,
    required this.depth,
    required this.onBeforeSelect,
    required this.isMobile,
    required this.onDeleteRequest,
  });
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AegisSecurityState>();
    final isSel =
        p.normalize(state.selectedDirectory?.path ?? "") ==
        p.normalize(node.directory.path);
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.only(left: 12.0 * depth + 8.0, right: 8.0),
          leading: Icon(
            node.subFolders.isEmpty
                ? Icons.folder
                : (node.isExpanded ? Icons.folder_open : Icons.folder),
            size: 18,
            color: isSel ? Colors.orange : Colors.amber,
          ),
          title: Text(
            p.basename(node.directory.path).isEmpty
                ? "root"
                : p.basename(node.directory.path),
            style: const TextStyle(fontSize: 13),
          ),
          selected: isSel,
          selectedTileColor: Colors.white10,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSel && depth > 0)
                IconButton(
                  icon: const Icon(
                    Icons.delete_forever,
                    size: 18,
                    color: Colors.red,
                  ),
                  onPressed: () => onDeleteRequest(node.directory),
                ),
              if (isMobile)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.blue,
                  ),
                  onPressed: () => state.selectDirectory(node.directory),
                ),
            ],
          ),
          onTap: () async {
            if (isSel) {
              state.toggleFolderExpanded(node);
            } else {
              if (await onBeforeSelect()) {
                if (!node.isExpanded) state.toggleFolderExpanded(node);
                state.selectDirectoryOnly(node.directory);
              }
            }
          },
        ),
        if (node.isExpanded)
          ...node.subFolders
              .map(
                (sub) => FolderTreeWidget(
                  node: sub,
                  depth: depth + 1,
                  onBeforeSelect: onBeforeSelect,
                  isMobile: isMobile,
                  onDeleteRequest: onDeleteRequest,
                ),
              )
              .toList(),
      ],
    );
  }
}

// --- 5. エディタ & プレビュー ---
class NoteEditorView extends StatelessWidget {
  const NoteEditorView({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AegisSecurityState>();
    if (state.selectedFile == null) return const Center(child: Text("..."));
    final bool isMde = state.selectedFile!.path.endsWith('.mde');
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.black12,
          child: Row(
            children: [
              if (Platform.isWindows || Platform.isLinux)
                Text(
                  p.basename(state.selectedFile!.path),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_sweep, size: 20),
                onPressed: () => state.clearClipboard(context),
                tooltip: state.t('msg_clipboard'),
              ),
              Text(state.t('preview'), style: const TextStyle(fontSize: 12)),
              Switch(
                value: !state.isPreviewMode,
                onChanged: (v) => state.setPreviewMode(!v),
                activeColor: Colors.orange,
              ),
              Text(state.t('edit'), style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: state.isEditing
                    ? () => state.saveCurrentFile()
                    : null,
                icon: const Icon(Icons.save, size: 18),
                label: Text(state.t('save')),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.isPreviewMode
              ? (isMde
                    ? Markdown(
                        data: state.editorController.text,
                        selectable: true,
                      )
                    : Container(
                        alignment: Alignment.topLeft,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            state.editorController.text,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'monospace',
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: state.editorController,
                    maxLines: null,
                    expands: true,
                    onChanged: (v) {
                      if (!state.isEditing) state.setEditing(true);
                    },
                    decoration: const InputDecoration(border: InputBorder.none),
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// --- 6. セットアップ画面 ---
class SetupPage extends StatefulWidget {
  const SetupPage({super.key});
  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  final _zxc = Zxcvbn();
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AegisSecurityState>();
    int score = _p1.text.isEmpty
        ? 0
        : (_zxc.evaluate(_p1.text).score ?? 0).toInt().clamp(0, 4);
    bool isMatch = _p1.text == _p2.text && _p1.text.isNotEmpty;
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.t('setup'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _buildAegisPasswordField(
                state,
                _p1,
                state.t('new_pw'),
                () => setState(() {}),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (score + 1) / 5.0,
                color: [
                  Colors.red,
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  Colors.green,
                ][score],
              ),
              const SizedBox(height: 16),
              _buildAegisPasswordField(
                state,
                _p2,
                state.t('confirm_pw'),
                () => setState(() {}),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (isMatch && _p1.text.length >= 3)
                      ? () => state.setupMasterPassword(_p1.text)
                      : null,
                  child: Text(state.t('setup_done')),
                ),
              ),
              TextButton(
                onPressed: () => showAegisLicense(context),
                child: Text(
                  state.t('license'),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 7. ログイン画面 ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _pw = TextEditingController();
  final _zxc = Zxcvbn();
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AegisSecurityState>();
    int score = _pw.text.isEmpty
        ? 0
        : (_zxc.evaluate(_pw.text).score ?? 0).toInt().clamp(0, 4);
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "🛡️ AEGIS NOTE",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              if (state.loginErrorMessage != null)
                Text(
                  state.loginErrorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              _buildAegisPasswordField(
                state,
                _pw,
                state.t('password'),
                () => setState(() {}),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (score + 1) / 5.0,
                color: [
                  Colors.red,
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  Colors.green,
                ][score],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => state.login(_pw.text),
                      child: Text(state.t('login')),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    onPressed: () => state.clearClipboard(context),
                    tooltip: state.t('msg_clipboard'),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => showAegisLicense(context),
                child: Text(
                  state.t('license'),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AndroidFolderPickerPage extends StatelessWidget {
  const AndroidFolderPickerPage({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.read<AegisSecurityState>();
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_shared, size: 80, color: Colors.amber),
              const SizedBox(height: 24),
              Text(
                state.t('pick_folder'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(state.t('android_pick_msg'), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => state.pickAndroidFolder(),
                icon: const Icon(Icons.search),
                label: Text(state.t('execute')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
