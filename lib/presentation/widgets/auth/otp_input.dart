import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// A polished 6-box OTP / code input. Auto-advances, supports paste, and
/// fires [onCompleted] when all boxes are filled.
class OtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;

  const OtpInput({
    super.key,
    this.length = 6,
    required this.onChanged,
    this.onCompleted,
    this.autofocus = true,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _value => _controllers.map((c) => c.text).join();

  void _onChange(int i, String v) {
    // Paste handling — distribute across boxes
    if (v.length > 1) {
      final digits = v.replaceAll(RegExp(r'\D'), '');
      for (var j = 0; j < widget.length; j++) {
        _controllers[j].text = j < digits.length ? digits[j] : '';
      }
      final last = (digits.length).clamp(0, widget.length - 1);
      _nodes[last].requestFocus();
      _emit();
      return;
    }
    if (v.isNotEmpty && i < widget.length - 1) {
      _nodes[i + 1].requestFocus();
    } else if (v.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
    _emit();
  }

  void _emit() {
    final val = _value;
    widget.onChanged(val);
    // All boxes filled (digits-only formatter guarantees non-empty chars).
    if (val.length == widget.length) {
      widget.onCompleted?.call(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) {
        final filled = _controllers[i].text.isNotEmpty;
        return SizedBox(
          width: 48,
          height: 58,
          child: TextField(
            controller: _controllers[i],
            focusNode: _nodes[i],
            autofocus: widget.autofocus && i == 0,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: i == 0 ? widget.length : 1, // first box accepts paste
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: filled
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : context.cardColor,
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: filled ? AppColors.primary : context.cardBorderColor,
                  width: filled ? 1.6 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _onChange(i, v),
          ),
        );
      }),
    );
  }
}
