// ==============================================================================
// Title: AppSaveShortcutScope (app_save_shortcut_scope.dart)
// Path: frontend/lib/core/widgets/app_save_shortcut_scope.dart
// Description: Универсальный обработчик хоткеев Ctrl+S / Cmd+S и Escape для модалок.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── 1. Виджет перехвата клавиатурных комбинаций сохранения ───────────────────

/// [UI-KIT] [ИНВАРИАНТ] Область перехвата быстрых клавиш формы:
/// 1. Перехватывает Ctrl + S (Windows/Linux) и Cmd + S (macOS) для сохранения.
/// 2. [ИНВАРИАНТ] Работает независимо от текущей раскладки клавиатуры (RU / EN)
///    через сопоставление физической клавиши `PhysicalKeyboardKey.keyS`.
/// 3. Опционально перехватывает Escape для закрытия формы.
/// 4. Корректно перехватывает события даже при активном фокусе внутри полей ввода.
class AppSaveShortcutScope extends StatelessWidget {
  /// Опциональное действие сохранения данных формы
  final VoidCallback? onSave;

  /// Опциональное действие отмены / закрытия по клавише Escape
  final VoidCallback? onCancel;

  /// Дочерний виджет (обычно диалог или форма)
  final Widget child;

  /// Флаг активности перехватчика хоткеев
  final bool enabled;

  const AppSaveShortcutScope({
    super.key,
    required this.child,
    this.onSave,
    this.onCancel,
    this.enabled = true,
  });

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!enabled) return KeyEventResult.ignored;

    // Реагируем только на событие нажатия (KeyDownEvent)
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // 1. Проверка клавиши Escape для закрытия
    if (event.logicalKey == LogicalKeyboardKey.escape && onCancel != null) {
      onCancel!();
      return KeyEventResult.handled;
    }

    // 2. Проверка модификаторов Ctrl / Cmd
    final isCtrlOrMeta = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (!isCtrlOrMeta) return KeyEventResult.ignored;

    // 3. Проверка клавиши 'S' (поддержка русской и английской раскладки)
    final isKeyS = event.physicalKey == PhysicalKeyboardKey.keyS ||
        event.logicalKey == LogicalKeyboardKey.keyS;

    if (isKeyS && onSave != null) {
      onSave!();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: child,
    );
  }
}
