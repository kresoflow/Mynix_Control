---
name: refactor_bloat
description: Рефакторинг и декомпозиция Flutter UI Kreso Flow. Активируй при превышении лимитов строк (>250-300), разделении экранов, выносе виджетов и оптимизации God-объектов по Locality of Behavior.
---

# Flutter UI Decomposition & Bloat Refactoring Playbook

Операционный плейбук декомпозиции Flutter UI под стандарты Kreso Flow (**Locality of Behavior, BLoC State, UI Kit Tokens, лимиты 200–250/300 строк**).

---

## 1. Базовые законы декомпозиции

1. **Лимиты строк и связность:** Целевой 200–250 строк, жесткий потолок 300 строк (до 350 — для неделимых связанных BLoC с эвентами/стейтами). Запрещен механический распил единой бизнес-логики.
2. **Табу на файлы-карлики в UI (<60 строк):** Запрещено создавать самостоятельные файлы размером менее 60 строк для вспомогательных UI-виджетов одного экрана.
3. **[ИНВАРИАНТ] Автономия доменных атомов:** Чистые Enums, Value Objects, DTO и контракты (в папках `models/`, `enums/`, `domain/`) имеют полное право быть компактными (<60 строк). Запрещено искусственно сшивать их с чужими классами ради набивки строк.
4. **Locality of Behavior:** Вспомогательные виджеты формы оставляй в конце родительского файла как приватные классы, пока файл укладывается в 250–300 строк.
5. **[ИНВАРИАНТ] Тай-брейкер правила "файлов-карликов" (<60 строк):**
   Если вынос вспомогательного компонента с собственным контроллером/состоянием даёт файл короче 60 строк — **СТРОГО ЗАПРЕЩЕНО** выносить его в отдельный файл. Оставляй его приватным `StatefulWidget` в конце родительского файла с обязательным освобождением ресурсов (`dispose()` для `TextEditingController`, `FocusNode`, `ScrollController`, `AnimationController`, `TabController`).
6. **[ИНВАРИАНТ] Группировка при превышении 300 строк:**
   Если родительский файл выходит за лимит 300 строк из-за 2+ приватных виджетов (каждый <60 строк), объединяй их в один общий файл вспомогательных компонентов: `frontend/lib/features/<domain>/view/widgets/<domain>_form_fields.dart` (>60 строк).

---

## 2. Архитектурные паттерны выноса виджетов и логики

### Паттерн А: Вспомогательный приватный StatelessWidget (без выноса)
*Используется, если код виджета <60 строк и он нужен только текущему экрану.*

```dart
// ─── 3. Приватные вспомогательные виджеты ───────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppSecondaryButton(
      label: label,
      size: AppButtonSize.sm,
      isSelected: isSelected,
      onPressed: onTap,
    );
  }
}
```

---

### Паттерн Б: Приватный StatefulWidget с контроллером (Тай-брейкер <60 строк)
*Используется, когда вспомогательному виджету нужен контроллер, но общий объём <60 строк.*

```dart
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

class _InlineCommentField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _InlineCommentField({required this.onChanged});

  @override
  State<_InlineCommentField> createState() => _InlineCommentFieldState();
}

class _InlineCommentFieldState extends State<_InlineCommentField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose(); // [ИНВАРИАНТ] Защита от утечек памяти
    _focusNode.dispose();  // [ИНВАРИАНТ] Обязательное освобождение FocusNode
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      hintText: 'Комментарий к позиции',
    );
  }
}
```

---

### Паттерн В: Вынос диалога / модалки с сохранением BLoC-контекста
*Используется при создании `frontend/lib/features/<module>/view/widgets/<name>_dialog.dart` (>60 строк).*

```dart
// =============================================================================
// МОДУЛЬ: Подарочные карты / Диалог пополнения
// ДОМЕН: frontend/lib/features/gift_cards/view/widgets/topup_gift_card_dialog.dart
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TopUpGiftCardDialog extends StatefulWidget {
  final int cardId;
  const TopUpGiftCardDialog({super.key, required this.cardId});

  /// [ИНВАРИАНТ] Безопасная передача BLoC-контекста в диалог
  static Future<void> show(BuildContext context, {required int cardId}) {
    final bloc = context.read<GiftCardBloc>();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => BlocProvider.value(
        value: bloc,
        child: TopUpGiftCardDialog(cardId: cardId),
      ),
    );
  }

  @override
  State<TopUpGiftCardDialog> createState() => _TopUpGiftCardDialogState();
}

class _TopUpGiftCardDialogState extends State<TopUpGiftCardDialog> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose(); // [ИНВАРИАНТ] Защита от утечек памяти
    super.dispose();
  }

  void _onSubmit(BuildContext context) async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;
    context.read<GiftCardBloc>().add(TopUpGiftCardEvent(cardId: widget.cardId, amount: amount));
    if (!mounted) return; // [ИНВАРИАНТ] Защита от обращения к размонтированному контексту
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogScaffold(
      title: 'Пополнение карты',
      // ...
    );
  }
}
```

---

### Паттерн Г: Изоляция тяжелых перерисовок через BlocSelector

```dart
BlocSelector<CartBloc, CartState, double>(
  selector: (state) => state.totalAmount,
  builder: (context, totalAmount) {
    return Text(totalAmount.toCurrency(context), style: AppTextStyles.priceLarge);
  },
)
```

---

### Паттерн Д: Рефакторинг BLoC с EventTransformers
*Используется при разделении логики событий на поиск/фильтры и транзакции.*

```dart
class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final CatalogRepository _repository;

  CatalogBloc({required CatalogRepository repository})
      : _repository = repository,
        super(const CatalogState()) {
    // [ИНВАРИАНТ] restartable() — для поиска (новый ввод отменяет предыдущий запрос)
    on<SearchCatalogEvent>(_onSearch, transformer: restartable());

    // [ИНВАРИАНТ] sequential() — для мутаций данных (строгий порядок исполнения)
    on<UpdateProductEvent>(_onUpdateProduct, transformer: sequential());
  }

  Future<void> _onSearch(SearchCatalogEvent event, Emitter<CatalogState> emit) async {
    final results = await _repository.search(event.query);
    emit(state.copyWith(items: results));
  }

  Future<void> _onUpdateProduct(UpdateProductEvent event, Emitter<CatalogState> emit) async {
    await _repository.update(event.id, event.payload);
    emit(state.copyWith(lastUpdatedId: event.id));
  }
}
```

---

## 3. Алгоритм действий и верификация

1. Раздели метод `build` на логические секции.
2. Приватные компоненты оставь в конце родительского файла. Если файл превышает 300 строк — вынеси крупные блоки (>60 строк) в `frontend/lib/features/<domain>/view/widgets/`.
3. Для компонентов с контроллерами короче 60 строк используй приватный `StatefulWidget` (Тай-брейкер). При наличии 2+ таких компонентов объединяй их в `<domain>_form_fields.dart`.
4. Убедись, что все контроллеры (`TextEditingController`, `FocusNode`, `ScrollController`, `AnimationController`, `TabController`) очищаются через `dispose()`.
5. Запусти детерминированные проверки из корня репозитория:
   ```bash
   dart analyze frontend/lib/features/<module>
   python scripts/verify_rules.py --target <module>
   flutter test frontend/test/features/<module>
   ```
