import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mobile/features/profile/data/repositories/invoice_carrier.dart';
import 'package:mobile/features/profile/domain/profile_page_data.dart';
import 'package:mobile/features/profile/presentation/widgets/user_stats_card_back.dart';
import 'package:mobile/features/profile/presentation/widgets/user_stats_card_front.dart';
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
  UserStatsCardBackViewState _backViewState = UserStatsCardBackViewState.empty;
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
            ? UserStatsCardBackViewState.display
            : UserStatsCardBackViewState.empty;
      });
    }
  }

  void _onFlipStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && _flipController.value >= 0.99) {
      if (_backViewState == UserStatsCardBackViewState.display && _carrier != null) {
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

  void _discardBackEditIfNeeded() {
    if (_backViewState != UserStatsCardBackViewState.edit) return;
    setState(() {
      _backViewState = _carrier != null && _carrier!.isNotEmpty
          ? UserStatsCardBackViewState.display
          : UserStatsCardBackViewState.empty;
      _editText = _carrier ?? '';
      _editController.text = _editText;
    });
  }

  void _flipBackToFront() {
    if (!_isFlipped) return;
    _discardBackEditIfNeeded();
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
      _discardBackEditIfNeeded();
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
                      child: UserStatsCardFront(
                        data: widget.data,
                        entranceT: entranceT,
                        theme: theme,
                        heroColors: heroColors,
                        gradient: gradient,
                        edgeColor: edgeColor,
                        thicknessOffset: thicknessOffset,
                        glossCenterX: glossCenterX,
                        glossCenterY: glossCenterY,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: flipT >= 0.5 ? 1 : 0,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationX(math.pi),
                        child: UserStatsCardBack(
                          theme: theme,
                          heroColors: heroColors,
                          edgeColor: edgeColor,
                          thicknessOffset: thicknessOffset,
                          carrier: _carrier,
                          carrierLoaded: _carrierLoaded,
                          viewState: _backViewState,
                          editController: _editController,
                          onRestoreBrightness: _restoreBrightness,
                          onStartEdit: (String initialValue) {
                            setState(() {
                              _backViewState = UserStatsCardBackViewState.edit;
                              _editText = initialValue;
                              _editController.text = initialValue;
                              _editController.selection = TextSelection.collapsed(
                                offset: initialValue.length,
                              );
                            });
                          },
                          onCancel: () {
                            setState(() {
                              _backViewState = _carrier != null && _carrier!.isNotEmpty
                                  ? UserStatsCardBackViewState.display
                                  : UserStatsCardBackViewState.empty;
                              _editText = _carrier ?? '';
                              _editController.text = _editText;
                            });
                          },
                          onSave: _saveCarrier,
                          onEditChanged: (String value) =>
                              setState(() => _editText = value),
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

  Future<void> _saveCarrier() async {
    final trimmed = _editController.text.trim();
    if (trimmed.isEmpty) {
      await _carrierRepository.save(null);
      if (mounted) {
        setState(() {
          _carrier = null;
          _backViewState = UserStatsCardBackViewState.empty;
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
        _backViewState = UserStatsCardBackViewState.display;
        _editText = trimmed;
        _editController.text = trimmed;
      });
      if (_isFlipped) _setBrightnessHigh();
    }
  }
}
