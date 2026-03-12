import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart';
import 'package:mobile/features/profile/data/services/unsynced_check.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum CloudSyncStatus { synced, syncing, offline }

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({
    super.key,
    this.isLoggedIn = false,
    this.userName = '',
    this.userEmail = '',
    this.avatarFilePath,
  });

  final bool isLoggedIn;
  final String userName;
  final String userEmail;
  final String? avatarFilePath;

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  late String _userName;
  late String _userEmail;
  String? _avatarFilePath;
  CloudSyncStatus _syncStatus = CloudSyncStatus.synced;
  DateTime? _lastSyncAt;

  @override
  void initState() {
    super.initState();
    _userName = widget.userName;
    _userEmail = widget.userEmail;
    _avatarFilePath = widget.avatarFilePath;
    _lastSyncAt = DateTime.now();
  }

  String _formatLastSync(DateTime? dateTime) {
    if (dateTime == null) return '尚未同步';
    final now = DateTime.now();
    final local = dateTime.toLocal();
    final sameDay =
        now.year == local.year && now.month == local.month && now.day == local.day;
    if (sameDay) return '最後同步：今天 ${DateFormat('HH:mm').format(local)}';
    return '最後同步：${DateFormat('y/M/d HH:mm').format(local)}';
  }

  Future<void> _onSyncTap() async {
    if (_syncStatus == CloudSyncStatus.syncing) return;
    setState(() {
      _syncStatus = CloudSyncStatus.syncing;
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _syncStatus = CloudSyncStatus.synced;
      _lastSyncAt = DateTime.now();
    });
  }

  Future<void> _showAvatarSourceSheet() async {
    final theme = Theme.of(context);
    final source = await showAppBottomSheet<ImageSource>(
      context,
      mode: AppBottomSheetMode.static,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              Icons.camera_alt_outlined,
              color: theme.colorScheme.onSurface,
            ),
            title: Text('拍照', style: theme.textStyles.title),
            onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
          ListTile(
            leading: Icon(
              Icons.photo_library_outlined,
              color: theme.colorScheme.onSurface,
            ),
            title: Text('從相簿選擇', style: theme.textStyles.title),
            onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
    if (source == null || !mounted) return;
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source, maxWidth: 192, maxHeight: 192);
    if (xFile == null || !mounted) return;
    final dir = await getTemporaryDirectory();
    final savedPath =
        '${dir.path}/profile_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File(xFile.path);
    await file.copy(savedPath);
    setState(() => _avatarFilePath = savedPath);
  }

  Future<void> _showEditNameSheet() async {
    final controller = TextEditingController(text: _userName);
    final formKey = GlobalKey<FormState>();
    await showAppBottomSheet<void>(
      context,
      title: '修改名稱',
      showCloseButton: false,
      mode: AppBottomSheetMode.static,
      builder: (ctx) {
        final viewInsets = MediaQuery.viewInsetsOf(ctx);
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + viewInsets.bottom),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: '名稱', hintText: '請輸入名稱'),
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '請輸入名稱';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (formKey.currentState?.validate() ?? false) {
                      setState(() => _userName = controller.text.trim());
                      Navigator.of(ctx).pop();
                    }
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    final value = controller.text.trim();
                    setState(() => _userName = value);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('儲存'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportCsv() async {
    final entries = await EntryRepository.getAll();
    if (entries.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('目前沒有可匯出的資料')));
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('類型,借方帳號,貸方帳號,金額,備註,發生時間');
    for (final row in entries) {
      final type = row['type'] as String? ?? '';
      final debit = row['debit_account_id'] as String? ?? '';
      final credit = row['credit_account_id'] as String? ?? '';
      final amount = row['amount'] as num? ?? 0;
      final memo = (row['memo'] as String?)?.replaceAll(',', '，') ?? '';
      final occurred = row['occurred_at'] as String? ?? '';
      buffer.writeln('$type,$debit,$credit,$amount,$memo,$occurred');
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/leechai_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    await File(path).writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(path)], text: '記帳資料匯出');
  }

  Future<void> _onSignOutTap() async {
    final hasUnsynced = await UnsyncedCheck.hasUnsyncedData();
    if (!mounted) return;
    if (hasUnsynced) {
      await _showUnsyncedSignOutSheet();
    } else {
      await _showSignOutConfirmDialog();
    }
  }

  Future<void> _showUnsyncedSignOutSheet() async {
    final theme = Theme.of(context);
    final result = await showAppBottomSheet<bool>(
      context,
      mode: AppBottomSheetMode.static,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('您有尚未同步的資料。現在登出將會遺失這些紀錄。', style: theme.textStyles.body),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('立即同步並登出'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _showForceSignOutConfirm(ctx);
              },
              child: Text('強制登出', style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        ),
      ),
    );
    if (result == true && mounted) {
      setState(() => _syncStatus = CloudSyncStatus.syncing);
      await Future<void>.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _showForceSignOutConfirm(BuildContext sheetContext) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('強制登出'),
        content: const Text('確定要放棄未同步的資料並登出嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('強制登出'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showSignOutConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('登出'),
        content: const Text('確定要登出嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('登出'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onDeleteAccountTap() async {
    final theme = Theme.of(context);
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('刪除帳號', style: TextStyle(color: theme.colorScheme.error)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('此操作無法復原。請輸入 DELETE 以確認。'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '輸入 DELETE',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.trim().toUpperCase() == 'DELETE') {
                  Navigator.of(ctx).pop(true);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().toUpperCase() == 'DELETE') {
                Navigator.of(ctx).pop(true);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            child: const Text('刪除帳號'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('帳號刪除功能需與後端整合')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(toolbarHeight: kToolbarHeight, title: const Text('帳號管理')),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ProfileSection(
                  userName: _userName,
                  userEmail: _userEmail,
                  avatarFilePath: _avatarFilePath,
                  onAvatarTap: _showAvatarSourceSheet,
                  onNameTap: _showEditNameSheet,
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: widget.isLoggedIn
                    ? _CloudSyncCard(
                        status: _syncStatus,
                        lastSyncText: _formatLastSync(_lastSyncAt),
                        onSyncTap: _onSyncTap,
                      )
                    : _CloudSyncLoginPrompt(),
              ),
              const SizedBox(height: 32),
              _SectionLabel(title: widget.isLoggedIn ? '安全與登入' : '登入'),
              _TileGroup(
                children: widget.isLoggedIn
                    ? [
                        _AccountListTile(
                          icon: Icons.devices,
                          title: '管理登入裝置',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const _DevicesPlaceholderPage(),
                            ),
                          ),
                        ),
                      ]
                    : [
                        _AccountListTile(
                          icon: Icons.login,
                          title: '使用 Apple / Google 登入',
                          onTap: () {},
                        ),
                      ],
              ),
              const SizedBox(height: 32),
              _SectionLabel(title: '資料管理'),
              _TileGroup(
                children: [
                  _AccountListTile(
                    icon: Icons.download,
                    title: '匯出 CSV 報表',
                    onTap: _exportCsv,
                  ),
                ],
              ),
              if (widget.isLoggedIn) ...[
                const SizedBox(height: 32 + 24),
                _SectionLabel(title: '危險操作', color: colorScheme.error),
                _TileGroup(
                  children: [
                    _DangerTile(icon: Icons.logout, title: '登出', onTap: _onSignOutTap),
                    _DangerTile(
                      icon: Icons.person_remove,
                      title: '刪除帳號',
                      onTap: _onDeleteAccountTap,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.userName,
    required this.userEmail,
    this.avatarFilePath,
    required this.onAvatarTap,
    required this.onNameTap,
  });

  final String userName;
  final String userEmail;
  final String? avatarFilePath;
  final VoidCallback onAvatarTap;
  final VoidCallback onNameTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyles = theme.textStyles;
    final heroColors = HeroCardColors.of(context);
    const avatarRadius = 48.0;
    const cameraButtonRadius = 16.0;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onAvatarTap,
            customBorder: const CircleBorder(),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: avatarFilePath != null
                      ? FileImage(File(avatarFilePath!))
                      : null,
                  child: avatarFilePath == null && userName.isNotEmpty
                      ? Text(
                          userName[0].toUpperCase(),
                          style: textStyles.headline.copyWith(
                            color: colorScheme.primary,
                          ),
                        )
                      : avatarFilePath == null
                      ? Icon(Icons.person, size: 48, color: colorScheme.primary)
                      : null,
                ),
                Container(
                  width: cameraButtonRadius * 2,
                  height: cameraButtonRadius * 2,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: heroColors.shadowSubtle,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.camera_alt, size: 16, color: colorScheme.primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: onNameTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userName.isEmpty ? '未設定名稱' : userName,
                  style: textStyles.headlineSmallEmphasis.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.edit, size: 16, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(userEmail.isEmpty ? '未登入' : userEmail, style: textStyles.bodyMuted),
      ],
    );
  }
}

class _CloudSyncLoginPrompt extends StatelessWidget {
  const _CloudSyncLoginPrompt();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyles = theme.textStyles;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_outlined, color: colorScheme.onSurfaceVariant, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text('登入以啟用雲端備份，保全資料不遺失。', style: textStyles.bodyMuted)),
        ],
      ),
    );
  }
}

