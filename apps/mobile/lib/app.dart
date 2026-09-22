import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/storage/repository.dart';
import 'core/sync/worker.dart';
import 'core/storage/models.dart';
import 'core/theme/theme.dart';
import 'features/projects/screens.dart';

final repositoryProvider = Provider<KodoRepository>(
  (ref) => throw UnimplementedError('override at bootstrap'),
);
final syncProvider = Provider<SyncWorker?>((ref) => null);
final deletionProvider = Provider<DeletionController?>((ref) => null);
final projectsProvider = StreamProvider<List<ProjectView>>(
  (ref) => ref.watch(repositoryProvider).watchProjects(),
);

class KodoApp extends ConsumerStatefulWidget {
  const KodoApp({super.key});
  @override
  ConsumerState<KodoApp> createState() => _KodoAppState();
}

class _KodoAppState extends ConsumerState<KodoApp> with WidgetsBindingObserver {
  Timer? _timer;
  String? _date;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
  }

  void _refresh() {
    final r = ref.read(repositoryProvider);
    if (_date != r.today) {
      _date = r.today;
      ref.invalidate(projectsProvider);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(syncProvider)?.setForeground(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed) {
      _refresh();
      unawaited(ref.read(deletionProvider)?.recover());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Kodo · 行一',
    theme: kodoTheme(),
    locale: const Locale('zh', 'CN'),
    supportedLocales: const [Locale('zh', 'CN')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: const HomeScreen(),
  );
}
