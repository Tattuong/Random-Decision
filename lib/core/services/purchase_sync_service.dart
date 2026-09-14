import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../models/auth_models.dart';
import '../constants/api_constants.dart';
import 'api_client.dart';
import 'platform_api_service.dart';
import 'storage_service.dart';

class PurchaseSyncService {
  static final PurchaseSyncService instance = PurchaseSyncService._();
  PurchaseSyncService._();

  Future<void> enqueueAndSync(PurchaseDetails purchase) async {
    final item = fromPurchaseDetails(purchase);
    if (item.transactionId.isEmpty || item.productId.isEmpty) return;
    await _upsert(item);
    await sync();
  }

  Future<void> sync() async {
    if (!await ApiClient.instance.hasSession) {
      debugPrint(
        'Purchase verify skipped: not logged in. '
        'Sign in to POST ${ApiConstants.baseUrl}/purchase/verify',
      );
      return;
    }

    final pending = await _load();
    if (pending.isEmpty) return;

    final remaining = <PendingPurchaseVerify>[];
    for (var i = 0; i < pending.length; i++) {
      final item = pending[i];
      try {
        debugPrint(
          'POST /purchase/verify gameCode=${ApiConstants.gameCode} '
          'productId=${item.productId} txn=${item.transactionId} '
          'platform=${item.platform}',
        );
        await PlatformApiService.instance.verifyPurchase(item);
        debugPrint('Purchase verify OK: ${item.productId}');
      } on ApiException catch (e) {
        debugPrint('Purchase verify failed [${e.statusCode}]: ${e.message}');
        if (e.isConflict) {
          continue;
        }
        if (e.isUnauthorized) {
          remaining.addAll(pending.sublist(i));
          break;
        }
        remaining.add(item);
      } catch (e) {
        debugPrint('Purchase verify failed: $e');
        remaining.add(item);
      }
    }

    await _save(remaining);
  }

  static PendingPurchaseVerify fromPurchaseDetails(PurchaseDetails purchase) {
    final transactionId = purchase.purchaseID?.trim().isNotEmpty == true
        ? purchase.purchaseID!
        : '${purchase.productID}_${purchase.transactionDate ?? DateTime.now().millisecondsSinceEpoch}';

    return PendingPurchaseVerify(
      productId: purchase.productID,
      transactionId: transactionId,
      platform: Platform.isIOS ? 'IOS' : 'ANDROID',
      receiptData: purchase.verificationData.serverVerificationData,
    );
  }

  Future<List<PendingPurchaseVerify>> _load() async {
    final raw = await StorageService.instance.getString(ApiConstants.pendingVerifyKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(PendingPurchaseVerify.fromJson)
          .where((e) => e.transactionId.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _upsert(PendingPurchaseVerify item) async {
    final items = await _load();
    items.removeWhere((e) => e.transactionId == item.transactionId);
    items.add(item);
    await _save(items);
  }

  Future<void> _save(List<PendingPurchaseVerify> items) async {
    if (items.isEmpty) {
      await StorageService.instance.remove(ApiConstants.pendingVerifyKey);
      return;
    }
    await StorageService.instance.saveString(
      ApiConstants.pendingVerifyKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}
