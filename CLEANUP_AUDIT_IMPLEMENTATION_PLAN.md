# План реализации: Комплексная зачистка кодовой базы Kreso Flow (Pilot Lean MVP)

> **Статус документа:** Готов к исполнению  
> **Расположение:** Корень репозитория `CLEANUP_AUDIT_IMPLEMENTATION_PLAN.md`  
> **Исключение из текущей фазы:** Нижняя панель навигации `BottomNavigationBar` в `MobileLayout` (`mobile_layout.dart`) перенесена на отдельную фазу по прямому указанию пользователя.

---

## 1. Сводная матрица проблем аудита и инженерных решений (100% покрытие)

| # | Локация проблемы | Суть дефекта / рудимента | Инженерное решение в плане | Статус |
|---|---|---|---|---|
| **1** | `pos_operational_badges.dart:100-150`<br>`pos_screen.dart:88-95` | **Колокол кассы и запросы официантов:** На десктопе и мобайле отображается кнопка входящих заказов официантов со счетчиком и всплывающими алертами. | Удалить `_buildIncomingOrdersButton`, звуковые/тост уведомления, оставить только кнопку столиков зала. | **Выполнено (Коммит 1)** |
| **2** | `dialogs/incoming_orders_dialog.dart`<br>`dialogs/incoming_order_card.dart`<br>`dialogs/incoming_order_payment_modal.dart`<br>`dialogs/incoming_order_reject_modal.dart` | **Мертвые диалоги и кнопка KDS:** Карточка заказа содержит нерабочую зеленую кнопку «В цех (KDS)», диалоги approval-flow больше не вызываются. | Физически удалить 4 файла диалогов из проекта. 0 висячих вызовов. | **Выполнено (Коммит 1)** |
| **3** | `pos_tab_cubit.dart:30,58,72`<br>`order_repository.dart:107-147` | **Хранилище стейта входящих заказов:** Кубит хранит `incomingCount` и опрашивает несуществующие заказы официантов. | Удалить `incomingCount` из стейта, удалить методы `fetchPendingOrders`, `approveOrder`, `rejectOrder` из репозитория. | **Выполнено (Коммит 1)** |
| **4** | `checkout_router.py:165-197`<br>`checkout_service.py:174,258-340` | **Бэкенд роуты подтверждения заказов:** Эндпоинты `/approve`, `/reject` и статус `PENDING_APPROVAL` для официантов. | Вырезать роуты `/approve` и `/reject`, удалить функции `approve_order` и `reject_order`, заказы кассы сразу переходят в `COMPLETED` или `READY`. | **Выполнено (Коммит 1)** |
| **5** | `backend/tests/test_hall_orders_and_approval.py` | **Устаревший тест approval-flow:** Тестирует несуществующий флоу официантов. | Удалить устаревший тест-файл. | **Выполнено (Коммит 1)** |
| **6** | `roles_router.py:36`<br>`services.py:231-240` | **Утечка устаревших ролей в API:** Эндпоинт `GET /roles/` возвращает любые роли из БД (включая `cook`, `waiter`, `universal_worker`). | Добавить серверный фильтр `Role.name.in_([r.value for r in RoleName])`. | **Выполнено (Коммит 2)** |
| **7** | `user_form_dialog.dart:177-199` | **Форма создания/редактирования персонала:** Дропдаун показывает все роли без фильтрации, управляющий может назначить любую роль. | Ограничить список строго каноническими ролями (`owner`, `manager`, `cashier`). Для роли `manager` — отображать только `cashier` (Poka-Yoke). | **Выполнено (Коммит 2)** |
| **8** | `personnel_settings_tab.dart:168` | **Текст-заглушка со старыми ролями:** Содержит текст «кассиров, поваров, управляющих». | Заменить на «кассиров, управляющих». | **Выполнено (Коммит 2)** |
| **9** | `general_settings_tab.dart:145-167`<br>`settings_bloc.dart:36,44,70,89` | **Нерабочие переключатели KDS в настройках:** Свитчи «Экран повара» и «Отображать KDS в главном меню». | Удалить свитчи из UI, удалить стейт/события `showKdsInNav`, зафиксировать `useKds = false`. | **Выполнено (Коммит 3)** |
| **10** | `create_tenant_modules_section.dart:50`<br>`edit_tenant_modules_section.dart:40`<br>`tenant_card.dart:173` | **Рудименты KDS в Superadmin панели:** Чекбоксы включения KDS и бейдж KDS в карточке заведения. | Удалить свитчи и бейдж KDS из компонентов панели суперадмина. | **Выполнено (Коммит 3)** |
| **11** | `roles_router.py:96-108` | **Логика авто-завершения KDS на бэкенде:** При выключении флага `use_kds` выполняется принудительный апдейт заказов кухни. | Удалить блок `if not data.use_kds and tenant.use_kds`. | **Выполнено (Коммит 3)** |
| **12** | `ws.py:57`<br>`websocket_service.dart:53` | **Устаревший URL вебсокета:** Маршрут называется `/ws/kitchen/{tenant_id}`, хотя обслуживает кассу POS. | Переименовать маршрут в `/ws/pos/{tenant_id}` на бэкенде и фронтенде, удалить `notify_pos_incoming_*`. | **Выполнено (Коммит 3)** |
| **13** | `backend/app/hardware/printer.py`<br>`backend/app/hardware/__init__.py` | **Мертвый модуль Hardware:** 0 импортов по всей кодовой базе, рудимент старой печати. | Физически удалить папку `backend/app/hardware/` и упоминание в `backend/ARCHITECTURE_MAP.md`. | **Выполнено (Коммит 4)** |
| **14** | `backend/app/system/integrations.py:65,82` | **Дыра в безопасности сервисных логов:** Эндпоинты `GET /system/frontend-logs` и `DELETE` доступны публично без авторизации. | Защитить эндпоинты через `dependencies=[Depends(require_system_admin)]`. | **Выполнено (Коммит 4)** |

