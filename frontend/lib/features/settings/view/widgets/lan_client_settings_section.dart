import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:mynix_frontend/core/theme/app_colors.dart';
import 'package:mynix_frontend/core/theme/app_text_styles.dart';
import 'package:mynix_frontend/core/widgets/app_button.dart';
import '../../services/lan_settings_service.dart';

class LanClientSettingsSection extends StatefulWidget {
  final bool isDark;

  const LanClientSettingsSection({super.key, required this.isDark});

  @override
  State<LanClientSettingsSection> createState() => _LanClientSettingsSectionState();
}

class _LanClientSettingsSectionState extends State<LanClientSettingsSection> {
  late final TextEditingController _ipController;
  late final TextEditingController _portController;
  bool _isTesting = false;
  String? _pingResult;
  bool? _pingSuccess;

  @override
  void initState() {
    super.initState();
    final settings = LanSettingsService.current;
    _ipController = TextEditingController(text: settings.masterIp);
    _portController = TextEditingController(text: settings.port.toString());
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _testPing() async {
    setState(() {
      _isTesting = true;
      _pingResult = null;
      _pingSuccess = null;
    });

    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8080;
    await LanSettingsService.setMasterIp(ip);
    await LanSettingsService.setPort(port);

    final ok = await LanSettingsService.testMasterConnection(ip, port);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _pingSuccess = ok;
        _pingResult = ok
            ? 'Связь с кассой установлена (LAN активен)'
            : 'Касса не отвечает по адресу $ip:$port';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _ipController,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  labelText: 'IP-адрес главной кассы',
                  hintText: '192.168.1.10',
                  filled: true,
                  fillColor: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (val) => LanSettingsService.setMasterIp(val),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _portController,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  labelText: 'Порт',
                  hintText: '8080',
                  filled: true,
                  fillColor: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (val) {
                  final p = int.tryParse(val);
                  if (p != null) LanSettingsService.setPort(p);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            AppButton.secondary(
              label: _isTesting ? 'Проверка...' : 'Проверить связь с кассой',
              icon: PhosphorIconsRegular.lightning,
              isLoading: _isTesting,
              onPressed: _testPing,
            ),
            if (_pingResult != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (_pingSuccess == true ? AppColors.success : AppColors.danger).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _pingResult!,
                    style: AppTextStyles.caption.copyWith(
                      color: _pingSuccess == true ? AppColors.success : AppColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
