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
import 'package:mynix_frontend/features/crm/view/widgets/customer_filter_bar.dart';
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
          Navigator.pop(context);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить гостя?'),
        content: Text('Вы уверены, что хотите удалить гостя "${customer.name}"? Это действие необратимо.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена', style: TextStyle(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CrmBloc>().add(DeleteCustomerEvent(customer.id));
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: BlocBuilder<CrmBloc, CrmState>(
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
            padding: EdgeInsets.all(isMobile ? 12 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CRM & Лояльность', style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w800)),
                          if (!isMobile) ...[
                            const SizedBox(height: 4),
                            Text(
                              'База гостей, история чеков, кешбэк-бонусы и RFM-сегментация',
                              style: AppTextStyles.caption.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openCreateModal,
                      icon: const Icon(PhosphorIconsRegular.plus, size: 18),
                      label: Text(isMobile ? 'Гость' : 'Новый гость'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

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
                const SizedBox(height: 12),

                // Search and Filters
                CustomerFilterBar(
                  searchController: _searchController,
                  activeFilter: _activeFilter,
                  totalCount: totalCount,
                  vipCount: vipCount,
                  debtorsCount: debtorsCount,
                  depositsCount: depositsCount,
                  onSearch: _onSearch,
                  onFilterChanged: _onFilterChanged,
                ),
                const SizedBox(height: 10),

                // Table Header (desktop only)
                if (!isMobile) ...[
                  const CustomerTableHeader(),
                  const SizedBox(height: 4),
                ],

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
}
