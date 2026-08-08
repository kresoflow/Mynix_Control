from pydantic import BaseModel

class LowStockAlert(BaseModel):
    name: str
    current_stock: float

class TopItem(BaseModel):
    name: str
    options: str | None = None
    quantity_sold: int

class RecentOrderItem(BaseModel):
    name: str
    options: str | None = None
    quantity: int

class RecentOrder(BaseModel):
    order_number: str
    created_at: str
    total: float
    items: list[RecentOrderItem]

class DashboardTodayRead(BaseModel):
    total_revenue: float
    total_orders: int
    dishes_revenue: float
    retail_revenue: float
    total_cogs: float
    net_profit: float
    margin_percentage: float
    low_stock_alerts: list[LowStockAlert]
    top_items: list[TopItem]
    recent_orders: list[RecentOrder]

class TimeSeriesPoint(BaseModel):
    timestamp: str
    revenue: float
    orders: int

class AnalyticsMetrics(BaseModel):
    total_revenue: float
    total_orders: int
    net_profit: float
    margin_percentage: float
    average_check: float
    time_series: list[TimeSeriesPoint]

class CategorySales(BaseModel):
    category_name: str
    revenue: float
    percentage: float

class XRayItem(BaseModel):
    name: str
    options: str | None = None
    category: str
    quantity: int
    revenue: float

class AnalyticsXRay(BaseModel):
    categories: list[CategorySales]
    items: list[XRayItem]
