import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/iap_constants.dart';
import '../core/services/storage_service.dart';
import '../models/wheel_option.dart';

class WheelProvider extends ChangeNotifier {
  static const _optionsKey = 'rd_wheel_options';
  static const _historyKey = 'rd_spin_history';
  static const _spinRewardDateKey = 'rd_spin_reward_date';
  static const _spinRewardCountKey = 'rd_spin_reward_count';
  static const _addChoiceRewardDateKey = 'rd_add_choice_reward_date';
  static const _addChoiceRewardCountKey = 'rd_add_choice_reward_count';
  static const _shareRewardDateKey = 'rd_share_reward_date';
  static const _shareRewardCountKey = 'rd_share_reward_count';

  final _uuid = const Uuid();
  final Random _random = Random();

  List<WheelOption> _options = defaultWheelOptions();
  List<SpinResult> _history = [];
  bool _isSpinning = false;
  SpinResult? _lastResult;
  int? _pendingWinnerIndex;

  List<WheelOption> get options => List.unmodifiable(_options);
  List<SpinResult> get history => List.unmodifiable(_history);
  bool get isSpinning => _isSpinning;
  SpinResult? get lastResult => _lastResult;
  int? get pendingWinnerIndex => _pendingWinnerIndex;

  Future<void> load() async {
    final rawOptions = await StorageService.instance.getString(_optionsKey);
    _options = decodeWheelOptions(rawOptions);
    final rawHistory = await StorageService.instance.getString(_historyKey);
    _history = decodeSpinHistory(rawHistory);
    notifyListeners();
  }

  int maxChoices(bool unlimited) => unlimited ? 50 : IapConstants.freeChoiceLimit;

  bool canAddMore(bool unlimited) => _options.length < maxChoices(unlimited);

  Future<bool> addOption(String label, {bool unlimited = false}) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty || !canAddMore(unlimited)) return false;
    _options = [..._options, WheelOption(id: _uuid.v4(), label: trimmed)];
    await _saveOptions();
    notifyListeners();
    return true;
  }

  Future<void> updateOption(String id, String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;
    final index = _options.indexWhere((o) => o.id == id);
    if (index < 0 || _options[index].label == trimmed) return;
    _options = _options.map((o) => o.id == id ? o.copyWith(label: trimmed) : o).toList();
    await _saveOptions();
    notifyListeners();
  }

  Future<void> removeOption(String id) async {
    if (_options.length <= 2) return;
    _options = _options.where((o) => o.id != id).toList();
    await _saveOptions();
    notifyListeners();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _options.length) return;
    if (newIndex < 0 || newIndex >= _options.length) return;
    final list = [..._options];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _options = list;
    await _saveOptions();
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _options = defaultWheelOptions();
    await _saveOptions();
    notifyListeners();
  }

  int pickWinnerIndex({required bool weighted}) {
    if (_options.isEmpty) return 0;
    if (!weighted) return _random.nextInt(_options.length);

    final totalWeight = _options.fold<int>(0, (sum, o) => sum + o.weight.clamp(1, 99));
    var roll = _random.nextInt(totalWeight);
    for (var i = 0; i < _options.length; i++) {
      roll -= _options[i].weight.clamp(1, 99);
      if (roll < 0) return i;
    }
    return _options.length - 1;
  }

  void beginSpin({required bool weighted}) {
    if (_options.length < 2 || _isSpinning) return;
    _isSpinning = true;
    _pendingWinnerIndex = pickWinnerIndex(weighted: weighted);
    notifyListeners();
  }

  Future<SpinResult?> completeSpin() async {
    if (_pendingWinnerIndex == null || _options.isEmpty) {
      _isSpinning = false;
      notifyListeners();
      return null;
    }

    final winner = _options[_pendingWinnerIndex!];
    final result = SpinResult(optionId: winner.id, label: winner.label, at: DateTime.now());
    _lastResult = result;
    _history = [result, ..._history].take(100).toList();
    _isSpinning = false;
    _pendingWinnerIndex = null;
    await _saveHistory();
    notifyListeners();
    return result;
  }

  void cancelSpin() {
    _isSpinning = false;
    _pendingWinnerIndex = null;
    notifyListeners();
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
    count++;
    await StorageService.instance.saveInt(_spinRewardCountKey, count);
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
    count++;
    await StorageService.instance.saveInt(_addChoiceRewardCountKey, count);
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
    count++;
    await StorageService.instance.saveInt(_shareRewardCountKey, count);
    return true;
  }

  Future<void> clearHistory() async {
    _history = [];
    await _saveHistory();
    notifyListeners();
  }

  Future<void> _saveOptions() async {
    final json = jsonEncode(_options.map((o) => o.toJson()).toList());
    await StorageService.instance.saveString(_optionsKey, json);
  }

  Future<void> _saveHistory() async {
    final json = jsonEncode(_history.map((h) => h.toJson()).toList());
    await StorageService.instance.saveString(_historyKey, json);
  }

  String _dateKey(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';
}
