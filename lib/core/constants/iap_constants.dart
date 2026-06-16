class IapConstants {
  IapConstants._();

  static const String productPrefix = 'rd';

  static const String remoteConfigUrl = 'https://api2.blwsmartware.net/R217.json';

  static const Duration configTimeout = Duration(seconds: 10);

  static const List<String> coinPackIds = [
    'rd_pack_1',
    'rd_pack_2',
    'rd_pack_3',
    'rd_pack_4',
    'rd_pack_5',
    'rd_pack_6',
    'rd_pack_7',
    'rd_pack_8',
    'rd_pack_9',
    'rd_pack_10',
  ];

  static const String removeAdsProductId = 'rd_remove_ads';

  static List<String> get allProductIds => [...coinPackIds, removeAdsProductId];

  static const List<int> coinPackAmounts = [
    50,
    100,
    200,
    350,
    500,
    750,
    1000,
    1500,
    2200,
    3000,
  ];

  static int coinsForProduct(String productId) {
    final index = coinPackIds.indexOf(productId);
    if (index < 0) return 0;
    return coinPackAmounts[index];
  }

  static bool isRemoveAdsProduct(String productId) => productId == removeAdsProductId;

  static const int freeChoiceLimit = 8;
  static const int dailyLoginReward = 10;
  static const int spinReward = 3;
  static const int maxSpinRewardsPerDay = 10;
  static const int addChoiceReward = 2;
  static const int maxAddChoiceRewardsPerDay = 5;
  static const int shareResultReward = 5;
  static const int maxShareRewardsPerDay = 3;
}
