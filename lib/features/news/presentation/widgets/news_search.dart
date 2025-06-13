import 'package:flutter/material.dart';
import 'dart:async';

class NewsSearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const NewsSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<NewsSearchField> createState() => _NewsSearchFieldState();
}

class _NewsSearchFieldState extends State<NewsSearchField> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.onChanged(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      decoration: const InputDecoration(
        hintText: 'Search news...',
        border: InputBorder.none,
      ),
      onChanged: _onSearchChanged,
      autofocus: true,
    );
  }
}