---

## 2. Пошаговый план реализации по коммитам

### Коммит 1: `feat(pos): remove incoming orders bell and waiter approval flow`
**Цель:** Полное удаление колокола с кассы на Desktop и Mobile, ликвидация диалогов входящих заказов и серверных рудиментов согласования.

#### 2.1. Frontend — Очистка виджетов кассы
1. **[`frontend/lib/features/pos/view/widgets/pos_operational_badges.dart`](file:///d:/Kreso_Flow/frontend/lib/features/pos/view/widgets/pos_operational_badges.dart):**
   - Удалить вызов `_buildIncomingOrdersButton(context, tabState.incomingCount, isDark)`.
   - Удалить сам приватный метод `_buildIncomingOrdersButton` (строки 100–150).
   - Удалить неиспользуемый импорт `dialogs/incoming_orders_dialog.dart`.
   - В виджете остается исключительно кнопка активных столиков зала (`_buildActiveTablesButton`).
   - *Результат:* Колокол исчезает автоматически и в десктопной шапке (`app_nav_bar.dart`), и в мобильной шапке (`mobile_app_bar.dart`).
2. **[`frontend/lib/features/pos/view/pos_screen.dart`](file:///d:/Kreso_Flow/frontend/lib/features/pos/view/pos_screen.dart):**
   - В методе подписки на WebSocket удалить ветки `event == 'incoming_order'` и `event == 'incoming_order_resolved'`.
   - Удалить всплывающее уведомление `AppToast.showInfo(context, 'Новый заказ с зала', ...)` и звуковое оповещение `AudioHelper.playNewOrderSound()`.
3. **Физическое удаление 4 мертвых файлов диалогов:**
   - `frontend/lib/features/pos/view/widgets/dialogs/incoming_orders_dialog.dart`
   - `frontend/lib/features/pos/view/widgets/dialogs/incoming_order_card.dart` *(включая кнопку «В цех (KDS)»)*
   - `frontend/lib/features/pos/view/widgets/dialogs/incoming_order_payment_modal.dart`
   - `frontend/lib/features/pos/view/widgets/dialogs/incoming_order_reject_modal.dart`
4. **[`frontend/lib/features/pos/bloc/pos_tab_cubit.dart`](file:///d:/Kreso_Flow/frontend/lib/features/pos/bloc/pos_tab_cubit.dart):**
   - Удалить поле `incomingCount` из класса состояния `PosTabState` и метода `copyWith`.
   - В `PosTabCubit.refreshCounts()` убрать запрос `_orderRepo.fetchPendingOrders()`.
   - В методе `updateCounts` оставить только `activeTablesCount`.
5. **[`frontend/lib/features/pos/repository/order_repository.dart`](file:///d:/Kreso_Flow/frontend/lib/features/pos/repository/order_repository.dart):**
   - Удалить методы:
     - `fetchPendingOrders()`
     - `approveOrder(...)`
     - `rejectOrder(...)`

#### 2.2. Backend — Удаление роутов и логики согласования
1. **[`backend/app/pos/routers/checkout_router.py`](file:///d:/Kreso_Flow/backend/app/pos/routers/checkout_router.py):**
   - Удалить DTO-схемы `ApproveOrderRequest` и `RejectOrderRequest`.
   - Удалить эндпоинты `POST /orders/{order_id}/approve` и `POST /orders/{order_id}/reject`.
2. **[`backend/app/pos/services/checkout_service.py`](file:///d:/Kreso_Flow/backend/app/pos/services/checkout_service.py):**
   - Удалить функции `approve_order(...)` и `reject_order(...)`.
   - В функции `create_order` удалить ветку `is_waiter_order = source_lower in ("waiter", "qr_guest")` и статус `OrderStatus.PENDING_APPROVAL`.
   - Оставить стандартные статусы кассы: `COMPLETED` для прямой оплаты, `READY` для столиков зала на постоплату.
3. **[`backend/app/pos/ws.py`](file:///d:/Kreso_Flow/backend/app/pos/ws.py):**
   - Удалить функции `notify_pos_incoming_order` и `notify_pos_incoming_resolved`.
4. **Тесты:**
   - Физически удалить `backend/tests/test_hall_orders_and_approval.py`.

---

### Коммит 2: `feat(users): enforce canonical RoleName in API and user form dialog`
**Цель:** Гарантировать, что при создании/редактировании сотрудников в UI и API фигурируют только 3 канонические роли (`owner`, `manager`, `cashier`), с защитой Poka-Yoke для управляющего.

#### 2.1. Backend — Фильтрация ролей по каноническому реестру
1. **[`backend/app/users/services.py`](file:///d:/Kreso_Flow/backend/app/users/services.py):**
   - В функции `list_roles(session)` добавить фильтрацию:
     ```python
     from app.users.permissions import RoleName
     canonical_roles = [r.value for r in RoleName]
     stmt = (
         select(Role)
         .where(Role.name.in_(canonical_roles))
         .options(selectinload(Role.permissions))
     )
     ```
   - *Результат:* Любые исторические роли в БД (`cook`, `waiter`, `universal_worker`) отсекаются на уровне SQL и никогда не передаются клиенту.

#### 2.2. Frontend — Форма создания сотрудника и список персонала
1. **[`frontend/lib/features/settings/view/widgets/user_form_dialog.dart`](file:///d:/Kreso_Flow/frontend/lib/features/settings/view/widgets/user_form_dialog.dart):**
   - Определить константу канонических ролей:
     ```dart
     const allowedRoles = {'owner', 'manager', 'cashier'};
     ```
   - Получить роль текущего авторизованного пользователя через `AuthBloc` / `AuthState`.
   - Если текущий пользователь — `manager`, то в списке доступных ролей для назначения отображается **исключительно `'cashier'`** (Poka-Yoke).
   - Для `owner` — доступны роли из белого списка `allowedRoles` (исключая любые неожиданные значения из БД).
2. **[`frontend/lib/features/settings/view/tabs/personnel_settings_tab.dart`](file:///d:/Kreso_Flow/frontend/lib/features/settings/view/tabs/personnel_settings_tab.dart):**
   - В строке 168 заменить устаревший текст:
     - *Было:* `'Нет добавленных сотрудников (кассиров, поваров, управляющих)'`
     - *Стало:* `'Нет добавленных сотрудников (кассиров, управляющих)'`

---

### Коммит 3: `refactor(settings): purge dormant KDS toggles from settings and superadmin`
**Цель:** Окончательная зачистка остатков экрана кухни (KDS) из настроек заведения, панели суперадмина и фоновых служб.

#### 3.1. Frontend — Общие настройки и BLoC
1. **[`frontend/lib/features/settings/view/tabs/general_settings_tab.dart`](file:///d:/Kreso_Flow/frontend/lib/features/settings/view/tabs/general_settings_tab.dart):**
   - Удалить строки 145–167: переключатели «Использовать экран повара (KDS)» и «Отображать KDS в главном меню».
   - Удалить переменную состояния `_useKds` и неиспользуемый код обновления настроек KDS.
2. **[`frontend/lib/features/settings/bloc/settings_bloc.dart`](file:///d:/Kreso_Flow/frontend/lib/features/settings/bloc/settings_bloc.dart):**
   - Удалить свойство `showKdsInNav` и событие `ToggleShowKdsInNav`.
   - Зафиксировать `useKds = false` по умолчанию.

#### 3.2. Frontend — Superadmin панель
1. **[`frontend/lib/features/superadmin/view/widgets/create_tenant_modules_section.dart`](file:///d:/Kreso_Flow/frontend/lib/features/superadmin/view/widgets/create_tenant_modules_section.dart):**
   - Удалить `_buildSwitchRow` для «Кухонный дисплей (KDS)» (строки 47–55).
2. **[`frontend/lib/features/superadmin/view/widgets/edit_tenant_modules_section.dart`](file:///d:/Kreso_Flow/frontend/lib/features/superadmin/view/widgets/edit_tenant_modules_section.dart):**
   - Удалить `_buildModuleTile` для «Кухонный дисплей (KDS)» (строки 40–46).
3. **[`frontend/lib/features/superadmin/view/widgets/tenant_card.dart`](file:///d:/Kreso_Flow/frontend/lib/features/superadmin/view/widgets/tenant_card.dart):**
   - Удалить бейдж `TenantBadge(label: 'KDS', ...)` (строки 173–174).

#### 3.3. Backend & WebSocket — Зачистка логики KDS
1. **[`backend/app/users/routers/roles_router.py`](file:///d:/Kreso_Flow/backend/app/users/routers/roles_router.py):**
   - Удалить строки 96–108: рудиментарный блок авто-завершения кухонных заказов при выключении KDS.
2. **Маршрутизация WebSocket:**
   - **[`backend/app/pos/ws.py`](file:///d:/Kreso_Flow/backend/app/pos/ws.py):** Переименовать маршрут с `@router.websocket("/ws/kitchen/{tenant_id}")` на `@router.websocket("/ws/pos/{tenant_id}")`.
   - **[`frontend/lib/core/network/websocket_service.dart`](file:///d:/Kreso_Flow/frontend/lib/core/network/websocket_service.dart):** Изменить URI подключения на `$_baseWsUrl/pos/$_currentTenantId$query`.

---

### Коммит 4: `chore(backend): remove dead hardware module and protect frontend logs endpoint`
**Цель:** Физическое удаление мертвого модуля торгового оборудования и защита сервисных логов.

#### 4.1. Backend — Удаление модуля Hardware
1. Физически удалить файлы:
   - `backend/app/hardware/printer.py`
   - `backend/app/hardware/__init__.py`
2. Обновить `backend/ARCHITECTURE_MAP.md`: удалить устаревшую секцию `hardware`.

#### 4.2. Backend — Защита сервисных эндпоинтов логов
1. **[`backend/app/system/integrations.py`](file:///d:/Kreso_Flow/backend/app/system/integrations.py):**
   - Защитить эндпоинты `GET /system/frontend-logs` и `DELETE /system/frontend-logs`:
     ```python
     @router.get("/system/frontend-logs", dependencies=[Depends(require_system_admin)])
     @router.get("/frontend-logs", dependencies=[Depends(require_system_admin)])
     ...
     @router.delete("/system/frontend-logs", dependencies=[Depends(require_system_admin)])
     @router.delete("/frontend-logs", dependencies=[Depends(require_system_admin)])
     ```

---

## 3. Критерии приемки (Quality Gates & Verification)

Каждый шаг валидируется строгим набором проверок:

1. **Backend Tests:**
   ```bash
   pytest backend/tests
   ```
   *Критерий:* 100% тестов проходят успешно (зеленый статус).
2. **Frontend Analysis:**
   ```bash
   cd frontend && dart analyze lib/
   ```
   *Критерий:* 0 ошибок (`No issues found!`).
3. **Архитектурный контроль:**
   ```bash
   python scripts/verify_rules.py
   ```
   *Критерий:* 0 критических нарушений правил проекта.
4. **Визуальная проверка (Poka-Yoke):**
   - На кассе (десктоп и мобайл) видна только кнопка активных столиков, колокол отсутствует.
   - В настройках персонала при создании пользователя доступны только роли `owner`, `manager`, `cashier`.
   - Для управляющего отображается исключительно роль `cashier`.
   - В общих настройках и карточках суперадмина отсутствуют любые элементы KDS.
