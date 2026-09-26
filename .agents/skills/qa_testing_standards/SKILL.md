---
name: qa_testing_standards
description: Стандарты тестирования Kreso Flow (pytest, flutter test, dart analyze, PBAC, search_path). Активируй при написании unit/e2e тестов, верификации PBAC, регрессиях и валидации DoD.
---

# QA, Security & Architecture Testing Playbook

Операционный плейбук обеспечения качества для стека Kreso Flow (**FastAPI + PostgreSQL Multi-Tenancy + PBAC + Flutter BLoC**).

---

## 1. Обязательный квадривиум тестов бэкенда (`backend/tests/test_<module>.py`)

Каждый новый сервис, эндпоинт или сущность БД обязаны содержать 4 типа тестов до передачи в оркестратор:

```python
# ==============================================================================
# МОДУЛЬ: Тесты безопасности, инвариантов и транзакций модуля <ИМЯ>
# ДОМЕН: backend.tests.test_<name>
# ==============================================================================
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from app.users.permissions import Perm
from app.users.models import Tenant, Role, User, UserRole, Permission, RolePermission
from app.users import services as user_svc

# ─── Вспомогательный хелпер генерации изолированных клиентов тенантов ─────────
async def make_tenant_client(
    db_session: AsyncSession,
    async_client: AsyncClient,
    tenant_name: str,
    schema_name: str,
    permissions: list[str] | None = None,
) -> tuple[Tenant, dict[str, str]]:
    """[БЕЗОПАСНОСТЬ] Создает тенант, роль, пользователя с правами в БД и возвращает Bearer-заголовки."""
    tenant = Tenant(name=tenant_name, schema_name=schema_name, is_active=True)
    db_session.add(tenant)
    await db_session.commit()
    await db_session.refresh(tenant)

    user = User(
        tenant_id=tenant.id,
        username=f"usr_{schema_name}_{tenant.id}",
        full_name=f"User {tenant_name}",
        hashed_password="hash",
        is_active=True,
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    if permissions:
        role = Role(name=f"Role_{schema_name}_{tenant.id}", is_superuser=False, tenant_id=tenant.id)
        db_session.add(role)
        await db_session.commit()
        await db_session.refresh(role)

        for code in permissions:
            res_p = await db_session.execute(select(Permission).where(Permission.code == code))
            perm = res_p.scalars().first()
            if not perm:
                perm = Permission(code=code, description=f"Perm {code}")
                db_session.add(perm)
                await db_session.commit()
                await db_session.refresh(perm)
            db_session.add(RolePermission(role_id=role.id, permission_id=perm.id))
        db_session.add(UserRole(user_id=user.id, role_id=role.id))
        await db_session.commit()

    token = user_svc.create_access_token(
        user_id=user.id,
        tenant_id=tenant.id,
        permissions=permissions or [],
        is_superuser=False,
    )
    return tenant, {"Authorization": f"Bearer {token}"}

# ─── 1. Тест изоляции тенантов (Cross-Tenant Isolation / IDOR) ────────────────
@pytest.mark.asyncio
async def test_tenant_isolation(async_client: AsyncClient, db_session: AsyncSession):
    """
    [БЕЗОПАСНОСТЬ] Данные тенанта Alpha строго изолированы через search_path.
    Попытка доступа от имени Beta возвращает 404 Not Found (не 403!).
    """
    _, headers_alpha = await make_tenant_client(
        db_session, async_client, "Alpha", "tenant_alpha", [Perm.GIFT_CARDS_MANAGE]
    )
    _, headers_beta = await make_tenant_client(
        db_session, async_client, "Beta", "tenant_beta", [Perm.GIFT_CARDS_MANAGE]
    )

    # 1. Создаём ресурс в схеме Alpha
    res_create = await async_client.post(
        "/api/v1/<domain>/",
        json={"name": "Alpha Item"},
        headers=headers_alpha,
    )
    assert res_create.status_code == 201
    item_id = res_create.json()["id"]

    # 2. Пытаемся прочитать ресурс из схемы Beta -> 404 Not Found (search_path изоляция)
    res_idor = await async_client.get(
        f"/api/v1/<domain>/{item_id}",
        headers=headers_beta,
    )
    assert res_idor.status_code == 404

# ─── 2. Тест отката транзакций (Transaction Atomicity & Rollback) ─────────────
@pytest.mark.asyncio
async def test_transaction_rollback_on_failure(async_client: AsyncClient, db_session: AsyncSession):
    """
    [ТРАНЗАКЦИЯ] При сбое в составной операции все связанные изменения откатываются.
    """
    _, headers = await make_tenant_client(
        db_session, async_client, "Alpha", "tenant_alpha", [Perm.POS_CHECKOUT]
    )
    payload = {"invalid_trigger": True, "amount": -100}  # Невалидный триггер сбоя
    res = await async_client.post(
        "/api/v1/<domain>/composite-action",
        json=payload,
        headers=headers,
    )
    assert res.status_code == 400

    # [ИНВАРИАНТ] Прямая проверка БД: откат не оставил мусорных записей в дочерней таблице
    # db_items = (await db_session.execute(select(SubEntityModel))).scalars().all()
    # assert len(db_items) == 0

# ─── 3. Тест PBAC авторизации (Permissions Enforcement) ──────────────────────
@pytest.mark.asyncio
async def test_pbac_forbidden_without_permission(async_client: AsyncClient, db_session: AsyncSession):
    """
    [БЕЗОПАСНОСТЬ] Запрос без соответствующего Perm.<NAME> возвращает 403 Forbidden.
    """
    _, headers_no_perm = await make_tenant_client(
        db_session, async_client, "Alpha", "tenant_alpha", permissions=[]
    )
    res = await async_client.post(
        "/api/v1/<domain>/",
        json={"name": "Protected Action"},
        headers=headers_no_perm,
    )
    assert res.status_code == 403

# ─── 4. Тест конфликта дубликатов и идемпотентности (HTTP 409 & 200) ──────────
@pytest.mark.asyncio
async def test_duplicate_conflict_and_idempotency(async_client: AsyncClient, db_session: AsyncSession):
    """
    [ИНВАРИАНТ] Повтор уникального поля -> 409 Conflict. Повтор client_uuid -> 200 OK.
    """
    _, headers = await make_tenant_client(
        db_session, async_client, "Alpha", "tenant_alpha", [Perm.GIFT_CARDS_MANAGE]
    )
    payload = {"code": "UNIQUE-100", "client_uuid": "c-uuid-1", "name": "Item"}
    res1 = await async_client.post("/api/v1/<domain>/", json=payload, headers=headers)
    assert res1.status_code == 201

    # Повтор с тем же client_uuid -> 200 OK (идемпотентный no-op)
    res_idempotent = await async_client.post("/api/v1/<domain>/", json=payload, headers=headers)
    assert res_idempotent.status_code == 200

    # Попытка создать новую запись с уже занятым кодом -> 409 Conflict
    res_conflict = await async_client.post(
        "/api/v1/<domain>/",
        json={"code": "UNIQUE-100", "client_uuid": "c-uuid-2", "name": "Item 2"},
        headers=headers,
    )
    assert res_conflict.status_code == 409
```

