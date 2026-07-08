# Сводный отчет об аудите качества кода Mynix Control

Данный отчет объединяет результаты анализа серверной (FastAPI) и клиентской (Flutter) частей проекта, а также сквозных интеграционных сценариев. Его цель — выявление логических ошибок, проблем со стабильностью, уязвимостей безопасности и нарушений архитектурных стандартов проекта.

---

## 1. Сводка критических проблем (Critical Highlights)

В ходе аудита были обнаружены следующие критические проблемы, требующие немедленного устранения:

1. **Повреждение данных в KDS** (`backend/app/kitchen/services/kds_service.py`): Прямая мутация связи `order.items` в сессии базы данных приводит к каскадному удалению или исключениям целостности при авто-коммите транзакции.
2. **Уязвимость безопасности WebSocket** (`backend/app/pos/ws.py`): Отсутствие авторизации на вебсокете кухни позволяет любому неавторизованному пользователю прослушивать события заказов любого тенанта.
3. **Падение при расчете себестоимости (Food Cost)** (`backend/app/inventory/services/recipe_service.py`): Обращение к свойствам удаленного ингредиента без предварительной проверки на `None` приводит к падению сервиса аналитики.
4. **Небезопасный парсинг JSON и приведение типов в Flutter** (`auth_bloc.dart`, `ingredient.dart`, `document.dart`): Нехватка проверки типов и безопасного парсинга дат вызывает критические падения клиента на неожиданных или пустых ответах от сервера.
5. **Сбой авторизации по PIN-коду**: Несовпадение типов передаваемого `tenant_id` (`String` на клиенте и `int` на сервере) делает невозможным вход для линейных сотрудников (ошибка HTTP 422).
6. **Блокировка пользователей (PBAC)** (`seed.py` / роутеры): Защита эндпоинтов роутера правами, которые отсутствуют в сидах БД (например, `pos:menu_view`, `inventory:read`), полностью блокирует работу кассиров и поваров.
7. **God Objects во фронтенде (Нарушение лимита строк)**: UI-файлы содержат до 1477 строк (при лимите в 200-250 строк), нарушая стандарты декомпозиции и поддерживаемости.

---

## 2. Детальный реестр находок и рекомендации по исправлению

### 2.1 Backend (Серверная часть)

#### Находка 1: Повреждение данных при фильтрации заказов KDS
* **Путь к файлу**: `D:\Mynix_Control\backend\app\kitchen\services\kds_service.py`
* **Строки**: 28-29
* **Критичность**: Critical (Повреждение данных)
* **Описание**: Функция `get_active_orders` фильтрует позиции заказа на предмет принадлежности к блюдам (item_type == "dish") путем перезаписи поля связи: `order.items = dish_items`. Поскольку сессия SQLAlchemy автоматически коммитится при завершении запроса, это вызывает каскадное удаление всех остальных позиций заказа (например, розничных товаров) из базы данных, либо приводит к ошибке `IntegrityError` из-за ограничений внешнего ключа.
* **Пример проблемного кода**:
  ```python
  for order in orders:
      dish_items = [item for item in order.items if item.item_type == "dish"]
      if dish_items:
          order.items = dish_items  # <-- Прямая мутация связи!
          filtered_orders.append(order)
  ```
* **Рекомендованный фикс**: Избегать мутации отслеживаемых сущностей базы данных. Возвращать список объектов `Order` из сервисного слоя, отфильтрованный по наличию блюд, без изменения `order.items`. Фильтрацию позиций заказа (только `dish`) производить в роутере при сериализации ответа.
* **Предлагаемый код**:
  *В `backend/app/kitchen/services/kds_service.py`*:
  ```python
  async def get_active_orders(session: AsyncSession) -> List[Order]:
      stmt = (
          select(Order)
          .options(selectinload(Order.items))
          .where(Order.status == OrderStatus.COOKING)
          .order_by(Order.created_at.asc())
      )
      result = await session.execute(stmt)
      orders = result.scalars().all()
      
      return [order for order in orders if any(item.item_type == "dish" for item in order.items)]
  ```
  *В `backend/app/kitchen/routers/kds_router.py`*:
  ```python
  @router.get("/active", dependencies=[Depends(require_permission("kitchen:view"))])
  async def api_get_active_orders(current_user: CurrentUser, session: TenantSession):
      orders = await kds_service.get_active_orders(session)
      return [
          {
              "id": o.id,
              "order_number": o.order_number,
              "status": o.status,
              "payment_method": o.payment_method,
              "total": o.total,
              "note": o.note,
              "created_at": o.created_at.isoformat(),
              "items": [
                  {
                      "menu_item_name": oi.menu_item_name,
                      "quantity": oi.quantity,
                      "unit_price": oi.unit_price,
                      "subtotal": oi.subtotal,
                      "item_type": oi.item_type,
                  }
                  for oi in o.items
                  if oi.item_type == "dish"
              ],
          }
          for o in orders
      ]
  ```

