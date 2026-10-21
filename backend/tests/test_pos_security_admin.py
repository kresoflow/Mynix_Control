# ==============================================================================
# ТЕСТЫ: Управление безопасностью кассы (Слепая касса, Мастер-PIN и PBAC)
# ДОМЕН: backend/tests/test_pos_security_admin.py
# ==============================================================================

import pytest
from httpx import AsyncClient

from app.users.models import Tenant, Role, User, UserRole
from app.users import services as user_svc
from app.users.permissions import Perm


# ─── 1. Тест управления безопасностью кассы владельцем и PBAC ─────────────────

@pytest.mark.asyncio
async def test_pos_security_settings_and_master_pin_lifecycle(async_client: AsyncClient, db_session):
    """
    Проверка полного цикла управления безопасностью кассы:
    1. Чтение настроек GET /settings/ возвращает blind_pos_enabled и pos_master_pin_set (без открытого пароля).
    2. Попытка установить некорректный PIN (буквы, слишком короткий/длинный) возвращает 400 Bad Request.
    3. Успешное обновление параметров blind_pos_enabled=False и смены master_pin на '7890'.
    4. Проверка разблокировки через POST /auth/verify-pin с новым мастер-PIN.
    5. Проверка флага blind_pos_enabled в GET /auth/me.
    """
    from app.users.routers.auth_router import _pin_failed_attempts, _pin_locked_keys
    _pin_failed_attempts.clear()
    _pin_locked_keys.clear()

    tenant = Tenant(
        name="Security POS Cafe",
        schema_name="public",
        is_active=True,
        blind_pos_enabled=True,
        pos_master_pin="1234",
    )
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    owner_role = Role(name="owner", is_superuser=True)
    db_session.add(owner_role)
    await db_session.commit()
    await db_session.refresh(owner_role)

    owner = User(
        tenant_id=tenant.id,
        username="owner_sec",
        full_name="Cafe Owner",
        hashed_password="hash",
        is_active=True,
    )
    db_session.add(owner)
    await db_session.commit()
    await db_session.refresh(owner)

    db_session.add(UserRole(user_id=owner.id, role_id=owner_role.id))
    await db_session.commit()

    owner_token = user_svc.create_access_token(
        user_id=owner.id,
        tenant_id=tenant.id,
        permissions=[Perm.SETTINGS_MANAGE, Perm.POS_CASH_OPERATIONS],
    )
    owner_headers = {"Authorization": f"Bearer {owner_token}"}

    # 1. GET /settings/ - проверка отсутствия открытого PIN
    get_resp = await async_client.get("/api/v1/settings/", headers=owner_headers)
    assert get_resp.status_code == 200
    data = get_resp.json()
    assert data["blind_pos_enabled"] is True
    assert data["pos_master_pin_set"] is True
    assert "pos_master_pin" not in data, "Утечка PIN в открытом виде запрещена!"

    # 2. Невалидный PIN: буквы -> 400
    bad_resp1 = await async_client.put(
        "/api/v1/settings/",
        json={
            "use_kds": True,
            "use_orders": True,
            "enable_inventory_deduction": True,
            "pos_master_pin": "abcd",
        },
        headers=owner_headers,
    )
    assert bad_resp1.status_code == 400
    assert "PIN-код" in bad_resp1.json()["detail"]

    # Невалидный PIN: длина < 4
    bad_resp2 = await async_client.put(
        "/api/v1/settings/",
        json={
            "use_kds": True,
            "use_orders": True,
            "enable_inventory_deduction": True,
            "pos_master_pin": "12",
        },
        headers=owner_headers,
    )
    assert bad_resp2.status_code == 400

    # 3. Валидное обновление: отключение слепой кассы и установка PIN 7890
    update_resp = await async_client.put(
        "/api/v1/settings/",
        json={
            "use_kds": True,
            "use_orders": True,
            "enable_inventory_deduction": True,
            "blind_pos_enabled": False,
            "pos_master_pin": "7890",
        },
        headers=owner_headers,
    )
    assert update_resp.status_code == 200
    updated_data = update_resp.json()
    assert updated_data["blind_pos_enabled"] is False
    assert updated_data["pos_master_pin_set"] is True
    assert "pos_master_pin" not in updated_data

    # 4. Проверка разблокировки через новый мастер-PIN в verify-pin
    pin_resp = await async_client.post(
        "/api/v1/auth/verify-pin",
        json={"pin_code": "7890"},
        headers=owner_headers,
    )
    assert pin_resp.status_code == 200
    assert pin_resp.json()["valid"] is True
    assert pin_resp.json()["username"] == "Мастер-PIN кассы"

    # 5. Проверка флага blind_pos_enabled в GET /auth/me
    me_resp = await async_client.get("/api/v1/auth/me", headers=owner_headers)
    assert me_resp.status_code == 200
    assert me_resp.json()["blind_pos_enabled"] is False


@pytest.mark.asyncio
async def test_cashier_cannot_access_or_modify_settings(async_client: AsyncClient, db_session):
    """
    PBAC Гарантия:
    Кассир без права settings:manage получает 403 Forbidden при попытке
    прочитать или изменить настройки безопасности кассы.
    """
    tenant = Tenant(name="PBAC Security Tenant", schema_name="public", is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    cashier = User(
        tenant_id=tenant.id,
        username="cashier_bob",
        full_name="Bob Cashier",
        hashed_password="hash",
        is_active=True,
    )
    db_session.add(cashier)
    await db_session.commit()
    await db_session.refresh(cashier)

    cashier_token = user_svc.create_access_token(
        user_id=cashier.id,
        tenant_id=tenant.id,
        permissions=[Perm.ORDERS_CREATE, Perm.POS_CASH_OPERATIONS],
    )
    cashier_headers = {"Authorization": f"Bearer {cashier_token}"}

    # Попытка чтения настроек -> 403
    get_res = await async_client.get("/api/v1/settings/", headers=cashier_headers)
    assert get_res.status_code == 403

    # Попытка изменения настроек -> 403
    put_res = await async_client.put(
        "/api/v1/settings/",
        json={
            "use_kds": True,
            "use_orders": True,
            "enable_inventory_deduction": True,
            "blind_pos_enabled": False,
        },
        headers=cashier_headers,
    )
    assert put_res.status_code == 403
