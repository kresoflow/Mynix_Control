from enum import Enum

class UnitType(str, Enum):
    KG = "kg"       # килограммы
    G = "g"         # граммы
    L = "l"         # литры
    ML = "ml"       # миллилитры
    PCS = "pcs"     # штуки

class StockTransactionType(str, Enum):
    RECEIPT = "receipt"             # Приёмка товара
    WRITE_OFF = "write_off"        # Ручное списание
    AUTO_DEDUCTION = "auto_deduction"  # Автосписание по техкарте
    INVENTORY_SURPLUS = "inventory_surplus" # Излишек при инвентаризации
    INVENTORY_SHORTAGE = "inventory_shortage" # Недостача при инвентаризации

class DocumentType(str, Enum):
    RECEIPT = "receipt"
    WRITE_OFF = "write_off"
    INVENTORY = "inventory"

class DocumentStatus(str, Enum):
    DRAFT = "draft"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class PaymentStatus(str, Enum):
    UNPAID = "unpaid"
    PARTIAL = "partial"
    PAID = "paid"

class PaymentMethod(str, Enum):
    CASH = "cash"
    CARD = "card"
    BANK_TRANSFER = "bank_transfer"
    ONLINE = "online"
    DEBT = "debt"
    OTHER = "other"

class SupplierTransactionType(str, Enum):
    INVOICE = "invoice"          # Начисление по накладной
    PAYMENT = "payment"          # Выплата поставщику (гашение долга)
    MANUAL_DEBT = "manual_debt"  # Ручной долг
    ADJUSTMENT = "adjustment"    # Корректировка сальдо