---

#### Находка 2: Отсутствие авторизации на WebSocket-маршруте KDS
* **Путь к файлу**: `D:\Mynix_Control\backend\app\pos\ws.py`
* **Строки**: 60-61
* **Критичность**: Critical (Уязвимость безопасности)
* **Описание**: Эндпоинт WebSocket `/ws/kitchen/{tenant_id}` не имеет зависимостей для проверки JWT-токена или прав пользователя. Любое стороннее ПО может подключиться к нему и отслеживать события заказов любого тенанта в реальном времени.
* **Пример проблемного кода**:
  ```python
  @router.websocket("/ws/kitchen/{tenant_id}")
  async def kitchen_websocket(websocket: WebSocket, tenant_id: int):
  ```
* **Рекомендованный фикс**: Добавить передачу токена через query-параметр и валидировать его перед вызовом `accept()`, выполняя декодирование JWT напрямую с помощью `jose.jwt` и настроек приложения (`settings`).
* **Предлагаемый код**:
  ```python
  from jose import jwt, JWTError
  from app.config import settings
  
  @router.websocket("/ws/kitchen/{tenant_id}")
  async def kitchen_websocket(
      websocket: WebSocket,
      tenant_id: int,
      token: Optional[str] = Query(None)
  ):
      if not token:
          await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
          return
      try:
          payload = jwt.decode(
              token, settings.secret_key, algorithms=[settings.jwt_algorithm]
          )
          token_tenant_id = payload.get("tenant_id")
          permissions = payload.get("permissions", [])
          if token_tenant_id != tenant_id or "kitchen:view" not in permissions:
              await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
              return
      except JWTError:
          await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
          return
      
      await kitchen_manager.connect(websocket, tenant_id)
      # ...
  ```

---

#### Находка 3: Падение при расчете себестоимости блюда (Food Cost)
* **Путь к файлу**: `D:\Mynix_Control\backend\app\inventory\services\recipe_service.py`
* **Строка**: 86
* **Критичность**: Major (Необработанное исключение)
* **Описание**: Функция `calc_food_cost` вычисляет сумму затрат на ингредиенты блюда. В случае, если ингредиент был удален из БД, но связь в рецепте осталась («сирота»), `recipe.ingredient` возвращает `None`, что приводит к `AttributeError: 'NoneType' object has no attribute 'cost_per_unit'` и падению дашборда аналитики.
* **Пример проблемного кода**:
  ```python
  for recipe in recipes:
      total_cost += recipe.ingredient.cost_per_unit * recipe.quantity_required
  ```
* **Рекомендованный фикс**: Добавить проверку существования ингредиента перед расчетом.
* **Предлагаемый код**:
  ```python
  total_cost = 0.0
  for recipe in recipes:
      if recipe.ingredient is not None:
          total_cost += recipe.ingredient.cost_per_unit * recipe.quantity_required
  return round(total_cost, 2)
  ```

---

#### Находка 4: Нарушение разделения обязанностей (SQL в роутерах)
* **Путь к файлу**: `D:\Mynix_Control\backend\app\inventory\routers\document_router.py`
* **Строки**: 32-35, 44-53, 62-74
* **Критичность**: Major (Нарушение архитектурных стандартов)
* **Описание**: Роутер поставщиков (`supplier_router`) выполняет операции добавления, изменения и удаления записей из БД напрямую через сессию SQLAlchemy вместо делегирования бизнес-логики сервисному слою. Это нарушает правила бэкенда (Раздел 1.3: *routers/ — только маппинг HTTP, Pydantic-схемы и зависимости*).
* **Рекомендованный фикс**: Вынести логику манипулирования данными поставщиков в сервисный слой `document_service.py`.

