import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/gauss_design_system.dart';
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
    if (!_service.isSupported) {
      setState(() {
        _loading = false;
        _error = null;
      });
      return;
    }
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
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
              fontSize: GaussTypeScale.insignia,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/visual/map/orrery_atmosphere_portrait.png',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          cacheWidth: 1400,
          filterQuality: FilterQuality.medium,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xB507151C), Color(0xF503090B)],
            ),
          ),
        ),
        SafeArea(
          child: !_service.isSupported
              ? const _BrowserVaultBoundary()
              : _loading
              ? const _VaultLoadingState()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView(
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
                                color: GaussColors.warning.withValues(
                                  alpha: .4,
                                ),
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
                          _VaultErrorState(
                            error: _error!,
                            onRetry: _busy ? null : _refresh,
                          )
                        else if (_backups.isEmpty)
                          const _VaultEmptyState()
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
                                  softWrap: true,
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
                ),
        ),
      ],
    ),
  );
}

class _VaultLoadingState extends StatelessWidget {
  const _VaultLoadingState();

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      container: true,
      liveRegion: true,
      label: 'Opening the local progress vault.',
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        margin: const EdgeInsets.all(GaussSpacing.space24),
        padding: const EdgeInsets.all(GaussSpacing.space24),
        decoration: _vaultStateDecoration(),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 34,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: GaussSpacing.space16),
            Text(
              'Opening your local vault…',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    ),
  );
}

class _VaultErrorState extends StatelessWidget {
  const _VaultErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: 'The local vault could not be read. Retry is available.',
    child: Container(
      padding: const EdgeInsets.all(GaussSpacing.space20),
      decoration: _vaultStateDecoration(accent: GaussColors.error),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: GaussColors.error,
            size: 34,
          ),
          const SizedBox(height: GaussSpacing.space12),
          Text(
            'The vault could not be read',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: GaussSpacing.space8),
          Text(
            '$error',
            softWrap: true,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GaussColors.muted,
              fontSize: GaussTypeScale.metadata,
              height: 1.45,
            ),
          ),
          const SizedBox(height: GaussSpacing.space16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class _VaultEmptyState extends StatelessWidget {
  const _VaultEmptyState();

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label:
        'No backup copies yet. Use Back up now to create the first local copy.',
    child: Container(
      padding: const EdgeInsets.all(GaussSpacing.space20),
      decoration: _vaultStateDecoration(),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GaussColors.brass.withValues(alpha: .1),
              border: Border.all(
                color: GaussColors.brass.withValues(alpha: .35),
              ),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: GaussColors.brassLight,
              size: 27,
            ),
          ),
          const SizedBox(height: GaussSpacing.space12),
          Text('No copies yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: GaussSpacing.space4),
          const Text(
            'Create the first local copy whenever you want a restore point.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GaussColors.muted,
              fontSize: GaussTypeScale.metadata,
              height: 1.45,
            ),
          ),
        ],
      ),
    ),
  );
}

BoxDecoration _vaultStateDecoration({Color accent = GaussColors.brass}) =>
    BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: .08),
          GaussColors.deepInk.withValues(alpha: .95),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: accent.withValues(alpha: .34)),
    );

class _BrowserVaultBoundary extends StatelessWidget {
  const _BrowserVaultBoundary();

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GaussColors.panelHigh.withValues(alpha: .94),
                GaussColors.deepInk.withValues(alpha: .97),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: GaussColors.brass.withValues(alpha: .32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .34),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GaussColors.brass.withValues(alpha: .09),
                  border: Border.all(
                    color: GaussColors.brassLight.withValues(alpha: .45),
                  ),
                ),
                child: const Icon(
                  Icons.phonelink_lock_rounded,
                  size: 34,
                  color: GaussColors.brassLight,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Browser progress stays local',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GaussColors.ivory,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Gauss already keeps this browser\'s progress on this device. '
                'The Vault copies the native SQLite store, so backup and '
                'restore controls are available in the Android app only.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GaussColors.muted,
                  fontSize: 12.5,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
