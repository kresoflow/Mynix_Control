# ==============================================================================
#  Kreso Flow — POS: Cash Operation Service
#  [ИНВАРИАНТ] [ФИНАНСЫ] Учет служебных внесений, расходов и инкассации смены.
#  [ТРАНЗАКЦИЯ] Атомарное обновление баланса кассы и журнала транзакций.
# ==============================================================================

from typing import List, Optional, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, func

from app.pos.models import (
    Shift, CashTransaction, CashTransactionType,
    CashOperation, CashOperationType, CashOperationCreate,
    CashOperationRead, CashOperationsSummary
)
from app.pos.services.shift_service import get_open_shift, calculate_expected_cash
from app.users.models import User


# ──────────────────────────────────────────────────────────────────────────────
#  1. Создание кассовой операции (Внесение / Инкассация / Расход)
# ──────────────────────────────────────────────────────────────────────────────

async def create_cash_operation(
    session: AsyncSession,
    user_id: int,
    data: CashOperationCreate,
) -> Tuple[CashOperation, float]:
    """
    [ТРАНЗАКЦИЯ] Проводит кассовую операцию и фиксирует движение средств.
    [ИНВАРИАНТ] [ФИНАНСЫ] Сумма строго > 0.
    [БЕЗОПАСНОСТЬ] Смена обязана быть открыта.
    [ФИНАНСЫ] При списании/инкассации проверяется достаточность средств в кассе.
    """
    if data.amount <= 0:
        raise ValueError("Сумма кассовой операции должна быть строго больше нуля.")

    # 1. Поиск и валидация активной смены
    if data.shift_id:
        stmt_shift = select(Shift).where(Shift.id == data.shift_id)
        res_shift = await session.execute(stmt_shift)
        shift = res_shift.scalar_one_or_none()
        if not shift:
            raise ValueError(f"Смена #{data.shift_id} не найдена.")
        if not shift.is_open:
            raise ValueError(f"Смена #{data.shift_id} уже закрыта. Операции запрещены.")
    else:
        shift = await get_open_shift(session)
        if not shift:
            raise ValueError("Нет открытой кассовой смены. Откройте смену перед выполнением операции.")

    # 2. [ФИНАНСЫ] Проверка текущего остатка в кассе при изъятии/расходе
    current_cash = await calculate_expected_cash(session, shift.id, shift.opening_cash)

    if data.type == CashOperationType.WITHDRAWAL:
        if current_cash < data.amount:
            raise ValueError(
                f"Недостаточно наличных средств в кассе смены. "
                f"Текущий остаток: {current_cash:.2f} ₽, запрошено: {data.amount:.2f} ₽."
            )

    # 3. [ТРАНЗАКЦИЯ] Создание записи CashOperation
    operation = CashOperation(
        client_uuid=data.client_uuid,
        shift_id=shift.id,
        user_id=user_id,
        type=data.type,
        amount=round(data.amount, 2),
        category=data.category.strip() or "Общее",
        comment=data.comment.strip() if data.comment else None,
    )
    session.add(operation)

    # 4. [СИНХРОНИЗАЦИЯ] Создание сопутствующей CashTransaction для непрерывности X/Z-отчетов
    desc = f"[{operation.category}] {operation.comment or ''}".strip()
    if operation.type == CashOperationType.DEPOSIT:
        txn_type = CashTransactionType.INCOME
        desc = f"Внесение: {desc}"
    else:
        txn_type = CashTransactionType.WITHDRAWAL
        desc = f"Расход/Инкассация: {desc}"

    cash_txn = CashTransaction(
        shift_id=shift.id,
        user_id=user_id,
        type=txn_type,
        amount=operation.amount,
        description=desc[:255],
    )
    session.add(cash_txn)
    await session.flush()

    # Расчет нового актуального баланса
    new_balance = await calculate_expected_cash(session, shift.id, shift.opening_cash)
    return operation, new_balance


# ──────────────────────────────────────────────────────────────────────────────
#  2. Получение списка кассовых операций
# ──────────────────────────────────────────────────────────────────────────────

async def list_cash_operations(
    session: AsyncSession,
    shift_id: Optional[int] = None,
    limit: int = 50,
    offset: int = 0,
) -> List[CashOperationRead]:
    """Получает список операций по кассе с именами пользователей."""
    stmt = select(CashOperation).order_by(CashOperation.created_at.desc())
    if shift_id is not None:
        stmt = stmt.where(CashOperation.shift_id == shift_id)

    stmt = stmt.limit(limit).offset(offset)
    res = await session.execute(stmt)
    operations = list(res.scalars().all())

    if not operations:
        return []

    # Подгрузка имен сотрудников
    user_ids = {op.user_id for op in operations if op.user_id}
    users_map = {}
    if user_ids:
        stmt_users = select(User.id, User.full_name, User.username).where(User.id.in_(user_ids))
        res_users = await session.execute(stmt_users)
        for uid, full_name, username in res_users.all():
            users_map[uid] = full_name or f"@{username}"

    return [
        CashOperationRead(
            id=op.id,
            client_uuid=op.client_uuid,
            shift_id=op.shift_id,
            user_id=op.user_id,
            user_name=users_map.get(op.user_id, f"Сотрудник #{op.user_id}"),
            type=op.type,
            amount=op.amount,
            category=op.category,
            comment=op.comment,
            created_at=op.created_at,
        )
        for op in operations
    ]


# ──────────────────────────────────────────────────────────────────────────────
#  3. Сводка по кассовым операциям смены
# ──────────────────────────────────────────────────────────────────────────────

async def get_cash_operations_summary(
    session: AsyncSession,
    shift_id: Optional[int] = None,
) -> CashOperationsSummary:
    """Возвращает агрегированную статистику по кассовым операциям за смену."""
    if shift_id:
        stmt_shift = select(Shift).where(Shift.id == shift_id)
        res_shift = await session.execute(stmt_shift)
        shift = res_shift.scalar_one_or_none()
        if not shift:
            raise ValueError(f"Смена #{shift_id} не найдена.")
    else:
        shift = await get_open_shift(session)
        if not shift:
            raise ValueError("Нет активной смены для формирования отчета.")

    # 1. Сумма внесений
    stmt_dep = select(func.coalesce(func.sum(CashOperation.amount), 0)).where(
        CashOperation.shift_id == shift.id,
        CashOperation.type == CashOperationType.DEPOSIT.value,
    )
    res_dep = await session.execute(stmt_dep)
    total_deposits = float(res_dep.scalar() or 0.0)

    # 2. Сумма расходов и инкассаций
    stmt_with = select(func.coalesce(func.sum(CashOperation.amount), 0)).where(
        CashOperation.shift_id == shift.id,
        CashOperation.type == CashOperationType.WITHDRAWAL.value,
    )
    res_with = await session.execute(stmt_with)
    total_withdrawals = float(res_with.scalar() or 0.0)

    # 3. Текущий баланс и список операций
    current_cash = await calculate_expected_cash(session, shift.id, shift.opening_cash)
    operations = await list_cash_operations(session, shift_id=shift.id, limit=100)

    return CashOperationsSummary(
        shift_id=shift.id,
        opening_cash=shift.opening_cash,
        total_deposits=round(total_deposits, 2),
        total_withdrawals=round(total_withdrawals, 2),
        current_expected_cash=round(current_cash, 2),
        operations_count=len(operations),
        operations=operations,
    )