---

#### Находка 5: Отсутствие наследования от TenantModel
* **Пути к файлам**:
  1. `D:\Mynix_Control\backend\app\inventory\models\recipe_models.py` (Строка 9)
  2. `D:\Mynix_Control\backend\app\pos\models.py` (Строка 107)
* **Критичность**: Minor (Нарушение стандартов моделей)
* **Описание**: Классы `Recipe` и `OrderItem` наследуются от базового `SQLModel` вместо `TenantModel`. Несмотря на то что изоляция обеспечивается на уровне схем PostgreSQL, отсутствие наследования от `TenantModel` лишает эти сущности стандартных аудиторских полей (`created_at` и `updated_at`), нарушая общее архитектурное соглашение.
* **Рекомендованный фикс**: Унаследовать модели от `TenantModel`.
* **Предлагаемый код**:
  ```python
  class Recipe(TenantModel, table=True):
  ```

---

#### Находка 6: Отсутствие вызовов `session.flush()` в сервисах
* **Пути к файлам**:
  1. `D:\Mynix_Control\backend\app\inventory\services\stock_service.py` (Строка 137)
  2. `D:\Mynix_Control\backend\app\pos\services\shift_service.py` (Строка 122)
* **Критичность**: Major (Логическая ошибка API)
* **Описание**: Методы `receive_stock()` и `record_expense()` сохраняют объект транзакции в сессии базы данных (`session.add(txn)`), но возвращают его без предварительного вызова `await session.flush()`. Из-за этого при формировании ответа от сервера сгенерированный базой данных ID транзакции возвращается клиенту как `null`.
* **Рекомендованный фикс**: Выполнить `await session.flush()` перед возвратом объекта.
* **Предлагаемый код**:
  ```python
  session.add(txn)
  await session.flush()
  return txn
  ```

---

### 2.2 Frontend (Клиентская часть на Flutter)

#### Находка 7: Нарушение лимита строк в файлах и отсутствие декомпозиции
* **Пути к файлам**:
  1. `D:\Mynix_Control\frontend\lib\features\inventory\view\inventory_screen.dart` (1477 строк)
  2. `D:\Mynix_Control\frontend\lib\features\settings\view\settings_screen.dart` (727 строк)
  3. `D:\Mynix_Control\frontend\lib\features\inventory\view\widgets\warehouse\dialogs\receive_document_dialog.dart` (401 строка)
  4. `D:\Mynix_Control\frontend\lib\features\inventory\view\widgets\warehouse\suppliers_tab.dart` (384 строки)
  5. `D:\Mynix_Control\frontend\lib\features\kitchen\view\kds_board.dart` (355 строк)
* **Критичность**: Major (Поддерживаемость кода / God Objects)
* **Описание**: Согласно стандартам проекта, длина файла UI не должна превышать 200-250 строк. Файлы выше содержат inline-виджеты табов, развесистые диалоги и дублирование, что затрудняет чтение и развитие приложения.
* **Рекомендованный фикс**: Разбить большие виджеты. Вынести табы управления инвентарем и настройки во внешние файлы в поддиректориях `widgets/`. Использовать уже существующие, но не импортируемые в настоящий момент модульные виджеты настроек (`GeneralSettings`, `HardwareSettings` и др.) из папки `widgets/settings/`.

---

#### Находка 8: Небезопасный парсинг данных и приведение типов в моделях
* **Пути к файлам**:
  1. `D:\Mynix_Control\frontend\lib\features\inventory\models\ingredient.dart` (Строка 30)
  2. `D:\Mynix_Control\frontend\lib\features\inventory\models\supplier.dart` (Строка 14)
  3. `D:\Mynix_Control\frontend\lib\features\inventory\models\document.dart` (Строка 79)
  4. `D:\Mynix_Control\frontend\lib\features\auth\bloc\auth_bloc.dart` (Строки 24, 43)
