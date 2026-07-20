import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/gauss_theme.dart';
import '../data/backup_service.dart';
import '../state/gauss_controller.dart';
import '../widgets/gauss_brand.dart';

/// The vault: local copies of the progress store, kept on this device only.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  List<BackupEntry> _backups = const [];
  bool _loading = true;
  bool _busy = false;
  bool _pendingRestore = false;
  Object? _error;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    _refresh();
  }

  BackupService get _service => GaussScope.of(context).backups;

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await _service.listBackups();
      final pending = await _service.hasPendingRestore();
      if (!mounted) return;
      setState(() {
        _backups = entries;
        _pendingRestore = pending;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success)),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmRestore(BackupEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore this copy?'),
        content: Text(
          'Gauss will replace your current progress with the copy from '
          '${_describe(entry.savedAt)} the next time it opens. Your current '
          'progress is copied aside first, so nothing is lost either way.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep current'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stage restore'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _run(
        () => _service.stageRestore(entry),
        'Staged. Close and reopen Gauss to finish the restore.',
      );
    }
  }

  static String _describe(DateTime at) =>
      '${at.year}/${at.month.toString().padLeft(2, '0')}/'
      '${at.day.toString().padLeft(2, '0')} '
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';

  static String _size(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(0)} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/insights'),
        icon: const Icon(Icons.close_rounded),
        tooltip: 'Leave the vault',
      ),
      title: const Row(
        children: [
          GaussWordmark(width: 92),
          SizedBox(width: 12),
          Text(
            'VAULT',
            style: TextStyle(
              color: GaussColors.brassLight,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    ),
    body: SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                const Text(
                  'Copies of your progress stay on this device, in the app\'s '
                  'own folder. Nothing is uploaded and nothing is shared.',
                  style: TextStyle(
                    color: GaussColors.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                if (_pendingRestore) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: GaussColors.warning.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: GaussColors.warning.withValues(alpha: .4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'A restore is waiting',
                          style: TextStyle(
                            color: GaussColors.warning,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'It will be applied the next time Gauss opens.',
                          style: TextStyle(
                            color: GaussColors.muted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                  _service.cancelPendingRestore,
                                  'Restore cancelled.',
                                ),
                          child: const Text('Cancel the restore'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(
                          () async => _service.createBackup(),
                          'Progress copied to the vault.',
                        ),
                  icon: const Icon(Icons.save_alt_rounded),
                  label: const Text('Back up now'),
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Text(
                    'The vault could not be read: $_error',
                    style: const TextStyle(color: GaussColors.error),
                  )
                else if (_backups.isEmpty)
                  const Text(
                    'No copies yet.',
                    style: TextStyle(color: GaussColors.fog),
                  )
                else
                  for (final entry in _backups)
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.inventory_2_outlined,
                          color: GaussColors.brassLight,
                        ),
                        title: Text(_describe(entry.savedAt)),
                        subtitle: Text(
                          '${_size(entry.sizeBytes)} · ${entry.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: TextButton(
                          onPressed: _busy
                              ? null
                              : () => _confirmRestore(entry),
                          child: const Text('Restore'),
                        ),
                      ),
                    ),
              ],
            ),
    ),
  );
}
