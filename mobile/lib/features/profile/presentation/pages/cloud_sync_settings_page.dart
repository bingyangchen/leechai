import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/auth/data/services/auth.dart';
import 'package:mobile/features/auth/domain/account_conflict.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/sign_in_cancelled.dart';
import 'package:mobile/features/auth/presentation/widgets/user_avatar.dart';
import 'package:mobile/features/profile/data/services/cloud_sync.dart';
import 'package:mobile/features/profile/presentation/widgets/google_link_button.dart';
import 'package:mobile/shared/theme/app_theme.dart';

class CloudSyncSettingsPage extends StatefulWidget {
  const CloudSyncSettingsPage({super.key});

  @override
  State<CloudSyncSettingsPage> createState() => _CloudSyncSettingsPageState();
}

class _CloudSyncSettingsPageState extends State<CloudSyncSettingsPage> {
  static CloudSyncService get _sync => CloudSyncService.instance;

  AuthState? _greetingUser;
  bool _wasLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _wasLoggedIn = AuthService.instance.isLoggedIn;
    AuthService.instance.currentUser.addListener(_onAuthChanged);
    _sync.status.addListener(_onSyncChanged);
    _sync.lastSyncAt.addListener(_onSyncChanged);
  }

  @override
  void dispose() {
    AuthService.instance.currentUser.removeListener(_onAuthChanged);
    _sync.status.removeListener(_onSyncChanged);
    _sync.lastSyncAt.removeListener(_onSyncChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final user = AuthService.instance.currentUser.value;
    if (!_wasLoggedIn && user != null) {
      setState(() => _greetingUser = user);
    } else {
      setState(() {});
    }
    _wasLoggedIn = user != null;
  }

  void _onSyncChanged() {
    if (mounted) setState(() {});
  }

  void _onGreetingDone() {
    if (mounted) setState(() => _greetingUser = null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = AuthService.instance.currentUser.value;

    Widget body;
    if (_greetingUser != null) {
      body = _WelcomeGreetingView(
        key: const ValueKey('greeting'),
        user: _greetingUser!,
        onDone: _onGreetingDone,
      );
    } else if (user != null) {
      body = _AuthenticatedView(key: const ValueKey('authenticated'), user: user);
    } else {
      body = const _UnauthenticatedView(key: ValueKey('unauthenticated'));
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(toolbarHeight: kToolbarHeight, title: const Text('雲端備份與同步')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: body,
      ),
    );
  }
}

class _UnauthenticatedView extends StatefulWidget {
  const _UnauthenticatedView({super.key});

  @override
  State<_UnauthenticatedView> createState() => _UnauthenticatedViewState();
}

class _UnauthenticatedViewState extends State<_UnauthenticatedView>
    with SingleTickerProviderStateMixin {
  late AnimationController _heroController;
  late Animation<double> _heroOpacity;
  late Animation<double> _heroOffsetY;

  bool _isLoading = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _heroOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic));
    _heroOffsetY = Tween<double>(
      begin: 20,
      end: 0,
    ).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic));
    _heroController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  Future<void> _onLinkGoogleTap() async {
    if (_isLoading) return;

    final results = await Connectivity().checkConnectivity();
    final hasConnection =
        results.isNotEmpty &&
        !(results.length == 1 && results.contains(ConnectivityResult.none));
    if (!hasConnection) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '無法連線，請檢查網路設定後再試。',
            style: Theme.of(context).snackBarTheme.contentTextStyle,
          ),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    try {
      await AuthService.instance.signInWithGoogle();
    } on SignInCancelledException {
      // User cancelled — no feedback needed
    } on AccountConflictException catch (conflict) {
      if (!mounted) return;
      await _showAccountConflictDialog(conflict);
    } catch (error) {
      if (!mounted) return;
      final message = error is Exception
          ? error.toString().replaceFirst('Exception: ', '')
          : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: Theme.of(context).snackBarTheme.contentTextStyle,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAccountConflictDialog(AccountConflictException conflict) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('偵測到不同帳號'),
        content: Text(
          '此設備先前連結的是另一個 Google 帳號。'
          '繼續將會把本機資料同步到 ${conflict.newEmail}，'
          '原帳號的雲端資料不會受到影響。',
        ),
        actions: [
          TextButton(
            onPressed: () {
              AuthService.instance.cancelPendingSignIn();
              Navigator.of(ctx).pop(false);
            },
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('繼續連結'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.instance.confirmSignInWithDifferentAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyles = theme.textStyles;
    final screenWidth = MediaQuery.sizeOf(context).width;

    const maxHeroWidth = 120.0;
    const minHeroWidth = 80.0;
    final heroWidth = (screenWidth * 0.28).clamp(minHeroWidth, maxHeroWidth);

    return PopScope(
      canPop: !_isLoading,
      child: AnimatedBuilder(
        animation: _heroController,
        builder: (context, child) {
          return Opacity(
            opacity: _heroOpacity.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, _heroOffsetY.value),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(heroWidth * 0.22),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: heroWidth,
                height: heroWidth,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '保護你的財務資料',
              style: textStyles.headlineSmallEmphasis.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '開啟雲端同步，即使更換手機或遺失設備，你的記帳紀錄也能安全無虞地還原。',
                style: textStyles.bodyLargeMuted.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: SizedBox(
                    width: double.infinity,
                    child: GoogleLinkButton(
                      isLoading: _isLoading,
                      isPressed: _isPressed,
                      onTap: _onLinkGoogleTap,
                      onTapDown: (_) {
                        if (!_isLoading) setState(() => _isPressed = true);
                      },
                      onTapUp: (_) => setState(() => _isPressed = false),
                      onTapCancel: () => setState(() => _isPressed = false),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeGreetingView extends StatefulWidget {
  const _WelcomeGreetingView({super.key, required this.user, required this.onDone});

  final AuthState user;
  final VoidCallback onDone;

  @override
  State<_WelcomeGreetingView> createState() => _WelcomeGreetingViewState();
}

class _WelcomeGreetingViewState extends State<_WelcomeGreetingView>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _avatarScale;
  late Animation<double> _textOpacity;
  late Animation<double> _textOffsetY;

  static const _entranceDuration = Duration(milliseconds: 700);
  static const _holdDuration = Duration(milliseconds: 2000);

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(vsync: this, duration: _entranceDuration);

    _avatarScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _textOffsetY = Tween<double>(begin: 16.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _entranceController.forward().then((_) {
      Future.delayed(_holdDuration, () {
        if (mounted) widget.onDone();
      });
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyles = theme.textStyles;
    final user = widget.user;

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, _) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: _avatarScale.value.clamp(0.0, 1.5),
                  child: UserAvatar(user: user, size: 96),
                ),
                const SizedBox(height: 28),
                Opacity(
                  opacity: _textOpacity.value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, _textOffsetY.value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '設定完成！',
                          style: textStyles.headlineSmallEmphasis.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '你的記帳資料已受到雲端保護',
                          style: textStyles.bodyLargeMuted.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: textStyles.bodyMuted.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AuthenticatedView extends StatelessWidget {
  const _AuthenticatedView({super.key, required this.user});

  final AuthState user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyles = theme.textStyles;
    final sync = CloudSyncService.instance;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _LinkedAccountTile(user: user),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SyncStatusPanel(
                      status: sync.status.value,
                      lastSyncText: _formatLastSync(sync.lastSyncAt.value),
                      onSyncTap: () => sync.sync(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _DisconnectSection(textStyles: textStyles, colorScheme: colorScheme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatLastSync(DateTime? dateTime) {
    if (dateTime == null) return '尚未同步';
    final now = DateTime.now();
    final local = dateTime.toLocal();
    final sameDay =
        now.year == local.year && now.month == local.month && now.day == local.day;
    if (sameDay) return '最後同步：今天 ${DateFormat('HH:mm').format(local)}';
    return '最後同步：${DateFormat('y/M/d HH:mm').format(local)}';
  }
}

class _LinkedAccountTile extends StatelessWidget {
  const _LinkedAccountTile({required this.user});

  final AuthState user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = theme.textStyles;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          UserAvatar(user: user, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email, style: textStyles.titleEmphasis),
                const SizedBox(height: 2),
                Text('已連結的 Google 帳號', style: textStyles.bodyMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusPanel extends StatelessWidget {
  const _SyncStatusPanel({
    required this.status,
    required this.lastSyncText,
    required this.onSyncTap,
  });

  final CloudSyncStatus status;
  final String lastSyncText;
  final VoidCallback onSyncTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyles = theme.textStyles;

    String title;
    IconData icon;
    Color iconColor;
    switch (status) {
      case CloudSyncStatus.synced:
        title = '資料已安全備份至雲端';
        icon = Icons.cloud_done;
        iconColor = colorScheme.primary;
      case CloudSyncStatus.syncing:
        title = '同步中...';
        icon = Icons.cloud_upload_rounded;
        iconColor = colorScheme.primary;
      case CloudSyncStatus.offline:
        title = '離線 / 未同步';
        icon = Icons.cloud_off;
        iconColor = colorScheme.error;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (status == CloudSyncStatus.syncing)
            _SyncIconAnimated(color: iconColor)
          else
            Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textStyles.titleEmphasis),
                const SizedBox(height: 4),
                Text(lastSyncText, style: textStyles.bodyMuted),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: status == CloudSyncStatus.syncing ? null : onSyncTap,
            child: Text(
              '立即同步',
              style: textStyles.labelEmphasis.copyWith(
                color: status == CloudSyncStatus.syncing
                    ? colorScheme.primary.withValues(alpha: 0.4)
                    : colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisconnectSection extends StatelessWidget {
  const _DisconnectSection({required this.textStyles, required this.colorScheme});

  final AppTextStyles textStyles;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TileGroup(
          children: [
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.cloud_off, size: 20, color: colorScheme.error),
              ),
              title: Text(
                '關閉雲端同步',
                style: textStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.error,
                ),
              ),
              trailing: const SizedBox.shrink(),
              onTap: () => _onDisconnectTap(context),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Text('關閉後將停止備份，已在雲端的資料不受影響。', style: textStyles.labelMuted),
        ),
      ],
    );
  }

  Future<void> _onDisconnectTap(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('關閉雲端同步'),
        content: const Text('關閉後，新的記帳資料將只會保存在此設備上。已備份到雲端的資料不會被刪除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.instance.signOut();
      await CloudSyncService.instance.clearLastSyncAt();
    }
  }
}

class _SyncIconAnimated extends StatefulWidget {
  const _SyncIconAnimated({required this.color});
  final Color color;

  @override
  State<_SyncIconAnimated> createState() => _SyncIconAnimatedState();
}

class _SyncIconAnimatedState extends State<_SyncIconAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => Opacity(
        opacity: 0.4 + 0.6 * _controller.value,
        child: Icon(Icons.cloud_upload_rounded, color: widget.color, size: 28),
      ),
    );
  }
}

class _TileGroup extends StatelessWidget {
  const _TileGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
