import 'package:flutter/material.dart';

class TESearchBar extends StatelessWidget {
  const TESearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 14,
            fontFamily: 'Arial',
          ),
          cursorColor: const Color(0xFF22D3EE),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: Color(0xFF9AB3CF)),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF9AB3CF)),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
            hintText: 'Search group or model...',
            hintStyle: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontFamily: 'Arial',
            ),
            filled: true,
            fillColor: const Color(0xFF10213A),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1F3A5F)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1F3A5F)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF22D3EE)),
            ),
          ),
        );
      },
    );
  }
}
