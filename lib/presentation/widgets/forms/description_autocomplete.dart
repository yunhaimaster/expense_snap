import 'package:flutter/material.dart';

import '../../../core/constants/validation_rules.dart';
import '../../../core/services/quick_input_service.dart';
import '../../../core/theme/app_colors.dart';

/// 描述自動完成輸入框
///
/// 支援從歷史記錄中自動完成描述
class DescriptionAutocomplete extends StatefulWidget {
  const DescriptionAutocomplete({
    super.key,
    required this.controller,
    this.enabled = true,
    this.validator,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? Function(String?)? validator;

  @override
  State<DescriptionAutocomplete> createState() =>
      _DescriptionAutocompleteState();
}

class _DescriptionAutocompleteState extends State<DescriptionAutocomplete> {
  final _service = QuickInputService.instance;
  List<String> _suggestions = [];
  bool _isLoading = false;
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    _loadInitialSuggestions();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  Future<void> _loadInitialSuggestions() async {
    setState(() => _isLoading = true);
    try {
      _suggestions = await _service.getRecentDescriptions();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    if (text.isEmpty) {
      _loadInitialSuggestions();
    } else {
      _searchSuggestions(text);
    }
  }

  Future<void> _searchSuggestions(String query) async {
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      _suggestions = await _service.searchDescriptions(query);
      _updateOverlay();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && _suggestions.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null || _suggestions.isEmpty) return;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _overlayEntry = _createOverlayEntry();
    if (_overlayEntry != null) {
      overlay.insert(_overlayEntry!);
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    if (_focusNode.hasFocus && _suggestions.isNotEmpty) {
      _removeOverlay();
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  OverlayEntry? _createOverlayEntry() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    final size = renderObject.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.history,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    title: Text(
                      suggestion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      widget.controller.text = suggestion;
                      widget.controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: suggestion.length),
                      );
                      _removeOverlay();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: '描述',
          hintText: '例如：午餐、交通費',
          prefixIcon: const Icon(Icons.description_outlined),
          suffixIcon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
        ),
        maxLength: ValidationRules.maxDescriptionLength,
        maxLines: 2,
        validator: widget.validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return '請輸入描述';
              }
              if (value.length < ValidationRules.minDescriptionLength) {
                return '描述至少需要 ${ValidationRules.minDescriptionLength} 個字';
              }
              return null;
            },
      ),
    );
  }
}
