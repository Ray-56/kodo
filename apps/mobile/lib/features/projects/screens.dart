import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../app.dart';
import '../../core/storage/models.dart';
import '../../core/storage/repository.dart';
import '../../core/theme/tokens.dart';

Widget glyph(String name, {double size = 24}) => SvgPicture.asset(
  'assets/icons/$name.svg',
  width: size,
  height: size,
  colorFilter: const ColorFilter.mode(KodoTokens.primary, BlendMode.srcIn),
);
void openPage(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
void errorMessage(BuildContext context, Object error) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is DomainError ? error.message : '本机操作失败，原数据已保留。请重试或导出数据。',
        ),
      ),
    );
Future<bool> confirm(
  BuildContext context,
  String title,
  String body, {
  String action = '确认',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
void undoMessage(
  BuildContext context,
  KodoRepository repo,
  String id,
  int amount,
  String unit,
) {
  HapticFeedback.lightImpact();
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..removeCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text('已记录 ${number(amount)} $unit'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () async {
            try {
              await repo.voidEntry(id);
            } catch (e) {
              if (context.mounted) errorMessage(context, e);
            }
          },
        ),
      ),
    );
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        tab == 0 ? 'Kodo' : '统计',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      actions: [
        if (tab == 0)
          IconButton(
            key: const Key('create-project'),
            tooltip: '创建项目',
            onPressed: () => openPage(context, const ProjectForm()),
            icon: glyph('plus'),
          ),
        IconButton(
          tooltip: '设置与更多',
          onPressed: () => openPage(context, const SettingsScreen()),
          icon: glyph('more'),
        ),
      ],
    ),
    body: IndexedStack(
      index: tab,
      children: const [ProjectList(), StatsScreen()],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: (v) => setState(() => tab = v),
      destinations: [
        NavigationDestination(icon: glyph('projects'), label: '项目'),
        NavigationDestination(icon: glyph('stats'), label: '统计'),
      ],
    ),
  );
}

class ProjectList extends ConsumerWidget {
  const ProjectList({super.key, this.archived = false});
  final bool archived;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(projectsProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('数据库读取失败，文件已保留。请重试或导出。'),
          ),
        ),
        data: (all) {
          final projects = all.where((p) => p.archived == archived).toList();
          if (projects.isEmpty) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 96, 28, 24),
                child: Center(
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'assets/brand/logo_mark.svg',
                        width: 72,
                        height: 72,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        archived ? '暂无归档项目' : '从一次行动开始',
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        archived ? '归档后，历史仍会保留。' : '做了多少，就记多少。\n先创建一个属于你的项目。',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      if (!archived)
                        FilledButton(
                          onPressed: () =>
                              openPage(context, const ProjectForm()),
                          child: const Text('创建第一个项目'),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            key: PageStorageKey(archived ? 'archived' : 'projects'),
            padding: const EdgeInsets.all(20),
            itemCount: projects.length + 1,
            separatorBuilder: (_, i) => const SizedBox(height: 12),
            itemBuilder: (c, i) => i == 0
                ? Text(
                    archived ? '历史仍计入统计' : '让每一次行动，都算数',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : ProjectCard(projects[i - 1]),
          );
        },
      );
}

