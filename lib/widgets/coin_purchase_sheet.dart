import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/iap_constants.dart';
import '../core/navigation/app_navigator.dart';
import '../core/services/iap_config_service.dart';
import '../providers/auth_provider.dart';
import '../providers/shop_provider.dart';
import '../screens/auth/auth_screen.dart';
import 'app_toast.dart';

class CoinPurchaseSheet {
  static Future<void> show(BuildContext context) async {
    final shop = context.read<ShopProvider>();
    if (shop.isBillingDisabled) {
      AppToast.show(
        context,
        title: AppStrings.t(context, 'billingDisabled'),
        icon: Icons.info_outline,
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => const _CoinPurchaseSheet(),
    );
    if (context.mounted) shop.abortPurchase();
  }
}

class _CoinPurchaseSheet extends StatelessWidget {
  const _CoinPurchaseSheet();

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final auth = context.watch<AuthProvider>();
    final products = shop.billing.products;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.t(context, 'buyCoins'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Text(
                AppStrings.t(context, 'buyCoinsDesc'),
                style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.warning, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.t(context, 'yourCoins', {'count': shop.coins.toString()}),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (!auth.isLoggedIn) ...[
                const SizedBox(height: 10),
                _StatusBanner(
                  icon: Icons.person_outline_rounded,
                  text: AppStrings.t(context, 'accountShopHint'),
                  color: context.brand,
                  onTap: () {
                    Navigator.pop(context);
                    rootNavigatorKey.currentState?.push(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  },
                ),
              ],
              if (shop.configStatus == IapConfigStatus.networkError ||
                  shop.configStatus == IapConfigStatus.timeout) ...[
                const SizedBox(height: 10),
                _StatusBanner(
                  icon: Icons.wifi_off_outlined,
                  text: AppStrings.t(context, 'configNetworkError'),
                  color: AppColors.warning,
                ),
              ],
              if (shop.isPurchasing) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: 8),
                Text(
                  AppStrings.t(context, 'processingPurchase'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                ),
              ],
              if (!shop.billing.isAvailable) ...[
                const SizedBox(height: 16),
                _StatusBanner(
                  icon: Icons.storefront_outlined,
                  text: AppStrings.t(context, 'billingUnavailable'),
                  color: AppColors.onSurfaceVariant,
                ),
              ] else if (products.isEmpty) ...[
                const SizedBox(height: 16),
                _StatusBanner(
                  icon: Icons.inventory_2_outlined,
                  text: AppStrings.t(context, 'productsNotFound'),
                  color: AppColors.onSurfaceVariant,
                ),
              ] else ...[
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) => _PackTile(product: products[i]),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                AppStrings.t(context, 'earnCoinsHint'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackTile extends StatelessWidget {
  final ProductDetails product;

  const _PackTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final coins = IapConstants.coinsForProduct(product.id);
    final packNum = IapConstants.coinPackIds.indexOf(product.id) + 1;

    return Material(
      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: shop.isPurchasing ? null : () => _buy(context, shop),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star_rounded, color: AppColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t(context, 'coinPack', {'num': packNum.toString()}),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Text(
                      AppStrings.t(context, 'coinAmount', {'count': coins.toString()}),
                      style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: shop.isPurchasing ? null : () => _buy(context, shop),
                child: Text(product.price),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _buy(BuildContext context, ShopProvider shop) async {
    final ok = await shop.buyCoinPack(product);
    if (!context.mounted) return;
    if (ok) {
      AppToast.show(context, title: AppStrings.t(context, 'openingBilling'));
    } else if (shop.lastMessage != null) {
      AppToast.show(context, title: AppStrings.t(context, shop.lastMessage!));
    }
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback? onTap;

  const _StatusBanner({
    required this.icon,
    required this.text,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13))),
              if (onTap != null) Icon(Icons.chevron_right_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
