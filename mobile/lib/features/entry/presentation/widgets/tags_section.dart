import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/features/entry/data/repositories/tag.dart' show TagRepository;

class TagsSection extends StatefulWidget {
  const TagsSection({
    super.key,
    required this.tags,
    required this.inputController,
    required this.enabled,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  final List<String> tags;
  final TextEditingController inputController;
  final bool enabled;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;

  @override
  State<TagsSection> createState() => _TagsSectionState();
}

class _TagsSectionState extends State<TagsSection> {
  List<String> _searchResults = [];
  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;
  static const _debounceDuration = Duration(milliseconds: 200);
  final GlobalKey _anchorKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.inputController.addListener(_onInputChanged);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    widget.inputController.removeListener(_onInputChanged);
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      setState(() => _searchResults = []);
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !mounted) return;
    final position = box.localToGlobal(Offset.zero);
    final size = box.size;
    final theme = Theme.of(context);
    const dropdownMaxHeight = 200.0;
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy - 8 - dropdownMaxHeight,
        width: size.width,
        height: dropdownMaxHeight,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surfaceContainerHighest,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: dropdownMaxHeight),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final title = _searchResults[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.label_outline,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(title),
                    onTap: widget.enabled ? () => _onSelectSearchResult(title) : null,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onInputChanged() {
    final text = widget.inputController.text.trim();
    _debounceTimer?.cancel();
    if (text.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _debounceTimer = Timer(_debounceDuration, () => _runSearch(text));
  }

  Future<void> _runSearch(String query) async {
    final list = await TagRepository.searchByTitlePrefix(query);
    if (!mounted) return;
    final existing = widget.tags.toSet();
    setState(() {
      _searchResults = list.where((t) => !existing.contains(t)).toList();
    });
  }

  void _onSelectSearchResult(String title) {
    setState(() => _searchResults = []);
    _removeOverlay();
    widget.onAddTag(title);
  }

  @override
  Widget build(BuildContext context) {
    if (_searchResults.isEmpty) {
      _removeOverlay();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _searchResults.isNotEmpty) _showOverlay();
      });
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '標籤',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          InputDecorator(
            key: _anchorKey,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final tag in widget.tags)
                        Chip(
                          label: Text(tag),
                          deleteIcon: Icon(
                            Icons.close,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onDeleted: widget.enabled
                              ? () => widget.onRemoveTag(tag)
                              : null,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.inputController,
                        focusNode: _focusNode,
                        enabled: widget.enabled,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: '新增標籤',
                        ),
                        onSubmitted: (value) => widget.onAddTag(value),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.enabled
                          ? () => widget.onAddTag(widget.inputController.text)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