---

## 2. Тестирование фронтенда (Flutter BLoC & Widget Safety)

```dart
// =============================================================================
// МОДУЛЬ: Тесты BLoC логики и EventTransformers
// ДОМЕН: frontend/test/features/<module>/bloc/<module>_bloc_test.dart
// =============================================================================
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDomainRepository extends Mock implements DomainRepository {}

void main() {
  late MockDomainRepository mockRepo;

  setUp(() {
    mockRepo = MockDomainRepository();
  });

  group('<Domain>Bloc Tests', () {
    blocTest<DomainBloc, DomainState>(
      'эмитит [loading, success] при успешном выполнении действия',
      setUp: () {
        when(() => mockRepo.submitAction(any())).thenAnswer((_) async => true);
      },
      build: () => DomainBloc(repository: mockRepo),
      act: (bloc) => bloc.add(const SubmitEvent(id: 1)),
      expect: () => [
        isA<DomainState>().having((s) => s.status, 'status', DomainStatus.loading),
        isA<DomainState>().having((s) => s.status, 'status', DomainStatus.success),
      ],
    );

    // [ИНВАРИАНТ] Проверка sequential() трансформера: события не обгоняют друг друга
    blocTest<DomainBloc, DomainState>(
      'обрабатывает мутирующие события строго последовательно (sequential)',
      setUp: () {
        when(() => mockRepo.submitAction(any())).thenAnswer(
          (_) async => Future.delayed(const Duration(milliseconds: 50), () => true),
        );
      },
      build: () => DomainBloc(repository: mockRepo),
      act: (bloc) {
        bloc.add(const SubmitEvent(id: 1));
        bloc.add(const SubmitEvent(id: 2));
      },
      expect: () => [
        isA<DomainState>().having((s) => s.processedId, 'processedId', 1),
        isA<DomainState>().having((s) => s.processedId, 'processedId', 2),
      ],
    );
  });
}
```

