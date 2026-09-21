import 'package:flutter_test/flutter_test.dart';
import 'package:random_decision/core/constants/ad_constants.dart';

void main() {
  test('Android uses a valid AdMob app ID and banner unit', () {
    expect(AdConstants.androidAppId, 'ca-app-pub-1023100218618748~2563462380');
    expect(AdConstants.androidBannerId, 'ca-app-pub-1023100218618748/2276430038');
    expect(AdConstants.androidAppId.contains('3940256099942544'), isFalse);
    expect(AdConstants.isConfigured, isTrue);
    expect(AdConstants.bannerHeight, 50);
  });
}
