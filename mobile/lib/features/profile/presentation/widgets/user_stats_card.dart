import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/profile/data/repositories/invoice_carrier.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:screen_brightness/screen_brightness.dart';

class UserStatsCard extends StatefulWidget {
  const UserStatsCard({
    super.key,
    required this.data,
    this.isPageVisible = true,
    this.interactionNotifier,
    this.onTap,
  });
  final ProfilePageData data;
  final bool isPageVisible;
  final ValueNotifier<bool>? interactionNotifier;
  final VoidCallback? onTap;

  @override
  State<UserStatsCard> createState() => _UserStatsCardState();
}

enum _BackViewState { display, empty, edit }

class _UserStatsCardState extends State<UserStatsCard>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  double _tiltX = 0;
  double _tiltY = 0;
  Offset? _lastPosition;
  Offset? _pointerDownPosition;
  double _totalDragDown = 0;
  double _totalDragUp = 0;
  bool _isFlipped = false;
  static const double _maxTilt = 0.12;
  static const double _tapSlop = 18;
  static const double _dragSensitivity = 0.003;
  static const double _flipThreshold = 100;
  static const int _springBackDurationMs = 200;
  static const int _entranceDurationMs = 1000;
  static const int _flipDurationMs = 320;

  static final RegExp _carrierRegex = RegExp(r'^/[A-Z0-9+\-.]{7}$');

  late AnimationController _springController;
  late AnimationController _entranceController;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  double _tiltXBeforeSpring = 0;
  double _tiltYBeforeSpring = 0;
  bool _wasPageVisible = false;

  final InvoiceCarrierRepository _carrierRepository = InvoiceCarrierRepository();
  final TextEditingController _editController = TextEditingController();
  String? _carrier;
  _BackViewState _backViewState = _BackViewState.empty;
  String _editText = '';
  double? _savedBrightness;
  bool _carrierLoaded = false;

  void _runEntranceAnimation() {
    if (!mounted) return;
    _entranceController.reset();
    _entranceController.forward();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _springBackDurationMs),
    );
    _springController.addListener(_onSpringTick);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _entranceDurationMs),
    );
    _entranceController.addListener(() => setState(() {}));
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _flipDurationMs),
    );
    _flipAnimation = CurvedAnimation(parent: _flipController, curve: Curves.easeInOut);
    _flipController.addListener(() => setState(() {}));
    _flipController.addStatusListener(_onFlipStatusChanged);
    _wasPageVisible = widget.isPageVisible;
    if (widget.isPageVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runEntranceAnimation());
    }
    _loadCarrier();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _restoreBrightness();
    }
  }

  Future<void> _loadCarrier() async {
    final value = await _carrierRepository.load();
    if (mounted) {
      setState(() {
        _carrier = value;
        _carrierLoaded = true;
        _backViewState = (value != null && value.isNotEmpty)
            ? _BackViewState.display
            : _BackViewState.empty;
      });
    }
  }

  void _onFlipStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && _flipController.value >= 0.99) {
      if (_backViewState == _BackViewState.display && _carrier != null) {
        _setBrightnessHigh();
      }
    } else if (status == AnimationStatus.dismissed && _flipController.value <= 0.01) {
      _restoreBrightness();
    }
  }

  Future<void> _setBrightnessHigh() async {
    if (_savedBrightness != null) return;
    try {
      _savedBrightness = await ScreenBrightness().application;
      await ScreenBrightness().setApplicationScreenBrightness(1.0);
    } catch (_) {}
  }

  Future<void> _restoreBrightness() async {
    if (_savedBrightness == null) return;
    try {
      await ScreenBrightness().setApplicationScreenBrightness(_savedBrightness!);
      if (mounted) setState(() => _savedBrightness = null);
    } catch (_) {
      if (mounted) setState(() => _savedBrightness = null);
    }
  }

  void _flipBackToFront() {
    if (!_isFlipped) return;
    _restoreBrightness();
    setState(() {
      _isFlipped = false;
      _flipController.reverse();
    });
  }

  @override
  void didUpdateWidget(UserStatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPageVisible && !_wasPageVisible) {
      _runEntranceAnimation();
      _wasPageVisible = true;
    } else if (!widget.isPageVisible) {
      _wasPageVisible = false;
      if (_isFlipped) _flipBackToFront();
    }
  }

  void _onSpringTick() {
    if (!_springController.isAnimating) return;
    final value = Curves.easeOut.transform(_springController.value);
    setState(() {
      _tiltX = ui.lerpDouble(_tiltXBeforeSpring, 0, value)!;
      _tiltY = ui.lerpDouble(_tiltYBeforeSpring, 0, value)!;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flipController.removeStatusListener(_onFlipStatusChanged);
    _editController.dispose();
    _restoreBrightness();
    _springController.dispose();
    _entranceController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _lastPosition = event.position;
    _pointerDownPosition = event.position;
    _totalDragDown = 0;
    _totalDragUp = 0;
    _springController.stop();
    widget.interactionNotifier?.value = true;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_lastPosition == null) return;
    final delta = event.position - _lastPosition!;
    _lastPosition = event.position;
    if (delta.dy > 0) _totalDragDown += delta.dy;
    if (delta.dy < 0) _totalDragUp -= delta.dy;
    setState(() {
      _tiltY -= delta.dx * _dragSensitivity;
      _tiltX += delta.dy * _dragSensitivity;
      _tiltX = _tiltX.clamp(-_maxTilt, _maxTilt);
      _tiltY = _tiltY.clamp(-_maxTilt, _maxTilt);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    final down = _pointerDownPosition;
    _lastPosition = null;
    _pointerDownPosition = null;
    widget.interactionNotifier?.value = false;
    if (down != null &&
        widget.onTap != null &&
        (event.position - down).distance <= _tapSlop &&
        !_isFlipped) {
      widget.onTap!();
    }
    if (!_isFlipped && _totalDragDown >= _flipThreshold) {
      _isFlipped = true;
      _flipController.forward();
    } else if (_isFlipped && _totalDragUp >= _flipThreshold) {
      _isFlipped = false;
      _flipController.reverse();
    }
    _tiltXBeforeSpring = _tiltX;
    _tiltYBeforeSpring = _tiltY;
    _springController.forward(from: 0);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _lastPosition = null;
    _pointerDownPosition = null;
    widget.interactionNotifier?.value = false;
    _tiltXBeforeSpring = _tiltX;
    _tiltYBeforeSpring = _tiltY;
    _springController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final entranceT = Curves.easeOut.transform(_entranceController.value);
    final theme = Theme.of(context);
    final heroColors = HeroCardColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [theme.colorScheme.surfaceContainerHighest, theme.colorScheme.surface]
          : [theme.colorScheme.primary, theme.colorScheme.onPrimary],
    );

    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(_tiltX)
      ..rotateY(_tiltY);

    final glossCenterX = 0.5 + _tiltY * 2.5;
    final glossCenterY = 0.5 + _tiltX * 2.5;

    const double cardAspectRatio = 85.6 / 53.98;
    const double thicknessPixels = 8;
    final thicknessOffset = Offset(thicknessPixels * _tiltY, -thicknessPixels * _tiltX);
    final edgeColor = isDark
        ? theme.colorScheme.surface.withValues(alpha: 0.5)
        : theme.colorScheme.primary.withValues(alpha: 0.55);

    final flipT = _flipAnimation.value;

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: AspectRatio(
          aspectRatio: cardAspectRatio,
          child: Transform(
            alignment: Alignment.center,
            transform: transform,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(flipT * math.pi),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: flipT < 0.5 ? 1 : 0,
                      child: _buildFrontFace(
                        theme: theme,
                        heroColors: heroColors,
                        gradient: gradient,
                        edgeColor: edgeColor,
                        thicknessOffset: thicknessOffset,
                        glossCenterX: glossCenterX,
                        glossCenterY: glossCenterY,
                        entranceT: entranceT,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: flipT >= 0.5 ? 1 : 0,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationX(math.pi),
                        child: _buildBackFace(
                          theme: theme,
                          heroColors: heroColors,
                          edgeColor: edgeColor,
                          thicknessOffset: thicknessOffset,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrontFace({
    required ThemeData theme,
    required HeroCardColors heroColors,
    required Gradient gradient,
    required Color edgeColor,
    required Offset thicknessOffset,
    required double glossCenterX,
    required double glossCenterY,
    required double entranceT,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Transform.translate(
            offset: thicknessOffset,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: edgeColor,
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: heroColors.shadowSubtle,
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: _HeroStreakBlock(
                          value:
                              '${(widget.data.consecutiveActiveDays * entranceT).round()}',
                          label: '連續活躍日',
                          progressFactor: entranceT,
                          contentColor: heroColors.content,
                          contentColorMuted: heroColors.contentMuted,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _AuxStatBlock(
                                    icon: Icons.edit_note,
                                    value:
                                        '${(widget.data.totalEntries * entranceT).round()}',
                                    label: '總記帳數',
                                    contentColor: heroColors.content,
                                    contentColorMuted: heroColors.contentMuted,
                                  ),
                                ),
                                Expanded(
                                  child: _AuxStatBlock(
                                    icon: Icons.calendar_today,
                                    value:
                                        '${(widget.data.totalDays * entranceT).round()}',
                                    label: '累積天數',
                                    contentColor: heroColors.content,
                                    contentColorMuted: heroColors.contentMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _BadgeProgressBlock(
                                    unlocked: widget.data.unlockedBadgesCount,
                                    total: widget.data.totalBadgesCount,
                                    progressFactor: entranceT,
                                    contentColor: heroColors.content,
                                    contentColorMuted: heroColors.contentMuted,
                                  ),
                                ),
                                Expanded(
                                  child: _AuxStatBlock(
                                    icon: Icons.bar_chart,
                                    value:
                                        '${(widget.data.entriesThisMonth * entranceT).round()}',
                                    label: '本月記帳',
                                    contentColor: heroColors.content,
                                    contentColorMuted: heroColors.contentMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: RadialGradient(
                      center: Alignment(
                        glossCenterX.clamp(-1.0, 2.0),
                        glossCenterY.clamp(-1.0, 2.0),
                      ),
                      radius: 1.2,
                      colors: [
                        heroColors.content.withValues(alpha: 0.12),
                        heroColors.content.withValues(alpha: 0.04),
                        heroColors.content.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 12,
                child: _BrandMark(heroColors: heroColors),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackFace({
    required ThemeData theme,
    required HeroCardColors heroColors,
    required Color edgeColor,
    required Offset thicknessOffset,
  }) {
    const borderRadius = 20.0;
    final surfaceBg = theme.colorScheme.surfaceContainerHighest;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Transform.translate(
            offset: thicknessOffset,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                color: edgeColor,
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: surfaceBg,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: heroColors.shadowSubtle,
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: _carrierLoaded
                    ? AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: _backViewState == _BackViewState.display
                            ? KeyedSubtree(
                                key: const ValueKey('back_display'),
                                child: _buildBackDisplay(theme, heroColors),
                              )
                            : _backViewState == _BackViewState.empty
                            ? KeyedSubtree(
                                key: const ValueKey('back_empty'),
                                child: _buildBackEmpty(theme, heroColors),
                              )
                            : KeyedSubtree(
                                key: const ValueKey('back_edit'),
                                child: _buildBackEdit(theme, heroColors),
                              ),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '向上拖曳翻回',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackDisplay(ThemeData theme, HeroCardColors heroColors) {
    final carrier = _carrier ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                _restoreBrightness();
                setState(() {
                  _backViewState = _BackViewState.edit;
                  _editText = carrier;
                  _editController.text = carrier;
                  _editController.selection = TextSelection.collapsed(
                    offset: carrier.length,
                  );
                });
              },
              style: IconButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: BarcodeWidget(
              barcode: Barcode.code39(),
              data: carrier,
              width: double.infinity,
              height: 85,
              margin: const EdgeInsets.all(20),
              drawText: false,
              color: const Color(0xFF000000),
              backgroundColor: const Color(0xFFFFFFFF),
              errorBuilder: (_, context) => const SizedBox(height: 56),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            carrier,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackEmpty(ThemeData theme, HeroCardColors heroColors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DottedBorder(
          options: RoundedRectDottedBorderOptions(
            radius: const Radius.circular(12),
            color: theme.colorScheme.outline.withValues(alpha: 0.6),
            strokeWidth: 1.5,
            dashPattern: const [6, 4],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _backViewState = _BackViewState.edit;
                  _editText = '/';
                  _editController.text = '/';
                  _editController.selection = TextSelection.collapsed(offset: 1);
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Text(
                  '+ 新增發票載具',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackEdit(ThemeData theme, HeroCardColors heroColors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _editController,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) => setState(() => _editText = value),
            decoration: InputDecoration(
              hintText: '/AB12345',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onSubmitted: (_) => _saveCarrier(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _backViewState = _carrier != null && _carrier!.isNotEmpty
                        ? _BackViewState.display
                        : _BackViewState.empty;
                    _editText = _carrier ?? '';
                    _editController.text = _editText;
                  });
                },
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: _saveCarrier, child: const Text('儲存')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveCarrier() async {
    final trimmed = _editController.text.trim();
    if (trimmed.isEmpty) {
      await _carrierRepository.save(null);
      if (mounted) {
        setState(() {
          _carrier = null;
          _backViewState = _BackViewState.empty;
          _editText = '';
          _editController.text = '';
        });
      }
      return;
    }
    if (!_carrierRegex.hasMatch(trimmed)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請輸入正確格式：/ 開頭加 7 碼（大寫英文、數字或 + - .）')),
        );
      }
      return;
    }
    await _carrierRepository.save(trimmed);
    if (mounted) {
      setState(() {
        _carrier = trimmed;
        _backViewState = _BackViewState.display;
        _editText = trimmed;
        _editController.text = trimmed;
      });
      if (_isFlipped) _setBrightnessHigh();
    }
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.heroColors});

  final HeroCardColors heroColors;

  @override
  Widget build(BuildContext context) {
    final silver = heroColors.content.withValues(alpha: 0.62);
    return Text(
      'LEECHAI',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        color: silver,
      ),
    );
  }
}

class _HeroStreakBlock extends StatelessWidget {
  const _HeroStreakBlock({
    required this.value,
    required this.label,
    this.progressFactor = 1.0,
    required this.contentColor,
    required this.contentColorMuted,
  });

  final String value;
  final String label;
  final double progressFactor;
  final Color contentColor;
  final Color contentColorMuted;

  static const double _iconSize = 40;

  @override
  Widget build(BuildContext context) {
    final scale = Curves.easeOutBack.transform(progressFactor.clamp(0.0, 1.0));
    final opacity = progressFactor.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: Icon(
                Icons.local_fire_department,
                size: _iconSize,
                color: contentColor.withValues(alpha: opacity),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: contentColor,
                height: 1.0,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: contentColorMuted,
          ),
        ),
      ],
    );
  }
}

class _BadgeProgressBlock extends StatelessWidget {
  const _BadgeProgressBlock({
    required this.unlocked,
    required this.total,
    this.progressFactor = 1.0,
    required this.contentColor,
    required this.contentColorMuted,
  });

  final int unlocked;
  final int total;
  final double progressFactor;
  final Color contentColor;
  final Color contentColorMuted;

  static const double _size = 40;
  static const double _strokeWidth = 2.5;
  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (unlocked / total).clamp(0.0, 1.0) : 0.0;
    final displayProgress = (progress * progressFactor).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: displayProgress,
                strokeWidth: _strokeWidth,
                strokeCap: StrokeCap.round,
                backgroundColor: contentColorMuted.withValues(alpha: 0.35),
                valueColor: AlwaysStoppedAnimation<Color>(contentColor),
              ),
              Icon(Icons.emoji_events, size: _iconSize, color: contentColorMuted),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '收集徽章',
          style: TextStyle(fontSize: 11, color: contentColorMuted),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}

class _AuxStatBlock extends StatelessWidget {
  const _AuxStatBlock({
    required this.icon,
    required this.value,
    required this.label,
    required this.contentColor,
    required this.contentColorMuted,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color contentColor;
  final Color contentColorMuted;

  static const double _iconSize = 20;
  static const double _valueFontSize = 20;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: _iconSize, color: contentColorMuted),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: _valueFontSize,
            fontWeight: FontWeight.w600,
            color: contentColor,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: contentColorMuted),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}
