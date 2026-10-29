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
  });

  final String hint;
  final String initialValue;
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
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
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
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: _update,
      ),
    );
  }
}
