"""
Base model with tenant isolation and audit timestamps.
All domain entities inherit from TenantModel to enforce multi-tenancy.
"""

from datetime import datetime, timezone
from typing import Optional

from sqlmodel import SQLModel, Field


class TimestampMixin(SQLModel):
    """Audit timestamps for every record."""
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc).replace(tzinfo=None),
        nullable=False,
    )
    updated_at: Optional[datetime] = Field(
        default=None,
        sa_column_kwargs={"onupdate": lambda: datetime.now(timezone.utc).replace(tzinfo=None)},
    )


class TenantModel(TimestampMixin):
    """
    Base for all tenant-scoped entities.
    Data isolation is handled via PostgreSQL Schemas (schema-based multi-tenancy).
    """
    pass
