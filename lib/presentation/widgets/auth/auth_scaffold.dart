import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Shared, polished scaffold for every auth screen — animated gradient hero,
/// scrollable body, and a pinned footer.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? footer;
  final bool showBack;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    // When the keyboard is up, collapse the hero and tuck the footer into the
    // scroll area so the primary button is reachable WITHOUT manual scrolling.
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: context.bgColor,
      // Let the scroll view handle the keyboard inset (no body resize jump).
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Ambient gradient glow behind the hero
          Positioned(
            top: -120,
            left: -60,
            right: -60,
            child: Container(
              height: 320,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x553B82F6), Color(0x117C3AED), Colors.transparent],
                  radius: 0.9,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Top bar (back) ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Row(
                    children: [
                      if (showBack)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18, color: context.textPrimary),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      const Spacer(),
                    ],
                  ),
                ),

                // ── Hero (collapses when typing) ──────────────────────────
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  crossFadeState: keyboardOpen
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: Column(
                    children: [
                      const SizedBox(height: 8),
                      _Logo(),
                      const SizedBox(height: 24),
                    ],
                  ),
                  secondChild: const SizedBox(height: 8),
                ),

                // ── Body (scrolls; footer rides along so nothing overlaps) ─
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                        24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 6),
                        Text(subtitle,
                            style: TextStyle(
                                color: context.textSecondary, fontSize: 14)),
                        const SizedBox(height: 24),
                        ...children,
                        if (footer != null) ...[
                          const SizedBox(height: 24),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientMid],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientStart.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
              child: Text('💸', style: TextStyle(fontSize: 30))),
        ),
        const SizedBox(height: 12),
        Text('SpendLens',
            style: TextStyle(
                color: context.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── Reusable text field ─────────────────────────────────────────────────────────

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          textCapitalization: textCapitalization,
          style: TextStyle(color: context.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.textMuted),
            filled: true,
            fillColor: context.cardColor,
            prefixIcon: Icon(icon, size: 20, color: context.textSecondary),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: context.textSecondary),
                    onPressed: onToggleObscure,
                  )
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.cardBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Gradient primary button ─────────────────────────────────────────────────────

class GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientMid],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.gradientStart.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Demo button ──────────────────────────────────────────────────────────────

class DemoButton extends StatelessWidget {
  final VoidCallback onPressed;
  const DemoButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🧪', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text('Try Demo — Explore with Sample Data',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('150+ transactions · All features unlocked · No login',
            style: TextStyle(color: context.textMuted, fontSize: 11)),
      ],
    );
  }
}
