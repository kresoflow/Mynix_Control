import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/features/inventory/bloc/receive_retail_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/receive_retail_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/receive_retail_state.dart';
import 'package:mynix_frontend/features/inventory/repository/inventory_repository.dart';
import 'widgets/receive_retail_item_widget.dart';

class ReceiveRetailScreen extends StatelessWidget {
  const ReceiveRetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ReceiveRetailBloc(context.read<InventoryRepository>())
            ..add(LoadRetailProducts()),
      child: const _ReceiveRetailView(),
    );
  }
}

class _ReceiveRetailView extends StatelessWidget {
  const _ReceiveRetailView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Массовая приемка витрины'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocListener<ReceiveRetailBloc, ReceiveRetailState>(
        listenWhen: (previous, current) =>
            previous.error != current.error ||
            previous.successMessage != current.successMessage,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        child: BlocBuilder<ReceiveRetailBloc, ReceiveRetailState>(
          builder: (context, state) {
            if (state.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.brandPrimary),
              );
            }

            if (state.products.isEmpty) {
              return const Center(child: Text('Нет товаров для отображения'));
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      final quantity = state.quantities[product.id] ?? 0.0;

                      return ReceiveRetailItemWidget(
                        product: product,
                        quantity: quantity,
                        onChanged: (val) {
                          context.read<ReceiveRetailBloc>().add(
                            UpdateQuantity(product.id, val),
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildBottomBar(context, state, isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ReceiveRetailState state,
    bool isDark,
  ) {
    final hasItems = state.quantities.values.any((qty) => qty > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (hasItems && !state.isSubmitting)
                ? () => context.read<ReceiveRetailBloc>().add(
                    SubmitReceiveRetail(),
                  )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: state.isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Оприходовать',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }
}
