import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/consent_agreement.dart';

/// Inline consent checkbox used on login/signup. The "Privacy Agreement" link
/// opens the full text in a scrollable sheet. The parent gates its primary
/// action on [value] and records acceptance via ConsentService.
class ConsentCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
            side: BorderSide(color: context.cardBorderColor, width: 1.5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    color: context.textSecondary, fontSize: 12.5, height: 1.5),
                children: [
                  const TextSpan(
                      text:
                          'I agree to read bank SMS on this device to track my '
                          'spending. My data stays encrypted on my device. See the '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      onTap: () => showAgreement(context),
                      child: const Text(
                        'Privacy Agreement',
                        style: TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Future<void> showAgreement(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (ctx, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.cardBorderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text('Privacy Agreement',
                      style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Text(
                  ConsentAgreement.text,
                  style: TextStyle(
                      color: context.textSecondary, fontSize: 13, height: 1.6),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
