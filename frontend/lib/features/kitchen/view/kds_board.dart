import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/features/kitchen/bloc/kitchen_bloc.dart';
import 'package:mynix_frontend/features/kitchen/bloc/kitchen_event.dart';
import 'package:mynix_frontend/features/kitchen/bloc/kitchen_state.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_state.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';

class KdsBoard extends StatefulWidget {
  const KdsBoard({super.key});

  @override
  State<KdsBoard> createState() => _KdsBoardState();
}

class _KdsBoardState extends State<KdsBoard> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<KitchenBloc>().add(ConnectKitchen(authState.tenantId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocBuilder<KitchenBloc, KitchenState>(
      builder: (context, state) {
        int activeCount = 0;
        List<Map<String, dynamic>> orders = [];
        bool isConnected = false;

        if (state is KitchenLoaded) {
          activeCount = state.orders.length;
          orders = state.orders;
          isConnected = state.isConnected;
        }

        return Container(
          color: isDark ? AppColors.darkBg : AppColors.lightBg,
          child: Column(
            children: [
              // Premium KDS Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 16,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      children: [
                        Text(
                          'КУХНЯ: ЗАКАЗЫ',
                          style: AppTextStyles.h1.copyWith(
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isConnected ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isConnected ? PhosphorIconsRegular.wifiHigh : PhosphorIconsRegular.wifiSlash,
                            color: isConnected ? AppColors.success : AppColors.danger,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            PhosphorIconsRegular.arrowsClockwise, 
                            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          ),
                          onPressed: () {
                            context.read<KitchenBloc>().add(FetchActiveOrders());
                          },
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '$activeCount Активных',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // KDS Orders Grid
              if (state is KitchenLoading)
                Expanded(child: Center(child: CircularProgressIndicator()))
              else if (orders.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      "Нет активных заказов", 
                      style: AppTextStyles.h2.copyWith(
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 380,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _KdsOrderCard(order: order, isDark: isDark);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _KdsOrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final bool isDark;

  const _KdsOrderCard({required this.order, required this.isDark});

  @override
  State<_KdsOrderCard> createState() => _KdsOrderCardState();
}

class _KdsOrderCardState extends State<_KdsOrderCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final orderId = widget.order['id'];
    final status = widget.order['status'];
    final items = widget.order['items'] as List<dynamic>? ?? [];
    final isNew = status == 'new';
    
    // Status color (Red neon for new, Brand Amber for cooking)
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
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order Header (Sleek Glassmorphism instead of solid block)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18.5)),
                  border: Border(
                    bottom: BorderSide(
                      color: statusColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${widget.order['order_number'] ?? orderId}',
                      style: AppTextStyles.h1.copyWith(
                        color: widget.isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    // Neon Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        status.toString().toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Order Items
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
                    final item = items[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item['quantity']}x',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['menu_item_name'] ?? 'Item',
                                style: AppTextStyles.h2.copyWith(
                                  color: widget.isDark ? AppColors.darkText : AppColors.lightText,
                                  height: 1.3,
                                ),
                              ),
                              if (item['selected_options'] != null)
                                ...(() {
                                  try {
                                    final options = item['selected_options'] as Map;
                                    final List<String> parts = [];
                                    if (options['variation'] != null) parts.add(options['variation'].toString());
                                    if (options['modifiers'] != null) {
                                      for (var m in (options['modifiers'] as List)) {
                                        parts.add(m['name'].toString());
                                      }
                                    }
                                    if (parts.isEmpty) return <Widget>[];
                                    return [
                                      const SizedBox(height: 4),
                                      Text(
                                        parts.join(', '),
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.brandPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    ];
                                  } catch (e) {
                                    return <Widget>[
                                      Text('Err: $e', style: const TextStyle(color: Colors.red, fontSize: 10))
                                    ];
                                  }
                                })(),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Action Button (Premium Ready Button)
              Padding(
                padding: const EdgeInsets.all(20),
                child: _ReadyButton(orderId: orderId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadyButton extends StatefulWidget {
  final dynamic orderId;

  const _ReadyButton({required this.orderId});

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
          context.read<KitchenBloc>().add(MarkOrderReady(widget.orderId));
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
              )
            ] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            'ГОТОВО',
            style: AppTextStyles.buttonLarge.copyWith(
              color: _isHovered ? Colors.white : AppColors.success,
            ),
          ),
        ),
      ),
    );
  }
}
