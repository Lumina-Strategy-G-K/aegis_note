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

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:aegis_note/security_state.dart';
import 'package:aegis_note/views.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/LICENSE-2.0.txt');
    yield LicenseEntryWithLineBreaks(['Aegis Note'], license);
  });
  if (Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();
    windowManager.waitUntilReadyToShow(
      const WindowOptions(title: "Aegis Note"),
      () async {
        await windowManager.show();
        await windowManager.setPreventClose(true);
      },
    );
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => AegisSecurityState(),
      child: const AegisApp(),
    ),
  );
}

class AegisApp extends StatelessWidget {
  const AegisApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true),
    home: const AuthGate(),
  );
}

// --- AuthGate ---
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isLinux) windowManager.addListener(this);
    // 起動時に初期化を実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AegisSecurityState>().initializeApp();
    });
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isLinux)
      windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    final state = context.read<AegisSecurityState>();
    if (state.isEditing) {
      final res = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("未保存"),
          content: const Text("破棄しますか？"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("キャンセル"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("終了"),
            ),
          ],
        ),
      );
      if (res == true) await windowManager.destroy();
    } else {
      await windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AegisSecurityState>();

    // 1. パスが必要（Android初回）ならフォルダ選択画面へ
    if (state.needsAndroidPath) return const AndroidFolderPickerPage();

    // 2. まだ初期化が終わっていない（rootDirectoryが空）ならローディング
    if (state.rootDirectory == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // 3. ログイン状態によって画面を分岐
    if (state.isLoggedIn)
      return const InactivityWatcher(child: MainWorkbench());
    return state.isFirstRun ? const SetupPage() : const LoginPage();
  }
}

class InactivityWatcher extends StatefulWidget {
  final Widget child;
  const InactivityWatcher({super.key, required this.child});
  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _timer;
  Timer? _countdown;
  int _secondsLeft = 60;
  bool _showWarning = false;
  void _resetTimer() {
    final state = context.read<AegisSecurityState>();
    if (!state.isLoggedIn) return;
    if (_showWarning) setState(() => _showWarning = false);
    _timer?.cancel();
    _countdown?.cancel();
    _timer = Timer(const Duration(minutes: 4), () {
      if (!state.isEditing && !state.isProcessing) _startCountdown();
    });
  }

  void _startCountdown() {
    setState(() {
      _showWarning = true;
      _secondsLeft = 60;
    });
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        t.cancel();
        context.read<AegisSecurityState>().logout();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => _resetTimer(),
    child: Stack(children: [widget.child, if (_showWarning) _buildOverlay()]),
  );
  Widget _buildOverlay() => Positioned(
    top: 0,
    left: 0,
    right: 0,
    child: Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.timer, color: Colors.black),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                "${context.read<AegisSecurityState>().t('msg_inactivity')}$_secondsLeft${context.read<AegisSecurityState>().t('msg_sec')}",
                style: const TextStyle(color: Colors.black, fontSize: 13),
              ),
            ),
            ElevatedButton(
              onPressed: _resetTimer,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: Text(context.read<AegisSecurityState>().t('msg_continue')),
            ),
          ],
        ),
      ),
    ),
  );
}
