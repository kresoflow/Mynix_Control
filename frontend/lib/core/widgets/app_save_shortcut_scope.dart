// ==============================================================================
// Title: AppSaveShortcutScope (app_save_shortcut_scope.dart)
// Path: frontend/lib/core/widgets/app_save_shortcut_scope.dart
// Description: Универсальный обработчик хоткеев Ctrl+S / Cmd+S, Ctrl+F и Escape для модалок.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── 1. Виджет перехвата клавиатурных комбинаций сохранения и поиска ─────────

/// [UI-KIT] [ИНВАРИАНТ] Область перехвата быстрых клавиш формы:
/// 1. Перехватывает Ctrl + S (Windows/Linux) и Cmd + S (macOS) для сохранения.
/// 2. [ИНВАРИАНТ] Работает независимо от текущей раскладки клавиатуры (RU / EN)
///    через сопоставление физических клавиш `PhysicalKeyboardKey.keyS` и `PhysicalKeyboardKey.keyF`.
/// 3. Перехватывает Ctrl + F / Cmd + F / F2 для вызова поиска внутри модального окна.
/// 4. Изолирует модальное окно: блокирует утечку глобальных хоткеев в фоновые экраны.
/// 5. Двухфазный Escape: сначала расфокусирует поле ввода, при повторном нажатии закрывает форму.
class AppSaveShortcutScope extends StatefulWidget {
  /// Опциональное действие сохранения данных формы
  final VoidCallback? onSave;

  /// Опциональное действие отмены / закрытия по клавише Escape
  final VoidCallback? onCancel;

  /// Опциональное действие вызова поиска (Ctrl+F / Cmd+F / F2)
  final VoidCallback? onSearch;

  /// Дочерний виджет (обычно диалог или форма)
  final Widget child;

  /// Флаг активности перехватчика хоткеев
  final bool enabled;

  const AppSaveShortcutScope({
    super.key,
    required this.child,
    this.onSave,
    this.onCancel,
    this.onSearch,
    this.enabled = true,
  });

  /// Флаг активности хотя бы одного модального диалога в приложении.
  static bool get isAnyModalOpen => _AppSaveShortcutScopeState.isAnyModalOpen;

  @override
  State<AppSaveShortcutScope> createState() => _AppSaveShortcutScopeState();
}

class _AppSaveShortcutScopeState extends State<AppSaveShortcutScope> {
  static KeyEvent? _lastHandledKeyEvent;
  static int _activeScopesCount = 0;

  /// [ИНВАРИАНТ] Флаг активности хотя бы одной модальной области хоткеев.
  static bool get isAnyModalOpen => _activeScopesCount > 0;

  @override
  void initState() {
    super.initState();
    _activeScopesCount++;
    HardwareKeyboard.instance.addHandler(_handleGlobalHardwareKeyEvent);
  }

  @override
  void dispose() {
    if (_activeScopesCount > 0) _activeScopesCount--;
    HardwareKeyboard.instance.removeHandler(_handleGlobalHardwareKeyEvent);
    super.dispose();
  }

  // [ИНВАРИАНТ] Обработка клавиатурных комбинаций на уровне текущего маршрута.
  bool _handleGlobalHardwareKeyEvent(KeyEvent event) {
    if (!widget.enabled || !mounted) return false;
    if (event is! KeyDownEvent) return false;

    // 1. Проверяем, что данный модальный маршрут является текущим (активным сверху)
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null && !modalRoute.isCurrent) {
      return false;
    }

    if (identical(_lastHandledKeyEvent, event)) {
      return true;
    }

    // 2. Клавиша Escape: двухфазная логика выхода
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.physicalKey == PhysicalKeyboardKey.escape) {
      final primaryFocus = FocusManager.instance.primaryFocus;
      // Если активно конкретное поле текстового ввода — сначала снимаем фокус
      final isTextEditing = primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null;
      if (isTextEditing) {
        _lastHandledKeyEvent = event;
        primaryFocus?.unfocus();
        return true;
      }

      // Если текстовые поля не активны — закрываем модальное окно / отмена
      if (widget.onCancel != null) {
        _lastHandledKeyEvent = event;
        widget.onCancel!();
        return true;
      }
      return false;
    }

    // 3. Клавиша F2 для поиска
    final isF2 = event.physicalKey == PhysicalKeyboardKey.f2 ||
        event.logicalKey == LogicalKeyboardKey.f2;
    if (isF2 && widget.onSearch != null) {
      _lastHandledKeyEvent = event;
      widget.onSearch!();
      return true;
    }

    // 4. Проверка модификаторов Ctrl / Cmd
    final isCtrlOrMeta = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.physicalKeysPressed.contains(PhysicalKeyboardKey.controlLeft) ||
        HardwareKeyboard.instance.physicalKeysPressed.contains(PhysicalKeyboardKey.controlRight) ||
        HardwareKeyboard.instance.physicalKeysPressed.contains(PhysicalKeyboardKey.metaLeft) ||
        HardwareKeyboard.instance.physicalKeysPressed.contains(PhysicalKeyboardKey.metaRight);
    if (!isCtrlOrMeta) return false;

    // 5. Проверка клавиши 'S' (сохранение, поддержка RU/EN раскладки)
    final isKeyS = event.physicalKey == PhysicalKeyboardKey.keyS ||
        event.logicalKey == LogicalKeyboardKey.keyS;
    if (isKeyS && widget.onSave != null) {
      _lastHandledKeyEvent = event;
      widget.onSave!();
      return true;
    }

    // 6. Проверка клавиши 'F' (поиск, поддержка RU/EN раскладки — клавиша 'А')
    final isKeyF = event.physicalKey == PhysicalKeyboardKey.keyF ||
        event.logicalKey == LogicalKeyboardKey.keyF;
    if (isKeyF && widget.onSearch != null) {
      _lastHandledKeyEvent = event;
      widget.onSearch!();
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
