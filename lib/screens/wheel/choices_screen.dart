import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/iap_constants.dart';
import '../../models/wheel_option.dart';
import '../../providers/shop_provider.dart';
import '../../providers/wheel_provider.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/coin_balance_chip.dart';
import '../main_shell.dart';

class ChoicesScreen extends StatefulWidget {
  const ChoicesScreen({super.key});

  @override
  State<ChoicesScreen> createState() => _ChoicesScreenState();
}

class _ChoicesScreenState extends State<ChoicesScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addChoice() async {
    final wheel = context.read<WheelProvider>();
    final shop = context.read<ShopProvider>();
    final unlimited = shop.hasUnlimitedChoices;

    if (!wheel.canAddMore(unlimited)) {
      AppToast.show(
        context,
        title: AppStrings.t(context, 'choiceLimitReached'),
        message: AppStrings.t(context, 'choiceLimitInfo', {
          'max': '${IapConstants.freeChoiceLimit}',
        }),
        icon: Icons.lock_outline,
        color: AppColors.warning,
      );
      MainShell.of(context)?.openShop();
      return;
    }

    final ok = await wheel.addOption(_controller.text, unlimited: unlimited);
    if (!mounted) return;
    if (ok) {
      _controller.clear();
      final rewarded = await shop.rewardForAddChoice();
      if (rewarded && mounted) {
        AppToast.show(
          context,
          title: AppStrings.t(context, 'addChoiceRewardEarned', {'amount': '${IapConstants.addChoiceReward}'}),
          icon: Icons.star_rounded,
          color: AppColors.coin,
        );
      }
    }
  }

  Future<void> _exportChoices() async {
    final shop = context.read<ShopProvider>();
    if (!shop.hasExportLists) {
      MainShell.of(context)?.openShop();
      return;
    }
    final wheel = context.read<WheelProvider>();
    final text = wheel.options.map((o) => o.label).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    AppToast.show(context, title: AppStrings.t(context, 'exportSuccess'));
  }

  @override
  Widget build(BuildContext context) {
    final wheel = context.watch<WheelProvider>();
    final shop = context.watch<ShopProvider>();
    final unlimited = shop.hasUnlimitedChoices;
    final max = wheel.maxChoices(unlimited);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppStrings.t(context, 'choicesTitle')),
        actions: [
          if (shop.hasExportLists)
            IconButton(onPressed: _exportChoices, icon: const Icon(Icons.file_download_outlined)),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CoinBalanceChip(onTap: () => MainShell.of(context)?.openShop()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addChoice(),
                    decoration: InputDecoration(
                      hintText: AppStrings.t(context, 'choiceHint'),
                      prefixIcon: const Icon(Icons.add_circle_outline),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _addChoice, child: Text(AppStrings.t(context, 'addChoice'))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppStrings.t(context, 'choiceLimitInfo', {
                  'current': '${wheel.options.length}',
                  'max': '$max',
                }),
                style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wheel.options.length,
              onReorder: wheel.reorder,
              itemBuilder: (context, index) {
                final option = wheel.options[index];
                return _ChoiceTile(
                  key: ValueKey(option.id),
                  index: index,
                  label: option.label,
                  canDelete: wheel.options.length > 2,
                  onEdit: (value) => wheel.updateOption(option.id, value),
                  onDelete: () => wheel.removeOption(option.id),
                );
              },
            ),
          ),
          if (shop.hasSpinHistory && wheel.history.isNotEmpty)
            _HistoryPanel(history: wheel.history, onClear: wheel.clearHistory),        ],
      ),
    );
  }
}

class _ChoiceTile extends StatefulWidget {
  final int index;
  final String label;
  final bool canDelete;
  final ValueChanged<String> onEdit;
  final VoidCallback onDelete;

  const _ChoiceTile({
    super.key,
    required this.index,
    required this.label,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ChoiceTile> createState() => _ChoiceTileState();
}

class _ChoiceTileState extends State<_ChoiceTile> {
  late final TextEditingController _editCtrl;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController(text: widget.label);
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _ChoiceTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label && widget.label != _editCtrl.text) {
      _editCtrl.value = _editCtrl.value.copyWith(
        text: widget.label,
        selection: TextSelection.collapsed(offset: widget.label.length),
      );
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _commit();
  }

  void _commit() {
    final value = _editCtrl.text.trim();
    if (value.isEmpty) {
      _editCtrl.text = widget.label;
      return;
    }
    if (value != widget.label) {
      widget.onEdit(value);
    }
  }

  @override
  void dispose() {
    _commit();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _editCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: widget.index,
          child: const Icon(Icons.drag_handle_rounded, color: AppColors.onSurfaceVariant),
        ),
        title: TextField(
          controller: _editCtrl,
          focusNode: _focusNode,
          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
          textInputAction: TextInputAction.done,
          onChanged: (value) {
            if (value.trim().isNotEmpty && value != widget.label) {
              widget.onEdit(value);
            }
          },
          onSubmitted: (_) => _commit(),
          onEditingComplete: _commit,
        ),
        trailing: widget.canDelete
            ? IconButton(onPressed: widget.onDelete, icon: const Icon(Icons.delete_outline, color: AppColors.error))
            : null,
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  final List<SpinResult> history;
  final VoidCallback onClear;

  const _HistoryPanel({required this.history, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(AppStrings.t(context, 'spinHistory'), style: const TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(onPressed: onClear, child: Text(AppStrings.t(context, 'clearHistory'))),
            ],
          ),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: history.length.clamp(0, 20),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final item = history[i];
                return Chip(label: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w700)));
              },
            ),
          ),
        ],
      ),
    );
  }
}
