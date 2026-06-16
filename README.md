# Random Decision

Spin-the-wheel decision app for Android & iOS — built with Flutter.

## Features

- **Vòng quay** — Nhập lựa chọn, quay vòng quay đẹp mắt
- **Cửa hàng** — Kiếm sao hoặc mua gói Google Play, unlock theme / skin / tính năng
- **IAP remote config** — `https://api2.blwsmartware.net/R211.json` (`disable=1` tắt Google Billing, shop sao vẫn hoạt động)

## Google Play IAP product IDs

- Coin packs (consumable): `rd_pack_1` … `rd_pack_10`
- Remove ads (non-consumable): `rd_remove_ads`

## Package

`com.randomdecision.app`

## Build release

```bash
flutter pub get
flutter build appbundle --release
```

## Assets

- Logo: `assets/logo.png` (1024×1024, square)
- IAP config sample: `docs/R211.json`
- Privacy policy: `docs/privacy_policy.html`
