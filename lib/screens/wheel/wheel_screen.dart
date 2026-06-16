import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/iap_constants.dart';
import '../../providers/shop_provider.dart';
import '../../providers/wheel_provider.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/coin_balance_chip.dart';
import '../../widgets/spin_wheel.dart';
import '../main_shell.dart';

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen> {
  String? _resultLabel;

  Future<void> _spin() async {
    final wheel = context.read<WheelProvider>();
    final shop = context.read<ShopProvider>();

    if (wheel.options.length < 2) {
      AppToast.show(context, title: AppStrings.t(context, 'needMoreChoices'), icon: Icons.info_outline);
      return;
    }
    if (wheel.isSpinning) return;

    setState(() => _resultLabel = null);
    wheel.beginSpin(weighted: shop.hasWeightedSpin);

    if (shop.hasSoundEffects) {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _onSpinComplete() async {
    final wheel = context.read<WheelProvider>();
    final shop = context.read<ShopProvider>();
    final result = await wheel.completeSpin();
    if (!mounted || result == null) return;

    setState(() => _resultLabel = result.label);

    if (shop.hasSoundEffects) {
      HapticFeedback.mediumImpact();
    }

    final rewarded = await shop.rewardForSpin();
    if (rewarded && mounted) {
      AppToast.show(
        context,
        title: AppStrings.t(context, 'spinRewardEarned', {'amount': '${IapConstants.spinReward}'}),
        icon: Icons.star_rounded,
        color: AppColors.coin,
      );
    }
  }

  Future<void> _shareResult() async {
    final shop = context.read<ShopProvider>();
    if (_resultLabel == null) return;

    final text = shop.hasNoWatermark
        ? AppStrings.t(context, 'shareResultPlain', {'result': _resultLabel!})
        : AppStrings.t(context, 'shareResultBranded', {'result': _resultLabel!});

    await Share.share(text);
    await shop.rewardForShare();
  }

  void _dismissResult() => setState(() => _resultLabel = null);

  @override
  Widget build(BuildContext context) {
    final wheel = context.watch<WheelProvider>();
    final shop = context.watch<ShopProvider>();
    final bg = shop.activeBackground.gradient;
    final style = shop.activeWheelStyle;
    final labels = wheel.options.map((o) => o.label).toList();
    final hasResult = _resultLabel != null && !wheel.isSpinning;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bg),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.t(context, 'wheelTitle'),
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            AppStrings.t(context, 'wheelSubtitle'),
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    CoinBalanceChip(onTap: () => MainShell.of(context)?.openShop()),
                  ],
                ),
              ),
              if (!shop.hasRemoveAds)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      AppStrings.t(context, 'adPlaceholder'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wheelSize = (constraints.maxWidth * 0.82).clamp(240.0, 340.0);
                    return Center(
                      child: SpinWheel(
                        key: ValueKey(labels.join('|')),
                        labels: labels,
                        isSpinning: wheel.isSpinning,
                        targetIndex: wheel.pendingWinnerIndex,
                        style: style,
                        size: wheelSize,
                        onSpinComplete: _onSpinComplete,
                      ),
                    );
                  },
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: hasResult
                    ? _ResultFooter(
                        key: ValueKey(_resultLabel),
                        label: _resultLabel!,
                        onShare: _shareResult,
                        onSpinAgain: _spin,
                        onDismiss: _dismissResult,
                      )
                    : _SpinFooter(
                        key: const ValueKey('spin'),
                        isSpinning: wheel.isSpinning,
                        onSpin: _spin,
                      ),
              ),
              SizedBox(height: size.height < 700 ? 8 : 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpinFooter extends StatelessWidget {
  final bool isSpinning;
  final VoidCallback onSpin;

  const _SpinFooter({super.key, required this.isSpinning, required this.onSpin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          onPressed: isSpinning ? null : onSpin,
          icon: isSpinning
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.play_arrow_rounded, size: 28),
          label: Text(
            isSpinning ? AppStrings.t(context, 'spinning') : AppStrings.t(context, 'spinButton'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
    );
  }
}

class _ResultFooter extends StatelessWidget {
  final String label;
  final VoidCallback onShare;
  final VoidCallback onSpinAgain;
  final VoidCallback onDismiss;

  const _ResultFooter({
    super.key,
    required this.label,
    required this.onShare,
    required this.onSpinAgain,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.t(context, 'resultLabel'),
                        style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  tooltip: AppStrings.t(context, 'closeResult'),
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: Text(AppStrings.t(context, 'share')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onSpinAgain,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(AppStrings.t(context, 'spinAgain')),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
