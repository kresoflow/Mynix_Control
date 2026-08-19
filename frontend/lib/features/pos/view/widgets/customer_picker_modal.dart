import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/features/crm/models/customer.dart';
import 'package:mynix_frontend/features/crm/repository/crm_repository.dart';
import 'package:mynix_frontend/features/crm/view/widgets/dialogs/customer_form_modal.dart';
import 'package:mynix_frontend/features/pos/view/widgets/components/customer_picker_tile.dart';

class CustomerPickerModal extends StatefulWidget {
  final Customer? selectedCustomer;
  final Function(Customer? customer) onSelect;

  const CustomerPickerModal({
    super.key,
    this.selectedCustomer,
    required this.onSelect,
  });

  @override
  State<CustomerPickerModal> createState() => _CustomerPickerModalState();
}

class _CustomerPickerModalState extends State<CustomerPickerModal> {
  final _searchController = TextEditingController();
  List<Customer> _customers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers([String query = '']) async {
    setState(() => _isLoading = true);
    try {
      final repo = CrmRepository(apiClient.dio);
      final res = await repo.getCustomers(query: query);
      setState(() {
        _customers = res;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _openCreateCustomer(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CustomerFormModal(
        initialPhone: _searchController.text.trim(),
        onSubmit: (data) async {
          try {
            final repo = CrmRepository(apiClient.dio);
            final newCust = await repo.createCustomer(data);
            widget.onSelect(newCust);
            if (mounted) Navigator.of(context).pop();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка создания: $e'), backgroundColor: AppColors.error),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(PhosphorIconsRegular.users, color: AppColors.brandPrimary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text('Прикрепить гостя к чеку', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(PhosphorIconsRegular.x, size: 18, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search + Add Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _loadCustomers,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Номер телефона или имя...',
                        prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 18),
                        filled: true,
                        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _openCreateCustomer(context),
                    icon: const Icon(PhosphorIconsRegular.userPlus, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                    tooltip: 'Создать нового гостя',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (widget.selectedCustomer != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      widget.onSelect(null);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIconsRegular.xCircle, size: 16, color: AppColors.error),
                          const SizedBox(width: 6),
                          Text('Открепить гостя от чека', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),

              // Customer List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _customers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Гость не найден', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                                const SizedBox(height: 10),
                                TextButton.icon(
                                  onPressed: () => _openCreateCustomer(context),
                                  icon: const Icon(PhosphorIconsRegular.plus, size: 16),
                                  label: const Text('Создать гостя сейчас'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _customers.length,
                            itemBuilder: (context, index) {
                              final c = _customers[index];
                              return CustomerPickerTile(
                                customer: c,
                                isSelected: widget.selectedCustomer?.id == c.id,
                                onTap: () {
                                  widget.onSelect(c);
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