* **Критичность**: Critical (Нестабильность клиента)
* **Описание**: Данные из ответа бэкенда присваиваются без валидации типов и значений по умолчанию. Незащищенный вызов `DateTime.parse` выбрасывает `FormatException` и роняет экран при пустом или некорректном формате поля даты. Каст `profile['roles'] as List<dynamic>` вызывает сбой типов, если бэкенд возвращает роли в ином виде.
* **Рекомендованный фикс**: Использовать защищенные методы преобразования (`as String?`, `tryParse`, валидацию на массив).
* **Предлагаемый код**:
  *В `auth_bloc.dart`*:
  ```dart
  role: (profile['roles'] is List)
      ? (profile['roles'] as List).firstOrNull?.toString() ?? 'unknown'
      : 'unknown',
  ```
  *В `document.dart`*:
  ```dart
  date: json['date'] != null
      ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
      : DateTime.now(),
  ```

---

#### Находка 9: Отсутствие вызовов управления WebSocket-подключением KDS
* **Путь к файлу**: `D:\Mynix_Control\frontend\lib\features\kitchen\view\kds_board.dart`
* **Строки**: 21-27
* **Критичность**: Major (Логическая ошибка / Утечка ресурсов)
* **Описание**: Виджет `KdsBoard` запрашивает список активных заказов на этапе инициализации (`FetchActiveOrders`), но не инициирует событие `ConnectKitchen` для запуска прослушивания вебсокета. Экран кухни не получает обновления в реальном времени. Кроме того, нет метода `dispose` с вызовом `DisconnectKitchen()`, что оставляет сокет открытым при уходе с экрана KDS (утечка соединений).
* **Рекомендованный фикс**: Интегрировать события подключения/отключения вебсокета в жизненный цикл виджета, передавая `tenantId` из состояния авторизации при подключении.
* **Предлагаемый код**:
  ```dart
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<KitchenBloc>().add(FetchActiveOrders());
      context.read<KitchenBloc>().add(ConnectKitchen(authState.tenantId)); // Подключение WS
    }
  }

  @override
  void dispose() {
    context.read<KitchenBloc>().add(DisconnectKitchen()); // Очистка WS
    super.dispose();
  }
  ```

---

#### Находка 10: Прямое инстанцирование репозитория в UI
* **Путь к файлу**: `D:\Mynix_Control\frontend\lib\features\analytics\view\analytics_dashboard_screen.dart`
* **Строка**: 24
* **Критичность**: Major (Нарушение сетевых стандартов)
* **Описание**: Виджет `AnalyticsDashboardScreen` инстанцирует `AnalyticsRepository` напрямую, передавая ему `apiClient.dio`, вместо использования `RepositoryProvider`. Это нарушает запрет на прямое создание сетевых зависимостей внутри слоев представления.
* **Рекомендованный фикс**: Запрашивать репозиторий через контекст.
* **Предлагаемый код**:
  ```dart
  create: (context) => AnalyticsBloc(context.read<AnalyticsRepository>())
  ```

---

#### Находка 11: Глобальное мутабельное состояние в классе темы AppColors
* **Путь к файлу**: `D:\Mynix_Control\frontend\lib\core\theme\app_colors.dart`
* **Строки**: 53-60
* **Критичность**: Major (Небезопасное состояние)
* **Описание**: Поля темы (`brandPrimary` и т.д.) объявлены как изменяемые статические переменные, перезаписываемые при вызове `applyThemeVariant`. Это создает состояние гонки в многопоточности и не вызывает авто-перерисовку UI для тех виджетов, которые не перехватывают событие смены темы явно.
* **Рекомендованный фикс**: Использовать `ThemeData` и механизм `ThemeExtension` для кастомных цветовых схем бренда.

---

### 2.3 Сквозные проблемы и интеграция (Cross-Cutting Issues)

#### Находка 12: Ошибка типов PIN-кода при входе
* **Пути к файлам**:
  - Клиент: `D:\Mynix_Control\frontend\lib\features\auth\repository\auth_repository.dart` (Строка 36)
  - Сервер: `D:\Mynix_Control\backend\app\users\models.py` (Строка 175)
* **Критичность**: Major (Неработоспособность входа по PIN)
* **Описание**: Клиент отправляет параметр `tenant_id` как строку (`String`), в то время как модель валидации бэкенда `PinLoginRequest` ожидает целое число (`int`). При попытке авторизации сервер отклоняет запрос с ошибкой `422 Unprocessable Entity`.
* **Рекомендованный фикс**: Преобразовать `tenant_id` в целое число перед сериализацией на стороне Flutter.
* **Предлагаемый код**:
  ```dart
  // auth_repository.dart
  'tenant_id': int.tryParse(tenantId) ?? 0,
  ```

