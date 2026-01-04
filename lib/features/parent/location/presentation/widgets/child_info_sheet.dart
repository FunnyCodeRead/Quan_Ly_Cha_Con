import 'package:flutter/material.dart';
import 'package:quan_ly_cha_con/features/parent/location/domain/entities/location_data.dart';
import 'package:quan_ly_cha_con/features/user/domain/entities/user.dart';


class ChildInfoSheet extends StatefulWidget {
  final User child;
  final LocationData? latest;

  final bool isSearching;

  /// mở màn chat
  final VoidCallback onOpenChat;

  /// gửi tin nhắn nhanh
  final Future<void> Function(String message) onSendQuickMessage;

  /// bật/tắt tìm kiếm (route)
  final VoidCallback onToggleSearch;

  const ChildInfoSheet({
    super.key,
    required this.child,
    required this.latest,
    required this.isSearching,
    required this.onOpenChat,
    required this.onSendQuickMessage,
    required this.onToggleSearch,
  });

  @override
  State<ChildInfoSheet> createState() => _ChildInfoSheetState();
}

class _ChildInfoSheetState extends State<ChildInfoSheet> {
  final TextEditingController _msgCtl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await widget.onSendQuickMessage(text);
      _msgCtl.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi tin nhắn')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gửi thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final latest = widget.latest;

    final name = child.name.isNotEmpty ? child.name : child.email;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    const batteryText = '70%'; // TODO: thay bằng dữ liệu thật
    const statusText = 'Đang học'; // TODO: thay bằng dữ liệu thật

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom; // ✅ keyboard height
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset), // ✅ đẩy sheet lên khi mở phím
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Thông tin',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),

                      // ===== card user =====
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.amber.shade200,
                              child: Text(
                                initial,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Online',
                                        style: TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // ✅ chat -> chuyển màn chat luôn
                            InkWell(
                              onTap: widget.onOpenChat,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.chat_bubble_outline, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ===== quick message =====
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _msgCtl,
                                decoration: const InputDecoration(
                                  hintText: 'Gửi tin nhắn nhanh...',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _send(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _sending ? null : _send,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: _sending
                                    ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                    : const Icon(Icons.send, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LEFT schedule
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_month, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Lịch trình',
                                        style: TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  _ScheduleItem(
                                    title: 'Đang học thể dục',
                                    time: '7h00p – 7h45p',
                                  ),
                                  SizedBox(height: 8),
                                  _ScheduleItem(
                                    title: 'Đang học thể dục',
                                    time: '7h00p – 7h45p',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // RIGHT buttons
                          SizedBox(
                            width: 120,
                            child: Column(
                              children: [
                                _RightPill(
                                  icon: Icons.battery_full,
                                  label: batteryText,
                                  onTap: () {},
                                ),
                                const SizedBox(height: 10),
                                _RightPill(
                                  icon: Icons.circle_outlined,
                                  label: statusText,
                                  onTap: () {},
                                ),
                                const SizedBox(height: 10),
                                _RightPill(
                                  icon: widget.isSearching ? Icons.clear : Icons.search,
                                  label: widget.isSearching ? 'Tắt tìm kiếm' : 'Tìm kiếm',
                                  onTap: widget.onToggleSearch,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (latest != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Lat ${latest.latitude.toStringAsFixed(4)} • Lng ${latest.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  final String title;
  final String time;

  const _ScheduleItem({required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RightPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RightPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
