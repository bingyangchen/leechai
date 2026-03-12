import 'package:barcode_widget/barcode_widget.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';

enum UserStatsCardBackViewState { display, empty, edit }

class UserStatsCardBack extends StatelessWidget {
  const UserStatsCardBack({
    super.key,
    required this.theme,
    required this.heroColors,
    required this.edgeColor,
    required this.thicknessOffset,
    this.carrier,
    required this.carrierLoaded,
    required this.viewState,
    required this.editController,
    this.onRestoreBrightness,
    required this.onStartEdit,
    required this.onCancel,
    required this.onSave,
    required this.onEditChanged,
  });

  final ThemeData theme;
  final HeroCardColors heroColors;
  final Color edgeColor;
  final Offset thicknessOffset;
  final String? carrier;
  final bool carrierLoaded;
  final UserStatsCardBackViewState viewState;
  final TextEditingController editController;
  final VoidCallback? onRestoreBrightness;
  final void Function(String initialValue) onStartEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final void Function(String value) onEditChanged;

  @override
  Widget build(BuildContext context) {
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
                child: carrierLoaded
                    ? AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: viewState == UserStatsCardBackViewState.display
                            ? KeyedSubtree(
                                key: const ValueKey('back_display'),
                                child: _buildDisplay(context),
                              )
                            : viewState == UserStatsCardBackViewState.empty
                            ? KeyedSubtree(
                                key: const ValueKey('back_empty'),
                                child: _buildEmpty(context),
                              )
                            : KeyedSubtree(
                                key: const ValueKey('back_edit'),
                                child: _buildEdit(context),
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

  Widget _buildDisplay(BuildContext context) {
    final carrierValue = carrier ?? '';
    final barcodeColors = BarcodeColors.fromTheme(theme);
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
                onRestoreBrightness?.call();
                onStartEdit(carrierValue);
              },
              style: IconButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: barcodeColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: BarcodeWidget(
              barcode: Barcode.code39(),
              data: carrierValue,
              width: double.infinity,
              height: 85,
              margin: const EdgeInsets.all(20),
              drawText: false,
              color: barcodeColors.bar,
              backgroundColor: barcodeColors.background,
              errorBuilder: (_, context) => const SizedBox(height: 56),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            carrierValue,
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

  Widget _buildEmpty(BuildContext context) {
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
              onTap: () => onStartEdit('/'),
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

  Widget _buildEdit(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: editController,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onChanged: onEditChanged,
            decoration: const InputDecoration(
              hintText: '/AB12345',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onSubmitted: (_) => onSave(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onCancel, child: const Text('取消')),
              const SizedBox(width: 8),
              TextButton(onPressed: onSave, child: const Text('儲存')),
            ],
          ),
        ],
      ),
    );
  }
}