```dart
// =============================================================================
// МОДУЛЬ: Widget-тест диалога с BlocProvider.value и очисткой памяти
// ДОМЕН: frontend/test/features/<module>/view/widgets/<name>_dialog_test.dart
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kreso_frontend/core/widgets/ui_kit/ui_kit.dart';

class MockDomainBloc extends Mock implements DomainBloc {}

void main() {
  late MockDomainBloc mockBloc;

  setUp(() {
    mockBloc = MockDomainBloc();
    when(() => mockBloc.state).thenReturn(const DomainState());
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('Диалог корректно открывается с BlocProvider.value и освобождает ресурсы', (tester) async {
    // 1. Рендерим тестовый harness с инжектированным BLoC в дереве
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<DomainBloc>.value(
          value: mockBloc,
          child: Scaffold(
            body: Builder(
              builder: (ctx) => AppPrimaryButton(
                label: 'Открыть',
                size: AppButtonSize.md,
                onPressed: () => MyDialog.show(ctx, itemId: 42),
              ),
            ),
          ),
        ),
      ),
    );

    // 2. Открываем диалог и верифицируем рендер модального окна
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
    expect(find.byType(MyDialog), findsOneWidget);

    // 3. Закрываем диалог и верифицируем демонтирование виджета (dispose)
    final closeBtn = find.byKey(const Key('dialog_close_button'));
    if (closeBtn.evaluate().isNotEmpty) {
      await tester.tap(closeBtn);
    } else {
      Navigator.of(tester.element(find.byType(MyDialog))).pop();
    }
    await tester.pumpAndSettle();
    expect(find.byType(MyDialog), findsNothing);
  });
}
```

---

## 3. Детерминированный чек-лист верификации перед сдачей (DoD)

Выполни последовательно терминальные команды из корня репозитория:

1. **Архитектурный линтер:**
   ```bash
   python scripts/verify_rules.py --target <имя_модуля>
   ```
   *(Проверяет лимиты строк 200-250, запрет `tenant_id`, микро-файлы <60 строк и UI Kit правила)*.

2. **Backend тесты:**
   ```bash
   pytest backend/tests/test_<name>.py -v
   ```

3. **Frontend статический анализ (с префиксом монорепозитория):**
   ```bash
   dart analyze frontend/lib/features/<имя_модуля>
   ```
   *(Результат обязан быть: `No issues found!`)*.

4. **Frontend тесты:**
   ```bash
   flutter test frontend/test/features/<имя_модуля>
   ```
