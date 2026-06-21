---
name: fastapi_feature_architect
description: Архитектурные стандарты Mynix Control для Backend-разработки (FastAPI + SQLModel). Обязательно к прочтению перед созданием API.
---

# FastAPI Feature Architect Standards

## 1. Проверка существующих схем
**ОБЯЗАТЕЛЬНО:** Прежде чем создавать новую таблицу БД или схему, ты ОБЯЗАН проверить файлы `app/inventory/models.py`, `app/pos/models.py` и т.д. Возможно, сущность (например, Чек или Категория) уже существует! Не плоди дубликаты.

## 2. База Данных (SQLModel)
* Изоляция: Каждая таблица, содержащая бизнес-данные, обязана наследоваться от `TenantModel` (из `app.base_model`), а не от обычного `SQLModel`.
* Offline-First готовность: В каждой новой бизнес-модели должны присутствовать поля:
  * `uuid: str = Field(index=True)` (генерация на клиенте)
  * `sync_status: str = Field(default="synced")` (статусы: `pending`, `synced`, `conflict`)

## 3. Бизнес-логика (Services)
* Вся сложная бизнес-логика живет ТОЛЬКО в папке `services/`.
* Роутеры (`router.py`) занимаются только HTTP-маппингом и инъекцией зависимостей.
* Лимит строк: Ни один файл сервиса не должен превышать 250 строк. Если файл растет, разбивай его на под-модули.

## 4. Безопасность (Auth & PBAC)
* Каждый эндпоинт обязан использовать `Depends(require_permission("domain:action"))`. Пример: `require_permission("menu:manage")`.
* Доступ к БД осуществляется через `session: TenantSession` (гарантирует изоляцию по `search_path`).
