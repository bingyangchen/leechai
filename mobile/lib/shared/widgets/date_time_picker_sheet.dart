import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/shared/theme/app_theme.dart';

typedef DateTimePickerOnConfirm = void Function(DateTime value, {bool fromDrag});

class DateTimePickerSheet extends StatefulWidget {
  const DateTimePickerSheet({
    super.key,
    required this.initial,
    required this.onConfirm,
    required this.onCancel,
    this.monthOnly = false,
  });

  final DateTime initial;
  final DateTimePickerOnConfirm onConfirm;
  final VoidCallback onCancel;
  final bool monthOnly;

  @override
  State<DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<DateTimePickerSheet> {
  static const int _minYear = 1970;
  static const int _maxYear = 9999;
  static const double _wheelItemHeight = 36;
  static const double _wheelWidthYear = 58;
  static const double _wheelWidthTwoDigit = 44;
  static const double _wheelWidthAmPm = 48;
  static const double _separatorPadding = 0;

  bool _didConfirm = false;
  bool _didCancel = false;

  late int _year;
  late int _month;
  late int _day;
  late int _hour12;
  late int _minute;
  late bool _isAm;

  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _ampmController;

  static const List<String> _ampmLabels = ['上午', '下午'];

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
    _month = widget.initial.month;
    _yearController = FixedExtentScrollController(initialItem: _year - _minYear);
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    if (widget.monthOnly) {
      _day = 1;
      _hour12 = 12;
      _isAm = true;
      _minute = 0;
      _dayController = FixedExtentScrollController(initialItem: 0);
      _hourController = FixedExtentScrollController(initialItem: 0);
      _minuteController = FixedExtentScrollController(initialItem: 0);
      _ampmController = FixedExtentScrollController(initialItem: 0);
      return;
    }
    _day = widget.initial.day;
    _minute = widget.initial.minute;
    final h24 = widget.initial.hour;
    if (h24 == 0) {
      _hour12 = 12;
      _isAm = true;
    } else if (h24 < 12) {
      _hour12 = h24;
      _isAm = true;
    } else if (h24 == 12) {
      _hour12 = 12;
      _isAm = false;
    } else {
      _hour12 = h24 - 12;
      _isAm = false;
    }
    _clampDay();
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
    _hourController = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
    _ampmController = FixedExtentScrollController(initialItem: _isAm ? 0 : 1);
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _ampmController.dispose();
    super.dispose();
  }

  void _clampDay() {
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    if (_day > daysInMonth) _day = daysInMonth;
  }

  int get _hour24 {
    if (_isAm) return _hour12 == 12 ? 0 : _hour12;
    return _hour12 == 12 ? 12 : _hour12 + 12;
  }

  DateTime get _value => DateTime(_year, _month, _day, _hour24, _minute);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop && !_didConfirm && !_didCancel) {
          widget.onConfirm(_value, fromDrag: true);
        }
      },
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      _didCancel = true;
                      widget.onCancel();
                    },
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      _didConfirm = true;
                      widget.onConfirm(_value);
                    },
                    child: const Text('確定'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: _wheelItemHeight * 5,
              child: Center(
                child: widget.monthOnly
                    ? _buildMonthOnlyWheels()
                    : _buildDateTimeWheels(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthOnlyWheels() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _wheelWidthYear,
          child: _buildWheel<int>(
            items: List.generate(_maxYear - _minYear + 1, (i) => _minYear + i),
            value: _year,
            format: (v) => '$v',
            controller: _yearController,
            onChanged: (v) => setState(() => _year = v),
          ),
        ),
        _wheelSeparator('/'),
        SizedBox(
          width: _wheelWidthTwoDigit,
          child: _buildWheel<int>(
            items: List.generate(12, (i) => i + 1),
            value: _month,
            format: (v) => v.toString().padLeft(2, '0'),
            controller: _monthController,
            onChanged: (v) => setState(() => _month = v),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeWheels() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _wheelWidthYear,
          child: _buildWheel<int>(
            items: List.generate(_maxYear - _minYear + 1, (i) => _minYear + i),
            value: _year,
            format: (v) => '$v',
            controller: _yearController,
            onChanged: (v) {
              setState(() {
                _year = v;
                _clampDay();
                _dayController.jumpToItem(_day - 1);
              });
            },
          ),
        ),
        _wheelSeparator('/'),
        SizedBox(
          width: _wheelWidthTwoDigit,
          child: _buildWheel<int>(
            items: List.generate(12, (i) => i + 1),
            value: _month,
            format: (v) => v.toString().padLeft(2, '0'),
            controller: _monthController,
            onChanged: (v) {
              setState(() {
                _month = v;
                _clampDay();
                _dayController.jumpToItem(_day - 1);
              });
            },
          ),
        ),
        _wheelSeparator('/'),
        SizedBox(
          width: _wheelWidthTwoDigit,
          child: _buildWheel<int>(
            items: List.generate(DateTime(_year, _month + 1, 0).day, (i) => i + 1),
            value: _day,
            format: (v) => v.toString().padLeft(2, '0'),
            controller: _dayController,
            onChanged: (v) => setState(() => _day = v),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: _wheelWidthTwoDigit,
          child: _buildWheel<int>(
            items: List.generate(12, (i) => i + 1),
            value: _hour12,
            format: (v) => v.toString().padLeft(2, '0'),
            controller: _hourController,
            onChanged: (v) => setState(() => _hour12 = v),
          ),
        ),
        _wheelSeparator(':'),
        SizedBox(
          width: _wheelWidthTwoDigit,
          child: _buildWheel<int>(
            items: List.generate(60, (i) => i),
            value: _minute,
            format: (v) => v.toString().padLeft(2, '0'),
            controller: _minuteController,
            onChanged: (v) => setState(() => _minute = v),
          ),
        ),
        SizedBox(
          width: _wheelWidthAmPm,
          child: _buildWheel<int>(
            items: const [0, 1],
            value: _isAm ? 0 : 1,
            format: (v) => _ampmLabels[v],
            controller: _ampmController,
            onChanged: (v) => setState(() => _isAm = v == 0),
          ),
        ),
      ],
    );
  }

  Widget _wheelSeparator(String text) {
    final appTextStyles = AppTextStyles.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _separatorPadding),
        child: Text(text, style: appTextStyles.bodyLargeMuted),
      ),
    );
  }

  Widget _buildWheel<T>({
    required List<T> items,
    required T value,
    required String Function(T) format,
    required ScrollController controller,
    required ValueChanged<T> onChanged,
  }) {
    final appTextStyles = AppTextStyles.of(context);
    final index = items.indexOf(value);
    if (index < 0) return const SizedBox.shrink();
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _wheelItemHeight,
      diameterRatio: 1.2,
      physics: const FixedExtentScrollPhysics(),
      perspective: 0.005,
      onSelectedItemChanged: (i) {
        HapticFeedback.selectionClick();
        onChanged(items[i]);
      },
      overAndUnderCenterOpacity: 0.4,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: items.length,
        builder: (context, i) {
          return Center(
            child: Text(format(items[i]), style: appTextStyles.titleEmphasis),
          );
        },
      ),
    );
  }
}
