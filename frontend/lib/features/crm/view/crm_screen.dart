import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/crm/bloc/crm_bloc.dart';
import 'package:mynix_frontend/features/crm/bloc/crm_event.dart';
import 'package:mynix_frontend/features/crm/bloc/crm_state.dart';
import 'package:mynix_frontend/features/crm/models/customer.dart';
import 'package:mynix_frontend/features/crm/view/widgets/customer_kpi_cards.dart';
import 'package:mynix_frontend/features/crm/view/widgets/customer_table_header.dart';
import 'package:mynix_frontend/features/crm/view/widgets/customer_row.dart';
import 'package:mynix_frontend/features/crm/view/widgets/dialogs/customer_form_modal.dart';
import 'package:mynix_frontend/features/crm/view/widgets/dialogs/customer_details_dialog.dart';
import 'package:mynix_frontend/features/crm/view/widgets/dialogs/customer_payment_modal.dart';

class CrmScreen extends StatefulWidget {
  const CrmScreen({super.key});

  @override
  State<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends State<CrmScreen> {
  final _searchController = TextEditingController();
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    context.read<CrmBloc>().add(const LoadCustomers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<CrmBloc>().add(LoadCustomers(query: query, filterType: _activeFilter));
  }

  void _onFilterChanged(String filter) {
    setState(() => _activeFilter = filter);
    context.read<CrmBloc>().add(LoadCustomers(query: _searchController.text, filterType: filter));
  }

  void _openCreateModal() {
    showDialog(
      context: context,
      builder: (_) => CustomerFormModal(
        onSubmit: (data) => context.read<CrmBloc>().add(CreateCustomerEvent(data)),
      ),
    );
  }

  void _openEditModal(Customer customer) {
    showDialog(
      context: context,
      builder: (_) => CustomerFormModal(
        initialCustomer: customer,
        onSubmit: (data) => context.read<CrmBloc>().add(UpdateCustomerEvent(customer.id, data)),
      ),
    );
  }

  void _openDetailsDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (_) => CustomerDetailsDialog(
        customer: customer,
        onEdit: () {
          Navigator.of(context).pop();
          _openEditModal(customer);
        },
      ),
    );
  }

  void _openPaymentModal(Customer customer) {
    showDialog(
      context: context,
      builder: (_) => CustomerPaymentModal(
        customer: customer,
        onSubmit: (data) => context.read<CrmBloc>().add(CreateCustomerTransactionEvent(customer.id, data)),
      ),
    );
  }

  void _confirmDelete(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление гостя'),
        content: Text('Вы уверены, что хотите удалить клиента «${customer.name}»?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<CrmBloc>().add(DeleteCustomerEvent(customer.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      body: BlocConsumer<CrmBloc, CrmState>(
        listener: (context, state) {
          if (state is CrmError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          final customers = state is CrmLoaded ? state.customers : <Customer>[];
          final totalCount = customers.length;
          final totalDebt = state is CrmLoaded ? state.totalDebt : 0.0;
          final totalDeposit = state is CrmLoaded ? state.totalDeposit : 0.0;
          final totalLtv = state is CrmLoaded ? state.totalLtv : 0.0;
          final totalBonuses = state is CrmLoaded ? state.totalBonuses : 0.0;
          final debtorsCount = state is CrmLoaded ? state.debtorsCount : 0;
          final depositsCount = state is CrmLoaded ? state.depositsCount : 0;
          final vipCount = state is CrmLoaded ? state.vipCount : 0;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CRM, LTV & Лояльность', style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                          'База гостей, история чеков, кешбэк-бонусы и RFM-сегментация',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _openCreateModal,
                      icon: const Icon(PhosphorIconsRegular.plus, size: 18),
                      label: const Text('Новый гость'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // KPI summary
                CustomerKpiCards(
                  totalCount: totalCount,
                  totalDebt: totalDebt,
                  totalDeposit: totalDeposit,
                  totalLtv: totalLtv,
                  totalBonuses: totalBonuses,
                  debtorsCount: debtorsCount,
                  vipCount: vipCount,
                ),
                const SizedBox(height: 14),

                // Search and Filters
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearch,
                        decoration: InputDecoration(
                          hintText: 'Поиск по имени или телефону...',
                          prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 18),
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterPill('Все ($totalCount)', 'all', isDark),
                          const SizedBox(width: 6),
                          _buildFilterPill('🔥 VIP ($vipCount)', 'vip', isDark),
                          const SizedBox(width: 6),
                          _buildFilterPill('⚠️ Спящие', 'churn', isDark),
                          const SizedBox(width: 6),
                          _buildFilterPill('✨ Новички', 'new', isDark),
                          const SizedBox(width: 6),
                          _buildFilterPill('Должники ($debtorsCount)', 'debtors', isDark),
                          const SizedBox(width: 6),
                          _buildFilterPill('Депозиты ($depositsCount)', 'deposits', isDark),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Table Header
                const CustomerTableHeader(),
                const SizedBox(height: 4),

                // Customer List
                Expanded(
                  child: state is CrmLoading
                      ? const Center(child: CircularProgressIndicator())
                      : customers.isEmpty
                          ? Center(
                              child: Text(
                                'Гости не найдены',
                                style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                            )
                          : ListView.builder(
                              itemCount: customers.length,
                              itemBuilder: (context, index) {
                                final customer = customers[index];
                                return CustomerRow(
                                  customer: customer,
                                  onTap: () => _openDetailsDialog(customer),
                                  onPay: () => _openPaymentModal(customer),
                                  onEdit: () => _openEditModal(customer),
                                  onDelete: () => _confirmDelete(customer),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterPill(String label, String value, bool isDark) {
    final isSelected = _activeFilter == value;
    return InkWell(
      onTap: () => _onFilterChanged(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.black : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}
