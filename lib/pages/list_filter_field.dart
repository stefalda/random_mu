import 'package:flutter/material.dart';

/// Search field used by the browsable lists.
///
/// It owns its [TextEditingController], so every list keeps an independent
/// filter (the lists used to share one provider-held controller) and the
/// controller is disposed with the widget.
class ListFilterField extends StatefulWidget {
  const ListFilterField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.initialValue = '',
    this.compact = false,
  });

  final String hint;
  final String initialValue;
  final bool compact;
  final ValueChanged<String> onChanged;

  @override
  State<ListFilterField> createState() => _ListFilterFieldState();
}

class _ListFilterFieldState extends State<ListFilterField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update(String value) {
    widget.onChanged(value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.compact
          ? const EdgeInsets.fromLTRB(12, 8, 12, 4)
          : const EdgeInsets.all(16.0),
      child: TextField(
        controller: _controller,
        style: widget.compact ? const TextStyle(fontSize: 14) : null,
        decoration: InputDecoration(
          isDense: widget.compact,
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _update('');
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.compact ? 8 : 12),
          ),
        ),
        onChanged: _update,
      ),
    );
  }
}
