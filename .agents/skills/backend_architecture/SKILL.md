---
name: backend_architecture
description: Стандарты архитектуры бэкенда Kreso Flow (FastAPI, Async SQLAlchemy, PostgreSQL search_path, PBAC Perm, единые транзакции, Reader/Writer). Активируй при создании роутеров, сервисов, моделей, миграций и оптимизации бэкенда.
---

# Backend Architecture, Data Integrity & Concurrency Playbook

Операционный плейбук бэкенд-архитектуры Kreso Flow (**FastAPI + Async SQLAlchemy/SQLModel + PostgreSQL Multi-Tenancy через `search_path` + PBAC `Perm`**).

---

## 1. Архитектурные границы и разделение слоев (Layering)

Каждый доменный модуль бэкенда (`backend/app/<domain>/`) строится по строгой трехзвенной структуре:

```
[HTTP Request]
      │
      ▼
┌────────────────────────────────────────────────────────┐
│ 1. Routers (routers/*_router.py)                       │
│    • Только маппинг URL, Pydantic DTO и Depends()      │
│    • PBAC авторизация через Perm.<ACTION>              │
│    • Возврат HTTP статусов (200, 201, 400, 404, 409)   │
└──────────────────────────┬─────────────────────────────┘
                           │ Вызов UseCase / Service
┌──────────────────────────▼─────────────────────────────┐
│ 2. Services (services/)                                │
│    • *_query_service.py (Reader): Чтение, фильтры      │
│    • *_workflow_service.py (Writer): Единые транзакции │
│    • Никакого прямого знания о Request/HTTPResponse    │
└──────────────────────────┬─────────────────────────────┘
                           │ ORM Models / search_path
┌──────────────────────────▼─────────────────────────────┐
│ 3. Models (models.py или models/*)                     │
│    • Наследование от TenantModel (БЕЗ tenant_id)       │
│    • Pydantic v2 DTO триада: Create, Update, Read      │
└────────────────────────────────────────────────────────┘
```

---

## 2. Рецепт А: Транзакционный Workflow Service (Writer)

*Используется для любых мутаций данных (списание склада, проведение чека, пополнение карты, инкассация).*

```python
# ==============================================================================
# МОДУЛЬ: Транзакционный сервис с защитой от Race Conditions и Double Spending
# ДОМЕН: backend/app/<domain>/services/<domain>_workflow_service.py
# ==============================================================================
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import select
from fastapi import HTTPException, status
from app.base_model import TenantModel

class DomainWorkflowService:
    @staticmethod
    async def process_transaction(
        session: AsyncSession,
        item_id: int,
        amount: float,
        client_uuid: str | None = None,
    ) -> DomainEntity:
        """
        [ТРАНЗАКЦИЯ] Единая атомарная транзакция изменения связанных сущностей.
        [БЕЗОПАСНОСТЬ] Пессимистическая блокировка with_for_update() исключает
        состояние гонки (Race Condition) и овердрафт при параллельных запросах.
        """
        # [ИНВАРИАНТ] Идемпотентность: проверка повторного запроса с тем же client_uuid
        if client_uuid:
            existing_tx = (
                await session.exec(
                    select(TransactionAudit).where(TransactionAudit.client_uuid == client_uuid)
                )
            ).first()
            if existing_tx:
                # [ИНВАРИАНТ] Идемпотентный no-op: возвращаем исходную сущность со статусом 200
                return (
                    await session.exec(select(DomainEntity).where(DomainEntity.id == existing_tx.entity_id))
                ).one()

        # [ТРАНЗАКЦИЯ] Все связанные изменения строго внутри session.begin()
        async with session.begin():
            # 1. Блокируем строку агрегата на чтение/запись до коммита транзакции
            stmt = (
                select(DomainEntity)
                .where(DomainEntity.id == item_id)
                .with_for_update()  # <-- Защита от Double Spending / Race Condition
                .options(selectinload(DomainEntity.sub_items))  # <-- Защита от MissingGreenlet
            )
            entity = (await session.exec(stmt)).first()
            if not entity:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Запрашиваемый ресурс не найден",
                )

            # 2. Проверка бизнес-инварианта (например, баланс / остаток на складе)
            if entity.balance < amount:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Недостаточно средств/остатка: доступно {entity.balance}, списание {amount}",
                )

            # 3. Атомарное изменение состояния
            entity.balance -= amount
            session.add(entity)

            # 4. Создание записи аудита движения
            audit_record = TransactionAudit(
                entity_id=entity.id,
                amount=-amount,
                client_uuid=client_uuid,
            )
            session.add(audit_record)

            # Автоматический commit() при успешном выходе из блока begin()
            # При любом исключении происходит немедленный rollback()

        await session.refresh(entity)
        return entity
```

---

## 3. Рецепт Б: Высокопроизводительный Query Service (Reader)

*Используется для списков, выборок, аналитики и поиска с защитой от MissingGreenlet и N+1.*

