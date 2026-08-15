from typing import Any, Optional


class AppException(Exception):
    """Base application exception."""
    status_code: int = 400
    detail: str = "Application error"

    def __init__(self, detail: Optional[str] = None, status_code: Optional[int] = None, extra: Optional[Any] = None):
        if detail:
            self.detail = detail
        if status_code:
            self.status_code = status_code
        self.extra = extra
        super().__init__(self.detail)


class NotFoundError(AppException):
    status_code = 404
    detail = "Resource not found"


class ValidationError(AppException):
    status_code = 400
    detail = "Validation error"


class PermissionDeniedError(AppException):
    status_code = 403
    detail = "Permission denied"


class ConflictError(AppException):
    status_code = 409
    detail = "Conflict state"


class ShiftNotOpenError(AppException):
    status_code = 400
    detail = "No active shift open for this operation"


class InsufficientStockError(AppException):
    status_code = 400
    detail = "Insufficient ingredient stock"
