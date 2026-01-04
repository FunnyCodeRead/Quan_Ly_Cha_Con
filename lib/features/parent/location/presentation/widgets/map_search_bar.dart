import 'package:flutter/material.dart';

class MapSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final double topOffset;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onFilterTap;

  const MapSearchBar({
    super.key,
    required this.controller,
    required this.topOffset,
    required this.onSubmitted,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topOffset,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.black54, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm',
                  border: InputBorder.none,
                  isDense: true,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: onSubmitted,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onFilterTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(Icons.tune, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