```python
# ==============================================================================
# МОДУЛЬ: Сервис безопасного и быстрого чтения данных (Reader)
# ДОМЕН: backend/app/<domain>/services/<domain>_query_service.py
# ==============================================================================
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload, joinedload
from sqlmodel import select, col, func
from typing import List, Tuple

class DomainQueryService:
    @staticmethod
    async def get_items_paged(
        session: AsyncSession,
        skip: int = 0,
        limit: int = 50,
        search_query: str | None = None,
        is_active_only: bool = True,
    ) -> Tuple[List[DomainEntity], int]:
        """
        [ИНВАРИАНТ] Безопасная жадная загрузка связей исключает MissingGreenlet.
        Пагинация защищена лимитом limit <= 200.
        """
        safe_limit = min(limit, 200)

        # 1. Базовый запрос с жадной загрузкой (selectinload для коллекций)
        stmt = (
            select(DomainEntity)
            .options(
                selectinload(DomainEntity.sub_items),       # 1-to-many связь
                joinedload(DomainEntity.parent_category),   # many-to-one связь
            )
        )

        count_stmt = select(func.count(col(DomainEntity.id)))

        # 2. Предикаты фильтрации
        if is_active_only:
            stmt = stmt.where(DomainEntity.is_active == True)
            count_stmt = count_stmt.where(DomainEntity.is_active == True)

        if search_query:
            stmt = stmt.where(col(DomainEntity.name).ilike(f"%{search_query.strip()}%"))
            count_stmt = count_stmt.where(col(DomainEntity.name).ilike(f"%{search_query.strip()}%"))

        # 3. Выполнение подсчета и пагинации
        total_count = (await session.exec(count_stmt)).one()
        stmt = stmt.order_by(DomainEntity.id.desc()).offset(skip).limit(safe_limit)
        items = (await session.exec(stmt)).all()

        return items, total_count
```

---

## 4. Рецепт В: Pydantic v2 DTO Триада (Контракт API)

*Запрещено возвращать ORM-модели напрямую в роутере во избежание циклических ссылок и утечек.*

```python
# ==============================================================================
# МОДУЛЬ: Pydantic v2 DTO Схемы (Валидация ввода и сериализация ответа)
# ДОМЕН: backend/app/<domain>/schemas.py
# ==============================================================================
from pydantic import BaseModel, ConfigDict, Field
from typing import Optional, List
from datetime import datetime

# ─── 1. Входные данные создания (Create) ──────────────────────────────────────
class ItemCreate(BaseModel):
    name: str = Field(min_length=1, max_length=150, description="Название позиции")
    price: float = Field(ge=0.0, description="Цена продажи (>= 0)")
    category_id: Optional[int] = Field(default=None, description="ID категории")
    client_uuid: Optional[str] = Field(default=None, max_length=64, description="UUID для идемпотентности")

# ─── 2. Входные данные обновления (Update) ────────────────────────────────────
class ItemUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=150)
    price: Optional[float] = Field(default=None, ge=0.0)
    is_active: Optional[bool] = Field(default=None)

# ─── 3. Выходные данные ответа (Read) ─────────────────────────────────────────
class ItemRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)  # [ИНВАРИАНТ] Безопасный маппинг из ORM

    id: int
    name: str
    price: float
    is_active: bool
    created_at: datetime
```

---

## 5. Рецепт Г: Мультитенантность и Миграции схем

### 1. Создание НОВОЙ таблицы
1. Модель наследуется от `TenantModel` (из `app.base_model`), колонка `tenant_id` **СТРОГО ЗАПРЕЩЕНА**.
2. Обязательно добавить импорт модели в `backend/app/database.py` внутри функций `init_tenant_schema` и `auto_migrate_tenant_schemas`.

### 2. Изменение СУЩЕСТВУЮЩЕЙ таблицы (SQL-патчи)
Для каждого изменения структуры создавай идемпотентный SQL-файл:  
`backend/migrations/tenant_patches/<номер>_<описание>.sql`:

```sql
-- ==============================================================================
-- Kreso Flow: Tenant Schema Migration Patch
-- [ИНВАРИАНТ] Идемпотентный патч с плейсхолдером "{schema}"
-- ==============================================================================

ALTER TABLE "{schema}".items ADD COLUMN IF NOT EXISTS barcode VARCHAR(64);
CREATE INDEX IF NOT EXISTS ix_items_barcode ON "{schema}".items (barcode);
```

---

## 6. Рецепт Д: Стандарты HTTP-статусов и Ошибок

- **`HTTP 201 CREATED`**: Успешное создание новой сущности.
- **`HTTP 200 OK`**: Успешное чтение/обновление ИЛИ идемпотентный повтор запроса с тем же `client_uuid`.
- **`HTTP 400 BAD REQUEST`**: Бизнес-ошибки валидации (овердрафт, недостаточно средств, смена закрыта).
- **`HTTP 403 FORBIDDEN`**: Отсутствие прав в PBAC-реестре `Perm`.
- **`HTTP 404 NOT FOUND`**: Ресурс не существует в схеме текущего тенанта (включая IDOR-попытки).
- **`HTTP 409 CONFLICT`**: Попытка зарегистрировать дубликат уникального бизнес-ключа (штрихкод, артикул, номер карты).

---

## 7. Детерминированный чек-лист проверки (DoD)

После любых правок бэкенда выполни из корня репозитория:

```bash
python scripts/verify_rules.py --target <имя_модуля>
pytest backend/tests/test_<name>.py -v
```
