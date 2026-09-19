import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/kitchen/bloc/kitchen_bloc.dart';
import 'package:kreso_frontend/features/kitchen/bloc/kitchen_event.dart';
import 'package:kreso_frontend/core/theme/app_colors.dart';
import 'package:kreso_frontend/core/theme/app_text_styles.dart';
import 'package:kreso_frontend/core/widgets/app_toast.dart';
import 'kds/kds_card_header.dart';
import 'kds/kds_item_row.dart';

class KdsOrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final bool isDark;

  const KdsOrderCard({super.key, required this.order, required this.isDark});

  @override
  State<KdsOrderCard> createState() => _KdsOrderCardState();
}

class _KdsOrderCardState extends State<KdsOrderCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final orderId = widget.order['id'];
    final status = widget.order['status'];
    final items = widget.order['items'] as List<dynamic>? ?? [];
    final isNew = status == 'new';
    final statusColor = isNew ? AppColors.danger : AppColors.brandPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withValues(alpha: _isHovered ? 0.6 : 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: _isHovered ? 0.15 : 0.05),
                blurRadius: _isHovered ? 24 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KdsCardHeader(
                orderNumber: widget.order['order_number'],
                orderId: orderId,
                tableNumber: widget.order['table_number']?.toString(),
                status: status.toString(),
                statusColor: statusColor,
                isDark: widget.isDark,
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  itemBuilder: (context, index) {
                    return KdsItemRow(
                      item: items[index],
                      isDark: widget.isDark,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: _ReadyButton(order: widget.order),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadyButton extends StatefulWidget {
  final Map<String, dynamic> order;

  const _ReadyButton({required this.order});

  @override
  State<_ReadyButton> createState() => _ReadyButtonState();
}

class _ReadyButtonState extends State<_ReadyButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          final kitchenBloc = context.read<KitchenBloc>();
          final order = widget.order;
          final orderId = order['id'] as int;
          final orderNum = order['order_number'] ?? orderId;

          kitchenBloc.add(MarkOrderReady(orderId));

          AppToast.showUndo(
            context,
            message: 'Заказ #$orderNum передан на выдачу',
            onUndo: () => kitchenBloc.add(UndoOrderReady(order)),
            duration: const Duration(seconds: 5),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _isHovered 
                ? AppColors.success 
                : AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.success.withValues(alpha: _isHovered ? 1.0 : 0.5),
              width: 1.5,
            ),
            boxShadow: _isHovered ? [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            'ГОТОВО',
            style: AppTextStyles.buttonLarge.copyWith(
              color: _isHovered ? AppColors.white : AppColors.success,
            ),
          ),
        ),
      ),
    );
  }
}
