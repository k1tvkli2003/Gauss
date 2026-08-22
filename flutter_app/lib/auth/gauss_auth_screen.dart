import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/gauss_design_system.dart';
import '../app/gauss_theme.dart';
import '../widgets/gauss_brand.dart';
import 'gauss_auth_controller.dart';

class GaussAuthScreen extends StatefulWidget {
  const GaussAuthScreen({required this.controller, super.key});

  final GaussAuthController controller;

  @override
  State<GaussAuthScreen> createState() => _GaussAuthScreenState();
}

class _GaussAuthScreenState extends State<GaussAuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await widget.controller.submit(
      email: _email.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/visual/map/orrery_atmosphere_portrait.png',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          cacheWidth: 1600,
          filterQuality: FilterQuality.medium,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x7203090B), Color(0xF703090B)],
              stops: [.05, .82],
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final window = GaussWindowClass.fromWidth(constraints.maxWidth);
              final landscape = constraints.maxWidth > constraints.maxHeight;
              final tabletLandscape = !window.isCompact && landscape;
              final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
              final content = _AuthInstrument(
                controller: widget.controller,
                email: _email,
                password: _password,
                emailFocus: _emailFocus,
                passwordFocus: _passwordFocus,
                obscurePassword: _obscurePassword,
                onTogglePassword: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onSubmit: _submit,
                compact: window.isCompact,
              );

              if (tabletLandscape) {
                return Padding(
                  key: const ValueKey('auth-tablet-landscape'),
                  padding: const EdgeInsets.all(28),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: _ScrollableAuthPane(
                          child: _AuthIdentityStage(
                            showDetail: !keyboardOpen,
                            horizontal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        flex: 5,
                        child: _ScrollableAuthPane(
                          bottomPadding: MediaQuery.viewInsetsOf(
                            context,
                          ).bottom,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: content,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final maxWidth = window.isCompact ? 480.0 : 620.0;
              return SingleChildScrollView(
                key: ValueKey(
                  window.isCompact
                      ? 'auth-phone-portrait'
                      : 'auth-tablet-portrait',
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  window.isCompact ? 18 : 32,
                  window.isCompact ? 20 : 32,
                  window.isCompact ? 18 : 32,
                  28 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      children: [
                        if (!keyboardOpen)
                          _AuthIdentityStage(
                            showDetail: !window.isCompact,
                            horizontal: false,
                          ),
                        if (!keyboardOpen)
                          SizedBox(height: window.isCompact ? 20 : 28),
                        content,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _ScrollableAuthPane extends StatelessWidget {
  const _ScrollableAuthPane({required this.child, this.bottomPadding = 0});

  final Widget child;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(child: child),
      ),
    ),
  );
}

class _AuthIdentityStage extends StatelessWidget {
  const _AuthIdentityStage({
    required this.showDetail,
    required this.horizontal,
  });

  final bool showDetail;
  final bool horizontal;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Gauss learning observatory',
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TheoremStarMark(
              key: const ValueKey('auth-theorem-mark'),
              size: horizontal ? 142 : 104,
              semanticLabel: 'Gauss theorem star',
            ),
            SizedBox(height: horizontal ? 28 : 16),
            GaussWordmark(width: horizontal ? 208 : 174),
            if (showDetail) ...[
              const SizedBox(height: 20),
              const Text(
                'CHART YOUR PRIVATE UNIVERSE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GaussColors.brassLight,
                  fontSize: GaussTypeScale.insignia,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'One account keeps your mathematics, physics, streaks, and reflections in their own orbit.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GaussColors.fog,
                  fontSize: GaussTypeScale.body,
                  height: 1.55,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _AuthInstrument extends StatelessWidget {
  const _AuthInstrument({
    required this.controller,
    required this.email,
    required this.password,
    required this.emailFocus,
    required this.passwordFocus,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.compact,
  });

  final GaussAuthController controller;
  final TextEditingController email;
  final TextEditingController password;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final bool compact;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final creating = controller.mode == GaussAuthMode.createAccount;
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: GaussColors.deepInk.withValues(alpha: .9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: GaussColors.brass.withValues(alpha: .48),
              ),
              boxShadow: const [
                BoxShadow(color: Color(0xB0000000), blurRadius: 34),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(compact ? 18 : 26),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'PRIVATE ORBIT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: GaussColors.brassLight,
                        fontSize: GaussTypeScale.insignia,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AuthModeSelector(
                      mode: controller.mode,
                      enabled: !controller.busy,
                      onChanged: controller.setMode,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      key: const ValueKey('auth-email-field'),
                      controller: email,
                      focusNode: emailFocus,
                      enabled: !controller.busy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      enableSuggestions: false,
                      onSubmitted: (_) => passwordFocus.requestFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      key: const ValueKey('auth-password-field'),
                      controller: password,
                      focusNode: passwordFocus,
                      enabled: !controller.busy,
                      obscureText: obscurePassword,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: creating
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      autocorrect: false,
                      enableSuggestions: false,
                      onSubmitted: (_) => onSubmit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        helperText: creating ? 'At least 10 characters' : null,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          key: const ValueKey('auth-password-visibility'),
                          tooltip: obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: controller.busy ? null : onTogglePassword,
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    if (controller.message != null) ...[
                      const SizedBox(height: 14),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          controller.message!,
                          key: const ValueKey('auth-message'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: GaussColors.warning,
                            fontSize: GaussTypeScale.metadata,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _OrbitSubmitAction(
                      creating: creating,
                      busy: controller.busy,
                      onPressed: controller.busy ? null : onSubmit,
                    ),
                    if (!creating) ...[
                      const SizedBox(height: 4),
                      TextButton(
                        key: const ValueKey('auth-forgot-password'),
                        onPressed: controller.busy
                            ? null
                            : () => controller.resendRecovery(email.text),
                        child: const Text('Forgot password?'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _AuthAssuranceRow(
                      icon: creating
                          ? Icons.verified_user_outlined
                          : Icons.lock_person_outlined,
                      text: creating
                          ? 'No email verification'
                          : 'Private progress. Synced securely.',
                    ),
                    const SizedBox(height: 8),
                    const _AuthAssuranceRow(
                      icon: Icons.cloud_done_outlined,
                      text: 'Works offline after sign in',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _AuthModeSelector extends StatelessWidget {
  const _AuthModeSelector({
    required this.mode,
    required this.enabled,
    required this.onChanged,
  });

  final GaussAuthMode mode;
  final bool enabled;
  final ValueChanged<GaussAuthMode> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stack =
          constraints.maxWidth < 330 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final choices = [
        _AuthModeChoice(
          mode: GaussAuthMode.signIn,
          label: 'Sign in',
          selected: mode == GaussAuthMode.signIn,
          enabled: enabled,
          onChanged: onChanged,
        ),
        _AuthModeChoice(
          mode: GaussAuthMode.createAccount,
          label: 'Create account',
          selected: mode == GaussAuthMode.createAccount,
          enabled: enabled,
          onChanged: onChanged,
        ),
      ];
      return Semantics(
        key: const ValueKey('auth-mode-selector'),
        container: true,
        label: 'Authentication mode',
        child: stack
            ? Column(
                key: const ValueKey('auth-mode-stacked'),
                children: [
                  choices.first,
                  const SizedBox(height: 8),
                  choices.last,
                ],
              )
            : Row(
                key: const ValueKey('auth-mode-inline'),
                children: [
                  Expanded(child: choices.first),
                  const SizedBox(width: 8),
                  Expanded(child: choices.last),
                ],
              ),
      );
    },
  );
}

class _AuthModeChoice extends StatelessWidget {
  const _AuthModeChoice({
    required this.mode,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final GaussAuthMode mode;
  final String label;
  final bool selected;
  final bool enabled;
  final ValueChanged<GaussAuthMode> onChanged;

  @override
  Widget build(BuildContext context) => Material(
    color: selected
        ? GaussColors.brass.withValues(alpha: .17)
        : GaussColors.abyss.withValues(alpha: .48),
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      key: ValueKey('auth-mode-${mode.name}'),
      onTap: enabled ? () => onChanged(mode) : null,
      borderRadius: BorderRadius.circular(15),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? GaussColors.brassLight : GaussColors.fog,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _OrbitSubmitAction extends StatelessWidget {
  const _OrbitSubmitAction({
    required this.creating,
    required this.busy,
    required this.onPressed,
  });

  final bool creating;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: creating ? 'Create my orbit' : 'Enter Orbit',
    child: FilledButton(
      key: const ValueKey('auth-submit-action'),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      child: AnimatedSwitcher(
        duration: GaussMotion.resolve(context, GaussMotion.micro),
        child: busy
            ? const SizedBox.square(
                key: ValueKey('auth-submit-progress'),
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Row(
                key: ValueKey(creating),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const TheoremStarMark(size: 30, darkInk: true),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      creating ? 'Create my orbit' : 'Enter Orbit',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

class _AuthAssuranceRow extends StatelessWidget {
  const _AuthAssuranceRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, color: GaussColors.signalBright, size: 20),
      const SizedBox(width: 9),
      Flexible(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: GaussColors.fog,
            fontSize: GaussTypeScale.caption,
            height: 1.4,
          ),
        ),
      ),
    ],
  );
}
