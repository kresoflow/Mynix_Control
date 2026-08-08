"""
Hardware module — ESC/POS receipt printer integration.

Supports Xprinter XP-Q200 / XP-N160M (80mm, USB).
Uses python-escpos library for ESC/POS command generation.

NOTE: python-escpos must be installed separately when hardware is connected:
  uv add python-escpos
"""

from typing import Optional
import logging

logger = logging.getLogger(__name__)


class ReceiptPrinter:
    """
    ESC/POS receipt printer controller.
    Connects via USB to Xprinter XP-Q200 or compatible.
    """

    def __init__(self, vendor_id: int = 0x0416, product_id: int = 0x5011):
        self.vendor_id = vendor_id
        self.product_id = product_id
        self._printer = None

    def connect(self) -> bool:
        """Attempt to connect to the USB printer."""
        try:
            from escpos.printer import Usb
            self._printer = Usb(self.vendor_id, self.product_id)
            logger.info("✅ Receipt printer connected")
            return True
        except Exception as e:
            logger.warning(f"⚠️ Printer not available: {e}")
            self._printer = None
            return False

    @property
    def is_connected(self) -> bool:
        return self._printer is not None

    def print_receipt(
        self,
        order_number: int,
        items: list[dict],
        total: float,
        payment_method: str,
        cashier_name: str,
        tenant_name: str = "Mynix Control",
    ) -> bool:
        """
        Print a customer receipt.
        Returns True on success, False if printer unavailable.
        """
        if not self.is_connected:
            logger.warning("Printer not connected, skipping receipt")
            return False

        try:
            p = self._printer

            # Header
            p.set(align="center", bold=True, double_height=True)
            p.text(f"{tenant_name}\n")
            p.set(align="center", bold=False, double_height=False)
            p.text("=" * 32 + "\n")

            # Order info
            p.set(align="left")
            p.text(f"Заказ: #{order_number}\n")
            p.text(f"Кассир: {cashier_name}\n")
            p.text("-" * 32 + "\n")

            # Items
            for item in items:
                name = item["menu_item_name"][:20]
                qty = item["quantity"]
                price = item["subtotal"]
                p.text(f"{name}\n")
                p.text(f"  {qty} x {item['unit_price']:.0f} = {price:.0f} ₽\n")

            # Total
            p.text("-" * 32 + "\n")
            p.set(bold=True, double_height=True)
            p.text(f"ИТОГО: {total:.0f} ₽\n")
            p.set(bold=False, double_height=False)
            p.text(f"Оплата: {payment_method}\n")
            p.text("=" * 32 + "\n")

            # Footer
            p.set(align="center")
            p.text("Спасибо за покупку!\n\n")

            # Cut paper (auto-cutter)
            p.cut()

            logger.info(f"🖨️ Receipt printed for order #{order_number}")
            return True

        except Exception as e:
            logger.error(f"Printer error: {e}")
            return False

    def print_kitchen_ticket(
        self,
        order_number: int,
        items: list[dict],
        note: Optional[str] = None,
    ) -> bool:
        """
        Print a kitchen runner ticket (бегунок).
        This is the physical proof that the order was registered in the system.
        Cook MUST NOT serve food without this ticket.
        """
        if not self.is_connected:
            logger.warning("Printer not connected, skipping kitchen ticket")
            return False

        try:
            p = self._printer

            # Header
            p.set(align="center", bold=True, double_height=True, double_width=True)
            p.text(f"# {order_number}\n")
            p.set(bold=False, double_height=False, double_width=False)
            p.text("=" * 32 + "\n")

            # Items (large, easy to read)
            p.set(align="left", bold=True)
            for item in items:
                p.text(f"{item['quantity']}x {item['menu_item_name']}\n")

            # Note
            if note:
                p.text("-" * 32 + "\n")
                p.set(bold=False)
                p.text(f"📝 {note}\n")

            p.text("\n")
            p.cut()

            logger.info(f"🍳 Kitchen ticket printed for order #{order_number}")
            return True

        except Exception as e:
            logger.error(f"Printer error: {e}")
            return False

    def open_cash_drawer(self) -> bool:
        """
        Send ESC/POS kick-pulse to open the cash drawer.
        The Aibao 410 drawer is connected via RJ11 to the printer's kick port.
        Pulse: pin 2, 100ms on, 100ms off.
        """
        if not self.is_connected:
            logger.warning("Printer not connected, cannot open drawer")
            return False

        try:
            # ESC/POS command: ESC p m t1 t2
            # m=0 (pin 2), t1=100ms, t2=100ms
            self._printer._raw(b'\x1b\x70\x00\x19\x19')
            logger.info("💰 Cash drawer opened")
            return True
        except Exception as e:
            logger.error(f"Cash drawer error: {e}")
            return False


# ── Singleton printer instance ───────────────────────────────────
receipt_printer = ReceiptPrinter()
