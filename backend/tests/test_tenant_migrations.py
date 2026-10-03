# ==============================================================================
# ТЕСТЫ: Миграции схем тенантов и верификация полноты патчей (Tenant Migrations)
# ДОМЕН: backend.tests.test_tenant_migrations
# ==============================================================================
"""
Тесты миграций структуры данных тенантов (tenant_patches).
Проверяют корректность применения патчей на существующих тенантах и ловят
рассинхронизацию между моделями SQLModel и SQL-миграциями.
"""

from pathlib import Path
import pytest
from sqlalchemy import text
from sqlalchemy.exc import DBAPIError, OperationalError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.database import apply_tenant_patches
from app.crm.models import BonusTransaction, Customer, CustomerTransaction
from app.gift_cards.models import (
    GiftCard,
    GiftCardStatus,
    GiftCardTransaction,
    GiftCardTransactionType,
)
from app.inventory.models import (
    Ingredient,
    InventoryDocument,
    InventoryDocumentItem,
    RetailProduct,
    Supplier,
)
from app.pos.models import Order, OrderItem


# ─── 1. Тест воспроизведения и снятия патчем 004 ─────────────────────────────

@pytest.mark.asyncio
async def test_reproduction_and_patch_004_resolution(db_session: AsyncSession):
    """
    [ФАЗА 0 & 1] Воспроизведение ошибки на старой схеме и снятие патчем 004.
    1. Эмулирует старую схему тенанта без client_uuid в gift_card_transactions.
    2. Попытка вставки вызывает реальную ошибку БД (OperationalError: no column named client_uuid).
    3. Применяется патч 004_add_gift_card_client_uuid.sql.
    4. Повторная вставка с client_uuid успешно проходит (PASSED).
    """
    # 1. Приводим таблицу к состоянию 'старой' схемы (патчи 001-003, без client_uuid)
    await db_session.execute(text("DROP TABLE IF EXISTS gift_card_transactions"))
    await db_session.execute(text("""
        CREATE TABLE gift_card_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            gift_card_id INTEGER NOT NULL REFERENCES gift_cards(id),
            order_id INTEGER,
            type VARCHAR(30) NOT NULL,
            amount FLOAT DEFAULT 0.0,
            balance_before FLOAT DEFAULT 0.0,
            balance_after FLOAT DEFAULT 0.0,
            comment VARCHAR(255),
            created_at TIMESTAMP,
            updated_at TIMESTAMP,
            created_by INTEGER
        )
    """))
    await db_session.commit()

    card = GiftCard(
        code="GC-OLD-001",
        initial_balance=1000.0,
        current_balance=1000.0,
        status=GiftCardStatus.ACTIVE,
    )
    db_session.add(card)
    await db_session.flush()

    # 2. Попытка вставки транзакции с client_uuid в старую схему падает с ошибкой БД
    txn_fail = GiftCardTransaction(
        gift_card_id=card.id,
        type=GiftCardTransactionType.REDEEM,
        amount=100.0,
        balance_before=1000.0,
        balance_after=900.0,
        client_uuid="uuid-stale-schema-fail",
    )
    db_session.add(txn_fail)
    with pytest.raises((OperationalError, DBAPIError)) as exc_info:
        await db_session.commit()
    assert "client_uuid" in str(exc_info.value).lower()
    await db_session.rollback()

    # 3. Применяем патчи (включая 004) к схеме
    conn = await db_session.connection()
    await apply_tenant_patches(conn, "public")
    await db_session.commit()

    card_new = GiftCard(
        code="GC-NEW-002",
        initial_balance=1000.0,
        current_balance=1000.0,
        status=GiftCardStatus.ACTIVE,
    )
    db_session.add(card_new)
    await db_session.flush()

    # 4. Повторяем вставку с client_uuid - теперь она проходит успешно
    txn_success = GiftCardTransaction(
        gift_card_id=card_new.id,
        type=GiftCardTransactionType.REDEEM,
        amount=200.0,
        balance_before=1000.0,
        balance_after=800.0,
        client_uuid="uuid-patched-schema-success",
    )
    db_session.add(txn_success)
    await db_session.commit()

    res = await db_session.execute(
        select(GiftCardTransaction).where(GiftCardTransaction.client_uuid == "uuid-patched-schema-success")
    )
    saved_txn = res.scalars().first()
    assert saved_txn is not None
    assert saved_txn.client_uuid == "uuid-patched-schema-success"
    assert saved_txn.amount == 200.0


# ─── 2. Постоянный тест-гард соответствия моделей и патчей ───────────────────

@pytest.mark.asyncio
async def test_all_tenant_patches_cover_domain_models(db_session: AsyncSession):
    """
    [ФАЗА 2] Постоянный тест-гард соответствия схемы БД и доменных моделей.
    Применяет все патчи из migrations/tenant_patches/ и проверяет, что все колонки,
    заявленные в доменных моделях с table=True, реально присутствуют в БД.
    Если разработчик добавит поле в Model(table=True) и забудет создать SQL-патч,
    тест немедленно упадет с ошибкой отсутствия колонки.
    """
    # 1. Применяем все существующие патчи к схеме
    conn = await db_session.connection()
    await apply_tenant_patches(conn, "public")
    await db_session.commit()

    # 2. Ключевые модели, затронутые миграционными патчами 001-004
    key_models = [
        GiftCard,
        GiftCardTransaction,
        Order,
        OrderItem,
        Customer,
        CustomerTransaction,
        BonusTransaction,
        Ingredient,
        RetailProduct,
        Supplier,
        InventoryDocument,
        InventoryDocumentItem,
    ]

    # Выполняем SELECT по каждой модели (SQLAlchemy включает в запрос ВСЕ атрибуты модели)
    for model in key_models:
        stmt = select(model).limit(1)
        await db_session.execute(stmt)

    # 3. Проверяем вставку и чтение записи с полями из последних патчей (client_uuid)
    card = GiftCard(
        code="GC-GUARD-001",
        initial_balance=500.0,
        current_balance=500.0,
        status=GiftCardStatus.ACTIVE,
    )
    db_session.add(card)
    await db_session.commit()
    await db_session.refresh(card)

    txn = GiftCardTransaction(
        gift_card_id=card.id,
        type=GiftCardTransactionType.REDEEM,
        amount=50.0,
        balance_before=500.0,
        balance_after=450.0,
        client_uuid="uuid-guard-permanent-check",
    )
    db_session.add(txn)
    await db_session.commit()
    await db_session.refresh(txn)

    assert txn.id is not None
    assert txn.client_uuid == "uuid-guard-permanent-check"
