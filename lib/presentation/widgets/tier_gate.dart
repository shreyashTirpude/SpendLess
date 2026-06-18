import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/subscription_tier.dart';
import '../providers/subscription_provider.dart';

/// Wraps any [child] widget and blurs/dims it with a lock overlay when the
/// current subscription tier does not satisfy [hasAccess].
///
/// Example:
/// ```dart
/// TierGate(
///   hasAccess: (tier) => tier.hasChatbot,
///   featureName: 'AI Chatbot',
///   lockedMessage: 'Available on Pro and above',
///   child: ChatbotWidget(),
/// )
/// ```
class TierGate extends ConsumerWidget {
  final Widget child;
  final bool Function(SubscriptionTier) hasAccess;
  final String featureName;
  final String lockedMessage;

  const TierGate({
    super.key,
    required this.child,
    required this.hasAccess,
    required this.featureName,
    this.lockedMessage = 'Upgrade to unlock this feature',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(subscriptionTierProvider);
    final allowed = hasAccess(tier);

    if (allowed) return child;

    return _LockedOverlay(
      featureName: featureName,
      lockedMessage: lockedMessage,
      child: child,
    );
  }
}

// ── Private locked overlay ─────────────────────────────────────────────────────

class _LockedOverlay extends StatelessWidget {
  final Widget child;
  final String featureName;
  final String lockedMessage;

  const _LockedOverlay({
    required this.child,
    required this.featureName,
    required this.lockedMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Blurred / dimmed child ─────────────────────────────────────
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              AppColors.background.withValues(alpha: 0.45),
              BlendMode.srcOver,
            ),
            child: IgnorePointer(child: child),
          ),
        ),

        // ── Lock overlay ───────────────────────────────────────────────
        Positioned.fill(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lock icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.gradientStart, AppColors.gradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    featureName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    lockedMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Upgrade button → /paywall
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/paywall'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Upgrade to unlock',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