---

#### Находка 13: Рассогласование прав PBAC (Блокировка интерфейса)
* **Пути к файлам**:
  - Ограничения роутеров: `pos_menu_router.py`, `document_router.py`, `kds_router.py`
  - База сидов: `D:\Mynix_Control\backend\app\users\seed.py`
* **Критичность**: Major (Логическая ошибка прав)
* **Описание**: Имена прав, требуемые на бэкенде, отсутствуют в БД сидов:
  - Права `"pos:menu_view"` (требуется в меню POS) нет в сидах, там присутствует только `"menu:view"`.
  - Права `"inventory:read"` и `"inventory:write"` отсутствуют, вместо них сидируются `"inventory:view"` и `"inventory:manage"`.
  - Права `"kitchen:manage"` для отметки готовности нет в сидах, вместо него используется `"orders:update_status"`.
* **Рекомендованный фикс**: Привести права в декораторах API-эндоинтов к сидируемым аналогам (см. фикс для Находки 2).

---

#### Находка 14: Ошибки в скриптах доработок БД и неверный путь к Alembic
* **Пути к файлам**:
  - `D:\Mynix_Control\backend\app\database.py` (Строка 49)
  - `D:\Mynix_Control\backend\alter_db_postgres.py` (Строка 9)
  - `D:\Mynix_Control\backend\alter_db_postgres_attributes.py` (Строка 5)
* **Критичность**: Major (Сбои деплоя и миграций)
* **Описание**:
  - `database.py` жестко прописывает путь `D:\Mynix_Control\SCafe`, который не существует, из-за чего автоматические миграции при старте приложения не запускаются.
  - Скрипты изменения структуры БД (`alter_db_postgres*.py`) делают запросы вида `ALTER TABLE menu_items` без указания схемы PostgreSQL и без установки `search_path`. Поскольку таблицы тенантов создаются внутри соответствующих схем тенантов, данные скрипты завершаются ошибкой отсутствия таблиц в схеме `public`.
  - Скрипт `alter_db_postgres_attributes.py` имеет битый импорт из-за прописанного в `sys.path` несуществующего пути `SCafe`.
* **Рекомендованный фикс**: Обновить путь к проекту в `database.py` до `backend/`. В скриптах доработок БД перед выполнением SQL-кода вызывать команду установки схемы, например `SET search_path TO tenant_1`, перебирая схемы тенантов.

---

#### Находка 15: Неполная сериализация API (Потеря полей)
* **Пути к файлам**:
  1. `D:\Mynix_Control\backend\app\inventory\services\ingredient_service.py` (Строки 44-54)
  2. `D:\Mynix_Control\backend\app\inventory\services\menu_service.py` (Строки 125-138)
* **Критичность**: Minor (Потеря пользовательских настроек)
* **Описание**: При конвертации объектов бэкенда в структуры `IngredientRead` и `MenuItemRead` опущены поля `sort_order` и `attributes`. Данные сохраняются в БД, но не передаются на фронтенд, возвращаясь как дефолтные `0` или `null`.
* **Рекомендованный фикс**: Передавать эти поля при конструировании объектов ответа в сервисах.

---

## 3. Ревизия неиспользуемых файлов и артефактов

В директориях проекта обнаружено значительное количество мертвых файлов и устаревших скриптов:

* **Модуль принтеров**: `backend/app/hardware/` — полностью не используется и не импортируется.
* **Дублирующий/Мертвый код во Flutter**:
  - `lib/features/inventory/repository/parts/` — файлы содержат части репозитория (`categories_part.dart` и др.), но не объявлены в основном репозитории.
  - `lib/features/inventory/view/widgets/retail_product_modal.dart`, `bulk_receipt_view.dart` — не используются в интерфейсе.
* **Скрипты в корневой папке**: В `D:\Mynix_Control\` содержатся файлы `smart_restore*.py`, `recover_*.py`, а во `frontend/` — `replace_currency.py` и `replace_icons.py`. Их необходимо переместить в архив или удалить.

---
*Конец отчета.*
