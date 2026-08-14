import 'dart:async';

import 'package:flutter/material.dart';

import '../app/gauss_app.dart';
import '../app/gauss_theme.dart';
import 'gauss_account_session.dart';
import 'gauss_auth_controller.dart';
import 'gauss_auth_screen.dart';

class GaussAuthApp extends StatefulWidget {
  const GaussAuthApp({required this.auth, required this.appBuild, super.key});

  final GaussAuthController auth;
  final int appBuild;

  @override
  State<GaussAuthApp> createState() => _GaussAuthAppState();
}

class _GaussAuthAppState extends State<GaussAuthApp> {
  GaussAccountSession? _session;
  String? _openingUserId;
  Object? _openError;
  Future<void> _closeFuture = Future<void>.value();
  bool _closingSession = false;
  String _openingMessage = 'Opening your private orbit…';

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_handleAuth);
    unawaited(widget.auth.initialize());
    _handleAuth();
  }

  @override
  void didUpdateWidget(covariant GaussAuthApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auth == widget.auth) return;
    oldWidget.auth.removeListener(_handleAuth);
    widget.auth.addListener(_handleAuth);
    _handleAuth();
  }

  void _handleAuth() {
    if (!mounted) return;
    final userId = widget.auth.user?.id;
    if (userId == null) {
      _openingUserId = null;
      _openError = null;
      final previous = _session;
      _session = null;
      if (previous != null) {
        _closingSession = true;
        _closeFuture = previous.dispose();
        unawaited(_finishClosing(previous));
      }
      setState(() {});
      return;
    }
    if (_session?.userId == userId || _openingUserId == userId) {
      setState(() {});
      return;
    }
    _openingUserId = userId;
    _openError = null;
    _openingMessage = 'Opening your private orbit…';
    setState(() {});
    unawaited(_openSession(userId));
  }

  Future<void> _openSession(String userId) async {
    await _closeFuture;
    if (!mounted || widget.auth.user?.id != userId) return;
    final previous = _session;
    _session = null;
    if (previous != null) await previous.dispose();
    try {
      final next = await GaussAccountSession.open(
        userId,
        contentClient: widget.auth.client,
        appBuild: widget.appBuild,
        onOpeningPhase: (message) {
          if (!mounted || widget.auth.user?.id != userId) return;
          _openingMessage = message;
          setState(() {});
        },
      );
      if (!mounted || widget.auth.user?.id != userId) {
        await next.dispose();
        return;
      }
      _session = next;
      _openingUserId = null;
      _openError = null;
      setState(() {});
    } catch (error) {
      if (!mounted || widget.auth.user?.id != userId) return;
      _openingUserId = null;
      _openError = error;
      setState(() {});
    }
  }

  Future<void> _finishClosing(GaussAccountSession closing) async {
    await _closeFuture;
    if (!mounted || _session == closing) return;
    _closingSession = false;
    setState(() {});
  }

  @override
  void dispose() {
    widget.auth.removeListener(_handleAuth);
    final session = _session;
    if (session != null) unawaited(session.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.auth,
    builder: (context, _) {
      final userId = widget.auth.user?.id;
      if (userId == null) {
        if (_closingSession) return const _AccountOpeningApp(closing: true);
        return MaterialApp(
          title: 'Gauss',
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          supportedLocales: const [Locale('en')],
          theme: buildGaussTheme(),
          home: GaussAuthScreen(controller: widget.auth),
        );
      }
      if (_openError != null) {
        return MaterialApp(
          title: 'Gauss',
          debugShowCheckedModeBanner: false,
          theme: buildGaussTheme(),
          home: _AccountOpenFailure(
            onRetry: () => _openSession(userId),
            onSignOut: widget.auth.signOut,
          ),
        );
      }
      final session = _session;
      if (session == null) {
        return _AccountOpeningApp(message: _openingMessage);
      }
      return GaussApp(
        key: ValueKey('gauss-account-${session.storageKey}'),
        controller: session.controller,
        accountEmail: widget.auth.user?.email,
        onSignOut: widget.auth.signOut,
      );
    },
  );
}

class _AccountOpeningApp extends StatelessWidget {
  const _AccountOpeningApp({
    this.closing = false,
    this.message = 'Opening your private orbit…',
  });

  final bool closing;
  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Gauss',
    debugShowCheckedModeBanner: false,
    theme: buildGaussTheme(),
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 18),
            Text(closing ? 'Securing the previous orbit…' : message),
          ],
        ),
      ),
    ),
  );
}

class _AccountOpenFailure extends StatelessWidget {
  const _AccountOpenFailure({required this.onRetry, required this.onSignOut});

  final VoidCallback onRetry;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_clock_outlined,
                  color: GaussColors.warning,
                  size: 54,
                ),
                const SizedBox(height: 18),
                Text(
                  'Your private orbit did not open',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                const Text(
                  'No progress was changed. Retry the local store, or sign out safely.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
                TextButton(onPressed: onSignOut, child: const Text('Sign out')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