class ProjectCard extends ConsumerStatefulWidget {
  const ProjectCard(this.project, {super.key});
  final ProjectView project;
  @override
  ConsumerState<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends ConsumerState<ProjectCard> {
  bool saving = false;
  Future<void> add() async {
    if (saving) return;
    setState(() => saving = true);
    final p = widget.project;
    final r = ref.read(repositoryProvider);
    try {
      final id = await r.addEntry(p.id, p.quick);
      if (mounted) undoMessage(context, r, id, p.quick, p.unit);
    } catch (e) {
      if (mounted) errorMessage(context, e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              key: Key('project-${p.id}'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => openPage(context, DetailScreen(p.id)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: KodoTokens.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: glyph(p.icon),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        p.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    glyph('chevron_right'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '今日 ${number(p.today)} ${p.unit}',
                  key: Key('today-${p.id}'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!p.archived)
                  FilledButton(
                    key: Key('quick-${p.id}'),
                    onPressed: saving ? null : add,
                    child: Text('+${number(p.quick)}'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '累计 ${number(p.total)} ${p.unit}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectForm extends ConsumerStatefulWidget {
  const ProjectForm({super.key, this.project});
  final ProjectView? project;
  @override
  ConsumerState<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends ConsumerState<ProjectForm> {
  final form = GlobalKey<FormState>();
  late TextEditingController name, unit, quick;
  late String icon;
  bool saving = false, leaving = false;
  @override
  void initState() {
    super.initState();
    final p = widget.project;
    name = TextEditingController(text: p?.name ?? '');
    unit = TextEditingController(text: p?.unit ?? '次');
    quick = TextEditingController(text: '${p?.quick ?? 1}');
    icon = p?.icon ?? 'check';
    for (final c in [name, unit, quick]) {
      c.addListener(_changed);
    }
  }

  void _changed() => setState(() {});
  bool get dirty =>
      name.text != (widget.project?.name ?? '') ||
      unit.text != (widget.project?.unit ?? '次') ||
      quick.text != '${widget.project?.quick ?? 1}' ||
      icon != (widget.project?.icon ?? 'check');
  @override
  void dispose() {
    name.dispose();
    unit.dispose();
    quick.dispose();
    super.dispose();
  }

  Future<void> back() async {
    if (saving) return;
    if (!dirty || await confirm(context, '放弃修改？', '未保存的修改将丢失。', action: '放弃')) {
      if (mounted) {
        setState(() => leaving = true);
        Navigator.pop(context);
      }
    }
  }

  String? validate(String? v, int max, String field) {
    try {
      validText(v ?? '', max, field);
      return null;
    } catch (e) {
      return '$e';
    }
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await ref
          .read(repositoryProvider)
          .putProject(
            id: widget.project?.id,
            name: name.text,
            unit: unit.text,
            icon: icon,
            quick: parseAmount(quick.text, 9999),
            archived: widget.project?.archived ?? false,
          );
      if (mounted) {
        setState(() => leaving = true);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) errorMessage(context, e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: leaving || !dirty,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) back();
    },
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '取消',
          onPressed: back,
          icon: glyph('close'),
        ),
        title: Text(widget.project == null ? '新建项目' : '编辑项目'),
      ),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('选择图标'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                icons.length,
                (i) => Semantics(
                  selected: icon == icons[i],
                  child: IconButton(
                    tooltip: iconLabels[i],
                    onPressed: () => setState(() => icon = icons[i]),
                    style: IconButton.styleFrom(
                      backgroundColor: icon == icons[i]
                          ? KodoTokens.primarySoft
                          : Colors.white,
                      side: BorderSide(
                        color: icon == icons[i]
                            ? KodoTokens.primary
                            : KodoTokens.border,
                      ),
                    ),
                    icon: glyph(icons[i]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('project-name'),
              controller: name,
              decoration: const InputDecoration(
                labelText: '项目名称',
                hintText: '例如：俯卧撑',
              ),
              validator: (v) => validate(v, 40, '名称'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('project-unit'),
              controller: unit,
              enabled: !(widget.project?.unitLocked ?? false),
              decoration: const InputDecoration(
                labelText: '单位',
                hintText: '例如：个、页、分钟',
              ),
              validator: (v) => validate(v, 8, '单位'),
            ),
            if (widget.project?.unitLocked ?? false)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('已有记录，单位不可更改；请新建项目'),
              ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('project-quick'),
              controller: quick,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '快捷记录数量'),
              validator: (v) {
                try {
                  parseAmount(v ?? '', 9999);
                  return null;
                } catch (e) {
                  return '$e';
                }
              },
            ),
            const SizedBox(height: 12),
            const Text('首页点一次，即记录这个数量。'),
            const SizedBox(height: 32),
            FilledButton(
              key: const Key('save-project'),
              onPressed: saving || name.text.trim().isEmpty ? null : save,
              child: Text(saving ? '正在保存…' : '保存项目'),
            ),
          ],
        ),
      ),
    ),
  );
}

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen(this.id, {super.key});
  final String id;
  @override
  ConsumerState<DetailScreen> createState() => _DetailState();
}

class _DetailState extends ConsumerState<DetailScreen> {
  final amount = TextEditingController();
  bool saving = false;
  bool initialized = false;
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  Future<void> record(ProjectView p) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final n = parseAmount(amount.text);
      final r = ref.read(repositoryProvider);
      final id = await r.addEntry(p.id, n);
      if (mounted) undoMessage(context, r, id, n, p.unit);
    } catch (e) {
      if (mounted) errorMessage(context, e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(projectsProvider).asData?.value;
    final p = all?.where((p) => p.id == widget.id).firstOrNull;
    if (p == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!initialized) {
      amount.text = '${p.quick}';
      initialized = true;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('项目详情'),
        actions: [
          PopupMenuButton<String>(
            tooltip: '项目操作',
            onSelected: (v) async {
              if (v == 'edit') {
                openPage(context, ProjectForm(project: p));
              } else if (await confirm(
                context,
                p.archived ? '恢复项目？' : '归档项目？',
                p.archived ? '恢复后可以继续记录。' : '归档后不能新记录，历史会保留。',
              )) {
                try {
                  await ref.read(repositoryProvider).archive(p, !p.archived);
                } catch (e) {
                  if (context.mounted) errorMessage(context, e);
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('编辑项目')),
              PopupMenuItem(
                value: 'archive',
                child: Text(p.archived ? '恢复项目' : '归档项目'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: KodoTokens.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: glyph(p.icon, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  p.name,
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text('今日'),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 140),
                    child: Text(
                      '${number(p.today)} ${p.unit}',
                      key: ValueKey(p.today),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Text(
                  '累计 ${number(p.total)} ${p.unit}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (p.archived) ...[
            const Text('项目已归档，历史只读；仍可删除误记。'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                try {
                  await ref.read(repositoryProvider).archive(p, false);
                } catch (e) {
                  if (context.mounted) errorMessage(context, e);
                }
              },
              child: const Text('恢复项目'),
            ),
          ] else ...[
            const Text('本次数量'),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  tooltip: '减少本次草稿数量',
                  onPressed: () {
                    final n = int.tryParse(amount.text) ?? 1;
                    setState(() => amount.text = '${math.max(1, n - 1)}');
                  },
                  icon: glyph('minus'),
                ),
                Expanded(
                  child: TextField(
                    key: const Key('entry-amount'),
                    controller: amount,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '数量'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                IconButton(
                  tooltip: '增加本次草稿数量',
                  onPressed: () {
                    final n = int.tryParse(amount.text) ?? 1;
                    setState(() => amount.text = '${math.min(999999, n + 1)}');
                  },
                  icon: glyph('plus'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final n in [1, 5, 10, 20])
                  OutlinedButton(
                    onPressed: () => setState(() => amount.text = '$n'),
                    child: Text('$n'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('record-entry'),
              onPressed: saving ? null : () => record(p),
              child: Text(saving ? '正在保存…' : '记录 ${amount.text} ${p.unit}'),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Text(
                  '最近记录',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => openPage(context, HistoryScreen(p.id, p.unit)),
                child: const Text('看全部'),
              ),
            ],
          ),
          FutureBuilder<List<Json>>(
            future: ref.read(repositoryProvider).history(p.id, limit: 5),
            builder: (c, s) => s.hasError
                ? const Text('读取记录失败')
                : Column(
                    children: [
                      for (final e in s.data ?? <Json>[])
                        RecordRow(e, p.unit, onDeleted: () => setState(() {})),
                      if (s.data?.isEmpty ?? false)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('还没有记录'),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class RecordRow extends ConsumerWidget {
  const RecordRow(this.entry, this.unit, {super.key, required this.onDeleted});
  final Json entry;
  final String unit;
  final VoidCallback onDeleted;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = DateTime.fromMillisecondsSinceEpoch(
      entry['occurred_at_utc_ms'] as int,
      isUtc: true,
    ).add(Duration(minutes: entry['utc_offset_minutes'] as int));
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('+${number(entry['amount'] as int)} $unit'),
      subtitle: Text('${entry['local_date']} ${DateFormat('HH:mm').format(t)}'),
      trailing: IconButton(
        tooltip: '删除这条记录',
        icon: glyph('trash'),
        onPressed: () async {
          if (await confirm(
            context,
            '删除这条记录？',
            '将删除这次 ${entry['amount']} $unit，无法恢复。',
            action: '删除',
          )) {
            try {
              await ref
                  .read(repositoryProvider)
                  .voidEntry(entry['id'] as String);
              onDeleted();
            } catch (e) {
              if (context.mounted) errorMessage(context, e);
            }
          }
        },
      ),
    );
  }
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen(this.id, this.unit, {super.key});
  final String id, unit;
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryState();
}

class _HistoryState extends ConsumerState<HistoryScreen> {
  List<Json> entries = [];
  bool loading = false, more = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool reset = false}) async {
    if (loading) return;
    setState(() => loading = true);
    try {
      final page = await ref
          .read(repositoryProvider)
          .history(
            widget.id,
            after: reset || entries.isEmpty ? null : entries.last,
          );
      if (mounted) {
        setState(() {
          if (reset) entries = [];
          entries.addAll(page);
          more = page.length == 50;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = '读取历史失败，请重试');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('全部记录')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final e in entries)
          RecordRow(e, widget.unit, onDeleted: () => load(reset: true)),
        if (error != null) Text(error!),
        if (entries.isEmpty && !loading) const Text('暂无有效记录'),
        if (more || error != null)
          TextButton(
            onPressed: loading ? null : () => load(),
            child: Text(loading ? '正在读取…' : '加载更多'),
          ),
      ],
    ),
  );
}

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});
  @override
  ConsumerState<StatsScreen> createState() => _StatsState();
}

class _StatsState extends ConsumerState<StatsScreen> {
  int days = 7;
  String? projectId;
  @override
  Widget build(BuildContext context) {
    final all = ref.watch(projectsProvider).asData?.value ?? [];
    final selected = all.where((p) => p.id == projectId).firstOrNull;
    return ListView(
      key: const PageStorageKey('stats'),
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 12,
          children: [
            for (final d in [7, 30])
              ChoiceChip(
                label: Text('最近 $d 天'),
                selected: days == d,
                onSelected: (_) => setState(() => days = d),
              ),
          ],
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          key: ValueKey(selected?.id),
          initialValue: selected?.id ?? '',
          isExpanded: true,
          decoration: const InputDecoration(labelText: '统计范围'),
          items: [
            const DropdownMenuItem(value: '', child: Text('全部项目')),
            for (final p in all)
              DropdownMenuItem(
                value: p.id,
                child: Text(
                  '${p.name}${p.archived ? '（已归档）' : ''}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (v) => setState(() => projectId = v == '' ? null : v),
        ),
        const SizedBox(height: 24),
        FutureBuilder<StatsData>(
          future: ref
              .read(repositoryProvider)
              .stats(days, projectId: selected?.id),
          builder: (c, s) {
            if (s.hasError) return const Text('统计读取失败，原记录已保留');
            if (!s.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final d = s.data!;
            final unit = selected?.unit ?? '次记录';
            final max = d.values.fold<int>(1, math.max);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected?.name ?? '每一次行动，都算数',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  '${number(d.total)} $unit',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text('${d.projectCount} 个参与项目 · ${d.activeDays} 个活跃日期'),
                const SizedBox(height: 28),
                ExcludeSemantics(
                  child: SizedBox(
                    height: 160,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < d.values.length; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Container(
                                height: math.max(2, 140 * d.values[i] / max),
                                decoration: BoxDecoration(
                                  color: KodoTokens.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(d.dates.first.substring(5)),
                    Text(d.dates.last.substring(5)),
                  ],
                ),
                if (d.total == 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('这段时间还没有记录。从下一次行动开始。'),
                  ),
                const SizedBox(height: 20),
                ExpansionTile(
                  title: const Text('逐日期数据'),
                  children: [
                    for (var i = 0; i < d.dates.length; i++)
                      ListTile(
                        title: Text(d.dates[i]),
                        trailing: Text('${number(d.values[i])} $unit'),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('各项目累计', style: Theme.of(context).textTheme.titleLarge),
                for (final p in all)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${p.name}${p.archived ? '（已归档）' : ''}'),
                    subtitle: Text('${number(p.total)} ${p.unit}'),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  Future<void> export(BuildContext context, KodoRepository repo) async {
    if (!await confirm(
      context,
      '导出个人活动数据',
      '文件包含项目、数量、时间及删除标记，请妥善保管。本期不支持导入恢复。',
      action: '导出',
    )) {
      return;
    }
    try {
      final data = await repo.export();
      final dir = await getTemporaryDirectory();
      final name =
          'kodo-export-${DateFormat('yyyyMMdd-HHmmss').format(repo.clock.now())}.json';
      final temp = File('${dir.path}/$name.tmp');
      await temp.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
        flush: true,
      );
      final file = await temp.rename('${dir.path}/$name');
      if (context.mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            sharePositionOrigin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) errorMessage(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(syncProvider);
    final deletion = ref.watch(deletionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListenableBuilder(
        listenable: Listenable.merge([?worker, ?deletion]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('云端副本'),
                      value: worker?.enabled ?? false,
                      onChanged: worker == null || worker.deleting
                          ? null
                          : (value) async {
                              if (value &&
                                  !await confirm(
                                    context,
                                    '开启云端副本？',
                                    '将上传项目名称、单位、记录数量与时间。\n服务地址：${const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://localhost:8080')}\n这是单安装副本；本期无账号找回、换机恢复或多设备同步。关闭开关只暂停上传。',
                                    action: '同意并开启',
                                  )) {
                                return;
                              }
                              try {
                                await worker.setEnabled(value);
                              } catch (e) {
                                if (context.mounted) errorMessage(context, e);
                              }
                            },
                    ),
                    Semantics(
                      liveRegion: true,
                      child: Text(worker?.status ?? '仅本机'),
                    ),
                    if (worker?.identity.problem != null)
                      Text(worker!.identity.problem!),
                    if (worker?.errorCode != null)
                      Text('错误码：${worker!.errorCode}'),
                    if (worker != null)
                      TextButton(
                        onPressed: worker.running || worker.deleting
                            ? null
                            : () async {
                                await worker.identity.open();
                                await worker.wake(manual: true);
                              },
                        child: const Text('立即重试'),
                      ),
                    const Text(
                      '关闭副本不会删除已上传的数据。',
                      style: TextStyle(
                        fontSize: 14,
                        color: KodoTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: glyph('export'),
              title: const Text('导出数据'),
              subtitle: const Text('JSON · 包含个人活动信息'),
              onTap: () => export(context, ref.read(repositoryProvider)),
            ),
            ListTile(
              leading: glyph('archive'),
              title: const Text('归档项目'),
              onTap: () => openPage(
                context,
                Scaffold(
                  appBar: AppBar(title: const Text('归档项目')),
                  body: const ProjectList(archived: true),
                ),
              ),
            ),
            if (deletion != null) ...[
              const Divider(),
              ListTile(
                leading: glyph('trash'),
                title: const Text(
                  '删除全部数据',
                  style: TextStyle(color: KodoTokens.error),
                ),
                onTap: deletion.busy
                    ? null
                    : () async {
                        if (!await confirm(
                          context,
                          '删除全部数据？',
                          '将删除本机所有项目与记录，以及本安装已上传的云端副本。无法恢复。旧服务端备份可能保留到备份到期。',
                          action: '继续',
                        )) {
                          return;
                        }
                        if (!context.mounted ||
                            !await confirm(
                              context,
                              '最后确认删除',
                              '发送删除请求后不能取消。断网时将保留凭据，待联网继续删除。',
                              action: '删除全部数据',
                            )) {
                          return;
                        }
                        await deletion.begin();
                        ref.invalidate(projectsProvider);
                      },
              ),
              if (deletion.message != null) Text(deletion.message!),
              if (worker?.deleting ?? false) ...[
                FilledButton(
                  onPressed: deletion.busy
                      ? null
                      : () async {
                          await deletion.resume();
                          ref.invalidate(projectsProvider);
                        },
                  child: Text(deletion.busy ? '正在处理删除…' : '重试完成删除'),
                ),
                TextButton(
                  onPressed: deletion.busy
                      ? null
                      : () async {
                          try {
                            await deletion.cancelWaiting();
                          } catch (e) {
                            if (context.mounted) errorMessage(context, e);
                          }
                        },
                  child: const Text('取消尚未发送的删除'),
                ),
              ],
            ],
            const SizedBox(height: 24),
            const Text(
              'Kodo · 行一 0.1.0\n让每一次行动，都算数。\n私人试用版 · 无账号与换机恢复',
              style: TextStyle(color: KodoTokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