class _CloudSyncCard extends StatelessWidget {
  const _CloudSyncCard({
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
        break;
      case CloudSyncStatus.syncing:
        title = '同步中...';
        icon = Icons.sync;
        iconColor = colorScheme.primary;
        break;
      case CloudSyncStatus.offline:
        title = '離線 / 未同步';
        icon = Icons.cloud_off;
        iconColor = colorScheme.error;
        break;
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
          if (status == CloudSyncStatus.syncing)
            TextButton(
              onPressed: null,
              child: Text(
                '同步中...',
                style: textStyles.labelEmphasis.copyWith(color: colorScheme.primary),
              ),
            )
          else
            TextButton(
              onPressed: onSyncTap,
              child: Text(
                '立即同步',
                style: textStyles.labelEmphasis.copyWith(color: colorScheme.primary),
              ),
            ),
        ],
      ),
    );
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
      duration: const Duration(milliseconds: 1500),
    )..repeat();
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
      builder: (_, child) => Transform.rotate(
        angle: _controller.value * 2 * 3.14159,
        child: Icon(Icons.sync, color: widget.color, size: 28),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, this.color});
  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: theme.textStyles.labelEmphasis.copyWith(
          color: color ?? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _AccountListTile extends StatelessWidget {
  const _AccountListTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  static const double _iconBoxSize = 32;
  static const double _iconBoxRadius = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Container(
        width: _iconBoxSize,
        height: _iconBoxSize,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(_iconBoxRadius),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: colorScheme.onSurface),
      ),
      title: Text(title),
      trailing: Icon(
        Icons.chevron_right,
        size: 24,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
      onTap: onTap,
    );
  }
}

class _DangerTile extends StatelessWidget {
  const _DangerTile({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  static const double _iconBoxSize = 32;
  static const double _iconBoxRadius = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Container(
        width: _iconBoxSize,
        height: _iconBoxSize,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(_iconBoxRadius),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: colorScheme.error),
      ),
      title: Text(
        title,
        style: theme.textStyles.body.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.error,
        ),
      ),
      trailing: const SizedBox.shrink(),
      onTap: onTap,
    );
  }
}

class _DevicesPlaceholderPage extends StatelessWidget {
  const _DevicesPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight,
        title: const Text('管理登入裝置'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Center(
        child: Text('目前無其他登入裝置', style: Theme.of(context).textStyles.bodyMuted),
      ),
    );
  }
}
