import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/constants/iap_constants.dart';
import '../core/services/billing_service.dart';
import '../core/services/iap_config_service.dart';
import '../core/services/purchase_sync_service.dart';
import '../core/services/storage_service.dart';
import '../models/app_theme_preset.dart';
import '../models/shop_coin_event.dart';
import '../models/shop_item.dart';

enum ShopPurchaseResult {
  success,
  insufficientCoins,
  alreadyOwned,
  notFound,
  error,
}

class ShopProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const _coinsKey = 'rd_coins';
  static const _ownedKey = 'rd_owned_items';
  static const _activeThemeKey = 'rd_active_theme';
  static const _activeBgKey = 'rd_active_background';
  static const _activeSkinKey = 'rd_active_skin';
  static const _lastDailyKey = 'rd_last_daily_reward';
  static const _spinRewardDateKey = 'rd_shop_spin_reward_date';
  static const _spinRewardCountKey = 'rd_shop_spin_reward_count';
  static const _addChoiceRewardDateKey = 'rd_shop_add_choice_reward_date';
  static const _addChoiceRewardCountKey = 'rd_shop_add_choice_reward_count';
  static const _shareRewardDateKey = 'rd_share_reward_date';
  static const _shareRewardCountKey = 'rd_share_reward_count';
  static const _processedPurchasesKey = 'rd_processed_purchases';

  final IapConfigService _configService = IapConfigService();
  final BillingService _billing = BillingService();

  int _coins = 0;
  Set<String> _ownedItems = {};
  String _activeThemeId = ShopCatalog.defaultThemeId;
  String _activeBackgroundId = ShopCatalog.defaultBackgroundId;
  String _activeSkinId = ShopCatalog.defaultSkinId;
  bool _isPurchasing = false;
  bool _isLoading = true;
  String? _lastMessage;
  Set<String> _processedPurchaseIds = {};
  ShopCoinEvent? _lastCoinEvent;
  Timer? _purchaseWatchdog;

  int get coins => _coins;
  Set<String> get ownedItems => _ownedItems;
  String get activeThemeId => _activeThemeId;
  String get activeBackgroundId => _activeBackgroundId;
  String get activeSkinId => _activeSkinId;
  bool get isPurchasing => _isPurchasing;
  bool get isLoading => _isLoading;
  String? get lastMessage => _lastMessage;
  ShopCoinEvent? get lastCoinEvent => _lastCoinEvent;
  IapConfigService get configService => _configService;
  BillingService get billing => _billing;

  bool get isBillingDisabled => _configService.isBillingDisabled;
  bool get isBillingAvailable =>
      !isBillingDisabled && _billing.isAvailable && _billing.products.isNotEmpty;
  IapConfigStatus get configStatus => _configService.status;

  bool get hasRemoveAds => _ownedItems.contains('remove_ads');
  bool get hasUnlimitedChoices => _ownedItems.contains('feat_unlimited_choices');
  bool get hasWeightedSpin => _ownedItems.contains('feat_weighted_spin');
  bool get hasSoundEffects => _ownedItems.contains('feat_sound_effects');
  bool get hasSpinHistory => _ownedItems.contains('feat_spin_history');
  bool get hasExportLists => _ownedItems.contains('feat_export_lists');
  bool get hasCustomColors => _ownedItems.contains('feat_custom_colors');
  bool get hasNoWatermark => _ownedItems.contains('feat_no_watermark');

  AppThemePreset get activeTheme => AppThemePresets.get(_activeThemeId);
  WheelBackground get activeBackground => WheelBackground.get(_activeBackgroundId);
  WheelStyle get activeWheelStyle => WheelStyle.get(_activeSkinId);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(this);
    await _loadLocal();
    await _configService.fetch();

    if (!isBillingDisabled && (Platform.isAndroid || Platform.isIOS)) {
      await _billing.init(
        onPurchase: _handlePurchase,
        onError: abortPurchase,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshConfig() async {
    await _configService.fetch(forceRefresh: true);
    notifyListeners();
  }

  Future<void> _loadLocal() async {
    _coins = await StorageService.instance.getInt(_coinsKey) ?? 0;
    final owned = await StorageService.instance.getStringList(_ownedKey);
    _ownedItems = owned?.toSet() ?? {};
    _activeThemeId =
        await StorageService.instance.getString(_activeThemeKey) ?? ShopCatalog.defaultThemeId;
    _activeBackgroundId =
        await StorageService.instance.getString(_activeBgKey) ?? ShopCatalog.defaultBackgroundId;
    _activeSkinId =
        await StorageService.instance.getString(_activeSkinKey) ?? ShopCatalog.defaultSkinId;
    final processed = await StorageService.instance.getStringList(_processedPurchasesKey);
    _processedPurchaseIds = processed?.toSet() ?? {};
  }

  Future<void> _saveLocal() async {
    await StorageService.instance.saveInt(_coinsKey, _coins);
    await StorageService.instance.saveStringList(_ownedKey, _ownedItems.toList());
    await StorageService.instance.saveString(_activeThemeKey, _activeThemeId);
    await StorageService.instance.saveString(_activeBgKey, _activeBackgroundId);
    await StorageService.instance.saveString(_activeSkinKey, _activeSkinId);
    await StorageService.instance.saveStringList(_processedPurchasesKey, _processedPurchaseIds.toList());
  }

  bool ownsItem(String id) => _ownedItems.contains(id);

  ShopPurchaseResult buyWithCoins(String itemId) {
    final item = ShopCatalog.find(itemId);
    if (item == null) return ShopPurchaseResult.notFound;
    if (item.oneTime && _ownedItems.contains(itemId)) {
      return ShopPurchaseResult.alreadyOwned;
    }
    if (_coins < item.price) return ShopPurchaseResult.insufficientCoins;

    _coins -= item.price;
    _ownedItems.add(itemId);
    _applyItem(item);
    _lastMessage = 'purchaseSuccess';
    _saveLocal();
    notifyListeners();
    return ShopPurchaseResult.success;
  }

  void _applyItem(ShopItem item) {
    switch (item.type) {
      case ShopItemType.theme:
        _activeThemeId = item.id;
      case ShopItemType.background:
        _activeBackgroundId = item.id;
      case ShopItemType.skin:
        _activeSkinId = item.id;
      case ShopItemType.removeAds:
      case ShopItemType.feature:
        break;
    }
  }

  Future<bool> buyCoinPack(ProductDetails product) async {
    if (isBillingDisabled || !_billing.isAvailable) return false;
    _beginPurchaseUi();
    final ok = await _billing.buyCoinPack(product);
    if (!ok) {
      abortPurchase();
      _lastMessage = 'purchaseFailed';
      notifyListeners();
    }
    return ok;
  }

  Future<bool> buyRemoveAdsViaBilling() async {
    if (isBillingDisabled || !_billing.isAvailable || _billing.removeAdsProduct == null) {
      return false;
    }
    if (hasRemoveAds) return false;
    _beginPurchaseUi();
    final ok = await _billing.buyRemoveAds();
    if (!ok) {
      abortPurchase();
      _lastMessage = 'purchaseFailed';
      notifyListeners();
    }
    return ok;
  }

  void _beginPurchaseUi() {
    _isPurchasing = true;
    _lastMessage = null;
    _purchaseWatchdog?.cancel();
    notifyListeners();
  }

  void abortPurchase() {
    _purchaseWatchdog?.cancel();
    _purchaseWatchdog = null;
    if (!_isPurchasing) return;
    _isPurchasing = false;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_isPurchasing) return;
    // Play Billing overlay closed without a stream event on some devices.
    _purchaseWatchdog?.cancel();
    _purchaseWatchdog = Timer(const Duration(milliseconds: 1200), abortPurchase);
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    _purchaseWatchdog?.cancel();
    _purchaseWatchdog = null;

    final purchaseId = purchase.purchaseID ?? '${purchase.productID}_${purchase.transactionDate}';
    if (_processedPurchaseIds.contains(purchaseId)) {
      _isPurchasing = false;
      notifyListeners();
      return;
    }

    if (IapConstants.isRemoveAdsProduct(purchase.productID)) {
      _ownedItems.add('remove_ads');
      _processedPurchaseIds.add(purchaseId);
      _lastMessage = 'removeAdsUnlocked';
    } else {
      final coins = IapConstants.coinsForProduct(purchase.productID);
      if (coins > 0) {
        _coins += coins;
        _processedPurchaseIds.add(purchaseId);
        _lastMessage = 'coinsAdded';
        _emitCoinEarned(coins, 'coinsAdded');
      }
    }

    _isPurchasing = false;
    await _saveLocal();
    notifyListeners();
    await PurchaseSyncService.instance.enqueueAndSync(purchase);
  }

  Future<void> syncPendingPurchases() => PurchaseSyncService.instance.sync();

  Future<bool> claimDailyReward() async {
    final today = _dateKey(DateTime.now());
    final last = await StorageService.instance.getString(_lastDailyKey);
    if (last == today) return false;

    const amount = IapConstants.dailyLoginReward;
    _coins += amount;
    await StorageService.instance.saveString(_lastDailyKey, today);
    _lastMessage = 'dailyRewardClaimed';
    _emitCoinEarned(amount, 'dailyRewardClaimed');
    await _saveLocal();
    notifyListeners();
    return true;
  }

  Future<bool> hasClaimedDailyToday() async {
    final today = _dateKey(DateTime.now());
    final last = await StorageService.instance.getString(_lastDailyKey);
    return last == today;
  }

  Future<bool> rewardForSpin() async {
    final today = _dateKey(DateTime.now());
    final savedDate = await StorageService.instance.getString(_spinRewardDateKey);
    var count = await StorageService.instance.getInt(_spinRewardCountKey) ?? 0;

    if (savedDate != today) {
      count = 0;
      await StorageService.instance.saveString(_spinRewardDateKey, today);
    }

    if (count >= IapConstants.maxSpinRewardsPerDay) return false;

    const amount = IapConstants.spinReward;
    _coins += amount;
    count++;
    await StorageService.instance.saveInt(_spinRewardCountKey, count);
    _emitCoinEarned(amount, 'spinRewardEarned');
    await _saveLocal();
    notifyListeners();
    return true;
  }

  Future<bool> rewardForAddChoice() async {
    final today = _dateKey(DateTime.now());
    final savedDate = await StorageService.instance.getString(_addChoiceRewardDateKey);
    var count = await StorageService.instance.getInt(_addChoiceRewardCountKey) ?? 0;

    if (savedDate != today) {
      count = 0;
      await StorageService.instance.saveString(_addChoiceRewardDateKey, today);
    }

    if (count >= IapConstants.maxAddChoiceRewardsPerDay) return false;

    const amount = IapConstants.addChoiceReward;
    _coins += amount;
    count++;
    await StorageService.instance.saveInt(_addChoiceRewardCountKey, count);
    _emitCoinEarned(amount, 'addChoiceRewardEarned');
    await _saveLocal();
    notifyListeners();
    return true;
  }

  Future<bool> rewardForShare() async {
    final today = _dateKey(DateTime.now());
    final savedDate = await StorageService.instance.getString(_shareRewardDateKey);
    var count = await StorageService.instance.getInt(_shareRewardCountKey) ?? 0;

    if (savedDate != today) {
      count = 0;
      await StorageService.instance.saveString(_shareRewardDateKey, today);
    }

    if (count >= IapConstants.maxShareRewardsPerDay) return false;

    const amount = IapConstants.shareResultReward;
    _coins += amount;
    count++;
    await StorageService.instance.saveInt(_shareRewardCountKey, count);
    _emitCoinEarned(amount, 'shareRewardEarned');
    await _saveLocal();
    notifyListeners();
    return true;
  }

  Future<void> selectTheme(String themeId) async {
    if (themeId != ShopCatalog.defaultThemeId && !_ownedItems.contains(themeId)) return;
    _activeThemeId = themeId;
    await _saveLocal();
    notifyListeners();
  }

  Future<void> selectBackground(String bgId) async {
    if (bgId != ShopCatalog.defaultBackgroundId && !_ownedItems.contains(bgId)) return;
    _activeBackgroundId = bgId;
    await _saveLocal();
    notifyListeners();
  }

  Future<void> selectSkin(String skinId) async {
    if (skinId != ShopCatalog.defaultSkinId && !_ownedItems.contains(skinId)) return;
    _activeSkinId = skinId;
    await _saveLocal();
    notifyListeners();
  }

  Future<void> resetThemeToDefault() => selectTheme(ShopCatalog.defaultThemeId);
  Future<void> resetBackgroundToDefault() => selectBackground(ShopCatalog.defaultBackgroundId);
  Future<void> resetSkinToDefault() => selectSkin(ShopCatalog.defaultSkinId);

  void clearLastMessage() => _lastMessage = null;
  void clearCoinEvent() => _lastCoinEvent = null;

  void _emitCoinEarned(int amount, String messageKey) {
    if (amount <= 0) return;
    _lastCoinEvent = ShopCoinEvent(amount: amount, messageKey: messageKey);
  }

  String _dateKey(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';

  @override
  void dispose() {
    _purchaseWatchdog?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _billing.dispose();
    super.dispose();
  }
}
